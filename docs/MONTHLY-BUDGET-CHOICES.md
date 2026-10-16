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


## Current §86

88 readable source records=62localarchive+23creatorwebsite+3indexedYTdescriptions;17packs/62snapshots,51local source labels. Planning54/4 and reviewed naanmethodfamily1 unchanged. KitchenService snapshot-safe monthly advisory adapter implemented;282fullFlutter/36relatedNode/analyze clean. HANDOFF§86. `KitchenService.previewMonthlyBudgetChoices(savedBudgetId, options:, rules:, optionalLinesByOption:, measuredByOption:)` resolves explicit unsaved PlannedMeal candidates using current/pinned revisions and existing serving/optional/measured review semantics. Owns nested inputs before await; same-country saved budget, current stock/frozen ledger/private user-first prices; full snapshot/current write-tail guard rejects intervening price/budget/stock/revision changes. Shared _purchasePreviewMeal preserves previous purchase-preview behavior. Returned candidateId is exact resolved revision.key. Read-only, no save/plan/stock/ledger/intake changes. Request a new preview after subsequent data changes; no stale acceptance API. Full automatic month generator/person targets/clinical suitability remain separate; next bounded explicit-candidate combination search.


## Current §87

90 readable source records=64localarchive+23creatorwebsite+3indexedYTdescriptions;18packs/64snapshots,53local source category labels. Planning54/4 and naanmethodfamily1 unchanged. Bounded explicit-candidate monthly search implemented;292fullFlutter/30relatedNode/analyze clean. HANDOFF§87. `searchMonthlyBudgetChoices` (lib/domain/monthly_budget_search.dart) consumes explicit reviewed MonthlyBudgetSlotPool candidates, month/frozen purchases/stock/rules and pure country/user-first pricing. Validates ALL candidates before callbacks, including unexamined; owns collections. Lazy deterministic odometer evaluates at most maxEvaluations whole combinations via unchanged comparator, exact BigInt total. Returns evaluated/truncated/unknown and bestKnownAffordable; capped OR unknown costs yield indeterminate. Exhaustive known negative is only noAffordableInSuppliedPools, not global infeasibility or clinical fitness. No partial-cost pruning, source approval, writes or automatic plan selection. KitchenService only compares caller-built whole options so far; a later search adapter must retain revision/line/snapshot guards.


## Current §88

1090 readable source records=1064offlinearchive+23creatorwebsite+3indexedYTdescriptions;19packs/1064snapshots,71local source-category labels. Planning54/4 and reviewed naanmethodfamily1 unchanged. Native1000-record batch and snapshot-safe monthly candidate search service implemented;306fullFlutter/31relatedNode/analyze clean. HANDOFF§88. `KitchenService.searchMonthlyBudgetChoices(budgetId,pools:,maxEvaluations:,rules:,optionalLinesByPool:,measuredByPool:)` returns MonthlyBudgetSearchPreview(search,candidatesByPool). Explicit pool IDs scope decisions; each pool one unique date/slot, callermeal.id is candidate identity so same recipe/differentservings remains valid. Resolve ALL candidates/current or requested revisions before bounded cost evaluation. Return deeply immutable exact-pinned PlannedMeal evidence perpool/candidate. Own inputs preawait, samecountry savedbudget/privateuser-firstcost/frozenledger/currentstock/fullsnapshot+write-tail guard. Shared requirement helper defaults revision.key for prior APIs. Pure domain cap/BigInt/unknown/indeterminate contract unchanged; no write/autosave/clinical/globalmonthly guarantee.


## Current §89

2090 readable source records=2064archive+23website+3indexedYTdescriptions;20packs/2064snapshots,71local source labels unchanged. Planning54/4/methodfamily1 unchanged. Second1000native conversion and explicit repeat/diversity search preferences;319fullFlutter/37Node/analyze clean. HANDOFF§89. Optional MonthlyBudgetRecipePreferences(maxOccurrencesByRecipe:,minimumDistinctRecipes:) on domain/service search: explicit nonnegative maxima(max0excludes), absentorpositive minimum, no defaults. Count exact resolved revision.variantId==recipe.id across supplied slots, not family/cuisine/clinical aliases. Service derives every candidate identity before pricing; missing/extra/blank domain context rejects even beyondcap. Inputs/criteria/context/reasons owned+immutable. SamefirstNrawcombinations priced; rejectedconsume cap. comparison.ranked remains financial evidence; use eligibleRanked/eligibleCount and preferenceViolationsByOption; bestKnownAffordable/outcome respect limits withoutrelaxation. Any evaluatedunknowncost orcap staysindeterminate, exhaustive negative onlyscopeofsuppliedpools/preferences. No autosave/globalmonth/personfitness claim.


## Required slot coverage §90 —16October2026

`searchMonthlyBudgetChoices` in the pure domain and `KitchenService` now accept optional `requiredSlots: List<MonthlyBudgetCoverage>`. Each caller-declared pair has an exact in-month `YYYY-MM-DD` date and nonblank meal slot; empty, duplicate or out-of-period requirements reject. The service copies the input before awaits. If any required pair is absent from candidate pools, `requiredCoverage.missing` identifies it, `outcome` becomes indeterminate and `bestKnownAffordable` stays null while financial rankings remain reviewable. Extra supplied pairs remain costed. Omission of `requiredSlots` keeps prior partial-coverage behavior. The caller, not the app, defines required meals; no person-target, nutrition, live-price or auto-save inference. Handoff/test evidence §90.
