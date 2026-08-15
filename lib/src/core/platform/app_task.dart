import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Leaving the app without killing it.
///
/// `SystemNavigator.pop()` finishes the activity, which on Android tears
/// down the Flutter engine — and with it the audio handler and the
/// player. For an app whose sessions are meant to outlive the UI, that
/// is the wrong kind of "leave": the dialog promises the session keeps
/// playing and then silently ends it.
///
/// Backgrounding the task keeps the engine and the foreground service
/// alive, exactly as pressing Home does.
abstract final class AppTask {
  static const _channel = MethodChannel('sanctum/app');

  /// Sends the app to the background, leaving playback running.
  ///
  /// Android only. Elsewhere this falls back to a normal pop, since iOS
  /// has no supported way to background an app programmatically — and
  /// does not need one, as its back gesture never exits the app.
  static Future<void> moveToBackground() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      await SystemNavigator.pop();
      return;
    }
    await _channel.invokeMethod<void>('moveToBackground');
  }

  /// Actually leaves the app.
  static Future<void> exit() => SystemNavigator.pop();
}
