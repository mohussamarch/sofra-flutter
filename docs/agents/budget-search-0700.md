# Bounded monthly search — independent backend unit, 15 October 2026

## Ownership and scope

- Sole active checkout `E:\work\SOFRA\app`, main. Root supplied clean/pushed §86 base `9a3e17425e982dac00839b449ed9ebbbd46d2870` and authorized this bounded unit.
- Only owned files: `lib/domain/monthly_budget_search.dart`, `test/monthly_budget_search_test.dart`, this handoff and `budget-search-0700.status.md`. No edits to comparator, service, shared docs, queue or Git. No temporary `hash.txt` created by this worker.
- Actual quota supplied by root:67/10 ordinary=true at dispatch,71/11 during implementation,77/12 at closure, all below90. This worker has no exposed usage-limit tool and used these fresh coordinator readings. No network/source requests, credits/reset or purchases.
- Root owns review/shared integration, single full gate, Git/push and delivery receipt. Worker returns all ownership after this report and starts no further work.

## Proven missing unit and API

The existing domain comparator and service adapter assess explicit complete alternatives, but do not construct combinations from explicit per-slot candidates. Added pure:

```dart
final search = searchMonthlyBudgetChoices(
  period: explicitMonth,
  confirmedPurchases: frozenLedger,
  stock: stockSnapshot,
  pools: explicitSlotPools,
  maxEvaluations: explicitPositiveLimit,
  estimateCost: pureCountryUserFirstPrice,
  rules: explicitUnitRules,
);
```

`MonthlyBudgetSlotPool(date, slot, candidates)` owns its candidate list. Candidates reuse immutable `MonthlyBudgetMeal`: reviewed/scaled caller-supplied needs and unresolved identities. This API does not resolve recipes or certify caller/source/quantity/food review. The existing pure callback contract remains country-scoped and user-override-before-average; negative/nonfinite amounts reject through the unchanged comparator/forecast. Known zero cost remains valid.

Before ANY price callback, search owns pool/stock/ledger/rule collections and validates the entire supplied structure, including candidates that will not be evaluated: exact calendar month, positive evaluation limit, nonempty unique in-period date/slot pools, nonempty candidates, nonblank unique candidate IDs within each pool, matching candidate date/slot, positive finite requirement amounts using existing IngredientUse semantics, nonblank ingredient IDs/units/unresolved identities and explicit valid rule identity/units/factor. The same candidate ID may occur in different pools to repeat a recipe on another date/slot. No missing needs or conversions are inferred.

## Bounded enumeration and results

- `totalCombinations` is an exact BigInt product of pool lengths.
- A private lazy odometer emits whole options in supplied pool/candidate order, last pool fastest. Only `min(maxEvaluations, totalCombinations)` options are materialized for the unchanged comparator; the Cartesian product is never materialized. Memory for evaluated options is bounded by the explicit evaluation limit times coverage size, plus supplied inputs.
- Generated opaque option IDs are `choice:` plus the index vector. Existing comparator cost ties follow lexical IDs, not a numeric-index ordering claim.
- Each evaluated option passes through existing whole-option `compareMonthlyBudgetChoices`, preserving stock allocation once per alternative, frozen country/month confirmed spending, new-purchase/consumption separation and explicitly partial coverage. No partial-cost or heuristic budget pruning occurs; arbitrary nonnegative callback prices need not be monotonic.
- `MonthlyBudgetSearchResult` exposes immutable `comparison`, `totalCombinations`, `evaluatedCount`, `truncated`, `unknownCostCount`, `bestKnownAffordable` and `outcome`.
- Outcome is `indeterminate` whenever capped OR any evaluated purchase total is unknown, even if a known affordable option exists. That option remains visible as `bestKnownAffordable`. Otherwise outcome is `affordableFound` or `noAffordableInSuppliedPools`.
- The negative exhaustive outcome concerns these exact supplied candidate pools and coverage only. No global menu feasibility, full-month completeness, nutritional/clinical fitness or global optimality claim is made. No automatic plan, apply/save, stock/ledger/history/intake write or monthly carryover occurs.

## Actual verification

1. Added the first meaningful shared-stock/frozen-spend/combinations test against an API skeleton. `flutter test --no-pub test/monthly_budget_search_test.dart` failed with expected runtime `UnimplementedError` (1failed).
2. Implemented search; same focused test passed1.
3. Final `flutter test --no-pub test/monthly_budget_search_test.dart test/monthly_budget_choices_test.dart` passed21:10 new search tests +11 unchanged comparator tests. No remaining failures.
4. Formatted only the2 owned Dart files. `dart analyze lib/domain/monthly_budget_search.dart test/monthly_budget_search_test.dart` exited0 with `No issues found!`.

The10 new tests cover: full combinations/shared stock/frozen country-month ledger; cap with and without a known affordable prefix; unknown price/quantity/stock; exhaustive scoped negative outcome and true zero prices; validation of unexamined bad candidates/pools before any callback; exact2^70 count with only3evaluations/6price calls and deterministic odometer; snapshot ownership under adversarial callback collection mutation plus immutable outputs; nonmonotonic pricing without pruning; numeric/financial overflow rejection; repeated recipe IDs across pools and stable lexical vector tie breaks. Callback reentry is an ownership stress case, not permission for impure production pricing.

Existing13service tests and full282 gate are prior §86 evidence and were not rerun by this worker. SDK unchanged at `C:\Users\atgs0\Documents\Codex\2026-10-09\cooking-app-flutter\work\flutter_sdk\bin`; no pub/dependency/network changes.

## Next action and remaining gaps

Root reviews/integrates the contract and runs its single integration gate before commit/push/receipt. No additional unit started. Search is domain-only; service assembly from explicit reviewed recipe pools, coherent current snapshot/user-first private pricing and asynchronous guards remains a later adapter. Candidate generation/coverage, preferences/diversity/person constraints, reviewed merchant feeds/package rounding, full automatic month menus, clinical rules and explicit approved saving remain separate.

No UI/audio/images/Firebase/billing/APK/Drive/device/source-bank or other-project changes. No processes or preview server were touched; root owns final server-status receipt. All existing user decisions preserved.
