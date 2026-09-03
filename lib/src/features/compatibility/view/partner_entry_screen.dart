import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/atoms/date_wheel.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/atoms/time_wheel.dart';
import 'package:sanctum/src/design_system/atoms/zodiac_wheel.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_typography.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/domain/services/zodiac.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/l10n/sanctum_lexicon.dart';
import 'package:sanctum/src/routing/app_router.dart';

/// Collects the other person's name, birth date and — if it is known —
/// birth time.
///
/// The same wheel, the same live sign reveal and the same rhythm as the
/// onboarding question, because someone who has already done this once
/// should recognise the screen immediately. The time is asked the same
/// way here as it is there, and it is optional in both: it buys the
/// Moon and nothing else, and most people do not know it.
class PartnerEntryScreen extends StatefulWidget {
  /// Creates the screen.
  const PartnerEntryScreen({super.key});

  @override
  State<PartnerEntryScreen> createState() => _PartnerEntryScreenState();
}

class _PartnerEntryScreenState extends State<PartnerEntryScreen> {
  final _name = TextEditingController();
  DateTime _date = DateTime(1996, 6, 15);
  int? _minuteOfDay;

  ZodiacSign get _sign => Zodiac.signFor(_date);

  bool get _ready => _name.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_ready) return;
    unawaited(
      MatchResultRoute(
        name: _name.text.trim(),
        birth:
            '${_date.year.toString().padLeft(4, '0')}-'
            '${_date.month.toString().padLeft(2, '0')}-'
            '${_date.day.toString().padLeft(2, '0')}',
        minuteOfBirth: _minuteOfDay,
      ).push<void>(context),
    );
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
        iconTheme: IconThemeData(color: colors.textSecondary),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            SanctumSpacing.xl,
            0,
            SanctumSpacing.xl,
            SanctumSpacing.huge + SanctumSpacing.xxl,
          ),
          children: [
            Text(context.l10n.partnerTitle, style: type.displaySmall),
            const SizedBox(height: SanctumSpacing.sm),
            Text(
              context.l10n.partnerBody,
              style: type.bodyMedium,
            ),
            const SizedBox(height: SanctumSpacing.xl),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              style: type.title,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _continue(),
              decoration: InputDecoration(
                hintText: context.l10n.partnerNameHint,
                hintStyle: type.title.copyWith(color: colors.textTertiary),
                filled: true,
                fillColor: colors.glassFill,
                border: const OutlineInputBorder(
                  borderRadius: SanctumRadii.mdAll,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: SanctumSpacing.xl),
            Center(
              child: ZodiacWheel(
                glyphs: [for (final one in ZodiacSign.values) one.glyph],
                activeIndex: ZodiacSign.values.indexOf(_sign),
                size: 230,
              ),
            ),
            const SizedBox(height: SanctumSpacing.sm),
            AnimatedSwitcher(
              duration: SanctumMotion.quick,
              child: Column(
                key: ValueKey(_sign),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _sign.glyph,
                        style: SanctumTypography.symbol(26, colors.gold),
                      ),
                      const SizedBox(width: SanctumSpacing.md),
                      Text(_sign.label(context.l10n), style: type.title),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: SanctumSpacing.lg),
            SizedBox(
              height: 170,
              child: BirthDateWheels(
                date: _date,
                onChanged: (date) => setState(() => _date = date),
              ),
            ),
            const SizedBox(height: SanctumSpacing.xl),
            Text(
              context.l10n.partnerAskTime,
              style: type.bodyMedium.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: SanctumSpacing.md),
            BirthTimeField(
              minuteOfDay: _minuteOfDay,
              onChanged: (value) => setState(() => _minuteOfDay = value),
            ),
            const SizedBox(height: SanctumSpacing.lg),
            SanctumButton(
              label: context.l10n.partnerRead,
              expand: true,
              onPressed: _ready ? _continue : null,
            ),
          ],
        ),
      ),
    );
  }
}
