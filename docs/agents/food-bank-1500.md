# Food bank helper batch 1500 — 14 October 2026

Checkout: `E:\work\SOFRA\app` (designated active checkout; reported base `0fcfffd`). Scope: one bounded Open Food Facts public-read attempt through the authorized module API, `runBatch({out,maxRequests:1,onProgress})` under `withCollectorLock`.

## Preflight and source basis

- Read `docs/FOOD-BANK-CONTINUITY.md` shared access gate and bounded module invocation entries, `tool/food/collect-incremental.mjs`, `tool/food/import.mjs`, and `tool/food/source-access.mjs`.
- Official API docs: https://openfoodfacts.github.io/openfoodfacts-server/api/ . They specify a custom identifying User-Agent for requests; GET/read operations do not require authentication beyond that header, and search queries have a 10 requests/minute/IP limit. The existing collector sends `SofraResearch/0.1 (https://github.com/mohussamarch/sofra-flutter)`. No credentials or alternate endpoint were used.
- Immediately before the network call: quota reported ordinary usage allowed, primary 36%, weekly 21%; no purchased credits available. After the attempt, quota was ordinary allowed, primary 37%, weekly 21%. No reset was used.
- Lock absent, no checkpoint temp files, no Node processes visible, and shared source gate had expired at the current time. Collector lock remained absent after completion.

## Actual attempt and result

Exactly one request was issued to the existing public endpoint `world.openfoodfacts.org/cgi/search.pl`, Egypt/global page 11. It returned HTTP 401 at `2026-10-14T15:13:18.596Z`. The collector recorded `egypt/global` page 11 failure and backoff through `2026-10-14T16:33:18.596Z`. This 401 activates the shared upstream access gate. No retry, country/category switch, alternate domain, authentication, or access workaround was attempted.

Products remain 2,378 and raw archives 67. `products.jsonl` and `manifest.json` retain their pre-attempt 14 October 05:35 (+03:00) modification times. No products were added, so no bank validator was run; this was a failure-only checkpoint and no broad tests were run. Product data remains unreviewed and is not nutrition approval.

## Next action

Stop collection during the shared access gate. Before any future request, review official public access guidance and determine whether the source needs an API usage form or other source-side resolution. Do not use credentials or change route automatically. Root owns shared `STATUS.md`/`HANDOFF.md` and Git operations.

Coordinator clarification: the helper process listing was scoped/permission-limited. Existing preview node.exe PID31004 on8766 remained alive; it is not a food collector. Do not infer the machine has no Node processes from helper visibility.
