import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';

import 'recipe_variants_test.dart' as f;

double? conv(double q, String from, String to, {List<UnitRule>? rules}) =>
    Units.convert(q, from, to, ingredientId: 'rice', rules: rules ?? const []);

// Synthetic fixture: raw recipe line IDs differ from stock identities.
CatalogRecipe rawLines() => CatalogRecipe.fromJson({
  ...f.recipe().toJson(),
  'ingredients': [
    {'id': 'raw-onion-1', 'name': 'بصل', 'amount': 2, 'unit': 'حبة'},
    {'id': 'raw-rice-7', 'name': 'رز', 'amount': 1, 'unit': 'كوب'},
  ],
});

String stockId(String raw) =>
    const {'raw-onion-1': 'onion', 'raw-rice-7': 'rice'}[raw] ?? raw;

PlannedMeal meal() => PlannedMeal(
  id: 'm1',
  date: '2026-10-25',
  slot: 'lunch',
  recipeId: 'fixture',
  servings: 2,
);

InventoryLot lot(String id, String ingredient, double q, String unit) =>
    InventoryLot(
      id: id,
      ingredientId: ingredient,
      quantity: q,
      unit: unit,
      zone: StorageZone.pantry,
    );

void main() {
  test('canonical synonyms', () {
    for (final e in {
      'كيلوغرام': 'kg',
      'كيلوجرام': 'kg',
      'كجم': 'kg',
      'ملليلتر': 'ml',
      'مللي': 'ml',
      'مل': 'ml',
      'ملعقة كبيرة': 'tbsp',
      'T': 'tbsp',
      'ملعقة صغيرة': 'tsp',
      't': 'tsp',
      'كوب': 'cup',
      'رطل': 'lb',
      'أونصة': 'oz',
      'أونصات': 'oz',
      'كوارت': 'qt',
      'باينت': 'pt',
      'ديسيلتر': 'dl',
      'جرام': 'g',
      'حبات': 'count',
      ' لتر ': 'l',
      'فص': 'فص',
      'قطعة': 'قطعة',
      'أكواب': 'cup',
      'cups': 'cup',
      'م.ك': 'tbsp',
      'tablespoon': 'tbsp',
      'م.ص': 'tsp',
      'teaspoon': 'tsp',
      'pound': 'lb',
      'ounce': 'oz',
      'غرام': 'g',
      'grams': 'g',
      'مليلتر': 'ml',
    }.entries) {
      expect(Units.canonical(e.key), e.value, reason: e.key);
    }
  });

  test('definitional conversions only', () {
    expect(conv(2, 'ملعقة كبيرة', 'ml'), closeTo(30, 1e-9));
    expect(conv(3, 'tsp', 'مل'), closeTo(15, 1e-9));
    expect(conv(1, 'tbsp', 'tsp'), closeTo(3, 1e-9));
    expect(conv(1, 'كوب', 'ml'), closeTo(240, 1e-9));
    expect(conv(1, 'cup', 'tbsp'), closeTo(16, 1e-9));
    expect(conv(1, 'رطل', 'g'), closeTo(453.59237, 1e-9));
    expect(conv(1, 'lb', 'oz'), closeTo(16, 1e-9));
    expect(conv(1, 'أونصة', 'جم'), closeTo(28.349523125, 1e-9));
    expect(conv(1, 'كوارت', 'ml'), closeTo(946.352946, 1e-9));
    expect(conv(1, 'qt', 'pt'), closeTo(2, 1e-9));
    expect(conv(1, 'باينت', 'ml'), closeTo(473.176473, 1e-9));
    expect(conv(1, 'ديسيلتر', 'ml'), closeTo(100, 1e-9));
    expect(conv(1, 'لتر', 'dl'), closeTo(10, 1e-9));
    expect(conv(1, 'كيلوغرام', 'g'), closeTo(1000, 1e-9));
    expect(conv(500, 'ملليلتر', 'l'), closeTo(.5, 1e-9));
  });

  test('volume and weight never cross without an explicit rule', () {
    expect(conv(1, 'كوب', 'g'), isNull);
    expect(conv(1, 'tbsp', 'kg'), isNull);
    expect(conv(1, 'oz', 'ml'), isNull);
    expect(conv(1, 'حبة', 'g'), isNull);
    expect(conv(1, 'فص', 'g'), isNull);
    expect(conv(2, 'فص', 'فص'), 2);
    final rule = [UnitRule('rice', 'كوب', 'g', 200)];
    expect(conv(2, 'tbsp', 'g', rules: rule), closeTo(25, 1e-9));
    expect(conv(1, 'كوب', 'kg', rules: rule), closeTo(.2, 1e-9));
    expect(conv(100, 'g', 'ml', rules: rule), closeTo(120, 1e-9));
    expect(
      Units.convert(1, 'cup', 'g', ingredientId: 'flour', rules: rule),
      isNull,
    );
  });

  test('unit rules save, replace, remove and reload', () async {
    final store = f.Store();
    final k = KitchenService(store, f.repository());
    await k.load();
    expect(k.unitRules, isEmpty);
    expect(store.data, isNull);
    await k.saveUnitRule(UnitRule('rice', 'كوب', 'جرام', 200));
    await k.saveUnitRule(UnitRule('rice', 'cup', 'g', 190));
    await k.saveUnitRule(UnitRule('lentils', 'كوب', 'g', 180));
    expect(k.unitRules.length, 2);
    final rice = k.unitRules.singleWhere((r) => r.ingredientId == 'rice');
    expect((rice.from, rice.to, rice.factor), ('cup', 'g', 190));
    expect(
      () => k.saveUnitRule(UnitRule('', 'cup', 'g', 1)),
      throwsArgumentError,
    );
    expect(() => UnitRule('rice', 'cup', 'g', 0), throwsArgumentError);

    final reloaded = KitchenService(store, f.repository());
    await reloaded.load();
    expect(
      reloaded.unitRules.map((r) => r.toJson()).toList(),
      k.unitRules.map((r) => r.toJson()).toList(),
    );
    await reloaded.removeUnitRule('rice', 'كوب', 'جم');
    expect(reloaded.unitRules.single.ingredientId, 'lentils');
    final again = KitchenService(store, f.repository());
    await again.load();
    expect(again.unitRules.single.ingredientId, 'lentils');
  });

  test('old state without unitRules still loads', () async {
    final store = f.Store();
    final k = KitchenService(store, f.repository());
    await k.load();
    await k.addStock(lot('a', 'rice', 1, 'kg'), newPurchase: false);
    final kitchen = store.data!['kitchen'] as Map<String, dynamic>;
    expect(kitchen.containsKey('unitRules'), isFalse);
    final old = KitchenService(store, f.repository());
    await old.load();
    expect(old.unitRules, isEmpty);
  });

  test('stockIdOf maps raw recipe lines to stock, cost and history', () async {
    final store = f.Store();
    final k = KitchenService(
      store,
      f.repository(value: rawLines()),
      stockIdOf: stockId,
    );
    await k.load();
    await k.addStock(lot('o', 'onion', 5, 'حبات'), newPurchase: false);
    await k.addStock(lot('r', 'rice', 1, 'كيلو'), newPurchase: false);
    await k.plan(meal());
    // No rule yet: a cup line cannot draw from gram stock.
    await expectLater(k.confirmCooking('m1', 'op0'), throwsStateError);
    await k.saveUnitRule(UnitRule('rice', 'كوب', 'g', 200));
    expect(
      k.estimatedCost(IngredientUse('raw-rice-7', 1, 'كوب')),
      isNull,
    ); // no price yet
    final receipt = await k.confirmCooking(
      'm1',
      'op1',
      untrackedStockLines: const {},
    );
    final byId = {for (final l in k.inventory) l.ingredientId: l.quantity};
    expect(byId['onion'], closeTo(3, 1e-9));
    expect(byId['rice'], closeTo(.8, 1e-9));
    final consumed = (receipt['consumed'] as List)
        .map((v) => (v as Map)['ingredientId'])
        .toList();
    expect(consumed, ['onion', 'rice']);
    expect(receipt['unpricedIngredients'], ['onion', 'rice']);
  });

  test('explicit rules win over stored rules for the same key', () async {
    final store = f.Store();
    final k = KitchenService(
      store,
      f.repository(value: rawLines()),
      stockIdOf: stockId,
    );
    await k.load();
    await k.addStock(lot('o', 'onion', 5, 'حبة'), newPurchase: false);
    await k.addStock(lot('r', 'rice', 1000, 'g'), newPurchase: false);
    await k.plan(meal());
    await k.saveUnitRule(UnitRule('rice', 'cup', 'g', 200));
    await k.confirmCooking(
      'm1',
      'op',
      rules: [UnitRule('rice', 'كوب', 'g', 150)],
    );
    expect(
      k.inventory.singleWhere((l) => l.id == 'r').quantity,
      closeTo(850, 1e-9),
    );
  });

  test(
    'untracked lines report stock IDs and validation keeps raw IDs',
    () async {
      final store = f.Store();
      final k = KitchenService(
        store,
        f.repository(value: rawLines()),
        stockIdOf: stockId,
      );
      await k.load();
      await k.addStock(lot('o', 'onion', 500, 'جرام'), newPurchase: false);
      await k.plan(meal());
      // Actual line use must name the raw recipe ID, not the stock ID.
      await expectLater(
        k.confirmCooking(
          'm1',
          'bad',
          untrackedStockLines: {1},
          actualUsesByLine: {0: IngredientUse('onion', 100, 'g')},
        ),
        throwsArgumentError,
      );
      final receipt = await k.confirmCooking(
        'm1',
        'ok',
        untrackedStockLines: {1},
        actualUsesByLine: {0: IngredientUse('raw-onion-1', 100, 'g')},
      );
      expect(k.inventory.single.quantity, closeTo(400, 1e-9));
      expect(receipt['unpricedIngredients'], ['rice', 'onion']);
      expect((receipt['consumed'] as List).single['ingredientId'], 'onion');
    },
  );
}
