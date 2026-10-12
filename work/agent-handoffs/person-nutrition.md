# Agent handoff: people, portions and nutritional interaction

Date: 2026-10-12 (Asia/Riyadh). Canonical checkout only: `E:\work\SOFRA\app`.
Base provided by coordinator: `bb1034d3b6056cdccde7f1c2f298368ef71e8d25`.
No commits, pushes, shared docs, UI, Firebase or server changes made by this agent.

## Owned files

- `lib/domain/person_nutrition.dart`: new domain models, allocation ledger and interaction rules.
- `test/person_nutrition_test.dart`: eight focused tests.
- `work/agent-handoffs/person-nutrition.md`: this handoff, coordinator consolidates shared documentation.

## API

- `NutritionPersonProfile.memberId` references the existing `HouseholdMember.id`; there is no separate person identity. Optional date of birth or explicit age plus observation date, preference recipe/food IDs, allergy rules, target ranges, free health text and optional celebrations.
- `AllergyRule` stores allergen ID, explicitly entered severity, cross-contact warn/avoid, source and recorded date. Unknown allergen evidence remains unknown.
- `NutrientTarget` stores daily range, unit, user/clinician authority, source, recorded date, validity dates and optional review date. No age-, sex-, diagnosis- or free-text-derived target. Overlapping targets for the same nutrient rejected.
- `PersonNutrientValue(knownSubtotal, complete, unit)` bridges core `NutrientTotal`; use core nutrient enum `.name` and `.unit.name`. No guessed values or percentage coverage. `value` is null unless complete.
- `MealBatch(id,recipeId,sourceSnapshotId,cookedGrams?,nutrients,allergens)` is immutable after being registered in the ledger. Freeze the nutrition source snapshot ID in the coordinator adapter.
- `PortionAmount(amount, grams|batchFraction)` is explicit. Gram portions require measured cooked batch grams; fractions do not require mass. No inferred equal portions, household age multipliers or item-to-mass conversion.
- `NutritionEvent(id,batchId,kind,personId?,portion,day,actorId,recordedAt,corrects?,cancelled)` is an attributed append-only record. Event kinds planned/consumed/leftover/waste. Actor ID is attribution, **not** a cryptographic signature. Service authorization remains the state owner's responsibility.
- `NutritionLedger.empty().addBatch(...).append(...)` returns immutable values. Exactly identical retry event returns the same ledger; reusing the ID with changed content rejects. `fromJson/toJson` version 1 validate and replay the full history.
- Corrections reference the current leaf only, keep batch/person/kind identity, cannot predate the replaced record, preserve all old records. Cancellation is a correction, not deletion.
- `balance(batchId)` separates planned and actual totals. Actual consumed + leftover + waste cannot exceed one batch; planned allocations separately cannot exceed one. Unaccounted fraction is explicit.
- `report(personId,day,kind,nutrientIds)` keeps planned vs consumed separate. Any missing/partial source prevents complete totals; known subtotal remains visible. No intake records does not mean zero intake.
- `mealInteractions(person,batch,triggerId)` returns deterministic event IDs for allergy conflicts, cross-contact warnings, unknown evidence and optional favorite celebration. Any allergy warning/unknown suppresses celebration. No reaction is inferred from health free text.
- `targetInteractions(person,report,periodComplete,triggerId)` only emits below/above/within for a caller-confirmed complete period with fully known nutrients and matching units. Other cases return unknown; a due review returns needs-review. It does not give clinical advice.

## Integration constraints

- Root coordinator owns persistence and food-core adapter. Persist updated ledger together with the app's state using its single owner. No direct Firebase writer added.
- Fractions estimate proportional distribution of batch nutrients. Heterogeneous components (rice vs meat) should use separate batch/component records instead of falsely assuming uniform food.
- Reallocating a fully allocated batch or consuming leftovers requires reducing/cancelling the earlier allocation first, then adding the new intake. Build the whole immutable result locally and save once. Replay preserves sequential conservation, so corrections that release a portion must precede new allocations.
- A batch is a preparation identity; leftovers do not create a second identical nutritious batch. Correct leftover accounting and append actual consumption with its real day.
- Adapter may map `AllergenAssessment` conservatively: unknown evidence must not become absent.
- No existing behavior decisions changed. No UI, audio, image generation, prices, targets, nutrition values or medical facts invented.

## Checks actually run

- `dart format lib/domain/person_nutrition.dart test/person_nutrition_test.dart`: success.
- `dart analyze lib/domain/person_nutrition.dart test/person_nutrition_test.dart`: **No issues found** after fixing six brace style notices and using package import.
- `flutter test test/person_nutrition_test.dart --no-pub --reporter expanded`: **8 passed**, rerun after style fixes.
- Tests cover versioned immutable profile/age dates/target overlap; separate plan vs intake/retry/reopen; explicit gram/fraction units; conservation with leftovers/waste; correction chains/cancellation/history; partial/missing nutrition; allergy/favorite deterministic events; target period/unit/completeness/review guards.

## Exact next action

Coordinator adds core-to-person adapter and persisted service methods, runs integration/full gates, consolidates STATUS/HANDOFF/receipt and commits/pushes. No agent-owned work remains unfinished.
