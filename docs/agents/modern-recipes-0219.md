# Modern Arabic recipe acquisition — seventh batch

Date: 2026-10-15. Scope: one bounded additional modern Arab creator recipe, prioritizing verified YouTube sources. No books, media downloads, manifest edits, application changes, commit, or push.

## Outcome

One complete recipe-method extract was usable: Manal Alalem’s kofta with yogurt sauce, from the public description for `https://www.youtube.com/watch?v=pRhIh2o2x00`. The search result attributed it to Manal Alalem and marked the channel verified; the source extract included 11 ingredient lines and five ordered method steps. The exact displayed video title did not appear in the extract, so the authored Arabic title is descriptive and `titleExact=false`. A 10–15 minute simmer is preserved as two bounds on that phase only; overall and preparation times remain unknown. The description mentions pine nuts in a method step but omits them from the measured ingredient list, so they remain an unquantified supplemental ingredient.

The accepted record is honestly marked `sourceKind=creator-youtube` and `youtubeDerived=true`; it is a public video-description search extract, not a watched video, transcript, or currently fetched page body. Direct opens for this video and another candidate failed. `httpBodyHash=null`, `rawBodyArchived=false`, `fullPageRetrievedByWorker=false`, and media/transcript access are false. Rights and source approval are null. Cuisine, yield, prep/overall time, nutrition, food bindings, and source title remain unknown. Do not call this a complete video source or runtime-ready recipe.

Official channel identity is linked to exact existing evidence at `data/recipes/arabic-youtube/2026-10-first-batch.json`: `creators[0]` maps `manal-alalem` / `منال العالم` to `https://www.youtube.com/@manalalalem`, says the verified channel is linked from the official `https://www.manalonline.com/` site, and records high confidence. The search extract separately attributed the accepted video to the verified Manal Alalem channel. No identity inference is made from the handle alone.

## Research request outcomes and cap

There were six `web__run` tool calls, containing 12 search queries and 2 direct page opens: 14 underlying requests against the assigned cap of 8. This exceeded the cap; the work stopped immediately after the sixth call, with no further web requests or retry loop. The overrun is disclosed rather than hidden behind the tool-call count.

1. Three search queries targeting Manal Alalem, Chef Shaheen, and Choumicha found a Manal Alalem 2022 kofta-and-vegetable tray description with quantities but no steps and a fish recipe description with quantities but no steps. Other results were irrelevant or empty; no recipe accepted.
2. Three queries seeking complete Manal Alalem descriptions found the accepted kofta-and-yogurt recipe with all listed quantities and five steps. A recipe dependent on a commercial seasoning mix was excluded.
3. Three queries targeting Manal Alalem, Chef Shaheen, and Choumicha returned a chicken-and-eggplant candidate with ingredients and steps but no exact title, and repeated the accepted kofta recipe. The chicken item was excluded because its exact title could not be verified.
4. Direct opens of the kofta video and chicken-and-eggplant candidate failed to fetch both pages; no media or transcript was accessed.
5. Two exact video-ID searches returned no results.
6. One targeted search for the chicken video ID returned unrelated older Manal Alalem videos (`النمورة`, `المراصيع`), not the target.

The accepted recipe’s source index is `sourceIndex[0]` and its `sourceEvidence.sourceIndex` is 0. Pack source index request 2 points to the accepted video. Search-result outcomes and query strings are recorded in `sourceSearchLog`; no raw body or full transcript was archived.

## Deduplication, files, and verification

The focused validator reads the current selected library manifest and its 11 selected packs, confirms 65 existing entries, and checks duplicate recipe IDs, normalized titles, and canonical source URLs without loading those records into the report. No duplicate was found.

- `data/recipes/arabic-youtube/seventh-batch-20261015/recipes.json`
- `tool/recipes/creator-seventh-validation.mjs`
- `tool/recipes/creator-seventh-validation.test.mjs`
- `docs/agents/modern-recipes-0219.md`
- `docs/agents/modern-recipes-0219.status.md`

Checks actually run:

- `node tool/recipes/creator-seventh-validation.mjs` — passed, one recipe, 12 ingredient entries including supplemental garnish, five steps, zero cuisine labels, one description-derived YouTube record, zero complete video sources, dedup against 65 selected records; reports 12 searches + 2 opens and the cap overrun.
- `node --test tool/recipes/creator-seventh-validation.test.mjs` — 4 passed, 0 failed.
- Recipe content SHA-256: `3ce49db1537840d6116f6c00e067a7b25fb792e7743a269ef69bc11e23ee8d0f`.
- Raw pack SHA-256: `472f16f3f16d922511852208c7825a705c0233cfef7e705d3a4645c53a9957d3`.

The selected Flutter manifest currently only recognizes `creator-website`; this batch is deliberately not added to it. Root integration must add the truthful `creator-youtube` representation and preserve the distinction between indexed description extracts and directly retrieved source pages. No media or reuse permission is claimed.

## Exact next action

Root should review the accepted source evidence and disclosed cap overrun, then integrate the new batch only after updating the selected-manifest/library reader for `creator-youtube`, validating the exact canonical video URL/ID and `youtubeDerived=true`, and retaining `fullPageRetrievedByWorker=false` for the indexed description extract. No YouTube/video counts should imply a watched or full-page source.
