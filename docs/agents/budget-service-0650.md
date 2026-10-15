# Budget advisory service — independent backend unit, 15 October 2026

## Ownership and starting point

- Sole active checkout `E:\work\SOFRA\app`, branch main. Coordinator supplied clean/pushed base `96df43d3bc6a2ab574ae463bf29d133c3a72cb1b` (§85) and actual quota35primary/5weekly, ordinary=true, ceiling90. No worker Git/network/usage-reset/purchase actions.
- Root approved the proposed service contract, including existing optional-null/current versus explicitly pinned revision resolution. Exclusive owned files: `lib/data/kitchen_service.dart`, `test/monthly_budget_service_test.dart`, this handoff and `budget-service-0650.status.md`.
- Domain comparator from§85 remains unchanged. No additional DTO was needed. Root owns shared API/queue/handoff/status integration, single full gate, commit/push and final receipt.

## Actual gap and resulting API

The§85 domain comparator required a caller pricing callback and already assembled ingredient requirements. The existing service had only a selected saved-plan purchase preview. Added:

```dart
final result = await kitchen.previewMonthlyBudgetChoices(
  'saved-month-budget-id',
  options: <String, List<PlannedMeal>>{
    'option-id': explicitCandidateMeals,
  },
  rules: explicitUnitRules,
  optionalLinesByOption: <String, Map<String, Set<int>>>{},
  measuredByOption: <String, Map<String, Map<int, IngredientUse>>>{},
);
```

Each option contains explicit unsaved `PlannedMeal` selections: local candidate ID, recipe ID, requested date/slot/servings and optional recipe revision key. Decisions are scoped option ID → candidate meal ID → recipe line. Options may reuse the same candidate ID across alternatives but candidate IDs within one option must be unique. Extra/unselected decision scopes are rejected even if their maps are empty. Completed candidate meals are rejected.

The service resolves recipes using existing `_resolveMeal` semantics. A supplied pin must exist and match its recipe. Null input resolves the currently effective personal revision or catalog recipe using the existing resolver; it is not described as initially pinned. Every returned `MonthlyBudgetMeal.candidateId` contains its exact resolved `revision.key`, including catalog snapshot version evidence. Caller raw recipe text, food identity or guessed source quantities are never accepted by this API.

A private `_purchasePreviewMeal` helper is shared by `previewPurchases` and the new monthly adapter. It preserves existing forServings scaling, line-specific optional selection, allowed measurements only for unresolved lines with matching ingredient ID, and unresolved requirement IDs. It does not parse raw source quantities, guess conversions, override known amounts, include optional lines automatically or imply nutrition/rights/medical review. Existing saved-plan forecast behavior is verified by all7 prior service tests.

The saved budget must exist uniquely and match the captured kitchen country. Prices are always resolved through private `_cost(k, use, ownedRules)` over that kitchen snapshot, preserving existing user-override-before-average and country rules. No public arbitrary-price callback exists on the adapter. Captured inventory and frozen confirmed purchase ledger feed the unchanged monthly comparator. The comparator retains equal explicit partial coverage, end-exclusive calendar-month/country spending, shared stock once per option, separate purchase/consumption values, unranked incomplete totals, nullable affordability and no carryover.

## Input ownership and freshness

- Every option list, all nested optional sets/measurement maps and the unit-rule list are copied before the first await. PlannedMeal, IngredientUse and UnitRule leaves contain final scalar fields, so copying their collection references is sufficient ownership.
- Await the existing write tail, then capture one kitchen snapshot and its JSON guard.
- Resolve all recipes/decisions and retain their exact keys in the result candidates. No recipe registration/save occurs even for a previously uncached catalog read.
- Await the then-current write tail and reject if the whole kitchen JSON differs. Price, budget, stock, country, recipe-book, plan, history or ledger changes cannot produce a silently stale asynchronous advisory result. Waiting for an in-flight save is explicitly verified.
- The final comparison is synchronous and uses only the captured snapshot. No new acceptance/save API is introduced; a caller must request fresh advice after subsequent kitchen changes.

## Verification actually run

1. Added first meaningful readonly/current-stock/user-price/ledger test against the new API skeleton. `flutter test --no-pub test/monthly_budget_service_test.dart` failed with the expected runtime `UnimplementedError` (1failed).
2. Implemented adapter/helper. Same new test plus7 existing purchase-service tests passed8.
3. Added ownership/unknown/country/history/revision/scope/race tests. One intermediate focused run was interrupted when the test fixture blocked the recipe index that its concurrent revision writer also needed. This was a controlled test-fixture deadlock, not product evidence. Moved the gate to recipe-body loading, leaving index access available; no product behavior changed for this correction.
4. Final `flutter test --no-pub test/monthly_budget_service_test.dart test/purchase_forecast_integration_test.dart test/monthly_budget_choices_test.dart` passed31:13 new service tests,7 existing purchase-service tests,11 unchanged monthly domain tests.
5. Formatted only the two owned Dart files. `dart analyze lib/data/kitchen_service.dart test/monthly_budget_service_test.dart` exited0 with `No issues found!`.

New tests substantiate unchanged kitchen/store/save count, current stock shared across option meals, override before average, frozen confirmed purchase/cooking history, current-country prices and budget matching, unknown included/optional quantities, explicit measurements, deep pre-await ownership including unit rules, current versus old pinned revisions and result keys, rejected ignored scopes/measurements, four actual asynchronous changes (price/budget/stock/revision), unchanged delayed success without registration and final waiting for an in-flight write. Synthetic fixtures prove contracts/arithmetic only; no shipped food/price claims.

SDK remains `C:\Users\atgs0\Documents\Codex\2026-10-09\cooking-app-flutter\work\flutter_sdk\bin`; commands used `--no-pub` and no dependency/source network.

## Handoff and remaining work

Root can review the4 owned files, integrate the new adapter into BACKEND-API/MONTHLY-BUDGET-CHOICES/queue and run its single full gate before commit/push. Worker returns ownership now; no active tests or processes remain from this unit. Preview server was untouched, so root retains server-status receipt responsibility.

This is advisory comparison of explicit options, not automatic monthly menu creation. Full-month completeness, diversity/preferences/person targets, reviewed merchant feeds/package rounding, source/food/quantity coverage, nutritional/clinical fitness and explicit user-approved saving remain separate. No changes to domain comparator, other projects, UI/audio/images/Firebase/billing/APK/Drive/device work, source banks, intake or cloud state. Planning, stock, ledger and history are never written by this preview. User decisions remain unchanged.
