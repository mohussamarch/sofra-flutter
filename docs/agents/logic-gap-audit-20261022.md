# Focused backend gap audit — 2026-10-22

Read-only audit of the monthly budget and recipe scaling path. Evidence is from current code; no product files were changed.

## Three concrete missing flows

1. **Accept a chosen monthly search result as one atomic plan write (highest value / best bounded unit).** `KitchenService.searchMonthlyBudgetChoices` resolves and returns immutable, exact-revision `candidatesByPool` evidence alongside the ranked search result, but it is preview-only (`lib/data/kitchen_service.dart:46-58,1463-1626`). The only plan writer is `plan(PlannedMeal)`, which writes one meal at a time and does not consume a search preview (`lib/data/kitchen_service.dart:1140-1158`). No API validates that a chosen option is an evaluated, coverage-complete, preference-eligible affordable row, rechecks the preview snapshot, and saves all selected pinned meals in a single `_write`. This leaves callers to rebuild acceptance logic and risk partial month writes. **Bounded implementation:** add preview evidence carrying the searched snapshot identity and selected result ID; an acceptance method rechecks current state and selected result eligibility, then upserts every exact-pinned meal within one `_write`, rejecting cooked/replaced conflicts. Keep selection explicit; do not auto-pick. Existing `_write` serializes and publishes only after store success (`kitchen_service.dart:159-180`).

2. **Persist explicit user-reviewed source yield for recipes whose yield is unknown.** `CatalogRecipe.servings` remains nullable; `forServings` can use a transient `sourceServings` override but throws when neither is present (`lib/domain/recipe_catalog.dart:200-224`). Service resolution and downstream scaling call `forServings(meal.servings)` without that override (`lib/data/kitchen_service.dart:966,999,1238,1683`); repository-wide search found no persisted `sourceServings` field or acceptance method. Thus an explicit yield can be demonstrated at the pure helper, but it cannot be saved as reviewed evidence and reused for planning, cost preview, or cooking. **Next bounded unit after acceptance:** add an immutable, revision-scoped yield review (positive integer, reviewer/time/note, source revision fingerprint), persist it through the existing serialized write path, and resolve it only for that exact revision; invalidate/review again on recipe revision change. Do not infer or copy yield across variants.

3. **Generate monthly candidate pools from saved recipes.** Both search and comparison take caller-built whole options or explicit `MonthlyBudgetSlotPool` pools; service search requires nonempty supplied pools, each tied to one explicit in-period date/slot (`lib/data/kitchen_service.dart:1463-1517`; `lib/domain/monthly_budget_search.dart:82-99`). Required slots are optional caller-supplied coverage constraints, and the result is expressly limited to supplied pools, with no global menu claim (`monthly_budget_search.dart:48-71,158-170`). No service enumerates recipes/revisions into candidate pools for a month. **Action:** implement a separate opt-in generator only after defining explicit slot coverage and candidate eligibility inputs; never equate all saved recipes with suitable candidates or silently relax coverage/preferences.

## Recommendation

Implement item 1 as the next bounded high-impact backend unit. It closes the actual search-to-plan hole using existing exact revision evidence and the established atomic state writer, while keeping the search advisory and the user’s selection explicit. Leave source-yield review and automatic pool generation as separate units because they need new persisted review semantics and candidate-selection policy, respectively.

## Focused evidence trail

- `docs/FEATURE-STATUS.md` §86–90: preview/search adapters, explicit supplied pools, no stale acceptance API, no full-month generator; especially §90.
- `docs/BACKEND-API.md` §85–90: documented contracts and explicit candidate coverage limits.
- `lib/data/kitchen_service.dart`: `MonthlyBudgetSearchPreview`, `_write`, `_resolveMeal`, `plan`, `searchMonthlyBudgetChoices`.
- `lib/domain/monthly_budget_search.dart`: caller-supplied pool contract, bounded evaluation, scope of outcome.
- `lib/domain/recipe_catalog.dart`: nullable servings and transient source-yield override.

This was a focused code/document audit only. No tests, UI, Firebase, network, or Git operations were performed.
