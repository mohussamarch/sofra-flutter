# Second1000 archived-source records

Completed preparation; ownership returned to coordinator. Active checkout `E:\work\SOFRA\app`; base `44b961b1c7e1c8428d4ebe0f77efeda204080b96` (§88 delivered). Only the second pack/module/tests/these notes and the explicitly authorized small reuse change in `bulk-normalize-1000.mjs` were edited. No network, new books, UI, Firebase, billing, APK, shared manifest/pubspec/docs/queue or Git writes.

## Actual output

- Exactly1000 additional native source records,1000 exact source snapshots,8479 ingredient lines and6936 method steps.
- Already parsed source records converted1000; new source acquisitions0; translations0; culinary/runtime/nutrition approvals0. Variants remain source records, not1000 distinct dishes.
- Reader validates3640 parsed English archive records. Candidate pool2575 after excluding1064 prior archive source identities (including every first-pack1000) and one policy/template demonstration. Baseline includes all1090 previously selected records across19packs, including creator records. Selected batch has1000 distinct page/revision/permalink identities and1000 distinct normalized exact ingredient+method signatures. Semantic/cross-language duplicate review is not claimed. Exact-content rejections encountered during selected traversal0.
- Source-derived cuisine labels:Indian42,Italian11,947records untagged. Existing balanced first1000 consumed most recognized exact cuisine-category evidence in this archive; the converter does not guess labels for remaining recipes. No claim of fresh cuisine expansion. Exact source/API/literal categories remain in pinned source/index evidence; category labels do not establish approved cuisine origin or suitability.
- All8479 accepted numeric amounts/units remainnull. All1000 structured yields/times unknown; food bindings, scaling, inclusion/optionality and family/method assignments remain unreviewed/unknown. Exact ingredient/method text and raw quantity parser candidates are retained. English `name`/`text` fields preserved, Arabic fieldsnull, explicit sourceLanguage=en/translationStatus=not-translated.

Output `data/recipes/curated-local/bulk-2000-20261015/normalized-recipes.json`; SHA256 `1d65a70f09930fd5b6e375069a6869080d424d3868f43dc55c9e1ea0c82905c7`. Detailed report `conversion-report.json`; frozen original19pack manifest `baseline-manifest.json`, SHA256 `584f7a80f91afdb2e5814477e4c5e6c87760e715ebd5cac7fde4d0cf858f5804` anchored in the runner. Folder contains1003 output files:pack/report/baseline and1000snapshots.

Snapshots preserve original source-record objects/wikitext, authoritative parsed extraction, source archive evidence hashes, immutable revision URLs/timestamps, licence objects and hashes, exact line review targets and snapshot-byte hashes. Attribution/change/share-alike notices retained; page-specific licence exceptions remain unreviewed. Source/format integrity checks do not constitute culinary review.

## Reuse/API

`tool/recipes/bulk-normalize-1000.mjs` gains only a third options argument to shared `buildBatch(inputs,count=1000,{outputFolder=originalFolder})`. It validates an immediate safe child under `data/recipes/curated-local/`, derives all output paths from it, and guards a supplied baseline against the caller's input-manifest SHA for nondefault folders. The original default API, first pack/report/baseline/snapshot bytes and hashes are preserved. No copied normalization implementation.

`tool/recipes/bulk-normalize-2000.mjs` reuses archive reading, baseline pin validation and conversion. Exports `folder`, `packFile`, `baselineFile`, `baselineManifestSha256`, `selectedManifestBaseline`, `loadInputs`, `buildSecondBatch` and `run({check=false})`. CLI build: `node tool/recipes/bulk-normalize-2000.mjs`; drift check:append `--check`. `buildSecondBatch` returns `{pack,report,files}`; the report schema is identical to the first pack with second-pack values. Current19pack baseline must contain exactly1090 records and all original pins must remain unchanged. Own registration and later unrelated packs cannot change this batch's baseline/selection; later batches own dedup against this immutable record set.

## Actual verification

`node --test tool/recipes/bulk-normalize-1000.test.mjs tool/recipes/bulk-normalize-2000.test.mjs`:12/12pass (unchanged original6 plus6focused new tests). New checks cover exact1000/stored pack+report and first pack hash, all1000 source snapshots/provenance and ingredient targets, exclusion of all1090 prior records/every first1000 identity and signature, own/later manifest registration stability plus baseline drift rejection, honest language/unknowns/category evidence, source text/revision/licence drift and unsafe output folders. Six original tests independently revalidate every first1000 snapshot as well as exact first pack bytes.

`node tool/recipes/bulk-normalize-1000.mjs --check`:exit0. First pack SHA remains `26d6ca3ebf32b88f46e3573fdaadf8d5f959e4b230203a9e4b90be783981be02`; all1003 first-unit outputs byte-identical.

`node tool/recipes/bulk-normalize-2000.mjs --check`:exit0; all1003 second-unit outputs exactly reproduce. These commands ran before coordinator registration; tests explicitly simulate own and later registrations. Coordinator must rerun both checks after actual20pack registration.

Native reader uses `nameAr ?? name`/`textAr ?? text`; prepared records retain that existing schema. No Flutter registration/loading test was performed by this worker. Unknown optionality remainsnull in source rows; the native convenience boolean defaultsfalse without implying approval. Readable source records do not become planning/nutrition-approved recipes.

Exact next action:coordinator registers second pack and1000 snapshots in manifest/pubspec, preserves prior19pack pins, runs native library loading checks plus both converters' `--check`, then consolidates shared handoff/commit/push. No third batch started. All owned file rights returned; no processes started/stopped.
