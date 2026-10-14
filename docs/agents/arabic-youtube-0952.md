# Arabic YouTube and creator-site acquisition handoff

Retrieved 2026-10-14. Data batch: `data/recipes/arabic-youtube/2026-10-first-batch.json`.

Arabic cookbook companion: `data/recipes/arabic-youtube/COOKBOOK.ar.md`.

## Result

- Verified/official channel candidates: 4 (Manal Alalem, Choumicha Chafay, Chef Shaheen, Umm Ali Halabi channel).
- Public YouTube recipe-video discoveries: 14, with video IDs, titles, source URLs, and publication dates when observed.
- Usable, fully structured creator-site recipes: 6 (2 Manal official-site recipes; 4 recipes on Choumicha's official site, including a guest-attributed Meknes recipe).
- Partial YouTube description extractions: 4; zero complete video-derived recipes. Three have ingredient quantities but no ordered method, and Chef Shaheen's Iraqi maqlooba description supplies ingredients and method without quantities.
- Moroccan cuisine is an explicit creator-site classification for 4 records. This remains a candidate classification pending human review. No cuisines or recipe-family relationships are confirmed.

## Provenance and schema

Creator-owned site records use `sourceKind: creator-website`, `sourceVideoId: null`, and `youtubeDerived: false`. Channel identity is represented separately. YouTube records remain separate from those recipes. Ingredient entries include original quantity text and nullable normalized amount/unit. Each step points to its public page evidence. Null fields preserve unknowns; `sourceApproval` and `reuseRights` stay null. The Meknes tangia page credits Lalla Haniya ben Chakroun as source of the recipe; that guest attribution is retained.

All 72 ingredients and 26 ordered steps in the six complete creator-site records now include Arabic fields (`labelAr` and `textAr`) while retaining the original English labels/summaries, source quantity text, and evidence URLs. `COOKBOOK.ar.md` presents all six with source links, quantities, concise Arabic methods, and unknowns. It compares the three tangia pages and two maqluba pages using explicit differences in ingredients and methods; these are pending family proposals and have not been culinary-tested. Moroccan cuisine is labeled source-declared from official page category metadata and remains pending approval/review. For Marrakech tangia, the page's cooking-time metadata (2 h 5 min) conflicts with its method (3 h); both are preserved and flagged.

No video/audio/image was downloaded, no unofficial transcript path was used, and no source body was archived. The batch contains no content hashes. Recipe steps are concise paraphrases. Dish-name matches are only pending family proposals; no method relationship is asserted.

## Primary source evidence

- Manal identity/site: <https://www.manalonline.com/> and <https://www.youtube.com/@manalalalem>
- Manal maqluba pages: <https://www.manalonline.com/مقلوبة-الدجاج-الباذنجان/> and <https://www.manalonline.com/المقلوبـة/>
- Choumicha official channel identity announcement: <https://www.choumicha.ma/ar/actualites/سلسلة-دار-شميشة-على-اليوتيوب.html>
- Choumicha recipes: <https://www.choumicha.ma/ar/recette/1006-الطنجية-على-طريقتي.html>, <https://www.choumicha.ma/ar/recette/1010-الطنجية-المكناسية.html>, <https://www.choumicha.ma/ar/recette/1008-الطنجية-المراكشية.html>, <https://choumicha.ma/ar/recette/56-كسكس-الفواكه-الياغورت-طريقة-صيكوك.html>
- Chef Shaheen channel and recipe video: <https://www.youtube.com/@chef.shaheen>, <https://www.youtube.com/watch?v=yxXD7-Vty2k>
- Umm Ali Halabi video: <https://www.youtube.com/watch?v=-AZXPrwnGfk>

## Verification and limits

Validated the JSON with Node's JSON parser and checked the counts (14 discovered videos, 6 complete creator-site recipes, 4 partial YouTube extractions, 72 translated ingredient labels, 26 translated steps). This is a data handoff only; no app/runtime import or schema preflight was run. Rights, publication approval, nutrition, and popularity were not established.
