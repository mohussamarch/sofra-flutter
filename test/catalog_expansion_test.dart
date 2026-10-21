import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';
import 'package:tabkha_demo/domain/recipe_nutrition.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';

void main() {
  final repo = RecipeRepository(read: (path) => File(path).readAsString());
  const added = {
    'bc-tzatziki': 'يوناني',
    'bc-chicken-paprikash': 'مجري',
    'bc-baked-rice': 'إسباني',
    'bc-chicken-in-red-wine-vinegar-sauce': 'فرنسي',
    'bc-cheesy-ham-and-potato-bake': 'فنلندي',
    'bc-tarte-merengada': 'برتغالي',
    'bc-ukrainian-borscht': 'أوكراني',
    'bc-tajine': 'تونسي',
    'bc-tarta-de-santiago': 'إسباني',
    'bc-zurich-sytle-meat-saute': 'سويسري',
    'bc-arroz-chaufa': 'بيروفي',
  };

  test(
    'new cuisines load through the operational repository and preserve sources',
    () async {
      final all = await repo.loadAll();
      expect(all, hasLength(65));
      expect(all.map((r) => r.cuisine).toSet(), hasLength(14));
      for (final pair in added.entries) {
        final recipe = await repo.get(pair.key);
        expect(recipe.cuisine, pair.value);
        expect(
          (await repo.search(cuisine: pair.value)).map((r) => r['id']),
          contains(pair.key),
        );
        final snapshot = recipe.toJson();
        final restored = CatalogRecipe.fromJson(
          jsonDecode(jsonEncode(snapshot)),
        );
        expect(restored.toJson(), snapshot);
        expect(
          restored.notes,
          contains(
            'https://github.com/LukeSmithxyz/based.cooking/blob/9d4a31a040eedd61e4fb608cb0c114ff9a7c4dd2/',
          ),
        );
        expect(recipe.steps, hasLength(1));
        expect(
          recipe.steps.single.minutes,
          recipe.prepMinutes + recipe.cookMinutes,
        );
        expect(recipe.steps.single.tip, contains('إجمالي'));
        expect(recipe.steps.single.passive, isFalse);
        for (final ingredient in recipe.ingredients) {
          expect(ingredient.id, startsWith('${pair.key}-'));
          if (ingredient.amount == null) {
            expect(ingredient.scales, isFalse);
            expect(
              recipe.forServings(recipe.servings * 2).quantity(ingredient),
              isNull,
            );
          }
        }
        final coverage = assessRecipeNutrition(
          scaled: recipe.forServings(recipe.servings),
          selections: [],
        );
        expect(coverage.whole[NutrientId.protein]!.value, isNull);
        expect(coverage.per100g, isNull);
      }
      expect((await repo.search(cuisine: 'مصري')), hasLength(12));
      expect((await repo.search(cuisine: 'شامي')), hasLength(14));
      expect((await repo.search(cuisine: 'سعودي')), hasLength(14));
      expect((await repo.search(cuisine: 'إيطالي')), hasLength(14));
    },
  );
}
