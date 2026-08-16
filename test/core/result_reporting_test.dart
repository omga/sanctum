import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/core/result/result_reporting.dart';

void main() {
  tearDown(() => ResultReporting.onFailure = null);

  test('a successful guard reports nothing', () async {
    var reported = 0;
    ResultReporting.onFailure = (_) => reported++;

    final result = await Result.guard(
      () async => 42,
      onError: (error, stackTrace) => const UnexpectedFailure('nope'),
    );

    expect(result, isA<Ok<int>>());
    expect(reported, 0);
  });

  test('a failed guard reports the failure it produced', () async {
    final reported = <AppFailure>[];
    ResultReporting.onFailure = reported.add;

    await Result.guard<void>(
      () async => throw StateError('boom'),
      onError: (error, stackTrace) => StorageFailure(
        'Could not write',
        cause: error,
        stackTrace: stackTrace,
      ),
    );

    expect(reported, hasLength(1));
    expect(reported.single, isA<StorageFailure>());
    expect(reported.single.message, 'Could not write');
    // The original error is preserved for the report, not swallowed.
    expect(reported.single.cause, isA<StateError>());
  });

  test('reports every failure, not just the first', () async {
    var reported = 0;
    ResultReporting.onFailure = (_) => reported++;

    for (var i = 0; i < 3; i++) {
      await Result.guard<void>(
        () async => throw StateError('boom'),
        onError: (error, stackTrace) => const AudioFailure('no sound'),
      );
    }

    expect(reported, 3);
  });

  test('works with no reporter installed', () async {
    // The default in tests and in any build without crash reporting.
    final result = await Result.guard<void>(
      () async => throw StateError('boom'),
      onError: (error, stackTrace) => const ContentFailure('bad json'),
    );

    expect(result, isA<Err<void>>());
  });

  test('a throwing reporter cannot break a handled failure', () async {
    // Observability must never turn a failure the app was designed to
    // survive into one it does not.
    ResultReporting.onFailure = (_) => throw StateError('reporter down');

    final result = await Result.guard<void>(
      () async => throw StateError('boom'),
      onError: (error, stackTrace) => const StorageFailure('write failed'),
    );

    expect(result, isA<Err<void>>());
  });

  test('a throwing reporter cannot break a successful call either', () async {
    ResultReporting.onFailure = (_) => throw StateError('reporter down');

    final result = await Result.guard(
      () async => 'fine',
      onError: (error, stackTrace) => const UnexpectedFailure('nope'),
    );

    expect(result, isA<Ok<String>>());
  });
}
