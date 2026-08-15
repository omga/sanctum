import 'package:flutter/widgets.dart';

/// Corner radii.
///
/// Sanctum leans soft and round — sharp corners read as utilitarian,
/// which is the opposite of the feeling this app is selling.
abstract final class SanctumRadii {
  /// 8pt — chips and small controls.
  static const double sm = 8;

  /// 14pt — buttons and inputs.
  static const double md = 14;

  /// 22pt — cards.
  static const double lg = 22;

  /// 32pt — sheets and hero surfaces.
  static const double xl = 32;

  /// Fully rounded. Use for pills and circular controls.
  static const double pill = 999;

  /// [BorderRadius] for small controls.
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));

  /// [BorderRadius] for buttons and inputs.
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));

  /// [BorderRadius] for cards.
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));

  /// [BorderRadius] for sheets.
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));

  /// [BorderRadius] for pills.
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}
