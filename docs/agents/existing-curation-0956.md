# Existing local recipe curation — 14 October 2026

## Scope and checkout
- Active/only checkout: E:\work\SOFRA\app, main. Base: 33da2ff216c122949469451db63b36464e956aab.
- User correction: process existing 6056 research records into actual reviewable recipes. Acquisition of book/Wikibooks sources remains stopped. This unit made no network requests and did not resume collectors.
- Assigned ownership only: data/recipes/curated-local/**; tool/recipes/curated-local*.mjs/.test.mjs; this full/small handoff. Coordinator owns shared docs, registry, service, assets, Git and delivery.

## Concrete results
- data/recipes/curated-local/first-reviewed-20261014/normalized-recipes.json: 16 manually curated source records / 99 original ingredient lines / 12 supplemental procedural ingredient observations / 62 Arabic method steps.
- COOKBOOK.ar.md in the same folder: actual Arabic names, quantified ingredient lists, original Arabic method summaries, published yields/times, exact review issues, source revision links and hashes. It is a cookbook, not a title index.
- Four have fully specified culinary information: 141667 peach/strawberry/icecream smoothie (4 source servings, 5 minutes); 264763 kulfi (4–6 source servings, 7 hours); 303834 Vietnamese fish dipping sauce (advertised 2-cup yield, 10 minutes); 17844 plain rolled-oat porridge (1 source serving, 15 minutes).
- Ten need explicit review: mango lassi, pikelet, alkubus, two naan methods, two Irish soda breads, msemmen, wali wa nazi, sheer khurma. Every gap is recorded; none is advertised as fully specified or native-import ready.
- Two are withheld as not-cookable: chakarai pongal lacks water allocation/milk use/remaining ghee use; kunun gyada lacks processing-water quantities and rice cooking endpoint. Amounts were not invented to complete them.
- 14 selected family IDs. Naan has two genuine source-supported methods: baking-soda/yogurt/hot oven versus active yeast/proofing/140 C oven. Irish soda breads are ingredient variants, explicitly not counted as two distinct techniques.
- Eleven source-supported cuisine labels, including regional Hausa/Swahili labels; not eleven newly approved runtime/national cuisines. Indian/Pakistani, Vietnamese, New Zealand/Australian, Hausa/Nigerian, Irish, Algerian/Moroccan, Swahili evidence is exact source prose/categories. Three records have no independent cuisine label, including yeasted naan; family links do not inherit cuisine.
- Comparison with actual 54 catalogue recipe names and six initial research source URLs found no exact selected-name/source matches. Source IDs within the selected set are unique. Cross-language/global 6056 dedup was not performed; no global distinct-dish total claimed.

## Decisions and quality controls
- review-decisions.json holds manually entered quantities/units/alternatives, source line mapping and newly written Arabic methods; it is pinned to exact source recordId/source SHA/full derived source fingerprint. Quantity candidates were not bulk accepted.
- Milk/yogurt/icecream source metric amounts are chosen where explicitly printed. Mango sugar stays 250 ml, not 250 g. Cups/spoons/pinch/count remain source measures without density/weight guesses.
- Kulfi stays 4–6 servings, sauce stays volume yield, yeasted naan stays four dough balls (not four servings). Unknown prep/cook/step durations and scaling stay null; no missing values become zero.
- Garlic in the sauce uses the stated 1 tsp option, without adding the alternative two cloves. Optional sauce boiling is explicitly excluded. Porridge is served plain with suggested toppings excluded. Optional coconut-rice oil is explicitly excluded.
- Procedural-only ingredients are preserved separately: e.g. naan yeast water is explicitly 1 tbsp; hand water/board flour/tray grease remain unknown.
- Source inconsistencies remain visible: naan total shorter than rest; wholewheat soda bread total shorter than baking; soda bread source temperature discrepancy; coconut-rice category mismatch/timing contradiction; source editorial incomplete flags. No automatic culinary correction.
- Per-page licence exceptions, independent culinary testing, inventory identity, nutrient bindings and medical suitability remain unapproved.

## Source and hash contract
- Sixteen source-snapshots/*.json each preserve the full immutable source record (including original wikitext, revision URL/timestamp, source attribution/license/retrieval evidence) plus authoritative re-extracted English recipe and bank pins.
- tool/recipes/curated-local-build.mjs calls existing loadRecipeReviewSnapshots, verifying all English source/index/category hashes and full re-extraction before writing outputs. It verifies each wikitext SHA and every manually pinned source fingerprint. Existing differing snapshot bytes are rejected rather than overwritten.
- sourceSnapshotSha256 hashes exact UTF8 file bytes, JSON.stringify(snapshot,null,2) plus LF, no BOM.
- sourceSha256 hashes original wikitext UTF8. derivedRecipeSha256 and licenseSha256 use existing snapshotFingerprint (sorted object keys canonical JSON). contentSha256 uses snapshotFingerprint of the normalized recipe before adding contentSha256.
- Final normalized file raw-byte SHA256: 2e8b81cba110ea979f6199dd0a7e8e67c9626e3081c98491897b83664d032946.
- Attribution: Wikibooks contributors via fixed revision URLs; Arabic names/methods and structured choices explicitly modified/adapted under CC BY-SA 4.0. Source exceptions remain unapproved. These fingerprints prove local consistency, not upstream authenticity.

## Existing native preflight integration
- preflight-drafts/{141667,264763,303834,17844}.json are four populated existing emptyImportDraft-schema reviews with actual reviewed amounts/units/forms/choice decisions, not blank templates.
- preflight-reports.json records actual auditRecipeImportDraft reports and draft byte hashes. They are not added to shared import registry. All draftComplete/runtimeReady remain false.
- Exact minimum structural gaps:
  - 141667: prep time, cook time, 1 source-step duration, 4 scaling decisions, 4 food references.
  - 264763: fixed servings, prep/cook time, 5 step durations, 5 scaling decisions, 5 food references.
  - 303834: fixed servings (source is 2-cup yield), prep/cook time, 3 original step durations, 6 scaling decisions, 6 food references.
  - 17844: prep/cook time, 5 original step durations, 3 scaling decisions, 3 food references.
- Remaining native gates also include required CatalogRecipe metadata/inventory IDs, per-page rights/instruction review, runtime food form/basis/measurement and retention/nutrient completeness. Generic source food descriptions are not accepted USDA or runtime FoodRecord bindings.
- Coordinator is implementing an unknown-aware read-only library reader so the real curated ingredient/method records can be consumed without falsifying native numeric-time metadata or changing old catalogue roots.

## Verification actually run
- node tool/recipes/curated-local-build.mjs: passed, authoritative offline rebuild /16 records /4 fully specified /10 needs review /2 not cookable /1 genuine distinct-method family /11 supported labels /0 runtime.
- node --test tool/recipes/curated-local-build.test.mjs: 9 tests passed. Tests verify actual16 source/file/license/record pins; reject full source/revision drift and invented cuisine; preserve units/ranges/pieces/nulls; prevent incomplete supplemental quantities being labelled complete; require all source-step mapping/exclusion; verify alternative decisions; distinguish genuine methods versus ingredient variants; prove nonmutation; verify populated draft hashes and unresolved gates.
- No Flutter tests run by this helper; no Dart/service/cloud/UI/registry/pubspec changes made by this helper. Coordinator owns runtime integration and Flutter gates.
- Existing source banks were never written or replaced. No Firebase/billing/APK/Drive/S24 actions performed.

## Exact next action and delivery
- Coordinator: review/pin the frozen 16-record pack and 16 source snapshots in the read-only reader manifest/assets, run its actual Flutter tests/analyze, consolidate shared STATUS/HANDOFF/queue and commit/push this scoped unit with other reviewed changes.
- No further recipe acquisition is authorized here. For future expansion, repeat manual local curation on strongest archived evidence; never equate all6056 source records with complete or unique recipes.
- Helper did not commit/push (coordinator owns Git). No preview server was started/stopped/inspected by this helper; coordinator must verify process/source/port in final delivery receipt.
