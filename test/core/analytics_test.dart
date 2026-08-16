import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/analytics/analytics_event.dart';
import 'package:sanctum/src/core/analytics/analytics_service.dart';

/// One of every event the app can emit.
///
/// New events must be added here. That is the point: the guarantees
/// below are only worth anything if the list is exhaustive, and a
/// contributor who adds an event without adding it here gets no
/// protection from the checks that follow.
final _everyEvent = <AnalyticsEvent>[
  const AnalyticsEvent.onboardingShown(),
  const AnalyticsEvent.quizStarted(),
  AnalyticsEvent.quizQuestionShown(questionId: 'goals', index: 1),
  AnalyticsEvent.quizQuestionAnswered(questionId: 'goals', index: 1),
  AnalyticsEvent.quizCompleted(answered: 8),
  const AnalyticsEvent.payoffShown(),
  const AnalyticsEvent.payoffShared(),
  const AnalyticsEvent.reminderPermissionAsked(),
  AnalyticsEvent.reminderPermissionResolved(granted: true),
  AnalyticsEvent.paywallShown(moment: 'lockedContent'),
  AnalyticsEvent.paywallDismissed(moment: 'lockedContent'),
  AnalyticsEvent.purchaseStarted(plan: 'yearly'),
  AnalyticsEvent.purchaseCompleted(plan: 'yearly'),
  AnalyticsEvent.matchStarted(source: 'celebrity'),
  const AnalyticsEvent.matchInviteSent(),
  AnalyticsEvent.matchRevealed(access: 'needsInvite'),
  const AnalyticsEvent.matchShared(),
  const AnalyticsEvent.cardRevealed(),
  AnalyticsEvent.energyCheckedIn(level: 'radiant'),
  AnalyticsEvent.sessionStarted(sessionId: 'tone-528'),
  AnalyticsEvent.ritualCompleted(phase: 'fullMoon'),
  AnalyticsEvent.journalEntrySaved(lengthBucket: 2),
];

/// Property names that would mean something personal had escaped.
const _forbiddenKeys = {
  'name',
  'first_name',
  'user_name',
  'birth_date',
  'birthdate',
  'dob',
  'sign',
  'zodiac',
  'text',
  'body',
  'note',
  'entry',
  'answer',
  'email',
  'partner',
  'partner_name',
  'query',
};

void main() {
  group('the event taxonomy', () {
    test('has no duplicate names', () {
      final names = [for (final event in _everyEvent) event.name];
      expect(
        names.toSet(),
        hasLength(names.length),
        reason: 'two events reporting under one name silently merge',
      );
    });

    test('uses snake_case throughout', () {
      for (final event in _everyEvent) {
        expect(
          event.name,
          matches(RegExp(r'^[a-z][a-z0-9_]*$')),
          reason: event.name,
        );
        for (final key in event.properties.keys) {
          expect(key, matches(RegExp(r'^[a-z][a-z0-9_]*$')), reason: key);
        }
      }
    });

    test('carries only primitives', () {
      // An object property means somebody serialised a model into an
      // event, which is how a journal entry ends up on a dashboard.
      for (final event in _everyEvent) {
        for (final value in event.properties.values) {
          expect(
            value is String || value is int || value is bool,
            isTrue,
            reason: '${event.name} carries a ${value.runtimeType}',
          );
        }
      }
    });
  });

  group('the privacy promise', () {
    test('no event carries a property that could identify anyone', () {
      // The app tells users their name, birth date and journal stay on
      // the phone. This is the test that keeps that true as the app
      // grows, rather than a sentence in a review checklist.
      for (final event in _everyEvent) {
        for (final key in event.properties.keys) {
          expect(
            _forbiddenKeys,
            isNot(contains(key)),
            reason: '${event.name} would send "$key" off the device',
          );
        }
      }
    });

    test('no event carries a long free-text value', () {
      // Ids and enum names are short and come from bundled content.
      // Anything long is prose, and prose is the user's.
      for (final event in _everyEvent) {
        for (final value in event.properties.values) {
          if (value is! String) continue;
          expect(
            value.length,
            lessThan(40),
            reason: '${event.name} carries something prose-shaped',
          );
        }
      }
    });

    test('the star sign is not reported', () {
      // Derived straight from the birth date we promised stays local,
      // and no decision would change based on it.
      for (final event in _everyEvent) {
        expect(event.properties.keys, isNot(contains('sign')));
      }
    });
  });

  group('services', () {
    test('the recorder keeps order', () {
      final analytics = RecordingAnalyticsService()
        ..track(const AnalyticsEvent.quizStarted())
        ..track(const AnalyticsEvent.payoffShown());

      expect(analytics.names, ['quiz_started', 'payoff_shown']);
    });

    test('the no-op swallows everything without throwing', () {
      const analytics = NoopAnalyticsService();
      for (final event in _everyEvent) {
        expect(() => analytics.track(event), returnsNormally);
      }
    });

    test('events render readably for the log', () {
      expect(
        AnalyticsEvent.quizQuestionShown(
          questionId: 'goals',
          index: 1,
        ).toString(),
        'quiz_question_shown question_id=goals index=1',
      );
      expect(const AnalyticsEvent.quizStarted().toString(), 'quiz_started');
    });
  });
}
