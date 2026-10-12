# Packaged food bank — source and usage contract

Canonical checkout: `E:\work\SOFRA\app`. This bank is a source-separated, unreviewed seed of real packaged product records, not a complete food market catalogue or a verified ranking of popular products. Product names, market tags and nutrient values are community supplied by Open Food Facts (OFF). No source values were invented. No current prices, photos, medical recommendations or baby-feeding recommendations were collected.

## Current bounded collection —12October2026

687named records with valid GTIN length/checksum; Egypt320, Saudi374, overlap7. All20category groups below have at least one record. Nutrition is present for510products,461have energy/protein/carbohydrate/fat fields,329have ingredient text,179have declared allergen tags,579have source brands. Missing data are explicit, including108missingbrands. All687nutrition bases require review; none is approved as an exact calculator input by this bank alone.

27source archives include two initial100-record Egypt pages and25successful category/market responses.15of40bounded category queries returned503, recorded without automatic retries.75source occurrences were quarantined (68missingnames,7invalidGTINs);92duplicate occurrences were audited. These are occurrence counts, not extra usable products. Raw archives total2,414,882bytes. The manifest is the machine-readable authority for counts/hashes.

| Category | Records |
| --- | ---: |
| Sweets / chocolate / biscuits / salty snacks |48 /24 /119 /13|
| Dairy / oils / ghee |171 /31 /2|
| Rice / pasta / flour / pulses |3 /1 /3 /4|
| Canned fish / meat / canned vegetables |15 /14 /9|
| Condiments / spices |34 /25|
| Beverages / frozen / bakery / baby |122 /13 /42 /9|

Groups overlap. Rice, pasta, flour, ghee and pulses have especially limited coverage; they need sourced local expansion. Market availability and popularity were not independently verified.

## Files

- `data/food/openfoodfacts/index.json`: compact product lookup (`schemaVersion`, products with id/barcode/name/brands/markets/categories).
- `products.jsonl`: one normalized source record per valid named GTIN. Leading zeroes remain intact. The primary key is `off:<barcode>`; different package barcodes are different records.
- `raw/*.json`: field-selected original OFF responses, query URL, query inputs, retrieval time and source count. Full source nutrient values and ingredient/allergen text remain here.
- `manifest.json`: counts, category/market coverage, archive and derived file SHA256 hashes. Market counts overlap when OFF lists both countries.
- `quarantine.json`: rejected occurrences (invalid checksum/length or missing name), never silently usable for barcode matching.
- `duplicates.json`: duplicate source occurrence audit; newest OFF revision is retained as a whole. Nutrients from different revisions are never blended.
- `fetch-failures.json`: explicit requests that failed in the latest collection pass. A failed request is neither an empty market nor a retry claim.
- `tool/food/import.mjs`: reproducible parser, validator and public importer. No credentials or dependency packages.
- `tool/food/import.test.mjs`: parser invariants and full shipped-bank integrity/source-value checks.

## Critical interpretation rules

**Nutrition basis stays unknown until label review.** OFF `_100g` keys mean per100g for solids OR per100ml for liquids. `nutrition_data_per` describes entered values, often `100g` or `serving`; it is not sufficient to resolve liquid normalization. We retain a `packageUnitHint` from the source package, but never treat it as an approved calculation basis. Every record has `basis.unit:null`, `requiresLabelReview:true` and `quality.verification:unreviewed`. The backend must surface an unknown-basis gap unless a separate sourced review explicitly approves mass or volume. No implicit density or gram/millilitre conversion.

`asSold` and `prepared` are separate. Never add them together or treat milk-added prepared cocoa powder as plain powder. OFF's normalized fields have standard units (most mass nutrients in grams; energy in kcal/kJ); the entered `*_unit` can describe the label input rather than normalized values. Keep nutrient modifiers (`<`, `>`, `~`) and do not turn a bound into an exact observation. Sodium grams require an explicit ×1000 conversion if the app schema uses milligrams. Missing nutrients remain missing, not zero. Unsupported/invalid normalized values remain in the raw archive; invalid, negative or implausible mass values are flagged and not exposed as usable nutrients.

Source quality errors and our energy/sugar/fat consistency warnings are retained. Passing checksum or parser tests does not verify a nutrition label. These records must not silently qualify a meal as complete or nutritionally balanced.

**Allergens:** `declaredTags` and `traceTags` are different evidence. Empty tags or ingredients text mean unknown, never allergy-free. No inference of free-from or safety. Original declaration/text and source are preserved. People-specific allergen mapping belongs in the separate nutrition/person logic, not a rewrite of source data.

**Market/popularity:** `EG` and `SA` are only the source's Egypt/Saudi country tags. OFF scan-count sorting was used to choose a bounded seed, not to prove present-day shelf availability or national popularity. Barcode prefixes never infer country of sale or manufacturer origin. Brands missing in the source stay missing. Baby products are a separate searchable category without recommendations.

## Food categories

Sweets, chocolate, biscuits, salty snacks, dairy, oils, ghee, rice, pasta, flour, pulses, canned fish, meat, canned vegetables, condiments, spices, beverages, frozen foods, bread/bakery, baby foods. Source categories can overlap and remain visible. Unknown source classification remains `unclassified`. Zero coverage is an explicit gap; it must not be filled with invented products. This framework can be extended for baking additives, sweeteners, sauces, eggs, spreads and regional pantry products without changing food identity.

## Licensing and attribution

**Contains information from Open Food Facts, available under the [Open Database License1.0](https://opendatacommons.org/licenses/odbl/1-0/). Individual contents are under [Database Contents License1.0](https://opendatacommons.org/licenses/dbcl/1-0/).** The bank and raw OFF subset remain a separate ODbL-derived database. Do not strip notices or silently relabel the data under the application code license. Keep proprietary user profiles, purchases and health records outside this public source bank, linked by stable identifiers. Review redistribution requirements when publishing a combined database. No product photos were included; images have separate conditions.

Primary documentation:

- [OFF API requirements, custom User-Agent and limits](https://openfoodfacts.github.io/openfoodfacts-server/api/).
- [OFF nutrition field schema and100g/100ml semantics](https://openfoodfacts.github.io/documentation/docs/Product-Opener/schemas/schemas/product_nutrition/).
- [OFF product schema: quantities and normalized nutrients](https://openfoodfacts.github.io/documentation/docs/Product-Opener/schemas/schemas/product/).
- [OFF data licenses](https://openfoodfacts.github.io/openfoodfacts-server/api/tutorials/license-be-on-the-legal-side/).
- [OFF API conditions/combining databases](https://support.openfoodfacts.org/help/en-gb/12-donnees-api/94-y-a-t-il-des-conditions-pour-utiliser-l-api).

## Reproduce/check

From the repository root with Node24+:

```powershell
node tool/food/import.mjs build
$env:SOFRA_FOOD_BANK = 'E:/work/SOFRA/app/data/food/openfoodfacts'
node --test tool/food/import.test.mjs
```

Rebuilding from tracked raw archives reproduces the products/index hashes. Manifest `builtAt` changes intentionally. Synthetic test data only exist in temporary test archives and never enter the shipped bank.

Network refresh is explicit (`fetch` for3bounded pages per market; `fetch-categories` for one100-record page/category/market; `fetch-category <out> <category-id>`). Existing archive names are cached and not fetched again. Requests identify Sofra with a custom User-Agent and wait at least8seconds sequentially (less than10searches/minute). No automatic retries on503/429. To intentionally refresh, choose a new output archive directory and compare revisions before replacing the bank. V2 was503 during collection, so the official v1 `cgi/search.pl` endpoint was used. Coverage is bounded by successful requests and source category tagging.

## Exact next actions

1. Bind the source-separated transport into the FoodRepository; do not load this entire JSONL into every person's private state.
2. Review package identity, market variant, label basis and nutrition/allergen evidence before allowing calculation; store review provenance/revision separately.
3. Add missing categories/products through the importer or sourced manufacturer-label records, retaining source/license separation and verified GTINs.
4. Barcode scanning, label/photo review and live price feeds are not implemented by this collection task.
