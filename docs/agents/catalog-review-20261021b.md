# Catalog review — 2026-10-21b

Scope: read-only comparison of all 11 `catalog-reviewed.json` recipes against the exact `fullSavedSourceText` and `sourceIngredients` in the paired review sidecar, plus relevant candidate/supplemental evidence. No catalog edits, network access, or application changes. Source SHA/revision and rights evidence are pinned in the sidecar; per-page rights exceptions remain unreviewed, so this review does not grant a rights clearance. The sidecar correctly states aggregate prep+cook duration semantics and unknown nutrition; no kitchen or clinical validation was performed.

## Material findings

- **P1 — `bc-tajine` ingredient identity alignment is corrupted** (`catalog-reviewed.json`, recipe starts line 666; ingredients lines 679–721; sidecar recipe starts line 1748). Compare source lines: index 1 is “1 medium onion” but catalog says eggs; index 3 is “1 cup water” but catalog says onion; index 4 is parsley but catalog says cheese; index 5 is eggs but catalog says parsley; index 6 is cheese but catalog says olive oil; index 7 is olive oil but catalog says spice blend. This shifts most identities from the onion onward, including incompatible names/units. Further, the nine-item `## Spice Blend` (cumin, coriander, turmeric, salt, paprika-or-cayenne alternative, black pepper, caraway, thyme, cinnamon) is omitted as ingredient facts and replaced by “spice blend, 2 tbsp,” an amount absent from source. Correct names and preserve spice lines/amounts and the paprika-or-cayenne choice; do not infer a total blend amount.

- **P1 — `bc-ukrainian-borscht` has incorrect amounts/units and alternatives** (catalog starts line 547; ingredients lines 560 onward; sidecar starts line 1434). Source says 2 carrots, catalog says 3; source says 1 onion, catalog says 2 celery stalks (`2 عود`). Source potato count is 3 Yukon potatoes but catalog leaves the amount unknown despite it being explicit. The source offers 4 Tbsp ketchup **or** 3 Tbsp tomato sauce; catalog records only 4 Tbsp for the combined option, discarding the alternative’s distinct quantity. Preserve each fact/alternative accurately.

- **P1 — `bc-tarte-merengada` drops a material bake temperature** (catalog recipe starts line 481; inspect its sole step). Source direction 9 explicitly says reduce oven to 160°C before returning the pie; translated direction only says reduce the heat. Restore 160°C. Duration may remain unspecified because the source gives no time for that final phase.

- **P2 — `bc-arroz-chaufa` omits two source-listed optional ingredients** (catalog starts line 893; sole grouped step). Source direction 6 offers optional bacon and sesame oil; the step translation includes both, but no corresponding ingredient rows/supplemental entries exist. Add both with unknown amounts and optional status, or clearly retain them as unquantified optional additions in the catalog representation.

- **P2 — `bc-chicken-in-red-wine-vinegar-sauce` invents parsley quantity and drops chicken count** (catalog starts line 314; ingredients lines 339–368; sidecar starts line 813). Source parsley is optional with no quantity; catalog sets 1 cup. Source says 1 whole chicken, with breast/leg alternatives; catalog nulls the amount entirely. Keep parsley amount unknown and preserve the explicit “1 whole chicken” quantity while retaining the alternative cuts. The vinegar contradiction (1 cup/720 mL) was appropriately left unknown and documented.

- **P2 — optionality is lost in Borscht audit fields** (sidecar recipe at line 1434; `sourceIngredients` entries for source lines 27–31). The source marks pepper, beans, bay leaves, garlic, sour cream, and dill optional, but the sidecar records `optional:false` for all. Some Arabic display names say “اختياري” while the audit boolean contradicts that. Set the sidecar facts to true; ensure the catalog semantics keep the same optionality.

## Reviewed without further material findings

For the remaining reviewed source/direction content, translation covers the listed method sequence and retained source quantities/units or explicitly surfaced unknowns as expected. Paprikash optional flags and the vinegar amount contradiction are represented in sidecar evidence. Baked-rice sequence/220°C and 20–25-minute bake, Finnish bake’s 200°C/90 minutes (source typo in step text noted in recipe notes), Santiago’s 180°C/40 minutes, Zurich’s omitted-from-list butter surfaced as an unquantified supplemental, and Tzatziki’s odd published cook-time metadata are visible and documented. “All 11 reviewed” means text comparison only; source page-specific rights, food safety, and kitchen performance were not certified.

- **P2 — inherited poultry doneness guidance lacks a thermometer check** (`bc-chicken-in-red-wine-vinegar-sauce`, grouped step; source direction 3). The translated/source instruction says the chicken is cooked after browning 12–15 minutes, with no internal-temperature endpoint. This is an inherited source claim, not introduced by translation. Consider flagging for later food-safety review; do not represent this source transcription as safety-validated.

## Delta re-review — 2026-10-21

Rechecked the coordinator's corrections in `catalog-reviewed.json` and `.review.json` against each affected recipe's exact `source.fullSavedSourceText`, `sourceIngredientsCorrected`, and `sourceSteps`. All previously reported catalog defects are corrected:

- Tajine now maps the eight main ingredient identities and their original quantities correctly; all nine separately listed spices and the method-mentioned optional harissa are represented without inventing a total spice-blend amount.
- Borscht splits broth and water, restores 3 potatoes/2 carrots/1 onion, preserves the ketchup-versus-sauce quantities distinctly, and marks the six optional source ingredients true in corrected evidence.
- Tarte merengada now states 160°C for the final oven phase.
- Chaufa now includes bacon and sesame oil as optional unquantified additions and sugar at 1 teaspoon.
- Red-wine chicken now preserves one whole chicken and cut alternatives, leaves optional parsley quantity unknown, and documents the source's vinegar quantity/unit conflict.
- The four chicken recipes (paprikash, tajine, red-wine chicken, chaufa) now separately include thermometer guidance at 73.9°C/165°F, with the safety evidence in audit fields and notes explicitly separated from source directions. This review did not independently confirm the live FSIS page: opening the cited URL returned HTTP 403 during this pass. The source citation and check date are recorded in the audit.

No material source-fidelity mismatch remains in the corrected delta. Original `sourceIngredients` arrays still contain some prior crosswalk errors by design, but `sourceIngredientsCorrected` explicitly retains the corrected exact source-section crosswalk and `coordinatorCorrection` points reviewers to it; those historical arrays should not be read as current approved mappings. Page-specific source rights remain unreviewed. Text comparison only; no cooking or clinical validation.
