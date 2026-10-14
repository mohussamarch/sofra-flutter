import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/personal_recipe_draft.dart';

// Synthetic data only: 100 g contains 10 g protein.
FoodRecord fixtureFood() => FoodRecord(
  id: 'fixture-food',
  version: 'v1',
  nameAr: 'Test food',
  kind: FoodKind.generic,
  form: FoodForm.raw,
  nutrition: NutrientProfile(
    basis: NutritionBasis(amount: 100, unit: FoodQuantityUnit.g),
    values: {NutrientId.protein: NutrientValue(value: 10)},
  ),
  sources: [
    FoodSource(
      id: 'fixture',
      url: 'https://example.com/test',
      authority: 'Synthetic test data',
      license: 'test-only',
      retrievedAt: DateTime.utc(2026, 10, 14),
    ),
  ],
);

PersonalRecipeLine line(
  String id, {
  FoodRecord? food,
  double? grams = 100,
  bool scales = true,
  bool optional = false,
  bool selected = true,
  bool estimated = false,
  FoodForm amountForm = FoodForm.raw,
  FoodForm preparedForm = FoodForm.raw,
  PreparationTransform? preparation,
}) => PersonalRecipeLine(
  id: id,
  name: 'Ingredient $id',
  scales: scales,
  input: RecipeFoodInput(
    ingredientId: id,
    food: food,
    amount: grams == null
        ? null
        : FoodAmount(value: grams, unit: FoodQuantityUnit.g),
    amountForm: amountForm,
    preparedForm: preparedForm,
    optional: optional,
    selected: selected,
    quantityEstimated: estimated,
    preparation: preparation,
  ),
);

PersonalRecipeDraft draft({
  List<PersonalRecipeLine>? lines,
  String id = 'mine',
  String revision = 'r1',
  double servings = 2,
  int? prepMinutes,
  int? cookMinutes,
  List<String> instructions = const [],
}) => PersonalRecipeDraft(
  id: id,
  revision: revision,
  name: 'My recipe',
  servings: servings,
  createdAt: DateTime.parse('2026-10-14T06:00:00+03:00'),
  lines: lines ?? [line('a', food: fixtureFood())],
  prepMinutes: prepMinutes,
  cookMinutes: cookMinutes,
  instructions: instructions,
);

Map<String, dynamic> clone(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

Object? reversedMaps(Object? value) {
  if (value is Map) {
    return {
      for (final key in value.keys.toList().reversed)
        key: reversedMaps(value[key]),
    };
  }
  if (value is List) return value.map(reversedMaps).toList();
  return value;
}

void main() {
  test('round trip preserves unknown metadata and UTC time without parent', () {
    final value = draft();
    final json = value.toJson();
    expect(json['schemaVersion'], 1);
    expect(json['cuisine'], isNull);
    expect(json['prepMinutes'], isNull);
    expect(json['cookMinutes'], isNull);
    expect(json['createdAt'], '2026-10-14T03:00:00.000Z');
    expect(json.containsKey('parent'), isFalse);
    expect(PersonalRecipeDraft.fromJson(json).toJson(), json);
    expect(draft(prepMinutes: 0, cookMinutes: 5).cookMinutes, 5);
  });

  test(
    'invalid identity servings times and duplicate ingredient IDs reject',
    () {
      for (final make in <void Function()>[
        () => draft(id: ' '),
        () => draft(revision: ''),
        () => draft(servings: 0),
        () => draft(servings: double.nan),
        () => draft(prepMinutes: -1),
        () => draft(cookMinutes: -1),
        () => draft(lines: []),
        () => draft(lines: [line('a'), line('a')]),
        () => PersonalRecipeLine(id: 'x', name: ' ', input: line('x').input),
        () => PersonalRecipeLine(id: 'x', name: 'X', input: line('y').input),
      ]) {
        expect(make, throwsArgumentError);
      }
      expect(draft(id: 'a@b', revision: 'c').key, '["a@b","c"]');
      expect(
        draft(id: 'a', revision: 'b@c').key,
        isNot(draft(id: 'a@b', revision: 'c').key),
      );
    },
  );

  test('owned lines instructions nested input and emitted JSON cannot mutate draft', () {
    final rows = [line('a', food: fixtureFood())];
    final steps = ['Mix'];
    final value = draft(lines: rows, instructions: steps);
    final fingerprint = value.fingerprint;
    rows.clear();
    steps.clear();
    final json = value.toJson();
    (json['lines'] as List).clear();
    expect(value.lines.single.input.food!.id, 'fixture-food');
    expect(value.instructions, ['Mix']);
    expect(() => value.lines.clear(), throwsUnsupportedError);
    expect(() => value.instructions.clear(), throwsUnsupportedError);
    expect(value.fingerprint, fingerprint);
    final imported = PersonalRecipeDraft.fromJson(value.toJson());
    expect(imported.fingerprint, fingerprint);
    final reordered = PersonalRecipeDraft.fromJson(
      Map<String, dynamic>.from(reversedMaps(value.toJson()) as Map),
    );
    expect(reordered.fingerprint, fingerprint);
    expect(
      draft(lines: [line('a', food: fixtureFood(), grams: 200)]).fingerprint,
      isNot(fingerprint),
    );
  });

  test('strict JSON rejects schema fields malformed nested inputs and absent booleans', () {
    final baseline = draft().toJson();
    final mutations = <void Function(Map<String, dynamic>)>[
      (j) => j['schemaVersion'] = 2,
      (j) => j['parent'] = 'fake',
      (j) => j.remove('cuisine'),
      (j) => j['prepMinutes'] = 1.5,
      (j) => j['createdAt'] = '2026-10-14',
      (j) => ((j['lines'] as List).single as Map).remove('scales'),
      (j) => (((j['lines'] as List).single as Map)['input'] as Map).remove(
        'selected',
      ),
      (j) =>
          (((j['lines'] as List).single as Map)['input']
                  as Map)['quantityEstimated'] =
              'false',
      (j) =>
          ((((j['lines'] as List).single as Map)['input'] as Map)['food']
                  as Map)
              .remove('compoundIngredientsComplete'),
    ];
    for (final mutate in mutations) {
      final json = clone(baseline);
      mutate(json);
      expect(() => PersonalRecipeDraft.fromJson(json), throwsFormatException);
    }
  });

  test(
    'serving scaling respects fixed lines and estimated excluded ingredients',
    () {
      final result = draft(
        lines: [
          line('a', food: fixtureFood(), estimated: true),
          line('fixed', food: fixtureFood(), grams: 50, scales: false),
          line('excluded', food: null, optional: true, selected: false),
        ],
      ).previewIngredients(servings: 4);
      expect(result.whole[NutrientId.protein]!.value, 25);
      expect(result.perPortion[NutrientId.protein]!.value, 6.25);
      expect(result.whole[NutrientId.protein]!.estimated, isTrue);
      expect(result.snapshot.last.selected, isFalse);
      expect(result.snapshot.first.quantityEstimated, isTrue);
      expect(
        () => draft().previewCooked(servings: double.infinity),
        throwsArgumentError,
      );
    },
  );

  test('unknown food and unmeasured quantity remain visible gaps', () {
    final result = draft(
      lines: [
        line('unmapped'),
        line('unmeasured', food: fixtureFood(), grams: null),
      ],
    ).previewIngredients();
    final protein = result.whole[NutrientId.protein]!;
    expect(protein.value, isNull);
    expect(protein.missing.map((g) => g.reason), [
      NutrientGapReason.unmappedFood,
      NutrientGapReason.unmeasuredAmount,
    ]);
    expect(result.snapshot.last.amount, isNull);
    expect(result.per100g, isNull);
  });

  test('ingredient preview removes preparation while preserving cooked amount form', () {
    final value = draft(
      lines: [
        line(
          'a',
          food: fixtureFood(),
          amountForm: FoodForm.cooked,
          preparedForm: FoodForm.cooked,
        ),
      ],
    );
    final result = value.previewIngredients();
    expect(result.snapshot.single.amountForm, FoodForm.cooked);
    expect(result.snapshot.single.preparedForm, FoodForm.raw);
    expect(result.snapshot.single.preparation, isNull);
    expect(result.whole[NutrientId.protein]!.value, isNull);
    expect(
      result.whole[NutrientId.protein]!.missing.single.reason,
      NutrientGapReason.formMismatch,
    );
  });

  test(
    'cooked preview retains explicit retention unknown factors and yield',
    () {
      final food = fixtureFood();
      final transform = PreparationTransform(
        id: 'manual-test',
        sourceForm: FoodForm.raw,
        targetForm: FoodForm.cooked,
        source: food.sources.single,
        massYield: 0.5,
        retention: {NutrientId.protein: 0.8},
        estimated: true,
      );
      final value = draft(
        lines: [
          line(
            'a',
            food: food,
            grams: 50,
            amountForm: FoodForm.cooked,
            preparedForm: FoodForm.cooked,
            preparation: transform,
          ),
        ],
      );
      final cooked = value.previewCooked(cookedYieldGrams: 50);
      expect(cooked.whole[NutrientId.protein]!.value, 8);
      expect(cooked.per100g![NutrientId.protein]!.value, 16);
      expect(cooked.whole[NutrientId.protein]!.estimated, isTrue);
      expect(cooked.whole[NutrientId.fibre]!.value, isNull);
      expect(cooked.snapshot.single.preparation!.id, 'manual-test');
      expect(value.previewIngredients().snapshot.single.preparation, isNull);
      final noPreparation = draft(
        lines: [line('a', food: food, preparedForm: FoodForm.cooked)],
      ).previewCooked();
      expect(
        noPreparation.whole[NutrientId.protein]!.missing.single.reason,
        NutrientGapReason.missingPreparation,
      );
      expect(
        () => value.previewCooked(cookedYieldGrams: 0),
        throwsArgumentError,
      );
    },
  );
}
