# Planning cuisine inventory and candidate readiness — 2026-10-21

Read-only audit of `E:\work\SOFRA\app`; checkout HEAD was verified by the coordinator as `91754179a00f4e69e7ab4040c684ddf1a8b13757` (the older `8012d...` is a previous base). No source rows, catalog files, app code, manifests, or Git state were changed.

## Why the app has four cuisines

The shipped planning catalog is an explicit allow-list in `recipes/data/index.json`: Egyptian (12 recipes), Levantine (14), Saudi (14), and Italian (14), for 54 recipes total. This is separate from the 5,545-record source library. The library loader deliberately exposes read-only evidence and keeps it out of planning/runtime approval.

Corrected source-field inventory: 1,011 rows have a nonempty structured `cuisines` array; 27 more carry a direct nonempty `cuisine` value, for 1,038 rows with structured cuisine labels. Separately, 911 rows have `sourceCategories` and 440 have `sourceTags`; these are not automatically cuisine approvals (many are ingredient, dish-type, or broad category tags). Do not call the other 4,507 records “untagged”: absence in one cuisine field does not imply absent labels in other fields, and source categories/tags have different meaning.

The source labels have not passed the catalog's review gates. The selected offline archive recipes are generally English, without Arabic names, ingredient labels, or method translations; extracted rows retain blockers for independent culinary, quantity/form/scaling, inventory identity, and per-page rights review. Source-language, a source tag, or a cuisine claim is not runtime/planning approval. All 12 candidates below retain their source snapshots and exact source revision/URL. Each has complete numeric ingredient amount+unit fields and a positive integer source-servings yield; times below reproduce only recorded source evidence. No missing time was filled in.

## Candidate readiness matrix

All candidates are from pinned Wikibooks Cookbook CC BY-SA 4.0 snapshots. The source `perPageLicenseApproved` gate is false for every row, so they are review candidates, not catalog approvals. “Amounts” is accepted numeric amount+unit lines / total ingredient lines. Source yields retain source `source-servings` meaning and are not converted to app servings here.

| Source ID / dish | Source cuisine evidence | Amounts; source yield | Source timing evidence | Remaining blockers |
|---|---|---|---|---|
| `curated-local:455788` Sweet Mango Lassi | Indian, “Category:Indian recipes” | 4/4; 6 | No time published | Arabic translation; culinary and rights review |
| `curated-local:80271` Pikelet | Australian + New Zealand source categories | 7/7; 15 | 120 min fermentation; ~2 min per side | No total time; serving interpretation, Arabic, culinary and rights review |
| `curated-local:456807` Alkubus | Hausa category; northern Nigeria description | 6/6; 4 | 60 min fermentation | No total/cook time; Arabic, culinary and rights review |
| `curated-local:483763` Msemmen | Algeria and Morocco | 8/8; 8 | Declared 90 min; rests 30 + 15 min | Confirm timeline; Arabic, culinary and rights review |
| `curated-local:7299` Sheer Khurma | Indian cuisine | 11/11; 12 | Approx. 2 min initial simmer only | No total time; Arabic, culinary and rights review |
| `curated-local:11375` Hominy Grits | Native American source cuisine label | 4/4; 8 | Declared 30 min; 20 min cooking step | Arabic, culinary and rights review |
| `curated-local:108458` Spicy Tomato Soup | American source cuisine label | 7/7; 4 | Declared 60 min; 20–30 min simmer | Arabic, culinary and rights review |
| `curated-local:130025` Percolator Punch | American source cuisine label | 8/8; 10 | Declared 15 min; 10 min heating | Arabic, culinary and rights review |
| `curated-local:141020` Strawberry and Yogurt Eton Mess | English recipe category | 6/6; 4 | Declared 10 min | Arabic, culinary and rights review; “fully-specified” source status is not runtime approval |
| `curated-local:245915` Eärgon Salsa | Mexican recipe category | 4/4; 4 | Declared 5 min | Arabic, culinary and rights review; “fully-specified” source status is not runtime approval |
| `curated-local:385022` Spanish Potato Omelette | Spanish recipe category | 5/5; 4 | Declared 20 min; first side 7–8 min | Culinary review; Arabic and rights review |
| `curated-local:127705` Frijoles Antioqueños | Colombian recipe category | 10/10; 6 | Source says overnight soak / one-day total and 1 h cooking; pressure steps 30 min, optional-meat step 30 min | Preserve source timing text; Arabic, culinary and rights review |

Two additional fully quantified rows were intentionally held out of the first-priority 12 because source timing conflicts are already recorded: `curated-local:96175` Irish Soda Bread (header says 50–70 min baking; procedure says 65–70 min; prep 15 min) and `curated-local:164154` Whole Wheat Irish Soda Bread (declares 60 min total although baking alone is 65–70 min). Do not silently choose one source value. Naan was also held out because its declared two-hour total conflicts with a 2–3-hour rest plus 4–5-minute baking; two rows marked `not-cookable` were excluded.

## Evidence and reproducibility

- Pinned source manifest: `data/recipes/curated-local/flutter-manifest.json`, SHA256 `1fb26f05cfdc56dfb954edc77f87952bbf67edc5d4f1ad3616d57937d612f04a`.
- Candidate normalized packs: first-review SHA256 `2e8b81cba110ea979f6199dd0a7e8e67c9626e3081c98491897b83664d032946`; gap-review `9b4e2d203b80dd25c9c1392ef7b35d3dab097e0fc5e67cbee5a43908851aa4e5`; third-review `bef4b419623fd9a981d131232d04b5aa52e1d9e2fab50a0f57b5a313fe821d21`; fifth-review `1df899307df2cf630c3fe850dc5ddb997a1f179dd8a1e2ea67bdb7eb77fbf6be`.
- Reproducible count: parse the pinned manifest, read every manifest pack, and count nonempty cuisine arrays/direct cuisine values separately from `sourceCategories` and `sourceTags`; no language/name inference. Candidate filter: curated-local, explicit cuisine object with source evidence, each ingredient has finite positive numeric `amount` and nonempty `unit`, positive integer yield with source-servings unit, and nonempty steps. Matrix values were then read directly from each matching normalized row and its pinned provenance; no parser, network, converter, or project tests run.
- Snapshot paths and SHA pins for each candidate are in `provenance.sourceSnapshotFile` and `provenance.sourceSnapshotSha256` in the normalized rows.

Suggested next step: review the 12 first-priority source transcriptions and legal/culinary gates, translate only after that review, then have the catalog owner decide which candidates to integrate. No source record is promoted by this report.
