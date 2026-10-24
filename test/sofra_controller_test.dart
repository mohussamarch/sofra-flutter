import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/sofra_controller.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';

import 'recipe_variants_test.dart' as f;

// Synthetic two-line recipe: one gram line, one count line, one unmeasured.
CatalogRecipe threeLines() => CatalogRecipe.fromJson({
  ...f.recipe().toJson(),
  'ingredients': [
    {'id': 'sample', 'name': 'عينة', 'amount': 200, 'unit': 'جرام'},
    {'id': 'water', 'name': 'ماء', 'amount': 2, 'unit': 'كوب'},
    {'id': 'salt', 'name': 'ملح', 'amount': null, 'unit': null, 'scale': false},
  ],
});

Future<KitchenService> kitchen(f.Store store) async {
  final k = KitchenService(store, f.repository(value: threeLines()));
  await k.load();
  await k.addStock(
    InventoryLot(
      id: 'lot-a',
      ingredientId: 'sample',
      quantity: 500,
      unit: 'g',
      zone: StorageZone.pantry,
    ),
    newPurchase: false,
  );
  await k.plan(
    PlannedMeal(
      id: 'm1',
      date: '2026-10-25',
      slot: 'lunch',
      recipeId: 'fixture',
      servings: 2,
    ),
  );
  return k;
}

void main() {
  test('untracked stock lines are cooked without deduction or cost', () async {
    final store = f.Store();
    final k = await kitchen(store);
    await expectLater(
      k.confirmCooking('m1', 'op-x', omitUnmeasuredLines: {2}),
      throwsStateError,
      reason: 'water is not in stock and must be decided explicitly',
    );
    await expectLater(
      k.confirmCooking(
        'm1',
        'op-y',
        untrackedStockLines: {1},
        omitUnmeasuredLines: {1, 2},
      ),
      throwsArgumentError,
    );
    final record = await k.confirmCooking(
      'm1',
      'op-1',
      untrackedStockLines: {1},
      omitUnmeasuredLines: {2},
    );
    expect(record['untrackedStockLines'], [1]);
    expect(record['cost'], isNull);
    expect(record['unpricedIngredients'], contains('water'));
    expect((record['consumed'] as List).single['ingredientId'], 'sample');
    expect(k.inventory.single.quantity, 300);
    final again = await k.confirmCooking(
      'm1',
      'op-1',
      untrackedStockLines: {1},
      omitUnmeasuredLines: {2},
    );
    expect(again['operationId'], 'op-1');
    expect(k.inventory.single.quantity, 300);
  });

  test(
    'root fields share the single writer and protect reserved keys',
    () async {
      final store = f.Store();
      final k = await kitchen(store);
      await k.saveRootFields({
        'name': 'مريم',
        'saved': ['a'],
      });
      expect(store.data!['name'], 'مريم');
      expect(store.data!['kitchen'], isNotNull);
      expect(k.rootFields['saved'], ['a']);
      expect(k.rootFields.containsKey('kitchen'), isFalse);
      expect(() => k.saveRootFields({'kitchen': {}}), throwsArgumentError);
      await k.saveRootFields({'name': null});
      expect(store.data!.containsKey('name'), isFalse);
      final reload = KitchenService(store, k.recipes);
      await reload.load();
      expect(reload.inventory.single.id, 'lot-a');
    },
  );

  test('profile reads legacy Arabic cuisine labels', () {
    final p = Profile.fromRoot({
      'name': 'سارة',
      'cuisines': ['مصري', 'إيطالي', 'غير معروف'],
      'servings': 40,
    });
    expect(p.cuisines, {'egyptian', 'italian'});
    expect(p.servings, 12);
    expect(Profile.fromRoot(p.toJson()).cuisines, p.cuisines);
  });

  test('stock check allocates lots once and classifies every line', () async {
    final store = f.Store();
    final c = SofraController(
      store: store,
      recipes: f.repository(value: threeLines()),
      readAsset: (path) => File(path).readAsString(),
    );
    await c.load();
    await c.kitchen.addStock(
      InventoryLot(
        id: 'lot-w',
        ingredientId: 'water',
        quantity: 500,
        // Weight stock vs a cup line stays unresolved (cup→ml is now a
        // definitional 240 ml conversion; volume→weight needs a rule).
        unit: 'g',
        zone: StorageZone.pantry,
      ),
      newPurchase: false,
    );
    final recipe = await c.recipes.get('fixture');
    var check = c.checkStock(recipe.forServings(2));
    expect(check.lines.map((l) => l.status), [
      LineStock.missing,
      LineStock.unresolved,
      LineStock.unmeasured,
    ]);
    expect(check.lines.first.missing, 200);
    await c.addMissing(check);
    check = c.checkStock(recipe.forServings(2));
    expect(check.lines.first.status, LineStock.inStock);
    expect(c.kitchen.snapshot['purchases'], isEmpty);
    expect(c.ingredientName('sample'), 'عينة');
  });

  test('recipe lines use directory stock ids and saved unit rules', () async {
    final recipe = CatalogRecipe.fromJson({
      ...f.recipe().toJson(),
      'ingredients': [
        {
          'id': 'bc-arroz-chaufa-ing-1',
          'name': 'أرز',
          'amount': 1,
          'unit': 'كوب',
        },
      ],
    });
    final c = SofraController(
      store: f.Store(),
      recipes: f.repository(value: recipe),
      readAsset: (path) => File(path).readAsString(),
    );
    await c.load();
    expect(c.stockId('bc-arroz-chaufa-ing-1'), 'rice');
    expect(c.ingredientName('rice'), 'رز');
    await c.addIngredient('rice', 1, 'كيلو', StorageZone.pantry);
    await c.addIngredient('rice', 500, 'جم', StorageZone.pantry);
    expect(c.stock.single.quantity, 1.5, reason: 'g merges into the kg lot');
    final scaled = (await c.recipes.get('fixture')).forServings(2);
    expect(c.checkStock(scaled).lines.single.status, LineStock.unresolved);
    expect(c.stockUnit('rice'), 'kg');
    expect(await c.saveUnitRule('rice', 'كوب', 'g', 200), isTrue);
    final line = c.checkStock(scaled).lines.single;
    expect(line.status, LineStock.inStock);
    expect(c.kitchen.unitRules.single.factor, 200);
  });
}
