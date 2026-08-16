import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// One scheduled daily reading.
class Reminder {
  /// Creates a reminder.
  const Reminder({
    required this.at,
    required this.title,
    required this.body,
  });

  /// Local time it should fire.
  final DateTime at;

  /// Notification title.
  final String title;

  /// Notification body — the actual reading for that day.
  final String body;
}

/// Schedules the daily reading.
abstract interface class ReminderService {
  /// Asks the OS for permission. `false` if the user declined.
  Future<Result<bool>> requestPermission();

  /// Replaces every pending reminder with [reminders].
  Future<Result<void>> replaceAll(List<Reminder> reminders);

  /// Cancels everything pending.
  Future<Result<void>> cancelAll();
}

/// A reminder service backed by `flutter_local_notifications`.
///
/// ## Why the notification carries the whole reading
///
/// Nothing of ours runs when a notification fires — there is no
/// background isolate, and adding one to compute a sentence would be
/// absurd. So each day's transit line is composed *now* and travels with
/// the scheduled notification. That is why the queue is rewritten on
/// every launch: the copy is a week-old snapshot, and refreshing it
/// costs one cancel and seven schedules.
///
/// ## Why the alarms are inexact
///
/// Exact alarms on Android need `SCHEDULE_EXACT_ALARM`, which needs a
/// Play Console policy declaration, and Google rejects apps that ask for
/// it without an alarm-clock-grade justification. A reading that arrives
/// at 08:07 instead of 08:00 is indistinguishable to the user, so this
/// uses `inexactAllowWhileIdle` and the permission never comes up.
class LocalNotificationReminderService implements ReminderService {
  /// Creates a service around a notifications plugin.
  LocalNotificationReminderService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'sanctum.daily_reading';
  static const _channelName = 'Daily reading';

  bool _ready = false;

  Future<void> _ensureInitialised() async {
    if (_ready) return;

    tz_data.initializeTimeZones();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // All false: permission is requested explicitly, at a moment we
        // choose, rather than by a dialog appearing on first launch
        // before the user knows what the app is.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  @override
  Future<Result<bool>> requestPermission() {
    return Result.guard(
      () async {
        await _ensureInitialised();

        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        if (ios != null) {
          return await ios.requestPermissions(alert: true, sound: true) ??
              false;
        }

        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (android != null) {
          return await android.requestNotificationsPermission() ?? false;
        }

        return false;
      },
      onError: (error, stackTrace) => UnexpectedFailure(
        'Could not ask for notification permission',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> replaceAll(List<Reminder> reminders) {
    return Result.guard(
      () async {
        await _ensureInitialised();
        await _plugin.cancelAll();

        for (final (index, reminder) in reminders.indexed) {
          // Converted to an absolute UTC instant rather than scheduled
          // against a named zone. The offset is taken now, so a user who
          // crosses a DST boundary without opening the app sees their
          // reading drift by an hour until the next launch rewrites the
          // queue. That is the trade for not carrying a timezone-name
          // dependency, and an hour on a reading is not a defect worth
          // paying for.
          await _plugin.zonedSchedule(
            id: index,
            title: reminder.title,
            body: reminder.body,
            scheduledDate: tz.TZDateTime.from(reminder.at, tz.UTC),
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                _channelId,
                _channelName,
                channelDescription: 'Your reading, once a day.',
                styleInformation: BigTextStyleInformation(''),
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      },
      onError: (error, stackTrace) => UnexpectedFailure(
        'Could not schedule your reading',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<Result<void>> cancelAll() {
    return Result.guard(
      () async {
        await _ensureInitialised();
        await _plugin.cancelAll();
      },
      onError: (error, stackTrace) => UnexpectedFailure(
        'Could not clear your reminders',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
