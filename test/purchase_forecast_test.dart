import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/purchase_forecast.dart';

InventoryLot lot(String id, double? quantity, String unit) => InventoryLot(
  id: id,
  ingredientId: 'rice',
  quantity: quantity,
  unit: unit,
  zone: StorageZone.pantry,
);

void main() {
  test(
    'allocates shared stock once and separates purchase from consumption',
    () {
      final stock = [lot('r', 0.75, 'kg')];
      final requirements = [
        IngredientUse('rice', 500, 'g'),
        IngredientUse('rice', 500, 'g'),
      ];
      final result = forecastPurchases(
        requirements,
        stock,
        estimateCost: (use) => use.quantity / 1000 * 40,
      );
      expect(result.purchases.single.use.quantity, closeTo(250, 1e-9));
      expect(result.purchaseTotal, 10);
      expect(result.consumptionTotal, 40);
      expect(stock.single.quantity, 0.75);
      expect(requirements.length, 2);
      expect(() => result.purchases.clear(), throwsUnsupportedError);
    },
  );

  test('aggregates compatible units before producing shortages', () {
    final result = forecastPurchases(
      [IngredientUse('rice', 500, 'g'), IngredientUse('rice', 0.5, 'kg')],
      [],
      estimateCost: (use) => use.quantity * 0.04,
    );
    expect(result.purchases.single.use.toJson(), {
      'ingredientId': 'rice',
      'quantity': 1000.0,
      'unit': 'g',
    });
    expect(result.purchaseTotal, 40);
  });

  test('missing price keeps total unknown and retains known subtotal', () {
    final result = forecastPurchases(
      [IngredientUse('rice', 100, 'g'), IngredientUse('oil', 50, 'ml')],
      [],
      estimateCost: (use) => use.ingredientId == 'rice' ? 4 : null,
    );
    expect(result.knownPurchaseSubtotal, 4);
    expect(result.purchaseTotal, isNull);
    expect(result.unpricedPurchases, {'oil'});
    expect(result.consumptionTotal, isNull);
    expect(result.complete, isFalse);
  });

  test('known existing stock needs no new budget despite unknown consumption price', () {
    final result = forecastPurchases(
      [IngredientUse('rice', 100, 'g')],
      [lot('unknown', null, 'g'), lot('known', 150, 'g')],
      estimateCost: (_) => null,
    );
    expect(result.purchaseTotal, 0);
    expect(result.unresolvedStock, isEmpty);
    expect(result.unpricedPurchases, isEmpty);
    expect(result.unpricedConsumption, {'rice'});
    expect(result.consumptionTotal, isNull);
  });

  test('unknown inventory never becomes a priced zero-stock shortage', () {
    final result = forecastPurchases(
      [IngredientUse('rice', 100, 'g')],
      [lot('unknown', null, 'g'), lot('known', 25, 'g')],
      estimateCost: (use) => use.quantity * 0.04,
    );
    expect(result.purchases.single.use.quantity, 75);
    expect(result.purchases.single.estimatedCost, isNull);
    expect(result.unresolvedStock, {'rice'});
    expect(result.unpricedPurchases, isEmpty);
    expect(result.purchaseTotal, isNull);
    expect(result.knownPurchaseSubtotal, 0);
    expect(result.consumptionTotal, 4);
  });

  test(
    'unresolved requirements block complete forecasts even with ample stock',
    () {
      final pending = {'oil'};
      final result = forecastPurchases(
        [IngredientUse('rice', 100, 'g')],
        [lot('known', 1000, 'g')],
        estimateCost: (_) => 2,
        unresolvedRequirements: pending,
      );
      pending.clear();
      expect(result.unresolvedRequirements, {'oil'});
      expect(result.purchaseTotal, isNull);
      expect(result.consumptionTotal, isNull);
    },
  );

  test(
    'count and weight are unresolved without an explicit ingredient rule',
    () {
      final result = forecastPurchases(
        [IngredientUse('rice', 100, 'g')],
        [lot('pack', 1, 'count')],
        estimateCost: (_) => 4,
      );
      expect(result.purchaseTotal, isNull);
      expect(result.unresolvedStock, {'rice'});
      final resolved = forecastPurchases(
        [IngredientUse('rice', 100, 'g')],
        [lot('pack', 1, 'count')],
        estimateCost: (_) => 4,
        rules: [UnitRule('rice', 'count', 'g', 200)],
      );
      expect(resolved.purchaseTotal, 0);
    },
  );

  test('valid zero quote remains a known amount', () {
    final result = forecastPurchases(
      [IngredientUse('rice', 100, 'g')],
      [],
      estimateCost: (_) => 0,
    );
    expect(result.purchaseTotal, 0);
    expect(result.complete, isTrue);
    expect(result.unpricedPurchases, isEmpty);
  });

  test('invalid price callback values and numeric overflow are rejected', () {
    for (final value in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
      -1.0,
    ]) {
      expect(
        () => forecastPurchases(
          [IngredientUse('rice', 1, 'g')],
          [],
          estimateCost: (_) => value,
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => forecastPurchases(
        [IngredientUse('rice', 1, 'g'), IngredientUse('oil', 1, 'ml')],
        [],
        estimateCost: (_) => double.maxFinite,
      ),
      throwsArgumentError,
    );
    expect(
      () => forecastPurchases(
        [
          IngredientUse('rice', double.maxFinite, 'g'),
          IngredientUse('rice', double.maxFinite, 'g'),
        ],
        [],
        estimateCost: (_) => 1,
      ),
      throwsArgumentError,
    );
  });

  test(
    'empty requirements explicitly resolve to zero without invoking pricing',
    () {
      final result = forecastPurchases(
        [],
        [],
        estimateCost: (_) => throw StateError('unused'),
      );
      expect(result.purchaseTotal, 0);
      expect(result.consumptionTotal, 0);
    },
  );
  test('an empty incompatible lot cannot hide a known shortage', () {
    final result = forecastPurchases(
      [IngredientUse('rice', 100, 'g')],
      [lot('empty', 0, 'count')],
      estimateCost: (_) => 4,
    );
    expect(result.purchaseTotal, 4);
    expect(result.unresolvedStock, isEmpty);
  });
}
