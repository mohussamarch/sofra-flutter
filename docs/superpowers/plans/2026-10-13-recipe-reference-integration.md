# Recipe reference integration

Approved scope: continue nutrition backend implementation, sole E checkout, no UI changes. Existing food architecture and user instruction authorize inline implementation; no new design approval needed. Use writing-plans, executing-plans and test-driven-development, preserving the one-checkout user rule.

1. Add a distinct ingredient-input estimate. Test first: prepared result remains unknown without retention; input estimate uses measured input forms, never changes stock/intake/history.
2. Load reviewed generic reference candidates for exact immutable recipe snapshots. Require explicit generic-reference acknowledgement and ambiguous choices; reject stale/invalid identities. Apply atomically through KitchenService, preserving manual selections by default; test failure rollback.
3. Stamp source-reviewed artifact against full recipe snapshots. Test actual bechamel data, missing units, compound lines, optional choices, and source freshness. Run full Flutter tests/analyze plus actual bank hash tests and one fresh code review. Consolidate handoffs, commit/push main and verify clean equality.

Ledger: research agent owns data/nutrition/recipe-reference-review.json until release; cheap collector owns OFF data and its own handoff. Root owns implementation, tests and shared docs. No guessed nutrient/portion/retention values, no personal intake inferred. Ingredient estimates are explicitly separate from prepared nutrition. USDA CC0 and OFF licenses stay separate. This delivery does not create an APK or change Firebase.

Open follow-up: reviewed preparation factors, measured household measures, label basis review and external UI integration. Source candidate identity is not verified full-recipe nutrition.


Outcome: tasks1–3 implemented and verified. Final71Flutter tests, full analysis no issues, Node8tests (actualbank5/review3), guarded197-entry stamp. Fresh independent review found unsafe stamping and mutable choices; both corrected with negative/regression tests. Source identity review197entries is distinct from0fully verified nutrition bindings. Bank1344after source backoff exhausted due jobs. No UI/APK/Firebase changes. Final pushed hash/clean check is in external receipt. Next task is measured input/compound and preparation evidence, not an assumption of complete cooked nutrition.
