import 'dart:convert';

import 'food_nutrition.dart';
import 'person_nutrition.dart';
import 'recipe_catalog.dart';

/// One explicit food selection per recipe LINE. The same ingredient ID may
/// describe raw rice in one recipe and cooked rice in another.
class RecipeFoodSelection {
  RecipeFoodSelection({
    required this.recipeId,
    required this.line,
    required this.food,
    required this.amountForm,
    required this.preparedForm,
    this.measuredAmount,
    this.preparation,
    this.asPurchased = false,
    this.notConsumed = false,
    this.exclusionReason,
    this.recipeRevisionKey,
  }) {
    if (recipeId.trim().isEmpty ||
        line < 0 ||
        (recipeRevisionKey != null && recipeRevisionKey!.trim().isEmpty)) {
      throw ArgumentError('Invalid recipe line');
    }
    if (notConsumed &&
        (exclusionReason == null || exclusionReason!.trim().isEmpty)) {
      throw ArgumentError('Excluded nonconsumed material requires a reason');
    }
  }
  final String recipeId;
  final String? recipeRevisionKey;
  final int line;
  final FoodRecord food;
  final FoodForm amountForm, preparedForm;

  /// Explicit base-recipe amount; scales with its recipe line only.
  final FoodAmount? measuredAmount;
  final PreparationTransform? preparation;
  final bool asPurchased, notConsumed;
  final String? exclusionReason;
  String get key => jsonEncode([recipeId, recipeRevisionKey, line]);
  Map<String, dynamic> toJson() => {
    'version': 1,
    'recipeId': recipeId,
    'recipeRevisionKey': recipeRevisionKey,
    'line': line,
    'food': food.toJson(),
    'amountForm': amountForm.name,
    'preparedForm': preparedForm.name,
    'measuredAmount': measuredAmount?.toJson(),
    'preparation': preparation?.toJson(),
    'asPurchased': asPurchased,
    'notConsumed': notConsumed,
    'exclusionReason': exclusionReason,
  };
  factory RecipeFoodSelection.fromJson(Map<String, dynamic> j) {
    if (j['version'] != 1) {
      throw const FormatException('Food selection version');
    }
    return RecipeFoodSelection(
      recipeId: j['recipeId'] as String,
      recipeRevisionKey: j['recipeRevisionKey'] as String?,
      line: j['line'] as int,
      food: FoodRecord.fromJson(Map<String, dynamic>.from(j['food'] as Map)),
      amountForm: FoodForm.values.byName(j['amountForm'] as String),
      preparedForm: FoodForm.values.byName(j['preparedForm'] as String),
      measuredAmount: j['measuredAmount'] == null
          ? null
          : FoodAmount.fromJson(
              Map<String, dynamic>.from(j['measuredAmount'] as Map),
            ),
      preparation: j['preparation'] == null
          ? null
          : PreparationTransform.fromJson(
              Map<String, dynamic>.from(j['preparation'] as Map),
            ),
      asPurchased: j['asPurchased'] == true,
      notConsumed: j['notConsumed'] == true,
      exclusionReason: j['exclusionReason'] as String?,
    );
  }
}

FoodQuantityUnit? nutritionUnit(String? unit) => switch (unit) {
  'g' || 'جرام' => FoodQuantityUnit.g,
  'kg' || 'كيلو' => FoodQuantityUnit.kg,
  'ml' || 'مل' => FoodQuantityUnit.ml,
  'l' || 'لتر' => FoodQuantityUnit.l,
  'count' ||
  'حبة' ||
  'حبات' ||
  'بيضة' ||
  'بيضة كبيرة' => FoodQuantityUnit.count,
  'serving' => FoodQuantityUnit.serving,
  _ => null,
};

RecipeNutritionResult assessRecipeNutrition({
  required ScaledCatalogRecipe scaled,
  required List<RecipeFoodSelection> selections,
  Set<String> optionalIds = const {},
  Set<int>? optionalLines,
  Set<int> excludedLines = const {},
  Map<int, FoodAmount> measuredLines = const {},
  double? cookedYieldGrams,
  String? recipeRevisionKey,
}) {
  final recipe = scaled.recipe;
  final byLine = <int, RecipeFoodSelection>{};
  for (final binding in selections) {
    if (binding.recipeId != recipe.id ||
        binding.recipeRevisionKey != recipeRevisionKey ||
        binding.line >= recipe.ingredients.length ||
        byLine.containsKey(binding.line)) {
      throw ArgumentError('Invalid/duplicate recipe food selection');
    }
    byLine[binding.line] = binding;
  }
  if (measuredLines.keys.any((i) => i < 0 || i >= recipe.ingredients.length)) {
    throw ArgumentError('Invalid measured line');
  }
  if (optionalLines != null && optionalIds.isNotEmpty) {
    throw ArgumentError(
      'Choose optional ingredients by IDs or lines, not both',
    );
  }
  if ((optionalLines ?? {}).any(
        (i) =>
            i < 0 ||
            i >= recipe.ingredients.length ||
            !recipe.ingredients[i].optional,
      ) ||
      excludedLines.any((i) => i < 0 || i >= recipe.ingredients.length)) {
    throw ArgumentError('Invalid optional/excluded recipe line');
  }
  final inputs = <RecipeFoodInput>[];
  for (var i = 0; i < recipe.ingredients.length; i++) {
    final row = recipe.ingredients[i], binding = byLine[i];
    final unit = nutritionUnit(row.unit), quantity = scaled.quantity(row);
    final explicit = binding?.measuredAmount;
    final amount =
        measuredLines[i] ??
        (explicit != null && (quantity == null || unit == null)
            ? FoodAmount(
                value: explicit.value * (row.scales ? scaled.factor : 1),
                unit: explicit.unit,
              )
            : quantity == null || unit == null
            ? null
            : FoodAmount(value: quantity, unit: unit));
    // An unbound preparation is unknown: never assert that cooking preserves
    // nutrients. Unknown food still appears in coverage, never silently omitted.
    inputs.add(
      RecipeFoodInput(
        ingredientId: '${recipe.id}:$i:${row.id}',
        food: binding?.food,
        amount: amount,
        amountForm: binding?.amountForm ?? FoodForm.raw,
        preparedForm: binding?.preparedForm ?? FoodForm.cooked,
        optional:
            row.optional ||
            binding?.notConsumed == true ||
            excludedLines.contains(i),
        selected: binding?.notConsumed == true || excludedLines.contains(i)
            ? false
            : !row.optional ||
                  (optionalLines?.contains(i) ?? optionalIds.contains(row.id)),
        preparation: binding?.preparation,
        asPurchased: binding?.asPurchased ?? false,
      ),
    );
  }
  return calculateRecipeNutrition(
    recipeId: recipe.id,
    recipeVersion: recipeNutritionVersion(recipe),
    inputs: inputs,
    portions: scaled.servings,
    cookedYieldGrams: cookedYieldGrams,
  );
}

/// Equal per-serving estimates are a display metric, never person allocation.
/// Actual person portions must be recorded explicitly in NutritionLedger.
MealBatch nutritionMealBatch(
  RecipeNutritionResult result, {
  required String batchId,
  required String sourceSnapshotId,
  Set<String> allergenIds = const {},
}) => MealBatch(
  id: batchId,
  recipeId: result.recipeId,
  sourceSnapshotId: sourceSnapshotId,
  cookedGrams: result.cookedYieldGrams,
  nutrients: {
    for (final e in result.whole.entries)
      e.key.name: PersonNutrientValue(
        knownSubtotal: e.value.knownSubtotal,
        complete: e.value.complete,
        unit: e.key.unit.name,
      ),
  },
  allergens: {
    for (final id in <String>{
      ...allergenIds.map(canonicalAllergenId),
      for (final input in result.snapshot)
        if (input.food != null && (!input.optional || input.selected))
          ...input.food!.allergens.map((v) => v.allergenId),
    })
      id: switch (recipeAllergenStatus(result.snapshot, id)) {
        AllergenStatus.contains => AllergenPresence.present,
        AllergenStatus.mayContain => AllergenPresence.mayContain,
        AllergenStatus.freeFrom => AllergenPresence.absent,
        AllergenStatus.unknown => AllergenPresence.unknown,
      },
  },
);

/// Stable content fingerprint, not a security signature or publication version.
String recipeNutritionVersion(CatalogRecipe recipe) {
  final source = jsonEncode([
    recipe.id,
    recipe.name,
    recipe.servings,
    [
      for (final step in recipe.steps)
        [step.number, step.text, step.minutes, step.tip],
    ],
    for (final i in recipe.ingredients)
      [i.id, i.name, i.amount, i.unit, i.scales, i.optional, i.label, i.note],
  ]);
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16),
      mask = (BigInt.one << 64) - BigInt.one;
  for (final byte in utf8.encode(source)) {
    hash = ((hash ^ BigInt.from(byte)) * prime) & mask;
  }
  return 'catalog-fnv1a64:${hash.toRadixString(16).padLeft(16, '0')}';
}
