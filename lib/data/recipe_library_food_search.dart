import 'dart:convert';

import '../domain/recipe_library_draft.dart';
import '../domain/food_nutrition.dart';
import 'food_repository.dart';
import 'recipe_library_repository.dart';

List<Map<String, dynamic>> _copyCandidates(List<Map<String, dynamic>> rows) =>
    (jsonDecode(jsonEncode(rows)) as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();

Object? _orderedSource(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: _orderedSource(value[key])};
  }
  if (value is List) return value.map(_orderedSource).toList();
  return value;
}

/// Food-bank search evidence for one pinned source line, never a food binding.
class RecipeLibraryFoodSearchResult {
  RecipeLibraryFoodSearchResult._({
    required this.recipeId,
    required this.sourceFingerprint,
    required this.lineIndex,
    required this.ingredient,
    required this.query,
    required this.market,
    required this.packagedOnly,
    required this.limit,
    required List<Map<String, dynamic>> candidates,
  }) : _candidates = _copyCandidates(candidates);

  final String recipeId, sourceFingerprint, query;
  final int lineIndex, limit;
  final RecipeLibraryIngredient ingredient;
  final String? market;
  final bool packagedOnly;
  final List<Map<String, dynamic>> _candidates;

  /// Each read is an owned deep copy; the list itself cannot be changed.
  List<Map<String, dynamic>> get candidates =>
      List.unmodifiable(_copyCandidates(_candidates));
  bool get requiresExplicitReview => true;

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'scope': 'library-ingredient-food-search',
    'recipeId': recipeId,
    'sourceFingerprint': sourceFingerprint,
    'lineIndex': lineIndex,
    'ingredient': ingredient.toJson(),
    'query': query,
    'market': market,
    'packagedOnly': packagedOnly,
    'limit': limit,
    'candidates': _copyCandidates(_candidates),
    'requiresExplicitReview': true,
    'runtimeApproved': false,
  };
}

/// Connects library triage to the existing licensed food-bank search.
/// Query is explicit: names, translations and first matches are not identities.
class RecipeLibraryFoodSearch {
  RecipeLibraryFoodSearch({required this.foods});
  final FoodRepository foods;

  /// Explicitly selected generic food, not a recipe binding or quantity choice.
  /// The caller supplies the current entry; later draft save checks the library.
  Future<FoodRecord> resolveUsdaCandidate({
    required RecipeLibraryFoodSearchResult result,
    required RecipeLibraryEntry currentEntry,
    required String foodId,
    required String form,
    required bool acknowledgeFoodIdentity,
  }) async {
    if (!acknowledgeFoodIdentity ||
        !{'raw', 'cooked', 'asSold', 'prepared'}.contains(form)) {
      throw ArgumentError('Explicit food identity and form review required');
    }
    if (result.recipeId != currentEntry.id ||
        result.sourceFingerprint !=
            recipeLibrarySourceFingerprint(currentEntry)) {
      throw StateError('Library source changed; search and review again');
    }
    final matches = result._candidates
        .where((row) => row['id'] == foodId && !row.containsKey('barcode'))
        .toList();
    if (matches.length != 1 || !foodId.startsWith('usda:')) {
      throw ArgumentError('Select one USDA identity from this search result');
    }
    final chosen = matches.single;
    if (chosen['version'] is! String ||
        (chosen['version'] as String).trim().isEmpty ||
        chosen['name'] is! String ||
        (chosen['name'] as String).trim().isEmpty) {
      throw StateError('Food search lacks source identity/version evidence');
    }
    final raw = await foods.usdaRaw(foodId);
    if (raw['version'] != chosen['version'] || raw['name'] != chosen['name']) {
      throw StateError('Food source changed; search and review again');
    }
    return foods.usdaFood(foodId, form: form);
  }

  /// Explicit package choice keeps the source snapshot and label basis separate.
  Future<FoodRecord> resolvePackagedCandidate({
    required RecipeLibraryFoodSearchResult result,
    required RecipeLibraryEntry currentEntry,
    required String barcode,
    required String market,
    required bool acknowledgeProductIdentity,
    NutritionBasis? reviewedBasis,
    FoodSource? reviewSource,
  }) async {
    if (!acknowledgeProductIdentity ||
        barcode.trim().isEmpty ||
        !{'EG', 'SA'}.contains(market) ||
        (result.market != null && result.market != market)) {
      throw ArgumentError(
        'Explicit product identity and search market required',
      );
    }
    if (result.recipeId != currentEntry.id ||
        result.sourceFingerprint !=
            recipeLibrarySourceFingerprint(currentEntry)) {
      throw StateError('Library source changed; search and review again');
    }
    final matches = result._candidates
        .where((row) => row['barcode'] == barcode)
        .toList();
    if (matches.length != 1) {
      throw ArgumentError('Select one package from this search result');
    }
    if ((reviewedBasis == null) != (reviewSource == null) ||
        (reviewedBasis != null &&
            (reviewSource!.recordId != barcode ||
                reviewedBasis.amount != 100 ||
                !{
                  FoodQuantityUnit.g,
                  FoodQuantityUnit.ml,
                }.contains(reviewedBasis.unit)))) {
      throw ArgumentError(
        'Label basis requires evidence for this exact barcode',
      );
    }
    final raw = await foods.productRaw(barcode);
    if (jsonEncode(_orderedSource(raw)) !=
        jsonEncode(_orderedSource(matches.single))) {
      throw StateError(
        'Product source changed; reload sources and review again',
      );
    }
    return foods.packagedFood(
      barcode,
      market: market,
      reviewedBasis: reviewedBasis,
      reviewSource: reviewSource,
    );
  }

  Future<RecipeLibraryFoodSearchResult> search({
    required RecipeLibraryEntry entry,
    required String expectedSourceFingerprint,
    required int lineIndex,
    required String query,
    String? market,
    bool packagedOnly = false,
    int limit = 40,
  }) async {
    final pin = recipeLibrarySourceFingerprint(entry);
    if (pin != expectedSourceFingerprint) {
      throw StateError('Library source changed; review the source again');
    }
    if (lineIndex < 0 || lineIndex >= entry.ingredients.length) {
      throw ArgumentError('Unknown library ingredient line');
    }
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Explicit non-empty food search query required');
    }
    // FoodRepository validates limit/market before reading either source bank.
    final rows = await foods.search(
      query: trimmed,
      market: market,
      packagedOnly: packagedOnly,
      limit: limit,
    );
    return RecipeLibraryFoodSearchResult._(
      recipeId: entry.id,
      sourceFingerprint: pin,
      lineIndex: lineIndex,
      ingredient: entry.ingredients[lineIndex],
      query: trimmed,
      market: market,
      packagedOnly: packagedOnly,
      limit: limit,
      candidates: rows,
    );
  }
}
