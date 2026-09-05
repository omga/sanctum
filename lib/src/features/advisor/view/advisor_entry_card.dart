import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/services/conversation_budget.dart';
import 'package:sanctum/src/features/advisor/view/advisor_screen.dart';
import 'package:sanctum/src/l10n/l10n.dart';

/// The card that opens a conversation about a pairing.
///
/// ## Why it lives on the reading and the report, and nowhere else
///
/// `roadmap.md` §2: "The compatibility feature also generates the
/// questions for free… Put the entry point there, not in a generic chat
/// tab." A user looking at a 43 in Trust already has the question; a
/// chat tab asks them to invent one.
///
/// The report is the better of the two surfaces still, because somebody
/// who has just paid for depth on one named person is the most likely
/// user in the app to have a follow-up about that person.
///
/// ## Why it states the number of questions
///
/// It is what is bought. An entry point that says "ask the advisor" and
/// then meters the conversation invisibly is the shape of the thing this
/// app's paywall documentation spends three paragraphs rejecting.
class AdvisorEntryCard extends StatelessWidget {
  /// Creates the card for [match].
  const AdvisorEntryCard({required this.match, super.key});

  /// The pairing it opens a conversation about.
  final CompatibilityMatch match;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Names the person, like the report offer above it does. The
            // name is rendered here and never sent — see AdvisorContext.
            l10n.advisorEntryTitle(match.them.name),
            style: type.title,
          ),
          const SizedBox(height: SanctumSpacing.sm),
          Text(
            l10n.advisorEntryBody(ConversationBudget.turnsPerConversation),
            style: type.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: SanctumSpacing.lg),
          SanctumButton(
            label: l10n.advisorEntryAction,
            icon: Icons.forum_outlined,
            expand: true,
            variant: SanctumButtonVariant.ghost,
            onPressed: () => unawaited(AdvisorScreen.open(context, match)),
          ),
        ],
      ),
    );
  }
}
