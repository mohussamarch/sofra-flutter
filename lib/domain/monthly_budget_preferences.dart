/// Exact runtime identities supplied by the service's resolved candidates.
typedef MonthlyBudgetCandidateKey = ({
  String date,
  String slot,
  String candidateId,
});

/// Explicit user limits within the supplied proposal coverage. No defaults,
/// recipe-family/cuisine grouping or clinical criteria are inferred.
class MonthlyBudgetRecipePreferences {
  MonthlyBudgetRecipePreferences({
    Map<String, int> maxOccurrencesByRecipe = const {},
    this.minimumDistinctRecipes,
  }) : maxOccurrencesByRecipe = Map.unmodifiable(maxOccurrencesByRecipe) {
    if (this.maxOccurrencesByRecipe.entries.any(
          (entry) => entry.key.trim().isEmpty || entry.value < 0,
        ) ||
        (minimumDistinctRecipes != null && minimumDistinctRecipes! < 1)) {
      throw ArgumentError(
        'Recipe limits must be explicit nonnegative maxima or a positive minimum',
      );
    }
  }
  final Map<String, int> maxOccurrencesByRecipe;
  final int? minimumDistinctRecipes;
  bool get hasConstraints =>
      maxOccurrencesByRecipe.isNotEmpty || minimumDistinctRecipes != null;
}

enum MonthlyBudgetPreferenceViolationKind {
  maximumOccurrences,
  minimumDistinctRecipes,
}

class MonthlyBudgetPreferenceViolation {
  const MonthlyBudgetPreferenceViolation({
    required this.kind,
    required this.actual,
    required this.limit,
    this.recipeId,
  });
  final MonthlyBudgetPreferenceViolationKind kind;
  final String? recipeId;
  final int actual, limit;
}

/// Counts selected proposal slots, not servings or prior plans/history.
List<MonthlyBudgetPreferenceViolation> assessMonthlyRecipePreferences(
  MonthlyBudgetRecipePreferences preferences,
  Iterable<String> recipeIds,
) {
  final counts = <String, int>{};
  for (final id in recipeIds) {
    if (id.trim().isEmpty) throw ArgumentError('Missing exact recipe identity');
    counts[id] = (counts[id] ?? 0) + 1;
  }
  final violations = <MonthlyBudgetPreferenceViolation>[];
  final limitedIds = preferences.maxOccurrencesByRecipe.keys.toList()..sort();
  for (final id in limitedIds) {
    final actual = counts[id] ?? 0,
        limit = preferences.maxOccurrencesByRecipe[id]!;
    if (actual > limit) {
      violations.add(
        MonthlyBudgetPreferenceViolation(
          kind: MonthlyBudgetPreferenceViolationKind.maximumOccurrences,
          recipeId: id,
          actual: actual,
          limit: limit,
        ),
      );
    }
  }
  final minimum = preferences.minimumDistinctRecipes;
  if (minimum != null && counts.length < minimum) {
    violations.add(
      MonthlyBudgetPreferenceViolation(
        kind: MonthlyBudgetPreferenceViolationKind.minimumDistinctRecipes,
        actual: counts.length,
        limit: minimum,
      ),
    );
  }
  return List.unmodifiable(violations);
}
