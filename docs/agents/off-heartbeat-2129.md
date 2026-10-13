# OFF collector heartbeat 2129 — 2026-10-14

Scope: one bounded Open Food Facts collection cycle in the sole checkout `E:\work\SOFRA\app`. Collection only; no UI, Firebase, audio, image, recipe, or shared status changes.

## Start and safety checks

- Read `docs/STATUS.md` (under 50 lines), `docs/FOOD-BANK-CONTINUITY.md`, and `AGENTS.md` for the collector constraints.
- Initial actual usage check immediately before invocation 1: primary 3%, weekly 45%, `ordinaryUsageAllowed=true`. All values were available and below the 90% stop threshold.
- No collector lock file or active Node process was found before starting.
- Initial bank: 2,266 products and 63 raw archives. Existing source checkpoint had Egypt/global page 8 and Saudi Arabia/global page 10 with elapsed gates.

## Work and observed result

1. `node tool/food/collect-incremental.mjs data/food/openfoodfacts`
   - Actual process exit: 0; reported wall time 9.42 seconds (tool call 12.2 seconds).
   - Two requests; both returned HTTP 503. Egypt/global page 8 checkpointed `nextAttemptAt=2026-10-14T01:30:53.428Z`, failures 5. Saudi Arabia/global page 10 checkpointed `nextAttemptAt=2026-10-13T23:31:01.818Z`, failures 4. The collector summary said `fetched=false`, `nextJobIndex=0`.
2. Re-read actual usage immediately before invocation 2: primary 3%, weekly 45%, `ordinaryUsageAllowed=true`.
   - Same command; actual process exit: 0; reported wall time 0.35 seconds.
   - Zero requests; `fetched=false`, `nextJobIndex=0`. No eligible work was available.

Afterward the bank remained at 2,266 products and 63 raw archives. `products.jsonl` and `manifest.json` retained their 2026-10-13 20:20:46 modification times; only `collection-state.json` recorded the failures/backoff. No data-bank tests were run because this was a checkpoint-only HTTP 503 cycle; no source/content files changed.

## Current checkpoint and next action

Resume the ordinary quota check before any new batch. Respect the recorded source gates and verify the lock/process first. Do not retry these failed requests before their recorded gates or use an alternate endpoint. When sources become eligible, make at most the next authorized bounded invocation and record its actual exit and deltas. No claims of product growth or source success are made.

## Checkout / commit / process receipt

This agent did not commit or edit shared docs. Git metadata inspection was unavailable to this shell (`git rev-parse` reported permission denied), so no commit hash is claimed. No collector process remains running; no preview server was started or stopped.
