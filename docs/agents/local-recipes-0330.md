# Local recipes 0330 — bounded offline batch eight

## Ownership and outcome

- Parent assigned only `data/recipes/curated-local/eighth-reviewed-20261015/**`, `tool/recipes/curated-eighth-build.mjs`, its test, and these two agent notes. No shared manifests, pubspec, queue, STATUS, HANDOFF, outside mirrors, Git, UI, Firebase, billing or live source touched.
- Work completed; ownership returned to coordinator. Coordinator still must integrate selected assets and run the combined product gates.
- Six Arabic source drafts from existing English Wikibooks revisions only; zero network requests, zero newly acquired books, zero kitchen tests, zero food/nutrition bindings and zero runtime approval.
- Source language is not cuisine. Five source category labels occur in this pack; Norwegian is the single new label versus seven frozen previous local packs.
- Counts: 6 recipes, 44 listed ingredient lines, 4 procedural additions, 32 steps, 0 fully specified, 6 needs review, 0 not cookable. Native preflight reports 151 issues.
- Combined local after integration: 62 records, 10 fully specified culinary source drafts / 50 needs review / 2 not cookable, 457 listed ingredients, 29 procedural additions, 339 steps and 51 explicit source category labels. This does not claim 62 unique globally deduplicated dishes or 51 approved national cuisines.
- Selected library integration would add six to the current78; coordinator owns that count and manifest change. Original54 planning recipes and reviewed method-family count remain unchanged.

## Evidence and immutable pins

- Normalized pack SHA256: `295b204f9618d52555fe8c0236f9f0ca4feee214943e0b75081101c5dae08a7b`.
- `source-snapshots/*.json` retain original source records, exact revisions/timestamps, retrieved dates, original wikitext, licence, authoritative parsed recipe and source-bank evidence.
- Provenance includes raw source hash, parsed recipe hash, snapshot byte hash, licence hash and CC BY-SA4.0 attribution/change notice. Page-specific rights exceptions remain unreviewed.
- Seven prior normalized local pack hashes are checked before and after building. Duplicate checks cover selected source IDs, titles and family IDs, all22 modern creator archive records, and54 planning names; no global6056-record duplicate review claim.

| Page/revision | Arabic adaptation | Preserved gaps |
|---|---|---|
| 13447 / 4610539 | بولغوغي كوري (لحم بقري مشوي بالتتبيلة) | 450g explicitly appears beside1lb; no calculated conversion. Six servings. Garlic1–2tbsp remains null. Three optional ingredients retained. Ingredient soy/sugar ratio conflicts with a note; neither repaired nor approved. Grill duration unknown; rice serving unquantified. |
| 14459 / 4518657 | موكيكا برازيلية (يخنة السمك بحليب جوز الهند) | Five servings. Salt, pepper and serving rice unknown. Tomato is included; only peeling is optional. At least60min marinade and20min boiling are separate phase values; no inferred total. |
| 219286 / 4613881 | ساغاناكي يونانية (جبن أبيض مملح بالمقلاة) | One serving/5min from source. Cheese type/weight unresolved. Flour/bread optional and unquantified. Per-side1–2min is approximate and scoped to0.75cm slice, not total. |
| 294156 / 4519135 | ليفسه نرويجية (خبز البطاطس المسطح) | About40pieces retained as text and scalar yield null. Prep1–2h remains range text, cook60min explicit, total null. Overnight refrigeration conditional. Dusting flour/toppings unknown; no filling method family inferred. |
| 234180 / 4541090 | كليبون إندونيسية (كرات الأرز بسكر النخيل وجوز الهند) | Four explicit gram amounts retained.8–10pandan leaves or paste and water remain unresolved. Approximate5min boiling retained; total/yield unknown. |
| 452631 / 4512915 | أرز إندونيسي بحليب جوز الهند | 300g rice/400ml coconut milk retained. Source says all ingredients first and remaining milk later without allocation; contradiction explicit. Pinpoint fenugreek unknown. Four servings,15min rest only; cook/total unknown. Optional note alternatives not selected. |


## Verification actually run

- `node tool/recipes/curated-eighth-build.mjs` succeeded.
- `node --test tool/recipes/curated-eighth-build.test.mjs`: 2/2 passed, about2.9seconds.
- Test1 verifies exact IDs/revisions/raw wikitext SHA/source and licence identity, each provenance/content/draft SHA, all source steps mapped, absent runtime/nutrition/food bindings, counts, ranges, optionality and declared conflicts.
- Test2 rebuilds all pack files and compares every filename and exact byte; all identical. No network involved.
- No Flutter/full repository test was run by this helper; coordinator owns combined integration gates.
- One initial local shell check used the unavailable WindowsApps python alias and failed before any file change; subsequent scripts used bundled Python explicitly. No source request failure or bypass.

## Integration instructions / next step

1. Select `data/recipes/curated-local/eighth-reviewed-20261015/normalized-recipes.json` in coordinator-owned builder and bundle its six exact snapshot files.
2. Rebuild manifest/pin and adjust actual integration counts only after validating the files.
3. Include focused Node2 plus related Flutter asset/calculator tests in the combined gate; update shared handoff/queue/outside receipt through coordinator only.
4. Keep all six review gates and source contradictions visible; future culinary review should resolve them against current attributable source evidence without silently rewriting archived revisions.

## Files delivered

- `data/recipes/curated-local/eighth-reviewed-20261015/normalized-recipes.json`, `review-decisions.json`, `review-report.json`, `COOKBOOK.ar.md`, six `source-snapshots/*.json` and six `preflight-drafts/*.json`.
- `tool/recipes/curated-eighth-build.mjs` and `tool/recipes/curated-eighth-build.test.mjs`.
- `docs/agents/local-recipes-0330.md` and `.status.md`.
