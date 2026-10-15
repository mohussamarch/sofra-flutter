import 'kitchen_core.dart';
import 'market_profile.dart';
import 'purchase_forecast.dart';

/// One caller-selected meal with already scaled, explicitly included needs.
/// Unresolved lines must be supplied; an empty list is an explicit empty need,
/// never evidence that an unreviewed recipe has no cost.
class MonthlyBudgetMeal {
  MonthlyBudgetMeal({
    required this.date,
    required this.slot,
    required this.candidateId,
    required List<IngredientUse> requirements,
    Set<String> unresolvedRequirements = const {},
  }) : requirements = List.unmodifiable(requirements),
       unresolvedRequirements = Set.unmodifiable(unresolvedRequirements);
  final String date, slot, candidateId;
  final List<IngredientUse> requirements;
  final Set<String> unresolvedRequirements;
}

class MonthlyBudgetOption {
  MonthlyBudgetOption({
    required this.id,
    required List<MonthlyBudgetMeal> meals,
  }) : meals = List.unmodifiable(meals);
  final String id;
  final List<MonthlyBudgetMeal> meals;
}

/// Only the supplied date/slot coverage, with no assumed daily meal pattern.
class MonthlyBudgetCoverage {
  const MonthlyBudgetCoverage(this.date, this.slot);
  final String date, slot;
}

class MonthlyBudgetAssessment {
  const MonthlyBudgetAssessment._(
    this.option,
    this.forecast,
    this.remainingAfterPurchases,
    this.overrun,
    this.withinBudget,
  );
  final MonthlyBudgetOption option;
  final PurchaseForecast forecast;
  final double? remainingAfterPurchases, overrun;
  final bool? withinBudget;
}

class MonthlyBudgetComparison {
  MonthlyBudgetComparison._({
    required this.period,
    required this.spent,
    required List<MonthlyBudgetCoverage> coverage,
    required List<MonthlyBudgetAssessment> assessments,
    required List<MonthlyBudgetAssessment> ranked,
    required List<MonthlyBudgetAssessment> unranked,
  }) : coverage = List.unmodifiable(coverage),
       assessments = List.unmodifiable(assessments),
       ranked = List.unmodifiable(ranked),
       unranked = List.unmodifiable(unranked);
  final BudgetPeriod period;
  final double spent;
  double get remainingBeforePurchases => period.limit - spent;
  final List<MonthlyBudgetCoverage> coverage;
  final List<MonthlyBudgetAssessment> assessments, ranked, unranked;
}

/// Compares explicit alternatives for one calendar month without saving a plan.
/// Each option uses the same inventory snapshot independently, allocating stock
/// only once across all its meals. Only new purchases affect affordability.
///
/// [estimateCost] must be pure, use the supplied country and honor user prices
/// before averages, as KitchenService's existing pricing does. No prices, food
/// identities, serving quantities, optional choices or unit rules are inferred.
/// Confirmed purchase records are read at their frozen amounts through the
/// existing BudgetSummary rules; no new purchase flag or ledger entry is made.
///
/// [MonthlyBudgetComparison.ranked] contains only complete purchase forecasts,
/// ordered by new purchase cost then option ID. Incomplete options are unranked
/// and have nullable affordability. Identical explicit coverage can still be a
/// partial month. Ranking is financial, with no nutritional/clinical judgment.
MonthlyBudgetComparison compareMonthlyBudgetChoices({
  required BudgetPeriod period,
  required List<MoneyEntry> confirmedPurchases,
  required List<InventoryLot> stock,
  required List<MonthlyBudgetOption> options,
  required double? Function(MarketCountry country, IngredientUse use)
  estimateCost,
  List<UnitRule> rules = const [],
}) {
  final start = parseDay(period.start), end = parseDay(period.end);
  if (start.day != 1 || end != DateTime(start.year, start.month + 1)) {
    throw ArgumentError('Budget must span exactly one calendar month');
  }
  final ownedOptions = List<MonthlyBudgetOption>.of(options);
  final ownedStock = List<InventoryLot>.of(stock);
  final ownedRules = List<UnitRule>.of(rules);
  final purchases = List<MoneyEntry>.of(confirmedPurchases);
  if (ownedOptions.isEmpty ||
      ownedOptions.any((option) => option.id.trim().isEmpty) ||
      ownedOptions.map((option) => option.id).toSet().length !=
          ownedOptions.length) {
    throw ArgumentError('Explicit unique budget options are required');
  }
  Set<(String, String)>? expectedCoverage;
  for (final option in ownedOptions) {
    final coverage = <(String, String)>{};
    for (final meal in option.meals) {
      final day = parseDay(meal.date);
      if (!period.includes(day) ||
          meal.slot.trim().isEmpty ||
          meal.candidateId.trim().isEmpty ||
          !coverage.add((meal.date, meal.slot))) {
        throw ArgumentError('Invalid, duplicate or out-of-period meal slot');
      }
    }
    if (coverage.isEmpty ||
        (expectedCoverage != null &&
            (coverage.length != expectedCoverage.length ||
                !coverage.containsAll(expectedCoverage)))) {
      throw ArgumentError('Options must cover the same explicit meal slots');
    }
    expectedCoverage ??= coverage;
  }
  final spent = BudgetSummary(period, purchases, plannedPurchases: 0).spent;
  requireAmount(spent, zero: true);
  final assessments = <MonthlyBudgetAssessment>[];
  for (final option in ownedOptions) {
    final forecast = forecastPurchases(
      [for (final meal in option.meals) ...meal.requirements],
      ownedStock,
      estimateCost: (use) => estimateCost(period.country, use),
      rules: ownedRules,
      unresolvedRequirements: {
        for (final meal in option.meals) ...meal.unresolvedRequirements,
      },
    );
    final total = forecast.purchaseTotal;
    double? remaining, overrun;
    bool? withinBudget;
    if (total != null) {
      final proposedSpent = spent + total;
      requireAmount(proposedSpent, zero: true);
      remaining = period.limit - proposedSpent;
      overrun = remaining < 0 ? -remaining : 0;
      withinBudget = remaining >= 0;
    }
    assessments.add(
      MonthlyBudgetAssessment._(
        option,
        forecast,
        remaining,
        overrun,
        withinBudget,
      ),
    );
  }
  final ranked = assessments.where((row) => row.forecast.complete).toList()
    ..sort((a, b) {
      final costOrder = a.forecast.purchaseTotal!.compareTo(
        b.forecast.purchaseTotal!,
      );
      return costOrder != 0 ? costOrder : a.option.id.compareTo(b.option.id);
    });
  final coverage = expectedCoverage!.toList()
    ..sort((a, b) {
      final dateOrder = a.$1.compareTo(b.$1);
      return dateOrder != 0 ? dateOrder : a.$2.compareTo(b.$2);
    });
  return MonthlyBudgetComparison._(
    period: period,
    spent: spent,
    coverage: [
      for (final slot in coverage) MonthlyBudgetCoverage(slot.$1, slot.$2),
    ],
    assessments: assessments,
    ranked: ranked,
    unranked: assessments.where((row) => !row.forecast.complete).toList(),
  );
}
