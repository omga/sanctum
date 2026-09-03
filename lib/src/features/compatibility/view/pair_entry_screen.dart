import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/effects/aurora_background.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/effects/starfield.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/services/zodiac.dart';
import 'package:sanctum/src/features/compatibility/view/match_result_screen.dart';
import 'package:sanctum/src/features/compatibility/view/person_picker_screen.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/sign_avatar.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/l10n/sanctum_lexicon.dart';

/// Reads two other people against each other.
///
/// The user is not in this reading at all. Two friends, two celebrities,
/// a friend and a celebrity — the engine never cared who the first
/// person was, it only ever received two birth dates, so this is a
/// picker rather than a feature.
///
/// It is also the most postable thing the app can produce: a reading
/// about *you* invites one opinion, and a reading about two people the
/// viewer knows invites an argument.
class PairEntryScreen extends StatefulWidget {
  /// Creates the screen.
  const PairEntryScreen({super.key});

  /// Opens it.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PairEntryScreen()),
    );
  }

  @override
  State<PairEntryScreen> createState() => _PairEntryScreenState();
}

class _PairEntryScreenState extends State<PairEntryScreen> {
  MatchPerson? _first;
  MatchPerson? _second;

  bool get _ready => _first != null && _second != null;

  Future<void> _choose({required bool isFirst}) async {
    final person = await PersonPickerScreen.open(
      context,
      isFirst
          ? context.l10n.pairFirstPerson
          : context.l10n.pairSecondPerson,
    );
    if (person == null || !mounted) return;
    setState(() => isFirst ? _first = person : _second = person);
  }

  Future<void> _compare() async {
    final first = _first;
    final second = _second;
    if (first == null || second == null) return;
    await MatchResultScreen.openPair(context, first, second);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.l10n.pairTitle, style: type.title),
        iconTheme: IconThemeData(color: colors.textSecondary),
      ),
      body: AuroraBackground(
        child: Starfield(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                SanctumSpacing.xl,
                0,
                SanctumSpacing.xl,
                SanctumSpacing.huge + SanctumSpacing.xxl,
              ),
              children: [
                Text(
                  context.l10n.pairBody,
                  style: type.bodyMedium,
                ),
                const SizedBox(height: SanctumSpacing.xl),
                _Slot(
                  label: context.l10n.pairSlotFirst,
                  person: _first,
                  onTap: () => unawaited(_choose(isFirst: true)),
                ),
                const SizedBox(height: SanctumSpacing.md),
                Center(
                  child: Text(
                    '+',
                    style: type.displaySmall.copyWith(color: colors.gold),
                  ),
                ),
                const SizedBox(height: SanctumSpacing.md),
                _Slot(
                  label: context.l10n.pairSlotSecond,
                  person: _second,
                  onTap: () => unawaited(_choose(isFirst: false)),
                ),
                const SizedBox(height: SanctumSpacing.xxl),
                SanctumButton(
                  label: context.l10n.pairRead,
                  icon: Icons.auto_awesome,
                  expand: true,
                  onPressed: _ready ? () => unawaited(_compare()) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the two people, chosen or waiting to be.
class _Slot extends StatelessWidget {
  const _Slot({
    required this.label,
    required this.person,
    required this.onTap,
  });

  final String label;
  final MatchPerson? person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final chosen = person;

    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          if (chosen == null)
            Icon(Icons.person_add_alt, color: colors.textSecondary, size: 34)
          else
            SignAvatar(sign: Zodiac.signFor(chosen.birthDate), size: 46),
          const SizedBox(width: SanctumSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: type.caption.copyWith(
                    color: colors.gold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: SanctumSpacing.xxs),
                Text(
                  chosen?.name ?? context.l10n.pairChooseSomeone,
                  style: type.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (chosen != null)
                  Text(
                    Zodiac.signFor(chosen.birthDate).label(context.l10n),
                    style: type.caption,
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.textTertiary),
        ],
      ),
    );
  }
}
