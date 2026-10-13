# USDA household-measure bank handoff — 13 October 2026

Checkout: `E:\work\SOFRA\app` only. Objective: add source-backed, explicitly reviewable portion choices for USDA IDs already present in `data/nutrition/recipe-reference-review.json`.

## Owned file

- `data/nutrition/household-measures-review.json` (schemaVersion 1).

Each row preserves food ID, candidate source version/description/form, shard path, canonical-LF shard SHA256, FoodData Central URL and exact USDA portion values with their original array index. The bank is CC0 and documents USDA provenance. Option labels surface source values; every rationale says that the measure/count is an estimate and needs explicit form/measure acceptance. No automatic recipe application, utensil equivalence, density, conversion, retention, price, or cooked-form inference was added.

## Results

- 36 unique food IDs and 36 food/form rows inspected; no food IDs appeared in multiple candidate forms.
- 30 rows contain 103 proposed exact source portions; 6 rows have no options.
- Bechamel-first coverage includes usable options for dry pasta, raw onion, raw 95% lean ground beef, dairy butter oil, enriched/unenriched all-purpose flour, several fluid milk forms, mozzarella portions where available, ground nutmeg, canned tomato paste/sauce, plus the source portion records for seasoning components. USDA portion records remain estimates, never confirmed measures for the recipe or the user's utensils.
- Gaps: USDA provides only generic RACC rows for ground beef 90/10, ground beef 80/20 and ground lamb; no portion rows for part-skim mozzarella, salted butter or unsalted butter. These have explicit issue reasons. No generic RACC was converted into an option.
- Source records marked raw retain only raw-compatible portions; candidate form is kept per entry. Source options list original measures (including US cups/spoons/oz) without a metric equivalence invented by this review.

## Verification

A focused generator/validator read all candidate references and actual shards; it checked canonical-LF SHA256 values, source record presence, source portion array indices and exact amount/gramWeight/measureUnit/modifier/description preservation, positive values, CC0 provenance, and exclusion of generic RACC rows. Counts are recorded in the artifact summary. No application code, shared docs, OFF collector, Firebase, APK, or commit was touched.

## Exact next action

Coordinator can review `data/nutrition/household-measures-review.json` and decide whether/how to expose the exact source options for explicit user acceptance. Keep household estimates separate from measured ingredient weights and raw input measures separate from cooked-food references.

Ownership released. No server, APK, or external service was changed by this task.
