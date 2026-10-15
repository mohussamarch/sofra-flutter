# Monthly budget choices — independent backend unit, 15 October 2026

## Scope and ownership

- Sole active checkout: `E:\work\SOFRA\app`, branch `main`; coordinator supplied base `1872fdd`. No Git operations performed by this worker. The `/main` wording in dispatch referred to the branch, not a directory.
- Root approved this bounded contract and confirmed all four owned files were absent/clean before implementation.
- Owned files only: `lib/domain/monthly_budget_choices.dart`, `test/monthly_budget_choices_test.dart`, this file and `budget-logic-0630.status.md`.
- Root owns shared docs, queue, service integration, full gate, commit/push and final receipt. No second source checkout edited; SDK/generated cache in C is existing infrastructure.
- Dispatch supplied actual quota 0/0, ordinary=true, ceiling90. This unit made no network/source requests or usage reset/purchase.

## Proven missing unit and implementation

Existing `forecastPurchases`/`KitchenService.previewPurchases` forecast a selected plan set; `BudgetSummary` compares one planned-purchase scalar. No monthly alternative comparator was present. The new pure `compareMonthlyBudgetChoices` compares explicit caller-supplied alternative meal requirements for a calendar-month `BudgetPeriod`.

Inputs:

- `MonthlyBudgetOption(id, meals)` owns immutable meal lists.
- `MonthlyBudgetMeal(date, slot, candidateId, requirements, unresolvedRequirements)` owns explicit, already scaled included ingredient uses and unresolved requirement identities. No recipe/food match, serving calculation, optional inclusion or missing quantity is inferred.
- Explicit stock snapshot, confirmed `MoneyEntry` purchase records, optional explicit `UnitRule` conversions, and a pure `estimateCost(country, use)` callback. The callback must use the supplied country and existing user-override-before-average pricing. It must not fetch sources or mutate state. The comparator cannot certify caller-supplied recipe completeness or price provenance.

Validation and results:

- Budget starts on day1 and ends at the next calendar month, exclusive; December rollover and leap February work. Each option needs a unique nonblank ID and nonempty, unique in-period date/slot coverage; each meal needs a nonblank caller candidate ID.
- Options must cover the same explicit date/slot set, independent of order. Sorted `coverage` reports only those supplied slots. It does not assert a complete calendar month or an assumed number of meals per day.
- Every whole option calls the existing `forecastPurchases` independently against one shared stock snapshot. Stock is allocated once within an option and remains available when assessing another alternative. Compatible quantity aggregation, explicit conversion rules, unknown stock and unresolved requirements follow the existing engine.
- `spent` uses the existing `BudgetSummary` country and end-exclusive period filters over frozen confirmed amounts. No previous-month balance is imported.
- Each assessment exposes its option, full purchase/consumption forecast and nullable `remainingAfterPurchases`, `overrun`, `withinBudget`. A complete purchase forecast may rank even if consumed-stock value is unknown. Unknown purchase totals stay unranked with all three affordability values null; known subtotals and reason sets remain available through the forecast.
- `ranked` contains complete forecasts by new-purchase cost ascending, breaking equal costs by option ID. `assessments` and `unranked` preserve supplied option order. Zero prices remain known zeros. Nonfinite pricing/spending/combined spending rejects instead of presenting affordability.
- Collections are owned and immutable; no stock mutation, new purchase flag, ledger/history creation, intake, reservation, plan selection/edit, save, monthly carryover or clinical/nutritional fitness inference occurs. Existing explicit purchase choice and frozen confirmed history remain in their current service APIs.

## Verification actually run

1. Added the first real shared-stock/alternative-ranking behavior test and API skeleton. `flutter test --no-pub test/monthly_budget_choices_test.dart` failed at runtime with the expected `UnimplementedError` (1failed).
2. Implemented comparison. Same focused test passed (1passed).
3. Added independent edge cases; `flutter test --no-pub test/monthly_budget_choices_test.dart test/purchase_forecast_test.dart` passed22 tests:11 new monthly tests and11 existing forecast dependency tests.
4. Ran formatter only on the two owned Dart files.
5. `dart analyze lib/domain/monthly_budget_choices.dart test/monthly_budget_choices_test.dart` returned `No issues found!`, exit0.

The11 monthly tests cover whole-option stock allocation/cost separation, unknown price/quantity/stock, stocked ingredients with unknown consumption value, country/start/end spending filters and no carryover, explicit country pricing/overrun with unchanged choices, explicit count conversion, partial/equal/unique coverage and stable ties, December/leap-year month boundaries, invalid identities/options, input ownership/result immutability, and nonfinite/overflow rejection. SDK: `C:\Users\atgs0\Documents\Codex\2026-10-09\cooking-app-flutter\work\flutter_sdk\bin`.

## Remaining work and exact next action

This is a read-only comparison prerequisite, not an automatic monthly menu generator. Root can integrate the contract into BACKEND-API/queue and run its single full gate. Future service/UI integration must assemble explicit reviewed/pinned candidate needs, scope existing user-first prices to the selected country, and guard stale kitchen snapshots before offering or accepting results. Automatic candidate generation, diversity/preferences/person-target constraints, reviewed price-feed coverage, package rounding, nutritional completeness and user-approved saving remain separate work. Existing people targets were not duplicated.

No UI/audio/images/Firebase/billing/APK/Drive/device work; no source bank or clinical rules changed. No preview/process operations performed. Root retains commit/push/cleanliness/server receipt responsibility. Worker returns ownership of all four files after reporting completion.
