# Recipe identity proposals and authoritative research snapshots

This is an offline research pipeline. Eight source lines in eight recipes now have14 identity candidates from3USDA records. Every proposal is unreviewed. Candidate presence is not accepted identity, exact retail product, food form, measured quantity, clinical suitability or complete nutrition. Runtime approval count remains zero.

## Files and flow

1. `usda-review-reader.mjs`: loads requested raw USDA snapshots only, checks manifest/index/shard byte hashes, sourceCC0licence, ID/FDC ID/version/name/dataset consistency. Archive and local-file evidence remain separate. The actual reader was validated across all8156source records/32shards. Unknown fields and raw nutrient rows are not transformed.
2. `recipe-review-reader.mjs`: verifies original-source/parsed/category-observation hashes, invokes the existing raw-source validator and deterministic parser, then compares the entire index core and re-extracted recipes. Changing the parsed file and its outer hash alone fails.
3. `review-target.mjs`: pins exact recipe source/revision/parser/line/full-derived snapshot and food source version/hash. Strict proposal fields prohibit embedded selection, quantity or nutrition approval.
4. `validate-identity-bank.mjs`: validates recipe attribution/licence and food evidence against freshly loaded sources. The CLI checks the collector lock before reading the current bank. It reads sources only; no bindings are applied.

Current data: [first-review.json](../data/recipes/identity-proposals/first-review.json). Six explicit granulated/white-sugar lines propose separate Foundation and SR Legacy references; two explicit table-salt lines propose a generic reference. These are recorded interpretations with unresolved issues, not factual local-brand equivalence. The report field `unresolvedCount` means no candidates, not approved identities; all8remain unreviewed.

```powershell
node tool/recipes/validate-identity-bank.mjs
```

## Trust and integration limits

Hashes establish local consistency against the trusted checkout. Manifests and source archives are not independently signed/authenticated by this tooling. A coordinated replacement of every source and hash could still pass. Source-page licence exceptions remain unreviewed. Readers are not atomic with a concurrent indexer: stop collection/indexing first; mixed data should fail hashes/re-extraction.

The proposed food fingerprint is of the raw USDA research row, not the transformed Dart `FoodRecord`. Future runtime admission must separately accept identity/form/quantity/preparation, preserve raw-source evidence and produce the runtime snapshot. No source estimates, volume conversions, target choices or clinical rules are silently applied. Original54recipes and existing runtime review flow remain unchanged.

## Verification and next step

75relatedNode tests passed, including7USDA reader,6bank validator,5recipe-source reader and3pending-request regressions. Initial new-module tests failed for missing modules; one fixture syntax error and shared-object alias were corrected. Three collector behavioral regressions failed before the pending-cursor implementation, then passed. Live collector recovery fetched30pending pages and exhausted this source category in3requests.

Next: extend explicit ingredient/alternative proposals, retain unknown measurements and provenance, then implement separate runtime acceptance/import and private drafts from scratch. Curation is not automatic nutrition readiness.

## Second actual research batch

[spices-leavening-review.json](../data/recipes/identity-proposals/spices-leavening-review.json) adds8explicit interpretations/8recipes/8candidate references/2rawUSDA records. Combined16targets/16recipes/22references/5foods,all unreviewed;firstbank remains unchanged. Source-specific soaking/rinsing/draining evidence identifies unknown retained baking-soda amount/sodium; no all-or-zero assumption or automatic clinical/retention rule. Existing validator actual8/8/2/8/0passed;source/fullsnapshot guards preserve method evidence. See identity-proposals/README.md for command and limitations.
