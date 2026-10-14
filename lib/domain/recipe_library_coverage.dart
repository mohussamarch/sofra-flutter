import '../data/recipe_library_repository.dart';
import 'recipe_library_draft.dart';

/// Source-only triage. A stated quantity is never an accepted food binding.
class RecipeLibraryLineCoverage {
  RecipeLibraryLineCoverage._(this.lineIndex, RecipeLibraryIngredient source)
    : labelAr = source.labelAr,
      sourceQuantityText = source.sourceQuantityText,
      amount = source.amount,
      unit = source.unit,
      optional = source.optional,
      included = source.included,
      supplemental = source.supplemental;
  final int lineIndex;
  final String labelAr;
  final String? sourceQuantityText, unit;
  final double? amount;
  final bool optional, supplemental;
  final bool? included;
  bool get missingAmount => amount == null;
  bool get missingUnit => unit == null;
  bool get nonPositiveAmount => amount != null && amount! <= 0;
  // Only exact raw g/kg units are recognised here. Other source units still
  // need explicit review; this report never supplies a gram conversion.
  bool get unitNeedsReview => unit != null && unit != 'g' && unit != 'kg';
  bool get needsQuantityReview =>
      missingAmount || missingUnit || nonPositiveAmount || unitNeedsReview;
  bool get requiresExplicitFoodReview => true;
  Map<String, dynamic> toJson() => {
    'lineIndex': lineIndex,
    'labelAr': labelAr,
    'sourceQuantityText': sourceQuantityText,
    'amount': amount,
    'unit': unit,
    'optional': optional,
    'included': included,
    'supplemental': supplemental,
    'missingAmount': missingAmount,
    'missingUnit': missingUnit,
    'nonPositiveAmount': nonPositiveAmount,
    'unitNeedsReview': unitNeedsReview,
    'needsQuantityReview': needsQuantityReview,
    'requiresExplicitFoodReview': true,
  };
}

class RecipeLibraryRecipeCoverage {
  RecipeLibraryRecipeCoverage._(RecipeLibraryEntry entry)
    : recipeId = entry.id,
      titleAr = entry.titleAr,
      sourceFingerprint = recipeLibrarySourceFingerprint(entry),
      lines = List.unmodifiable(
        List.generate(
          entry.ingredients.length,
          (i) => RecipeLibraryLineCoverage._(i, entry.ingredients[i]),
        ),
      );
  final String recipeId, titleAr, sourceFingerprint;
  final List<RecipeLibraryLineCoverage> lines;
  bool get hasQuantityGaps => lines.any((line) => line.needsQuantityReview);
  Map<String, dynamic> toJson() => {
    'recipeId': recipeId,
    'titleAr': titleAr,
    'sourceFingerprint': sourceFingerprint,
    'hasQuantityGaps': hasQuantityGaps,
    'lines': lines.map((l) => l.toJson()).toList(),
    'runtimeApproved': false,
  };
}

/// Immutable audit of already pinned entries, not a recipe, nutritional or
/// rights approval. It does not inspect or change saved personal draft reviews.
class RecipeLibraryCoverageReport {
  RecipeLibraryCoverageReport._(List<RecipeLibraryRecipeCoverage> rows)
    : recipes = List.unmodifiable(rows);
  factory RecipeLibraryCoverageReport.fromEntries(
    Iterable<RecipeLibraryEntry> entries,
  ) {
    final ids = <String>{}, rows = <RecipeLibraryRecipeCoverage>[];
    for (final entry in entries) {
      if (!ids.add(entry.id)) {
        throw ArgumentError('Duplicate library recipe: ${entry.id}');
      }
      rows.add(RecipeLibraryRecipeCoverage._(entry));
    }
    return RecipeLibraryCoverageReport._(rows);
  }
  final List<RecipeLibraryRecipeCoverage> recipes;
  Iterable<RecipeLibraryLineCoverage> get _lines =>
      recipes.expand((r) => r.lines);
  int get recipeCount => recipes.length;
  int get ingredientCount => _lines.length;

  /// Counts each source line once, even if several quantity gaps overlap.
  int get quantityReviewLineCount =>
      _lines.where((line) => line.needsQuantityReview).length;
  int get missingAmountCount => _lines.where((l) => l.missingAmount).length;
  int get missingUnitCount => _lines.where((l) => l.missingUnit).length;
  int get nonPositiveAmountCount =>
      _lines.where((l) => l.nonPositiveAmount).length;
  int get unitNeedsReviewCount => _lines.where((l) => l.unitNeedsReview).length;
  int get supplementalCount => _lines.where((l) => l.supplemental).length;
  int get optionalCount => _lines.where((l) => l.optional).length;
  int get recipesWithQuantityGaps =>
      recipes.where((r) => r.hasQuantityGaps).length;
  int get runtimeApprovedRecipes => 0;
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'scope': 'source-library-review-triage',
    'recipeCount': recipeCount,
    'ingredientCount': ingredientCount,
    'quantityReviewLineCount': quantityReviewLineCount,
    'missingAmountCount': missingAmountCount,
    'missingUnitCount': missingUnitCount,
    'nonPositiveAmountCount': nonPositiveAmountCount,
    'unitNeedsReviewCount': unitNeedsReviewCount,
    'supplementalCount': supplementalCount,
    'optionalCount': optionalCount,
    'recipesWithQuantityGaps': recipesWithQuantityGaps,
    'runtimeApprovedRecipes': 0,
    'recipes': recipes.map((r) => r.toJson()).toList(),
  };
}
