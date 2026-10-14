import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/personal_recipe_draft.dart';
import 'package:tabkha_demo/domain/personal_recipe_finalization.dart';

final source = FoodSource(
  id: 'test',
  url: 'https://example.com/test',
  authority: 'Synthetic fixture only',
  license: 'test-only',
  retrievedAt: DateTime.utc(2026),
);
FoodRecord food() => FoodRecord(
  id: 'fixture-food',
  version: '1',
  nameAr: 'Fixture',
  kind: FoodKind.generic,
  form: FoodForm.raw,
  sources: [source],
  nutrition: NutrientProfile(
    basis: NutritionBasis(amount: 100, unit: FoodQuantityUnit.g),
    values: {NutrientId.protein: NutrientValue(value: 10)},
  ),
);
PersonalRecipeLine line(
  String id, {
  bool mapped = true,
  bool scales = true,
  double? amount = 100,
  bool estimated = false,
  bool optional = false,
  bool selected = true,
  PreparationTransform? preparation,
  String? name,
}) => PersonalRecipeLine(
  id: id,
  name: name ?? id,
  scales: scales,
  input: RecipeFoodInput(
    ingredientId: id,
    food: mapped ? food() : null,
    amount: amount == null
        ? null
        : FoodAmount(value: amount, unit: FoodQuantityUnit.g),
    amountForm: FoodForm.raw,
    preparedForm: FoodForm.cooked,
    quantityEstimated: estimated,
    optional: optional,
    selected: selected,
    asPurchased: true,
    preparation: preparation,
  ),
);
PersonalRecipeDraft draft({
  double servings = 2,
  String? cuisine = 'Home',
  int? prep = 0,
  int? cook = 5,
  List<String> steps = const ['Mix', 'Cook'],
  List<PersonalRecipeLine>? lines,
  String name = 'My recipe',
}) => PersonalRecipeDraft(
  id: 'mine',
  revision: 'r1',
  name: name,
  servings: servings,
  cuisine: cuisine,
  prepMinutes: prep,
  cookMinutes: cook,
  instructions: steps,
  createdAt: DateTime.utc(2026, 10, 14),
  lines:
      lines ??
      [line('a'), line('b', mapped: false, scales: false, amount: null)],
  note: 'User note',
);
PersonalRecipeFinalization finalize({
  PersonalRecipeDraft? value,
  List<double> minutes = const [0, 5],
  Map<String, String> ids = const {'a': 'stock-a', 'b': 'stock-b'},
  String category = 'Main',
  String description = 'User description',
  String difficulty = 'Easy',
  String reviewNote = 'Reviewed exact inputs',
  bool ackInputs = true,
  bool ackNutrition = true,
}) => PersonalRecipeFinalization(
  draft: value ?? draft(),
  category: category,
  description: description,
  difficulty: difficulty,
  stepMinutes: minutes,
  ingredientIds: ids,
  reviewNote: reviewNote,
  reviewedAt: DateTime.parse('2026-10-14T06:00:00+03:00'),
  acknowledgeInstructionsAndInputs: ackInputs,
  acknowledgeNutritionIncomplete: ackNutrition,
);
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

Map<String, dynamic> clone(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

void main() {
  test(
    'explicit metadata builds independent recipe and unknown fixed ingredient',
    () {
      final result = finalize();
      expect(result.recipeId, 'personal:["mine"]');
      expect(result.familyId, 'personal-dish:["mine"]');
      expect(result.revisionId, 'personal-sha256:${result.fingerprint}');
      expect(result.recipe.id, result.recipeId);
      expect(result.recipe.servings, 2);
      expect(result.recipe.prepMinutes, 0);
      expect(result.recipe.cookMinutes, 5);
      expect(result.recipe.steps.map((s) => s.minutes), [0, 5]);
      expect(result.recipe.ingredients.first.id, 'stock-a');
      expect(result.recipe.ingredients.first.unit, 'g');
      expect(result.recipe.ingredients.first.amount, 100);
      expect(result.recipe.ingredients.last.amount, isNull);
      expect(result.recipe.ingredients.last.scales, isFalse);
      expect(result.recipe.notes, 'User note');
      expect(result.toJson().containsKey('parent'), isFalse);
    },
  );

  test('missing runtime metadata fractional servings and padded catalog text reject', () {
    for (final make in <void Function()>[
      () => finalize(value: draft(cuisine: null)),
      () => finalize(value: draft(prep: null)),
      () => finalize(value: draft(cook: null)),
      () => finalize(
        value: draft(steps: []),
        minutes: [],
      ),
      () => finalize(value: draft(servings: 1.5)),
      () => finalize(value: draft(name: ' Padded')),
      () => finalize(value: draft(steps: [' Mix', 'Cook'])),
      () => finalize(
        value: draft(lines: [line('a', name: ' a')]),
        ids: {'a': 'stock-a'},
      ),
      () => finalize(category: ' '),
      () => finalize(description: ''),
      () => finalize(difficulty: ' Easy'),
    ]) {
      expect(make, throwsArgumentError);
    }
  });

  test('inventory mapping exactness estimated amounts and borrowed preparation reject', () {
    final category = PreparationTransform(
      id: 'accepted-category-preparation-estimate:other',
      sourceForm: FoodForm.raw,
      targetForm: FoodForm.cooked,
      source: source,
      retention: {},
    );
    final disguised = PreparationTransform(
      id: 'manual',
      sourceForm: FoodForm.raw,
      targetForm: FoodForm.cooked,
      source: source,
      retention: {},
      evidence: '{"kind":"accepted-category-preparation-estimate"}',
    );
    for (final make in <void Function()>[
      () => finalize(ids: {'a': 'stock-a'}),
      () => finalize(ids: {'a': 'stock-a', 'b': 'stock-b', 'extra': 'stock-x'}),
      () => finalize(ids: {'a': ' stock-a', 'b': 'stock-b'}),
      () => finalize(
        value: draft(lines: [line('a', amount: null)]),
        ids: {'a': 'stock-a'},
      ),
      () => finalize(
        value: draft(lines: [line('a', estimated: true)]),
        ids: {'a': 'stock-a'},
      ),
      () => finalize(
        value: draft(lines: [line('a', amount: 0.001)]),
        ids: {'a': 'stock-a'},
      ),
      () => finalize(
        value: draft(lines: [line('a', preparation: category)]),
        ids: {'a': 'stock-a'},
      ),
      () => finalize(
        value: draft(lines: [line('a', preparation: disguised)]),
        ids: {'a': 'stock-a'},
      ),
    ]) {
      expect(make, throwsArgumentError);
    }
    final fixed = finalize(
      value: draft(lines: [line('a', amount: 0.001, scales: false)]),
      ids: {'a': 'stock-a'},
    );
    expect(fixed.recipe.ingredients.single.quantityFor(1), 0.001);
  });

  test('review acknowledgements and exact finite nonnegative step durations required', () {
    for (final make in <void Function()>[
      () => finalize(ackInputs: false),
      () => finalize(ackNutrition: false),
      () => finalize(reviewNote: ' '),
      () => finalize(minutes: [5]),
      () => finalize(minutes: [0, -1]),
      () => finalize(minutes: [0, double.infinity]),
    ]) {
      expect(make, throwsArgumentError);
    }
    expect(finalize().reviewedAt.toIso8601String(), '2026-10-14T03:00:00.000Z');
  });

  test(
    'owned snapshot survives map reorder and rejects mutated derived envelope',
    () {
      final minutes = [0.0, 5.0], ids = {'a': 'stock-a', 'b': 'stock-b'};
      final result = finalize(minutes: minutes, ids: ids);
      final pin = result.fingerprint;
      minutes.clear();
      ids.clear();
      final json = result.toJson();
      final restored = PersonalRecipeFinalization.fromJson(
        Map<String, dynamic>.from(reversedMaps(json) as Map),
      );
      expect(restored.fingerprint, pin);
      expect(jsonEncode(restored.toJson()), jsonEncode(result.toJson()));
      expect(restored.recipe.toJson(), result.recipe.toJson());
      expect(() => result.stepMinutes.clear(), throwsUnsupportedError);
      expect(() => result.ingredientIds.clear(), throwsUnsupportedError);
      (json['draft'] as Map)['name'] = 'Changed';
      expect(result.draft.name, 'My recipe');
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (j) => j['fingerprint'] = '0' * 64,
        (j) => j['recipeId'] = 'wrong',
        (j) => j['familyId'] = 'wrong',
        (j) => j['revisionId'] = 'wrong',
        (j) => (j['recipe'] as Map)['servings'] = 3,
        (j) => j.remove('acknowledgeNutritionIncomplete'),
        (j) => j['extra'] = true,
        (j) => j['reviewedAt'] = '2026-10-14',
      ]) {
        final copy = clone(result.toJson());
        mutate(copy);
        expect(
          () => PersonalRecipeFinalization.fromJson(copy),
          throwsFormatException,
        );
      }
      expect(finalize(reviewNote: 'Different review').fingerprint, isNot(pin));
    },
  );

  test('food selections preserve line scope forms and transforms without forced exclusions', () {
    final transform = PreparationTransform(
      id: 'manual-test',
      sourceForm: FoodForm.raw,
      targetForm: FoodForm.cooked,
      source: source,
      massYield: 0.5,
      retention: {NutrientId.protein: 0.8},
      estimated: true,
    );
    final result = finalize(
      value: draft(
        lines: [
          line('a', mapped: false, scales: false, amount: null),
          line('b', optional: true, selected: false, preparation: transform),
        ],
      ),
    );
    final selection = result.selectionsFor('exact-revision-key').single;
    expect(selection.line, 1);
    expect(selection.recipeId, 'personal:["mine"]');
    expect(selection.recipeRevisionKey, 'exact-revision-key');
    expect(selection.amountForm, FoodForm.raw);
    expect(selection.preparedForm, FoodForm.cooked);
    expect(selection.asPurchased, isTrue);
    expect(selection.preparation!.estimated, isTrue);
    expect(selection.measuredAmount, isNull);
    expect(selection.notConsumed, isFalse);
    expect(result.draft.lines.last.input.selected, isFalse);
    expect(result.recipe.ingredients.last.optional, isTrue);
    expect(() => result.selectionsFor(' '), throwsArgumentError);
  });
}
