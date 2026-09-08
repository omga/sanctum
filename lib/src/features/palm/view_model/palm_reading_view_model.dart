import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/domain/services/palm_gate.dart';

part 'palm_reading_view_model.g.dart';

/// Whether the reading for [scanId] may be shown.
///
/// Reads storage rather than taking the answer from the scan, because
/// the allowance is spent across scans: what decides this reading is
/// what the user has already read and already shared, not anything about
/// the hand in front of the camera.
@riverpod
Future<PalmReadingAccess> palmReadingAccess(Ref ref, String scanId) async {
  final repository = ref.watch(palmRepositoryProvider);
  final unlocked = await repository.unlockedReadings();
  final shared = await repository.hasSharedScan();

  return PalmGate.decide(
    scanId: scanId,
    unlockedIds: unlocked.getOrElse(const <String>{}),
    hasSharedScan: shared.getOrElse(false),
    isPremium: ref.watch(isPremiumProvider),
  );
}

/// How many free readings are left, for the copy that says so.
@riverpod
Future<int> palmReadingsRemaining(Ref ref) async {
  final unlocked = await ref.watch(palmRepositoryProvider).unlockedReadings();
  return PalmGate.readingsRemaining(
    unlockedIds: unlocked.getOrElse(const <String>{}),
    isPremium: ref.watch(isPremiumProvider),
  );
}

/// Spends and records what the gate hands out.
@riverpod
class PalmUnlockController extends _$PalmUnlockController {
  @override
  void build() {}

  /// Records a completed share.
  ///
  /// Called only when the share sheet reports success, which means an
  /// app was picked and nothing more — `ShareController.shareInvite`
  /// carries the full argument for why that is the strongest signal
  /// available and why the honest failure mode is the generous one.
  Future<void> recordShare() async {
    await ref.read(palmRepositoryProvider).recordShare();
    // The share sheet is a round trip through another app, and the
    // screen behind it can be gone by the time it returns.
    if (!ref.mounted) return;
    ref
      ..invalidate(palmReadingAccessProvider)
      ..invalidate(palmReadingsRemainingProvider);
  }

  /// Writes down that [scanId] has been opened.
  ///
  /// Called when the gate first says a reading may be shown, so that it
  /// stays shown. Without this, re-opening the reading a minute later
  /// would consume the allowance a second time and then ask for money
  /// for a screen the user has already read — the same bait and switch
  /// `CompatibilityGate` keeps its revealed set to avoid.
  ///
  /// Recorded for subscribers too. Their reading also stays open if the
  /// subscription lapses, which is the rule the gate documents: a scan
  /// is a particular hand on a particular day, and closing one is taking
  /// back a thing somebody earned.
  Future<void> keepOpen(String scanId) async {
    await ref.read(palmRepositoryProvider).recordUnlock(scanId);
    if (!ref.mounted) return;
    ref.invalidate(palmReadingsRemainingProvider);
  }
}
