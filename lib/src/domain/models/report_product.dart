/// The one-off report, as the store describes it.
///
/// Only an id and a price string. The price is never computed, formatted
/// or converted here — it arrives from the store already localised, in
/// the currency and format of the user's own account, because doing
/// anything else is both a localisation bug and an App Store rejection.
class ReportProduct {
  /// Creates a product.
  const ReportProduct({required this.id, required this.displayPrice});

  /// Store product identifier.
  final String id;

  /// The price as the store wrote it, e.g. `£4.99`.
  final String displayPrice;
}
