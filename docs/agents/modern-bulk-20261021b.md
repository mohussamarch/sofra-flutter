# Common Pile Foodista bulk acquisition

## Source and license evidence

- Foodista terms: https://www.foodista.com/terms. The current Content License grants CC BY 4.0.
- Public republisher: https://huggingface.co/datasets/common-pile/foodista. Its card identifies Foodista and CC BY; it warns generally that metadata can be inaccurate. That broad caveat is preserved as a limitation, not treated as evidence of a specific row violation.
- Pinned dataset revision: `4fd174745182885bea01d47c8ba71b1946375898`. Collection used only cached text shards `00000_foodista.jsonl.gz` and `00003_foodista.jsonl.gz`; no images or other media were acquired.
- Each retained row keeps its own historical CC BY 3.0 declaration, URI, source URL, author, source date when present, source-record hash, source-text hash, and shard hash. Rows are not relabeled under the current 4.0 terms. No archived per-page license capture was available.
- Direct Foodista HTML was not acquired; an earlier request returned a Vercel checkpoint, and the route was not retried or bypassed. The republisher revision timestamp is unknown. One earlier shard request outcome is unknown; final batch regeneration used local cached files only.

## Parser correction and extraction

Repeated `Ingredients`/`Preparation` labels inside the active section are treated as formatting, so their following text remains captured. The parser now stops at standalone terminal headings only. This fixes lines such as `About 10 black pitted olives`, which were previously mistaken for an `About` section. The audit's 18 previously flagged records were re-read from cached source: all 18 now have exact section coverage; the 51901 Tom Colicchio row is excluded by explicit named attribution. The 58836 salami rolls record now retains 10 ingredient-section lines and its method.

Regression tests cover repeated headings and subheadings, terminal `Tools`/`Comments`/`About`, the `About 10` ingredient edge case, link-placeholder rejection, BOM handling, short valid preparation actions, and explicit third-party attribution. `node --test tool/recipes/collect-modern-bulk-20261021b.test.mjs` passes 8/8.

Every accepted record passed normalized equality between extracted fields and captured source ingredient/method sections. Text screens reject link/ad/placeholders, methods without an evident preparation action, blog/article titles, baked-item titles missing a cooking or setting action, and explicit third-party source/copyright cues. This does not establish ingredient completeness, culinary quality, cookability, or safety.

English source text is preserved; no quantities, units, times, yield, cuisine, nutrition, translations, or food bindings are inferred. Records remain `needs-review`, `runtimeReady: false`, `nutrition: null`, and not kitchen-tested. `recipeKind` remains `unknown` or `component-review`; flags are for human review only.

## Frozen collection

- 10,000 records in ten packs of 1,000, with 10,000 referenced source snapshots.
- All 10,000 snapshots and raw source text hashes verify; there are no missing or stale snapshot JSON files.
- All 10,000 accepted records have exact ingredient and method section coverage. All 18 prior audit rows were retested and pass coverage.
- Across the ten new packs: 10,000 unique canonical URLs, 10,000 unique normalized ingredient/method content keys, and no duplicates against the external baseline or earlier new packs.
- The 28 external manifest packs were hash-checked before collection (5,648 records; earlier 5,545 historical records plus a separate 103-record Manal pack). Audit found one internal normalized-content duplicate and 5,062 repeated canonical-URL references inside the existing baseline, but no new-vs-baseline collision.
- Accepted rows with explicit rights-source conflict cues: 0. The refreshed content-free rejection ledger contains 822 ID/URL/hash/reason entries and no accepted record IDs.
- Source dates range from 2009-11-30 to 2024-04-11; these are archived Foodista records, not newly authored recipes from collection time.
- First pack has 9,918 ingredient lines and 1,041 method blocks. The full set has 97,436 ingredient lines and 10,267 method blocks.
- Component-review / unknown counts: 6,182 / 3,818.

Final audit summary: `data/recipes/modern-scale-20261021b-bulk/final-audit.json`.

| Batch | Path | SHA-256 |
|---:|---|---|
| 1 | `data/recipes/curated-local/foodista-scale-20261021b/normalized-recipes.json` | `0ed49edd177ab2dfbcf8de777b6bb412959b6415c2de9b183f5f2bca46d5aaf8` |
| 2 | `data/recipes/curated-local/foodista-scale-20261021b/batches/batch-0002/normalized-recipes.json` | `cf2a473bb4d68e28c222bde2598fc3038314d761233c47c5d6c84da6b5631dfa` |
| 3 | `data/recipes/curated-local/foodista-scale-20261021b/batches/batch-0003/normalized-recipes.json` | `fa302021636880c3a8201fb5c392b9cca49184eaa829abecaa52e0077fdd0724` |
| 4 | `data/recipes/curated-local/foodista-scale-20261021b/batches/batch-0004/normalized-recipes.json` | `30da33356986ce0f7f01982c311f6b3f3cf8d30889b022e1ec62691bef62b767` |
| 5 | `data/recipes/curated-local/foodista-scale-20261021b/batches/batch-0005/normalized-recipes.json` | `fd1204ee65ff3a93d11dbb66b3b44410215d4203210da06c93eeba042b8c21c4` |
| 6 | `data/recipes/curated-local/foodista-scale-20261021b/batches/batch-0006/normalized-recipes.json` | `fc574248a992d2b4c2a2d6d77e5cce13ba1bd98c441b244dad2b410064bab0a7` |
| 7 | `data/recipes/curated-local/foodista-scale-20261021b/batches/batch-0007/normalized-recipes.json` | `367ceed7ccd150461374b0123158bb762d1fd6f40348973708dbc2a91af58a2b` |
| 8 | `data/recipes/curated-local/foodista-scale-20261021b/batches/batch-0008/normalized-recipes.json` | `a5a1a44480b7fa55080d52ca761c21ebabfd1af2d9895ab7a41af2ab20045c95` |
| 9 | `data/recipes/curated-local/foodista-scale-20261021b/batches/batch-0009/normalized-recipes.json` | `906aa2354c5fcbe8430cc0cfadf79257d6cc93e809330978c347bffff435a350` |
| 10 | `data/recipes/curated-local/foodista-scale-20261021b/batches/batch-0010/normalized-recipes.json` | `387761ff22aff93475dade6c2ea00eb8ad23d1fba17a7e77e8afd76fc19d72ea` |

## Request and file records

- The final ten 1,000-record packs were regenerated using local cache only; no network request occurred during regeneration.
- The request history records 13 known prior logical requests and one attempt with an unknown result. Underlying redirect/hop counts for tool-mediated requests are not fully observable.
- Cache and checkpoints are in `data/recipes/modern-scale-20261021b-bulk/`; the scoped collector is `tool/recipes/collect-modern-bulk-20261021b.mjs` with focused tests alongside it.
- The shared manifest/pubspec were not edited by this collection task; parent handles integration.
