# Local recipe curation 0241 — sixth archived batch

Date: 2026-10-15. Selected checkout: `E:\work\SOFRA\app`, as assigned. This subtask owned only `data/recipes/curated-local/sixth-reviewed-20261015/**`, `tool/recipes/curated-sixth-build.mjs`, `tool/recipes/curated-sixth-build.test.mjs`, and these two agent notes. No shared docs, queue, Flutter assets, manifest, or Git integration files were changed. No network requests, source acquisition, credits, quota reset, or kitchen testing.

## Work completed

Processed four fixed Wikibooks revisions already present in the archive:

| Source page / revision | Arabic draft | Exact source category |
|---|---|---|
| 6493 / 4514673 | زلابية مجرية محشوة بالجبن | `Category:Hungarian recipes` |
| 32960 / 4512993 | أرز بمرق السمك (صيادية) | `Category:Lebanese recipes` |
| 457155 / 4518412 | شوربة الفول السوداني الغانية (نكاتن-كوان) | `Category:Ghanaian recipes` |
| 456772 / 4509838 | لحم مشوي تنزاني (نياما تشوما) | `Category:Tanzanian recipes` |

The pack has 38 listed ingredient lines, 3 procedural supplemental lines, and 30 Arabic steps. All four are `needs-review`; none is fully specified, cookability-approved, runtime-ready, nutritionally accepted, or kitchen-tested. Across the six local packs: 48 records, 340 listed ingredient lines, 23 supplementals, 250 steps, 10 fully specified, 36 needing review, 2 not cookable, 42 source-category labels, and 0 runtime-ready.

Amounts and facts that do not fit an exact field remain unknown or explicitly described: dumpling filling/yield; fish’s conflicting ~2 lb / 1 kg estimates and broth-to-rice 1–4 range; Ghana soup yield and unspecified chicken simmer, plus salt/chili amounts only in method; nyama choma’s four meat alternatives, heaped spoon measures, unknown grill time, and source-only doneness language. Source categories are exact evidence, not approved cuisine. No food binding, nutrition, scaling, legal page-exception decision, or safety claim was added.

The builder pins all five previous pack byte hashes and each original source revision, source text SHA, source/parsed fingerprints, license snapshot, exact raw source snapshot bytes, preflight draft bytes, and normalized record content. Dedup compares selected source IDs, title/family identities, exact selected cuisine labels, the prior five local packs, archived creator records, and 54 catalogue titles. It makes no global 6056-record uniqueness claim. Outputs include review decisions, full source snapshots, preflight drafts/reports, `normalized-recipes.json`, readable `COOKBOOK.ar.md`, and `review-report.json`.

## Verification

- `node tool/recipes/curated-sixth-build.mjs` completed offline; 4 records, 38 ingredient lines, 3 supplementals, 30 steps, labels `hungarian`, `lebanese`, `ghanaian`, `tanzanian`; pack SHA256 `bf8453d0ac1c7f3caaef4b48083a780b9211f02b147ba7bd0309cc9572854a84`.
- `node --test tool/recipes/curated-sixth-build.test.mjs`: 3/3 passed. Tests check exact source pins and provenance, step/ingredient completeness, unresolved fields and non-runtime status, plus byte-for-byte offline rebuild of pack, cookbook, report, decisions, snapshots, and preflight drafts.
- The test's first run caught an assertion-pattern typo; it was corrected and the final 3/3 run passed.

## Next action / ownership

Return this bounded pack to root for independent review and any shared manifest/library integration. Do not add further candidates in this subtask. No Git commit or push was made; root owns Git integration.
