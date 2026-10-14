import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/market_profile.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';

import 'recipe_variants_test.dart' as fixture;

class CountedStore extends fixture.Store {
  int saves = 0;
  @override
  Future<void> save(Map<String, dynamic> value) async {
    saves++;
    await super.save(value);
  }
}

MarketPrice price(
  String id,
  double amount, {
  MarketCountry country = MarketCountry.egypt,
  String unit = 'kg',
}) => MarketPrice(
  country: country,
  ingredientId: id,
  unit: unit,
  quantity: 1,
  amount: amount,
  recordedAt: DateTime(2026, 10, 14),
  source: 'Synthetic test price',
);

CatalogRecipe unmeasuredRecipe() {
  final json = fixture.recipe().toJson();
  (json['ingredients'] as List).addAll(<Map<String, dynamic>>[
    {'id': 'salt', 'name': 'Synthetic salt', 'amount': null, 'scale': false},
    {
      'id': 'pepper',
      'name': 'Synthetic pepper',
      'amount': null,
      'scale': false,
      'optional': true,
    },
  ]);
  return CatalogRecipe.fromJson(json);
}

Future<KitchenService> kitchen(
  CountedStore store, {
  CatalogRecipe? recipe,
}) async {
  final service = KitchenService(store, fixture.repository(value: recipe));
  await service.load();
  await service.plan(fixture.plan('p1', 'fixture'));
  await service.savePrice(price('sample', 60), userOverride: true);
  return service;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'two selected plans share stock and preserve prices/history/storage',
    () async {
      final store = CountedStore();
      final k = await kitchen(store);
      await k.plan(fixture.plan('p2', 'fixture'));
      await k.savePrice(price('sample', 50), userOverride: false);
      await k.addStock(
        InventoryLot(
          id: 'lot',
          ingredientId: 'sample',
          quantity: 450,
          unit: 'g',
          zone: StorageZone.pantry,
        ),
        newPurchase: true,
        paid: 27,
        purchasedAt: DateTime(2026, 10, 14),
      );
      await k.plan(fixture.plan('past', 'fixture'));
      await k.confirmCooking('past', 'past-cook');
      final before = jsonEncode(k.snapshot),
          stored = jsonEncode(store.data),
          saves = store.saves;
      final result = await k.previewPurchases(['p1', 'p2']);
      expect(result.purchases.single.use.quantity, 150);
      expect(result.purchaseTotal, 9);
      expect(result.consumptionTotal, 24);
      expect(jsonEncode(k.snapshot), before);
      expect(jsonEncode(store.data), stored);
      expect(store.saves, saves);
    },
  );

  test('unknown required quantities and explicit optional measurement stay explicit', () async {
    final k = await kitchen(CountedStore(), recipe: unmeasuredRecipe());
    await k.savePrice(price('salt', 1, unit: 'g'), userOverride: true);
    await k.savePrice(price('pepper', 2, unit: 'g'), userOverride: true);
    final unknown = await k.previewPurchases(['p1']);
    expect(unknown.unresolvedRequirements, {'p1:1:salt'});
    expect(unknown.purchaseTotal, isNull);
    final measured = await k.previewPurchases(
      ['p1'],
      measuredByPlan: {
        'p1': {1: IngredientUse('salt', 5, 'g')},
      },
    );
    expect(measured.purchaseTotal, 17);
    final optional = await k.previewPurchases(
      ['p1'],
      optionalLinesByPlan: {
        'p1': {2},
      },
      measuredByPlan: {
        'p1': {1: IngredientUse('salt', 5, 'g')},
      },
    );
    expect(optional.unresolvedRequirements, {'p1:2:pepper'});
    final full = await k.previewPurchases(
      ['p1'],
      optionalLinesByPlan: {
        'p1': {2},
      },
      measuredByPlan: {
        'p1': {
          1: IngredientUse('salt', 5, 'g'),
          2: IngredientUse('pepper', 3, 'g'),
        },
      },
    );
    expect(full.purchaseTotal, 23);
  });

  test(
    'unknown stock blocks certainty and country prices never cross markets',
    () async {
      final k = await kitchen(CountedStore());
      await k.addStock(
        InventoryLot(
          id: 'unknown',
          ingredientId: 'sample',
          quantity: null,
          unit: 'g',
          zone: StorageZone.pantry,
        ),
        newPurchase: true,
        paid: 27,
        purchasedAt: DateTime(2026, 10, 14),
      );
      expect((await k.previewPurchases(['p1'])).unresolvedStock, {'sample'});
      await k.setCountry(MarketCountry.saudi);
      final missing = await k.previewPurchases(['p1']);
      expect(missing.consumptionTotal, isNull);
      expect(missing.unpricedConsumption, {'sample'});
      await k.savePrice(
        price('sample', 20, country: MarketCountry.saudi),
        userOverride: true,
      );
      expect((await k.previewPurchases(['p1'])).consumptionTotal, 4);
    },
  );

  test('rejects missing duplicate completed plans and ignored or conflicting decisions', () async {
    final k = await kitchen(CountedStore(), recipe: unmeasuredRecipe());
    await expectLater(k.previewPurchases(['p1', 'p1']), throwsArgumentError);
    await expectLater(k.previewPurchases(['missing']), throwsArgumentError);
    await expectLater(
      k.previewPurchases(['p1'], optionalLinesByPlan: {'other': {}}),
      throwsArgumentError,
    );
    await expectLater(
      k.previewPurchases(['p1'], measuredByPlan: {'other': {}}),
      throwsArgumentError,
    );
    for (final indices in [
      {0},
      {-1},
      {3},
    ]) {
      await expectLater(
        k.previewPurchases(['p1'], optionalLinesByPlan: {'p1': indices}),
        throwsArgumentError,
      );
    }
    for (final measured in [
      {0: IngredientUse('sample', 1, 'g')},
      {1: IngredientUse('wrong', 1, 'g')},
      {2: IngredientUse('pepper', 1, 'g')},
      {8: IngredientUse('salt', 1, 'g')},
    ]) {
      await expectLater(
        k.previewPurchases(['p1'], measuredByPlan: {'p1': measured}),
        throwsArgumentError,
      );
    }
    final store = CountedStore();
    final ordinary = await kitchen(store);
    await ordinary.addStock(
      InventoryLot(
        id: 'lot',
        ingredientId: 'sample',
        quantity: 200,
        unit: 'g',
        zone: StorageZone.pantry,
      ),
      newPurchase: false,
    );
    await ordinary.confirmCooking('p1', 'cook');
    await expectLater(ordinary.previewPurchases(['p1']), throwsStateError);
  });

  test('copies nested caller choices before its first await', () async {
    final k = await kitchen(CountedStore(), recipe: unmeasuredRecipe());
    await k.savePrice(price('salt', 1, unit: 'g'), userOverride: true);
    await k.savePrice(price('pepper', 2, unit: 'g'), userOverride: true);
    final ids = ['p1'],
        selected = {2},
        measurements = {
          1: IngredientUse('salt', 5, 'g'),
          2: IngredientUse('pepper', 3, 'g'),
        };
    final options = {'p1': selected}, measured = {'p1': measurements};
    final pending = k.previewPurchases(
      ids,
      optionalLinesByPlan: options,
      measuredByPlan: measured,
    );
    ids.clear();
    selected.clear();
    measurements.clear();
    options.clear();
    measured.clear();
    final result = await pending;
    expect(result.purchaseTotal, 23);
  });

  test(
    'rejects a kitchen change during asynchronous legacy recipe resolution',
    () async {
      final store = CountedStore();
      final original = await kitchen(store);
      final kitchenData = store.data!['kitchen'] as Map;
      (kitchenData['plans'] as List).single['recipeRevisionKey'] = null;
      kitchenData.remove('recipeBook');
      final entered = Completer<void>(), release = Completer<void>();
      final r = fixture.recipe();
      final repository = RecipeRepository(
        read: (path) async {
          if (path.endsWith('index.json')) {
            entered.complete();
            await release.future;
            return jsonEncode({
              'cuisines': [
                {'file': 'test.json'},
              ],
              'recipes': [
                {
                  'id': r.id,
                  'file': 'test.json',
                  'cuisine': r.cuisine,
                  'servings': r.servings,
                  'name': r.name,
                  'tags': [],
                },
              ],
            });
          }
          return jsonEncode({
            'recipes': [r.toJson()],
          });
        },
      );
      final k = KitchenService(store, repository);
      await k.load();
      final pending = k.previewPurchases(['p1']);
      await entered.future;
      await k.setCountry(MarketCountry.saudi);
      final assertion = expectLater(pending, throwsStateError);
      release.complete();
      await assertion;
      expect(k.market.country, MarketCountry.saudi);
      expect(original.market.country, MarketCountry.egypt);
    },
  );
  test('uses the pinned revision and selected servings after another revision becomes active', () async {
    final k = await kitchen(CountedStore());
    final base = await k.recipeForMeal('p1');
    final first = fixture.custom(base, 'v1', 100);
    await k.saveRecipeRevision(first);
    await k.plan(
      PlannedMeal(
        id: 'personal',
        date: '2026-10-14',
        slot: 'lunch',
        recipeId: first.variantId,
        servings: 1,
      ),
    );
    await k.saveRecipeRevision(fixture.custom(base, 'v2', 300));
    final result = await k.previewPurchases(['personal']);
    expect(result.purchases.single.use.quantity, 50);
    expect(result.purchaseTotal, 3);
  });
}
