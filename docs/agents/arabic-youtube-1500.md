# Arabic creator recipe batch 3 — handoff (14 October 2026)

## Scope and result

Created only `data/recipes/arabic-youtube/third-batch-20261014/` plus this handoff and its status file. This is a small set of three verified, complete creator-site recipes from Choumicha Chafay; none is represented as YouTube-derived. Files: `recipes.json`, `COOKBOOK.ar.md`, `validate.js`.

The attempted bounded YouTube query for complete publicly accessible description text returned no candidates. Following the authorized fallback, I used three recipe pages on Choumicha's own site. The channel association is recorded separately via the official site announcement linking the `tvchoumicha` YouTube channel. Sources:

- [Milk harsha](https://choumicha.ma/ar/recette/834-%D8%AD%D8%B1%D8%B4%D8%A9-%D8%A8%D8%A7%D9%84%D8%AD%D9%84%D9%8A%D8%A8-%D8%AE%D8%A8%D9%8A%D8%B2%D8%A7%D8%AA-%D8%A7%D9%84%D8%B3%D9%85%D9%8A%D8%AF-%D8%A8%D8%A7%D9%84%D8%AD%D9%84%D9%8A%D8%A8.html): semolina cake; 6 servings, 10m cooking / 30m total.
- [Swordfish and vegetable tajine](https://choumicha.ma/ar/recette/540-%D8%B7%D8%A7%D8%AC%D9%8A%D9%86-%D8%B3%D9%85%D9%83-%D8%A8%D9%88-%D8%B3%D9%8A%D9%81-%D8%A8%D8%A7%D9%84%D8%AE%D8%B6%D8%B1.html): 4 servings, 20m cooking / 50m total; method states 20–25m on very low heat.
- [Chicken-almond bastilla](https://choumicha.ma/ar/recette/1495-%D8%A8%D8%B3%D8%B7%D9%8A%D9%84%D8%A9-%D8%A8%D8%A7%D9%84%D8%AF%D8%AC%D8%A7%D8%AC-%D9%88%D8%A7%D9%84%D9%84%D9%88%D8%B2.html): 6 servings, source metadata reports 0m cook and 2h30 total despite describing multiple cooking stages. Stored exactly as published and called out as conflicting metadata; do not treat 0m as a usable duration.

All pages say `أطباق مغربية` and attribute the recipe to `By Choumicha Chafay`. Cuisine status is source-declared, pending human review. Ingredients and steps are paraphrased in Arabic and English; exact source quantity strings are kept, unspecified amounts remain null. Every item links to the originating page. `sourceApproval`, `reuseRights`, publication date, and HTTP body hash remain null. No media downloaded; no kitchen testing or runtime import performed.

## Validation

Ran `node data/recipes/arabic-youtube/third-batch-20261014/validate.js`: passed with 3 unique recipes against prior 8, 47 bilingual source-linked ingredient facts, and 15 bilingual source-linked steps. Validator also checks official-site provenance, cuisine review status, unknowns, null rights/approval, and cookbook source links.

## Limitations / next step

This adds recipe variety (bread, seafood, filled pastry), but all cuisine labels are Moroccan because all three source pages explicitly declare the same category. No separate cuisine is claimed. The bastilla source does not specify salt/frying oil/garnish amounts or use of the egg yolk; these are surfaced as unknowns. Runtime integration, reuse rights review, attribution presentation, and cooking validation remain downstream curator decisions.
