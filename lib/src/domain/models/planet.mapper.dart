// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'planet.dart';

class PlanetMapper extends EnumMapper<Planet> {
  PlanetMapper._();

  static PlanetMapper? _instance;
  static PlanetMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlanetMapper._());
    }
    return _instance!;
  }

  static Planet fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  Planet decode(dynamic value) {
    switch (value) {
      case r'sun':
        return Planet.sun;
      case r'mercury':
        return Planet.mercury;
      case r'venus':
        return Planet.venus;
      case r'mars':
        return Planet.mars;
      case r'jupiter':
        return Planet.jupiter;
      case r'saturn':
        return Planet.saturn;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(Planet self) {
    switch (self) {
      case Planet.sun:
        return r'sun';
      case Planet.mercury:
        return r'mercury';
      case Planet.venus:
        return r'venus';
      case Planet.mars:
        return r'mars';
      case Planet.jupiter:
        return r'jupiter';
      case Planet.saturn:
        return r'saturn';
    }
  }
}

extension PlanetMapperExtension on Planet {
  String toValue() {
    PlanetMapper.ensureInitialized();
    return MapperContainer.globals.toValue<Planet>(this) as String;
  }
}

