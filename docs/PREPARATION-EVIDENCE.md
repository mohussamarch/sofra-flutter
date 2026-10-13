# Preparation evidence: source index and extraction queue

`data/nutrition/preparation-sources-review.json` now indexes4official USDA sources. This is a source-guidance index, not a validated coefficient bank. `approvedFactors` and `approvedTransforms` are empty. The original ASCII data are now archived separately; documentation PDFs remain unarchived (their sourceSha256=null/sourceBytesArchived=false). The retention entry dataArchive records the data file hash and retrieval, separate from document hashes. Source review is automated research, not independent approval of food factors.

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


## First extracted retention candidates — 13 October2026

Offline importer `node tool/nutrition/import-retention.mjs` validates the original archive in research/nutrition/usda/retn06.txt against metadata SHA256/bytecount. The exact linked USDA ASCII archive contains7018rows;24published factors are blank and staynull, while an explicitly written0 stays0. Seven fields preserve source retention code/group/description/nutrient number/name/percent/rowdate plus physical line and line hash.

Nine candidates in data/nutrition/retention-candidates.json: codes0381/0382/0432 × vitaminC(401)/thiamin(404)/riboflavin(405), percent/100 only. They describe pasta boiled/drained, pasta boiled/drained then baked, and white/brown rice cooked with water retained. Independent arithmetic/source extraction review checked all9against the official PDF and physical source lines. This does not approve matching to a particular food record, product, recipe or cooking method.

Unknown source-specific license staysunknown, notFDC CC0. Raw scientific-data archive is preserved for reproducible research, with source/date/hash and general USDA government-work guidance recorded as context; no source-specific licence assertion made. Sourcebytes557859, SHA2565b71867f6649e801db3bf88c6cd1887b0673e853d4ba94aa0af2b3c091e983f9. .gitattributes -text preserves downloaded bytes acrossGit/platforms. The research archive is outside declared Flutter asset directories; only small candidate JSON is in nutritionassets, with no runtime reader or automatic transform.

Candidates remain source-extracted-unmapped, foodIds=[],massYield=null,edibleFraction=null,approvedTransformCount=0. Primary5nutrients still lack approved retention evidence. Next unit: exact food/preparation matching and explicit acceptance, source reuse review, separate mass-yield/edible-fraction evidence. Do not treat this as full cooked recipe nutrition.

Actual gate:5new retention parser/hash/unknown/regeneration tests,39combinedNode passed/0skip. Initial missingmodule red; published blank-factor parser regression red→green. No Dart/UI/API code changed, so92Flutter/analyzeclean frome023260 remain historical rather than rerun.
