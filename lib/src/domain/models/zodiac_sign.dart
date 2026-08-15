import 'package:dart_mappable/dart_mappable.dart';

part 'zodiac_sign.mapper.dart';

/// The classical elements, used for compatibility and for tone.
@MappableEnum()
enum ZodiacElement {
  /// Fire.
  fire('Fire'),

  /// Earth.
  earth('Earth'),

  /// Air.
  air('Air'),

  /// Water.
  water('Water');

  const ZodiacElement(this.displayName);

  /// Human-readable name.
  final String displayName;
}

/// The twelve sun signs.
@MappableEnum()
enum ZodiacSign {
  /// Aries.
  aries('Aries', ZodiacElement.fire, '♈'),

  /// Taurus.
  taurus('Taurus', ZodiacElement.earth, '♉'),

  /// Gemini.
  gemini('Gemini', ZodiacElement.air, '♊'),

  /// Cancer.
  cancer('Cancer', ZodiacElement.water, '♋'),

  /// Leo.
  leo('Leo', ZodiacElement.fire, '♌'),

  /// Virgo.
  virgo('Virgo', ZodiacElement.earth, '♍'),

  /// Libra.
  libra('Libra', ZodiacElement.air, '♎'),

  /// Scorpio.
  scorpio('Scorpio', ZodiacElement.water, '♏'),

  /// Sagittarius.
  sagittarius('Sagittarius', ZodiacElement.fire, '♐'),

  /// Capricorn.
  capricorn('Capricorn', ZodiacElement.earth, '♑'),

  /// Aquarius.
  aquarius('Aquarius', ZodiacElement.air, '♒'),

  /// Pisces.
  pisces('Pisces', ZodiacElement.water, '♓');

  const ZodiacSign(this.displayName, this.element, this.glyph);

  /// Human-readable name.
  final String displayName;

  /// Its element.
  final ZodiacElement element;

  /// The astrological glyph, U+2648–2653.
  ///
  /// Must be drawn with the `SanctumSymbols` family — see
  /// `SanctumTypography.symbol`. Left to the platform default, both iOS
  /// and Android resolve these through their emoji font and draw them as
  /// coloured tiles: inconsistent across platforms and wrong against our
  /// type either way. A variation selector does not reliably override
  /// that, which is why the font is bundled instead.
  final String glyph;
}
