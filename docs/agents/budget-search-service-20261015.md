# Unit89 — bounded monthly search service, 15 October 2026

## Ownership and authorization

- Sole active checkout `E:\work\SOFRA\app`, main. Root owns shared files/Git/final delivery and integrates the independent source-pack worker. No second source checkout, Git, network, UI, cloud/Firebase/billing, audio/images or other-project changes by this worker.
- Explicit ownership only: `lib/data/kitchen_service.dart`, `test/monthly_budget_search_service_test.dart`, this handoff and `budget-search-service-20261015.status.md`. Existing domain modules and existing tests unchanged.
- User ceiling99 supersedes earlier90. Fresh actual quota supplied by coordinator:1primary/16weekly at dispatch,28/20ordinary=true before closure. Worker has no exposed usage tool; no reset/credits/purchase. No further unit starts after ownership return.

## Resulting API and concrete identity decision

```dart
final preview = await kitchen.searchMonthlyBudgetChoices(
  'saved-month-budget-id',
  pools: <String, List<PlannedMeal>>{
    'explicit-pool-id': explicitCandidatesForOneDateAndSlot,
  },
  maxEvaluations: explicitPositiveLimit,
  rules: explicitUnitRules,
  optionalLinesByPool: <String, Map<String, Set<int>>>{},
  measuredByPool: <String, Map<String, Map<int, IngredientUse>>>{},
);
final search = preview.search;
final exactCandidates = preview.candidatesByPool;
```

Added public `MonthlyBudgetSearchPreview` in the owned service file. It contains the unchanged domain `MonthlyBudgetSearchResult` plus immutable nested `candidatesByPool[poolId][candidateId]` evidence containing exact resolved `PlannedMeal` pins, date/slot, recipe and servings. Search candidates use caller `PlannedMeal.id`, unique within their pool. Reusing the same recipe/revision at different serving sizes is valid. The previous whole-option adapter used revision keys as candidate IDs; using those keys directly for pools would incorrectly collide serving alternatives. Root approved the explicit evidence-map design.

Every nonempty pool has one explicit date/slot, and coverage must be unique across pools. Duplicate/nonblank candidate IDs are checked per pool; the same candidate ID may appear in different pools. Pool IDs scope optional/measurement decisions. Unknown or extra decision scope keys reject even with empty maps. Completed candidates reject. Input dates/slots remain caller selections; no meal-pattern or complete-month guarantee is inferred.

## Current resolution, all-candidate validation and freshness

- Own every mutable candidate list, optional set, nested measurement map and unit-rule list before the first await. Leaves are existing immutable scalar-field PlannedMeal/IngredientUse/UnitRule objects.
- Await current write tail, capture one kitchen snapshot/JSON guard and the saved budget. Budget must exist uniquely and its country match the captured kitchen country.
- Resolve EVERY candidate through existing `_resolveMeal`, including candidates beyond `maxEvaluations`. Requested old pins remain old; null keys resolve the effective current personal/catalog recipe at preview time and are pinned only in returned evidence.
- Shared `_purchasePreviewMeal` retains existing forServings, explicit optional lines, valid unresolved-line measurements, ingredient-ID matching and unknown requirement semantics. Its only extension is an optional candidate-ID override; old callers retain revision-key default. No raw source text, guessed quantities/food identities/conversions or nutrition/rights/clinical approval is introduced.
- Build only supplied per-slot resolved pools, not the Cartesian product. Every supplied revision/line decision is validated before invoking domain search. Domain structural checks also validate all pools/candidates before any pricing, including out-of-period/unexamined needs.
- Await the then-current write tail; reject if whole kitchen JSON differs. This includes changes while resolving an UNEVALUATED candidate and while an in-flight save has not completed. Final search is synchronous and receives only captured stock/ledger/rules and private `_cost(k,...)` pricing; no arbitrary price callback is exposed by this service API.
- Domain `searchMonthlyBudgetChoices` remains unchanged: bounded lazy odometer, exact BigInt combination total, stock once per whole option, frozen matching confirmed spending, user-first country prices, explicit partial coverage, nullable incomplete affordability and no carryover. Capped or unknown =>indeterminate even with a visible best-known affordable suggestion. Negative exhaustive outcomes concern only supplied pools.
- Preview makes no writes, recipe registration, reservation, stock/ledger/history/intake update, automatic menu creation/apply/save or acceptance call. Subsequent kitchen changes require fresh preview.

## Verification actually run

1. Added first substantive shared-stock/current-user-price/confirmed-spend/serving-identity/readonly test against the new API skeleton. `flutter test --no-pub test/monthly_budget_search_service_test.dart` failed with expected runtime UnimplementedError (1failed).
2. Implemented adapter and evidence DTO; same test passed1.
3. Final focused run `flutter test --no-pub test/monthly_budget_search_service_test.dart test/monthly_budget_service_test.dart` passed27:14 new search-service tests +13 existing monthly-service tests. No remaining test failures. Existing13 suite ran once after integration changes.
4. Targeted `dart analyze lib/data/kitchen_service.dart test/monthly_budget_search_service_test.dart` initially reported2 informational style findings (single-line if braces, unnecessary dart:async import). Fixed those only, formatted the2owned files, reran targeted analysis: `No issues found!`, exit0. No additional functional edits or optional test expansion after the passing27; root owns final full integration gate.

The14 new tests cover: same recipe/different explicit servings with exact pins and no kitchen/store/save changes; exact2^70 count with3evaluations; unresolved included/optional quantities and stock; pre-await deep ownership and immutable evidence; country mismatch/missing prices/user override; ignored scopes, unknown/mismatched revisions, invalid decisions and malformed pools even when unevaluated; old pin versus current resolution;4actual async mutations(price/budget/stock/revision) during UNEVALUATED candidate resolution; waiting for an in-flight write; invalid cap/nonmonth/out-of-period pool; and unchanged delayed success returning unevaluated pins without registration/save. Synthetic fixture assertions are contracts/arithmetic only, not shipped food/price facts.

SDK unchanged: `C:\Users\atgs0\Documents\Codex\2026-10-09\cooking-app-flutter\work\flutter_sdk\bin`. No dependency/pub/network changes. No full suite by this worker; older292/full282 counts remain historical unless root reruns.

## Handoff and next action

Return all4owned files to root now; no pending test/analyze processes from this unit. Root reviews/shared API/queue integration and runs its single integration gate with the independent source-pack change, then commits/pushes and updates external receipt. Preview/process/server inspection not performed by this worker; root owns final server-status receipt.

Remaining: actual candidate generation, full-month coverage/preferences/diversity/person targets, reviewed merchant feed/package rounding, nutrition/allergen/clinical constraints and explicit user-approved persistence. This adapter provides read-only bounded advisory search over explicit recipe selections. No automatic full generator, clinical fitness, global feasibility/optimality or source-bank runtime approval claimed.
