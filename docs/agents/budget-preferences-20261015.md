# Explicit recipe preferences — independent core unit, 15 October 2026

## Ownership and authorization

- Sole active checkout `E:\work\SOFRA\app`, main; coordinator reported §88 delivered at44b961b before this unit. Root alone owns shared docs/queue/Git/full integration and the independent source-pack work.
- Seven owned files only: new `lib/domain/monthly_budget_preferences.dart`; existing `lib/domain/monthly_budget_search.dart` and `lib/data/kitchen_service.dart`; new `test/monthly_budget_preferences_test.dart` and `test/monthly_budget_preferences_service_test.dart`; this handoff and `budget-preferences-20261015.status.md`.
- Fresh coordinator actual quota38/22ordinary=true at dispatch,57/25before closure; user ceiling99. No worker usage-reset/credit/purchase/network/source request. Worker has no exposed usage-limit tool and relied on fresh coordinator evidence.

## API and exact user-only meaning

```dart
final preview = await kitchen.searchMonthlyBudgetChoices(
  savedBudgetId,
  pools: explicitRecipeCandidates,
  maxEvaluations: explicitLimit,
  recipePreferences: MonthlyBudgetRecipePreferences(
    maxOccurrencesByRecipe: {'exact-runtime-recipe-id': 2},
    minimumDistinctRecipes: 3,
  ),
);
```

Both fields are optional. Maxima must have nonblank exact recipe IDs and nonnegative integer values;0explicitly excludes that recipe from passing options. A supplied minimum must be positive (>=1); omit it for no minimum. Empty preferences have no constraints. There are no invented repeat/diversity defaults, no automatic relaxation and no clinical criteria.

Identity is the existing runtime `RecipeRevision.variantId == revision.recipe.id`. Service derives this exact value from EVERY resolved candidate, never from caller cuisine/family/source tags or labels. Different versions and serving sizes of the same runtime recipe ID share one repeat identity. Different runtime recipe IDs stay distinct even when in the same family or cuisine. IDs are case-sensitive; no aliases or family/cuisine/medical grouping is inferred.

Counts apply once per selected proposal slot, independent of servings/ingredient amounts, only within explicitly supplied coverage. Existing plans, confirmed cooking/intake and unprovided month slots are not silently counted. Include fixed meals as explicit one-candidate pools when they should count. A maximum naming an exact ID absent from supplied selected recipes has zero actual occurrences; it is never aliased to another recipe. This is known absence after complete identity validation, not an unknown recipe identity converted to zero.

## Domain identity contract and returned evidence

`MonthlyBudgetCandidateKey` is a named Dart record `(date:, slot:, candidateId:)`. Pure domain search accepts optional `recipePreferences` and `candidateRecipeIds: Map<MonthlyBudgetCandidateKey,String>`.

Before any pricing callback, active constraints require exact identities for ALL supplied candidates including unexamined ones. Missing, extra, wrong-scope or blank identities reject. Any nonempty supplied identity context must also be complete even with no active constraints. All maps/preferences are owned before callbacks; service copies accepted preferences before its first await and derives full identity context from its captured current/pinned resolutions. No default or free-text context label is substituted.

Search result adds immutable:

- `recipePreferences`: accepted explicit criteria, or null when absent.
- `candidateRecipeIds`: exact full identity evidence when supplied/derived.
- `preferenceViolationsByOption`: each evaluated option ID maps to immutable reasons (empty means passing). A maximum violation records exact recipeId, actual selected-slot count and explicit limit; minimum diversity records actual distinct count and explicit minimum. Reason ordering is deterministic.
- `eligibleRanked`: complete-price options passing every explicit criterion, ordered by existing financial purchase-cost/ID rules.
- `eligibleCount`: all preference-passing evaluated options, including unknown-cost options.

`comparison.ranked` remains financial evidence for all evaluated options, including preference rejections. `bestKnownAffordable` and final outcome use ONLY passing options. No criteria means eligible ranking/count and best/outcome preserve prior behavior.

## Boundedness, unknowns and existing guarantees

Search still evaluates/prices the SAME firstN raw whole combinations. Rejected options consume the evaluation cap. It does not scan past that cap to findNpassing options or prune using arbitrary partial costs. BigInt raw combination total, odometer ordering, frozen confirmed ledger, stock once per option, separate new-purchase/consumption values and country/user-first pricing remain unchanged.

Any cap or any evaluated unknown purchase cost remains conservatively indeterminate, even if the unknown-cost option fails preferences. An eligible known affordable suggestion may still be shown. Exhaustive `noAffordableInSuppliedPools` concerns only supplied candidates/coverage AND these explicit criteria; it does not establish global universe infeasibility, clinical fitness or a complete monthly menu. Contradictory explicit criteria return reasons without relaxing them or filling missing slots.

Existing service full-kitchen JSON/write-tail guard, validation of excluded/unevaluated revisions and line decisions, immutable pinned candidate evidence and read-only operation remain active. No plan/stock/history/ledger/intake write, acceptance/apply/save, carryover or UI/clinical/default-generation flow was introduced.

## Verification actually run

1. First meaningful integrated preference test against a placeholder failed with expected runtime UnimplementedError (1failed), then passed after implementation (1passed).
2. Final focused command:
   `flutter test --no-pub test/monthly_budget_preferences_test.dart test/monthly_budget_preferences_service_test.dart test/monthly_budget_search_test.dart test/monthly_budget_search_service_test.dart`
   passed37:13new (8domain+5service) +10existing domain search +14existing search-service. Existing tests unchanged and run once for integration. No remaining failures.
3. Formatted only the5owned Dart files. Targeted analysis of those5files initially found one unused test import. Removed that import and clarified a service doc comment; no further functional changes. Final same targeted `dart analyze` exited0: `No issues found!`.

The13new tests substantiate repeat/diversity winner selection, zero exclusion/conflicting rules and immutable reasons; absent/empty/default compatibility and invalid explicit values; ALLunexamined identity preflight before pricing; rejected-prefix cap/unknown conservatism; callback-reentry ownership; exact case-sensitive IDs and per-slot counting; impossible explicit minimum with partial coverage; service-derived identities across same-family distinct recipes, pins and serving sizes; pre-await criteria ownership; stale rejection during unevaluated resolution; and no bypass of invalid revisions/decisions merely because preferences exclude a candidate. Synthetic fixtures prove contracts/arithmetic only.

SDK unchanged at `C:\Users\atgs0\Documents\Codex\2026-10-09\cooking-app-flutter\work\flutter_sdk\bin`. No pub/dependency/network changes. Root owns the one final full integration gate; previous306Flutter is historical for this worker.

## Handoff and remaining scope

Return all7owned files to root now. No pending test/analyzer process or additional unit. Root reviews/integrates shared API/queue and runs its single integration gate with the source-pack worker, then commits/pushes/receipts. Preview server/processes untouched; root owns final server-status evidence.

Actual candidate/menu generation, full-month coverage, richer explicit preference windows/groups, person/nutrient/allergen/clinical constraints, reviewed merchant/package pricing, UI/APK and explicit approved persistence remain separate. This unit makes existing product-path bounded search honor explicit recipe repeat/diversity choices; no source-bank runtime approval or other project/cloud/Firebase/billing/audio/image work occurred.
