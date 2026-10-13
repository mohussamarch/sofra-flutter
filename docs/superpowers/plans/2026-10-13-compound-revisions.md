# Explicit compound ingredient split revisions

Goal: implement source-backed USER REVIEW mechanism, not author recipe facts. Sole E/main, no UI/sourcebank/Firebase changes. Existing append-only revisions and pinned plans remain.

1. TDD new personal revision replacing one parent row by2+distinct quantified components; full snapshot/source stamp/review note/time; no inferred ratios or salt-only substitution.
2. Typed immutable IngredientSplitReview, pure builder, RecipeBook validation against exact parent snapshot and expected complete contents. Optional version1 field backward readable.
3. KitchenService entry copies inputs into immutable draft before await/save; uses existing atomic book save, no automatic food-binding inheritance or replanning. Explicitly new bindings required for every new revision.
4. Test source/history stability, stale/tampered reviews, idempotent retry, failed save rollback, independent quantities/scaling and no leaked shifted-line selections. Fresh focused review/full relevant gates/docs/queue/commitpush.

Acknowledgement affirms supplied components fully replace source line and existing instructions remain appropriate. Dates/amounts supplied by caller, no generated food quantities or recipe variants. No automatic parsing of names proves chemical identity. Next: official preparation/yield/retention evidence, then allergens.

All4stepscompleted;6new/92fullFlutter,cleanAnalyze,34Node,focusedreviewnoissues. Preparation-sourceindexfirstunitalsointegrated;0factorsapproved. FinalGitreceiptoutsideafterpush.
