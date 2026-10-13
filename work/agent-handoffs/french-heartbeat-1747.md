# French Wikibooks collection heartbeat — 2026-10-13 17:50–17:52 UTC

## Outcome

Resumed the existing French Wikibooks collector after its prior gate expired. Ran two sequential bounded invocations of `node tool/recipes/collect-wikibooks-fr.mjs --requests 10 --resume`.

- Batch 1 exited 0 after 10 API requests. It added 107 source-page revision records and 81 parsed research recipes.
- Batch 2 exited 1 after 2 successful requests, then `French MediaWiki HTTP 429`. Stopped immediately; no retry or alternate endpoint was attempted.
- Collector lock cleanup verified: no lock remains and no matching collector process is running.
- The checkpoint records `nextAttemptAt: 2026-10-13T18:01:42.279Z` (10-minute backoff from HTTP 429 at `2026-10-13T17:51:42.279Z`). Source listing remains incomplete; 28 pending page IDs are checkpointed.

## Corpus change

| Metric | Before this heartbeat | After | Change |
|---|---:|---:|---:|
| Distinct source page/revision records | 625 | 752 | +127 |
| Parseable research recipe records | 450 | 540 | +90 |
| Ingredient source rows | 2,862 | 3,557 | +695 |
| Ordered step rows | 2,591 | 3,210 | +619 |
| Distinct observed source category labels across parsed records | 127 | 160 | +33 |
| Ingredient rows with numeric `amount` | 0 | 0 | 0 |
| Ingredient rows with canonical `unit` | 0 | 0 | 0 |
| Runtime-ready records | 0 | 0 | 0 |
| Cumulative API requests | 53 | 65 | +12 |

The 90 appended recipes contain 579 ingredient rows and 619 steps. Source category labels are preserved as observed metadata; they are not normalized into cuisine assertions. Example observed labels include `Catégorie:Cuisine belge`, `Catégorie:Cuisine française`, `Catégorie:Cuisine espagnole`, and broad categories such as vegetarian, desserts, drinks, and soups. The existing manifest did not contain category or quantity aggregates; baseline category/quantity counts above were computed offline from the first 450 entries of the append-only parsed JSONL. No amount, unit, nutrition, yield, or runtime readiness was inferred.

## Integrity and provenance

The verified site-level source policy is CC BY-SA 4.0, language `fr`, namespace 0, prefix `Livre de cuisine/`; per-page exceptions remain unreviewed. Raw source pages and parser output remain in their source-specific collection folder, separate from English Wikibooks data and shipping/runtime recipe data.

- `data/recipes/bulk/fr-wikibooks-cuisine/source-pages.jsonl`: SHA-256 `403bbb601507e5aa1c6e02fd9c8ae10dae7f346b92330e5feb7600edead09a56`; matches manifest.
- `data/recipes/bulk/fr-wikibooks-cuisine/parsed-recipes.jsonl`: SHA-256 `43041d517335e358063b5b3bde118526f74a2e03bead9fea8847e6d659837622`; matches manifest.
- Latest `lastRunApiRequests`: 2 (batch stopped on 429); `cumulativeApiRequests`: 65.
- Latest successful retrieval: `2026-10-13T17:51:20.840Z`.

## Next step

After `2026-10-13T18:01:42.279Z`, a later authorized run can resume from the persisted listing continuation/checkpoint. Continue with bounded requests and stop on the first failure or new backoff. Do not reset the cursor or alter the raw archived pages.
