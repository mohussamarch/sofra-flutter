import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/food_repository.dart';
import 'package:tabkha_demo/data/household_measure_repository.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/market_profile.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';
import 'package:tabkha_demo/domain/recipe_nutrition.dart';

import 'recipe_variants_test.dart' as fixture;

Future<String> read(String p) => File(p).readAsString();

class Setup {
  final store = fixture.Store();
  late KitchenService kitchen;
  late CatalogRecipe recipe;
  late RecipeFoodSelection binding;
  late HouseholdMeasureReview review;
  final measures = HouseholdMeasureRepository(read: read);
  Future<void> load({bool optional = false, bool scales = true}) async {
    final j = fixture.recipe().toJson();
    j['ingredients'] = [
      {
        'id': 'onion',
        'name': 'بصل اختبار',
        'amount': 1,
        'unit': 'حبة',
        'optional': optional,
        'scale': scales,
      },
      if (optional)
        {'id': 'sample', 'name': 'عينة لازمة', 'amount': 1, 'unit': 'g'},
    ];
    recipe = CatalogRecipe.fromJson(j);
    kitchen = KitchenService(store, fixture.repository(value: recipe));
    await kitchen.load();
    final revision = await kitchen.catalogRevision(recipe.id),
        food = await FoodRepository(read: read)
            .usdaFood('usda:170000', form: 'raw');
    binding = RecipeFoodSelection(
      recipeId: recipe.id,
      recipeRevisionKey: revision.key,
      line: 0,
      food: food,
      amountForm: FoodForm.raw,
      preparedForm: FoodForm.raw,
    );
    await kitchen.saveRecipeFoodSelection(binding);
    await kitchen.plan(
      PlannedMeal(
        id: 'meal',
        date: '2026-10-13',
        slot: 'lunch',
        recipeId: recipe.id,
        servings: 4,
      ),
    );
    review = await measures.optionsFor(food);
    await kitchen.addStock(
      InventoryLot(
        id: 'lot',
        ingredientId: 'onion',
        quantity: 10000,
        unit: 'g',
        zone: StorageZone.fridge,
      ),
      newPurchase: false,
    );
    if (optional) {
      await kitchen.addStock(
        InventoryLot(
          id: 'required',
          ingredientId: 'sample',
          quantity: 100,
          unit: 'g',
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
    }
    await kitchen.savePrice(
      MarketPrice(
        country: MarketCountry.egypt,
        ingredientId: 'onion',
        unit: 'g',
        quantity: 1,
        amount: 0.1,
        recordedAt: DateTime.utc(2026, 10, 13),
        source: 'synthetic test price',
      ),
      userOverride: true,
    );
  }

  Future<void> accept({
    HouseholdMeasureRepository? repo,
    bool replace = false,
    bool ack = true,
    double quantity = 1,
  }) => kitchen.acceptRecipeHouseholdMeasure(
    'meal',
    repo ?? measures,
    line: 0,
    optionId: review.options.first.id,
    measureQuantity: quantity,
    acknowledgeExactSourcePortion: ack,
    replaceExisting: replace,
  );
  double get baseGrams =>
      review.options.first.gramWeight / review.options.first.amount;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('accepted source measure persists by exact revision and scales count preview without stock write', () async {
    final f = Setup();
    await f.load();
    final before = f.kitchen.inventory.single.quantity;
    await f.accept();
    final reload = KitchenService(f.store, fixture.repository(value: f.recipe));
    await reload.load();
    final result = await reload.previewIngredientNutrition('meal');
    expect(
      result.whole[NutrientId.protein]!.value,
      closeTo(
        f.binding.food.nutrition.values[NutrientId.protein]!.value! *
            f.baseGrams *
            2 /
            100,
        1e-9,
      ),
    );
    expect(reload.inventory.single.quantity, before);
    final selections =
        (reload.snapshot['nutrition'] as Map)['selections'] as Map;
    final saved = RecipeFoodSelection.fromJson(
      Map<String, dynamic>.from(selections.values.single),
    );
    final evidence = jsonDecode(saved.householdMeasureEvidence!);
    expect(evidence['estimated'], true);
    expect(evidence['recipeRevisionKey'], f.binding.recipeRevisionKey);
    expect(evidence['line'], 0);
  });
  test('acceptance and replacement are explicit; failed save leaves prior selection', () async {
    final f = Setup();
    await f.load();
    final before = f.kitchen.snapshot;
    await expectLater(f.accept(ack: false), throwsArgumentError);
    expect(f.kitchen.snapshot, before);
    f.store.fail = true;
    await expectLater(f.accept(), throwsStateError);
    expect(f.kitchen.snapshot, before);
    f.store.fail = false;
    await f.accept();
    final accepted = f.kitchen.snapshot;
    await expectLater(f.accept(quantity: 2), throwsStateError);
    expect(f.kitchen.snapshot, accepted);
    await f.accept(quantity: 2, replace: true);
    expect(f.kitchen.snapshot, isNot(accepted));
  });
  test('source estimates need cooking acknowledgement and freeze consistent use/cost/nutrition once', () async {
    final f = Setup();
    await f.load();
    await f.accept();
    final before = f.kitchen.snapshot;
    await expectLater(f.kitchen.confirmCooking('meal', 'op'), throwsStateError);
    expect(f.kitchen.snapshot, before);
    f.store.fail = true;
    await expectLater(
      f.kitchen.confirmCooking(
        'meal',
        'op',
        acknowledgeSourceMeasureEstimates: true,
      ),
      throwsStateError,
    );
    expect(f.kitchen.snapshot, before);
    f.store.fail = false;
    final h = await f.kitchen.confirmCooking(
      'meal',
      'op',
      acknowledgeSourceMeasureEstimates: true,
    );
    final grams = f.baseGrams * 2;
    expect(f.kitchen.inventory.single.quantity, closeTo(10000 - grams, 1e-9));
    expect(h['cost'], closeTo(grams * 0.1, 1e-9));
    expect(h['estimatedSourceMeasureLines'], [0]);
    expect((h['sourceMeasureEvidence'] as Map)['0'], isNotNull);
    expect(
      f
          .kitchen
          .nutritionLedger
          .batches
          .values
          .single
          .nutrients['protein']!
          .knownSubtotal,
      closeTo(
        f.binding.food.nutrition.values[NutrientId.protein]!.value! *
            grams /
            100,
        1e-9,
      ),
    );
    expect(await f.kitchen.confirmCooking('meal', 'op'), h);
    expect(f.kitchen.inventory.single.quantity, closeTo(10000 - grams, 1e-9));
  });
  test('actual quantity overrides count and source estimate for all accounting without estimated flag', () async {
    final f = Setup();
    await f.load();
    await f.accept();
    final h = await f.kitchen.confirmCooking(
      'meal',
      'op',
      actualUsesByLine: {0: IngredientUse('onion', 150, 'g')},
    );
    expect(f.kitchen.inventory.single.quantity, 9850);
    expect(h['cost'], 15);
    expect(h['estimatedSourceMeasureLines'], isEmpty);
    expect(
      f
          .kitchen
          .nutritionLedger
          .batches
          .values
          .single
          .nutrients['protein']!
          .knownSubtotal,
      closeTo(
        f.binding.food.nutrition.values[NutrientId.protein]!.value! * 1.5,
        1e-9,
      ),
    );
    final frozen = jsonEncode(h);
    await f.kitchen.saveRecipeFoodSelection(f.binding);
    expect(jsonEncode(await f.kitchen.confirmCooking('meal', 'op')), frozen);
  });
  test('optional unused estimates are ignored and non-scaling source amounts stay fixed', () async {
    final f = Setup();
    await f.load(optional: true, scales: false);
    await f.accept();
    final preview = await f.kitchen.previewIngredientNutrition(
      'meal',
      optionalLines: {0},
    );
    expect(
      preview.whole[NutrientId.protein]!.knownSubtotal,
      closeTo(
        f.binding.food.nutrition.values[NutrientId.protein]!.value! *
            f.baseGrams /
            100,
        1e-9,
      ),
    );
    final h = await f.kitchen.confirmCooking('meal', 'op');
    expect(h['estimatedSourceMeasureLines'], isEmpty);
    expect(
      f.kitchen.inventory
          .where((v) => v.ingredientId == 'onion')
          .single
          .quantity,
      10000,
    );
  });
  test('binding changes while source loads reject atomic acceptance', () async {
    final f = Setup();
    await f.load();
    final started = Completer<void>(), release = Completer<void>();
    final slow = HouseholdMeasureRepository(
      read: (p) async {
        if (p.endsWith('household-measures-review.json')) {
          started.complete();
          await release.future;
        }
        return read(p);
      },
    );
    final future = f.accept(repo: slow);
    await started.future;
    await f.kitchen.saveRecipeFoodSelection(
      RecipeFoodSelection.fromJson({
        ...f.binding.toJson(),
        'preparedForm': 'cooked',
      }),
    );
    final before = f.kitchen.snapshot;
    release.complete();
    await expectLater(future, throwsStateError);
    expect(f.kitchen.snapshot, before);
  });
  test(
    'invalid actual line and legacy/new overlap cannot mutate state',
    () async {
      final f = Setup();
      await f.load();
      final before = f.kitchen.snapshot;
      await expectLater(
        f.kitchen.confirmCooking(
          'meal',
          'bad',
          actualUsesByLine: {0: IngredientUse('other', 10, 'g')},
        ),
        throwsArgumentError,
      );
      await expectLater(
        f.kitchen.confirmCooking(
          'meal',
          'bad',
          actualUsesByLine: {0: IngredientUse('onion', 10, 'g')},
          measuredUsesByLine: {0: IngredientUse('onion', 10, 'g')},
        ),
        throwsArgumentError,
      );
      expect(f.kitchen.snapshot, before);
    },
  );
  test('legacy selection JSON without measure field accepts a new reviewed measure', () async {
    final f = Setup();
    await f.load();
    final stored =
        (f.store.data!['kitchen']['nutrition']['selections'] as Map)
                .values
                .single
            as Map;
    stored.remove('householdMeasureEvidence');
    await f.kitchen.load();
    await f.accept();
    expect(
      (await f.kitchen.previewIngredientNutrition('meal'))
          .whole[NutrientId.protein]!
          .value,
      isNotNull,
    );
  });
  test('serialized acceptance rejects changed food, revision, amount or estimate status', () async {
    final f = Setup();
    await f.load();
    await f.accept();
    final saved = Map<String, dynamic>.from(
      (f.kitchen.snapshot['nutrition']['selections'] as Map).values.single,
    );
    final evidence =
        jsonDecode(saved['householdMeasureEvidence']) as Map<String, dynamic>;
    for (final patch in [
      {'foodVersion': 'changed'},
      {'recipeRevisionKey': 'changed'},
      {'estimated': false},
      {
        'amount': {'value': 1, 'unit': 'g'},
      },
    ]) {
      expect(
        () => RecipeFoodSelection.fromJson({
          ...saved,
          'householdMeasureEvidence': jsonEncode({...evidence, ...patch}),
        }),
        throwsFormatException,
      );
    }
  });
  test('actual unfamiliar units roll back stock and history; source does not override mass line', () async {
    final f = Setup();
    await f.load();
    final before = f.kitchen.snapshot;
    await expectLater(
      f.kitchen.confirmCooking(
        'meal',
        'op',
        actualUsesByLine: {0: IngredientUse('onion', 1, 'unknown')},
      ),
      throwsStateError,
    );
    expect(f.kitchen.snapshot, before);
    final k = KitchenService(fixture.Store(), fixture.repository());
    await k.load();
    final rev = await k.catalogRevision('fixture');
    await k.saveRecipeFoodSelection(
      RecipeFoodSelection(
        recipeId: 'fixture',
        recipeRevisionKey: rev.key,
        line: 0,
        food: f.binding.food,
        amountForm: FoodForm.raw,
        preparedForm: FoodForm.raw,
      ),
    );
    await k.plan(fixture.plan('mass', 'fixture'));
    await expectLater(
      k.acceptRecipeHouseholdMeasure(
        'mass',
        f.measures,
        line: 0,
        optionId: f.review.options.first.id,
        measureQuantity: 1,
        acknowledgeExactSourcePortion: true,
      ),
      throwsStateError,
    );
  });
  test('analytical nutrient still reports estimated when source portion supplies the quantity', () async {
    final f = Setup();
    await f.load();
    final food = await FoodRepository(read: read)
        .usdaFood('usda:168927', form: 'asSold');
    final review = await f.measures.optionsFor(food);
    await f.kitchen.saveRecipeFoodSelection(
      RecipeFoodSelection.fromJson({
        ...f.binding.toJson(),
        'food': food.toJson(),
        'amountForm': 'asSold',
        'preparedForm': 'asSold',
      }),
    );
    await f.kitchen.acceptRecipeHouseholdMeasure(
      'meal',
      f.measures,
      line: 0,
      optionId: review.options.first.id,
      measureQuantity: 1,
      acknowledgeExactSourcePortion: true,
    );
    final result = await f.kitchen.previewNutrition('meal');
    expect(
      food.nutrition.values[NutrientId.protein]!.method,
      NutrientMethod.analytical,
    );
    expect(result.whole[NutrientId.protein]!.estimated, true);
    expect(result.toJson()['snapshot'][0]['quantityEstimated'], true);
    expect(
      RecipeNutritionResult.fromJson(result.toJson()).toJson(),
      result.toJson(),
    );
    final actual = await f.kitchen.previewNutrition(
      'meal',
      measuredLines: {0: FoodAmount(value: 100, unit: FoodQuantityUnit.g)},
    );
    expect(actual.whole[NutrientId.protein]!.estimated, false);
    expect(actual.toJson()['snapshot'][0]['quantityEstimated'], false);
  });
}
