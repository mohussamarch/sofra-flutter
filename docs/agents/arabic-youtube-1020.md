# Arabic creator recipe batch handoff

Second bounded batch captured 2026-10-14. Data lives only in `data/recipes/arabic-youtube/second-batch-20261014/`:

- `recipes.json`: two complete, source-backed creator-site recipe records.
- `COOKBOOK.ar.md`: Arabic cookbook presentation with quantities, ordered methods, links, page-stated serving/time metadata, and known gaps.
- `validate.js`: focused local validator.

## Sources and result

Both recipes are published by Choumicha Chafay on her official site. The official site identifies its YouTube account separately; these recipe pages are explicitly records from the creator website (`sourceKind: creator-website`, `youtubeDerived: false`, `sourceVideoId: null`), not recipes attributed to videos.

1. **حريرة (حساء) بالدجاج والجزر** — [official recipe page](https://choumicha.ma/ar/recette/138-حريرة-حساء-الدجاج-الجزر.html). Source labels it Moroccan, eight servings, one-hour cooking time and 1 h 30 min total. The page has full ingredient quantities and an ordered method. It lists 50 g lentils but omits when they enter the method; it also lists salt without a clear addition step and lemon pieces without quantity. Those are called out in `unknowns` and the Arabic cookbook without invented steps or quantities.
2. **تاكرة بالأنشوفة (لانشوبة، بلم)** — [official recipe page](https://www.choumicha.ma/ar/recette/700-تاكرة-بالأنشوفة-لانشوبة-بلم.html). Source labels it Moroccan and notes that the uncovered, unglazed earthenware taqra is common in northern Moroccan cooking. Page states four servings, 30 min cooking, one hour total. Full measured ingredients and ordered method are captured; the coriander-stem amount is unspecified.

Both pages say “By Choumicha Chafay”; no guest author is listed for this pair. Cuisine status is `source-declared-pending-human-review`, based on page metadata, not inferred from creator identity. Rights and publication approvals remain null. No video/audio/image was downloaded, no transcript was used, and no page body was archived or hashed.

## Validation

Ran `node data/recipes/arabic-youtube/second-batch-20261014/validate.js`; it passed for two complete creator-site records, checking source/evidence links, Arabic ingredient and method fields, nullable unknown amounts, pending cuisine review, null approvals/rights, and cookbook coverage. No app/runtime import test was run.
