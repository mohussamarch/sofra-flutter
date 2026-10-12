# Food bank growth handoff — 12 October 2026

## Scope and result

Canonical checkout: `E:\work\SOFRA\app`, working base `e981a05`; no commit/push. Owned only `tool/food/**`, `data/food/**`, `docs/PRODUCT-DATA.md` and this handoff. Extended the collector to rotate through all20categories in Egypt and Saudi Arabia plus global-market pages, one request per query per batch, up to six requests per invocation. It resumes source pagination from immutable archives, uses source counts when available and page length otherwise, caches existing responses, serializes runs with a lock, enforces eight-second pacing, and persists exponential backoff for429/503. Derived bank rebuild occurs only after at least one response archive is added.

## Collection batch

Six sequential official OFF requests ran. Egypt snacks page1 succeeded with45source occurrences and added29new usable GTIN records after deduplication/quarantine. Five queries returned503 and were checkpointed: Saudi sweets p1, Saudi chocolate p1, Saudi snacks p1, Saudi dairy p2, and Egypt oils p1. The earlier Egypt rice p1 failure remains checkpointed. No same failed query was retried during backoff.

Bank now has716valid named GTINs; EG349, SA378, shared11. It has28immutable source archives,78quarantined occurrences and105duplicate occurrences. Nutrition remains unreviewed for every record. SHA256: products `6020deac70f9a0e88222b73f990f4873808e658e8afa3ce08283f1c03e61f71d`; index `0f7cc18efcb9ec0019be1429b01b398285d1ab1fdb07a313a4e2040a16d1b7c4`. Detailed source counts and category totals are in manifest.

## Verification and exact continuation

- `node --check tool/food/collect-incremental.mjs` and `node --check tool/food/import.mjs`: passed.
- `node --test tool/food/collect-incremental.test.mjs`:7passed, covering all-category/global rotation, cached full pages, partial/source-count exhaustion, numeric source counts, global page resume, 503 persisted backoff, and production-default no-rebuild on all-failure batches. Cursor inference has no fixed page ceiling.
- Exact next action: run `node tool/food/collect-incremental.mjs` after persisted retry eligibility; the checkpoint in `data/food/openfoodfacts/collection-state.json` rotates past failed queries and keeps their retry times. Respect OFF backoff and inspect source response summaries only. No prices/photos/credentials/Firebase/billing/UI changes; no popularity or nutrition-review claims.

## Resumed batch — 12 October 2026

At base `1a6bac2`, three sequential due queries succeeded: Egypt rice p1 (3 occurrences), Egypt pasta p1 (17), and Saudi pasta p1 (46). These produced61new unique GTIN records after duplicate/quarantine processing. Bank now has777records: EG366, SA422, overlap11; rice4, pasta61, flour4, ghee2, pulses6. It has31source archives,82quarantined occurrences,106duplicates,574with nutrition,519with core macros,649with brand. All777nutrition bases remain unreviewed. Products SHA256 `f4b83d80fb6af1438f9aa230444cee0134618de2630c467ca3285c8d74c24339`; index SHA256 `501c81398c4741508640e3c6c5475e9c252e85460cbba9079aa2e57c129bf221`.

`node --test tool/food/import.test.mjs`:5passed, including shipped-bank source/hash integrity after these additions. The scheduler advanced to job index18 and retained earlier503 backoff entries; it did not retry them. Next action: let the hourly collector resume from `collection-state.json`. No source failures in this three-request batch; no product nutrition basis was approved.

## Resumed batch — 13 October 2026

At base `b22187b`, three requests ran sequentially: Egypt condiments p1 succeeded with43 source occurrences; Saudi flour p1 and Saudi pulses p1 returned503 and were persisted with retry times. The successful page added25 unique GTINs after dedupe/quarantine. Bank now has802records: EG391, SA422; condiments59, rice4, pasta61, flour4, pulses6. Across the bank:32archives,84quarantined occurrences,122duplicates,587with nutrition,529with core macros,667with brand, and all802bases unreviewed. Products SHA256 `8397263a7bc2461606c450cce757ce20c8d3622cf3379d11b1e9533f37940006`; index SHA256 `e545923e2d000c1882ced3b8bedb06123f3b428018ac9b3ff17a73c92e7d0356`.

`node --test tool/food/import.test.mjs`:5passed, including shipped-bank source/hash integrity after the new archive. Checkpoint advanced to job index29; no repeated failed query. Resume from `data/food/openfoodfacts/collection-state.json` after recorded backoff. No nutrition basis was approved.
