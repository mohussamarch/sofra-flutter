# Monthly budget alternatives — explicit read-only comparison

`compareMonthlyBudgetChoices` in `lib/domain/monthly_budget_choices.dart` compares explicit caller-supplied alternatives for one exact calendar-month BudgetPeriod (next-month end exclusive). Each option contains dated slots, candidate IDs and already reviewed/scaled included IngredientUse needs plus unresolved IDs. All options must cover the same nonempty unique date/slot set. Returned sorted coverage describes only supplied slots; it does not establish all meals/days of a month.

```dart
final comparison = compareMonthlyBudgetChoices(
  period: selectedMonthlyPeriod,
  confirmedPurchases: frozenPurchases,
  stock: currentStock,
  options: reviewedMonthOptions,
  estimateCost: reviewedCountryCost,
  rules: acceptedUnitRules,
);
```

The callback is pure, receives the period country and must use existing user-price-before-average rules. No network, current price, package rounding, food match, quantity/serving conversion, optional inclusion or clinical/nutritional suitability is inferred. The comparator cannot certify caller recipe completeness or price provenance.

Every whole alternative independently calls existing forecastPurchases against the same stock snapshot; stock is used once across that option, and remains available when evaluating another option. New purchase cost and consumed-stock value stay separate. Spent uses BudgetSummary over matching country and end-exclusive period frozen MoneyEntry amounts; no previous-month carryover.

Complete purchase totals rank ascending with option-ID tie break, even if consumed stock value is unknown. Incomplete totals stay unranked with null withinBudget, remainingAfterPurchases and overrun; reason sets and known subtotals remain visible. Zero is a known zero, not missing. Finite arithmetic, exact month, IDs and coverage validate; collections are owned and immutable.

This API creates no stock change/reservation, purchase flag, ledger entry, intake, plan selection/edit, save or carryover. It is a prerequisite for the monthly generator, not automatic menu creation. A later KitchenService adapter must assemble current reviewed candidate requirements and user-first prices, and guard stale snapshots before any acceptance. Diversity/preferences/person-target constraints, reviewed merchant feeds and user-approved saving remain separate.

Verification:11 new meaningful tests plus11 existing forecast tests passed22; full269Flutter/62relatedNode/dart analyze clean after integration. Independent read-only review found no concrete defect under this contract; no tests or edits by reviewer.
