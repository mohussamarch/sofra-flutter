# French Wikibooks collection heartbeat — 2026-10-13 18:03–18:05 UTC

## Outcome

Resumed the French Wikibooks collector after its recorded 18:01:42.279Z gate. Two sequential bounded invocations of `node tool/recipes/collect-wikibooks-fr.mjs --requests 10 --resume` were attempted.

- Batch 1 exited 0 after 10 API requests. It added 122 source-page revision records and 81 parseable research recipes.
- Batch 2 exited 1 after 2 requests with `French MediaWiki HTTP 429`. Stopped immediately; no retry or alternate endpoint was attempted.
- Latest 429 time: `2026-10-13T18:04:40.525Z`; checkpoint `nextAttemptAt`: `2026-10-13T18:14:40.525Z`.
- Source listing is not exhausted. The checkpoint has 49 pending page IDs and a listing continuation.
- Lock cleanup verified: no lock remains and no matching collector process is running.
- Usage after batch 2: 72% primary, 40% weekly; ordinary use allowed. Stopping here due to source backoff.

## Corpus snapshot

| Metric | Before this heartbeat | After | Manifest difference |
|---|---:|---:|---:|
| Distinct source page/revision records | 752 | 874 | +122 |
| Parseable research recipe records | 540 | 621 | +81 |
| Ingredient rows (manifest) | 3,557 | 4,090 | +533 |
| Ordered step rows (manifest) | 3,210 | 3,794 | +584 |
| Cumulative API requests | 65 | 77 | +12 |
| Numeric `amount` values in current parsed rows | — | 0 | — |
| Canonical `unit` values in current parsed rows | — | 0 | — |
| Runtime-ready records | 0 | 0 | 0 |

The first 10-request batch added 122 pages / 81 parsed recipes. The second invocation made 2 requests before the 429 and added no further page/recipe records. Current parsed JSONL contains 4,090 ingredient rows and 3,794 steps by direct traversal; all ingredient amount/unit fields remain null. No nutrition, conversions, yields, or runtime readiness were inferred.

## Verified count and record integrity

Counts below use the root-verified snapshots at commit `2d184e9` (625 raw pages / 450 parsed recipes) and commit `5a60180` (752 raw pages / 540 parsed recipes), plus the current working corpus (874 raw pages / 621 parsed recipes). Distinct category labels are counted separately for all raw source pages and for parsed recipe records; labels are source metadata only and are not cuisine assignments.

| Snapshot | Raw pages: distinct category labels | Parsed recipes: distinct category labels | Parsed ingredient rows | Parsed steps |
|---|---:|---:|---:|---:|
| `2d184e9` | 180 / 625 pages | 142 / 450 recipes | — | — |
| `5a60180` | 199 / 752 pages | 163 / 540 recipes | 3,557 | 3,210 |
| Current | 208 / 874 pages | 165 / 621 recipes | 4,090 | 3,794 |
| Change from `5a60180` | +9 labels / +122 pages | +2 labels / +81 recipes | +533 | +584 |

The earlier helper reports of 127→160, 133→162 category labels, and 3,538 ingredient rows / 3,167 steps in the previous parsed snapshot were incorrect and are superseded by these verified counts. They did not indicate changes to source records.

The first 752 raw source-page JSONL records remain byte-for-byte unchanged: prefix SHA-256 `403bbb601507e5aa1c6e02fd9c8ae10dae7f346b92330e5feb7600edead09a56`, matching the prior full raw-file hash.

The parsed JSONL is ordered by source page ID, so a byte-prefix comparison is not an invariant when new lower IDs are inserted. Compared the previous committed parsed records at `5a60180` against the current file by `recordId` and deep JSON content: 540 prior records, 621 current records, 0 prior IDs missing, 0 shared records changed, and 81 new IDs. The current full raw and parsed hashes match the manifest.
## Provenance and hashes

Source: French Wikibooks (`fr`), namespace 0, prefix `Livre de cuisine/`; siteinfo reports CC BY-SA 4.0 at https://creativecommons.org/licenses/by-sa/4.0/deed.fr. Page-specific exceptions remain unreviewed. This source remains isolated from English collection and shipping/runtime data.

- Raw `source-pages.jsonl`: manifest SHA-256 `a9f2175844872e7c7d0bb06d365c045a4f90a3da0492f3527969cf75844407a0`; actual file hash matches.
- Parsed `parsed-recipes.jsonl`: manifest SHA-256 `e5a5f100207ebf831588597c0297e5d12ccd2f84ecf96344d0c457006aaa8a1d`; actual file hash matches.
- Current run API requests: 2 (stopped on 429); cumulative requests: 77.
- Last successful retrieval: `2026-10-13T18:04:20.794Z`.

## Next step

A later authorized run may resume after `2026-10-13T18:14:40.525Z` using the persisted checkpoint. Keep the source cursor and raw records; stop on the first failure/backoff. Parsed records are sorted by page ID; future integrity comparisons should continue using recordId and deep content, while raw prefix bytes remain stable.
