# Wikibooks bulk collection handoff

## Source and current collection state

- Official source: Wikibooks Cookbook, starting at `Category:Recipes` in namespace 102 through `https://en.wikibooks.org/w/api.php`.
- Wikibooks' copyright policy states most text is dual licensed under CC BY-SA 4.0 and GFDL, subject to page-specific exceptions. Source-level evidence is recorded at `https://en.wikibooks.org/wiki/Wikibooks:Copyrights`; check each page before reuse. Collector records preserve attribution/change notice/share-alike requirements and mark page exceptions as not reviewed.
- The successful API probe retrieved category membership metadata only: 10 real titles, including Nigerian dishes Abacha and Aadun. This is not evidence of parsed cuisine classifications; no cuisine labels have been inferred.
- The first content request failed with `invalidparammix` because `rvlimit` was combined with a multi-page generator. The error checkpoint records a ten-minute retry time of `2026-10-13T12:11:43Z`. An immediate escalated retry was rejected by automatic review due to the no-retry/backoff instruction. This agent made no further network request. Root confirmed the cooldown has elapsed and will run the corrected same-endpoint collector.
- Historical pre-collection checkpoint above is superseded by the latest snapshot below: the corpus now contains 3,616 source revisions/distinct pages. Two successful batches ran in this turn; a third stopped on HTTP 429.

## Collector contract

- Run from `E:\work\SOFRA\app`: because the failed attempt already created a checkpoint, resume with `node tool/recipes/collect-wikibooks.mjs --limit 500 --resume`.
- Default output: `data/recipes/bulk/wikibooks-cookbook/`. The append-only immutable source revision log is `source-pages.jsonl`; state is `checkpoint.json`; the generated manifest keeps category counts and separate revision/page/parseable-recipe counts.
- Each invocation permits at most 10 sequential API calls; each call requests no more than 50 pages. `--limit` is a per-invocation new source page limit, not an all-time cap. No automatic retry is made after API errors; errors persist with a ten-minute cooldown.
- Records retain exact returned source wikitext, namespace/page/revision identity, contributor and timestamp where returned, version permalink, actual retrieval timestamp, source categories, and SHA256. Pages without recognized ingredient and instruction sections are retained as unparsed source records and do not count as recipes. Revisions are immutable; a later revision is a separate revision record for the same source page. The manifest reports revision records, distinct source page IDs, and distinct parseable recipe page IDs separately.
- Parser fields are research extraction only. It does not invent conversions, food identities, nutrition, durations, servings, or cuisine mappings. Do not import these records into runtime until individually reviewed and normalized.

## Offline verification

- `node --check tool/recipes/collect-wikibooks.mjs` passed.
- Collector tests passed 17/17 before the current quantity-only task. They cover pagination, bounded runs, persisted errors/cooldown, append-before-checkpoint recovery, exhaustion, locking, partial continuation/page-ID recovery, source validation, category callback union, parser nesting, HTTP Retry-After, and two-second pacing.
- Latest source request stopped at HTTP 429 at `2026-10-13T16:18:38Z`; the checkpoint imposes `nextAttemptAt=2026-10-13T16:28:38Z`. No requests should be made before that time; root controls any future resume.

## Files and boundaries

- Collector and tests: `tool/recipes/collect-wikibooks.mjs`, `tool/recipes/collect-wikibooks.test.mjs`.
- Source/probe status: `data/recipes/bulk/collection-status.json`.
- Checkpoint: `data/recipes/bulk/wikibooks-cookbook/checkpoint.json`.
- Source records and derived index are present under `data/recipes/bulk/wikibooks-cookbook/`.
- No shipping recipes/index, prior research bank, runtime, shared docs, validator, Firebase, UI, or Git state was changed by this work.

## Coordinator live collection and final indexing

Root executed after recordedcooldown, corrected request approved. Currentindex:2428sourcepages/2312parsed/52sourcecuisine tags. 4 HTTP429events honored,latestnextAttemptAt:2026-10-13T13:19:44.428Z.17collector/7index/7quantity/10contracttests passed; actualindex/source/parsed/observations hashes checked. Derived parsedbankv2 preserved original records. PowerShellcase-distinctcategorysummary errorwasnotcollectionfailure; Node used. Ownerreleased,coordinatorhandlesGit/receipts. Nextsourceonlyaftergate, localquantityparseravailable.

## Latest bounded collection snapshot (2026-10-13)

- Pre-turn saved index: 3,116 source revisions/distinct pages, 2,981 parsed recipes, 53 source cuisine tags; quantity candidates 12,921 parsed + 13,015 unresolved (25,936 total).
- This turn: two successful 10-request batches added 500 distinct source revision records. The third batch stopped on HTTP 429. Total is 3,616 revisions/pages; rebuilt index has 3,470 parsed recipes and 53 exact source cuisine labels. The +489 parsed growth includes records gathered in the batches; source-level `isRecipe` flags are older parser metadata and count 3,382, while the builder re-parses immutable wikitext.
- Current quantity candidates: 15,066 parsed + 15,128 unresolved (30,194 total); runtime-ready count remains 0. Sample source-category page counts: Egyptian 26, Indian 146, Nigerian 55.
- Latest source gate is `2026-10-13T16:28:38Z`, source not exhausted, 50 page IDs pending. Collector lock was removed. Root controls any next request and will curate the stable snapshot; bulk collection owner released.
- Offline builder succeeded. Hash checks: no source wikitext hash failures; raw source file, parsed-bank file, and category-observation file hashes match index metadata.

## Latest resume after that snapshot

- Root authorized a new bounded resume after confirming the 16:28:38Z gate elapsed. The first invocation stopped with exit code 1 on a source response missing revision/content payload for 30 page IDs; the collector saved this error and did not retry in this run.
- Before stopping, it added 150 revision records. The refreshed index now contains 3,766 source pages, 3,610 parsed recipes, 53 source cuisine labels, 31,475 quantity rows (15,725 candidate parsed, 15,750 unresolved), and 0 runtime-ready records.
- Current checkpoint `nextAttemptAt` is `2026-10-13T16:39:31Z`; source is not exhausted and 30 page IDs remain pending. Collector lock is absent. Root owns further API attempts and must wait until the gate; do not resume from this agent.
- Offline index rebuild exited 0. Verified raw source page hashes: 0 failures; source file, parsed file, and category-observation file SHA256 values all match index metadata.


## Coordinator recovery and final source pool

Root isolated pending-request continuation and added3behavioral regressions;live3request recovery aftergate fetched30pages,actualexit0. Final3796/3640/53,sourceExhaustedtrue,pendingIDs empty,pendingRequest null. Generator cursor preserved independently.75relatedNode tests passed;identitybank8/8/3/14/0 passed. Sourcepool exhaustion requires newlicensed discovery,notbank completion. Root ownsfinalGit/receipts.
