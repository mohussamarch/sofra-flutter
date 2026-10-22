import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/food_repository.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';
import 'package:tabkha_demo/data/state_store.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/person_nutrition.dart';
import 'package:tabkha_demo/domain/recipe_nutrition.dart';

class Store implements StateStore {
  Map<String, dynamic>? value;
  bool fail = false;
  @override
  String get label => 'memory';
  @override
  Future<Map<String, dynamic>?> load() async => value == null
      ? null
      : jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  @override
  Future<void> save(Map<String, dynamic> data) async {
    if (fail) throw StateError('failed');
    value = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final offManifest = jsonDecode(
    File('data/food/openfoodfacts/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final offCount = offManifest['productCount'] as int;
  FoodRepository foods() => FoodRepository(read: (p) => File(p).readAsString());
  RecipeRepository recipes() =>
      RecipeRepository(read: (p) => File(p).readAsString());
  test(
    'USDA real source records and shards stay selectable, preserve unknowns',
    () async {
      final repo = foods(), index = await repo.usdaIndex();
      expect(index.length, 8156);
      expect(index.map((v) => v['id']).toSet().length, 8156);
      final selected = index.firstWhere(
        (v) => (v['name'] as String).toLowerCase().contains(
          'rice, white, long-grain, regular, raw, unenriched',
        ),
      );
      final food = await repo.usdaFood(selected['id'] as String, form: 'raw');
      expect(food.nutrition.basis.unit, FoodQuantityUnit.g);
      expect(food.nutrition.values[NutrientId.protein]!.value, greaterThan(0));
      expect(food.nutrition.values.containsKey(NutrientId.addedSugars), false);
      expect(foodAllergenStatus(food, 'milk'), AllergenStatus.unknown);
      expect(FoodRecord.fromJson(food.toJson()).key, food.key);
    },
  );
  test(
    'OFF exact markets, unknown basis and explicit sourced label review',
    () async {
      final repo = foods(), rows = await repo.products();
      expect(rows.length, offCount);
      expect(rows.map((v) => v['barcode']).toSet().length, rows.length);
      expect(rows, isNotEmpty);
      final row = rows.firstWhere(
        (v) =>
            (v['brands'] as String).isNotEmpty &&
            ((v['nutrition'] as Map)['asSold'] as Map).containsKey('proteins'),
      );
      final market = (row['markets'] as List).first as String;
      final food = await repo.packagedFood(
        row['barcode'] as String,
        market: market,
      );
      expect(food.nutrition.basis.unit, FoodQuantityUnit.unknown);
      final result = calculateRecipeNutrition(
        recipeId: 'snack',
        recipeVersion: 'v1',
        inputs: [
          RecipeFoodInput(
            ingredientId: 'snack',
            food: food,
            amount: FoodAmount(value: 100, unit: FoodQuantityUnit.g),
            amountForm: FoodForm.asSold,
            preparedForm: FoodForm.asSold,
          ),
        ],
        portions: 1,
      );
      expect(result.whole[NutrientId.protein]!.value, null);
      expect(
        result.whole[NutrientId.protein]!.missing.single.reason,
        NutrientGapReason.unknownBasis,
      );
      final reviewed = await repo.packagedFood(
        row['barcode'] as String,
        market: market,
        reviewedBasis: NutritionBasis(amount: 100, unit: FoodQuantityUnit.g),
        reviewSource: FoodSource(
          id: 'review',
          url: 'https://example.org/label',
          authority: 'User label review',
          license: 'user-provided',
          retrievedAt: DateTime.utc(2026, 10, 12),
        ),
      );
      expect(reviewed.nutrition.basis.unit, FoodQuantityUnit.g);
      final sodium =
          ((row['nutrition'] as Map)['asSold'] as Map)['sodium'] as Map?;
      if (sodium != null &&
          sodium['unit'] == 'g' &&
          sodium['modifier'] == null) {
        expect(
          reviewed.nutrition.values[NutrientId.sodium]!.value,
          closeTo((sodium['value'] as num) * 1000, 1e-8),
        );
      }
    },
  );
  test(
    'all catalog recipes expose coverage gaps or require explicit source yield',
    () async {
      for (final recipe in await recipes().loadAll()) {
        if (!recipe.hasKnownYield) {
          expect(() => recipe.forServings(4), throwsArgumentError);
          continue;
        }
        final result = assessRecipeNutrition(
          scaled: recipe.forServings(recipe.servings!),
          selections: [],
        );
        expect(result.whole[NutrientId.protein]!.value, null);
        expect(result.per100g, null);
        expect(result.snapshot.length, recipe.ingredients.length);
        expect(
          result.snapshot.map((v) => v.ingredientId).toSet().length,
          recipe.ingredients.length,
        );
        expect(
          RecipeNutritionResult.fromJson(result.toJson()).recipeId,
          recipe.id,
        );
      }
    },
  );
  test('cook snapshot and person ledger persist atomically with retry, rollback and no automatic intake', () async {
    final store = Store(), repo = recipes();
    final k = KitchenService(store, repo);
    await k.load();
    await k.saveMember(
      HouseholdMember(
        id: 'solo',
        name: 'solo',
        age: 30,
        gender: MemberGender.male,
      ),
    );
    await k.saveNutritionProfile(NutritionPersonProfile(memberId: 'solo'));
    final r = (await repo.loadAll()).first;
    await k.plan(
      PlannedMeal(
        id: 'p',
        date: '2026-10-12',
        slot: 'lunch',
        recipeId: r.id,
        servings: r.servings!,
      ),
    );
    final stock = <String, (double, String)>{};
    for (final row in r.ingredients.where(
      (v) => !v.optional && v.amount != null,
    )) {
      final prev = stock[row.id];
      stock[row.id] = ((prev?.$1 ?? 0) + row.amount!, row.unit!);
    }
    for (final e in stock.entries) {
      await k.addStock(
        InventoryLot(
          id: e.key,
          ingredientId: e.key,
          quantity: e.value.$1 * 2,
          unit: e.value.$2,
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
    }
    final omit = r.ingredients
        .where((v) => v.amount == null)
        .map((v) => v.id)
        .toSet();
    store.fail = true;
    await expectLater(
      k.confirmCooking('p', 'op', omitUnmeasured: omit, cookedYieldGrams: 1000),
      throwsStateError,
    );
    expect(k.nutritionLedger.batches, isEmpty);
    store.fail = false;
    final receipts = await Future.wait([
      k.confirmCooking('p', 'op', omitUnmeasured: omit, cookedYieldGrams: 1000),
      k.confirmCooking('p', 'op', omitUnmeasured: omit, cookedYieldGrams: 1000),
    ]);
    expect(receipts.first['nutritionBatchId'], 'cooked:op');
    expect(k.nutritionLedger.batches.length, 1);
    expect(k.nutritionLedger.events, isEmpty);
    final batch = k.nutritionLedger.batches.values.single;
    expect(batch.nutrients['protein']!.complete, false);
    final event = NutritionEvent(
      id: 'ate',
      batchId: batch.id,
      kind: NutritionEventKind.consumed,
      personId: 'solo',
      portion: PortionAmount(.25, PortionUnit.batchFraction),
      day: '2026-10-12',
      actorId: 'tester',
      recordedAt: DateTime.utc(2026, 10, 12),
    );
    await k.recordNutritionEvents(events: [event, event]);
    expect(k.nutritionLedger.events.length, 1);
    final reload = KitchenService(store, repo);
    await reload.load();
    expect(reload.nutritionLedger.balance(batch.id).consumed, .25);
    expect(reload.nutritionProfile('solo')!.memberId, 'solo');
    expect(
      (await reload.confirmCooking('p', 'op'))['nutrition'],
      receipts.first['nutrition'],
    );
  });
  test(
    'actual bundled food index is available without bundling source archives',
    () async {
      expect((await FoodRepository().usdaIndex()).length, 8156);
      expect((await FoodRepository().products()).length, offCount);
    },
  );
}
