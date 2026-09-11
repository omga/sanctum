import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the manifest entries that fail silently when they are absent.
///
/// ## Why a test reads an XML file
///
/// Because the failure has no other detector. `flutter_local_notifications`
/// stopped declaring its own receivers at version 16 — its manifest now
/// carries `POST_NOTIFICATIONS` and `VIBRATE` and nothing else — so every
/// app must declare them. Miss them and `zonedSchedule` still succeeds,
/// no `Result` fails, nothing is logged, and the alarm fires into a
/// broadcast that resolves to no component. The only symptom is that no
/// notification ever arrives, on a real device, days later.
///
/// Nothing in the Dart layer can observe that, which is exactly why it
/// survived a full build of the reminders feature and its unit tests.
/// The cheapest available guard is to assert the strings are present.
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  group('the Android manifest declares what fails silently', () {
    test('the alarm receiver that posts a scheduled notification', () {
      expect(
        manifest,
        contains(
          'com.dexterous.flutterlocalnotifications.'
          'ScheduledNotificationReceiver',
        ),
      );
    });

    test('the boot receiver that restores the queue after a restart', () {
      expect(
        manifest,
        contains(
          'com.dexterous.flutterlocalnotifications.'
          'ScheduledNotificationBootReceiver',
        ),
      );
      expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
      expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
    });

    test('the runtime permission the notification needs to be posted', () {
      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    });

    test('exact alarms are still not asked for', () {
      // `handoff.md`: the reminders schedule inexactly on purpose, and
      // either exact-alarm permission drags in a Play Console policy
      // declaration. If one appears here, it was added by somebody
      // "fixing" notifications without reading why they were broken.
      // Matched as a declaration rather than as a word: the manifest
      // comment names SCHEDULE_EXACT_ALARM in order to say it is
      // deliberately absent, and a bare substring check fails on the
      // explanation rather than on the permission.
      expect(
        manifest,
        isNot(
          contains(
            'android:name="android.permission.'
            'SCHEDULE_EXACT_ALARM"',
          ),
        ),
      );
      expect(
        manifest,
        isNot(
          contains(
            'android:name="android.permission.'
            'USE_EXACT_ALARM"',
          ),
        ),
      );
    });

    test('the camera the palm scan opens', () {
      expect(
        manifest,
        contains('android:name="android.permission.CAMERA"'),
      );
    });

    test('and not the microphone the camera plugin drags in', () {
      // camera_android_camerax declares RECORD_AUDIO. Losing this removal
      // is silent: nothing misbehaves, no test fails, and "Microphone"
      // appears on the Play listing of an app whose whole claim is that
      // nothing leaves the device.
      expect(
        manifest,
        matches(
          RegExp(
            r'<uses-permission\s+android:name="android\.permission\.'
            r'RECORD_AUDIO"\s+tools:node="remove"\s*/>',
          ),
        ),
      );
    });

    test('nor the read access the merger implies from it', () {
      // Nobody declares READ_EXTERNAL_STORAGE: the merger implies it from
      // camerax's WRITE request, off the plugin's own declaration, so it
      // appears whatever this manifest does with WRITE.
      expect(
        manifest,
        matches(
          RegExp(
            r'<uses-permission\s+android:name="android\.permission\.'
            r'READ_EXTERNAL_STORAGE"\s+tools:node="remove"\s*/>',
          ),
        ),
      );
    });

    test('write access for Save, and only on Android 10 and below', () {
      // Needed by the gallery save on API 29 and lower, which minSdk 24
      // includes. Uncapped, it would be requested on every Android
      // version for no reason; removed, Save fails on the older ones.
      final write = RegExp(
        r'<uses-permission\s+android:name="android\.permission\.'
        'WRITE_EXTERNAL_STORAGE"([^>]*)/>',
      ).firstMatch(manifest);

      expect(write, isNotNull);
      expect(write!.group(1), contains('android:maxSdkVersion="29"'));
      expect(write.group(1), isNot(contains('tools:node="remove"')));
    });

    test('the audio service and its media button receiver', () {
      // Same class of defect, already paid for once: the missing
      // service produced "Unable to start service … AudioService: not
      // found" and silent playback.
      expect(manifest, contains('com.ryanheise.audioservice.AudioService'));
      expect(
        manifest,
        contains('com.ryanheise.audioservice.MediaButtonReceiver'),
      );
    });
  });
}
