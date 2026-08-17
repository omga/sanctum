import 'package:dart_mappable/dart_mappable.dart';

part 'subscription_plan.mapper.dart';

/// Billing period.
@MappableEnum()
enum BillingPeriod {
  /// Renews monthly.
  monthly('month'),

  /// Renews yearly.
  yearly('year'),

  /// Bought once, never renews.
  ///
  /// Deliberately not on the paywall. It sits in the model because the
  /// store offering contains it and a repository that silently dropped a
  /// configured product would be lying about what is for sale; the
  /// paywall filters it out, so a one-off offer is a screen to write
  /// rather than a data-layer migration to do first.
  lifetime('once');

  const BillingPeriod(this.unitLabel);

  /// Word used after the price: "£4.99 / month".
  final String unitLabel;

  /// Whether the store will charge for this again.
  bool get renews => this != BillingPeriod.lifetime;
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
  ///
  /// Null for [BillingPeriod.lifetime], which has no monthly equivalent,
  /// and null for any product the store declines to break down. It comes
  /// from the store's own `pricePerMonthString` rather than a division
  /// we do ourselves — dividing a price and formatting the result is how
  /// an app ends up showing "€3.33" to someone whose locale writes
  /// "3,33 €".
  final String? displayPricePerMonth;

  /// Length of the introductory free trial, in days. `0` for none.
  final int trialDays;

  /// Percent saved against paying monthly, if any.
  final int? savingsPercent;

  /// Whether this plan carries a free trial.
  bool get hasTrial => trialDays > 0;
}
