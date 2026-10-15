import 'kitchen_core.dart';
import 'market_profile.dart';
import 'monthly_budget_choices.dart';

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
  });
  final MonthlyBudgetComparison comparison;
  final BigInt totalCombinations;
  final bool truncated;
  final MonthlyBudgetAssessment? bestKnownAffordable;
  final MonthlyBudgetSearchOutcome outcome;
  int get evaluatedCount => comparison.assessments.length;
  int get unknownCostCount => comparison.unranked.length;
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
/// A capped search or any unknown evaluated cost is indeterminate, even when a
/// known affordable option exists. Exhaustive outcomes concern only these exact
/// supplied pools and coverage; they imply no global menu/clinical conclusion.
MonthlyBudgetSearchResult searchMonthlyBudgetChoices({
  required BudgetPeriod period,
  required List<MoneyEntry> confirmedPurchases,
  required List<InventoryLot> stock,
  required List<MonthlyBudgetSlotPool> pools,
  required int maxEvaluations,
  required double? Function(MarketCountry country, IngredientUse use)
  estimateCost,
  List<UnitRule> rules = const [],
}) {
  final ownedPools = List<MonthlyBudgetSlotPool>.of(pools);
  final ownedStock = List<InventoryLot>.of(stock);
  final purchases = List<MoneyEntry>.of(confirmedPurchases);
  final ownedRules = List<UnitRule>.of(rules);
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
  final comparison = compareMonthlyBudgetChoices(
    period: period,
    confirmedPurchases: purchases,
    stock: ownedStock,
    options: _combinations(ownedPools).take(maxEvaluations).toList(),
    estimateCost: estimateCost,
    rules: ownedRules,
  );
  MonthlyBudgetAssessment? best;
  for (final assessment in comparison.ranked) {
    if (assessment.withinBudget == true) {
      best = assessment;
      break;
    }
  }
  final truncated = BigInt.from(comparison.assessments.length) < total;
  final outcome = truncated || comparison.unranked.isNotEmpty
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
