# Open Food Facts collection handoff - cumulative through 2026-10-13 09:59Z

## Scope and execution
- Checkout: `E:\work\SOFRA\app`, branch `main`. Only `data/food/openfoodfacts/**` and this assigned handoff/status pair were written. Collector/test source was read/run, not edited. No shared status, queue, code, Firebase, UI, purchase, or quota-reset changes were made. The coordinator has other shared worktree edits; they were left untouched.
- Prior quota snapshot: ordinary usage allowed, 62% five-hour / 10% weekly at 09:49Z. Recheck after p1: ordinary allowed, 65% / 10%. Fresh pre-follow-up check at 09:59:04Z: ordinary allowed, 68% / 11%. Credits/reset were not used.
- Pre-follow-up collector checkpoint: no lock; ~50,653,917,184 bytes free; Saudi Arabia global p3 was the sole due job. Saudi dairy p3 and Egypt global p7 were still in their stored 503 backoffs.
- Collector requests, all under `withCollectorLock` through `runBatch`:
  1. Saudi Arabia global p1 succeeded (`2026-10-13T09:54:40Z` archive/build); 100 source records saved to `raw/saudi-arabia-p1.json`.
  2. Saudi Arabia global p2 succeeded (`2026-10-13T09:56:16Z` archive/build); 100 source records saved to `raw/saudi-arabia-p2.json`.
  3. Follow-up batch, max 2, made one request: Saudi Arabia global p3 succeeded (`2026-10-13T09:59:24Z` archive/build); 100 source records saved to `raw/saudi-arabia-p3.json`. No second request was made in this batch.
- Each batch wrote the collector checkpoint between requests. All three requests had `status=success`; all three collector commands actually exited 0; no failed request or retry occurred in this run. Lock is absent at handoff; no collector process remains.
- After each successful bank rebuild, ran `$env:SOFRA_FOOD_BANK='data/food/openfoodfacts'; node --test tool/food/import.test.mjs`: 5 passed, 0 failed on all three checks.

## Cumulative bank counters and delta
Baseline from the preceding handoff (before p1): 1,690 products; 52 archives; 247 quarantined; 302 duplicate occurrences; EG 686 / SA 1,015; nutrition 1,239; core macros 1,131; ingredients 680; brand 1,277; declared allergens 352.

Final manifest (`builtAt` `2026-10-13T09:59:24.205Z`):
- Products: 1,793 (+103 net; EG 686, SA 1,118)
- Archives: 55 (+3)
- Quarantined: 261 (+14)
- Duplicate occurrences: 485 (+183)
- With nutrition: 1,305 (+66); core macros: 1,194 (+63)
- With ingredients: 733 (+53); brand: 1,349 (+72); declared allergens: 381 (+29)
- Unreviewed nutrition basis: 1,793; all product bases remain unknown pending label review.
- Products SHA-256: `79c43b033c553f6b7586ce299ab759e3063cbb8a97a014e85cd2dfceab6547b9`
- Index SHA-256: `5768149a838ee42446570750b982c1b247b7f95fc2bfdf82beb5f2f6679bd045`

## Checkpoint, retries, and next cursor
- Current checkpoint at `2026-10-13T10:00:01.058Z`: `nextJobIndex=0`, `lastRequestAt=2026-10-13T09:59:23.916Z`; lock absent.
- Next cursor: Saudi Arabia global page 4, due now. Recheck quota, due status, and lock after the coordinator finishes the import transaction/commit; then continue from this cursor. No terminal dataset size is set.
- Saudi Arabia dairy page 3: prior OFF 503 at `06:53:29.507Z`; retry no earlier than `2026-10-13T10:53:29.506Z`.
- Egypt global page 7: prior OFF 503 at `08:54:39.414Z`; retry no earlier than `2026-10-13T12:54:39.414Z`.
- Other saved cursors are complete. Do not repeat failed jobs during their backoffs. Ownership released; coordinator may consolidate/commit the food-bank changes with its ongoing import transaction.
