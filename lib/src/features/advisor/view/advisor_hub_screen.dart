import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/advisor_topic.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/features/advisor/view/advisor_screen.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/sign_avatar.dart';
import 'package:sanctum/src/features/compatibility/view_model/compatibility_view_model.dart';
import 'package:sanctum/src/features/today/view_model/today_view_model.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/routing/app_router.dart';

/// The Ask tab: pick who a conversation is about.
///
/// ## Why this exists, given that the argument was against a chat tab
///
/// `roadmap.md` §2 puts the entry point on the compatibility result and
/// the report, "not in a generic chat tab", because a question the user
/// already has beats a blank box. Those entry points are still there and
/// still convert better; this tab is *discovery*, not the primary route
/// in. Somebody who has never scrolled to the foot of a reading has no
/// way to learn the feature exists.
///
/// What it deliberately is not is a blank chat. There is no composer
/// here — every route out of this screen is attached to a subject, so
/// the conversation still opens with the numbers in hand and the
/// suggestions already written. The tab is a list of who you can ask
/// about, not a text box with nothing behind it.
///
/// ## The You row
///
/// First, and there whether or not any reading has been saved. Every
/// other conversation in the app needs a second person before it can
/// exist, which left the one chart the app definitely has — the
/// reader's own — as the only thing it would not talk about. It also
/// means this tab is never empty for somebody who has finished
/// onboarding, which is what it was for anybody who had not yet checked
/// a pairing.
class AdvisorHubScreen extends ConsumerWidget {
  /// Creates the hub.
  const AdvisorHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;
    final state = ref.watch(compatibilityControllerProvider).value;
    final saved = state?.savedReadings ?? const <CompatibilityMatch>[];
    final you = state?.you;
    // The same reading the Today screen is showing, rather than a
    // second composition of it: an advisor describing a different
    // transit than the panel the user just scrolled past is worse than
    // one with no transit at all.
    final today = ref.watch(todayStateProvider).value?.transit;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            SanctumSpacing.lg,
            SanctumSpacing.lg,
            SanctumSpacing.lg,
            // Clears the floating nav bar, which draws over this list.
            SanctumSpacing.xxl * 3,
          ),
          children: [
            Text(l10n.advisorHubTitle, style: type.displaySmall),
            const SizedBox(height: SanctumSpacing.xs),
            Text(
              l10n.advisorHubSubtitle,
              style: type.bodyMedium.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: SanctumSpacing.xl),

            if (you != null) ...[
              _SelfRow(
                topic: SelfTopic(you: you, today: today),
              ),
              const SizedBox(height: SanctumSpacing.md),
            ],

            if (saved.isEmpty)
              _Empty(
                title: l10n.advisorHubEmptyTitle,
                body: l10n.advisorHubEmptyBody,
                action: l10n.matchCheckSomeone,
              )
            else
              for (final match in saved) ...[
                _MatchRow(match: match),
                const SizedBox(height: SanctumSpacing.md),
              ],
          ],
        ),
      ),
    );
  }
}

/// The reader's own chart.
///
/// Its own widget rather than a variant of [_MatchRow]: it carries a
/// different subtitle, and the day it is opened on is part of what it
/// sends. Sharing a row widget between them would put a `switch` inside
/// a list tile to save nine lines.
class _SelfRow extends StatelessWidget {
  const _SelfRow({required this.topic});

  final SelfTopic topic;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final colors = context.colors;

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SanctumSpacing.md,
        vertical: SanctumSpacing.md,
      ),
      onTap: () => unawaited(AdvisorScreen.open(context, topic)),
      child: Row(
        children: [
          SignAvatar(sign: topic.you.sign, size: 44),
          const SizedBox(width: SanctumSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.advisorSelfTitle, style: type.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  context.l10n.advisorSelfHint,
                  style: type.caption.copyWith(color: colors.textTertiary),
                ),
              ],
            ),
          ),
          Icon(Icons.forum_outlined, size: 18, color: colors.textTertiary),
        ],
      ),
    );
  }
}

/// One pairing you can open a conversation about.
class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match});

  final CompatibilityMatch match;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final colors = context.colors;

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SanctumSpacing.md,
        vertical: SanctumSpacing.md,
      ),
      onTap: () => unawaited(AdvisorScreen.open(context, MatchTopic(match))),
      child: Row(
        children: [
          SignAvatar(sign: match.them.sign, size: 44),
          const SizedBox(width: SanctumSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.them.name, style: type.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  context.l10n.advisorHubRowHint,
                  style: type.caption.copyWith(color: colors.textTertiary),
                ),
              ],
            ),
          ),
          Icon(Icons.forum_outlined, size: 18, color: colors.textTertiary),
        ],
      ),
    );
  }
}

/// Nothing to ask about yet.
///
/// Sends them to the tab that produces the thing this one consumes,
/// rather than offering a blank conversation as a consolation prize — a
/// reading with no pairing behind it is exactly the generic chat this
/// feature is built not to be.
class _Empty extends StatelessWidget {
  const _Empty({
    required this.title,
    required this.body,
    required this.action,
  });

  final String title;
  final String body;
  final String action;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.type.title),
        const SizedBox(height: SanctumSpacing.sm),
        Text(
          body,
          style: context.type.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: SanctumSpacing.lg),
        SanctumButton(
          label: action,
          icon: Icons.add,
          expand: true,
          onPressed: () => const MatchRoute().go(context),
        ),
      ],
    ),
  );
}
