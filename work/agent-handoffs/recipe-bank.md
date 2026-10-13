# Recipe research handoff

## Scope and base

- Selected checkout: `E:\work\SOFRA\app`; task base reported by coordinator: `7d9dcb4`.
- Read `docs/STATUS.md`, `docs/RECIPE-VARIANTS.md`, the recipe index, two existing catalog examples/schema sources, `lib/domain/recipe_catalog.dart`, `lib/domain/recipe_variants.dart`, and `lib/data/recipe_repository.dart`.
- Added only `data/recipes/research-candidates.json` and this handoff plus `recipe-bank.status.md`. No shipping recipe index/data, shared queue/status/handoff, application code, nutrition records, UI, Firebase, billing, assets, or Git state were changed.

## Research bank

- One source grouping, four candidates, 41 ingredient rows, and 29 ordered steps. Candidates: black bean burgers, black bean burrito, lentil stew, quinoa and black bean salad.
- Each row preserves source ingredient wording in `sourceText`; quantities/units preserve source form where supplied. Amounts expressed as mixed fractions are stored as numeric decimals without unit conversion. `to taste` remains null. Steps are concise Arabic summaries; numeric timing details are retained only inside step text and no unsupported aggregate durations are supplied.
- Source pages: [black bean burgers](https://myplate.food/recipes/black-bean-burgers), [black bean burrito](https://myplate.food/recipes/black-bean-burrito), [lentil stew](https://myplate.food/recipes/lentil-stew), [quinoa and black bean salad](https://myplate.food/recipes/quinoa-and-black-bean-salad). Publisher/recipe credits and per-source URLs are retained on each record.
- Licence evidence: the independent archive states the underlying federal recipes are US public-domain works under 17 USC §105 and says its enhanced edition is reusable with credit for non-profit/teaching use; its page identifies separate commercial licensing. Primary USDA pages were not fetchable in this session. Therefore `licenseStatus` is `unverified-primary-source`, and this batch is research-only. No archive prose, images, or nutrition values copied. Do not publish/runtime-import pending primary-source and intended-use review.

## Mapping to current app model

- Candidate `familyId`/`variantId` are suggestions only. Current `RecipeRepository` reads the fixed `recipes/data/index.json` and cuisine files; this research file is intentionally outside that path and cannot appear in search or runtime.
- A reviewed catalog record would need an exact repository index row (`id`, cuisine, category, file, servings) and a complete `CatalogRecipe`: localized name/cuisine/category/description/difficulty; positive serving count; prep/cook minutes and matching total; ingredients and sequential steps; tags/notes.
- Ingredient `name`/`amount`/`unit` are close to `CatalogIngredient`, but source units include forms absent from the shipping unit list (`can`, `scallions`, `large egg`, `buns`, `tablespoons`, `cups`, package/can expressions). Mapping them needs editor decisions, not silent conversion. `CatalogIngredient` also has optional `scale`, `optional`, `label`, `display`, and `note`; none are inferred here. Choice alternatives (basil/oregano, oil substitutions, bean alternatives) need explicit representation or separate reviewed variants.
- `CatalogStep.duration` is mandatory nonnegative numeric, while candidate `durationMinutes` is null because step durations are not consistently stated. This data therefore cannot be directly serialized into runtime steps. `prepTime`, `cookTime`, `totalTime` likewise remain unavailable as aggregate values.
- Per `docs/RECIPE-VARIANTS.md`, an authored variant requires saving a full immutable `RecipeRevision`, same-family parent identity where applicable, explicit review, and fresh revision-specific nutrition selection. No `RecipeRevision`, family grouping, or food binding is created by this research batch.
- Nutrition remains null. The app requires explicit revision-and-line `RecipeFoodSelection` acceptance; source nutrient panels, if later considered, do not automatically establish exact ingredient form or full recipe line bindings.

## Verification and next action

- Ran an offline Node parse/invariant check: JSON valid; 1 source, 4 recipes, 41 ingredient rows, 29 sequential steps; every candidate marked research-only; nutrition and food bindings null. Passed.
- No Flutter tests or build run: no runtime or application files changed.
- Next: confirm primary USDA source/license provenance or keep these archived candidates unapproved; resolve candidate family overlaps and units/choice groups; obtain reviewed aggregate preparation durations; then a curator may decide whether to author a runtime revision with fresh nutrition review.

## Delivery state

- No commit created; no push. No preview server state changed.

## Regional research addendum — 13 October 2026

- Added `research-wikibooks-koshari-eg` from the revision permalink `https://en.wikibooks.org/w/index.php?title=Cookbook:Koshari_(Egyptian_Rice_with_Pasta_and_Lentils)&oldid=4515104`, and `research-wikibooks-shitha-sa` from the Cookbook:Shitha page. Arabic display names and steps are supplied; original ingredient text and quantity text remain in `amountText` / `sourceText`.
- Source group `wikibooks-cookbook-cc-by-sa` is separate from the MyPlate archive group. The official Wikibooks copyright policy states most text is dual-licensed under CC BY-SA 4.0 and GFDL, with attribution, share-alike, change indication and license notice requirements. `licenseStatus` is `verified-license`, with the policy page in `licenseEvidenceUrl`. Do not represent Wikibooks content as public domain.
- Retrieval timestamp measured from the session clock: `2026-10-13T11:13:54Z`. The earlier MyPlate timestamp remains `2026-10-13T10:00:00Z`, now explicitly labeled as prior-agent-recorded because that agent did not capture its clock; do not present it as independently measured.
- Candidate limitation: Koshari has the revision permalink and 4-serving yield is not provided, so servings remain null. Shitha's page content and Gulf/Saudi relevance were available, but the retrieval did not expose a revision ID; its canonical page URL is retained, version-specific attribution is unresolved, and this candidate must remain research-only until a stable revision link is recorded.
- Validator command `node tool/recipes/validate-research.mjs` passed: 2 source groups, 6 candidates, 61 ingredients, 46 steps, 0 runtime-ready candidates. Nutrition and food bindings remain null. No runtime recipes, tests/build, Git state, or shared documentation changed.

## Coordinator provenance corrections

Reopened all4 archive recipe pages at measured2026-10-13T11:16:02Z; replaced the prior unmeasured10:00Z timestamp. Corrected original author credits per page: USDA CNPP / Michigan health department / University of Maryland Extension / NIH NHLBI. Federal redistribution is not proof that all original authors are federal employees; archive licence remains unverified. Added recordVersion1/sourceRevision(nullable), explicit CC-BY-SA-4.0 adaptation notice/licenseURL/attribution for both Wikibooks candidates. Runtime approvals and food/nutrition bindings remain0. Final validator/tests and commit receipt are coordinator-owned.
