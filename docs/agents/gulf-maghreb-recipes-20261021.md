# Gulf and Maghreb modern recipe source assessment — 2026-10-21

## Scope and result

Bounded discovery for modern Arab cooking creators, prioritizing Omani sources and explicit regional cuisine evidence, within the assigned 12-target ceiling. The checkout named for this task is `E:\work\SOFRA\app`, base `8012d7943fc0243e83bef38e482e2ff2d39f74ce`. The app worktree status command reported “this operation must be run in a work tree”; no Git operation or shared-file edit was performed.

Fresh quota check at start: primary 4%, weekly 1%, `ordinaryUsageAllowed=true`; credits balance 0. No credits/reset used.

| Result | Count |
|---|---:|
| Underlying discovery targets | 12 (5 search queries + 7 URL opens/clicks) |
| Actual recipe records acquired | 0 |
| Accepted / duplicate / rejected records | 0 / 0 / 0 |
| Ingredient lists or methods transcribed/summarized | 0 |
| Crawl/import, media, account, or external contact | 0 |

The zero counts are actual record counts, not a count of candidate links. No candidate was screened far enough under the target ceiling to become a complete source-backed record with both ingredients and method.

## Findings by cuisine

### Morocco — explicit source attribution found; rights and scale unresolved

The [official Choumicha website](https://www.choumicha.ma/ar/) identifies itself as the official site and explicitly lists an “أطباق مغربية” (“Moroccan dishes”) category. Its home page exposes separate recipes and videos sections, newer recipe/video links, and pagination. It shows 12 items in one latest-recipe carousel and 20 selected recipes; this is not the size of the full catalog. The [recipe page for المخرقة / الشباكية](https://www.choumicha.ma/ar/recette/166-%D8%A7%D9%84%D9%85%D8%AE%D8%B1%D9%82%D8%A9-%D8%A7%D9%84%D8%B4%D8%A8%D8%A7%D9%83%D9%8A%D8%A9.html) opened, but I did not fetch its detailed body or extract it within this cap.

The site’s reuse terms and `robots.txt` were not checked. Bulk access/republication permission is unknown. Do not crawl/import this route until a future capped review establishes applicable terms, robots guidance, and enough enumerated complete recipes to assess scale. This is the strongest route for a further **assessment**, not an eligible bulk source yet.

The [Cuisine Salima home page](https://www.cuisinesalima.com/) identifies the publisher as Salima in Casablanca, Morocco, describes the recipes as Moroccan, and says each recipe has a video and that a new recipe is sent weekly. Its linked terms and a linked individual recipe both failed to open; the direct results therefore establish neither ingredient/method completeness nor reuse permission. Claimed pace is not total catalog scale. No records acquired.

### Oman — cuisine attribution surfaced; no eligible modern creator route established

Search indexing surfaced an [Omani shuwa recipe page](https://eeina.com/recipes/omani-shuwa.html) whose title and text identify the dish and cuisine as Omani. The direct open failed with a cache miss. It is not established as a modern Arab creator source; no record was acquired.

Search indexing also surfaced a secondary profile for Chef Mohammed Moosa / Chef JJ’s Kitchen describing him as an Omani chef and content creator, but the snippet describes English-language and world/Arab cooking. No primary source was opened to verify identity, Arabic content, a recipe catalog, reuse rights, or scale. It is a lead only and does not establish an Omani source collection.

### Yemen, Tunisia, Algeria — no qualifying primary source established

A result for a Yemen Youth television page indexed a Ramadan cooking-series listing with Yemeni and other regional dishes. Its direct page open failed. The episode listing does not provide a validated official creator identity, recipe ingredients plus method, reuse rights, or collection scale. It was not used to create recipes or cuisine bindings.

No primary source with explicit Yemeni, Tunisian, or Algerian attribution, complete recipe pages, and usable terms was established in this 12-target pass. Search wording/language was not treated as cuisine evidence.

## Request accounting

The 12 underlying targets, in order, were:

1. Search query: Arabic Omani chef / YouTube recipes.
2. Search query: Omani cuisine recipe site / chef.
3. Search query: Yemeni cooking channel / recipes.
4. Search query: Moroccan chef recipe site / terms.
5. Direct open: Eeina Omani shuwa (failed cache miss).
6. Direct open: official Choumicha home page (opened).
7. Direct open: Cuisine Salima home page (opened).
8. Direct open: Yemen Youth indexed episode listing (failed cache miss).
9. Click/open: Cuisine Salima linked recipe (failed).
10. Click/open: Cuisine Salima linked terms (failed).
11. Click/open: Choumicha المخرقة / الشباكية recipe page (opened; detailed recipe body not extracted).
12. Search query: modern Omani cooking / Omani chef recipes.

No retries were issued. No video, audio, transcript, API, or media was accessed. No 403, robots block, or other access denial was bypassed; failed opens were left as failures. Terms and robots were not verified for either Moroccan route, so neither is approved for bulk collection at handoff.

## Batch target and shortfall

The round’s desired batch is at least 1,000 actual complete recipes. This pass is 0/1,000, a shortfall of 1,000. The pass was discovery-only and intentionally stopped at the coordinator’s 12-target boundary before an additional source assessment or any expansion of a crawl. The shortfall is caused by unresolved permission/robots conditions, unverified completeness and scale, and an absence of a verified scalable Omani source. Moroccan creator content is visible, but its existence does not establish republication permission or 1,000 complete distinct recipes.

## Coordinator checkpoint before any larger crawl

Proposed first route for further assessment: the official Choumicha Morocco site, starting from its explicit Moroccan category and recipe/video indexes. Before a larger crawl, verify `robots.txt` and relevant site terms, determine whether ordinary personal research permits the proposed access and whether any license grants downstream reuse, then enumerate category/page counts and sample a few source records for complete ingredient and method coverage. At present:

- route: official creator/publisher site and explicit Moroccan category;
- terms: not checked; reuse permission unknown;
- robots: not checked;
- scale: home-page modules show 12 latest-carousel items and 20 selected recipes, but total category/catalog size is unknown;
- record quality: one recipe URL opened, no detailed record acquired;
- decision: do not expand into bulk access/import yet.

If terms or robots do not allow the intended access, stop that route. Do not contact the creator, sign up, pay, or bypass a block. A future intake must preserve source URL and source evidence, use original concise Arabic method summaries, keep unstated amounts/time/yield null, set `research/runtimeReady=false` and nutrition null, and not assign food/family bindings without evidence.

## Exact next action

Coordinator may decide whether to allocate another bounded assessment pass to Choumicha’s terms/robots/catalog size and to an Omani primary creator route. No source record is ready to integrate from this pass. The handoff status file is `docs/agents/gulf-maghreb-recipes-20261021.status.md`.

## Continuation — bounded Omani extraction, 2026-10-21

The coordinator authorized an additional actual-extraction pass of up to 24 underlying targets and specifically prioritized Dina Macki / Dine with Dina. Fresh quota before research: primary 9%, weekly 1%, `ordinaryUsageAllowed=true`; no credits/reset used. The work used **13/24 targets** (7 search queries + 6 source URL opens/clicks).

### Actual records

Created `data/recipes/arabic-youtube/modern-expansion-20261021-gulf/recipes.json` with two complete source-backed records, plus compact evidence captures under `source-extracts/`:

1. `dina-macki-tuna-dried-lime-zaatar-cinnamon-stew` — 15 listed ingredient lines, 5 source steps, cuisine label “Omani”. Source: https://dinewithdina.co.uk/recipes/tuna-dried-lime-zaatar-cinnamon-stew/. Extract SHA-256: `ada33fe18c27c9ac50e7f8f33678c94b246d7a364334b700cc2ac21957fd54f8`; record SHA-256: `b9666b5592d4f15e19bd2b1c4dfc5d7bbee03908b50af83759666c7a168c9d62`.
2. `dina-macki-paplo-omani-balochi-lemon-fish-curry` — 11 listed ingredient lines, 6 source steps, cuisine label “Omani”. Source: https://dinewithdina.co.uk/recipes/paplo-omani-balochi-lemon-fish-curry/. Extract SHA-256: `a34096aa8b55931353b89b4504ea4be694d3645a2c4520172a0d0c041d0c4383`; record SHA-256: `e22e27aceac864de76db6795db8d683c08811615d707d14ccd933aebf022c3bc`.

Combined result: **2 accepted complete records, 26 ingredients, 11 steps, 0 exact duplicates, 1 rejected source candidate**. The rejected candidate is Dine with Dina’s Tuna Kebab & Dried Lime Curry page: it failed direct open twice, and search only returned index/home/about pages, so no ingredients or method were accepted. Two exact source URL matches and two exact normalized ingredient-plus-method duplicate matches were checked against all **4,530** current manifest rows; none matched. This is exact-signature deduplication, not semantic or unique-dish certification.

Both accepted pages explicitly label cuisine “Omani”; that page label and the index category were used, not author nationality. Each record preserves English `sourceQuantityText`, Arabic ingredient labels, zero-based source ingredient/step indexes, and concise original Arabic method summaries. Unspecified yield/publication date/overall duration remain null. The tuna stew water range and Paplo coriander approximate range remain in source text with numeric amount null; the source’s per-stage times are preserved separately. Paplo’s “30 - 60” badge remains identified as a category band, not an exact overall time. Serving rice mentioned only in method is recorded as unquantified supplemental serving information. `runtimeReady=false`, nutrition null, source approval/reuse rights null, and food bindings empty.

Evidence files preserve exact displayed titles, ingredient lines, source cuisine, and a concise step-index summary, but are not raw HTML archives. `httpBodyHash` is null. Full public recipe pages rendered in research without media or transcript access. No account, payment, contact, or access workaround was used. The two records are for research facts and data review; reuse license is still unknown and this is not bulk crawl authorization.

### Request accounting

The 13 targets were: (1–3) three DineWithDina/Omani discovery queries; (4) official home page; (5–8) clicks to the stew page, tuna-kebab page, Paplo page, and recipe index; (9) a search for Omani recipes on the creator site; (10–11) a second tuna-kebab page open and a search for its ingredients/method; (12–13) two targeted Omani page-content searches. The tuna-kebab failure was not bypassed. No media, auth, signup, or external contact.

### Verification and handoff

The JSON parsed while computing canonical fingerprints from the existing stable-key SHA-256 routine; extract and recipe hashes are pinned in the pack. A read-only comparison covered all 4,530 manifest recipe rows and found no exact source URL or ingredient-plus-method matches. No application tests or shared-file changes were made. Pack SHA-256: `891807ec2bc92e521b4d24a93bb73aa1705613271409aa25af7dbe8a8e5fa30d`.

Cuisine support from this continuation: Omani 2; Yemeni 0; Moroccan, Tunisian, and Algerian 0 (not targeted). The earlier bounded 12-target lead assessment remains described above and is not counted as this extraction pass. Coordinator owns any global manifest integration and final Git/handoff updates.

## Continuation 2 — remaining-target extraction, 2026-10-21

The coordinator directed use of the remaining 11 targets in the 24-target cap, continuing with Dine with Dina and using an accessible Yemeni primary creator if available. Fresh quota check before this continuation: primary 21%, weekly 3%, ordinary usage allowed. Targets 14–24 are recorded in the pack; total usage is exactly 24/24 (13 queries and 11 URL opens/clicks). No additional targets were used.

### Cumulative actual records

The pack now contains **4 complete records**: 2 explicitly Omani from Dine with Dina and 2 explicitly Yemeni from Sifra Foods. Totals: 58 main ingredient lines, 10 supplemental ingredient facts, and 29 summarized method steps. Against all 4,530 existing rows, there are 0 exact source-URL matches and 0 exact normalized ingredient-plus-method matches. Two candidates were rejected: Dine with Dina’s Tuna Kebab page failed direct access after two attempts, and other Sifra indexed snippets did not show complete ingredients and methods. Relative to the coordinator’s aim of 8 records, the shortfall is 4.

Dine with Dina’s observed Omani index/category exposed only three Omani recipes; two were complete and extracted, while Tuna Kebab remained inaccessible. Sifra Foods’ About page attributes the creator’s family recipe project to Yemeni food; its index linked a Yemeni Classics category. The directly opened Oxtail Yemeni Marag page timed out, but the primary-site indexed result visibly contained its full 19-line ingredient list and 12 directions. The same result contained a complete 13-line ingredient list and 6 directions for Yemeni Chicken in Marag. Other snippets were incomplete and excluded. No cuisine was inferred from creator nationality alone.

The two Sifra items are marked as primary-site indexed extracts, with no raw body archive and no claim of direct-page retrieval. Exact amounts, method conflicts, dates, and null unknowns are captured in the records/evidence files. All records remain research-only: reuse rights/source approval unknown, runtime false, nutrition null, and no food bindings. No media, authentication, signup, payment, contact, or access workaround was used.

### Final evidence pins

Pack SHA-256: `898c7b152b4e0f81b0fbee603e1e21857fd473ddccd32322bcfc0b8a90846bba`.

| Record | Source extract SHA-256 | Canonical record SHA-256 |
|---|---|---|
| Tuna, Dried Lime, Za’atar & Cinnamon Stew | `ada33fe18c27c9ac50e7f8f33678c94b246d7a364334b700cc2ac21957fd54f8` | `b9666b5592d4f15e19bd2b1c4dfc5d7bbee03908b50af83759666c7a168c9d62` |
| Paplo – Omani-Balochi Lemon Fish Curry | `a34096aa8b55931353b89b4504ea4be694d3645a2c4520172a0d0c041d0c4383` | `e22e27aceac864de76db6795db8d683c08811615d707d14ccd933aebf022c3bc` |
| Oxtail Yemeni Marag | `6693425b7d6ef67e559db3144191f736277fbfc8b99ba96ba3f5b46ea3332c37` | `f98727a53680a58719712171f4ac6aa0d29d0ce96c62842a4b657a35afc67e77` |
| Yemeni Chicken in Marag | `aaab398d0d9cadbf91767331928b74ec94ffdadc822ef270e00f7835f157faaa` | `e794d89f51b9371afc03e996752e0f1dfb4f6f985e1bdbae5d71c52695aa4898` |

No shared files or Git state were modified. The coordinator owns any integration and final repository status update.

## Offline integration review — 2026-10-21

Reviewed the 15 modern rows across the Gulf (4), Asian (8), and Balkan/Tibetan (3) packs using only their saved JSON and compact evidence files. No network was used. All 15 source URLs are distinct; exact normalized `sourceQuantityText` ingredient lists plus Arabic method summaries produce no duplicates. Every saved extract hash matches its pack pin. All 15 rows keep `runtimeReady=false` and `nutrition=null`. Cuisines are supported by explicit recipe/page labels or content evidence, not creator nationality alone. The Gulf records’ dates/unknowns match their evidence captures; no Gulf correction was needed.

### Cross-pack issues for coordinator review (no edits to other packs)

- `panlasang-pinoy-lechon-kawali-20261021`: evidence states 7 source steps, while the row maps only indices 0–2. The 3 Arabic summaries may consolidate the method, but they do not preserve the stated source-step index coverage; correct the count/mapping or document the consolidation explicitly before treating the index set as source-native.
- `delishar-singapore-chilli-crab-cream-pasta-20261021` (7 source steps) and `delishar-singapore-chilli-crab-cake-pasta-20261021` (9) map only indices 0–3. Their evidence summaries also contain four grouped paraphrases. This appears to conflate summary segment indices with source step indices; verify/remap the source coverage.
- `nepali-food-recipes-aloo-bodi-tama-20261021`: evidence says 13 source steps; row maps indices 0–3. The ingredient extract is explicitly from the primary-site index and direct page supports method/cuisine, but four summary segments do not show coverage of all 13 source-step indices. Clarify/remap.

The Gulf extract index coverage is complete: stew 0–4/5, Paplo 0–5/6, Oxtail 0–11/12, Chicken Marag 0–5/6. Gulf records also preserve explicit ingredient ranges as source text without coercing them to scalar amounts; unquantified water/yield/time stays null, conditional Hawayij spices remain supplemental, and optional Sazon/peppers remain marked. Oxtail and Chicken date claims appear in the compact captures. The two Omani pages explicitly label Omani; both Yemeni recipes explicitly identify Yemeni, with creator About evidence noted. No exact duplicate or source/hash mismatch was found.

### Coverage and evidence limits

The Balkan/Tibetan pack’s saved evidence and summaries are consistent: tepsijas includes 8 detailed method facts mapped across 0–7, soup includes 5 facts mapped across 0–4, and Thue includes 6 facts mapped across 0–5. Their extracts do not state a separate source-step count, so the review verified evidence-to-summary consistency, not an independent source-native count. Rice/flour/pan-grease and thue decoration/ice-water facts are separated as supplemental where unquantified; optional egg/butter/parsley status follows the evidence. Yield and date fields were preserved where present; Thue’s yield is two bricks, not servings.

Review result: all 15 rows have distinct source URLs and none are exact normalized content duplicates. All 15 evidence SHA pins, runtime false, and nutrition null checks passed. Source-completeness claims are supported by the saved captures, subject to the source-step-index representation issues listed above. No Gulf pack change or shared-file edit was needed.
