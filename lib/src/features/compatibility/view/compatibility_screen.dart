import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/design_system/atoms/date_wheel.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/atoms/zodiac_wheel.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/celebrity.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/domain/services/zodiac.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/celebrity_tile.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/sign_avatar.dart';
import 'package:sanctum/src/features/compatibility/view_model/compatibility_view_model.dart';
import 'package:sanctum/src/routing/app_router.dart';

/// The compatibility tab.
class CompatibilityScreen extends ConsumerWidget {
  /// Creates the screen.
  const CompatibilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compatibilityControllerProvider);

    return SafeArea(
      bottom: false,
      child: state.when(
   skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(SanctumSpacing.xl),
            child: Text('$error', textAlign: TextAlign.center),
          ),
        ),
        data: (data) =>
            data.isReady ? _Browser(state: data) : const _AskBirthDate(),
      ),
    );
  }
}

/// Shown only if someone reaches this tab without a birth date on file.
class _AskBirthDate extends ConsumerStatefulWidget {
  const _AskBirthDate();

  @override
  ConsumerState<_AskBirthDate> createState() => _AskBirthDateState();
}

class _AskBirthDateState extends ConsumerState<_AskBirthDate> {
  DateTime _date = DateTime(1996, 6, 15);

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final sign = Zodiac.signFor(_date);
    ref.watch(compatibilityControllerProvider);
    final controller = ref.read(compatibilityControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SanctumSpacing.xl,
        SanctumSpacing.xl,
        SanctumSpacing.xl,
        SanctumSpacing.huge + SanctumSpacing.xxl,
      ),
      children: [
        Text('When were you born?', style: type.displaySmall),
        const SizedBox(height: SanctumSpacing.sm),
        Text(
          'Every match is read from your sign against theirs.',
          style: type.bodyMedium,
        ),
        const SizedBox(height: SanctumSpacing.xl),
        Center(
          child: ZodiacWheel(
            glyphs: [for (final one in ZodiacSign.values) one.glyph],
            activeIndex: ZodiacSign.values.indexOf(sign),
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
          label: 'Continue',
          expand: true,
          onPressed: () => controller.setYourBirthDate(_date),
        ),
      ],
    );
  }
}

class _Browser extends StatefulWidget {
  const _Browser({required this.state});

  final CompatibilityUiState state;

  @override
  State<_Browser> createState() => _BrowserState();
}

class _BrowserState extends State<_Browser> {
  String _query = '';

  CompatibilityUiState get state => widget.state;

  List<Celebrity> _matching(CelebrityGroup group) {
    final needle = _query.trim().toLowerCase();
    return [
      for (final one in state.celebrities)
        if (one.group == group &&
            (needle.isEmpty || one.name.toLowerCase().contains(needle)))
          one,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final you = state.you!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SanctumSpacing.xl,
        SanctumSpacing.lg,
        SanctumSpacing.xl,
        SanctumSpacing.huge + SanctumSpacing.xxl,
      ),
      children: [
        Row(
          children: [
            SignAvatar(sign: you.sign, size: 52),
            const SizedBox(width: SanctumSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Compatibility', style: type.displaySmall),
                  Text(
                    'Reading as ${you.sign.displayName}',
                    style: type.caption.copyWith(color: colors.gold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: SanctumSpacing.lg),
        SanctumButton(
          label: 'Check someone new',
          icon: Icons.add,
          expand: true,
          onPressed: () => const MatchEntryRoute().push<void>(context),
        ),
        if (state.saved.isNotEmpty) ...[
          const SizedBox(height: SanctumSpacing.xxl),
          const _SectionTitle(label: 'Your matches'),
          for (final match in state.saved) ...[
            const SizedBox(height: SanctumSpacing.md),
            _SavedMatchTile(match: match),
          ],
        ],
        const SizedBox(height: SanctumSpacing.xxl),
        const _SectionTitle(label: 'Or someone famous'),
        const SizedBox(height: SanctumSpacing.md),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          style: type.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search by name',
            hintStyle: type.bodyMedium.copyWith(color: colors.textTertiary),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
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
        for (final group in CelebrityGroup.values) ...[
          if (_matching(group).isNotEmpty) ...[
            const SizedBox(height: SanctumSpacing.xl),
            Text(
              group.displayName.toUpperCase(),
              style: type.caption.copyWith(
                color: colors.textSecondary,
                letterSpacing: 2,
              ),
            ),
            for (final (index, one) in _matching(group).indexed) ...[
              const SizedBox(height: SanctumSpacing.md),
              CelebrityTile(
                    celebrity: one,
                    matched: state.revealedIds.contains(one.asPerson.key),
                    onTap: () => MatchResultRoute(
                      name: one.name,
                      birth: _iso(one.birthDate),
                      celebrityId: one.id,
                    ).push<void>(context),
                  )
                  .animate(delay: Duration(milliseconds: 24 * index))
                  .fadeIn(duration: SanctumMotion.quick),
            ],
          ],
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) =>
      Text(label, style: context.type.title);
}

class _SavedMatchTile extends StatelessWidget {
  const _SavedMatchTile({required this.match});

  final CompatibilityMatch match;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return GestureDetector(
      onTap: () => MatchResultRoute(
        name: match.them.name,
        birth: _iso(match.them.birthDate),
        celebrityId: match.them.celebrityId,
      ).push<void>(context),
      child: GlassCard(
        padding: const EdgeInsets.all(SanctumSpacing.md),
        child: Row(
          children: [
            SignAvatar(sign: match.them.sign, size: 44),
            const SizedBox(width: SanctumSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.them.name,
                    style: type.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(match.aspect.displayName, style: type.caption),
                ],
              ),
            ),
            Text(
              '${match.overall}%',
              style: type.title.copyWith(color: colors.gold),
            ),
          ],
        ),
      ),
    );
  }
}

/// `yyyy-MM-dd`, the shape the result route expects.
String _iso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
