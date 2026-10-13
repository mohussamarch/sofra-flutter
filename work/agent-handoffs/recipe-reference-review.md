# Recipe reference identity review — 13 October 2026

Checkout: `E:\work\SOFRA\app` only. Base commit inspected: `27b2a6b50f30691a4e0148a90139b210c982879f`.

## Objective and owned files

Provide explicit USDA CC0 reference identity candidates for actual recipe ingredient lines, starting with Egyptian bechamel pasta. Owned only:
- `data/nutrition/recipe-reference-review.json` (new, schemaVersion 1, top-level `entries`).
- `work/agent-handoffs/recipe-reference-review.md` and `.status.md`.

No application code, shared docs, OFF records, UI, Firebase, billing, images/audio or commits changed by this delegated task. Coordinator owns integration and delivery commit/push.

## Results

197/605 catalogue ingredient lines have entries across 53/54 recipes, using 36 distinct USDA records: 153 generic identity recommendations and 44 entries requiring user choices. All 10 `eg-bechamel-pasta` lines are present (2 recommendations, 8 choices). No confirmed nutrition bindings, nutrient values, densities, portion conversion factors or retention factors were authored.

Coverage is purposeful, not exhaustive: onion 29, garlic 23, raw tomato 14, parsley 12, cilantro 4, carrot 6, fresh basil 4, black pepper 9, ground cinnamon 9, paprika 3, granulated sugar 8, salt 49, water 19; plus the unique bechamel ingredient candidates. 408 lines remain outside this file; `sa-maamoul-tamr` has no entry. Drained onion, rubbing/flavour-only garlic, canned-or-fresh tomato alternatives, deseeded tomato, toasted pepper, whole cinnamon sticks, paprika-or-chili and fine/powdered sugar were excluded from generic expansion.

Each entry identifies recipeId + zero-based line, exact ingredientId/name, original quantity/unit/optional flag, recipe JSON source path and SHA256 after CRLF-to-LF normalization. Candidates preserve exact USDA description, ID, source shard/version/URL, explicit input form and rationale. `recipeSourceSha256` is freshness evidence, not the runtime immutable recipe snapshot version. Coordinator will add runtime version using Dart serializer.

## Decisions and unresolved issues

- Recommendations concern generic ingredient input identity only; they still need explicit acceptance and measured edible grams or independently reviewed conversion evidence. They do not establish the actual brand, fat percentage, fortification, allergen absence, final cooked composition or clinical validity.
- Bechamel dry pasta has enriched/unenriched choices; source form is `asSold`, never cooked pasta for the listed uncooked input. Boiling/rinsing losses and retained salt are unknown.
- Minced meat has 5%, 10% and 20% fat beef options plus a clearly conditional lamb option because the Arabic line does not state species. No silent species/fat default.
- Butter/ghee lists salted butter, unsalted butter and generic dairy butter oil. Vegetable ghee is unresolved. Clarify whether four tablespoons include onion sauteing and tray grease.
- Flour lists enriched/unenriched all-purpose wheat options only; actual grain/type/self-rising/enrichment need confirmation.
- Milk lists fluid cow milk options for whole unfortified, whole fortified, 2%, 1% and nonfat fortified. Carton/species/form/fat/fortification and cup mass remain unresolved; the shortlist is not exhaustive.
- Cheese lists mozzarella moisture/fat/shredded options. No exact Roumy reference identified in this scoped review; do not substitute parmesan/mozzarella for Roumy.
- Tomato sauce vs concentrated paste and salt status require choice.
- Compound salt-and-black-pepper rows remain blocked (`requiresUserChoice=true`); their two candidates are components, not whole-line alternatives. Need split measured lines in a new recipe revision or explicit multi-component support.
- Water is tap-vs-bottled options only. No exact local mineral profile or full cooking-water retention is assumed. Coarse specialty salt is an option, not a table-salt recommendation.
- All kitchen units, pieces, cups, spoons, bunches/leaves/pinches and to-taste amounts retain quantity/conversion issues. Optional inclusion, discarded water/salt/food, edible portions, finished yield and actual intake remain explicit next reviews.

## Evidence and verification actually run

Read STATUS first, repository AGENTS, focused nutrition handoff section, actual recipe JSON lines, filtered USDA index summaries and candidate shard metadata. USDA official documentation was browsed:
- https://fdc.nal.usda.gov/data-documentation/ — Foundation versus historical SR Legacy and label data.
- https://fdc.nal.usda.gov/Foundation_Foods_Documentation/ — food descriptions include raw/cooked/enrichment; edible basis, sample variability and missing nutrients matter.
- https://fdc.nal.usda.gov/api-guide/ — USDA CC0 provenance/licensing. OFF remains separate.

Focused Python validation passed: 197 unique recipe-line keys; exact current recipe ID/name/amount/unit and canonical-LF file hashes; all 36 food IDs/descriptions/versions resolve in index and source shards with 100 g edible basis; permitted forms; compound seasoning blocking; missing quantity and conversion issues; summary counts; all 10 bechamel lines; absence of nutrient values/density/retention guesses. Initial validation invocation hit Windows default text decoding; explicit UTF-8 rerun passed. Data file is 292148 bytes. No Flutter tests run for this data-only task.

## Exact next action

Coordinator imports the file as review proposals, derives runtime immutable recipe snapshot versions, rejects stale recipe sources, enforces choice and compound-row blocking, and previews an explicitly accepted ingredient-input estimate with unresolved measurements reported. Cooked retention/yield and actual product/portion evidence remain separate work. After coordinator integration, consolidate shared STATUS/HANDOFF and commit/push under repository delivery protocol. This agent has released ownership and will not revisit the JSON after completion.

No APK built or device/Drive test performed. No preview server started/stopped by this task; existing coordinator preview is outside this task's ownership and its current state was not rechecked here.
