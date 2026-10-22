# BasedCooking catalog extension — 2026-10-22

## Scope

Prepared 35 Arabic catalog candidates from the locally cached BasedCooking snapshot pack at revision `9d4a31a040eedd61e4fb608cb0c114ff9a7c4dd2`. No network, source-pack edits, shared catalog/index edits or Git operations were performed.

## Acceptance rules

- Compared candidates against reviewed catalog records and prior candidate chunks by source slug/URL and names before drafting.
- Excluded known held/rightshold sources and recipes with unresolved source conflicts. `hummus` was held because source-list and method baking-soda amounts disagree.
- Preserved original ingredient units and method facts. Source-list mappings use actual indices; method-derived ingredients carry a null source index and exact evidence text in provenance.
- Unknown/ranged amounts, servings and durations remain null. Country labels follow source tags or explicit description evidence; otherwise cuisine is `عالمي متنوع`.
- Each recipe row has `metadataPolicy: source-unknowns-v1`; notes include source URL, revision and snapshot SHA. Measured rows have `display: null`.

## Frozen chunks

Staged under `based-20261022/`:

- `chunk-001.json` + `chunk-001.provenance.json`: 10 recipes.
- `chunk-002.json` + `chunk-002.provenance.json`: 10 recipes.
- `chunk-003.json` + `chunk-003.provenance.json`: 10 recipes.
- `chunk-004.json` + `chunk-004.provenance.json`: 5 recipes.

The E: destination is outside this worker's writable sandbox. The coordinator must copy these eight files into `data/recipes/catalog-650-20261021/based-20261022/` and run application schema, semantic duplicate and integration checks. Source paths and snapshot hashes are included for all rows.

Coordinator closure: eight frozen source files copied into the named E folder, all35accepted after643/1479source consistency checks; final657/63 and356Flutter gate passed.
