import 'package:dart_mappable/dart_mappable.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/domain/services/zodiac.dart';

part 'celebrity.mapper.dart';

/// How the celebrity list is grouped in the picker.
@MappableEnum()
enum CelebrityGroup {
  /// Musicians.
  music('Music'),

  /// Film and television.
  screen('Film & TV'),

  /// Athletes.
  sport('Sport');

  const CelebrityGroup(this.displayName);

  /// Section heading.
  final String displayName;
}

/// Someone famous the user can check themselves against.
///
/// ## What is deliberately not here
///
/// No photograph, and no image asset of any kind. A public figure's
/// birth date is a fact and using it is fine; their likeness is not, and
/// putting a face next to a compatibility score also implies an
/// endorsement that does not exist. The picker draws a gradient disc
/// with their initial and their sign glyph instead, which is both safer
/// and more on-brand than a grid of scraped press photos.
@MappableClass()
class Celebrity with CelebrityMappable {
  /// Creates a celebrity.
  const Celebrity({
    required this.id,
    required this.name,
    required this.knownFor,
    required this.birthDate,
    required this.group,
  });

  /// Stable id, used in match bookkeeping. Never reuse one.
  final String id;

  /// Their name.
  final String name;

  /// One short line: what they are known for.
  final String knownFor;

  /// Their birth date, from public record.
  final DateTime birthDate;

  /// Which section of the picker they appear in.
  final CelebrityGroup group;

  /// Their sun sign.
  ZodiacSign get sign => Zodiac.signFor(birthDate);

  /// As the other half of a match.
  MatchPerson get asPerson =>
      MatchPerson(name: name, birthDate: birthDate, celebrityId: id);
}
