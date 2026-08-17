import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/repositories/entitlement_repository.dart';
import 'package:sanctum/src/data/repositories/revenuecat_subscription_repository.dart';
import 'package:sanctum/src/domain/models/subscription_plan.dart';

IntroductoryPrice _intro({
  required double price,
  required PeriodUnit unit,
  required int units,
}) => IntroductoryPrice(
  price,
  price == 0 ? 'Free' : '£0.99',
  'P${units}D',
  1,
  unit,
  units,
);

void main() {
  group('package type mapping', () {
    test('maps the three types the app sells', () {
      expect(
        RevenueCatSubscriptionRepository.periodFrom(PackageType.monthly),
        BillingPeriod.monthly,
      );
      expect(
        RevenueCatSubscriptionRepository.periodFrom(PackageType.annual),
        BillingPeriod.yearly,
      );
      expect(
        RevenueCatSubscriptionRepository.periodFrom(PackageType.lifetime),
        BillingPeriod.lifetime,
      );
    });

    test('drops weekly, which this app deliberately does not sell', () {
      // Weekly is the highest-refund configuration in this category and
      // was advised against. If somebody adds a weekly package in the
      // RevenueCat dashboard it must not appear in the app just because
      // the dashboard offered it.
      expect(
        RevenueCatSubscriptionRepository.periodFrom(PackageType.weekly),
        isNull,
      );
    });

    test('drops package types the paywall cannot describe', () {
      for (final type in [
        PackageType.sixMonth,
        PackageType.threeMonth,
        PackageType.twoMonth,
        PackageType.custom,
        PackageType.unknown,
      ]) {
        expect(
          RevenueCatSubscriptionRepository.periodFrom(type),
          isNull,
          reason: '$type reached the paywall',
        );
      }
    });
  });

  group('trial length', () {
    test('no introductory offer is no trial', () {
      expect(RevenueCatSubscriptionRepository.trialDaysFrom(null), 0);
    });

    test('a free introductory period converts to days', () {
      expect(
        RevenueCatSubscriptionRepository.trialDaysFrom(
          _intro(price: 0, unit: PeriodUnit.week, units: 1),
        ),
        7,
      );
      expect(
        RevenueCatSubscriptionRepository.trialDaysFrom(
          _intro(price: 0, unit: PeriodUnit.day, units: 3),
        ),
        3,
      );
    });

    test('a discounted-but-paid introductory price is not a trial', () {
      // The button says "Start 7 days free". An introductory *price* is
      // still a charge, and describing one as free is the kind of copy
      // App Store review rejects and users refund over. Only a zero
      // price counts.
      expect(
        RevenueCatSubscriptionRepository.trialDaysFrom(
          _intro(price: 0.99, unit: PeriodUnit.week, units: 1),
        ),
        0,
      );
    });

    test('an unknown period unit yields no trial claim', () {
      expect(
        RevenueCatSubscriptionRepository.trialDaysFrom(
          _intro(price: 0, unit: PeriodUnit.unknown, units: 4),
        ),
        0,
      );
    });
  });

  group('billing period', () {
    test('only lifetime does not renew', () {
      expect(BillingPeriod.monthly.renews, isTrue);
      expect(BillingPeriod.yearly.renews, isTrue);
      expect(BillingPeriod.lifetime.renews, isFalse);
    });
  });

  group('test store guard', () {
    test('recognises a Test Store key', () {
      // RevenueCat crashes the app on purpose if this key reaches a
      // release build, so the app has to know what it is holding before
      // it configures anything. The committed default is a test key.
      expect(RevenueCatSubscriptionRepository.usingTestStore, isTrue);
      expect(RevenueCatSubscriptionRepository.apiKey, startsWith('test_'));
    });

    test('nothing is configured in a test binding', () {
      // And therefore every path fails closed rather than open.
      expect(RevenueCatSubscriptionRepository.isConfigured, isFalse);
    });

    test('an unconfigured store reports free, never premium', () async {
      final repository = RevenueCatSubscriptionRepository();

      await expectLater(
        repository.watch().first,
        completion(SanctumEntitlement.free),
      );
    });

    test('an unconfigured store refuses to sell', () async {
      final repository = RevenueCatSubscriptionRepository();

      expect(await repository.plans(), isA<Err<List<SubscriptionPlan>>>());
      expect(await repository.purchase('anything'), isA<Err<void>>());
      expect(await repository.restore(), isA<Err<void>>());
    });
  });
}
