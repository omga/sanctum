// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'zodiac_sign.dart';

class ZodiacElementMapper extends EnumMapper<ZodiacElement> {
  ZodiacElementMapper._();

  static ZodiacElementMapper? _instance;
  static ZodiacElementMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ZodiacElementMapper._());
    }
    return _instance!;
  }

  static ZodiacElement fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ZodiacElement decode(dynamic value) {
    switch (value) {
      case r'fire':
        return ZodiacElement.fire;
      case r'earth':
        return ZodiacElement.earth;
      case r'air':
        return ZodiacElement.air;
      case r'water':
        return ZodiacElement.water;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ZodiacElement self) {
    switch (self) {
      case ZodiacElement.fire:
        return r'fire';
      case ZodiacElement.earth:
        return r'earth';
      case ZodiacElement.air:
        return r'air';
      case ZodiacElement.water:
        return r'water';
    }
  }
}

extension ZodiacElementMapperExtension on ZodiacElement {
  String toValue() {
    ZodiacElementMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ZodiacElement>(this) as String;
  }
}

class ZodiacSignMapper extends EnumMapper<ZodiacSign> {
  ZodiacSignMapper._();

  static ZodiacSignMapper? _instance;
  static ZodiacSignMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ZodiacSignMapper._());
    }
    return _instance!;
  }

  static ZodiacSign fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ZodiacSign decode(dynamic value) {
    switch (value) {
      case r'aries':
        return ZodiacSign.aries;
      case r'taurus':
        return ZodiacSign.taurus;
      case r'gemini':
        return ZodiacSign.gemini;
      case r'cancer':
        return ZodiacSign.cancer;
      case r'leo':
        return ZodiacSign.leo;
      case r'virgo':
        return ZodiacSign.virgo;
      case r'libra':
        return ZodiacSign.libra;
      case r'scorpio':
        return ZodiacSign.scorpio;
      case r'sagittarius':
        return ZodiacSign.sagittarius;
      case r'capricorn':
        return ZodiacSign.capricorn;
      case r'aquarius':
        return ZodiacSign.aquarius;
      case r'pisces':
        return ZodiacSign.pisces;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ZodiacSign self) {
    switch (self) {
      case ZodiacSign.aries:
        return r'aries';
      case ZodiacSign.taurus:
        return r'taurus';
      case ZodiacSign.gemini:
        return r'gemini';
      case ZodiacSign.cancer:
        return r'cancer';
      case ZodiacSign.leo:
        return r'leo';
      case ZodiacSign.virgo:
        return r'virgo';
      case ZodiacSign.libra:
        return r'libra';
      case ZodiacSign.scorpio:
        return r'scorpio';
      case ZodiacSign.sagittarius:
        return r'sagittarius';
      case ZodiacSign.capricorn:
        return r'capricorn';
      case ZodiacSign.aquarius:
        return r'aquarius';
      case ZodiacSign.pisces:
        return r'pisces';
    }
  }
}

extension ZodiacSignMapperExtension on ZodiacSign {
  String toValue() {
    ZodiacSignMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ZodiacSign>(this) as String;
  }
}

