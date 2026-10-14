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

## Explicit persisted draft registry

`data/recipes/import-review/registry.json` registers exact draft filenames and SHA256 with source recipeId/recordId/version URL/sourceSHA/licence/change notice. Files live only under `data/recipes/import-review/drafts/`. `node tool/recipes/import-draft-registry.mjs` verifies all paths/IDs/provenance before reading, raw bytes before JSON, exact full source/line targets via preflight, then requested current USDA snapshots/evidence once. Duplicate IDs/files or automatic discovery are forbidden. A source recipe can have multiple explicitly named drafts; they are not merged. Changed bytes need explicit registration and re-review, never silent rehash.

CLI exit0 means registry is valid even when drafts are incomplete; inspect `completeDraftCount`, per-draft issues and `runtimeReadyCount` (always0). Invalid registry/source/file/evidence exits1. This differs intentionally from the individual preflight CLI's exit2 for unresolved draft. Programmatic API: `validateImportDraftRegistry(registry, {recipes, readDraft, loadFoods})`. Injected readers must be authoritative; fingerprints are local consistency, not independent security signatures.

Actual persisted example: hummus-source.json from wikibooks:6737,1draft/9lines/50unresolvedissues/0complete/0foodreferences/0runtime. Source quantities/times/choices/servings remain null. A valid registry is not accepted culinary review or from-scratch personal authoring. The draft is source-derived CC BY-SA text/anchors with attribution/licence in registry; individual page exceptions remain unreviewed. No user/cloud state written.

Verification:7new registry tests; final36linked Node tests passed. Actual registryCLI exited0 and retained incomplete result; source/fullrecipe/target hashes reverified. Previous107Flutter/analyze are historical. Next explicit source-to-runtime adapter requires catalog metadata/provenance and must preserve remaining form/basis/measurement/retention/nutrition gates.

## Structural adapter checkpoint

[Runtime candidate contract](RECIPE-RUNTIME-ADAPTER.md): explicit complete source drafts/metadata become CatalogRecipe-shaped candidates with full source/licence/line maps and remaining gates.44linkedNode+1actualFlutterreader/scalingpassed;analyzeclean. Transport validation rebuilds against currentauthoritativeinputs. No KitchenService import/nutritionapproval yet;next native provenance reader/immutable registration. OFF2287/64(+21/1),5banktestspassed;Saudi503gate23:49:13.371Z. HANDOFF§56.

## Native source import checkpoint

[Native import API/compatibility](NATIVE-RECIPE-IMPORT.md) now verifies exactUTF8 transport/source envelope and persists selectedreviewed roots atomically through KitchenService.importSourceRecipe. Full142Flutter+1additionalnutritionbinding/46Node/analyzeclean;no actualsourcebankpromotion/UI/usercloudwrites/automaticnutritionbindings. Quantity/import infrastructuredone;scientificcoverage remainsopen,preparation30next,privateauthoring34unblocked. OFF2378/67(+91/3),5actualbanktests;sourcegates incheckpoint. HANDOFF§58.
