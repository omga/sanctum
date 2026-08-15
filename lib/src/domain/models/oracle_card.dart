import 'package:dart_mappable/dart_mappable.dart';

part 'oracle_card.mapper.dart';

/// One card in the oracle deck.
@MappableClass()
class OracleCard with OracleCardMappable {
  /// Creates an oracle card.
  const OracleCard({
    required this.id,
    required this.name,
    required this.message,
    required this.guidance,
  });

  /// Stable catalogue id. Never reuse one for different content — draws
  /// are stored by id, so reuse would rewrite a user's history.
  final String id;

  /// Card name, shown on the face.
  final String name;

  /// The single line the card leads with.
  final String message;

  /// The longer reading, revealed under the message.
  final String guidance;
}
