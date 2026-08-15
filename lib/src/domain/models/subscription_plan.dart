import 'package:dart_mappable/dart_mappable.dart';

part 'subscription_plan.mapper.dart';

/// Billing period.
@MappableEnum()
enum BillingPeriod {
  /// Renews monthly.
  monthly('month'),

  /// Renews yearly.
  yearly('year');

  const BillingPeriod(this.unitLabel);

  /// Word used after the price: "£4.99 / month".
  final String unitLabel;
}

/// One purchasable plan.
///
/// Prices are **strings from the store**, never numbers formatted by us.
/// The store returns them already localised, in the right currency, with
/// the right symbol placement — and App Store review rejects apps that
/// display a price differing from the one StoreKit reports.
@MappableClass()
class SubscriptionPlan with SubscriptionPlanMappable {
  /// Creates a plan.
  const SubscriptionPlan({
    required this.id,
    required this.period,
    required this.displayPrice,
    required this.displayPricePerMonth,
    this.trialDays = 0,
    this.savingsPercent,
  });

  /// Store product identifier.
  final String id;

  /// How often it renews.
  final BillingPeriod period;

  /// Localised total price, e.g. "£39.99".
  final String displayPrice;

  /// Localised price broken down per month, e.g. "£3.33".
  ///
  /// Shown alongside the yearly plan because a yearly total looks
  /// expensive next to a monthly one until it is expressed in the same
  /// unit. This is honest framing, not a trick: both numbers are shown.
  final String displayPricePerMonth;

  /// Length of the introductory free trial, in days. `0` for none.
  final int trialDays;

  /// Percent saved against paying monthly, if any.
  final int? savingsPercent;

  /// Whether this plan carries a free trial.
  bool get hasTrial => trialDays > 0;
}
