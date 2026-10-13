# Preparation evidence: source index and extraction queue

`data/nutrition/preparation-sources-review.json` now indexes4official USDA sources. This is a source-guidance index, not a validated coefficient bank. `approvedFactors` and `approvedTransforms` are empty. No source bytes were archived; sourceSha256=null/sourceBytesArchived=false explicitly preserve that distinction. Source review is automated research, not independent approval of food factors.

| Source | Use | Limit |
|---|---|---|
| [Foundation documentation](https://fdc.nal.usda.gov/Foundation_Foods_Documentation/) | Forms, refuse and edible basis semantics | No universal yield or preparation match |
| [Retention Release6](https://www.ars.usda.gov/ARSUserFiles/80400525/Data/retn/retn06.pdf) | Nutrient-specific food/preparation rows, December2007 | Selected vitamins/minerals/alcohol; no universal macro multiplier or mixed-dish factor |
| [Food Buying Guide](https://foodbuyingguide.fns.usda.gov/Home/About) | Average purchase/serving-yield context | U.S. institutional child-nutrition planning; exact row assumptions required |
| [FDC datasets](https://fdc.nal.usda.gov/download-datasets/) | Versioned records and field definitions | Raw/cooked record choice is not a yield/retention factor |

FDC API guide states CC0 for **FDC data**. Document/page/PDF reuse license is recorded as unknown, not inherited automatically from the data licence. Other sources' data/document licenses remain unknown until verified. No coefficient or document redistribution license is claimed.

Keep three quantities separate: edibleFraction=edible/as-acquired mass; massYield=prepared/input edible mass; nutrientRetention=nutrient amount remaining under a matching preparation. Added water/oil or a mixed recipe cannot be represented by one assumed multiplier. Do not apply raw retention again to an already cooked nutrient record. Existing PreparationTransform accepts retention0..1; any source value outside that model needs diagnosis, not clipping or invented1.

Next: verify an exact source row and reuse terms; retain archive URL/date/hash or document no archive; record food state/method/category/nutrient/unit and value/basis/page/row. Keep rows as candidates until exact food/preparation matching and an independent review. Extract retention and mass yields separately. The primary5display nutrients may still be unknown after Release6 because table coverage differs from the49stored definitions. No prepared bechamel/full recipe result has been certified.

Node source gate checks primary USDA URLs, required metadata, separate licence fields, null unarchived hashes, distinct quantity concepts and empty approval lists. JSON is validated; source index does not silently feed runtime transforms. Source-review handoff is work/agent-handoffs/preparation-sources.md with compact status sibling.
