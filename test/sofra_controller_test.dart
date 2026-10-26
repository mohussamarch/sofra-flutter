import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/sofra_controller.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/monthly_budget_search.dart';
import 'package:tabkha_demo/domain/purchase_forecast.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';

import 'personal_recipe_publication_test.dart' as pub;
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

  test('counted stock uses piece names and the user piece weight', () async {
    final recipe = CatalogRecipe.fromJson({
      ...f.recipe().toJson(),
      'ingredients': [
        {'id': 'chicken', 'name': 'دجاج', 'amount': 500, 'unit': 'جرام'},
      ],
    });
    final c = SofraController(
      store: f.Store(),
      recipes: f.repository(value: recipe),
      readAsset: (path) => File(path).readAsString(),
    );
    await c.load();
    final chicken = c.directory!.entry('chicken')!;
    expect(chicken.units.first, 'count');
    expect(chicken.units, contains('kg'));
    expect(c.directory!.entry('arugula')!.units.first, 'ربطة');
    expect(c.directory!.entry('chicken-breast')!.units, ['kg', 'g']);
    expect(c.amountText('chicken', 3, 'count'), '3 فراخ');
    expect(c.amountText('chicken', 1, 'count'), '1 فرخة');
    expect(c.amountText('chicken', 1.5, 'kg'), '1½ كيلو');

    await c.addIngredient('chicken', 2, 'count', StorageZone.freezer);
    final scaled = (await c.recipes.get('fixture')).forServings(2);
    expect(
      c.checkStock(scaled).lines.single.status,
      LineStock.unresolved,
      reason: 'no weight is assumed for a whole chicken',
    );
    await c.saveUnitRule('chicken', 'count', 'g', 1200);
    expect(c.measureOf('chicken', 'count'), 1200);
    expect(c.checkStock(scaled).lines.single.status, LineStock.inStock);
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
  test(
    'leftovers are saved after cooking and eaten from the microwave',
    () async {
      final c = SofraController(
        store: f.Store(),
        recipes: f.repository(value: threeLines()),
        readAsset: (path) => File(path).readAsString(),
      );
      await c.load();
      expect(await c.saveLeftovers('كشري', 0), isTrue);
      expect(c.leftovers, isEmpty, reason: 'nothing left, nothing saved');
      expect(
        await c.saveLeftovers('كشري', 1.5, on: DateTime(2026, 10, 26)),
        isTrue,
      );
      final dish = c.leftovers.single;
      expect(dish.servings, 1.5);
      expect(dish.preparedOn, '2026-10-26');
      expect(await c.eatLeftover(dish.id, 1), isTrue);
      expect(c.leftovers.single.servings, .5);
      expect(
        await c.eatLeftover(dish.id, 1),
        isFalse,
        reason: 'only half left',
      );
      expect(c.leftovers.single.servings, .5);
      expect(await c.eatLeftover(dish.id, .5), isTrue);
      expect(c.leftovers, isEmpty, reason: 'an empty dish leaves the fridge');
    },
  );
  test('a line offering two products deducts the chosen one', () async {
    final k = KitchenService(
      f.Store(),
      f.repository(value: threeLines()),
      stockOptionsOf: (id) => id == 'sample' ? ['sample', 'other'] : [id],
    );
    await k.load();
    await k.addStock(
      InventoryLot(
        id: 'lot-o',
        ingredientId: 'other',
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
    await expectLater(
      k.confirmCooking(
        'm1',
        'op-bad',
        untrackedStockLines: {1},
        omitUnmeasuredLines: {2},
        stockChoiceByLine: {0: 'water'},
      ),
      throwsArgumentError,
      reason: 'water is not one of the line options',
    );
    final record = await k.confirmCooking(
      'm1',
      'op-1',
      untrackedStockLines: {1},
      omitUnmeasuredLines: {2},
      stockChoiceByLine: {0: 'other'},
    );
    expect((record['consumed'] as List).single['ingredientId'], 'other');
    expect(k.inventory.single.quantity, 300);
  });
  test('a partly stocked line uses up what there is', () async {
    final c = SofraController(
      store: f.Store(),
      recipes: f.repository(value: threeLines()),
      readAsset: (path) => File(path).readAsString(),
    );
    await c.load();
    final k = c.kitchen;
    await k.addStock(
      InventoryLot(
        id: 'lot-a',
        ingredientId: 'sample',
        quantity: 150,
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
    final meal = k.plans.single;
    final check = await c.checkPlan(meal);
    final line = check.lines.first;
    expect(line.status, LineStock.missing);
    expect(line.missing, 50);
    expect(line.partial, isTrue);
    expect(check.lines[1].partial, isFalse, reason: 'no water at all');
    final record = await c.cook(meal, check, 'op-1');
    expect(record, isNotNull);
    expect(k.inventory.single.quantity, 0);
    final used = (record!['consumed'] as List).single;
    expect(used['ingredientId'], 'sample');
    expect(used['quantity'], 150);
    expect(record['cost'], isNull);
    expect(record['unpricedIngredients'], contains('sample'));
  });
  test('a weekly menu is priced over the month and saved on accept', () async {
    final c = SofraController(
      store: f.Store(),
      recipes: f.repository(value: threeLines()),
      readAsset: (path) => File(path).readAsString(),
    );
    await c.load();
    final menu = {
      for (var day = 1; day <= 7; day++) (day, 'lunch'): ['fixture'],
    };
    final february = DateTime(2027, 2, 10);
    var plan = await c.previewMonth(
      month: february,
      limit: 1000,
      menu: menu,
      servings: 2,
    );
    expect(plan.budget.start, '2027-02-01');
    expect(plan.budget.end, '2027-03-01');
    expect(plan.outcome, MonthlyBudgetSearchOutcome.indeterminate);
    expect(plan.unpriced.keys, containsAll(['sample', 'water']));
    expect(await c.acceptMonth(plan), isFalse, reason: 'no known total');
    expect(plan.unmeasured, isEmpty);

    for (final MapEntry(key: id, value: unit) in plan.unpriced.entries) {
      expect(await c.setUserPrice(id, 1, unit, 1), isTrue);
    }
    plan = await c.previewMonth(
      month: february,
      limit: 1,
      menu: menu,
      servings: 2,
      omitUnmeasured: true,
    );
    expect(plan.unmeasured, {'ملح'});
    expect(
      plan.outcome,
      MonthlyBudgetSearchOutcome.noAffordableInSuppliedPools,
    );
    expect(plan.cheapest!.overrun, greaterThan(0));

    plan = await c.previewMonth(
      month: february,
      limit: 100000,
      menu: menu,
      servings: 2,
      omitUnmeasured: true,
    );
    expect(plan.outcome, MonthlyBudgetSearchOutcome.affordableFound);
    expect(await c.acceptMonth(plan), isTrue);
    final saved = c.kitchen.plans.where((p) => p.date.startsWith('2027-02'));
    expect(saved, hasLength(28));
    expect(saved.every((p) => p.slot == 'lunch' && p.servings == 2), isTrue);

    // Planning the same month again: it asks, then keeps or replaces.
    await expectLater(
      c.previewMonth(
        month: february,
        limit: 100000,
        menu: menu,
        servings: 2,
        omitUnmeasured: true,
        keepPlanned: true,
      ),
      throwsStateError,
      reason: 'every day already has its lunch',
    );
    final again = await c.previewMonth(
      month: february,
      limit: 100000,
      menu: menu,
      servings: 2,
      omitUnmeasured: true,
    );
    expect(c.monthConflicts(again), hasLength(28));
    expect(await c.acceptMonth(again, replace: true), isTrue);
    expect(
      c.kitchen.plans.where((p) => p.date.startsWith('2027-02')),
      hasLength(28),
    );
  });
  test('a recipe the user writes is planned and cooked from stock', () async {
    final c = SofraController(
      store: f.Store(),
      recipes: f.repository(value: threeLines()),
      readAsset: (path) => File(path).readAsString(),
    );
    await c.load();
    Future<String?> create(String cuisine) => c.createMyRecipe(
      name: 'رز بالشعرية بتاعنا',
      servings: 2,
      cuisine: cuisine,
      prepMinutes: 5,
      cookMinutes: 20,
      category: 'أطباق رئيسية',
      description: 'زي ما بنعمله في البيت',
      difficulty: 'سهل',
      lines: const [
        MyRecipeLine('rice', 'رز', amount: 200, unit: 'g'),
        MyRecipeLine('salt', 'ملح'),
      ],
      steps: const [('حمّر الشعرية وضيف الرز', 5), ('سيبه يستوي', 20)],
    );
    expect(() => create('غير محدد'), throwsArgumentError);
    final id = await create('مصري');
    expect(id, isNotNull);
    expect(c.myRecipes.single.variantId, id);
    expect(c.myRecipes.single.recipe.name, 'رز بالشعرية بتاعنا');

    await c.kitchen.addStock(
      InventoryLot(
        id: 'lot-r',
        ingredientId: 'rice',
        quantity: 1,
        unit: 'kg',
        zone: StorageZone.pantry,
      ),
      newPurchase: false,
    );
    expect(
      await c.planMeal(
        id!,
        day: DateTime(2026, 10, 26),
        slot: 'lunch',
        servings: 4,
      ),
      isTrue,
    );
    final meal = c.kitchen.plans.single;
    final check = await c.checkPlan(meal);
    expect(check.lines.first.status, LineStock.inStock);
    expect(check.lines.last.status, LineStock.unmeasured);
    expect(await c.cook(meal, check, 'op-mine'), isNotNull);
    expect(c.kitchen.inventory.single.quantity, closeTo(.6, 1e-9));
  });
  test('portion nutrition shows only fully sourced values', () async {
    final c = SofraController(
      store: f.Store(),
      recipes: f.repository(),
      readAsset: (path) => File(path).readAsString(),
    );
    await c.load();
    final d = pub.draft();
    await pub.save(c.kitchen, d);
    final r = await c.kitchen.finalizePersonalRecipe(pub.review(d));
    await c.kitchen.plan(f.plan('sourced', r.variantId));
    await c.kitchen.plan(f.plan('unsourced', 'fixture'));
    final meals = {for (final m in c.kitchen.plans) m.id: m};
    // 100 g of a 200 kcal / 10 g protein per 100 g food, two portions.
    final sourced = await c.portionNutrition(meals['sourced']!);
    expect(sourced![NutrientId.energyKcal], 100);
    expect(sourced[NutrientId.protein], 5);
    expect(sourced.containsKey(NutrientId.fat), isFalse);
    expect(await c.portionNutrition(meals['unsourced']!), isNull);
  });
  test('a leftover reminds on the day the user chose', () async {
    final c = SofraController(
      store: f.Store(),
      recipes: f.repository(value: threeLines()),
      readAsset: (path) => File(path).readAsString(),
    );
    await c.load();
    await c.saveLeftovers(
      'كشري',
      2,
      on: DateTime(2026, 10, 26),
      remindAfterDays: 2,
    );
    await c.saveLeftovers('رز', 1, on: DateTime(2026, 10, 26));
    expect(c.leftoversDue(DateTime(2026, 10, 27)), isEmpty);
    expect(c.leftoversDue(DateTime(2026, 10, 28, 9)).single.name, 'كشري');
    final again = LeftoverDish.fromJson(c.leftovers.first.toJson());
    expect(again.remindAfterDays, 2);
    expect(c.leftovers.last.toJson().containsKey('remindAfterDays'), isFalse);
  });
  test(
    'bought items log a purchase only when the user says what they paid',
    () async {
      final c = SofraController(
        store: f.Store(),
        recipes: f.repository(value: threeLines()),
        readAsset: (path) => File(path).readAsString(),
      );
      await c.load();
      final rice = IngredientUse('rice', 1, 'kg');
      final salt = IngredientUse('salt', 500, 'g');
      await c.addBought([rice, salt], paid: {rice: 60});
      final purchases = c.kitchen.snapshot['purchases'] as List;
      expect(purchases, hasLength(1));
      expect(purchases.single['amount'], 60);
      expect(c.kitchen.inventory.map((l) => l.ingredientId), ['rice', 'salt']);
      final prices = c.kitchen.snapshot['prices'] as List;
      expect(prices.single['ingredientId'], 'rice');
    },
  );
  test('the shopping list reads as one line per item to share', () async {
    final c = SofraController(
      store: f.Store(),
      recipes: f.repository(value: threeLines()),
      readAsset: (path) => File(path).readAsString(),
    );
    await c.load();
    final text = c.shoppingText(
      PurchaseForecast(
        purchases: [
          ForecastPurchase(IngredientUse('rice', 1, 'kg'), null),
          ForecastPurchase(IngredientUse('salt', 500, 'g'), 5),
        ],
        knownPurchaseSubtotal: 5,
        purchaseTotal: null,
        knownConsumptionSubtotal: 0,
        consumptionTotal: null,
        unresolvedRequirements: {},
        unresolvedStock: {},
        unpricedPurchases: {'rice'},
        unpricedConsumption: {},
      ),
    );
    final lines = text.split('\n');
    expect(lines, hasLength(3));
    expect(lines.first, 'قائمة الشراء من سفرة:');
    expect(lines[1], startsWith('- ${c.ingredientName('rice')}: '));
    expect(lines[2], startsWith('- ${c.ingredientName('salt')}: '));
  });
  test(
    'cooking with less records the smaller amount as what was used',
    () async {
      final c = SofraController(
        store: f.Store(),
        recipes: f.repository(value: threeLines()),
        readAsset: (path) => File(path).readAsString(),
      );
      await c.load();
      await c.kitchen.addStock(
        InventoryLot(
          id: 'lot-a',
          ingredientId: 'sample',
          quantity: 150,
          unit: 'g',
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
      await c.kitchen.plan(
        PlannedMeal(
          id: 'm1',
          date: '2026-10-25',
          slot: 'lunch',
          recipeId: 'fixture',
          servings: 2,
        ),
      );
      final meal = c.kitchen.plans.single;
      final check = await c.checkPlan(meal);
      final record = await c.cook(meal, check, 'op-less', cookedLess: {0});
      expect(record, isNotNull);
      expect(c.kitchen.inventory.single.quantity, 0);
      expect((record!['consumed'] as List).single['quantity'], 150);
      expect(record['partialStockLines'] ?? const [], isNot(contains(0)));
    },
  );
}
