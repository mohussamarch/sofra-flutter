# Preparation evidence source review

- Checkout: `E:\work\SOFRA\app`; base commit: `49c274f`.
- Objective: build a small authoritative source index for preparation evidence, separate from product collection and recipe implementation.
- Added `data/nutrition/preparation-sources-review.json` (schema 1) with four official USDA references: Foundation Foods documentation, Nutrient Retention Factors Release 6, Food Buying Guide yield methods/tables, and FoodData Central downloadable datasets.
- Verified source descriptions, raw/cooked and refuse field semantics, retention-method distinctions, and the guide's average planning-yield context. Release 6 document identifies December 2007; the FBG index dates grains yields 2026-03-25 and meat yields 2026-09-02; page-level publication dates are recorded as undocumented where absent.
- FDC documentation explicitly cites CC0 1.0. For the separate retention and Food Buying Guide pages, explicit license evidence was not found and is marked unknown.
- Kept mass yield, edible fraction, and nutrient retention as separate quantities. No coefficients were extracted or approved. No mixed-recipe transform, proxy cuisine, clinical rule, or OFF collection is claimed.
- Applicability is limited: the FBG serves U.S. child-nutrition purchasing/production; its rows require exact-form review. It does not establish bechamel pasta or a finished mixed dish.
- Validation: JSON parsed; source IDs and URLs unique; required source fields present; all four entries state limitations and review status. No tests or app changes run.
- Exact next action: root reviews this index, then integrates only suitable source evidence into its separately owned compound-revisions work. Any later factor extraction needs a row-level match and independent review.
- This handoff records base `49c274f`; no commit/push was performed by this subtask. Preview server state not inspected or changed.


Coordinator correction after source-index review: FDC API-guide CC0 applies to FDC DATA, not automatically to the documentation PDFs/site text. The bank now keeps dataLicense/evidence separate from documentLicense=unknown. No source bytes were archived, so sourceSha256 remains null and sourceBytesArchived=false; this is a metadata index, not a hashed factor archive. Root is integrating this as the first preparation research unit; actual extraction and transformation remain next, not part of the compound-code unit.
