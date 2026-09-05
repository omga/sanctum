import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_dialog.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/conversation.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/services/conversation_starters.dart';
import 'package:sanctum/src/features/advisor/view_model/advisor_view_model.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/l10n/sanctum_lexicon.dart';

/// A conversation about one pairing.
///
/// ## Why it is pushed with an object rather than routed
///
/// The same reason `ReportScreen` is: `CompatibilityMatch.id` is built
/// from both people's names and birth dates, so routing to it by id puts
/// exactly that in a URL, which reaches crash breadcrumbs and OS logs.
/// A feature whose entire point is that the name stays on the device
/// must not be the one that writes it into a route.
///
/// ## What is not here yet
///
/// No purchase gate — `advisor.md` §8 step 6. The transport is scripted,
/// so nothing said here reaches a network at all.
class AdvisorScreen extends ConsumerStatefulWidget {
  /// Creates the screen for [match].
  const AdvisorScreen({required this.match, super.key});

  /// Opens a conversation about [match].
  static Future<void> open(BuildContext context, CompatibilityMatch match) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AdvisorScreen(match: match)),
    );
  }

  /// The pairing being discussed.
  final CompatibilityMatch match;

  @override
  ConsumerState<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends ConsumerState<AdvisorScreen> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String question) async {
    _composer.clear();
    final controller = ref.read(
      advisorControllerProvider(widget.match).notifier,
    );
    // The locale the answer should be written in. Read here rather than
    // in the notifier because it is a UI concern that the domain payload
    // merely carries.
    final language = Localizations.localeOf(context).languageCode;
    unawaited(_scrollToEnd());
    await controller.ask(question, languageCode: language);
    await _scrollToEnd();
  }

  Future<void> _scrollToEnd() async {
    // One frame, so the list has the new message in it before we ask
    // how tall it is.
    await Future<void>.delayed(Duration.zero);
    if (!_scroll.hasClients) return;
    await _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final state = ref.watch(advisorControllerProvider(widget.match)).value;

    // Scroll as the answer grows, not only when it is finished.
    ref.listen(advisorControllerProvider(widget.match), (previous, next) {
      if (next.value?.isStreaming ?? false) unawaited(_scrollToEnd());
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.reportTitle(widget.match.them.name),
          style: type.title,
        ),
        actions: [
          // Only once there is something to delete. An empty
          // conversation offering to erase itself is noise.
          if (state != null && state.messages.isNotEmpty)
            IconButton(
              tooltip: l10n.advisorDelete,
              onPressed: () => unawaited(_confirmDelete(context)),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        // Nothing, rather than a spinner, while the transcript loads.
        // It is a local SQLite read of a handful of rows, so a spinner
        // would be a flash rather than feedback — and showing the
        // suggestion row first would flash the wrong screen at anybody
        // who *does* have a transcript.
        child: state == null
            ? const SizedBox.shrink()
            : Column(
                children: [
                  _Disclosure(text: l10n.advisorDisclosure),
                  Expanded(
                    child: state.messages.isEmpty
                        ? _Starters(match: widget.match, onPick: _send)
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.symmetric(
                              horizontal: SanctumSpacing.lg,
                              vertical: SanctumSpacing.md,
                            ),
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) => _Bubble(
                              message: state.messages[index],
                              isStreaming:
                                  state.messages[index].id == state.streamingId,
                            ),
                          ),
                  ),
                  if (state.failure case final failure?)
                    _FailureBar(
                      failure: failure,
                      onRetry: () async {
                        final language = Localizations.localeOf(context)
                            .languageCode;
                        await ref
                            .read(
                              advisorControllerProvider(widget.match).notifier,
                            )
                            .retry(languageCode: language);
                        await _scrollToEnd();
                      },
                    ),
                  if (state.showsTurnCount && !state.isSpent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: SanctumSpacing.xs),
                      child: Text(
                        l10n.advisorTurnsLeft(state.turnsRemaining),
                        style: type.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ),
                  if (state.isSpent)
                    _Spent(
                      title: l10n.advisorSpentTitle,
                      body: l10n.advisorSpentBody,
                    )
                  else
                    _Composer(
                      controller: _composer,
                      enabled: state.canAsk,
                      hint: l10n.advisorComposerHint,
                      sendLabel: l10n.advisorSend,
                      onSend: _send,
                    ),
                ],
              ),
      ),
    );
  }

  /// Deleting a transcript is irreversible and unshared, so it asks.
  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await SanctumDialog.show(
      context,
      title: l10n.advisorDeleteTitle,
      message: l10n.advisorDeleteMessage,
      confirmLabel: l10n.advisorDelete,
      cancelLabel: l10n.journalKeep,
    );
    if (!confirmed) return;
    await ref
        .read(advisorControllerProvider(widget.match).notifier)
        .deleteConversation();
  }
}

/// The line that discharges two duties at once.
///
/// EU AI Act Article 50 wants the user told they are talking to an AI;
/// the privacy promise wants them told what does not leave the phone.
/// One sentence, at the top of every conversation, where it is read
/// rather than buried in a settings screen.
class _Disclosure extends StatelessWidget {
  const _Disclosure({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      SanctumSpacing.lg,
      0,
      SanctumSpacing.lg,
      SanctumSpacing.sm,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.auto_awesome_outlined,
          size: 14,
          color: context.colors.textTertiary,
        ),
        const SizedBox(width: SanctumSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: context.type.caption.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The questions the app already knows the user has.
class _Starters extends ConsumerWidget {
  const _Starters({required this.match, required this.onPick});

  final CompatibilityMatch match;
  final void Function(String) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;
    final catalog = ref.watch(contentCatalogProvider).value;
    if (catalog == null) return const SizedBox.shrink();

    final starters = ConversationStarters.forMatch(match);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SanctumSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.advisorSuggested,
            style: type.caption.copyWith(
              color: colors.textTertiary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: SanctumSpacing.md),
          for (final starter in starters) ...[
            _StarterChip(
              label: _render(starter, catalog.copy, context, named: true),
              onTap: () =>
                  onPick(_render(starter, catalog.copy, context, named: true)),
            ),
            const SizedBox(height: SanctumSpacing.sm),
          ],
        ],
      ),
    );
  }

  /// Fills a starter's slots.
  ///
  /// [named] picks the display wording, which carries the other person's
  /// name. The neutral wording behind `promptKey` is what the send path
  /// uses; the redactor rewrites the display form on its way out either
  /// way, so a user who edits the suggestion before sending is covered
  /// too.
  String _render(
    ConversationStarter starter,
    CopyBook copy,
    BuildContext context, {
    required bool named,
  }) => copy.format(named ? starter.displayKey : starter.promptKey, {
    'name': match.them.name,
    if (starter.facet case final facet?) ...{
      'facet': facet.label(context.l10n),
      'score': match.facets.firstWhere((scored) => scored.facet == facet).score,
    },
  });
}

class _StarterChip extends StatelessWidget {
  const _StarterChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(
      horizontal: SanctumSpacing.md,
      vertical: SanctumSpacing.sm,
    ),
    onTap: onTap,
    child: Row(
      children: [
        Expanded(child: Text(label, style: context.type.bodyMedium)),
        Icon(
          Icons.north_east,
          size: 16,
          color: context.colors.textTertiary,
        ),
      ],
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isStreaming});

  final ChatMessage message;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final mine = message.author == MessageAuthor.you;

    // An answer with no text yet is a state of its own: the alternative
    // is an empty bubble, which reads as the app having said nothing.
    final waiting = !mine && message.body.isEmpty && isStreaming;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: SanctumSpacing.sm),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: SanctumSpacing.md,
          vertical: SanctumSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: mine ? colors.surfaceRaised : colors.glassFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.glassBorder),
        ),
        child: Text(
          waiting ? context.l10n.advisorThinking : message.body,
          style: type.bodyMedium.copyWith(
            color: waiting ? colors.textTertiary : colors.textPrimary,
            fontStyle: waiting ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }
}

/// What went wrong, in the words that failure deserves.
class _FailureBar extends StatelessWidget {
  const _FailureBar({required this.failure, required this.onRetry});

  final AdvisorFailure failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    final message = switch (failure.kind) {
      AdvisorFailureKind.offline => l10n.advisorFailedOffline,
      AdvisorFailureKind.rateLimited => l10n.advisorFailedBusy,
      AdvisorFailureKind.refused => l10n.advisorFailedRefused,
      AdvisorFailureKind.server ||
      AdvisorFailureKind.scripted => l10n.advisorFailedServer,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SanctumSpacing.lg,
        vertical: SanctumSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: context.type.caption.copyWith(color: colors.textSecondary),
            ),
          ),
          // A refusal will refuse again. Offering "try again" for one is
          // an invitation to spend a minute proving that.
          if (failure.kind != AdvisorFailureKind.refused)
            TextButton(
              onPressed: () => unawaited(onRetry()),
              child: Text(l10n.advisorRetry),
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.hint,
    required this.sendLabel,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final String sendLabel;
  final void Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SanctumSpacing.lg,
        0,
        SanctumSpacing.lg,
        SanctumSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: enabled ? onSend : null,
              style: context.type.bodyMedium,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: colors.surfaceRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: SanctumSpacing.md,
                  vertical: SanctumSpacing.sm,
                ),
              ),
            ),
          ),
          const SizedBox(width: SanctumSpacing.sm),
          IconButton(
            tooltip: sendLabel,
            onPressed: enabled ? () => onSend(controller.text) : null,
            icon: const Icon(Icons.arrow_upward),
            color: colors.accent,
          ),
        ],
      ),
    );
  }
}

/// Shown where the composer was, once every question is spent.
class _Spent extends StatelessWidget {
  const _Spent({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      SanctumSpacing.lg,
      0,
      SanctumSpacing.lg,
      SanctumSpacing.md,
    ),
    child: Column(
      children: [
        Text(title, style: context.type.label),
        const SizedBox(height: SanctumSpacing.xxs),
        Text(
          body,
          textAlign: TextAlign.center,
          style: context.type.caption.copyWith(
            color: context.colors.textTertiary,
          ),
        ),
      ],
    ),
  );
}
