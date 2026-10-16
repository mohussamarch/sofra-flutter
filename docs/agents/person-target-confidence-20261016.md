# Person target confidence — 16 October 2026

Owner: coordinator. Independent core unit while the recipe worker handled the fourth offline archive batch.

`targetInteractions` previously emitted `targetWithin`, `targetBelow`, or `targetAbove` for a complete daily subtotal even when its `PersonNutrientValue.estimated` was true or legacy null. The ledger already preserved that confidence flag, so this made an estimate appear to establish a personal nutrient target.

The assessor now emits `targetEstimated` for a complete, matching-unit subtotal marked estimated, and `targetUnknown` for null confidence. An explicitly non-estimated, complete value keeps the prior range comparison. The existing `targetNeedsReview` date and incomplete-period checks retain precedence. This changes only read-only interaction classification; no inferred medical target, intake record, food value, or saved plan is created.

Evidence: `lib/domain/person_nutrition.dart`, `test/person_nutrition_test.dart`. A new regression test first failed because `targetEstimated` was absent; after implementation, all 9 focused tests passed. A second case carries true/null confidence through the immutable ledger report into the interaction. Final full Flutter passed327 after correcting one stale total-count fixture; final `flutter analyze --no-pub` is clean. Related source/monitor Node49 also pass; no source record was promoted by this logic change.

Next: user-facing presentation can distinguish estimated versus unknown, but no UI was changed in this unit. Assessments remain dependent on explicit person targets and complete reviewed nutrition.
