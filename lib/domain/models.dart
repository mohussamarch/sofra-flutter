enum StorageZone { fridge, freezer, pantry }

enum IngredientRole { main, supporting, optional }

class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.unit,
    required this.zone,
    required this.pricePerUnit,
    required this.purchasePackQuantity,
    required this.purchasePackPrice,
  });

  final String id;
  final String name;
  final String emoji;
  final String category;
  final String unit;
  final StorageZone zone;
  final double pricePerUnit;
  final double purchasePackQuantity;
  final double purchasePackPrice;
}

class StockItem {
  const StockItem(this.ingredientId, this.quantity, this.zone);

  final String ingredientId;
  final double quantity;
  final StorageZone zone;

  StockItem copyWith({double? quantity, StorageZone? zone}) =>
      StockItem(ingredientId, quantity ?? this.quantity, zone ?? this.zone);
}

class RecipeIngredient {
  const RecipeIngredient(this.ingredientId, this.quantity, this.role);

  final String ingredientId;
  final double quantity;
  final IngredientRole role;
}

class CookingStep {
  const CookingStep(this.title, this.detail, this.minutes, this.emoji);

  final String title;
  final String detail;
  final int minutes;
  final String emoji;
}

class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.cuisine,
    required this.minutes,
    required this.baseServings,
    required this.parts,
    required this.ingredients,
    required this.steps,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
  final String category;
  final String cuisine;
  final int minutes;
  final int baseServings;
  final List<String> parts;
  final List<RecipeIngredient> ingredients;
  final List<CookingStep> steps;
}
