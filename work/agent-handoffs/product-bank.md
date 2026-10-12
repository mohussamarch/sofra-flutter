# Product bank agent handoff

## Quick resume

- Canonical checkout only: `E:\work\SOFRA\app`; base GitHub/main `bb1034d3b6056cdccde7f1c2f298368ef71e8d25`.
- Completed source-separated OFF packaged bank687validnamedGTINs; index and transport final.
- Every product nutrition basis remains unknown/review-required; no safe/allergen-free inference.
- Node checks5/5pass including every shipped record, source value and file hashes.
- Next: coordinator's FoodRepository adapter/source review. No more scraping or broad expansion in this batch.

## Objective and changes

User authorized parallel agents to build complete nutritional data architecture and collect a broad real packaged product bank, without interfaces. This agent owned only `data/food/`, `tool/food/`, `docs/PRODUCT-DATA.md` and this handoff. No shared service/pubspec/STATUS/HANDOFF edits, no commit/push.

- `tool/food/import.mjs`: checksum/name validation; source archive preservation; source/market/license-qualified normalized transport; source nutrient modifiers; split as-sold/prepared; explicit unknown units/basis; missing data and quality flags; duplicate latest-revision selection without nutrient mixing; deterministic products/index output and SHA256 manifest.
- `tool/food/import.test.mjs`: GTIN/unit/modifier/unknown/prepared/allergen invariants, reproducible rebuild/latest-revision selection, full bank/archive source-value and attribution/hash verification.
- `data/food/README.md`: dataset license/attribution separation.
- `data/food/openfoodfacts/`:27raw source response archives plus products.jsonl, index.json, manifest, quarantine, duplicate and failed-request audits.
- `docs/PRODUCT-DATA.md`: real coverage counts, transport and basis contract, limitations, licenses, commands and exact next actions.

## Source findings and decisions

Official OFFv2 returned503. Official v1cgi search worked on a subset of requests. Identified Sofra User-Agent, sequential>=8second waits, no retry loops. Fetched40bounded category/market queries across20categories;25succeeded,15HTTP503failures logged. Initial Egypt pages1and2supplied200additional source occurrences; initial page3failed and was not retried. No user account/APIkeys, no Firebase, no prices/photos.

687valid named product records: EG320/SA374(overlap7),510with nutrients,461with core macro fields,329with ingredient text,179declared allergens,579known brands/108missing. All20food groups nonempty; pasta1/rice3/flour3/ghee2/pulses4are thin.75quarantined occurrences:68missing names and7invalid GTINs.92duplicate occurrences audited. Valid checksum is not proof of GS1 assignment or authentic/current package label. Brand names include source entries Almarai/Juhayna/Cadbury/Nestlé/Heinz/Pepsi but market popularity was not independently verified.

OFF`_100g`means100g OR100ml depending on food. `nutrition_data_per`does not resolve this. Package unit is a hint only; all687basis.unit=null,requiresLabelReview=true,verification=unreviewed. Core adapter must preserve unknownBasis, modifiers and missing nutrient values. OFFsodiumg requires explicit×1000 to canonicalmg. Allergen absent=unknown; traces separate from contains; no freefrom claims. Source quality/errors and consistency flags retained. Baby category is catalogue-only, no recommendation logic.

ODbL1.0/DbCL1.0 OFF-derived subset remains separate from USDA and application private profiles. Licenses/attribution are documented from primary official sources. The collection is a broad reproducible seed, not a complete or verified popular-market catalogue. Original selected source values are in tracked raw archives.

## Verification actually run

- `node --check E:\work\SOFRA\app\tool\food\import.mjs`:pass.
- `node --test ...\tool\food\import.test.mjs` with `SOFRA_FOOD_BANK=E:/work/SOFRA/app/data/food/openfoodfacts`:5passed/0failed.
- Actual shipped-bank check compared every normalized nutrient to the cited original archive; every archive/products/index hash and productGTIN/uniqueness/source attribution matched.
- Synthetic fixtures stay in OS temporary test archives, never in shipped data.
- No Flutter/UI/device tests claimed by this agent; coordinator owns integration verification.

## Final identifiers and limits

- productsSHA256:`6535c9c7630be5a95b035bd3c4a497cd35ba12632979a22bc679c7bd7a36e76b`.
- indexSHA256:`ee017d2ea78a04458b0e5d7b880ca58abf17747044e039f7f6e2768a7092394f`.
- Network importer finished/stopped. No preview server changed; preexisting8766ownership unchanged by this agent.
- Firebase/account/rules/billing changes:none. APK built:none. Images/audio generated:none. User design decisions unchanged.
- Coordinator must consolidate handoffs, integrate adapter, run meaningful gates, commit/pushmain and record final hash/root receipts; this agent intentionally did not commit concurrently.
