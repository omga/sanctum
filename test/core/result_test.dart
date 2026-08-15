import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';

void main() {
  group('Result', () {
    test('Ok carries its value and reports isOk', () {
      const result = Result<int>.ok(42);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
    });

    test('Err carries its failure and reports isErr', () {
      const failure = NotFoundFailure('session');
      const result = Result<int>.err(failure);

      expect(result.isErr, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, same(failure));
    });

    test('map transforms Ok and passes Err through untouched', () {
      const ok = Result<int>.ok(21);
      const err = Result<int>.err(StorageFailure('disk full'));

      expect(ok.map((v) => v * 2), const Ok<int>(42));
      expect(err.map((v) => v * 2).failureOrNull, isA<StorageFailure>());
    });

    test('fold collapses both branches to one type', () {
      const ok = Result<int>.ok(7);
      const err = Result<int>.err(AudioFailure('no output device'));

      String render(Result<int> r) => r.fold(
        onOk: (v) => 'value $v',
        onErr: (f) => 'error ${f.message}',
      );

      expect(render(ok), 'value 7');
      expect(render(err), 'error no output device');
    });

    test('getOrElse falls back only on Err', () {
      expect(const Result<int>.ok(1).getOrElse(99), 1);
      expect(const Result<int>.err(NotFoundFailure('x')).getOrElse(99), 99);
    });

    test('guard converts a thrown error into a typed Err', () async {
      final result = await Result.guard<int>(
        () async => throw const FormatException('bad json'),
        onError: (error, stackTrace) => ContentFailure(
          'catalog unreadable',
          cause: error,
          stackTrace: stackTrace,
        ),
      );

      expect(result.isErr, isTrue);
      final failure = result.failureOrNull!;
      expect(failure, isA<ContentFailure>());
      expect(failure.message, 'catalog unreadable');
      expect(failure.cause, isA<FormatException>());
      expect(failure.stackTrace, isNotNull);
    });

    test('guard returns Ok when nothing throws', () async {
      final result = await Result.guard<int>(
        () async => 5,
        onError: (_, _) => const UnexpectedFailure('unreachable'),
      );

      expect(result, const Ok<int>(5));
    });

    test('failure label does not rely on runtimeType', () {
      expect(const StorageFailure('x').label, 'StorageFailure');
      expect(const NotFoundFailure('x').toString(), contains('NotFound'));
    });
  });
}
