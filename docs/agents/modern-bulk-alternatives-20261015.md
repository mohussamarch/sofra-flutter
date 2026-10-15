# Modern bulk alternatives —15October2026

Checkout E:\work\SOFRA\app; metadata-only assessment. **0recipes collected/imported; >=1000complete distinct modern-source target not met.** Existing offline1000batch remains separate. Actual starting quota38/22ordinarytrue; user-authorized ceiling99.

## First-party findings

[TheMealDB homepage](https://www.themealdb.com/) currently displays793meals and992ingredients. Ingredient vocabulary is not recipe count.793is a platform claim, not collected contents, and is below1000.

[API docs](https://www.themealdb.com/api.php) explicitly document testkey1 for development/education, and require paid supporter access for appstore release. Full-database capability is a supporter feature rather than the stated100-item limit. Do not work around those free limits. Documented public URLs:
- https://www.themealdb.com/api/json/v1/1/search.php?s=Arrabiata
- https://www.themealdb.com/api/json/v1/1/search.php?f=a
- https://www.themealdb.com/api/json/v1/1/lookup.php?i=52772

Only the first endpoint was probed. It returned meal52771 with8nonempty ingredient/measure pairs and instructions. Source/dateModified and artwork CC-confirmation fields are null; no video/image accessed or record imported.

[MealDB terms](https://www.themealdb.com/terms_of_use.php), printed update01/07/2025, permit copying/modifying official API content with notices retained, prohibit website scraping, limit free API to development, require payment for appstore release and preserve third-party-content rights. This is a qualified partial development source, not unconditional public-domain data or production permission. Artwork CC field does not license recipe text globally.

[Based Cooking](https://based.cooking/) links directly to [LukeSmithxyz/based.cooking](https://github.com/lukesmithxyz/based.cooking). The README License section expressly places the website AND ALL CONTENT in the public domain and covers submitted text/images; repo shows Unlicense. This is content-specific publisher evidence, not a code-only licence assumption. Preserve contributor/source exceptions where noted.

Observed GitHub branch:master. Recipe contribution files are Markdown in content/, modeled after example.md. Repository also has static/,layouts/,data/authors/; **the repository is not Markdown-only**. Commit SHA was not retrieved. A future collector should pin commit/licence, fetch only content/*.md and needed attribution, and exclude images/static/media/theme/index files; no full media-containing archive was downloaded.

Returned index text contains440recipe-link entries/439distinct displayed titles, locally counted. These are not440validated or439unique dishes. [One recipe sample](https://based.cooking/pesto-chicken-quinoa-bowls/) exposes11ingredient lines,6numbered directions, an alternate oven-method paragraph and yield/times. No body saved/imported. Historical-themed index entries exist; no oldbook source link followed. Cuisine tags remain observations.

[Original RecipeNLG project](https://github.com/Glorf/recipenlg) claims2,231,142recipes and~1.6Mgathered subset, mixing gathered material and prior datasets. [Official dataset page](https://recipenlg.cs.put.poznan.pl/dataset) exposed0text lines. The [project-author card](https://huggingface.co/datasets/mbien/recipe_nlg/blob/main/README.md) extract did not expose substantive licence terms. Current data contract not verified; no download/academic/noncommercial agreement accepted. Third-party research-only snippets were excluded as current primary evidence. Source=Gathered is not rights clearance, and software licence is not recipe-data licence.

## Target and next route

Based Cooking is the clearest first-party open-content partial-source lead. MealDB is a documented development prototype API with the restrictions above. They need separate provenance/licence banks. A future collector must count successful ingredient+method records after canonical-ID/content/language/cross-bank dedup against the current library. **793+440=1233is raw arithmetic, not1233complete distinct new recipes.** No1000batch is established here.

Before collection, use fresh actual ordinary/limits/time<=30seconds when an in-command quota guard is needed; fail closed on absent/unknown/ordinaryfalse or>=99with the user-authorized ceiling. Respect source-specific access, locks, pacing and backoff; no full-database/supporter limit bypass. Root may plan one collector after its current delivery. No new fetches were started here.

Modern Arab creator/YouTube priority and all-cuisine coverage including Asia/Maghreb/Gulf/Omani remain open; no inferred labels.

## Exact requests and handoff

12/12underlying requests =2queries+10open/click targets across6webtoolcalls, pre-counted before dispatch:
1MealDBdocs;2homepage;3terms;4documentedAPI;
5BasedCookinglicencequery;6RecipeNLGdiscoveryquery;
7BasedCookinghome;8RecipeNLGdataset;9availableBasedCookingfooter;
10authorRecipeNLGcard;11site-linkedBasedCookingrepo;12sample.
The counted footer read was of an available page, not a failed-URL retry. No further network.

Owned files finalized: docs/agents/modern-bulk-alternatives-20261015.md and.status.md; data/recipes/modern-bulk-source-20261015/alternatives.json. Metadata only, no copyrighted recipe bulk. No signup/payment/agreement, private account/OFF tab, media/huge download, contact, oldbook network, bypass, code/shared/Git changes.

JSON/request QA verifies12sequential records,2queries/10opens,0collected. All ownership returned.
