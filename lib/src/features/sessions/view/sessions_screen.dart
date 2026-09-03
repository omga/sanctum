import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/paywall.dart';
import 'package:sanctum/src/domain/models/sound_session.dart';
import 'package:sanctum/src/domain/services/premium_gate.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/routing/app_router.dart';

/// The sound-bath library.
class SessionsScreen extends ConsumerWidget {
  /// Creates the screen.
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(contentCatalogProvider);

    return SafeArea(
      bottom: false,
      child: catalog.when(
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
            Text(context.l10n.soundTitle, style: context.type.displayMedium),
            const SizedBox(height: SanctumSpacing.xxs),
            Text(
              context.l10n.soundSubtitle,
              style: context.type.caption.copyWith(color: context.colors.gold),
            ),
            const SizedBox(height: SanctumSpacing.xl),
            for (final (index, session) in data.sessions.indexed) ...[
              _SessionTile(
                session: session,
                locked:
                    !PremiumGate.isSessionFree(index) &&
                    !ref.watch(isPremiumProvider),
              ),
              const SizedBox(height: SanctumSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.locked});

  final SoundSession session;

  /// Whether premium is required to play this one.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    // GlassCard.flat, not GlassCard: this is a list, and a BackdropFilter
    // per row is exactly the pattern that drops frames while scrolling.
    return GlassCard.flat(
      // A locked row still looks like content and still responds to a
      // tap — it just opens the paywall instead of the player. Greying
      // it out and swallowing the tap teaches people the row is broken.
      onTap: () {
        if (locked) {
          // push, not go: the paywall is a modal over this list. `go`
          // replaces the location, leaving nothing to pop back to — so
          // dismissing or even completing a purchase strands the user
          // on the paywall.
          unawaited(
            const PaywallRoute(moment: PaywallMoment.lockedContent)
                .push<void>(context),
          );
        } else {
          SessionPlayerRoute(sessionId: session.id).go(context);
        }
      },
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colors.accent.withValues(alpha: 0.45),
                  colors.accentTertiary.withValues(alpha: 0.25),
                ],
              ),
            ),
            child: Text(
              session.frequencyLabel.split(' ').first,
              style: type.caption.copyWith(color: colors.textPrimary),
            ),
          ),
          const SizedBox(width: SanctumSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.title, style: type.title),
                const SizedBox(height: SanctumSpacing.xxs),
                Text(
                  session.intention,
                  style: type.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: SanctumSpacing.md),
          if (locked)
            Icon(Icons.lock_outline, size: 18, color: colors.gold)
          else
            Text(session.durationLabel, style: type.caption),
        ],
      ),
    );
  }
}
