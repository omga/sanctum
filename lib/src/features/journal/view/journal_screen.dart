import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_dialog.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/journal_entry.dart';
import 'package:sanctum/src/features/journal/view_model/journal_view_model.dart';

/// The journal.
class JournalScreen extends ConsumerWidget {
  /// Creates the screen.
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalEntriesProvider);

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          entries.when(
            skipLoadingOnReload: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (data) => ListView(
              padding: const EdgeInsets.fromLTRB(
                SanctumSpacing.screenGutter,
                SanctumSpacing.lg,
                SanctumSpacing.screenGutter,
                SanctumSpacing.huge + SanctumSpacing.xxl,
              ),
              children: [
                Text('Journal', style: context.type.displayMedium),
                const SizedBox(height: SanctumSpacing.xxs),
                Text(
                  '${data.length} ENTR${data.length == 1 ? 'Y' : 'IES'}',
                  style: context.type.caption.copyWith(
                    color: context.colors.gold,
                  ),
                ),
                const SizedBox(height: SanctumSpacing.xl),
                if (data.isEmpty)
                  const _EmptyJournal()
                else
                  for (final entry in data) ...[
                    _EntryTile(entry: entry),
                    const SizedBox(height: SanctumSpacing.md),
                  ],
              ],
            ),
          ),
          Positioned(
            right: SanctumSpacing.screenGutter,
            // The shell sets extendBody: true, so this Stack extends
            // *behind* the floating nav bar. Clearing it means the nav
            // bar's own height plus the home-indicator inset — a fixed
            // offset leaves the button half-hidden on exactly the phones
            // that have a home indicator.
            bottom:
                MediaQuery.paddingOf(context).bottom +
                SanctumSpacing.huge +
                SanctumSpacing.xl,
            child: SanctumButton(
              label: 'Write',
              icon: Icons.edit_outlined,
              onPressed: () => _openComposer(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  void _openComposer(BuildContext context, WidgetRef ref) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (_) => const _ComposerSheet(),
      ),
    );
  }
}

class _EmptyJournal extends StatelessWidget {
  const _EmptyJournal();

  @override
  Widget build(BuildContext context) {
    return GlassCard.flat(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nothing written yet', style: context.type.title),
          const SizedBox(height: SanctumSpacing.sm),
          Text(
            'The first entry is the hardest. It does not have to be good, '
            'or long, or true tomorrow.',
            style: context.type.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return Semantics(
      button: true,
      label: 'Journal entry, ${entry.kind.displayName}',
      child: GestureDetector(
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          unawaited(
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              // Root navigator, or the shell's floating nav bar draws
              // on top of the sheet — a modal with a tab bar sitting
              // over its buttons.
              useRootNavigator: true,
              builder: (_) => _ReaderSheet(entry: entry),
            ),
          );
        },
        child: GlassCard.flat(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    entry.kind.displayName.toUpperCase(),
                    style: type.caption.copyWith(color: colors.gold),
                  ),
                  const Spacer(),
                  Text(_formatDate(entry.createdAt), style: type.caption),
                  const SizedBox(width: SanctumSpacing.xs),
                  // The affordance. Without it there is nothing on the
                  // card to suggest the text continues past the ellipsis.
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: colors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: SanctumSpacing.sm),
              Text(entry.preview, style: type.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

/// One entry, in full.
///
/// `JournalEntry.preview` truncates at 80 characters, and until now that
/// was the only way an entry was ever rendered — so anything longer than
/// a sentence was written, stored, and permanently unreadable. For a
/// journal that is not a missing feature, it is the feature failing.
///
/// This is also the first place `prompt` and `delete` surface. Both were
/// written end to end and reachable from nowhere: entries answering a
/// ritual prompt never showed what they were answering, and nothing the
/// user wrote could ever be removed.
class _ReaderSheet extends ConsumerWidget {
  const _ReaderSheet({required this.entry});

  final JournalEntry entry;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await SanctumDialog.show(
      context,
      title: 'Delete this entry?',
      message: 'It is only on this phone, so this cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Keep',
    );
    if (!confirmed || !context.mounted) return;

    await ref.read(journalControllerProvider.notifier).delete(entry.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final type = context.type;
    ref.watch(journalControllerProvider);

    return ConstrainedBox(
      // Tall enough for a long entry, short enough that the sheet still
      // reads as a sheet rather than a screen that arrived sideways.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: SanctumSpacing.lg,
          right: SanctumSpacing.lg,
          top: SanctumSpacing.md,
          bottom:
              MediaQuery.paddingOf(context).bottom + SanctumSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: SanctumRadii.pillAll,
                  color: colors.glassBorder,
                ),
              ),
            ),
            const SizedBox(height: SanctumSpacing.lg),
            Row(
              children: [
                Text(
                  entry.kind.displayName.toUpperCase(),
                  style: type.caption.copyWith(
                    color: colors.gold,
                    letterSpacing: 1.6,
                  ),
                ),
                const Spacer(),
                Text(_longDate(entry.createdAt), style: type.caption),
              ],
            ),
            const SizedBox(height: SanctumSpacing.lg),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.prompt case final prompt?) ...[
                      Text(prompt, style: type.quote),
                      const SizedBox(height: SanctumSpacing.md),
                      Divider(color: colors.divider, height: 1),
                      const SizedBox(height: SanctumSpacing.md),
                    ],
                    // The whole thing, wrapping and scrolling. No
                    // maxLines anywhere below this point.
                    SelectableText(entry.body, style: type.bodyLarge),
                  ],
                ),
              ),
            ),
            const SizedBox(height: SanctumSpacing.lg),
            Row(
              children: [
                SanctumButton(
                  label: 'Delete',
                  icon: Icons.delete_outline,
                  variant: SanctumButtonVariant.quiet,
                  onPressed: () => unawaited(_delete(context, ref)),
                ),
                const Spacer(),
                SanctumButton(
                  label: 'Done',
                  variant: SanctumButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _longDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ComposerSheet extends ConsumerStatefulWidget {
  const _ComposerSheet();

  @override
  ConsumerState<_ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends ConsumerState<_ComposerSheet> {
  final _controller = TextEditingController();
  JournalKind _kind = JournalKind.gratitude;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;

    await ref
        .read(journalControllerProvider.notifier)
        .add(
          kind: _kind,
          body: body,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Keeps the auto-dispose controller alive while the sheet is open;
    // see the note in today_screen.dart.
    ref.watch(journalControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: SanctumSpacing.lg,
        right: SanctumSpacing.lg,
        top: SanctumSpacing.lg,
        // Lift above the keyboard.
        bottom: MediaQuery.viewInsetsOf(context).bottom + SanctumSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: SanctumSpacing.sm,
            children: [
              for (final kind in JournalKind.values)
                ChoiceChip(
                  label: Text(kind.displayName),
                  selected: _kind == kind,
                  onSelected: (_) => setState(() => _kind = kind),
                  showCheckmark: false,
                  backgroundColor: colors.glassFill,
                  selectedColor: colors.accent.withValues(alpha: 0.3),
                  side: BorderSide(color: colors.glassBorder),
                  shape: const RoundedRectangleBorder(
                    borderRadius: SanctumRadii.pillAll,
                  ),
                ),
            ],
          ),
          const SizedBox(height: SanctumSpacing.lg),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 6,
            style: context.type.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Write freely.',
              hintStyle: context.type.bodyLarge.copyWith(
                color: colors.textTertiary,
              ),
              filled: true,
              fillColor: colors.glassFill,
              border: const OutlineInputBorder(
                borderRadius: SanctumRadii.mdAll,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: SanctumSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: SanctumButton(label: 'Save', onPressed: _save),
          ),
        ],
      ),
    );
  }
}
