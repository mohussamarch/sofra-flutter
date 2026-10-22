# Monthly search option acceptance — 2026-10-22

Implemented as the new `MonthlyPlanAcceptance` extension in `lib/data/monthly_plan_acceptance.dart`, attached to `KitchenService` by the root-owned `part` wiring.

## Contract

`acceptMonthlyBudgetSearchOption(preview, optionId:, planIdsByPool:, allowReplaceUncooked:false)` persists only the exact option the caller explicitly selected. It requires a preview from the same `KitchenService`, unchanged snapshot and write-tail, an evaluated option that appears in `eligibleRanked`, a known `withinBudget == true` assessment, and a non-null complete explicit slot-coverage assessment. A truncated search or unrelated unknown-cost option does not block accepting the selected known affordable row; the acceptance path makes no exhaustiveness claim.

The pool-to-plan ID map must cover exactly the selected pools, with unique nonblank IDs. Selected candidate evidence is resolved to its exact recipe revision; catalog revisions not yet in the recipe book are reconstructed from the same recipe ID and accepted only when the deterministic revision key still matches. A fresh snapshot check runs immediately before the single `_write` and again inside its transaction. The write registers catalog revisions and appends all selected plans atomically. Existing plan IDs are rejected by default; `allowReplaceUncooked: true` permits replacement of uncooked plans only. Cooked history is never replaced. Only plans and required catalog revision registration change; no stock, prices, purchases, budget, nutrition, or ledger data are written. Returned plans are immutable.

A search made without `requiredSlots` remains read-only advisory and cannot be accepted; request a new preview with the full explicit slot set.

## Verification

- TDD RED: the seven initial focused tests ran against an `UnimplementedError` stub and failed at acceptance behavior. The new missing-coverage test was also observed failing before its gate was added.
- GREEN: `flutter test --no-pub test/monthly_plan_acceptance_test.dart` — all 8 tests passed.
- `dart analyze lib/data/monthly_plan_acceptance.dart test/monthly_plan_acceptance_test.dart` — no issues found.
- Focused only; no full suite, UI, Firebase, or Git operations performed.

The root agent owns preview-constructor wiring in `kitchen_service.dart` and final integration review.
