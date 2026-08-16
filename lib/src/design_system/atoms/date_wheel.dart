import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';

/// Month / day / year picker wheels.
///
/// Extracted from the onboarding quiz so the compatibility flow asks for
/// a birth date exactly the way onboarding does. Two pickers that differ
/// slightly is the kind of thing nobody reports and everybody feels.
///
/// Deliberately free of any zodiac knowledge: it emits a [DateTime] and
/// nothing else, which is what keeps the design system independent of
/// the domain layer.
class BirthDateWheels extends StatelessWidget {
  /// Creates the wheels.
  const BirthDateWheels({
    required this.date,
    required this.onChanged,
    this.minimumAge = 13,
    this.span = 90,
    super.key,
  });

  /// The currently selected date.
  final DateTime date;

  /// Called with each change.
  final ValueChanged<DateTime> onChanged;

  /// Youngest selectable age, in years.
  final int minimumAge;

  /// How many years the year wheel offers.
  final int span;

  static const _months = [
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(span, (i) => now.year - minimumAge - i);
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _Wheel(
            count: 12,
            initial: date.month - 1,
            label: (i) => _months[i],
            onSelected: (i) => onChanged(
              // Clamp the day, or scrolling from 31 January to February
              // silently rolls the date into March.
              DateTime(
                date.year,
                i + 1,
                date.day.clamp(1, DateTime(date.year, i + 2, 0).day),
              ),
            ),
          ),
        ),
        Expanded(
          child: _Wheel(
            count: daysInMonth,
            initial: date.day - 1,
            label: (i) => '${i + 1}',
            onSelected: (i) => onChanged(
              DateTime(date.year, date.month, i + 1),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: _Wheel(
            count: years.length,
            initial: years.indexOf(date.year).clamp(0, years.length - 1),
            label: (i) => '${years[i]}',
            onSelected: (i) => onChanged(
              DateTime(years[i], date.month, date.day),
            ),
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
