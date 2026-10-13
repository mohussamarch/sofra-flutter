# Source recipe import-draft preflight

This is an offline review tool, not the runtime importer or a nutrition approval. Current English archived sources are supported by the authoritative reader; French/Spanish need separate reader contracts. Source language is not cuisine.

## API

```js
import {emptyImportDraft, auditRecipeImportDraft} from '../tool/recipes/import-preflight.mjs';
const draft = emptyImportDraft(authoritativeRecipe);
// Reviewer explicitly fills decisions; never copy quantity candidates as accepted facts.
const result = auditRecipeImportDraft(authoritativeRecipe, draft, {foods: authoritativeRawFoodSnapshots});
```

The caller supplies authoritative snapshots. Use recipe-review-reader.mjs and usda-review-reader.mjs; stop collectors while reading. Hashes detect local consistency, not independent authenticity or approval. The CLI performs source re-extraction and requested USDA snapshot verification itself:

```powershell
node tool/recipes/import-preflight.mjs wikibooks:6737
node tool/recipes/import-preflight.mjs wikibooks:6737 path/to/review-draft.json
```

Exit0: complete draft decisions; exit2: unresolved report; exit1: malformed/stale input or source failure. The first command audits a blank template. Neither command writes files, imports recipes, approves food bindings or touches Firebase.

## Draft schema1

- Top-level exact fields: schemaVersion=1, recipeSha256 (full canonical source fingerprint), note, reviewedAt (real UTC calendar timestamp ending Z), servings, prepMinutes, cookMinutes, stepMinutes, lines.
- Blank evidence, servings and times remain null. Positive integer servings required. Known prep/cook/step durations may explicitly be zero; missing/negative/nonfinite values cannot pass. Step durations must cover every source step, including sparse JS slots. No assumption that step durations sum to prep+cook (steps can overlap).
- Exactly one decision in source order per line: target=reviewTarget(recipe,index), resolution=null|single|choice|split, disposition=null|required|included-optional|excluded-optional, note, components.
- All full recipe/source/parser/quantity-parser/line anchors must match. Refreshing only recipeSha256 cannot hide stale per-line targets. Original source stays unchanged.
- Included single/choice has exactly one component; split requires at least two. Excluded optional lines have zero components, a recorded resolution and note. At least one included component overall is required. Review must decide compound/alternative/optional semantics explicitly, never accept an automatic guess. Source instructions still require separate review after changes.
- Component exact fields: name, amount (positive finite), unit (nonempty; conversion validity is a later gate), form (explicit text), optional (boolean consistent with line), scales (explicit boolean), food.
- Food is null (unresolved), or exact foodId/foodVersion/foodSnapshotSha256 matching the caller's current authoritative **raw** snapshot. Repeated food across lines/components is allowed. This reference is not the transformed runtime FoodRecord fingerprint, measured grams, food form compatibility or a nutrient binding.
- Unknown fields are rejected, including smuggled approval/nutrition fields. API never mutates source/draft/maps. A completed draft is caller-recorded evidence, not scientific validation of the entered amount, form or identity.

## Report and remaining gates

Report includes draftComplete, runtimeReady=false, precise issue code and line/component/step indices, per-line completion and remainingRuntimeGates. draftComplete only means these draft decisions are explicit and structurally consistent. It never means the recipe is safe, nutritious, licensed for a particular use or ready to cook.

Remaining gates: runtime adapter/required CatalogRecipe metadata; per-page licence/attribution/instructions; runtime food identity/form/basis/measurement conversion; ingredient retention and nutrient completeness. Do not fill missing times with zero, infer grams from cup/count, sum both alternative ingredients, retain all discarded soaking ingredients, or invent missing nutrients. The existing calculation engine remains the single arithmetic path; no duplicate calculator here.

## Actual baseline and verification

data/recipes/import-review/english-baseline.json pins current source/index/category and tool hashes. It audits **blank templates**, not existing approved reviews or unique dishes:3640source recipes/31774ingredient lines/24964steps,0complete blank drafts/0runtime. CLI on wikibooks:6737 exited2 with9lines/50issues. Source banks/shipping recipes/Flutter state unchanged.

11new tests plus18linked source/target/USDA reader tests passed (29total). Before fixes, regressions failed for sparse time slots, invalid calendar evidence and all ingredients excluded; all now pass. Previous107Flutter tests/analyze remain historical because no Dart code changed in this unit.

Next: persist explicitly registered draft files with byte hashes/source guards and review provenance, then design the runtime adapter without dropping unknown metadata/form/retention gates. No reviewed source draft or bulk runtime import has been accepted yet.
