import '../l10n/l10n.dart';
import 'sofra_controller.dart';

class RecipeStockPreview {
  const RecipeStockPreview({
    required this.requiredLines,
    required this.available,
    required this.missing,
    required this.unknown,
    this.yieldKnown = true,
    int? present,
  }) : present = present ?? available;

  const RecipeStockPreview.unknownYield(this.available)
    : present = available,
      requiredLines = 0,
      missing = 0,
      unknown = 1,
      yieldKnown = false;

  factory RecipeStockPreview.fromCheck(CookingCheck check, {int? present}) {
    final required = check.lines
        .where((line) => line.status != LineStock.optional)
        .toList();
    return RecipeStockPreview(
      requiredLines: required.length,
      present: present,
      available: required
          .where((line) => line.status == LineStock.inStock || line.partial)
          .length,
      missing: required
          .where((line) => line.status == LineStock.missing)
          .length,
      unknown: required
          .where(
            (line) =>
                line.status == LineStock.unmeasured ||
                line.status == LineStock.unresolved,
          )
          .length,
    );
  }

  final int requiredLines, available, present, missing, unknown;
  final bool yieldKnown;
  bool get ready =>
      yieldKnown && requiredLines > 0 && missing == 0 && unknown == 0;
  int get rank => ready
      ? 0
      : missing > 0 && unknown == 0
      ? 1
      : 2;
  String get label {
    final t = L10n.current;
    if (!yieldKnown) return t.kitPreviewNoYield;
    if (ready) return t.kitPreviewReady;
    if (requiredLines == 0) return t.kitPreviewNotEnough;
    if (unknown > 0) {
      return missing > 0
          ? t.kitPreviewMissingUnknown(missing, unknown)
          : t.kitPreviewUnknown(unknown);
    }
    return t.kitPreviewMissing(missing);
  }
}

extension StockRecipeDiscovery on SofraController {
  int get stockDiscoveryVersion => Object.hash(
    profile.servings,
    Object.hashAll(
      kitchen.inventory.map(
        (lot) => Object.hash(
          lot.id,
          lot.ingredientId,
          lot.quantity,
          lot.unit,
          lot.zone,
        ),
      ),
    ),
    Object.hashAll(
      kitchen.unitRules.map(
        (rule) =>
            Object.hash(rule.ingredientId, rule.from, rule.to, rule.factor),
      ),
    ),
    Object.hashAll(
      kitchen.recipeBook.active.entries.map(
        (entry) => Object.hash(entry.key, entry.value),
      ),
    ),
  );

  Future<Map<String, RecipeStockPreview>> stockRecipePreviews() async {
    final sources = await recipes.loadAll();
    final planning = await Future.wait(
      sources.map((source) => planningRecipe(source.id)),
    );
    final inventory = stock;
    final previews = <String, RecipeStockPreview>{};
    for (var index = 0; index < sources.length; index++) {
      final recipe = planning[index];
      final present = recipe.ingredients
          .where(
            (ingredient) =>
                !ingredient.optional &&
                inventory.any(
                  (lot) =>
                      (lot.quantity == null || lot.quantity! > 0) &&
                      stockOptions(ingredient.id).contains(lot.ingredientId),
                ),
          )
          .length;
      previews[sources[index].id] = recipe.servings != null
          ? RecipeStockPreview.fromCheck(
              checkStock(recipe.forServings(profile.servings)),
              present: present,
            )
          : RecipeStockPreview.unknownYield(present);
    }
    return previews;
  }
}
