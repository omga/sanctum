import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';

part 'settings_view_model.g.dart';

/// Changes the language the whole app is read in.
///
/// ## Why this invalidates rather than rebuilds
///
/// Two trees have to move together. `MaterialApp` re-resolves its own
/// locale when [contentLocaleProvider] changes, which swaps the ARB
/// strings; the content catalogue is a *cached future* over an asset
/// bundle and would happily keep serving the old language's JSON. So the
/// preference is invalidated and the catalogue chain re-runs from the
/// asset read — chrome and readings change in the same frame, which is
/// the invariant `SanctumLocales` exists to protect.
///
/// ## Why `keepAlive`, and not the obvious auto-dispose
///
/// This is called as `ref.read(...notifier).choose(code)`, and reading a
/// notifier registers **no listener** — so an auto-disposing provider is
/// collected at the end of the frame, while [choose] is still awaiting
/// the write. It then resumes on a dead `Ref` and throws *Cannot use the
/// Ref of languageControllerProvider after it has been disposed*, which
/// is what this did on Android; on iOS the same race simply lost more
/// often.
///
/// Guarding with `ref.mounted` would stop the crash and silently skip
/// the invalidate, leaving the preference saved and the app still in the
/// old language — the failure mode that is hardest to report. The work
/// has to outlive the screen that started it, so the provider does too.
/// It holds one notifier and no state; the cost is nothing.
@Riverpod(keepAlive: true)
class LanguageController extends _$LanguageController {
  @override
  FutureOr<void> build() {}

  /// Switches to [code], or back to following the device when null.
  ///
  /// Returns whether it was saved. A failure leaves the app in the
  /// language it was already in, which is the harmless outcome — the
  /// alternative is chrome in one language and readings in another.
  Future<bool> choose(String? code) async {
    final saved = await ref
        .read(settingsRepositoryProvider)
        .setPreferredLanguage(code);

    if (saved case Err(:final failure)) {
      state = AsyncError(failure, StackTrace.current);
      return false;
    }

    ref.invalidate(languagePreferenceProvider);
    return true;
  }
}
