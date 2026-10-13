# Persistent household measures and cooking quantities

Human explicitly authorized autonomous ordered implementation; sole E checkout/main. Source estimate acceptance is per full recipe revision and line, requires an existing explicit food binding and acknowledgement of equivalent base-recipe portion. No UI/Firebase/prices/source facts invented.

1. TDD persistence/reload/replacement/stale review/rollback and count-line nutrition scaling.
2. Add immutable serialized source-measure evidence to RecipeFoodSelection, validate identity/form/arithmetic; atomic KitchenService acceptance validates plan and binding after async resolution.
3. Actual line weights are explicit, override accepted estimates, apply to stock/cost/nutrition together. Using a source estimate in confirmation requires explicit acknowledgement; freeze evidence and estimated line IDs. Keep old unmeasured API constraints and once-only rollback.
4. Meaningful integration tests, fresh review, docs/queue and commit/push/clean; compound splitting remains a separately queued recipe revision task, never use salt as salt+pepper.

Quantity precedence: actual cooking weight (new line API or legacy explicit unmeasured API) > acknowledged source base amount scaled by row flag > nominal quantity. Omitted/optional lines do not consume or require estimates. Source choices must not override already quantified mass/volume lines. Missing preparation stays unknown; no automatic intake.

Completed all4steps with11integration/86fullFlutter/cleananalyze/33Node; fresh P2fixed with red/green. Commit/push receipt recorded outsideGit after delivery.
