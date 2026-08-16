import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/atoms/date_wheel.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/atoms/zodiac_wheel.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_typography.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/domain/services/zodiac.dart';
import 'package:sanctum/src/routing/app_router.dart';

/// Collects the other person's name and birth date.
///
/// The same wheel, the same live sign reveal and the same rhythm as the
/// onboarding question, because someone who has already done this once
/// should recognise the screen immediately.
class PartnerEntryScreen extends StatefulWidget {
  /// Creates the screen.
  const PartnerEntryScreen({super.key});

  @override
  State<PartnerEntryScreen> createState() => _PartnerEntryScreenState();
}

class _PartnerEntryScreenState extends State<PartnerEntryScreen> {
  final _name = TextEditingController();
  DateTime _date = DateTime(1996, 6, 15);

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
            Text('Who are we reading?', style: type.displaySmall),
            const SizedBox(height: SanctumSpacing.sm),
            Text(
              'Their birth date is the only thing the reading uses, '
              'and it stays on this phone.',
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
                hintText: 'Their name',
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
                      Text(_sign.displayName, style: type.title),
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
            const SizedBox(height: SanctumSpacing.lg),
            SanctumButton(
              label: 'Read us',
              expand: true,
              onPressed: _ready ? _continue : null,
            ),
          ],
        ),
      ),
    );
  }
}
