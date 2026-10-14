import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/food_repository.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/data/preparation_category_repository.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';
import 'package:tabkha_demo/domain/recipe_nutrition.dart';

import 'recipe_variants_test.dart' as fixture;

Future<String> read(String p) => File(p).readAsString();

class Setup {
  final store = fixture.Store();
  final preparations = PreparationCategoryRepository(read: read);
  late KitchenService kitchen;
  late CatalogRecipe recipe;
  late RecipeFoodSelection binding;
  Future<void> load({bool optional = false, bool unmeasured = false}) async {
    final j = fixture.recipe().toJson();
    j['ingredients'] = [
      {
        'id': 'sample',
        'name': 'عينة مكرونة اختبار',
        'amount': unmeasured ? null : 200,
        'scale': !unmeasured,
        'unit': 'g',
        'optional': optional,
      },
      if (optional || unmeasured)
        {'id': 'required', 'name': 'عينة ثانية', 'amount': 1, 'unit': 'g'},
    ];
    recipe = CatalogRecipe.fromJson(j);
    kitchen = KitchenService(store, fixture.repository(value: recipe));
    await kitchen.load();
    final revision = await kitchen.catalogRevision(recipe.id);
    final food = await FoodRepository(read: read)
        .usdaFood('usda:168927', form: 'asSold');
    binding = RecipeFoodSelection(
      recipeId: recipe.id,
      recipeRevisionKey: revision.key,
      line: 0,
      food: food,
      amountForm: FoodForm.asSold,
      preparedForm: FoodForm.asSold,
    );
    await kitchen.saveRecipeFoodSelection(binding);
    await kitchen.plan(fixture.plan('meal', recipe.id));
    for (final id in ['sample', 'required']) {
      await kitchen.addStock(
        InventoryLot(
          id: id,
          ingredientId: id,
          quantity: 10000,
          unit: 'g',
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
    }
  }

  Future<void> accept({
    PreparationCategoryRepository? repository,
    String code = '0381',
    bool replace = false,
    bool ack = true,
  }) => kitchen.acceptRecipePreparationEstimate(
    'meal',
    repository ?? preparations,
    line: 0,
    retentionCode: code,
    reviewNote: 'اختبار قبول طريقة التحضير الفعلية',
    acceptedAt: DateTime.utc(2026, 10, 14),
    acknowledgeCategoryEstimate: ack,
    acknowledgeUnknownLicense: true,
    replaceExisting: replace,
  );
  RecipeFoodSelection get saved => RecipeFoodSelection.fromJson(
    Map<String, dynamic>.from(
      ((kitchen.snapshot['nutrition'] as Map)['selections'] as Map)
          .values
          .single,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('acceptance persists exact revision source and input preview stays pre-cooking', () async {
    final f = Setup();
    await f.load();
    final before = await f.kitchen.previewIngredientNutrition('meal');
    final stock = f.kitchen.inventory.map((v) => v.toJson()).toList();
    await f.accept();
    final evidence = jsonDecode(f.saved.preparation!.evidence!) as Map;
    expect(evidence['recipeRevisionKey'], f.binding.recipeRevisionKey);
    expect(evidence['recipeId'], f.recipe.id);
    expect(evidence['line'], 0);
    expect(f.saved.preparation!.estimated, true);
    expect(f.saved.preparation!.massYield, isNull);
    expect(f.saved.preparation!.retention.length, 3);
    final reload = KitchenService(f.store, fixture.repository(value: f.recipe));
    await reload.load();
    final after = await reload.previewIngredientNutrition('meal');
    expect(
      after.whole[NutrientId.thiamin]!.toJson(),
      before.whole[NutrientId.thiamin]!.toJson(),
    );
    expect(reload.inventory.map((v) => v.toJson()).toList(), stock);
  });
  test('explicit acceptance and replacement are atomic, replacing methods never layers factors', () async {
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
    await expectLater(f.accept(code: '0382'), throwsStateError);
    expect(f.kitchen.snapshot, accepted);
    await f.accept(code: '0382', replace: true);
    expect(f.saved.preparation!.retention[NutrientId.thiamin], 0.55);
    expect(f.saved.preparation!.retention[NutrientId.vitaminC], 0.6);
  });
  test('cooking requires estimate acknowledgement even with actual grams and freezes incomplete nutrition once', () async {
    final f = Setup();
    await f.load();
    await f.accept();
    final accepted = f.kitchen.snapshot;
    final actual = {0: IngredientUse('sample', 100, 'g')};
    await expectLater(
      f.kitchen.confirmCooking('meal', 'op', actualUsesByLine: actual),
      throwsStateError,
    );
    expect(f.kitchen.snapshot, accepted);
    f.store.fail = true;
    await expectLater(
      f.kitchen.confirmCooking(
        'meal',
        'op',
        actualUsesByLine: actual,
        acknowledgePreparationEstimates: true,
      ),
      throwsStateError,
    );
    expect(f.kitchen.snapshot, accepted);
    f.store.fail = false;
    final h = await f.kitchen.confirmCooking(
      'meal',
      'op',
      actualUsesByLine: actual,
      acknowledgePreparationEstimates: true,
    );
    expect(h['estimatedPreparationLines'], [0]);
    expect(
      (h['preparationEstimateEvidence'] as Map)['0'],
      jsonDecode(f.saved.preparation!.evidence!),
    );
    final batch = f.kitchen.nutritionLedger.batches.values.single;
    final base = f.binding.food.nutrition.values[NutrientId.thiamin]!.value!;
    expect(batch.nutrients['thiamin']!.value, closeTo(base * 0.65, 1e-9));
    expect(batch.nutrients['thiamin']!.estimated, true);
    expect(batch.nutrients['protein']!.value, isNull);
    expect(f.kitchen.nutritionLedger.events, isEmpty);
    expect(
      f.kitchen.inventory
          .firstWhere((v) => v.ingredientId == 'sample')
          .quantity,
      9900,
    );
    final frozen = f.kitchen.snapshot;
    expect(await f.kitchen.confirmCooking('meal', 'op'), h);
    expect(f.kitchen.snapshot, frozen);
    await expectLater(f.accept(replace: true), throwsStateError);
    final reload = KitchenService(f.store, fixture.repository(value: f.recipe));
    await reload.load();
    expect(reload.snapshot, frozen);
  });
  test('saved category evidence cannot move line, revision, food or upgrade confidence', () async {
    final f = Setup();
    await f.load();
    await f.accept();
    final accepted = f.kitchen.snapshot;
    Future<void> reject(void Function(Map<String, dynamic>) mutate) async {
      final j = f.saved.toJson();
      mutate(j);
      await expectLater(
        Future(
          () async => f.kitchen.saveRecipeFoodSelection(
            RecipeFoodSelection.fromJson(j),
          ),
        ),
        throwsA(anything),
      );
      expect(f.kitchen.snapshot, accepted);
    }

    await reject((j) {
      final p = j['preparation'] as Map;
      final e = jsonDecode(p['evidence'] as String) as Map;
      e['line'] = 1;
      p['evidence'] = jsonEncode(e);
    });
    await reject((j) => (j['preparation'] as Map)['estimated'] = false);
    await reject(
      (j) => ((j['preparation'] as Map)['retention'] as Map)['thiamin'] = 1.0,
    );
    await reject((j) {
      final p = j['preparation'] as Map;
      final e = jsonDecode(p['evidence'] as String) as Map;
      e.remove('kind');
      p['evidence'] = jsonEncode(e);
    });
    await reject((j) => (j['food'] as Map)['version'] = 'changed');
    await reject((j) => j['preparedForm'] = 'asSold');
    await reject((j) => j['asPurchased'] = true);
  });
  test(
    'binding changed during asynchronous review rejects stale acceptance',
    () async {
      final f = Setup();
      await f.load();
      final entered = Completer<void>(), release = Completer<void>();
      var blocked = false;
      final delayed = PreparationCategoryRepository(
        read: (p) async {
          if (!blocked) {
            blocked = true;
            entered.complete();
            await release.future;
          }
          return read(p);
        },
      );
      final pending = f.accept(repository: delayed);
      await entered.future;
      await f.kitchen.saveRecipeFoodSelection(
        RecipeFoodSelection.fromJson({
          ...f.binding.toJson(),
          'measuredAmount': {'value': 150, 'unit': 'g'},
        }),
      );
      final changed = f.kitchen.snapshot;
      release.complete();
      await expectLater(pending, throwsStateError);
      expect(f.kitchen.snapshot, changed);
    },
  );
  test('unselected optional and explicitly omitted unknown lines do not require estimate acknowledgement', () async {
    for (final optional in [true, false]) {
      final f = Setup();
      await f.load(optional: optional, unmeasured: !optional);
      await f.accept();
      if (optional) {
        await expectLater(
          f.kitchen.confirmCooking('meal', 'selected', optionalLines: {0}),
          throwsStateError,
        );
      }
      final h = await f.kitchen.confirmCooking(
        'meal',
        'skip',
        omitUnmeasuredLines: optional ? {} : {0},
      );
      expect(h['estimatedPreparationLines'], isEmpty);
      expect(h['preparationEstimateEvidence'], isEmpty);
      expect(
        f.kitchen.inventory
            .firstWhere((v) => v.ingredientId == 'sample')
            .quantity,
        10000,
      );
    }
  });
}
