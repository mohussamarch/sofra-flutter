import 'dart:math' as math;

import 'models.dart';

class IngredientNeed {
  const IngredientNeed({
    required this.ingredient,
    required this.requiredQuantity,
    required this.availableQuantity,
    required this.role,
  });

  final Ingredient ingredient;
  final double requiredQuantity;
  final double availableQuantity;
  final IngredientRole role;

  double get missingQuantity =>
      math.max(0, requiredQuantity - availableQuantity);
  bool get isEnough => missingQuantity < 1e-9;
  double get consumedCost => requiredQuantity * ingredient.pricePerUnit;
  double get purchaseCost => missingQuantity <= 0
      ? 0
      : (missingQuantity / ingredient.purchasePackQuantity).ceil() *
            ingredient.purchasePackPrice;
}

class RecipeEstimate {
  const RecipeEstimate(this.recipe, this.servings, this.needs);

  final Recipe recipe;
  final int servings;
  final List<IngredientNeed> needs;

  List<IngredientNeed> get missing =>
      needs.where((need) => !need.isEnough).toList();
  List<IngredientNeed> get available =>
      needs.where((need) => need.isEnough).toList();
  double get consumedCost =>
      needs.fold(0, (total, need) => total + need.consumedCost);
  double get purchaseCost =>
      needs.fold(0, (total, need) => total + need.purchaseCost);
  double get costPerServing => consumedCost / servings;
  bool get fullyAvailable => missing.isEmpty;

  /// Only a main ingredient makes a partly missing recipe eligible for discovery.
  bool get hasMainIngredient => needs.any(
    (need) => need.role == IngredientRole.main && need.availableQuantity > 0,
  );

  double get availabilityFraction {
    if (needs.isEmpty) return 0;
    return needs.fold<double>(
          0,
          (total, need) =>
              total +
              math.min(1, need.availableQuantity / need.requiredQuantity),
        ) /
        needs.length;
  }
}

class RecipeEngine {
  const RecipeEngine(this.ingredients);

  final Map<String, Ingredient> ingredients;

  RecipeEstimate evaluate(Recipe recipe, int servings, List<StockItem> stock) {
    if (servings < 1 || recipe.baseServings < 1) {
      throw ArgumentError('Invalid servings');
    }
    final available = <String, double>{};
    for (final item in stock) {
      if (!item.quantity.isFinite || item.quantity < 0) {
        throw ArgumentError('Invalid stock quantity');
      }
      available.update(
        item.ingredientId,
        (value) => value + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }
    final entries = <String, RecipeIngredient>{};
    for (final entry in recipe.ingredients) {
      if (!entry.quantity.isFinite ||
          entry.quantity <= 0 ||
          !ingredients.containsKey(entry.ingredientId)) {
        throw ArgumentError('Invalid recipe ingredient');
      }
      final previous = entries[entry.ingredientId];
      entries[entry.ingredientId] = RecipeIngredient(
        entry.ingredientId,
        entry.quantity + (previous?.quantity ?? 0),
        previous?.role == IngredientRole.main
            ? IngredientRole.main
            : entry.role,
      );
    }
    final needs = entries.values.map((entry) {
      var quantity = entry.quantity * servings / recipe.baseServings;
      final ingredient = ingredients[entry.ingredientId]!;
      if (ingredient.unit == 'حبة' || ingredient.unit == 'علبة') {
        quantity = quantity.ceilToDouble();
      }
      return IngredientNeed(
        ingredient: ingredient,
        requiredQuantity: quantity,
        availableQuantity: available[entry.ingredientId] ?? 0,
        role: entry.role,
      );
    }).toList();
    return RecipeEstimate(recipe, servings, needs);
  }

  List<StockItem> consume(RecipeEstimate estimate, List<StockItem> stock) {
    final current = evaluate(estimate.recipe, estimate.servings, stock);
    if (!current.fullyAvailable) {
      throw StateError('Insufficient stock; review quantities');
    }
    final remaining = stock.map((item) => item.copyWith()).toList();
    for (final need in current.needs) {
      var toConsume = need.requiredQuantity;
      for (var index = 0; index < remaining.length && toConsume > 0; index++) {
        final item = remaining[index];
        if (item.ingredientId != need.ingredient.id) continue;
        final used = math.min(item.quantity, toConsume);
        remaining[index] = item.copyWith(quantity: item.quantity - used);
        toConsume -= used;
      }
    }
    return remaining.where((item) => item.quantity > 0.001).toList();
  }
}

String formatQuantity(double quantity) {
  if (quantity == quantity.roundToDouble()) return quantity.toInt().toString();
  return quantity.toStringAsFixed(1);
}

String formatMoney(double amount) => amount.round().toString();
