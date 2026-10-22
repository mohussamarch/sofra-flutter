# Independent sample review: catalog 650 data

Reviewed 12 records against their cached source crosswalks: first, early-quarter, middle, and last records from Based chunk 008, Foodista Asian chunk 106, and Foodista world chunk 006. This is a limited sample, not a culinary review of the full catalog.

## Findings

1. **[P2] A clear nutmeg quantity remains unparsed.** In `data/recipes/catalog-650-20261021/based/chunk-008.json`, candidate `bc650-kropsua` keeps the source phrase `1/4 Teapsoon nutmeg` in `display`, but has null structured `amount` and `unit` with scaling disabled. The typo does not make the amount or teaspoon unit ambiguous; parse 0.25 teaspoon while retaining the original display text.

2. **[P3] Final serving instruction omitted.** In the same Based chunk, candidate `bc650-hangover-eggs` ends with serving alongside beer. The source also instructs diners to use the bread to guide the egg onto each piece, break the yolk into the bread, and eat it without a fork. Add this final serving note to preserve the method.

3. **[P2] Asian source review note conflicts with its own ingredient crosswalk.** For `fi650-57978` in `data/recipes/catalog-650-20261021/foodista/chunk-106.json`, candidate ingredients say 1 teaspoon garlic and 1 teaspoon ginger, matching the sidecar's extracted source lines. The adjacent `chunk-106.review.json` entry says the source gives 1 tablespoon for each. Correct that sidecar note; do not change candidate quantities based on the stale note.

4. **[P2] Explicit lemon count is not represented structurally.** In `data/recipes/catalog-650-20261021/foodista-world/chunk-006.json`, candidate `fiw650-52472` has `عصير ليمون` with null amount/unit and scaling disabled. Its source ingredient line is `1 Juice from lemon`; represent one lemon (juiced) with a count unit and retain the source phrase in provenance.

5. **[P3] Optional source variations omitted from the bread method.** Candidate `fiw650-52460` in the world chunk includes the core dough, rise, shaping, egg wash, bake, and cooling sequence. The source also gives optional egg-coloring instructions, shaping into smaller buns/loaves, and an alternative warm proofing setup. Add these as clearly optional source notes if full method coverage is required.

## Sampled records without a material discrepancy found

- Based: `bc650-cheesy-potatoe-bake`, `bc650-gnocchi`. The first candidate's explicit 4 servings, 30-minute prep, and 45-minute bake match its source; the remaining source quantities are preserved, with `30g+` butter left unscaled.
- Foodista Asian: `fi650-55601`, `fi650-57392`, `fi650-60108`. Ingredient quantities, source alternatives/ranges, and ordered method facts matched the cached source lines in the sampled comparison.
- Foodista world: `fiw650-53716`, `fiw650-51270`. No omitted ingredient or unsupported time/yield was identified in the sampled comparison; unknown metadata remains null.

No files outside this review note were edited. This review does not establish operational readiness, kitchen testing, or approval of the remaining catalog.

Coordinator resolution: sample findings1,2,3,5 fixed in candidates/sidecars and shipping catalog. Finding4 did not establish a whole-lemon count from the ambiguous raw phrase; kept unknown/unscaled and held the already represented tabbouleh. See sample-review-resolution.json; no new inferred count was accepted. The original review above is historical.
