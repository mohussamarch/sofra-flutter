# Arabic catalog 650 candidates — 21 October 2026

## Scope and result

Prepared 114 source-backed candidate records under `data/recipes/catalog-650-20261021/arabic/` for the catalog expansion. These are candidates for independent review, not 114 approved operational recipes. The source set is 103 complete Manal Alalem website facts plus 11 complete modern creator website records (2 Omani, 2 Yemeni, 4 Filipino, 2 Bosnian, 1 Tibetan). Four modern partial records were excluded: Lechon Kawali, two Delishar pastas, and Nepali Aloo Bodi Tama.

The frozen 114-row worker files used the existing `CatalogRecipe` keys and unique `ma650-` candidate/ingredient IDs, but the raw rows did not include per-record `metadataPolicy`. Root added that field during integration after source audit so nullable servings/timing/step durations remain explicit. Six data chunks contain 25, 25, 25, 25, 3, and 11 recipes; each has an adjacent `.review.json` provenance sidecar. `manifest.json` and `status.json` summarize counts.

## Source fidelity and parsing

The Manal row facts and ordered Arabic method summaries come from `data/recipes/arabic-youtube/manal-scale-20261021b/finalpackrecipes.json`; the modern rows come from their three `modern-expansion-20261021-*` source packs and the completeness decisions in `docs/RECIPE-ROUND-20261021.md` and `docs/agents/asian-recipes-20261021.md`. Sidecars record source row ID, source URL, source extract file and SHA-256, source content hash, explicit cuisine evidence, known/unknown fields, and review status.

The worker’s initial parse extracted 1,381 of 1,588 ingredient quantities when a leading amount and explicit unit were unambiguous. Root’s later independent source audit raised the numeric check count to 1,479. The 207 initially-null count is historical, not the current unresolved-quantity count. Arabic/Latin digits and clear fractions were parsed without changing original quantity phrases. No unsupported units, ranges, amounts, or zero quantities were inferred. Source-provided yields and times were copied where available; all absent servings/time/step durations remain null. 13 cuisines have direct source evidence; 101 records use `غير محدد` because their sources do not state a cuisine.

A title comparison against the current 65 records in `recipes/data/*.json` found three exact overlaps: `مكرونة بالبشاميل` (`eg-bechamel-pasta`), `كبة مقلية` (`sh-kibbeh-kibbeh-balls`), and `صيادية سمك` (`eg-sayadeya`). Their ingredients and ordered methods differ from the existing rows; the sidecars mark them as same-title variants pending a root decision. They are not counted automatically as new distinct dishes. Other semantic duplication remains for root review; source-pack duplicate reports are not a global cuisine/dish deduplication approval.

The quick filename/source-pack search found no separate 38-row earlier creator-website candidate pack. The earlier modern packs located in this checkout are represented by the 11 complete rows above; partial rows were excluded.

## Verification and limits

Worker read-back checks found 114 recipes, 114 unique IDs, 114 source sidecars, exact recipe key sets, ordered step numbering, and no null-amount scaling. The worker’s measured-quantity count was 1,381; root’s later independent source audit checked 1,479 numeric quantities. The earlier 207-null tally is historical. All 114 source extract SHA-256 values matched their referenced local extracts after resolving relative extract paths. No test suite or runtime app validation was run. Rights, nutrition, food bindings, and runtime approval remain unknown/unapproved; `runtimeReady` remains 0 in the manifest.

## Handoff

Root owns independent review and any integration. Next: review the three same-title variants, run the catalog validator with nullable-metadata policy enabled, then decide which source-backed candidates qualify for promotion. Do not include partial records or treat an evidence-complete source record as culinary, rights, nutrition, or distinct-dish approval.
