import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/services/carousel_caption.dart';
import 'package:sanctum/src/domain/services/compatibility_composer.dart';

import '../support/copy.dart';

final CopyBook _copy = loadEnglishCopy();

final _now = DateTime(2026, 8, 16);

MatchPerson _person(String name, DateTime birth) =>
    MatchPerson(name: name, birthDate: birth);

/// A composed match, so the caption is tested against real copy rather
/// than against a fixture that could drift away from the composer.
CompatibilityMatch _composed() => CompatibilityComposer.compose(
  you: _person('Andrew', DateTime(1996, 7, 5)),
  them: _person('Selena Gomez', DateTime(1992, 7, 22)),
  now: _now,
  copy: _copy,
);

/// A match built by hand, so [DirectionalReading] can be pinned exactly.
/// The split is the branch that matters and the composer does not let a
/// test choose it.
CompatibilityMatch _withPull(DirectionalReading pull) {
  final base = _composed();
  return base.copyWith(pull: pull);
}

DirectionalReading _pull(int yourShare) => DirectionalReading(
  kind: DirectionKind.pull,
  yourShare: yourShare,
  line: 'A line about the split.',
);

void main() {
  group('headline', () {
    test('names both people and the score', () {
      final match = _composed();
      final headline = CarouselCaption.headline(match);

      expect(headline, contains('Andrew'));
      expect(headline, contains('Selena Gomez'));
      expect(headline, contains('${match.overall}%'));
    });
  });

  group('hook', () {
    test('names the heavier side when the pull leans to them', () {
      final match = _withPull(_pull(30));

      expect(
        CarouselCaption.hook(match, _copy),
        'Selena Gomez is 70% of this one.',
      );
    });

    test('names the user when the pull leans to the user', () {
      final match = _withPull(_pull(78));

      expect(CarouselCaption.hook(match, _copy), 'Andrew is 78% of this one.');
    });

    test('falls back to the share line when the split is even', () {
      final match = _withPull(_pull(52));

      expect(match.pull.isBalanced, isTrue);
      expect(CarouselCaption.hook(match, _copy), match.shareLine);
    });

    test('never posts a split it called too close to matter', () {
      // The whole point of `isBalanced` is that the model stays quiet
      // where it knows least. A caption that announced "51% of this
      // one" would undo that in the one place strangers see it.
      for (var share = 50 - DirectionalReading.evenTolerance;
          share <= 50 + DirectionalReading.evenTolerance;
          share++) {
        final match = _withPull(_pull(share));

        expect(
          CarouselCaption.hook(match, _copy),
          match.shareLine,
          reason: 'a $share/${100 - share} split should stay quiet',
        );
      }
    });
  });

  group('tags', () {
    test('carry both sun signs, lowercased and without a hash', () {
      final match = CompatibilityComposer.compose(
        you: _person('Andrew', DateTime(1996, 7, 5)),
        them: _person('Rae', DateTime(1990, 11, 2)),
        now: _now,
        copy: _copy,
      );
      final tags = CarouselCaption.tagsFor(match, _copy);

      expect(tags, containsAll(CarouselCaption.baseTags));
      expect(tags, contains('cancer'));
      expect(tags, contains('scorpio'));
      expect(tags.every((tag) => !tag.startsWith('#')), isTrue);
      expect(tags.every((tag) => tag == tag.toLowerCase()), isTrue);
    });

    test('a same-sign pair does not repeat its sign', () {
      final tags = CarouselCaption.tagsFor(_composed(), _copy);

      expect(tags.where((tag) => tag == 'cancer'), hasLength(1));
      expect(tags.toSet(), hasLength(tags.length));
    });
  });

  group('caption', () {
    test('is headline, hook and tags in that order', () {
      final match = _withPull(_pull(30));
      final caption = CarouselCaption.forMatch(match, _copy);

      expect(
        caption.indexOf(CarouselCaption.headline(match)),
        lessThan(caption.indexOf(CarouselCaption.hook(match, _copy))),
      );
      expect(
        caption.indexOf(CarouselCaption.hook(match, _copy)),
        lessThan(caption.indexOf('#astrology')),
      );
    });

    test('is deterministic for the same match', () {
      expect(
        CarouselCaption.forMatch(_composed(), _copy),
        CarouselCaption.forMatch(_composed(), _copy),
      );
    });
  });
}
