import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/analytics/analytics_event.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/services/reminders/reminder_service.dart';
import 'package:sanctum/src/domain/models/quiz.dart';
import 'package:sanctum/src/domain/services/reminder_schedule.dart';
import 'package:sanctum/src/domain/services/transit_composer.dart';

part 'reminder_view_model.g.dart';

/// Keeps the queue of daily readings fresh.
///
/// ## Why this runs on every launch
///
/// Nothing of ours executes when a notification fires, so each day's
/// line has to be composed in advance and shipped with the scheduled
/// notification. That makes the queue a snapshot, and a snapshot goes
/// stale — so it is thrown away and rebuilt whenever the app opens,
/// which is cheap and means the copy is never more than one session old.
/// Kept alive deliberately, and this is not a performance choice.
///
/// Both callers are fire-and-forget — the shell schedules on launch and
/// the payoff screen asks for permission — so neither ever *watches*
/// this provider. Under the generated default (auto-dispose) that means
/// `ref.read(...notifier)` builds a notifier with no listeners, Riverpod
/// disposes it on the spot, and the `ref.read` calls inside the async
/// body below then throw `UnmountedRefException`. Nothing is scheduled,
/// nothing is shown, and the error reaches `ConsoleLogger` — which goes
/// to the VM service and not to logcat, so a release build says nothing
/// at all.
///
/// That is the third time this exact pattern has bitten this codebase;
/// see the gotchas in `handoff.md`. Scheduling is an app-lifetime
/// concern, not a screen-scoped one, so keepAlive is also simply the
/// correct answer.
@Riverpod(keepAlive: true)
class ReminderController extends _$ReminderController {
  @override
  FutureOr<void> build() {}

  /// Asks for permission and, if granted, fills the queue.
  ///
  /// Returns whether reminders are now scheduled. Called from the point
  /// in the product where the user has just been *told* what they are
  /// signing up for, never on a cold first launch — a permission dialog
  /// that appears before the app has earned anything gets declined once
  /// and then cannot be asked again.
  Future<bool> enable() async {
    final analytics = ref.read(analyticsProvider)
      ..track(const AnalyticsEvent.reminderPermissionAsked());

    final granted = await ref
        .read(reminderServiceProvider)
        .requestPermission();

    final allowed = granted.getOrElse(false);
    analytics.track(
      AnalyticsEvent.reminderPermissionResolved(granted: allowed),
    );
    if (!allowed) return false;

    await refresh();
    return true;
  }

  /// Rebuilds the queue from the current answers.
  ///
  /// Silent about failure on purpose: this runs on launch, and a user
  /// who has declined notifications must not be shown an error every
  /// time they open the app for a feature they turned off.
  Future<void> refresh() async {
    final answers = (await ref.read(quizRepositoryProvider).load())
        .getOrElse(const QuizAnswers());

    final birthDate = answers.dates['birth_date'];
    if (birthDate == null) return;

    final hour = ReminderSchedule.hourFor(
      answers.optionsFor('rhythm').firstOrNull,
    );

    final slots = ReminderSchedule.upcoming(
      from: ref.read(clockProvider).now(),
      hour: hour,
    );

    final name = answers.name;
    await ref.read(reminderServiceProvider).replaceAll([
      for (final slot in slots)
        Reminder(
          at: slot,
          // The title is the transit itself — "Mars presses on your
          // Saturn" — because on a lock screen the title is all most
          // people read, and a title that says "Sanctum" tells them
          // nothing they did not already know.
          title: _titleFor(birthDate, slot, name),
          body: TransitComposer.compose(
            birthDate: birthDate,
            day: slot,
          ).line,
        ),
    ]);
  }

  /// Stops sending them.
  Future<void> disable() async {
    await ref.read(reminderServiceProvider).cancelAll();
  }

  String _titleFor(DateTime birthDate, DateTime day, String? name) {
    final reading = TransitComposer.compose(
      birthDate: birthDate,
      day: day,
    );
    final transit = reading.transit;
    if (transit != null) return transit.headline;
    return name == null ? 'A quiet sky today' : '$name, a quiet sky today';
  }
}
