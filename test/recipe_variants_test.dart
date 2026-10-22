import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';
import 'package:tabkha_demo/data/state_store.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/market_profile.dart';
import 'package:tabkha_demo/domain/person_nutrition.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';
import 'package:tabkha_demo/domain/recipe_nutrition.dart';
import 'package:tabkha_demo/domain/recipe_variants.dart';

class Store implements StateStore {
  Map<String, dynamic>? data;
  bool fail = false;
  @override
  String get label => 'recipe-test';
  @override
  Future<Map<String, dynamic>?> load() async => data == null
      ? null
      : jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  @override
  Future<void> save(Map<String, dynamic> value) async {
    if (fail) throw StateError('failed save');
    data = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }
}

// Synthetic fixtures test arithmetic only, never shipped food/recipe facts.
CatalogRecipe recipe({String id = 'fixture', double amount = 200}) =>
    CatalogRecipe.fromJson({
      'id': id,
      'name': 'وصفة اختبار',
      'cuisine': 'اختبار',
      'category': 'اختبار',
      'description': 'Synthetic test fixture',
      'difficulty': 'سهل',
      'servings': 2,
      'prepTime': 1,
      'cookTime': 0,
      'totalTime': 1,
      'tags': <String>[],
      'ingredients': [
        {
          'id': 'sample',
          'name': 'عينة اختبار',
          'amount': amount,
          'unit': 'جرام',
        },
      ],
      'steps': [
        {'n': 1, 'text': 'خلط عينة الاختبار', 'duration': 1},
      ],
    });

RecipeRepository repository({CatalogRecipe? value}) {
  final r = value ?? recipe();
  return RecipeRepository(
    read: (path) async => jsonEncode(
      path.endsWith('index.json')
          ? {
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
            }
          : {
              'recipes': [r.toJson()],
            },
    ),
  );
}

PlannedMeal plan(String id, String recipeId, {String? key}) => PlannedMeal(
  id: id,
  date: '2026-10-12',
  slot: 'lunch',
  recipeId: recipeId,
  servings: 2,
  recipeRevisionKey: key,
);

RecipeRevision custom(RecipeRevision parent, String version, double amount) =>
    RecipeRevision(
      familyId: parent.familyId,
      revision: version,
      kind: RecipeRevisionKind.personal,
      parentKey: parent.key,
      region: 'EG',
      method: 'mix',
      recipe: recipe(id: 'my-fixture', amount: amount),
    );

RecipeFoodSelection selection(RecipeRevision revision) => RecipeFoodSelection(
  recipeId: revision.variantId,
  recipeRevisionKey: revision.key,
  line: 0,
  amountForm: FoodForm.raw,
  preparedForm: FoodForm.raw,
  food: FoodRecord(
    id: 'test-food',
    version: '1',
    nameAr: 'عينة غذائية اختبار',
    kind: FoodKind.generic,
    form: FoodForm.raw,
    sources: [
      FoodSource(
        id: 'fixture',
        url: 'https://example.org/test',
        authority: 'Synthetic test, not food facts',
        license: 'test-only',
        retrievedAt: DateTime.utc(2026, 10, 12),
      ),
    ],
    nutrition: NutrientProfile(
      basis: NutritionBasis(amount: 100, unit: FoodQuantityUnit.g),
      values: {NutrientId.protein: NutrientValue(value: 10)},
    ),
    allergens: [
      AllergenDeclaration(
        allergenId: 'milk',
        status: AllergenStatus.contains,
        evidence: 'Synthetic fixture declaration',
        sourceId: 'fixture',
      ),
    ],
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all catalog recipes round-trip complete snapshot content', () async {
    final recipes = await RecipeRepository(read: (p) => File(p).readAsString())
        .loadAll(includeHeld: true);
    expect(recipes.length, 657);
    for (final r in recipes) {
      final saved = r.toJson();
      final restored = CatalogRecipe.fromJson(saved);
      expect(restored.toJson(), saved);
      expect(recipeSnapshotVersion(restored), recipeSnapshotVersion(r));
      (saved['ingredients'] as List).clear();
      expect(restored.ingredients, isNotEmpty);
    }
  });

  test(
    'revisions are immutable and retries cannot roll active choices backwards',
    () {
      final base = RecipeRevision(
        familyId: 'family',
        revision: 'base',
        kind: RecipeRevisionKind.catalog,
        recipe: recipe(),
      );
      final first = custom(base, 'v1', 100), next = custom(base, 'v2', 300);
      final book = RecipeBook.empty()
          .addFamily(RecipeFamily(id: 'family', name: 'عائلة'))
          .addRevision(base)
          .addRevision(first)
          .addRevision(next);
      expect(book.addRevision(first).active['my-fixture'], next.key);
      expect(() => book.addRevision(custom(base, 'v1', 999)), throwsStateError);
      expect(book.variants('family').length, 2);
      expect(
        RecipeBook.fromJson(book.toJson())
            .revisions[first.key]!
            .recipe
            .ingredients
            .single
            .amount,
        100,
      );
      final changed = recipe().toJson()..['notes'] = 'changed metadata';
      expect(
        recipeSnapshotVersion(CatalogRecipe.fromJson(changed)),
        isNot(recipeSnapshotVersion(recipe())),
      );
    },
  );

  test('cross-family parents and malformed stored references are rejected', () {
    final base = RecipeRevision(
      familyId: 'one',
      revision: 'base',
      kind: RecipeRevisionKind.catalog,
      recipe: recipe(),
    );
    final book = RecipeBook.empty()
        .addFamily(RecipeFamily(id: 'one', name: 'one'))
        .addFamily(RecipeFamily(id: 'two', name: 'two'))
        .addRevision(base);
    expect(
      () => book.addRevision(
        RecipeRevision(
          familyId: 'two',
          revision: '1',
          kind: RecipeRevisionKind.personal,
          recipe: recipe(id: 'other'),
          parentKey: base.key,
        ),
      ),
      throwsFormatException,
    );
    final broken = book.toJson();
    (broken['active'] as Map)['fixture'] = 'missing';
    expect(() => RecipeBook.fromJson(broken), throwsFormatException);
  });

  test(
    'old plans stay pinned while new plans select a new personal revision',
    () async {
      final store = Store();
      final k = KitchenService(store, repository());
      await k.load();
      final base = await k.catalogRevision('fixture');
      final first = custom(base, 'v1', 100), next = custom(base, 'v2', 300);
      await k.saveRecipeRevision(first);
      await k.plan(plan('old', first.variantId));
      await k.saveRecipeRevision(next);
      await k.plan(plan('new', next.variantId));
      expect((await k.recipeForMeal('old')).key, first.key);
      expect((await k.recipeForMeal('new')).key, next.key);
      final reload = KitchenService(k.store, repository());
      await reload.load();
      expect(
        (await reload.recipeForMeal('old')).recipe.ingredients.single.amount,
        100,
      );
      expect(reload.plans.length, 2);
    },
  );

  test(
    'nutrition and allergen bindings never leak across recipe revisions',
    () async {
      final k = KitchenService(Store(), repository());
      await k.load();
      final base = await k.catalogRevision('fixture');
      final first = custom(base, 'v1', 100), next = custom(base, 'v2', 300);
      await k.saveRecipeRevision(first);
      await k.saveRecipeFoodSelection(selection(first));
      await k.plan(plan('old', first.variantId));
      await k.saveRecipeRevision(next);
      await k.plan(plan('new', next.variantId));
      expect(
        (await k.previewNutrition('old')).whole[NutrientId.protein]!.value,
        10,
      );
      final missing = await k.previewNutrition('new');
      expect(missing.whole[NutrientId.protein]!.value, isNull);
      expect(
        nutritionMealBatch(
          missing,
          batchId: 'n',
          sourceSnapshotId: 'n',
          allergenIds: {'milk'},
        ).allergens['milk'],
        AllergenPresence.unknown,
      );
      await k.saveRecipeFoodSelection(selection(next));
      expect(
        (await k.previewNutrition('new')).whole[NutrientId.protein]!.value,
        30,
      );
      expect(
        (await k.previewNutrition('old')).whole[NutrientId.protein]!.value,
        10,
      );
      expect(
        () => assessRecipeNutrition(
          scaled: next.recipe.forServings(2),
          selections: [selection(first)],
          recipeRevisionKey: next.key,
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'cooking freezes custom content, stock and nutrition once with rollback',
    () async {
      final store = Store(), repo = repository();
      final k = KitchenService(store, repo);
      await k.load();
      final base = await k.catalogRevision('fixture');
      final first = custom(base, 'v1', 100);
      await k.saveRecipeRevision(first);
      await k.saveRecipeFoodSelection(selection(first));
      await k.plan(plan('dinner', first.variantId));
      await k.addStock(
        InventoryLot(
          id: 'lot',
          ingredientId: 'sample',
          quantity: 1000,
          unit: 'جرام',
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
      await k.savePrice(
        MarketPrice(
          country: MarketCountry.egypt,
          ingredientId: 'sample',
          unit: 'جرام',
          quantity: 100,
          amount: 2,
          recordedAt: DateTime.utc(2026, 10, 12),
          source: 'synthetic test price',
        ),
        userOverride: true,
      );
      store.fail = true;
      await expectLater(k.confirmCooking('dinner', 'cook'), throwsStateError);
      expect(k.inventory.single.quantity, 1000);
      expect(k.nutritionLedger.batches, isEmpty);
      store.fail = false;
      final receipts = await Future.wait([
        k.confirmCooking('dinner', 'cook'),
        k.confirmCooking('dinner', 'cook'),
      ]);
      expect(k.inventory.single.quantity, 900);
      expect(k.nutritionLedger.batches.length, 1);
      expect(receipts.first['recipeRevision'], first.toJson());
      expect(receipts.first['cost'], 2);
      expect(
        k
            .nutritionLedger
            .batches
            .values
            .single
            .nutrients['protein']!
            .knownSubtotal,
        10,
      );
      await k.saveRecipeRevision(custom(base, 'v2', 300));
      await k.savePrice(
        MarketPrice(
          country: MarketCountry.egypt,
          ingredientId: 'sample',
          unit: 'جرام',
          quantity: 100,
          amount: 5,
          recordedAt: DateTime.utc(2026, 10, 12),
          source: 'updated synthetic test price',
        ),
        userOverride: true,
      );
      final reload = KitchenService(store, repo);
      await reload.load();
      expect(await reload.confirmCooking('dinner', 'cook'), receipts.first);
      expect(reload.inventory.single.quantity, 900);
    },
  );

  test('catalog updates cannot rewrite an already planned snapshot', () async {
    final store = Store();
    final k = KitchenService(store, repository());
    await k.load();
    await k.plan(plan('old', 'fixture'));
    final oldKey = k.plans.single.recipeRevisionKey;
    final updated = KitchenService(
      k.store,
      repository(value: recipe(amount: 500)),
    );
    await updated.load();
    await updated.plan(plan('new', 'fixture'));
    expect(
      (await updated.recipeForMeal('old')).recipe.ingredients.single.amount,
      200,
    );
    expect(
      (await updated.recipeForMeal('new')).recipe.ingredients.single.amount,
      500,
    );
    expect(updated.plans.first.recipeRevisionKey, oldKey);
    expect(store.data, isNotNull);
  });

  test('failed revision save preserves active content and rejects catalog identity theft', () async {
    final store = Store();
    final k = KitchenService(store, repository());
    await k.load();
    final base = await k.catalogRevision('fixture');
    store.fail = true;
    await expectLater(
      k.saveRecipeRevision(custom(base, 'v1', 100)),
      throwsStateError,
    );
    expect(k.recipeBook.active.containsKey('my-fixture'), false);
    store.fail = false;
    await expectLater(
      k.saveRecipeRevision(
        RecipeRevision(
          familyId: base.familyId,
          revision: 'steal',
          kind: RecipeRevisionKind.variant,
          recipe: recipe(),
        ),
      ),
      throwsStateError,
    );
    await expectLater(
      k.plan(plan('bad', 'my-fixture', key: 'missing')),
      throwsStateError,
    );
    expect(store.data, isNotNull);
  });

  test(
    'repeated ingredients support independent line choices and measurements',
    () async {
      final k = KitchenService(Store(), repository());
      await k.load();
      final base = await k.catalogRevision('fixture');
      final data = recipe(id: 'repeated').toJson();
      data['ingredients'] = [
        for (var i = 0; i < 2; i++)
          {
            'id': 'sample',
            'name': 'test line $i',
            'amount': null,
            'unit': 'جرام',
            'scale': false,
            'optional': true,
          },
      ];
      final revision = RecipeRevision(
        familyId: base.familyId,
        revision: '1',
        kind: RecipeRevisionKind.variant,
        parentKey: base.key,
        recipe: CatalogRecipe.fromJson(data),
      );
      await k.saveRecipeRevision(revision);
      for (var i = 0; i < 2; i++) {
        await k.saveRecipeFoodSelection(
          RecipeFoodSelection.fromJson({
            ...selection(revision).toJson(),
            'line': i,
          }),
        );
      }
      await k.plan(plan('both', revision.variantId));
      await k.addStock(
        InventoryLot(
          id: 'lot',
          ingredientId: 'sample',
          quantity: 1000,
          unit: 'جرام',
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
      await expectLater(
        k.confirmCooking(
          'both',
          'ambiguous',
          optionalLines: {0, 1},
          measuredUses: {'sample': IngredientUse('sample', 100, 'جرام')},
        ),
        throwsStateError,
      );
      expect(k.inventory.single.quantity, 1000);
      final single = await k.previewNutrition(
        'both',
        optionalLines: {1},
        measuredLines: {1: FoodAmount(value: 150, unit: FoodQuantityUnit.g)},
      );
      expect(single.whole[NutrientId.protein]!.value, 15);
      final receipt = await k.confirmCooking(
        'both',
        'cook-both',
        optionalLines: {0, 1},
        measuredUsesByLine: {
          0: IngredientUse('sample', 100, 'جرام'),
          1: IngredientUse('sample', 200, 'جرام'),
        },
      );
      expect(k.inventory.single.quantity, 700);
      expect(receipt['selectedOptionalLines'], [0, 1]);
      expect((receipt['consumed'] as List).map((r) => r['quantity']).toList(), [
        100,
        200,
      ]);
      expect(
        k
            .nutritionLedger
            .batches
            .values
            .single
            .nutrients['protein']!
            .knownSubtotal,
        30,
      );
      await k.plan(plan('omit', revision.variantId));
      final omitted = await k.confirmCooking(
        'omit',
        'omit-line',
        optionalLines: {0, 1},
        omitUnmeasuredLines: {0},
        measuredUsesByLine: {1: IngredientUse('sample', 50, 'جرام')},
      );
      expect(k.inventory.single.quantity, 650);
      expect(omitted['omittedUnmeasuredLines'], [0]);
      await k.plan(plan('empty', revision.variantId));
      await expectLater(
        k.confirmCooking(
          'empty',
          'empty-cook',
          optionalLines: {0},
          omitUnmeasuredLines: {0},
        ),
        throwsArgumentError,
      );
      expect(k.inventory.single.quantity, 650);
      expect(k.plans.singleWhere((p) => p.id == 'empty').completed, false);
      expect(
        k
            .nutritionLedger
            .batches['cooked:omit-line']!
            .nutrients['protein']!
            .knownSubtotal,
        5,
      );
    },
  );

  test('legacy unversioned selections remain stored but require explicit re-review', () async {
    final store = Store(), repo = repository();
    final k = KitchenService(store, repo);
    await k.load();
    final base = await k.catalogRevision('fixture');
    await k.saveRecipeFoodSelection(selection(base));
    await k.plan(plan('meal', 'fixture'));
    final state = store.data!['kitchen'] as Map;
    final bindings = (state['nutrition'] as Map)['selections'] as Map;
    (bindings.values.single as Map)['recipeRevisionKey'] = null;
    final restored = KitchenService(store, repo);
    await restored.load();
    expect(
      (await restored.previewNutrition('meal'))
          .whole[NutrientId.protein]!
          .value,
      isNull,
    );
    expect(
      ((restored.snapshot['nutrition'] as Map)['selections'] as Map).length,
      1,
    );
    await restored.saveRecipeFoodSelection(selection(base));
    expect(
      (await restored.previewNutrition('meal'))
          .whole[NutrientId.protein]!
          .value,
      20,
    );
  });
  test(
    'actual unknown measurement unit never falls back to a reviewed weight',
    () async {
      final k = KitchenService(Store(), repository());
      await k.load();
      final base = await k.catalogRevision('fixture');
      final data = recipe(id: 'unknown-unit').toJson();
      data['ingredients'] = [
        {
          'id': 'sample',
          'name': 'test',
          'amount': null,
          'unit': 'جرام',
          'scale': false,
        },
      ];
      final revision = RecipeRevision(
        familyId: base.familyId,
        revision: '1',
        kind: RecipeRevisionKind.variant,
        recipe: CatalogRecipe.fromJson(data),
      );
      await k.saveRecipeRevision(revision);
      await k.saveRecipeFoodSelection(
        RecipeFoodSelection.fromJson({
          ...selection(revision).toJson(),
          'measuredAmount': FoodAmount(
            value: 100,
            unit: FoodQuantityUnit.g,
          ).toJson(),
        }),
      );
      await k.plan(plan('unknown', revision.variantId));
      await k.addStock(
        InventoryLot(
          id: 'scoops',
          ingredientId: 'sample',
          quantity: 20,
          unit: 'scoop',
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
      await expectLater(
        k.confirmCooking(
          'unknown',
          'unknown-cook',
          measuredUsesByLine: {0: IngredientUse('sample', 2, 'scoop')},
        ),
        throwsStateError,
      );
      expect(k.inventory.single.quantity, 20);
      expect(k.plans.single.completed, false);
      expect(k.nutritionLedger.batches, isEmpty);
    },
  );
}
