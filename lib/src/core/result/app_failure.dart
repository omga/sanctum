/// Every way this app is allowed to fail.
///
/// Why a sealed class instead of throwing exceptions? Because `sealed`
/// means the compiler knows the complete list of subtypes. A `switch`
/// over an [AppFailure] that forgets a case is a *compile* error, not a
/// crash discovered by a user at 2am. Adding a new failure type here
/// immediately shows you every place that must now handle it.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause, this.stackTrace});

  /// Human-readable, safe to log. Not necessarily safe to show a user —
  /// features map failures onto their own copy.
  final String message;

  /// The original error, when this failure wraps one.
  final Object? cause;

  /// Where [cause] came from, preserved so logs stay useful.
  final StackTrace? stackTrace;

  /// A stable label for logs.
  ///
  /// Deliberately not `runtimeType`, which is unreliable once release
  /// builds minify type names. Because [AppFailure] is sealed, adding a
  /// new subtype turns this switch into a compile error until it is
  /// handled here — which is the whole point of the sealed hierarchy.
  String get label => switch (this) {
    StorageFailure() => 'StorageFailure',
    NotFoundFailure() => 'NotFoundFailure',
    ContentFailure() => 'ContentFailure',
    AudioFailure() => 'AudioFailure',
    AdvisorFailure() => 'AdvisorFailure',
    UnexpectedFailure() => 'UnexpectedFailure',
  };

  @override
  String toString() => '$label: $message';
}

/// Reading or writing the on-device database went wrong.
final class StorageFailure extends AppFailure {
  /// Creates a storage failure.
  const StorageFailure(super.message, {super.cause, super.stackTrace});
}

/// A lookup succeeded mechanically but the thing simply is not there.
final class NotFoundFailure extends AppFailure {
  /// Creates a not-found failure for [what].
  const NotFoundFailure(String what) : super('Not found: $what');
}

/// Bundled JSON content was missing or malformed.
///
/// This is almost always a build/authoring mistake rather than something
/// a user can recover from, so it is deliberately distinct from
/// [StorageFailure].
final class ContentFailure extends AppFailure {
  /// Creates a content failure.
  const ContentFailure(super.message, {super.cause, super.stackTrace});
}

/// Audio playback or the background audio handler failed.
final class AudioFailure extends AppFailure {
  /// Creates an audio failure.
  const AudioFailure(super.message, {super.cause, super.stackTrace});
}

/// Why an advisor answer did not arrive.
///
/// One type with a `kind` rather than five subtypes, because the screen
/// has to tell them apart — "you are offline" and "you have asked a lot
/// in a short time" need different words and different buttons — while
/// the rest of the app only ever wants to know that the send failed.
enum AdvisorFailureKind {
  /// No usable connection. Retrying later is the right advice.
  offline,

  /// The proxy is refusing to spend more inference on this install right
  /// now. Distinct from [server] because it is not a fault and the copy
  /// should not apologise as though it were.
  rateLimited,

  /// The model or the proxy declined to answer. Retrying identically
  /// will not help, so the UI must not offer a bare "try again".
  refused,

  /// Anything else on the far end.
  server,

  /// Produced deliberately by the scripted transport, so the failure
  /// path can be exercised with no network at all.
  scripted,
}

/// An advisor request did not produce an answer.
///
/// A failed send **must not spend a turn** — see `chat_transport.dart`.
final class AdvisorFailure extends AppFailure {
  /// Creates an advisor failure.
  const AdvisorFailure(
    super.message, {
    required this.kind,
    super.cause,
    super.stackTrace,
  });

  /// Which kind, for the copy the screen shows.
  final AdvisorFailureKind kind;
}

/// The catch-all. Anything landing here is a bug we have not classified.
final class UnexpectedFailure extends AppFailure {
  /// Creates an unexpected failure.
  const UnexpectedFailure(super.message, {super.cause, super.stackTrace});
}
