import 'package:dart_mappable/dart_mappable.dart';
import 'package:sanctum/src/domain/models/moon_phase.dart';

part 'ritual.mapper.dart';

/// A guided moon ritual.
@MappableClass()
class Ritual with RitualMappable {
  /// Creates a ritual.
  const Ritual({
    required this.id,
    required this.moon,
    required this.title,
    required this.phase,
    required this.opening,
    required this.steps,
  });

  /// Stable catalogue id.
  final String id;

  /// The moon this belongs to, as a display string.
  final String moon;

  /// Ritual title.
  final String title;

  /// The phase that unlocks it.
  final MoonPhase phase;

  /// The opening line, setting the tone.
  final String opening;

  /// Ordered steps.
  final List<String> steps;
}
