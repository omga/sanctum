import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/effects/aurora_background.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/effects/starfield.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/ritual.dart';
import 'package:sanctum/src/domain/services/moon_phase_calculator.dart';
import 'package:sanctum/src/features/rituals/view_model/ritual_view_model.dart';
import 'package:sanctum/src/features/today/view/widgets/moon_disc.dart';

/// The moon ritual for the current phase.
class RitualScreen extends ConsumerWidget {
  /// Creates the screen.
  const RitualScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ritualStateProvider);

    return Scaffold(
      body: AuroraBackground(
        child: Starfield(
          child: SafeArea(
            child: state.when(
   skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (data) {
                final ritual = data.ritual;
                return ritual == null
                    ? _ClosedRitual(state: data)
                    : _OpenRitual(ritual: ritual, state: data);
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when the current phase carries no ritual.
class _ClosedRitual extends StatelessWidget {
  const _ClosedRitual({required this.state});

  final RitualUiState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final days = state.daysUntilNext;

    return Padding(
      padding: const EdgeInsets.all(SanctumSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CloseButton(),
          const Spacer(),
          MoonDisc(
            reading: MoonPhaseCalculator.readingFor(state.today),
            size: 76,
          ),
          const SizedBox(height: SanctumSpacing.xl),
          Text(state.phase.displayName, style: type.displayMedium),
          const SizedBox(height: SanctumSpacing.md),
          Text(
            // Framing the wait as intentional, not as a locked feature.
            // "Come back in 4 days" reads like a paywall; this does not.
            'The moon is between rituals. This part of the cycle asks '
            'for nothing except that you keep going.',
            style: type.bodyLarge,
          ),
          if (days != null && state.nextRitual != null) ...[
            const SizedBox(height: SanctumSpacing.xl),
            GlassCard.flat(
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty, color: colors.goldMuted),
                  const SizedBox(width: SanctumSpacing.md),
                  Expanded(
                    child: Text(
                      days == 0
                          ? '${state.nextRitual!.title} opens today'
                          : '${state.nextRitual!.title} in '
                                '$days day${days == 1 ? '' : 's'}',
                      style: type.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

/// The ritual itself.
class _OpenRitual extends ConsumerStatefulWidget {
  const _OpenRitual({required this.ritual, required this.state});

  final Ritual ritual;
  final RitualUiState state;

  @override
  ConsumerState<_OpenRitual> createState() => _OpenRitualState();
}

class _OpenRitualState extends ConsumerState<_OpenRitual> {
  late final List<bool> _done = List<bool>.filled(
    widget.ritual.steps.length,
    false,
  );
  final _reflection = TextEditingController();
  bool _saved = false;

  @override
  void dispose() {
    _reflection.dispose();
    super.dispose();
  }

  bool get _allStepsDone => _done.every((step) => step);

  Future<void> _complete() async {
    final text = _reflection.text.trim();
    await ref
        .read(ritualControllerProvider.notifier)
        .complete(
          ritual: widget.ritual,
          reflection: text.isEmpty ? 'Completed ${widget.ritual.title}.' : text,
        );

    if (!mounted) return;
    final failed = ref.read(ritualControllerProvider).hasError;
    if (failed) return;

    unawaited(HapticFeedback.mediumImpact());
    setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final ritual = widget.ritual;

    // Keeps the auto-dispose controller alive while this screen is up.
    ref.watch(ritualControllerProvider);
    ref.listen(ritualControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text('$error')));
      }
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SanctumSpacing.xl,
        SanctumSpacing.lg,
        SanctumSpacing.xl,
        SanctumSpacing.huge,
      ),
      children: [
        const _CloseButton(),
        const SizedBox(height: SanctumSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ritual.moon.toUpperCase(),
                    style: type.caption.copyWith(color: colors.gold),
                  ),
                  const SizedBox(height: SanctumSpacing.xxs),
                  Text(ritual.title, style: type.displayMedium),
                ],
              ),
            ),
            MoonDisc(
              reading: MoonPhaseCalculator.readingFor(widget.state.today),
              size: 56,
            ),
          ],
        ),
        const SizedBox(height: SanctumSpacing.lg),
        Text(ritual.opening, style: type.quote),
        const SizedBox(height: SanctumSpacing.xxl),

        for (var i = 0; i < ritual.steps.length; i++) ...[
          _StepTile(
            index: i + 1,
            text: ritual.steps[i],
            done: _done[i],
            onToggle: () {
              unawaited(HapticFeedback.selectionClick());
              setState(() => _done[i] = !_done[i]);
            },
          ),
          const SizedBox(height: SanctumSpacing.md),
        ],

        const SizedBox(height: SanctumSpacing.lg),
        if (_saved)
          GlassCard.flat(
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: colors.success),
                const SizedBox(width: SanctumSpacing.md),
                Expanded(
                  child: Text(
                    'Kept in your journal.',
                    style: type.bodyMedium,
                  ),
                ),
              ],
            ),
          )
        else ...[
          Text('What came up?', style: type.title),
          const SizedBox(height: SanctumSpacing.sm),
          TextField(
            controller: _reflection,
            maxLines: 4,
            style: type.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Optional. A line is enough.',
              hintStyle: type.bodyMedium.copyWith(color: colors.textTertiary),
              filled: true,
              fillColor: colors.glassFill,
              border: const OutlineInputBorder(
                borderRadius: SanctumRadii.mdAll,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: SanctumSpacing.lg),
          SanctumButton(
            label: 'Complete ritual',
            icon: Icons.auto_awesome,
            expand: true,
            // Enabled only once every step is ticked: the steps are the
            // ritual, and a "complete" button that works without them
            // quietly teaches people to skip it.
            onPressed: _allStepsDone ? _complete : null,
          ),
          if (!_allStepsDone) ...[
            const SizedBox(height: SanctumSpacing.sm),
            Text(
              'Work through each step first.',
              textAlign: TextAlign.center,
              style: type.caption,
            ),
          ],
        ],
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.text,
    required this.done,
    required this.onToggle,
  });

  final int index;
  final String text;
  final bool done;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return Semantics(
      checked: done,
      button: true,
      child: GlassCard.flat(
        onTap: onToggle,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: SanctumMotion.quick,
              curve: SanctumMotion.ease,
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? colors.gold.withValues(alpha: 0.9)
                    : Colors.transparent,
                border: Border.all(
                  color: done ? colors.gold : colors.glassBorder,
                ),
              ),
              child: done
                  ? Icon(Icons.check, size: 16, color: colors.textOnAccent)
                  : Text('$index', style: type.caption),
            ),
            const SizedBox(width: SanctumSpacing.md),
            Expanded(
              child: AnimatedOpacity(
                duration: SanctumMotion.quick,
                opacity: done ? 0.55 : 1,
                child: Text(text, style: type.bodyMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down),
        color: context.colors.textSecondary,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
