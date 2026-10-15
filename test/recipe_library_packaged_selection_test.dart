import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/food_repository.dart';
import 'package:tabkha_demo/data/recipe_library_assets.dart';
import 'package:tabkha_demo/data/recipe_library_food_search.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/recipe_library_draft.dart';

import 'recipe_library_food_search_test.dart' as fixture;

Map<String, dynamic> product({double protein = 3}) => {
  'id': 'off:0123456789012',
  'barcode': '0123456789012',
  'names': {
    'ar': 'منتج اختبار',
    'en': 'Fixture rice',
    'original': 'Fixture rice',
  },
  'markets': ['EG', 'SA'],
  'brands': 'Fixture brand',
  'nutrition': {
    'asSold': {
      'proteins': {
        'value': protein,
        'unit': 'g',
        'modifier': null,
        'sourceField': 'proteins_100g',
      },
    },
  },
  'allergens': {'declaredTags': [], 'traceTags': []},
  'package': {'quantity': 100, 'unit': 'g'},
  'source': {
    'url': 'https://example.org/product/0123456789012',
    'retrievedAt': '2026-10-12T00:00:00Z',
    'lastModifiedEpoch': 1,
  },
};
FoodRepository repository(Map<String, dynamic> row) => FoodRepository(
  read: (path) async {
    if (path == 'data/food/openfoodfacts/products.jsonl') {
      return jsonEncode(row);
    }
    throw StateError('Unexpected bank read:$path');
  },
);

class TrackedFoods extends FoodRepository {
  TrackedFoods(Map<String, dynamic> row)
    : super(read: (path) async => jsonEncode(row));
  int rawReads = 0;
  @override
  Future<Map<String, dynamic>> productRaw(String barcode) {
    rawReads++;
    return super.productRaw(barcode);
  }
}

FoodSource label({String? barcode = '0123456789012'}) => FoodSource(
  id: 'fixture-review',
  url: 'https://example.org/label',
  authority: 'Fixture label review',
  license: 'user-provided',
  retrievedAt: DateTime.utc(2026, 10, 15),
  recordId: barcode,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('selected package keeps unknown nutrition basis until exact scoped label review', () async {
    final e = await fixture.entry(),
        search = RecipeLibraryFoodSearch(foods: repository(product()));
    final result = await search.search(
      entry: e,
      expectedSourceFingerprint: recipeLibrarySourceFingerprint(e),
      lineIndex: 1,
      query: '0123456789012',
      market: 'EG',
      packagedOnly: true,
    );
    final food = await search.resolvePackagedCandidate(
      result: result,
      currentEntry: e,
      barcode: '0123456789012',
      market: 'EG',
      acknowledgeProductIdentity: true,
    );
    expect(food.gtin, '0123456789012');
    expect(food.market, 'EG');
    expect(food.form, FoodForm.asSold);
    expect(food.nutrition.basis.unit, FoodQuantityUnit.unknown);
    expect(result.ingredient.amount, isNull);
    expect(e.nutrition, isNull);
    expect(e.runtimeReady, false);
    final nutrition = calculateRecipeNutrition(
      recipeId: 'fixture',
      recipeVersion: 'v1',
      inputs: [
        RecipeFoodInput(
          ingredientId: 'p',
          food: food,
          amount: FoodAmount(value: 100, unit: FoodQuantityUnit.g),
          amountForm: FoodForm.asSold,
          preparedForm: FoodForm.asSold,
        ),
      ],
      portions: 1,
    );
    expect(nutrition.whole[NutrientId.protein]!.value, isNull);
    final reviewed = await search.resolvePackagedCandidate(
      result: result,
      currentEntry: e,
      barcode: '0123456789012',
      market: 'EG',
      acknowledgeProductIdentity: true,
      reviewedBasis: NutritionBasis(amount: 100, unit: FoodQuantityUnit.g),
      reviewSource: label(),
    );
    expect(reviewed.nutrition.basis.unit, FoodQuantityUnit.g);
    expect(reviewed.sources.last.recordId, '0123456789012');
    expect(reviewed.nutrition.values[NutrientId.protein]!.value, 3);
  });
  test('acknowledgment, recipe pin, returned barcode, search market and label scope gate raw reads', () async {
    final e = await fixture.entry(), changed = await fixture.entry(amount: 3);
    final result = await RecipeLibraryFoodSearch(foods: repository(product()))
        .search(
          entry: e,
          expectedSourceFingerprint: recipeLibrarySourceFingerprint(e),
          lineIndex: 0,
          query: '0123456789012',
          market: 'EG',
          packagedOnly: true,
        );
    final tracked = TrackedFoods(product()),
        search = RecipeLibraryFoodSearch(foods: tracked);
    await expectLater(
      search.resolvePackagedCandidate(
        result: result,
        currentEntry: e,
        barcode: '0123456789012',
        market: 'EG',
        acknowledgeProductIdentity: false,
      ),
      throwsArgumentError,
    );
    await expectLater(
      search.resolvePackagedCandidate(
        result: result,
        currentEntry: changed,
        barcode: '0123456789012',
        market: 'EG',
        acknowledgeProductIdentity: true,
      ),
      throwsStateError,
    );
    for (final choice in [
      (barcode: 'not-returned', market: 'EG'),
      (barcode: '0123456789012', market: 'SA'),
      (barcode: '0123456789012', market: 'US'),
    ]) {
      await expectLater(
        search.resolvePackagedCandidate(
          result: result,
          currentEntry: e,
          barcode: choice.barcode,
          market: choice.market,
          acknowledgeProductIdentity: true,
        ),
        throwsArgumentError,
      );
    }
    await expectLater(
      search.resolvePackagedCandidate(
        result: result,
        currentEntry: e,
        barcode: '0123456789012',
        market: 'EG',
        acknowledgeProductIdentity: true,
        reviewedBasis: NutritionBasis(amount: 100, unit: FoodQuantityUnit.g),
      ),
      throwsArgumentError,
    );
    for (final wrong in ['other', null]) {
      await expectLater(
        search.resolvePackagedCandidate(
          result: result,
          currentEntry: e,
          barcode: '0123456789012',
          market: 'EG',
          acknowledgeProductIdentity: true,
          reviewedBasis: NutritionBasis(amount: 100, unit: FoodQuantityUnit.g),
          reviewSource: label(barcode: wrong),
        ),
        throwsArgumentError,
      );
    }
    expect(tracked.rawReads, 0);
  });
  test('full source drift rejects even with unchanged source version while key order does not', () async {
    final e = await fixture.entry();
    final result = await RecipeLibraryFoodSearch(foods: repository(product()))
        .search(
          entry: e,
          expectedSourceFingerprint: recipeLibrarySourceFingerprint(e),
          lineIndex: 0,
          query: '0123456789012',
          market: 'EG',
          packagedOnly: true,
        );
    final changed = RecipeLibraryFoodSearch(
      foods: repository(product(protein: 4)),
    );
    await expectLater(
      changed.resolvePackagedCandidate(
        result: result,
        currentEntry: e,
        barcode: '0123456789012',
        market: 'EG',
        acknowledgeProductIdentity: true,
      ),
      throwsStateError,
    );
    final same = product();
    same['source'] = Map<String, dynamic>.fromEntries(
      (same['source'] as Map<String, dynamic>).entries.toList().reversed,
    );
    final reordered = RecipeLibraryFoodSearch(
      foods: repository(
        Map<String, dynamic>.fromEntries(same.entries.toList().reversed),
      ),
    );
    expect(
      (await reordered.resolvePackagedCandidate(
        result: result,
        currentEntry: e,
        barcode: '0123456789012',
        market: 'EG',
        acknowledgeProductIdentity: true,
      )).gtin,
      '0123456789012',
    );
  });
  test(
    'actual bundled product selection preserves source-only unknown basis',
    () async {
      final foods = FoodRepository(), rows = await foods.products();
      final row = rows.firstWhere(
        (r) =>
            (r['brands'] as String).trim().isNotEmpty &&
            (r['markets'] as List).isNotEmpty,
      );
      final e = (await bundledRecipeLibrary().all()).first;
      final search = RecipeLibraryFoodSearch(foods: foods),
          market = (row['markets'] as List).first as String;
      final result = await search.search(
        entry: e,
        expectedSourceFingerprint: recipeLibrarySourceFingerprint(e),
        lineIndex: 0,
        query: row['barcode'] as String,
        market: market,
        packagedOnly: true,
      );
      final food = await search.resolvePackagedCandidate(
        result: result,
        currentEntry: e,
        barcode: row['barcode'] as String,
        market: market,
        acknowledgeProductIdentity: true,
      );
      expect(food.gtin, row['barcode']);
      expect(food.market, market);
      expect(food.nutrition.basis.unit, FoodQuantityUnit.unknown);
      expect(e.nutrition, isNull);
      expect(e.runtimeReady, false);
    },
  );
}
