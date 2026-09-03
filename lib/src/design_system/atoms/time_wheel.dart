import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/l10n/l10n.dart';

/// Hour / minute picker wheels.
///
/// The sibling of `BirthDateWheels`, and deliberately built the same
/// way: the birth time is asked for in three different places, and a
/// picker that behaves differently in one of them is the kind of thing
/// nobody reports and everybody feels.
///
/// Like the date wheels it knows no astrology — it emits minutes since
/// midnight and nothing else, which is what keeps the design system
/// independent of the domain layer.
///
/// Minutes step in fives. Nobody knows the minute of their birth to
/// better than that, a 60-item wheel is a long scroll for a number that
/// moves the Moon by a fifth of a degree, and offering the precision
/// implies we can use it.
class BirthTimeWheels extends StatelessWidget {
  /// Creates the wheels.
  const BirthTimeWheels({
    required this.minuteOfDay,
    required this.onChanged,
    super.key,
  });

  /// Currently selected minutes since midnight, `0`–`1439`.
  final int minuteOfDay;

  /// Called with each change, in minutes since midnight.
  final ValueChanged<int> onChanged;

  /// Granularity of the minute wheel.
  static const int step = 5;

  @override
  Widget build(BuildContext context) {
    final hour = minuteOfDay ~/ 60;
    final minute = minuteOfDay % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          child: _Wheel(
            count: 24,
            initial: hour,
            label: (i) => i.toString().padLeft(2, '0'),
            onSelected: (i) => onChanged(i * 60 + minute),
          ),
        ),
        Text(':', style: context.type.displaySmall),
        SizedBox(
          width: 80,
          child: _Wheel(
            count: 60 ~/ step,
            initial: minute ~/ step,
            label: (i) => (i * step).toString().padLeft(2, '0'),
            onSelected: (i) => onChanged(hour * 60 + i * step),
          ),
        ),
      ],
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.count,
    required this.initial,
    required this.label,
    required this.onSelected,
  });

  final int count;
  final int initial;
  final String Function(int) label;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListWheelScrollView.useDelegate(
      controller: FixedExtentScrollController(initialItem: initial),
      itemExtent: 40,
      perspective: 0.004,
      diameterRatio: 1.6,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) => Center(
          child: Text(
            label(index),
            style: context.type.bodyLarge.copyWith(
              color: index == initial
                  ? colors.textPrimary
                  : colors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

/// A birth time, or an explicit "I do not know".
///
/// The whole control rather than just the wheels, because the birth time
/// is asked for in three places — onboarding, the partner entry screen
/// and the person picker — and all three need the same two-state
/// behaviour. Duplicating the toggle three times is how they drift.
///
/// ## Why "I do not know" is a first-class answer, not a skip
///
/// Most people do not know what time they were born, and an app that
/// treats that as an unanswered question re-asks it forever. Worse, the
/// obvious shortcut — defaulting the wheels to 12:00 and letting the
/// user press Continue — records a *precise* time the user never gave,
/// and nothing downstream can tell it apart from one they did.
///
/// So the control starts unknown and the user opts in. Nothing is
/// recorded as a time unless somebody actually set it.
///
/// Emits minutes since midnight, or null for unknown, so the design
/// system stays free of the domain's `BirthTime`.
class BirthTimeField extends StatelessWidget {
  /// Creates the field.
  const BirthTimeField({
    required this.minuteOfDay,
    required this.onChanged,
    this.unknownLabel,
    super.key,
  });

  /// Minutes since midnight, or null when unknown.
  final int? minuteOfDay;

  /// Called with the new value, null meaning unknown.
  final ValueChanged<int?> onChanged;

  /// Copy for the "unknown" side of the toggle.
  ///
  /// Nullable because the default is localised, and a default parameter
  /// value must be a compile-time constant.
  final String? unknownLabel;

  /// Where the wheels start when the user opts in.
  ///
  /// Not midnight: 00:00 is a plausible birth time, so a wheel resting
  /// there cannot be told from a deliberate answer. Morning is both the
  /// commonest hour to be born and obviously a starting point.
  static const int defaultMinuteOfDay = 9 * 60;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final l10n = context.l10n;
    final known = minuteOfDay != null;

    return Column(
      children: [
        if (known)
          SizedBox(
            height: 150,
            child: BirthTimeWheels(
              minuteOfDay: minuteOfDay!,
              onChanged: onChanged,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: SanctumSpacing.lg,
            ),
            child: Text(
              l10n.birthTimeWithoutMoon,
              textAlign: TextAlign.center,
              style: type.bodyMedium.copyWith(color: colors.textTertiary),
            ),
          ),
        const SizedBox(height: SanctumSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.glassFill,
            borderRadius: SanctumRadii.mdAll,
          ),
          child: Row(
            children: [
              Expanded(
                child: _Segment(
                  label: unknownLabel ?? l10n.birthTimeUnknown,
                  selected: !known,
                  onTap: () => onChanged(null),
                ),
              ),
              Expanded(
                child: _Segment(
                  label: l10n.birthTimeKnown,
                  selected: known,
                  onTap: () => onChanged(minuteOfDay ?? defaultMinuteOfDay),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: SanctumSpacing.md),
        decoration: BoxDecoration(
          color: selected ? colors.gold.withValues(alpha: 0.16) : null,
          borderRadius: SanctumRadii.mdAll,
          border: Border.all(
            color: selected ? colors.gold : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: context.type.bodyMedium.copyWith(
            color: selected ? colors.textPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
