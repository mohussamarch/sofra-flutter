import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/food_repository.dart';
import 'package:tabkha_demo/data/recipe_library_food_search.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/recipe_library_draft.dart';

import 'recipe_library_food_search_test.dart' as fixture;

class Sources extends fixture.FoodAssets {
  String version = 'v1', name = 'Rice, white, raw';
  int fullSourceReads = 0;
  @override
  Future<String> read(String path) async {
    if (path == 'data/usda/shards/01.json') {
      fullSourceReads++;
      return jsonEncode([
        {
          'id': 'usda:1',
          'fdcId': 1,
          'version': version,
          'name': name,
          'nutrients': [],
        },
      ]);
    }
    if (path == 'data/usda/nutrient-definitions.json') {
      return '{"nutrients":{}}';
    }
    return super.read(path);
  }
}

void main() {
  test('explicit candidate selection reads the chosen identity and version without choosing quantity or saving', () async {
    final e = await fixture.entry(), assets = Sources();
    final search = RecipeLibraryFoodSearch(
      foods: FoodRepository(read: assets.read),
    );
    final result = await search.search(
      entry: e,
      expectedSourceFingerprint: recipeLibrarySourceFingerprint(e),
      lineIndex: 1,
      query: 'rice',
    );
    final food = await search.resolveUsdaCandidate(
      result: result,
      currentEntry: e,
      foodId: 'usda:1',
      form: 'raw',
      acknowledgeFoodIdentity: true,
    );
    expect(food.id, 'usda:1');
    expect(food.version, 'v1');
    expect(food.form, FoodForm.raw);
    expect(food.nameEn, 'Rice, white, raw');
    expect(food.sources.single.authority, 'USDA FoodData Central');
    expect(result.ingredient.amount, isNull);
    expect(result.requiresExplicitReview, true);
    expect(e.nutrition, isNull);
    expect(e.runtimeReady, false);
    expect(assets.fullSourceReads, 1);
  });
  test('absent candidates, missing acknowledgment, stale recipe and invalid form reject before full food reads', () async {
    final e = await fixture.entry(),
        changed = await fixture.entry(amount: 3),
        assets = Sources();
    final search = RecipeLibraryFoodSearch(
      foods: FoodRepository(read: assets.read),
    );
    final result = await search.search(
      entry: e,
      expectedSourceFingerprint: recipeLibrarySourceFingerprint(e),
      lineIndex: 0,
      query: 'rice',
    );
    await expectLater(
      search.resolveUsdaCandidate(
        result: result,
        currentEntry: e,
        foodId: 'usda:1',
        form: 'raw',
        acknowledgeFoodIdentity: false,
      ),
      throwsArgumentError,
    );
    await expectLater(
      search.resolveUsdaCandidate(
        result: result,
        currentEntry: e,
        foodId: 'usda:2',
        form: 'raw',
        acknowledgeFoodIdentity: true,
      ),
      throwsArgumentError,
    );
    await expectLater(
      search.resolveUsdaCandidate(
        result: result,
        currentEntry: e,
        foodId: '100',
        form: 'raw',
        acknowledgeFoodIdentity: true,
      ),
      throwsArgumentError,
    );
    await expectLater(
      search.resolveUsdaCandidate(
        result: result,
        currentEntry: changed,
        foodId: 'usda:1',
        form: 'raw',
        acknowledgeFoodIdentity: true,
      ),
      throwsStateError,
    );
    await expectLater(
      search.resolveUsdaCandidate(
        result: result,
        currentEntry: e,
        foodId: 'usda:1',
        form: 'invalid',
        acknowledgeFoodIdentity: true,
      ),
      throwsArgumentError,
    );
    expect(assets.fullSourceReads, 0);
  });
  test('food version or description drift requires a fresh search and identity review', () async {
    for (final field in ['version', 'name']) {
      final e = await fixture.entry(), assets = Sources();
      final search = RecipeLibraryFoodSearch(
        foods: FoodRepository(read: assets.read),
      );
      final result = await search.search(
        entry: e,
        expectedSourceFingerprint: recipeLibrarySourceFingerprint(e),
        lineIndex: 0,
        query: 'rice',
      );
      if (field == 'version') {
        assets.version = 'v2';
      } else {
        assets.name = 'Different food';
      }
      await expectLater(
        search.resolveUsdaCandidate(
          result: result,
          currentEntry: e,
          foodId: 'usda:1',
          form: 'raw',
          acknowledgeFoodIdentity: true,
        ),
        throwsStateError,
      );
    }
  });
}
