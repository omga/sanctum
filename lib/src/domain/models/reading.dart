import 'package:sanctum/src/domain/models/zodiac_sign.dart';

/// The reading shown at the end of onboarding.
class Reading {
  /// Creates a reading.
  const Reading({
    required this.sign,
    required this.opening,
    required this.hasBirthDate,
    this.name,
    this.recognition,
    this.intention,
    this.closing,
  });

  /// What to call them, if they said.
  final String? name;

  /// Their sun sign.
  final ZodiacSign sign;

  /// Whether [sign] came from a real birth date rather than a fallback.
  ///
  /// Guards against presenting a default as though it were theirs — the
  /// one thing that would make the whole screen a lie.
  final bool hasBirthDate;

  /// Element-led opening line.
  final String opening;

  /// The heaviest thing they admitted, named back.
  final String? recognition;

  /// What the app will do about it.
  final String? intention;

  /// Their own commitment, quoted back.
  final String? closing;

  /// The line used on the shareable card.
  ///
  /// Short enough to read at a glance in someone's feed.
  String get shareLine => recognition ?? opening;

  /// Headline, addressed to them where possible.
  String get headline {
    final who = name;
    return who == null
        ? 'You are ${_article(sign.displayName)} ${sign.displayName}.'
        : '$who, you are ${_article(sign.displayName)} '
              '${sign.displayName}.';
  }

  static String _article(String word) =>
      'AEIOU'.contains(word[0].toUpperCase()) ? 'an' : 'a';
}
