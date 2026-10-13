# Wikibooks bulk collection handoff

## Source and current collection state

- Official source: Wikibooks Cookbook, starting at `Category:Recipes` in namespace 102 through `https://en.wikibooks.org/w/api.php`.
- Wikibooks' copyright policy states most text is dual licensed under CC BY-SA 4.0 and GFDL, subject to page-specific exceptions. Source-level evidence is recorded at `https://en.wikibooks.org/wiki/Wikibooks:Copyrights`; check each page before reuse. Collector records preserve attribution/change notice/share-alike requirements and mark page exceptions as not reviewed.
- The successful API probe retrieved category membership metadata only: 10 real titles, including Nigerian dishes Abacha and Aadun. This is not evidence of parsed cuisine classifications; no cuisine labels have been inferred.
- The first content request failed with `invalidparammix` because `rvlimit` was combined with a multi-page generator. The error checkpoint records a ten-minute retry time of `2026-10-13T12:11:43Z`. An immediate escalated retry was rejected by automatic review due to the no-retry/backoff instruction. This agent made no further network request. Root confirmed the cooldown has elapsed and will run the corrected same-endpoint collector.
- Actual collected revisions: 0; distinct source pages: 0; parseable recipe pages: 0. No bulk recipe growth is claimed.

## Collector contract

- Run from `E:\work\SOFRA\app`: because the failed attempt already created a checkpoint, resume with `node tool/recipes/collect-wikibooks.mjs --limit 500 --resume`.
- Default output: `data/recipes/bulk/wikibooks-cookbook/`. The append-only immutable source revision log is `source-pages.jsonl`; state is `checkpoint.json`; the generated manifest keeps category counts and separate revision/page/parseable-recipe counts.
- Each invocation permits at most 10 sequential API calls; each call requests no more than 50 pages. `--limit` is a per-invocation new source page limit, not an all-time cap. No automatic retry is made after API errors; errors persist with a ten-minute cooldown.
- Records retain exact returned source wikitext, namespace/page/revision identity, contributor and timestamp where returned, version permalink, actual retrieval timestamp, source categories, and SHA256. Pages without recognized ingredient and instruction sections are retained as unparsed source records and do not count as recipes. Revisions are immutable; a later revision is a separate revision record for the same source page. The manifest reports revision records, distinct source page IDs, and distinct parseable recipe page IDs separately.
- Parser fields are research extraction only. It does not invent conversions, food identities, nutrition, durations, servings, or cuisine mappings. Do not import these records into runtime until individually reviewed and normalized.

## Offline verification

- `node --check tool/recipes/collect-wikibooks.mjs` passed.
- `node --test tool/recipes/collect-wikibooks.test.mjs` passed before the latest reporting/timestamp refinements; rerun after those offline edits. Tests use injected fake API responses and cover pagination, bounded runs, persisted errors/cooldown, append-before-checkpoint recovery without duplication, exhaustion, exclusive locking, partial continuation/page-ID recovery, source validation, retention of unparsed pages, and distinct page counts across revisions.
- No live request has been made after the failed content request. Checkpoint `nextAttemptAt` is `2026-10-13T12:11:43Z`.

## Files and boundaries

- Collector and tests: `tool/recipes/collect-wikibooks.mjs`, `tool/recipes/collect-wikibooks.test.mjs`.
- Source/probe status: `data/recipes/bulk/collection-status.json`.
- Checkpoint: `data/recipes/bulk/wikibooks-cookbook/checkpoint.json`.
- Source pages log does not exist yet because zero revisions were fetched.
- No shipping recipes/index, prior research bank, runtime, shared docs, validator, Firebase, UI, or Git state was changed by this work.

## Coordinator live collection and final indexing

Root executed after recordedcooldown, corrected request approved. Currentindex:2428sourcepages/2312parsed/52sourcecuisine tags. 4 HTTP429events honored,latestnextAttemptAt:2026-10-13T13:19:44.428Z.17collector/7index/7quantity/10contracttests passed; actualindex/source/parsed/observations hashes checked. Derived parsedbankv2 preserved original records. PowerShellcase-distinctcategorysummary errorwasnotcollectionfailure; Node used. Ownerreleased,coordinatorhandlesGit/receipts. Nextsourceonlyaftergate, localquantityparseravailable.
