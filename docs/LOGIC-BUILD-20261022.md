# Recipe yield review and explicit monthly plan acceptance — 22 October 2026

Goal: make existing recipe and budget flows usable without inventing source metadata or silently selecting plans. Sole E checkout, no UI/Firebase/billing changes. User explicitly authorized identifying and building missing application logic.

## Unit A — revision-scoped yield review

- Add immutable RecipeYieldReview: exact source revision key/fingerprint, whole-recipe baseServings1..1000, nonempty review note, UTC date. Explicit whole-recipe acknowledgement required.
- Build a personal child revision with a new variant identity. Only ID and servings change; ingredients, instructions, unknown timing and provenance remain exact. Source catalog is unchanged.
- RecipeBook validates evidence against the exact parent and rejects tampering, cross-family use, mixed evidence or edits outside approved fields. Legacy serialization stays unchanged when no yield review exists.
- KitchenService.reviewRecipeYield saves through existing atomic writer; retry is immutable and does not reactivate an older revision or inherit nutrition bindings. Existing pinned plans/history remain unchanged.
- TDD: unknown source scaling refuses; reviewed child scales; persistence/reload/provenance; invalid ranges/ack/source/tamper; store failure rollback; retry and pinned old plans; no automatic stock/nutrition/price changes.

## Unit B — explicit monthly search acceptance

- Extend owned search preview with service owner identity, captured snapshot string and write tail. Add a separate service part implementing acceptMonthlyBudgetSearchOption.
- Caller selects exact evaluated eligible known-affordable option and supplies exact pool-to-new-plan IDs. No implicit cheapest selection, required coverage gaps, unknown selected price, duplicate IDs or silent overwrites.
- Verify preview owner, snapshot/write-tail freshness, and exact resolved revision pins before one atomic write. Register selected catalog snapshots and save all selected plans together. Explicit allowReplaceUncooked permits only uncooked replacement.
- Preserve other plans, stock, budget, prices, purchases and nutrition history. Rollback on save failure. Bounded search is not a global or medically suitable month guarantee.
- TDD: valid batch/reload, stale price/stock/revision, cross-service preview, invalid/ineligible/unknown option, map ownership/ID collisions, cooked-plan rejection, store failure.

## Delivery

First close the interrupted622-recipe baseline with fresh tests. A disjoint economical source worker continues the already-authorized650 target. Coordinator alone promotes candidates, updates counts/table/shared docs and Git. Freeze final catalog before final gates. Verify related tests, full integration gate, analysis, source pins and original65 parity; update STATUS/HANDOFF/WORK-QUEUE/CLAUDE plus external mirrors, commit/push and DELIVERY.
