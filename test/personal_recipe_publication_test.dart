import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/personal_recipe_draft.dart';
import 'package:tabkha_demo/domain/personal_recipe_finalization.dart';
import 'package:tabkha_demo/domain/recipe_variants.dart';

import 'food_nutrition_test.dart' as food_fixture;
import 'recipe_variants_test.dart' as fixture;

PersonalRecipeDraft draft({
  String version = 'v1',
  double grams = 100,
  bool unknown = false,
  String? note,
}) => PersonalRecipeDraft(
  id: 'my-dish',
  revision: version,
  name: 'وصفة اختبار',
  servings: 2,
  createdAt: DateTime.utc(2026, 10, 14),
  cuisine: 'اختبار',
  prepMinutes: 1,
  cookMinutes: 0,
  instructions: ['خلط عينة اختبار'],
  note: note,
  lines: [
    PersonalRecipeLine(
      id: 'line',
      name: 'عينة',
      scales: !unknown,
      input: RecipeFoodInput(
        ingredientId: 'line',
        food: unknown ? null : food_fixture.food(),
        amount: unknown
            ? null
            : FoodAmount(value: grams, unit: FoodQuantityUnit.g),
        amountForm: FoodForm.raw,
        preparedForm: FoodForm.raw,
      ),
    ),
  ],
);
PersonalRecipeFinalization review(PersonalRecipeDraft d) =>
    PersonalRecipeFinalization(
      draft: d,
      category: 'اختبار',
      description: 'مراجعة اختبار',
      difficulty: 'اختبار',
      stepMinutes: [1],
      ingredientIds: {'line': 'sample'},
      reviewNote: 'تأكيد اختبار',
      reviewedAt: DateTime.utc(2026, 10, 14),
      acknowledgeInstructionsAndInputs: true,
      acknowledgeNutritionIncomplete: true,
    );
Future<void> save(
  KitchenService k,
  PersonalRecipeDraft d, {
  String? expected,
}) => k.savePersonalRecipeDraft(
  d,
  acknowledgeInputsReviewed: true,
  reviewNote: 'اختبار',
  reviewedAt: DateTime.utc(2026, 10, 14),
  expectedActiveKey: expected,
);
void main() {
  test(
    'published scratch root binds exact foods, plans, cooks and reloads once',
    () async {
      final store = fixture.Store(),
          k = KitchenService(fixture.Store(), fixture.repository());
      final service = KitchenService(store, fixture.repository());
      await service.load();
      final d = draft();
      await save(service, d);
      final r = await service.finalizePersonalRecipe(review(d));
      expect(r.kind, RecipeRevisionKind.authored);
      expect(r.parentKey, isNull);
      expect(r.authoredReview!.draft.fingerprint, d.fingerprint);
      await service.plan(fixture.plan('meal', r.variantId));
      expect(
        (await service.previewIngredientNutrition('meal'))
            .whole[NutrientId.protein]!
            .value,
        10,
      );
      await service.addStock(
        InventoryLot(
          id: 'lot',
          ingredientId: 'sample',
          quantity: 1000,
          unit: 'g',
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
      final h = await service.confirmCooking('meal', 'operation');
      expect(service.inventory.single.quantity, 900);
      expect(
        service
            .nutritionLedger
            .batches
            .values
            .single
            .nutrients['protein']!
            .value,
        10,
      );
      expect(service.nutritionLedger.events, isEmpty);
      expect(await service.confirmCooking('meal', 'operation'), h);
      final reload = KitchenService(store, fixture.repository());
      await reload.load();
      expect(
        reload.recipeBook.revisions[r.key]!.authoredReview!.toJson(),
        r.authoredReview!.toJson(),
      );
      dynamic reordered(dynamic v) {
        if (v is Map) {
          final keys = v.keys.cast<String>().toList()
            ..sort((a, b) => b.compareTo(a));
          return {for (final key in keys) key: reordered(v[key])};
        }
        if (v is List) return v.map(reordered).toList();
        return v;
      }

      store.data = Map<String, dynamic>.from(reordered(store.data) as Map);
      final reorderedReload = KitchenService(store, fixture.repository());
      await reorderedReload.load();
      final beforeRetry = reorderedReload.snapshot;
      await reorderedReload.finalizePersonalRecipe(review(d));
      expect(reorderedReload.snapshot, beforeRetry);
      expect(() => k.snapshot, throwsStateError);
    },
  );
  test('failure rollback, exact retries and newer publication keep old history and bindings', () async {
    final store = fixture.Store(),
        k = KitchenService(store, fixture.repository());
    await k.load();
    final one = draft();
    await save(k, one);
    final before = k.snapshot;
    store.fail = true;
    await expectLater(k.finalizePersonalRecipe(review(one)), throwsStateError);
    expect(k.snapshot, before);
    store.fail = false;
    final old = await k.finalizePersonalRecipe(review(one));
    await k.plan(fixture.plan('old', old.variantId));
    final two = draft(version: 'v2', grams: 200);
    await save(k, two, expected: one.key);
    await expectLater(k.finalizePersonalRecipe(review(two)), throwsStateError);
    final newer = await k.finalizePersonalRecipe(
      review(two),
      expectedActiveRecipeKey: old.key,
    );
    final frozen = k.snapshot;
    await k.finalizePersonalRecipe(review(one));
    expect(k.snapshot, frozen);
    expect(k.recipeBook.active[old.variantId], newer.key);
    expect((await k.recipeForMeal('old')).key, old.key);
    expect(
      (await k.previewIngredientNutrition('old'))
          .whole[NutrientId.protein]!
          .value,
      10,
    );
    await k.plan(fixture.plan('new', newer.variantId));
    expect(
      (await k.previewIngredientNutrition('new'))
          .whole[NutrientId.protein]!
          .value,
      20,
    );
  });
  test(
    'only exact saved active draft can publish, without partial writes',
    () async {
      final k = KitchenService(fixture.Store(), fixture.repository());
      await k.load();
      await expectLater(
        k.finalizePersonalRecipe(review(draft())),
        throwsStateError,
      );
      final one = draft();
      await save(k, one);
      await save(k, draft(version: 'v2'), expected: one.key);
      final before = k.snapshot;
      await expectLater(
        k.finalizePersonalRecipe(review(one)),
        throwsStateError,
      );
      expect(k.snapshot, before);
      await expectLater(
        k.finalizePersonalRecipe(review(draft(version: 'v2', grams: 300))),
        throwsStateError,
      );
      expect(k.snapshot, before);
    },
  );
  test(
    'unknown food/amount stays unknown and cooking requires actual use',
    () async {
      final k = KitchenService(fixture.Store(), fixture.repository());
      await k.load();
      final d = draft(unknown: true);
      await save(k, d);
      final r = await k.finalizePersonalRecipe(review(d));
      await k.plan(fixture.plan('meal', r.variantId));
      expect(
        (await k.previewIngredientNutrition('meal'))
            .whole[NutrientId.protein]!
            .value,
        isNull,
      );
      await expectLater(k.confirmCooking('meal', 'op'), throwsStateError);
      await k.addStock(
        InventoryLot(
          id: 'lot',
          ingredientId: 'sample',
          quantity: 1000,
          unit: 'g',
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
      await k.confirmCooking(
        'meal',
        'op',
        actualUsesByLine: {0: IngredientUse('sample', 100, 'g')},
      );
      expect(
        k.nutritionLedger.batches.values.single.nutrients['protein']!.value,
        isNull,
      );
      expect(k.inventory.single.quantity, 900);
    },
  );
  test('authored root evidence cannot be dropped or changed, generic bypass blocked', () async {
    final k = KitchenService(fixture.Store(), fixture.repository());
    await k.load();
    final d = draft();
    await save(k, d);
    final r = await k.finalizePersonalRecipe(review(d));
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (j) => j['authoredReview'] = null,
      (j) => j['parentKey'] = 'fake-parent',
      (j) => j['familyId'] = 'other',
      (j) => j['revision'] = 'other',
      (j) => (j['recipe'] as Map)['name'] = 'changed',
    ]) {
      final j = r.toJson();
      mutate(j);
      expect(() => RecipeRevision.fromJson(j), throwsA(anything));
    }
    await expectLater(k.saveRecipeRevision(r), throwsStateError);
  });
  test('850KB publication guard preserves saved draft without partial book or bindings', () async {
    final k = KitchenService(fixture.Store(), fixture.repository());
    await k.load();
    final d = draft(note: 'x' * 600000);
    await save(k, d);
    final before = k.snapshot;
    await expectLater(k.finalizePersonalRecipe(review(d)), throwsStateError);
    expect(k.snapshot, before);
    expect(k.recipeBook.revisions, isEmpty);
  });
}
