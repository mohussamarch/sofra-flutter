import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';
import 'package:tabkha_demo/domain/recipe_nutrition.dart';

import 'recipe_variants_test.dart' as fixture;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/food_repository.dart';
import 'package:tabkha_demo/data/household_measure_repository.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<String> read(String p) => File(p).readAsString();
  test('all curated source measures load with exact version/form and six explicit gaps', () async {
    final foods = FoodRepository(read: read),
        measures = HouseholdMeasureRepository(read: read);
    final data = jsonDecode(
      await read('data/nutrition/household-measures-review.json'),
    ) as Map;
    var options = 0, gaps = 0;
    for (final raw in data['entries'] as List) {
      final food = await foods.usdaFood(
        raw['foodId'] as String,
        form: raw['form'] as String,
      );
      final review = await measures.optionsFor(food);
      options += review.options.length;
      if (review.options.isEmpty) {
        gaps++;
        expect(review.issues, isNotEmpty);
      }
    }
    expect(options, 103);
    expect(gaps, 6);
  });
  test('source measure acceptance is explicit; fractional scaling preserves evidence', () async {
    final foods = FoodRepository(read: read),
        measures = HouseholdMeasureRepository(read: read);
    final food = await foods.usdaFood('usda:170000', form: 'raw');
    final review = await measures.optionsFor(food),
        option = review.options.first;
    await expectLater(
      measures.resolve(
        food,
        optionId: option.id,
        measureQuantity: 0.5,
        acknowledgeExactSourcePortion: false,
      ),
      throwsArgumentError,
    );
    final result = await measures.resolve(
      food,
      optionId: option.id,
      measureQuantity: 0.5,
      acknowledgeExactSourcePortion: true,
    );
    expect(result.amount.unit, FoodQuantityUnit.g);
    expect(
      result.amount.value,
      closeTo(option.gramWeight * 0.5 / option.amount, 1e-9),
    );
    expect(result.estimated, isTrue);
    expect(result.basis, 'edibleInput');
    expect(result.toJson()['foodId'], food.id);
    expect(result.toJson()['sourceEvidence'], isNotEmpty);
    for (final q in [0.0, -1.0, double.nan, double.infinity]) {
      await expectLater(
        measures.resolve(
          food,
          optionId: option.id,
          measureQuantity: q,
          acknowledgeExactSourcePortion: true,
        ),
        throwsArgumentError,
      );
    }
    await expectLater(
      measures.resolve(
        food,
        optionId: 'wrong',
        measureQuantity: 1,
        acknowledgeExactSourcePortion: true,
      ),
      throwsArgumentError,
    );
  });
  test(
    'wrong food version/form and changed source portion cannot inherit review',
    () async {
      final foods = FoodRepository(read: read),
          measures = HouseholdMeasureRepository(read: read);
      final food = await foods.usdaFood('usda:170000', form: 'raw');
      await expectLater(
        measures.optionsFor(
          FoodRecord.fromJson({...food.toJson(), 'version': 'stale'}),
        ),
        throwsStateError,
      );
      await expectLater(
        measures.optionsFor(
          FoodRecord.fromJson({...food.toJson(), 'form': 'cooked'}),
        ),
        throwsStateError,
      );
      final broken = HouseholdMeasureRepository(
        read: (p) async {
          final text = await read(p);
          if (!p.endsWith('household-measures-review.json')) return text;
          final j = jsonDecode(text) as Map;
          final e = (j['entries'] as List).firstWhere(
            (e) => e['foodId'] == food.id,
          );
          (e['options'] as List)[0]['gramWeight'] = 999999;
          return jsonEncode(j);
        },
      );
      await expectLater(broken.optionsFor(food), throwsStateError);
    },
  );
  test(
    'accepted source grams feed input preview without changing stock/history',
    () async {
      final base = fixture.recipe();
      final json = base.toJson();
      json['ingredients'] = [
        {'id': 'onion', 'name': 'Onion fixture', 'amount': 1, 'unit': 'حبة'},
      ];
      final recipe = CatalogRecipe.fromJson(json);
      final kitchen = KitchenService(
        fixture.Store(),
        fixture.repository(value: recipe),
      );
      await kitchen.load();
      final revision = await kitchen.catalogRevision(recipe.id);
      final food = await FoodRepository(read: read)
          .usdaFood('usda:170000', form: 'raw');
      await kitchen.saveRecipeFoodSelection(
        RecipeFoodSelection(
          recipeId: recipe.id,
          recipeRevisionKey: revision.key,
          line: 0,
          food: food,
          amountForm: FoodForm.raw,
          preparedForm: FoodForm.cooked,
        ),
      );
      await kitchen.plan(fixture.plan('meal', recipe.id));
      final before = kitchen.snapshot;
      expect(
        (await kitchen.previewIngredientNutrition('meal'))
            .whole[NutrientId.protein]!
            .value,
        isNull,
      );
      final measures = HouseholdMeasureRepository(read: read),
          review = await measures.optionsFor(food);
      final proposal = await measures.resolve(
        food,
        optionId: review.options.first.id,
        measureQuantity: 1,
        acknowledgeExactSourcePortion: true,
      );
      final input = await kitchen.previewIngredientNutrition(
        'meal',
        measuredLines: {0: proposal.amount},
      );
      expect(input.estimated, isTrue);
      expect(input.whole[NutrientId.protein]!.value, isNotNull);
      expect(
        (await kitchen.previewNutrition(
          'meal',
          measuredLines: {0: proposal.amount},
        )).whole[NutrientId.protein]!.value,
        isNull,
      );
      expect(kitchen.snapshot, before);
    },
  );
}
