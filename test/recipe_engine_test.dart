import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/demo_data.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/recipe_engine.dart';

void main() {
  const engine = RecipeEngine(demoIngredients);
  final meal = demoRecipes.first;

  test('four servings distinguish insufficient stock and package cost', () {
    final result = engine.evaluate(meal, 4, demoStarterStock);
    expect(
      result.missing.map((need) => need.ingredient.id),
      containsAll(['chicken', 'tomato']),
    );
    expect(
      result.missing
          .firstWhere((need) => need.ingredient.id == 'chicken')
          .missingQuantity,
      200,
    );
    expect(
      result.missing
          .firstWhere((need) => need.ingredient.id == 'tomato')
          .missingQuantity,
      200,
    );
    expect(result.purchaseCost, 250);
    expect(result.consumedCost, greaterThan(250));
  });

  test('one serving rescales ingredients without changing stock', () {
    final result = engine.evaluate(meal, 1, demoStarterStock);
    expect(result.fullyAvailable, isTrue);
    expect(
      result.needs
          .firstWhere((need) => need.ingredient.id == 'chicken')
          .requiredQuantity,
      250,
    );
    expect(demoStarterStock.first.quantity, 800);
  });

  test('confirmed cooking consumes stock quantities', () {
    final stock = <StockItem>[
      ...demoStarterStock,
      const StockItem('chicken', 200, StorageZone.freezer),
      const StockItem('tomato', 200, StorageZone.fridge),
    ];
    final result = engine.evaluate(meal, 4, stock);
    expect(result.fullyAvailable, isTrue);
    final after = engine.consume(result, stock);
    expect(after.where((item) => item.ingredientId == 'chicken'), isEmpty);
    expect(
      after.where((item) => item.ingredientId == 'rice').single.quantity,
      100,
    );
    expect(after.where((item) => item.ingredientId == 'tomato'), isEmpty);
  });
}
