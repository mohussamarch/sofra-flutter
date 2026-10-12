import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';

final source = FoodSource(
  id: 'fixture',
  url: 'https://example.com/facts',
  authority: 'Synthetic unit-test data, not food facts',
  license: 'test-only',
  retrievedAt: DateTime.utc(2026, 10, 12),
);

FoodRecord food({
  String id = 'fixture-food',
  FoodQuantityUnit unit = FoodQuantityUnit.g,
  Map<NutrientId, NutrientValue>? values,
  FoodConversion? conversion,
  List<AllergenDeclaration> allergens = const [],
  List<FoodComponent> components = const [],
  bool completeComponents = false,
}) => FoodRecord(
  id: id,
  version: 'v1',
  nameAr: 'عينة اختبار',
  kind: FoodKind.generic,
  form: FoodForm.raw,
  nutrition: NutrientProfile(
    basis: NutritionBasis(amount: 100, unit: unit),
    values:
        values ??
        {
          NutrientId.protein: NutrientValue(value: 10),
          NutrientId.energyKcal: NutrientValue(value: 200),
        },
  ),
  sources: [source],
  conversion: conversion,
  allergens: allergens,
  components: components,
  compoundIngredientsComplete: completeComponents,
);

RecipeFoodInput input(
  String id,
  FoodRecord? record, {
  double? amount = 200,
  FoodQuantityUnit unit = FoodQuantityUnit.g,
  bool optional = false,
  bool selected = true,
  bool asPurchased = false,
  FoodForm amountForm = FoodForm.raw,
  FoodForm preparedForm = FoodForm.raw,
  PreparationTransform? preparation,
}) => RecipeFoodInput(
  ingredientId: id,
  food: record,
  amount: amount == null ? null : FoodAmount(value: amount, unit: unit),
  amountForm: amountForm,
  preparedForm: preparedForm,
  optional: optional,
  selected: selected,
  asPurchased: asPurchased,
  preparation: preparation,
);

RecipeNutritionResult calculate(
  List<RecipeFoodInput> inputs, {
  double? yield,
  double portions = 4,
}) => calculateRecipeNutrition(
  recipeId: 'fixture-recipe',
  recipeVersion: 'v1',
  inputs: inputs,
  portions: portions,
  cookedYieldGrams: yield,
);

void main() {
  test('whole and portion totals preserve missing nutrients; per100g needs final yield', () {
    final result = calculate([input('a', food())]);
    expect(result.whole[NutrientId.protein]!.value, 20);
    expect(result.perPortion[NutrientId.protein]!.value, 5);
    expect(result.whole[NutrientId.fibre]!.value, isNull);
    expect(result.whole[NutrientId.fibre]!.knownSubtotal, 0);
    expect(
      result.whole[NutrientId.fibre]!.missing.single.reason,
      NutrientGapReason.missingNutrient,
    );
    expect(result.per100g, isNull);
    expect(
      calculate([
        input('a', food()),
      ], yield: 400).per100g![NutrientId.protein]!.value,
      5,
    );
  });

  test('partial subtotal is not presented as total or invented coverage percentage', () {
    final result = calculate([input('a', food()), input('b', null)]);
    expect(result.whole[NutrientId.protein]!.knownSubtotal, 20);
    expect(result.whole[NutrientId.protein]!.value, isNull);
    expect(result.perPortion[NutrientId.protein]!.value, isNull);
    expect(result.whole[NutrientId.protein]!.missing.single.ingredientId, 'b');
  });

  test('optional excluded ingredients add neither nutrients nor gaps; required cannot be excluded', () {
    final result = calculate([
      input('a', food()),
      input('b', null, optional: true, selected: false),
    ]);
    expect(result.whole[NutrientId.protein]!.value, 20);
    expect(
      calculate([input('a', food()), input('b', null, optional: true)])
          .whole[NutrientId.protein]!
          .value,
      isNull,
    );
    expect(() => input('a', food(), selected: false), throwsArgumentError);
    expect(
      () => calculate([input('a', null, optional: true, selected: false)]),
      throwsArgumentError,
    );
  });

  test('volume calculations work directly; mass-volume and pieces require explicit food conversions', () {
    final liquid = food(unit: FoodQuantityUnit.ml);
    expect(
      calculate([input('a', liquid, amount: 0.25, unit: FoodQuantityUnit.l)])
          .whole[NutrientId.protein]!
          .value,
      25,
    );
    expect(
      calculate([input('a', liquid, amount: 200)])
          .whole[NutrientId.protein]!
          .value,
      isNull,
    );
    final converted = food(
      unit: FoodQuantityUnit.ml,
      conversion: FoodConversion(
        gramsPerMl: 1.05,
        gramsPerCount: 105,
        sourceId: 'fixture',
      ),
    );
    expect(
      calculate([input('a', converted, amount: 210)])
          .whole[NutrientId.protein]!
          .value,
      closeTo(20, 1e-10),
    );
    expect(
      calculate([
        input('a', converted, amount: 2, unit: FoodQuantityUnit.count),
      ]).whole[NutrientId.protein]!.value,
      closeTo(20, 1e-10),
    );
    expect(
      calculate([input('a', food(), amount: 2, unit: FoodQuantityUnit.count)])
          .whole[NutrientId.protein]!
          .value,
      isNull,
    );
  });

  test(
    'serving basis and explicit portion mass are distinct from recipe portions',
    () {
      final record = food(
        unit: FoodQuantityUnit.serving,
        conversion: FoodConversion(gramsPerServing: 40, sourceId: 'fixture'),
      );
      // This fixture basis is 100 servings, deliberately not 100g.
      expect(
        calculate([
          input('a', record, amount: 2, unit: FoodQuantityUnit.serving),
        ]).whole[NutrientId.protein]!.value,
        0.2,
      );
      expect(
        calculate([input('a', record, amount: 80)])
            .whole[NutrientId.protein]!
            .value,
        0.2,
      );
    },
  );

  test('unknown basis, unmeasured quantity and bounds stay unknown, including a label less-than', () {
    expect(
      calculate([input('a', food(unit: FoodQuantityUnit.unknown))])
          .whole[NutrientId.protein]!
          .missing
          .single
          .reason,
      NutrientGapReason.unknownBasis,
    );
    expect(
      calculate([input('a', food(), amount: null)])
          .whole[NutrientId.protein]!
          .missing
          .single
          .reason,
      NutrientGapReason.unmeasuredAmount,
    );
    final bounded = food(
      values: {
        NutrientId.protein: NutrientValue(
          value: 0.5,
          qualifier: NutrientQualifier.lessThan,
        ),
      },
    );
    expect(
      calculate([input('a', bounded)]).whole[NutrientId.protein]!.value,
      isNull,
    );
    final zero = food(values: {NutrientId.protein: NutrientValue(value: 0)});
    expect(calculate([input('a', zero)]).whole[NutrientId.protein]!.value, 0);
  });

  test('preparation mass yield never multiplies nutrients; nutrient retention is explicit', () {
    final transform = PreparationTransform(
      id: 'fixture-baked',
      sourceForm: FoodForm.raw,
      targetForm: FoodForm.cooked,
      source: source,
      massYield: 0.5,
      retention: {NutrientId.protein: 0.8},
    );
    final result = calculate([
      input('a', food(), preparation: transform, preparedForm: FoodForm.cooked),
    ], yield: 100);
    expect(result.whole[NutrientId.protein]!.value, 16);
    expect(result.per100g![NutrientId.protein]!.value, 16);
    expect(result.whole[NutrientId.energyKcal]!.value, isNull);
    expect(
      result.whole[NutrientId.energyKcal]!.missing.single.reason,
      NutrientGapReason.missingRetention,
    );
    final fromCooked = calculate([
      input(
        'a',
        food(),
        amount: 100,
        amountForm: FoodForm.cooked,
        preparedForm: FoodForm.cooked,
        preparation: transform,
      ),
    ]);
    expect(fromCooked.whole[NutrientId.protein]!.value, 16);
  });

  test('cooked/raw mismatches never silently reuse facts or source-form piece masses', () {
    expect(
      calculate([input('a', food(), preparedForm: FoodForm.cooked)])
          .whole[NutrientId.protein]!
          .value,
      isNull,
    );
    final transform = PreparationTransform(
      id: 'fixture-cooked',
      sourceForm: FoodForm.raw,
      targetForm: FoodForm.cooked,
      source: source,
      retention: {NutrientId.protein: 1},
    );
    expect(
      calculate([
        input(
          'a',
          food(),
          amountForm: FoodForm.cooked,
          preparedForm: FoodForm.cooked,
          preparation: transform,
        ),
      ]).whole[NutrientId.protein]!.missing.single.reason,
      NutrientGapReason.missingMassYield,
    );
    final wrong = PreparationTransform(
      id: 'wrong',
      sourceForm: FoodForm.asSold,
      targetForm: FoodForm.cooked,
      source: source,
      retention: {NutrientId.protein: 1},
    );
    expect(
      calculate([
        input('a', food(), preparedForm: FoodForm.cooked, preparation: wrong),
      ]).whole[NutrientId.protein]!.missing.single.reason,
      NutrientGapReason.formMismatch,
    );
  });

  test('as-purchased quantity requires explicit edible fraction', () {
    expect(
      calculate([input('a', food(), asPurchased: true)])
          .whole[NutrientId.protein]!
          .value,
      isNull,
    );
    final record = food(
      conversion: FoodConversion(edibleFraction: 0.6, sourceId: 'fixture'),
    );
    expect(
      calculate([input('a', record, asPurchased: true)])
          .whole[NutrientId.protein]!
          .value,
      12,
    );
    expect(
      calculate([input('a', record)]).whole[NutrientId.protein]!.value,
      20,
    );
  });

  test(
    'source-version snapshots roundtrip and resist external map/list mutation',
    () {
      final values = {
        NutrientId.protein: NutrientValue(
          value: 10,
          method: NutrientMethod.estimated,
        ),
      };
      final record = food(values: values);
      final inputs = [input('a', record)];
      final result = calculate(inputs, yield: 300);
      values.clear();
      inputs.clear();
      expect(result.whole[NutrientId.protein]!.value, 20);
      expect(result.whole[NutrientId.protein]!.estimated, true);
      expect(result.snapshot.single.food!.version, 'v1');
      final json =
          jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>;
      final restored = RecipeNutritionResult.fromJson(json);
      expect(restored.toJson(), result.toJson());
      expect(() => restored.whole.clear(), throwsUnsupportedError);
      expect(() => record.nutrition.values.clear(), throwsUnsupportedError);
      final malformed = record.toJson();
      final profile = malformed['nutrition'] as Map<String, dynamic>;
      (profile['values'] as List).add((profile['values'] as List).first);
      expect(() => FoodRecord.fromJson(malformed), throwsFormatException);
    },
  );

  test('allergen absent is unknown and free-from requires evidence; compound risk propagates', () {
    expect(foodAllergenStatus(food(), 'milk'), AllergenStatus.unknown);
    expect(
      () => AllergenDeclaration(
        allergenId: 'milk',
        status: AllergenStatus.freeFrom,
      ),
      throwsArgumentError,
    );
    final milk = food(
      id: 'milk',
      allergens: [
        AllergenDeclaration(
          allergenId: 'milk',
          status: AllergenStatus.contains,
          evidence: 'Synthetic declaration',
          sourceId: 'fixture',
        ),
      ],
    );
    final compound = food(
      components: [FoodComponent(foodId: 'milk', foodVersion: 'v1')],
    );
    expect(foodAllergenStatus(compound, 'milk'), AllergenStatus.unknown);
    expect(
      foodAllergenStatus(compound, 'milk', catalog: {milk.key: milk}),
      AllergenStatus.contains,
    );
    final free = food(
      id: 'free',
      allergens: [
        AllergenDeclaration(
          allergenId: 'milk',
          status: AllergenStatus.freeFrom,
          evidence: 'Synthetic label',
          sourceId: 'fixture',
        ),
      ],
    );
    expect(
      recipeAllergenStatus([input('a', free), input('b', null)], 'milk'),
      AllergenStatus.unknown,
    );
    expect(
      recipeAllergenStatus([
        input('a', free),
        input('b', milk, optional: true, selected: false),
      ], 'milk'),
      AllergenStatus.freeFrom,
    );
    final childFree = food(
      components: [FoodComponent(foodId: 'free', foodVersion: 'v1')],
      completeComponents: true,
    );
    expect(
      foodAllergenStatus(childFree, 'milk', catalog: {free.key: free}),
      AllergenStatus.unknown,
    );
  });

  test('input validation rejects negative/NaN, duplicate ids, mismatched nutrient units and bad GTIN', () {
    expect(() => NutrientValue(value: double.nan), throwsArgumentError);
    expect(() => NutrientValue(value: -1), throwsArgumentError);
    expect(
      () => FoodAmount(value: double.infinity, unit: FoodQuantityUnit.g),
      throwsArgumentError,
    );
    expect(
      () => NutritionBasis(amount: 0, unit: FoodQuantityUnit.g),
      throwsArgumentError,
    );
    expect(
      () => FoodConversion(gramsPerCount: 0, sourceId: 'fixture'),
      throwsArgumentError,
    );
    expect(
      () => calculate([input('a', food()), input('a', food())]),
      throwsArgumentError,
    );
    expect(
      () => calculate([input('a', food())], portions: 0),
      throwsArgumentError,
    );
    final j = food().toJson();
    (((j['nutrition'] as Map)['values'] as List).first as Map)['unit'] = 'mg';
    expect(() => FoodRecord.fromJson(j), throwsFormatException);
    final branded = food().toJson()
      ..addAll({
        'kind': 'packaged',
        'brand': 'Fixture',
        'market': 'EG',
        'gtin': '3017620422003',
      });
    expect(FoodRecord.fromJson(branded).gtin, '3017620422003');
    branded['gtin'] = '3017620422004';
    expect(() => FoodRecord.fromJson(branded), throwsArgumentError);
  });

  test(
    'canonical allergen aliases preserve source evidence and exact scope',
    () {
      final declaration = AllergenDeclaration(
        allergenId: 'en:eggs',
        status: AllergenStatus.contains,
        evidence: 'Source tag en:eggs',
        sourceId: 'fixture',
      );
      final record = food(allergens: [declaration]);
      expect(declaration.allergenId, 'egg');
      expect(declaration.evidence, 'Source tag en:eggs');
      expect(foodAllergenStatus(record, 'egg'), AllergenStatus.contains);
      expect(foodAllergenStatus(record, 'eggs'), AllergenStatus.contains);
      expect(foodAllergenStatus(record, 'en:eggs'), AllergenStatus.contains);
      expect(canonicalAllergenId('soybeans'), 'soy');
      expect(canonicalAllergenId('en:nuts'), 'treeNuts');
      expect(canonicalAllergenId('sesame-seeds'), 'sesame');
      expect(canonicalAllergenId('cereals-containing-gluten'), 'gluten');
      expect(canonicalAllergenId('wheat'), 'wheat');
      expect(canonicalAllergenId('almond'), 'almond');
      expect(canonicalAllergenId('custom:my-food'), 'custom:my-food');
      final wheat = food(
        allergens: [
          AllergenDeclaration(
            allergenId: 'wheat',
            status: AllergenStatus.contains,
            evidence: 'Synthetic wheat label',
            sourceId: 'fixture',
          ),
        ],
      );
      expect(foodAllergenStatus(wheat, 'gluten'), AllergenStatus.unknown);
      expect(
        () => food(
          allergens: [
            declaration,
            AllergenDeclaration(
              allergenId: 'egg',
              status: AllergenStatus.mayContain,
              evidence: 'Synthetic trace',
              sourceId: 'fixture',
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        FoodRecord.fromJson(record.toJson()).allergens.single.allergenId,
        'egg',
      );
    },
  );

  test(
    'compound lookup cannot substitute a different food under the expected key',
    () {
      final egg = food(
        id: 'egg',
        allergens: [
          AllergenDeclaration(
            allergenId: 'egg',
            status: AllergenStatus.contains,
            evidence: 'Synthetic egg label',
            sourceId: 'fixture',
          ),
        ],
      );
      final compound = food(
        components: [FoodComponent(foodId: 'milk', foodVersion: 'v1')],
      );
      expect(
        foodAllergenStatus(compound, 'egg', catalog: {'milk@v1': egg}),
        AllergenStatus.unknown,
      );
    },
  );

  test('different carbohydrate definitions never merge or subtract fibre implicitly', () {
    final byDifference = food(
      id: 'by-difference',
      values: {
        NutrientId.carbohydrateByDifference: NutrientValue(value: 20),
        NutrientId.fibre: NutrientValue(value: 5),
      },
    );
    final available = food(
      id: 'available',
      values: {
        NutrientId.availableCarbohydrate: NutrientValue(value: 15),
        NutrientId.fibre: NutrientValue(value: 3),
      },
    );
    final result = calculate([
      input('a', byDifference, amount: 100),
      input('b', available, amount: 100),
    ]);
    expect(result.whole[NutrientId.carbohydrate]!.value, isNull);
    expect(
      result.whole[NutrientId.carbohydrateByDifference]!.knownSubtotal,
      20,
    );
    expect(result.whole[NutrientId.carbohydrateByDifference]!.value, isNull);
    expect(result.whole[NutrientId.availableCarbohydrate]!.knownSubtotal, 15);
    expect(result.whole[NutrientId.availableCarbohydrate]!.value, isNull);
    expect(result.whole[NutrientId.fibre]!.value, 8);
    final single = calculate([input('a', byDifference, amount: 100)]);
    expect(single.whole[NutrientId.carbohydrateByDifference]!.value, 20);
    expect(single.whole[NutrientId.availableCarbohydrate]!.value, isNull);
  });
}
