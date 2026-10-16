import 'kitchen_core.dart';
import 'market_profile.dart';
import 'monthly_budget_choices.dart';
import 'monthly_budget_coverage.dart';
import 'monthly_budget_preferences.dart';

/// Explicit reviewed alternatives for one date/slot. Candidate order defines
/// search order; the same recipe may appear in different slot pools.
class MonthlyBudgetSlotPool {
  MonthlyBudgetSlotPool({
    required this.date,
    required this.slot,
    required List<MonthlyBudgetMeal> candidates,
  }) : candidates = List.unmodifiable(candidates);
  final String date, slot;
  final List<MonthlyBudgetMeal> candidates;
}

enum MonthlyBudgetSearchOutcome {
  indeterminate,
  affordableFound,
  noAffordableInSuppliedPools,
}

class MonthlyBudgetSearchResult {
  MonthlyBudgetSearchResult._({
    required this.comparison,
    required this.totalCombinations,
    required this.truncated,
    required this.bestKnownAffordable,
    required this.outcome,
    required this.recipePreferences,
    required this.requiredCoverage,
    required Map<MonthlyBudgetCandidateKey, String> candidateRecipeIds,
    required Map<String, List<MonthlyBudgetPreferenceViolation>>
    preferenceViolationsByOption,
    required List<MonthlyBudgetAssessment> eligibleRanked,
  }) : candidateRecipeIds = Map.unmodifiable(candidateRecipeIds),
       preferenceViolationsByOption = Map.unmodifiable({
         for (final entry in preferenceViolationsByOption.entries)
           entry.key: List<MonthlyBudgetPreferenceViolation>.unmodifiable(
             entry.value,
           ),
       }),
       eligibleRanked = List.unmodifiable(eligibleRanked);

  /// Financial evidence for every evaluated option, including rejected options.
  final MonthlyBudgetComparison comparison;
  final BigInt totalCombinations;
  final bool truncated;
  final MonthlyBudgetAssessment? bestKnownAffordable;
  final MonthlyBudgetSearchOutcome outcome;
  final MonthlyBudgetRecipePreferences? recipePreferences;

  /// Null preserves caller-defined partial-coverage behavior.
  final MonthlyBudgetSlotCoverageAssessment? requiredCoverage;
  final Map<MonthlyBudgetCandidateKey, String> candidateRecipeIds;
  final Map<String, List<MonthlyBudgetPreferenceViolation>>
  preferenceViolationsByOption;

  /// Complete-price options passing all explicit preferences, by purchase cost.
  final List<MonthlyBudgetAssessment> eligibleRanked;
  int get evaluatedCount => comparison.assessments.length;
  int get unknownCostCount => comparison.unranked.length;

  /// Includes preference-passing options whose price remains unknown.
  int get eligibleCount => preferenceViolationsByOption.values
      .where((reasons) => reasons.isEmpty)
      .length;
}

/// Evaluates at most [maxEvaluations] whole combinations in caller pool order,
/// with the last pool varying fastest. No partial-cost pruning is valid for an
/// arbitrary nonnegative pricing callback, so none is performed.
///
/// All pools/candidates are structurally checked before any callback. This does
/// not certify supplied source/quantity/food review. The pure callback must use
/// the supplied country and user prices before averages. All input collections
/// are owned before callbacks; no stock, ledger, intake or plans are written.
///
/// Explicit recipe preferences apply only to supplied proposal slots. All raw
/// combinations still consume the cap and retain financial comparison evidence;
/// eligibleRanked/bestKnownAffordable apply the user limits without relaxation.
/// Exact identities are mandatory for every candidate when constraints are active.
/// No identity aliases, recipe-family/cuisine or medical grouping is inferred.
///
/// A capped search or any unknown evaluated cost is indeterminate, even when a
/// known affordable option exists. Exhaustive outcomes concern only these exact
/// supplied pools and coverage; they imply no global menu/clinical conclusion.
/// Explicit required slots may be supplied to gate affordability on coverage.
/// Additional supplied slots remain included in every evaluated option.
MonthlyBudgetSearchResult searchMonthlyBudgetChoices({
  required BudgetPeriod period,
  required List<MoneyEntry> confirmedPurchases,
  required List<InventoryLot> stock,
  required List<MonthlyBudgetSlotPool> pools,
  required int maxEvaluations,
  required double? Function(MarketCountry country, IngredientUse use)
  estimateCost,
  List<UnitRule> rules = const [],
  List<MonthlyBudgetCoverage>? requiredSlots,
  MonthlyBudgetRecipePreferences? recipePreferences,
  Map<MonthlyBudgetCandidateKey, String> candidateRecipeIds = const {},
}) {
  final preferences = recipePreferences == null
      ? null
      : MonthlyBudgetRecipePreferences(
          maxOccurrencesByRecipe: recipePreferences.maxOccurrencesByRecipe,
          minimumDistinctRecipes: recipePreferences.minimumDistinctRecipes,
        );
  final identities = Map<MonthlyBudgetCandidateKey, String>.of(
    candidateRecipeIds,
  );
  final ownedPools = List<MonthlyBudgetSlotPool>.of(pools);
  final ownedStock = List<InventoryLot>.of(stock);
  final purchases = List<MoneyEntry>.of(confirmedPurchases);
  final ownedRules = List<UnitRule>.of(rules);
  final ownedRequiredSlots = requiredSlots == null
      ? null
      : List<MonthlyBudgetCoverage>.of(requiredSlots);
  final start = parseDay(period.start), end = parseDay(period.end);
  if (start.day != 1 || end != DateTime(start.year, start.month + 1)) {
    throw ArgumentError('Budget must span exactly one calendar month');
  }
  if (maxEvaluations < 1 || ownedPools.isEmpty) {
    throw ArgumentError(
      'Positive evaluation limit and explicit pools required',
    );
  }
  for (final rule in ownedRules) {
    requireAmount(rule.factor);
    if (rule.ingredientId.trim().isEmpty ||
        rule.from.isEmpty ||
        rule.to.isEmpty) {
      throw ArgumentError('Missing explicit unit rule identity or units');
    }
  }
  var total = BigInt.one;
  final coverage = <(String, String)>{};
  final expectedIdentities = <MonthlyBudgetCandidateKey>{};
  for (final pool in ownedPools) {
    if (!period.includes(parseDay(pool.date)) ||
        pool.slot.trim().isEmpty ||
        !coverage.add((pool.date, pool.slot)) ||
        pool.candidates.isEmpty) {
      throw ArgumentError('Explicit unique in-period pools must be nonempty');
    }
    final ids = <String>{};
    for (final candidate in pool.candidates) {
      if (candidate.date != pool.date ||
          candidate.slot != pool.slot ||
          candidate.candidateId.trim().isEmpty ||
          !ids.add(candidate.candidateId)) {
        throw ArgumentError('Candidate identity or date/slot mismatch');
      }
      expectedIdentities.add((
        date: candidate.date,
        slot: candidate.slot,
        candidateId: candidate.candidateId,
      ));
      for (final use in candidate.requirements) {
        requireAmount(use.quantity);
        if (use.ingredientId.trim().isEmpty || use.unit.isEmpty) {
          throw ArgumentError('Missing candidate requirement identity or unit');
        }
      }
      if (candidate.unresolvedRequirements.any((id) => id.trim().isEmpty)) {
        throw ArgumentError(
          'Missing unresolved candidate requirement identity',
        );
      }
    }
    total *= BigInt.from(pool.candidates.length);
  }
  if ((preferences?.hasConstraints ?? false) || identities.isNotEmpty) {
    if (identities.length != expectedIdentities.length ||
        !expectedIdentities.every(identities.containsKey) ||
        identities.values.any((id) => id.trim().isEmpty)) {
      throw ArgumentError(
        'Exact recipe identities required for every supplied candidate',
      );
    }
  }
  final requiredCoverage = ownedRequiredSlots == null
      ? null
      : assessMonthlyBudgetSlotCoverage(
          period: period,
          requiredSlots: ownedRequiredSlots,
          suppliedSlots: [
            for (final pool in ownedPools)
              MonthlyBudgetCoverage(pool.date, pool.slot),
          ],
        );
  final comparison = compareMonthlyBudgetChoices(
    period: period,
    confirmedPurchases: purchases,
    stock: ownedStock,
    options: _combinations(ownedPools).take(maxEvaluations).toList(),
    estimateCost: estimateCost,
    rules: ownedRules,
  );
  final violations = <String, List<MonthlyBudgetPreferenceViolation>>{
    for (final row in comparison.assessments)
      row.option.id: preferences?.hasConstraints == true
          ? assessMonthlyRecipePreferences(preferences!, [
              for (final meal in row.option.meals)
                identities[(
                  date: meal.date,
                  slot: meal.slot,
                  candidateId: meal.candidateId,
                )]!,
            ])
          : const [],
  };
  final eligible = comparison.ranked
      .where((row) => violations[row.option.id]!.isEmpty)
      .toList();
  MonthlyBudgetAssessment? best;
  if (requiredCoverage == null || requiredCoverage.coversRequired) {
    for (final assessment in eligible) {
      if (assessment.withinBudget == true) {
        best = assessment;
        break;
      }
    }
  }
  final truncated = BigInt.from(comparison.assessments.length) < total;
  final outcome =
      truncated ||
          comparison.unranked.isNotEmpty ||
          (requiredCoverage != null && !requiredCoverage.coversRequired)
      ? MonthlyBudgetSearchOutcome.indeterminate
      : best != null
      ? MonthlyBudgetSearchOutcome.affordableFound
      : MonthlyBudgetSearchOutcome.noAffordableInSuppliedPools;
  return MonthlyBudgetSearchResult._(
    comparison: comparison,
    totalCombinations: total,
    truncated: truncated,
    bestKnownAffordable: best,
    outcome: outcome,
    recipePreferences: preferences,
    requiredCoverage: requiredCoverage,
    candidateRecipeIds: identities,
    preferenceViolationsByOption: violations,
    eligibleRanked: eligible,
  );
}

Iterable<MonthlyBudgetOption> _combinations(
  List<MonthlyBudgetSlotPool> pools,
) sync* {
  final indices = List<int>.filled(pools.length, 0);
  while (true) {
    yield MonthlyBudgetOption(
      // Index vectors are opaque stable IDs; comparator ties use lexical IDs,
      // not a claim that lexical and numeric index ordering are equivalent.
      id: 'choice:${indices.join(",")}',
      meals: [
        for (var i = 0; i < pools.length; i++) pools[i].candidates[indices[i]],
      ],
    );
    var cursor = indices.length - 1;
    while (cursor >= 0) {
      indices[cursor]++;
      if (indices[cursor] < pools[cursor].candidates.length) break;
      indices[cursor] = 0;
      cursor--;
    }
    if (cursor < 0) return;
  }
}
