import 'package:sanctum/src/core/result/app_failure.dart';

/// Where handled failures go, if anyone is listening.
///
/// ## Why a static hook rather than an injected dependency
///
/// `Result.guard` is a static utility called from the edge of every
/// repository. Threading a reporter through all of those call sites
/// would mean changing every signature in the data layer to serve
/// observability, which is the tail wagging the dog. One assignment at
/// startup is the smaller price.
///
/// It also keeps `core/result` free of any vendor: this file knows only
/// about [AppFailure], and `bootstrap` decides what listens.
///
/// ## Why handled failures are worth reporting at all
///
/// This codebase converts almost everything into an [AppFailure] and
/// degrades rather than crashing — a corrupt blob, a failed write, a
/// share sheet that would not open. None of those reach a crash
/// reporter, because none of them are crashes, and they are most of what
/// actually goes wrong in production. Without this hook the error tool
/// would report on the one failure mode the architecture was explicitly
/// designed to avoid.
abstract final class ResultReporting {
  /// Called for every failure `Result.guard` produces.
  ///
  /// Left null in tests, so nothing is reported and nothing needs
  /// stubbing.
  static void Function(AppFailure failure)? onFailure;

  /// Reports [failure], swallowing anything the reporter throws.
  ///
  /// Observability must never be able to turn a handled failure — which
  /// the app is designed to survive — into an unhandled one.
  static void report(AppFailure failure) {
    final handler = onFailure;
    if (handler == null) return;
    try {
      handler(failure);
    } on Object {
      // Intentionally ignored.
    }
  }
}
