# Structural source-to-runtime recipe adapter

Implemented in tool/recipes/runtime-adapter.mjs. It builds a CatalogRecipe-shaped **candidate**, preserving source/review/ingredient mapping. It does not register a recipe in KitchenService/RecipeBook, write state or approve nutrition. runtimeReady remains false. Native provenance reader/persistence is the next unit.

```js
import {buildRuntimeRecipeCandidate, validateRuntimeRecipeCandidate} from '../tool/recipes/runtime-adapter.mjs';
const candidate = buildRuntimeRecipeCandidate(source, draft, metadata, {foods});
const checked = validateRuntimeRecipeCandidate(candidate, source, draft, metadata, {foods});
```

Use current authoritative source/food readers and the explicitly registered draft files described in [preflight/registry](RECIPE-IMPORT-PREFLIGHT.md). Caller-injected snapshots are a trust boundary; this API does not independently authenticate them. No candidate is accepted solely from its embedded fingerprints. Validation reconstructs the full candidate from current source/draft/metadata/food snapshots, then compares the canonical fingerprint; changed data/attribution/mappings/gates/approval fields fail.

## Explicit adapter metadata schema1

Exact fields: schemaVersion, draftSha256 (canonical fingerprint of full reviewed draft), id (`import:<lowercase-slug>`), name, cuisine, category, description, difficulty, tags, notes, ingredientIds, steps, reviewNote, reviewedAt, acknowledgeSourceAndInstructions, acknowledgeRemainingNutritionGates.

Names/cuisine/category/description/difficulty/reviewNote must be explicit nonempty strings; source language is never used as cuisine. tags is an explicit string list, notes is text or null. reviewedAt must be a real UTC calendar timestamp ending Z. Both acknowledgements must be true; they record caller review, not independent legal/clinical proof or completed remaining gates.

ingredientIds is a list in exact source-line order. Each inner list covers exactly the included components; excluded optional lines require an empty list. Runtime ingredient identities are explicitly supplied, never inferred from source text, raw USDA IDs or nutrition candidates. Repeated IDs are possible only as caller decisions; canonical stock/food compatibility still needs runtime review.

steps covers exactly every source step, with exact text/passive/tip fields. Text is caller-reviewed instruction text, passive is explicit boolean, tip is text or null. Durations come only from reviewed draft.stepMinutes; they cannot be overwritten in step metadata. Unknown time/servings/choice/quantity/form/raw-food reference blocks adaptation. Known zero duration remains zero. Prep+cook must remain finite; step totals are not forced to equal wall-clock time because steps may overlap.

## Candidate and ownership

- recipe uses the actual CatalogRecipe JSON contract: totalTime=prep+cook, ingredients with explicit IDs/quantities/units/scale/optional/form note, sequential steps with reviewed durations, explicit remaining metadata.
- provenance preserves original recipeId/recordId/sourceId/revision/SHA/version URL/licence/change notice, full source/draft/metadata/recipe fingerprints, review notes/dates and an adaptation change notice.
- Each source line keeps its exact target, resolution/disposition/review note, runtimeLineIndices (including empty exclusions), component form and rawFoodReference. Splits map to multiple ordered runtime lines; alternatives never become multiple automatically included foods.
- nutrition is unreviewed with runtimeBindings empty. Raw food reference fingerprints are not transformed runtime FoodRecord fingerprints, measured grams or accepted nutrient bindings.
- Returned JSON owns copies; edits do not mutate the original source/draft/metadata/foods. Export validation catches any later content/gate/provenance changes by rebuilding from authoritative inputs.
- Remaining gates: runtime persistence/provenance validation, per-page licence exceptions, runtime identity/form/basis/measurement, ingredient retention and nutrient review. Keep source licences separate; never drop attribution or infer culinary completeness/medical suitability.

## Verification and limitations

8new adapter/tamper tests;44linked Node tests passed. An actual Flutter test runs the synthetic Node fixture and parses/scales it through CatalogRecipe:1passed. Analyzer initially reported the test's relative lib import; package import fixed, test passed again and analysis clean. After final validator addition the44linked tests and interoperability test passed. The fixture is synthetic, not an imported/reviewed real recipe. Existing full107Flutter tests are historical; full suite/APK/device testing not repeated because production Dart did not change.

Independent focused read-only review found no concrete must-fix in adapter/validator; no network, bank reads, edits or duplicate suites. No bulk source recipe imported, no user/cloud writes, no automatic food/stock/price/nutrition updates. Source records and54shipping recipes stay intact. Next: native candidate/provenance reader and explicit immutable registration through KitchenService, with atomic rollback/reload/retry and frozen-history tests. Do not strip the envelope and save only recipe JSON.
