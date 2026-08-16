import 'package:meta/meta.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result_reporting.dart';

/// The outcome of an operation that is allowed to fail: either [Ok] with a
/// value, or [Err] with an [AppFailure].
///
/// ## Why this exists
///
/// A thrown exception is invisible in a function's type. A method
/// returning `Future<User>` looks total, but it might throw four different
/// things and nothing forces a caller to care. Returning
/// `Future<Result<User>>` instead puts failure in the signature, and
/// because [Result] is `sealed`, an exhaustive `switch` will not compile
/// until every case is handled.
///
/// ## The rule in this codebase
///
/// Repositories return `Result` and never throw. Exceptions are caught at
/// the boundary — see [Result.guard] — and converted once. Above that
/// line, no `try/catch` should appear in a ViewModel or a widget.
///
/// ```dart
/// switch (await repo.loadSession(id)) {
///   case Ok(:final value) => _play(value),
///   case Err(:final failure) => _showMessage(failure.message),
/// }
/// ```
sealed class Result<T> {
  /// Const base constructor.
  const Result();

  /// A successful result carrying [value].
  const factory Result.ok(T value) = Ok<T>;

  /// A failed result carrying [failure].
  const factory Result.err(AppFailure failure) = Err<T>;

  /// Runs [body], converting any thrown object into an [Err].
  ///
  /// This is the *only* place the codebase turns exceptions into results.
  /// Use it at the edge of the data layer, wrapping the third-party call
  /// (Drift, just_audio, dart:io) that can actually throw. [onError] lets
  /// the caller pick the right [AppFailure] subtype for its layer.
  static Future<Result<T>> guard<T>(
    Future<T> Function() body, {
    required AppFailure Function(Object error, StackTrace stackTrace) onError,
  }) async {
    try {
      return Ok(await body());
    } on Object catch (error, stackTrace) {
      final failure = onError(error, stackTrace);
      // The single choke point for handled failures, which is exactly
      // why the reporting hook lives here and nowhere else.
      ResultReporting.report(failure);
      return Err(failure);
    }
  }
}

/// A [Result] holding a successful [value].
@immutable
final class Ok<T> extends Result<T> {
  /// Creates a successful result.
  const Ok(this.value);

  /// The produced value.
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ok<T> && other.value == value);

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

/// A [Result] holding an [AppFailure].
@immutable
final class Err<T> extends Result<T> {
  /// Creates a failed result.
  const Err(this.failure);

  /// Why the operation failed.
  final AppFailure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Err<T> && other.failure == failure);

  @override
  int get hashCode => Object.hash(Err, failure);

  @override
  String toString() => 'Err($failure)';
}

/// Ergonomics for working with a [Result] without unwrapping it by hand.
extension ResultX<T> on Result<T> {
  /// Whether this is an [Ok].
  bool get isOk => this is Ok<T>;

  /// Whether this is an [Err].
  bool get isErr => this is Err<T>;

  /// The value if [Ok], otherwise `null`.
  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// The failure if [Err], otherwise `null`.
  AppFailure? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };

  /// The value if [Ok], otherwise [fallback].
  T getOrElse(T fallback) => valueOrNull ?? fallback;

  /// Transforms an [Ok] value with [transform], leaving [Err] untouched.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure) => Err(failure),
  };

  /// Collapses both branches into a single value of type [R].
  ///
  /// Handy in widgets, where you need *something* to render either way.
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(AppFailure failure) onErr,
  }) => switch (this) {
    Ok(:final value) => onOk(value),
    Err(:final failure) => onErr(failure),
  };
}
