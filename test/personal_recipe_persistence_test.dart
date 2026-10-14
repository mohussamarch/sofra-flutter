import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/personal_recipe_draft.dart';

import 'food_nutrition_test.dart' as food_fixture;
import 'recipe_variants_test.dart' as fixture;

PersonalRecipeDraft draft({
  String version = 'v1',
  double grams = 100,
  bool unknown = false,
  String? note,
  PreparationTransform? preparation,
}) => PersonalRecipeDraft(
  id: 'my-first-recipe',
  revision: version,
  name: 'وصفتي التجريبية',
  servings: 2,
  createdAt: DateTime.utc(2026, 10, 14),
  note: note,
  lines: [
    PersonalRecipeLine(
      id: 'line-1',
      name: 'مكوّن اختبار',
      input: RecipeFoodInput(
        ingredientId: 'line-1',
        food: unknown ? null : food_fixture.food(),
        amount: unknown
            ? null
            : FoodAmount(value: grams, unit: FoodQuantityUnit.g),
        amountForm: FoodForm.raw,
        preparedForm: FoodForm.cooked,
        preparation: preparation,
      ),
    ),
  ],
);
Future<void> save(
  KitchenService kitchen,
  PersonalRecipeDraft value, {
  String? expected,
  bool ack = true,
}) => kitchen.savePersonalRecipeDraft(
  value,
  acknowledgeInputsReviewed: ack,
  reviewNote: 'مراجعة إدخال اختبار',
  reviewedAt: DateTime.utc(2026, 10, 14),
  expectedActiveKey: expected,
);

void main() {
  test('scratch draft persists without fake parent/times/cuisine and uses existing calculator', () async {
    final store = fixture.Store(),
        kitchen = KitchenService(fixture.Store(), fixture.repository());
    final k = KitchenService(store, fixture.repository());
    await k.load();
    await save(k, draft());
    expect(k.recipeBook.revisions, isEmpty);
    expect(k.recipeBook.families, isEmpty);
    final saved = k.personalRecipeDraft('my-first-recipe')!;
    expect(saved.toJson()['prepMinutes'], isNull);
    expect(saved.toJson()['cookMinutes'], isNull);
    expect(saved.toJson()['cuisine'], isNull);
    expect(saved.toJson().containsKey('parentKey'), false);
    expect(
      k
          .previewPersonalRecipeIngredients(saved.id)
          .whole[NutrientId.protein]!
          .value,
      10,
    );
    expect(
      k.previewPersonalRecipeCooked(saved.id).whole[NutrientId.protein]!.value,
      isNull,
    );
    expect(
      k
          .previewPersonalRecipeIngredients(saved.id, servings: 4)
          .whole[NutrientId.protein]!
          .value,
      20,
    );
    final reload = KitchenService(store, fixture.repository());
    await reload.load();
    expect(reload.personalRecipeDrafts.single.toJson(), saved.toJson());
    expect(k.plans, isEmpty);
    expect(k.inventory, isEmpty);
    expect(k.nutritionLedger.batches, isEmpty);
    expect(k.nutritionLedger.events, isEmpty);
    // Unloaded unrelated service deliberately has no state initialized by drafts.
    expect(() => kitchen.snapshot, throwsStateError);
  });
  test('review acknowledgement and failed save rollback, then retry, no mutable alias', () async {
    final store = fixture.Store(),
        k = KitchenService(fixture.Store(), fixture.repository());
    final service = KitchenService(store, fixture.repository());
    await service.load();
    final before = service.snapshot;
    await expectLater(save(service, draft(), ack: false), throwsArgumentError);
    expect(service.snapshot, before);
    store.fail = true;
    await expectLater(save(service, draft()), throwsStateError);
    expect(service.snapshot, before);
    store.fail = false;
    await save(service, draft());
    final returned = service.personalRecipeDrafts.single.toJson();
    returned['name'] = 'mutated';
    expect(service.personalRecipeDrafts.single.name, 'وصفتي التجريبية');
    expect(() => k.snapshot, throwsStateError);
  });
  test('versions immutable, exact active guard, old retry cannot reactivate old draft', () async {
    final k = KitchenService(fixture.Store(), fixture.repository());
    await k.load();
    final first = draft();
    await save(k, first);
    final before = k.snapshot;
    await expectLater(save(k, draft(grams: 200)), throwsStateError);
    await expectLater(save(k, draft(version: 'v2')), throwsStateError);
    expect(k.snapshot, before);
    await save(k, draft(version: 'v2', grams: 200), expected: first.key);
    final second = k.personalRecipeDraft(first.id)!;
    await save(k, first);
    expect(k.personalRecipeDraft(first.id)!.key, second.key);
    expect(
      k.personalRecipeDraft(first.id, revisionKey: first.key)!.fingerprint,
      first.fingerprint,
    );
    expect(k.personalRecipeDrafts.length, 2);
  });
  test('unknown ingredient amount/food remains incomplete and state size guard is atomic', () async {
    final k = KitchenService(fixture.Store(), fixture.repository());
    await k.load();
    final missing = draft(unknown: true);
    await save(k, missing);
    expect(
      k
          .previewPersonalRecipeIngredients(missing.id)
          .whole[NutrientId.protein]!
          .value,
      isNull,
    );
    expect(
      k.personalRecipeDraft(missing.id)!.lines.single.input.amount,
      isNull,
    );
    final before = k.snapshot;
    await expectLater(
      save(
        k,
        draft(version: 'huge', note: 'x' * 900000),
        expected: missing.key,
      ),
      throwsStateError,
    );
    expect(k.snapshot, before);
  });
  test('parallel draft revisions reject stale activation without losing first commit', () async {
    final k = KitchenService(fixture.Store(), fixture.repository());
    await k.load();
    final first = draft();
    await save(k, first);
    final one = save(k, draft(version: 'v2'), expected: first.key);
    final two = save(k, draft(version: 'v3'), expected: first.key);
    await one;
    await expectLater(two, throwsStateError);
    expect(k.personalRecipeDraft(first.id)!.revision, 'v2');
    expect(k.personalRecipeDrafts.length, 2);
  });
  test('malformed persisted active pointers and review acknowledgements reject load', () async {
    final store = fixture.Store(),
        k = KitchenService(fixture.Store(), fixture.repository());
    final service = KitchenService(store, fixture.repository());
    await service.load();
    await save(service, draft());
    final good = jsonDecode(jsonEncode(store.data!)) as Map<String, dynamic>;
    for (final badAck in [true, false]) {
      store.data = jsonDecode(jsonEncode(good)) as Map<String, dynamic>;
      final b = (store.data!['kitchen'] as Map)['personalRecipeDrafts'] as Map;
      if (badAck) {
        (b['revisions'] as Map).values.single['acknowledgeInputsReviewed'] =
            false;
      } else {
        (b['active'] as Map)['my-first-recipe'] = 'missing';
      }
      await expectLater(
        KitchenService(store, fixture.repository()).load(),
        throwsA(anything),
      );
    }
    expect(() => k.snapshot, throwsStateError);
  });
  test('same draft retry tolerates reordered persisted object keys', () async {
    final store = fixture.Store();
    final k = KitchenService(store, fixture.repository());
    await k.load();
    final first = draft();
    await save(k, first);
    dynamic reorder(dynamic value) {
      if (value is Map) {
        final keys = value.keys.cast<String>().toList()
          ..sort((a, b) => b.compareTo(a));
        return {for (final key in keys) key: reorder(value[key])};
      }
      if (value is List) return value.map(reorder).toList();
      return value;
    }

    store.data = Map<String, dynamic>.from(reorder(store.data) as Map);
    final reload = KitchenService(store, fixture.repository());
    await reload.load();
    final before = reload.snapshot;
    await save(reload, first);
    expect(reload.snapshot, before);
    expect(
      reload.personalRecipeDraft(first.id)!.fingerprint,
      first.fingerprint,
    );
  });
  test('category acceptance scoped to another recipe cannot be copied into a new draft', () async {
    final k = KitchenService(fixture.Store(), fixture.repository());
    await k.load();
    final transform = PreparationTransform(
      id: 'accepted-category-preparation-estimate:other',
      sourceForm: FoodForm.raw,
      targetForm: FoodForm.cooked,
      source: food_fixture.source,
      retention: {NutrientId.protein: .5},
      estimated: true,
      evidence: '{"kind":"accepted-category-preparation-estimate"}',
    );
    final before = k.snapshot;
    await expectLater(save(k, draft(preparation: transform)), throwsStateError);
    expect(k.snapshot, before);
  });
}
