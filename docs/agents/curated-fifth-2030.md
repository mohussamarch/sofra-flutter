# Handoff: curated fifth archived recipe batch

## Scope and ownership

- Completed the coordinator's offline, bounded curation task in the sole checkout `E:\work\SOFRA\app`, branch `main`.
- Owned files: `data/recipes/curated-local/fifth-reviewed-20261014/**`, `tool/recipes/curated-fifth-build.mjs`, `tool/recipes/curated-fifth-build.test.mjs`, and this handoff plus `.status.md`.
- No source requests, book acquisition, quota use, resets, or purchases. All source records came from the existing fixed Wikibooks archive. The archived index identifies 3,796 source revisions and 3,640 parseable recipe pages; the broader 6,056-record research baseline remains research-only and is not a global unique-recipe claim.
- The collector was not run. Builder verifies the authoritative source-file, parsed-file and category-observation SHA pins before using the selected revisions.

## Selection and records

Programmatic selection required an exact source category absent from the previous local labels, at least five ingredient lines, and at least five method steps. Candidate texts were opened only for the eight selected revision IDs. The exact source categories, rather than the English source language or title, support these labels:

| Revision ID | Arabic title | Exact archived category | Source yield / time evidence |
|---|---|---|---|
| 18875 | فرغِسه تيرانا بالفلفل | Albanian | 4 servings; no aggregate time |
| 179898 | ألفاخوريس محشوة بدولسي دي ليتشي | Argentine | 40 cookies; total time absent; 15-minute bake phase |
| 179962 | يخنة فطر الشانتيريل النمساوية | Austrian | 4 servings; “25 min” header conflicts with “usually less than 25 minutes” text |
| 18333 | كفتة بلغارية مشوية (كيوفتِتا) | Bulgarian | yield/time absent; source says 15 minutes or browned, then 5 minutes |
| 127705 | فاصوليا أنتيوكيا الكولومبية | Colombian | 6 servings; header says cooking 1 hour and total 1 day, method starts with overnight soak |
| 110217 | بيكاديو كوبي باللحم والزبيب والزيتون | Cuban | 6–8 servings; 1-hour source header |
| 8658 | مجدّرة فلسطينية بالأرز أو البرغل | Palestinian | 3–4 servings; 30-minute header conflicts with listed phase durations and onion frying |
| 38143 | أريسا جوهور الماليزية بالدجاج والشوفان | Malaysian | yield/time absent; chicken count and 1.2 kg attribution unclear; method adds 12 unspecified glasses of water |

The English source URLs are revision-specific and recorded with their retrieval and revision timestamps. Each full raw and parsed source snapshot retains CC BY-SA 4.0 attribution and the global license evidence fingerprint; page-specific exceptions remain unreviewed. The Arabic text is a concise ordered adaptation with a change notice. It does not claim new-book rights clearance, kitchen testing, national cuisine approval, or nutrition quality.

Source ranges, alternatives, optional components, and absent values remain explicit. In particular, the vinegar range, cheese/fat/grain/meat choices, unsized water glass, and missing recipe yields were not guessed into quantities. The one procedural water line for Arisa remains a supplementary ingredient with null amount/unit. Clearly stated single phases and ranges are carried in structured step durations; endpoint-qualified/ranged phases do not become fixed preflight timers. Aggregate source-time conflicts remain unresolved.

## Before and after

- Local archived pack count: 36 → 44 (+8); culinary statuses: 10 fully specified, 24 → 32 needs review, 2 not cookable. The eight additions are all needs-review.
- Local source ingredient lines: 218 → 302 (+84); supplemental/procedural lines: 19 → 20 (+1); ordered steps: 161 → 220 (+59).
- Local exact source cuisine/region labels: 30 → 38 (+8). These are source-supported categories, not approved national cuisines.
- Exact IDs, title strings and family IDs were checked against all 36 frozen local records and 19 creator website records. Exact planning-catalogue title matches: 0. No global or cross-language duplicate claim was made.
- Runtime-ready: 0 additions; nutrition/food bindings: null; all eight preflight drafts incomplete; 278 preflight issues remain. Existing manifests, old packs, original 54 planning recipes, and source bytes were not modified.

## Files and verification

- Pack and compact cookbook: `data/recipes/curated-local/fifth-reviewed-20261014/normalized-recipes.json`, `COOKBOOK.ar.md`.
- Decisions, eight immutable source snapshots and eight preflight drafts are in the same folder. `review-report.json` records counts, source fingerprints, exact new labels, time/quantity conflicts, and unresolved gates.
- Rebuild: `node tool/recipes/curated-fifth-build.mjs`.
- Focused verification: `node --test tool/recipes/curated-fifth-build.test.mjs` — 6/6 passed. Rebuild was reproduced byte-for-byte; all four older pack SHA pins and the selected source, rights, record, and snapshot fingerprints were checked.
- New normalized pack SHA256: `1df899307df2cf630c3fe850dc5ddb997a1f179dd8a1e2ea67bdb7eb77fbf6be`.
- Archived input evidence SHA256: source pages `93e85705e9141453d5708622c321c17fc793b4fbacfb0663d079fd365e1385d0`; parsed recipes `b03a74dbe473f11d42d9a7456834d930384c3188d2cf6cae512dfe3cbb50dad5`; category observations `44b3f050f8fb7ed4bed800554d280e8f9251ea58830e90257f18049ecd70f350`.
- Builder SHA256: `270d11ed0a79e5c49c6303af23892df712211c9b3ddde4c240be473dc914a634`; test SHA256: `bf03c894b03ff3c2059b7c562d672425519d4ea4eb5f6ac34960e0bd03318037`.

## Next action and ownership return

Ownership of all assigned files is returned to the coordinator. The coordinator can review the Arabic adaptations and remaining quantity/time notes, then decide whether to register and collect the pack into the selected library. This batch is not registered, shipped, or runtime-approved. The coordinator owns shared docs, aggregation, and Git.
