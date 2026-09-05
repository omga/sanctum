import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';

part 'advisor_consent_view_model.g.dart';

/// Records the answer given on the consent screen.
///
/// ## Why the write lives here and the read lives in `data_providers`
///
/// The same split `LanguageController` uses: one provider anybody may
/// watch, one notifier that writes and then invalidates it. Settings
/// reaches across to this notifier rather than growing a second writer,
/// because consent is one decision and two places that can save it is
/// how the two disagree.
///
/// ## Why `keepAlive`
///
/// It is called as `ref.read(...notifier).decline()` from a screen that
/// pops in the same frame, and reading a notifier registers no
/// listener — an auto-disposing provider would be collected while the
/// write was still in flight and resume on a dead `Ref`. That exact
/// crash is recorded on `LanguageController`; this one holds a notifier
/// and no state, so the cost of avoiding it is nothing.
@Riverpod(keepAlive: true)
class AdvisorConsentController extends _$AdvisorConsentController {
  @override
  FutureOr<void> build() {}

  /// Agrees to the disclosure, and lets the advisor send.
  Future<bool> grant() => _record(granted: true);

  /// Says no, and records that it was a no rather than a silence.
  Future<bool> decline() => _record(granted: false);

  /// Withdraws a consent already given.
  ///
  /// The same write as [decline]. It is named separately because the
  /// two are different acts to the person doing them — one is an answer
  /// to a question, the other is taking something back — and a call
  /// site that says `withdraw()` is readable where `decline()` from a
  /// settings screen is not.
  Future<bool> withdraw() => _record(granted: false);

  Future<bool> _record({required bool granted}) async {
    final saved = await ref
        .read(settingsRepositoryProvider)
        .recordAdvisorConsent(granted: granted);

    if (saved case Err(:final failure)) {
      state = AsyncError(failure, StackTrace.current);
      return false;
    }

    ref.invalidate(advisorConsentProvider);
    return true;
  }
}
