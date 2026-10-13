# OpenFoodFacts bank helper handoff — 2026-10-13

## Objective and scope
Continue the bounded OFF collector once from the authorized checkout `E:\work\SOFRA\app`, preserving its source cursor/backoff rules. Owned outputs: `data/food/openfoodfacts/**` and this handoff/status pair only.

## Starting state
- Coordinator supplied base `a38bd2` and branch `main`; repository Git inspection is unavailable in this worker context (`git -C E:\work\SOFRA\app rev-parse` returned access denied). No Git operations were performed.
- Fresh account usage check before any collection: 87% of 5-hour limit, 14% weekly, ordinary usage allowed, no credits. This was below the 90% reserve threshold.
- One OFF job was due: Saudi Arabia global page 4. Saudi dairy page 3 remained backed off until `2026-10-13T10:53:29.506Z`; Egypt global page 7 until `2026-10-13T12:54:39.414Z`.

## Work and outcome
Invoked the existing `runBatch` inside `withCollectorLock`, with `maxRequests: 1`. The sole request was `saudi-arabia/global` page 4. It failed with `fetch failed` and no HTTP status; the existing collector persisted failure count 2 and retry time `2026-10-13T11:01:09.668Z`. No second request was made. The runner completed; its `finally` removed `collection.lock`. No collector process remained from this completed synchronous invocation; OS process inventory was inaccessible in this worker context.

## Data counters
- Product records: 1793 before and after (the run fetched no product data).
- Raw archives: 55 before and after.
- Quarantine records: 261; duplicate records: 485.
- Quality counters retained from the latest coordinator STATUS snapshot: 1305 with nutrients, 1194 core, 733 ingredients, 1349 brands, 381 declared allergens. All 1793 records remain unreviewed.
- Source license/provenance treatment unchanged. No invented or empty product data was added.

## Verification and limitations
- Verified persisted cursor/backoff and observed `collection.lock` absent after completion.
- No bank tests were run because products/archives did not change.
- The initial lock open was blocked by filesystem permissions before any request. After the requested write access was granted, the single bounded run completed as described.
- Git status/diff and OS process inventory were inaccessible; coordinator owns Git integration and shared docs.

## Exact next action
Recheck usage with a fresh limit reading and confirm ordinary usage remains allowed below the 90% reserve. Recheck lock and cursor timing. Earliest scheduled source is `saudi-arabia/dairy` page 3 at/after `2026-10-13T10:53:29.506Z`; Saudi global page 4 is next due at/after `2026-10-13T11:01:09.668Z`; Egypt global page 7 remains due after `2026-10-13T12:54:39.414Z`. Make at most one due request in a follow-up, preserving collector lock, cursor, pacing and backoff.

No code, shared docs, queue, Firebase, UI, APK, billing, Git, credits or reset changes were made.
