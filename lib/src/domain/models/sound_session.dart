import 'package:dart_mappable/dart_mappable.dart';

part 'sound_session.mapper.dart';

/// The energy centre a session is associated with.
@MappableEnum()
enum Chakra {
  /// Base, grounding.
  root('Root'),

  /// Creativity, feeling.
  sacral('Sacral'),

  /// Will, self-trust.
  solarPlexus('Solar Plexus'),

  /// Compassion, connection.
  heart('Heart'),

  /// Expression, truth.
  throat('Throat'),

  /// Insight.
  thirdEye('Third Eye'),

  /// Spaciousness.
  crown('Crown');

  const Chakra(this.displayName);

  /// Human-readable name.
  final String displayName;
}

/// A sound-bath session.
///
/// Note the field is [intention], not "benefit". These are traditional
/// associations, and the copy throughout the app frames them as something
/// to sit with rather than as a health outcome — which is both honest and
/// what keeps the listing clear of medical-claim review problems.
@MappableClass()
class SoundSession with SoundSessionMappable {
  /// Creates a session.
  const SoundSession({
    required this.id,
    required this.title,
    required this.frequencyHz,
    required this.frequencyLabel,
    required this.intention,
    required this.durationSeconds,
    required this.chakra,
  });

  /// Stable catalogue id.
  final String id;

  /// Display title.
  final String title;

  /// The tone generated, in hertz.
  final double frequencyHz;

  /// Pre-formatted label, so the UI never has to decide how many decimal
  /// places 136.1 needs.
  final String frequencyLabel;

  /// What the session invites, in one line.
  final String intention;

  /// Full length in seconds.
  final int durationSeconds;

  /// Associated energy centre.
  final Chakra chakra;

  /// Length as a [Duration].
  Duration get duration => Duration(seconds: durationSeconds);

  /// e.g. "20 min".
  String get durationLabel => '${(durationSeconds / 60).round()} min';
}
