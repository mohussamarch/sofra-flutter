# Local recipe curation 0259 — seventh archived batch

Date: 2026-10-15. Selected checkout: `E:\work\SOFRA\app`; assigned base `153d45d2d4606c7ee4a4cd7806c9012272584122`. This bounded subtask owns only `data/recipes/curated-local/seventh-reviewed-20261015/**`, `tool/recipes/curated-seventh-build.mjs`, `tool/recipes/curated-seventh-build.test.mjs`, and these two agent notes. No shared application/data integration, queue, manifest, Git, network, quota, or Firebase changes were made. No new source requests or books were acquired.

## Selection and evidence

The local metadata query selected eight exact revisions already present in the Wikibooks archive. Source-category strings are preserved as evidence only; they are not runtime cuisine approval.

| Page / revision | Arabic cookbook title | Exact source category | Listed ingredients / Arabic steps |
|---|---|---|---:|
| 4024 / 4613388 | دجاج جامايكي بالبهارات (جيرك) | `Category:Jamaican recipes` | 12 / 4 |
| 6472 / 4655348 | سيرنيكي روسية (فطائر الجبن) | `Category:Russian recipes` | 7 / 4 |
| 456825 / 4613362 | ياسا غامبية بالدجاج أو السمك | `Category:Gambian recipes` | 10 / 8 |
| 456953 / 4506432 | رولكس أوغندي (بيض ملفوف بخبز تشباتي) | `Category:Ugandan recipes` | 9 / 8 |
| 456979 / 4513621 | كواكوكو كاميرونية (حزم القلقاس المطهوة بالبخار) | `Category:Cameroonian recipes` | 10 / 9 |
| 457075 / 4587496 | عصيدة ليبية بالزبدة | `Category:Libyan recipes` | 7 / 8 |
| 457525 / 4534248 | فاصولياء وأرز زامبي | `Category:Zambian recipes` | 9 / 8 |
| 457553 / 4522833 | زيتومبوا ملاوية (فطائر الموز) | `Category:Malawian recipes` | 9 / 8 |

New exact labels: `jamaican`, `russian`, `gambian`, `ugandan`, `cameroonian`, `libyan`, `zambian`, `malawian` (8). The six previous local packs contain 48 records and 42 labels; this pack brings the local totals to 56 records and 50 labels. The source archive’s 6,056 research records were not globally deduplicated or counted as unique. Candidate review used compact script output; the archive was not pasted into the model as a whole.

## Curation and unresolved facts

The pack contains 73 listed ingredient lines, 2 procedural additions (banana leaves and unquantified water for Kwacoco), and 57 Arabic method steps. All eight records remain `needs-review`; none is fully specified, runtime-ready, nutritionally accepted, rights-cleared per page, or kitchen-tested. Their 251 native preflight issues are recorded per draft; they are not treated as completed recipes.

- Jamaican jerk chicken: source states 4 servings; chicken is 4 breasts without a weight; marinade is at least 1 hour and preferably overnight; grilling duration is not given.
- Russian sirniki: quantity of pan oil/butter and garnish amounts, yield, and times are absent; sour cream/sugar or jam alternatives remain as written.
- Gambian yassa: 4–5 onions; chicken or fish alternative; fresh/dried thyme have different amounts; salt is to taste; browning time and yield are absent. The source gives a 2-hour minimum marinade and 15–20-minute simmer.
- Ugandan rolex: two eggs and two chapatis; cilantro optional; source gives about 3 minutes for the first omelet portion and 2 minutes to warm chapati. Total time/yield are absent.
- Cameroonian Kwacoco: fish, smoked turkey, and spinach use source ranges; salt has no amount; banana-leaf and water quantities are absent; source gives a 3–5-minute stock boil and about 1 hour steaming.
- Libyan asida bil zibda: source gives 4–6 servings; cinnamon and nuts are optional garnishes with no quantities; source gives about 10-minute semolina toasting and 10–15 minutes after adding milk.
- Zambian beans and rice: black-eyed peas or kidney beans remain alternatives; salt is to taste; rice preparation/time and yield are absent. Beans soak overnight and simmer 1–1½ hours.
- Malawian zitumbuwa: banana size, additional oil, yield, and preparation time are absent; source gives about 2 minutes on one side and 1–2 minutes on the other.

Unknown quantities, ranges, optional items, alternatives, yields, and times stay unchanged in readable notes and native preflight drafts. No nutrition, medical, food identity, scaling, legal page-exception, food-safety, or runtime acceptance was inferred. The previous six normalized packs remain byte-pinned; the sixth pack SHA256 is `bf8453d0ac1c7f3caaef4b48083a780b9211f02b147ba7bd0309cc9572854a84`.

## Files and hashes

- Pack folder: `data/recipes/curated-local/seventh-reviewed-20261015/` with `review-decisions.json`, eight `source-snapshots/`, eight `preflight-drafts/`, `normalized-recipes.json`, `COOKBOOK.ar.md`, and `review-report.json`.
- Builder and test: `tool/recipes/curated-seventh-build.mjs` and `tool/recipes/curated-seventh-build.test.mjs`.
- Normalized pack SHA256: `b311d73afa69110f18907991d04db5fb1ea4bc823921a49f6e2af72bd6207435`.
- Arabic cookbook SHA256: `0e44f9e8d349e6b9a50054fb69aa99807ea8e45f0385be95250287a53fd677fd`.
- Review report SHA256: `f04676952b5c1c67b1dcc24d9f2bc3285fc3a5ddbfc8a6d72f39423d814c1086`.
- Review decisions SHA256: `9e2c823a5e54dca8236b3335b724e645eab4ef3080634f334dedbd1154328074`.
- Builder SHA256: `b6e179ce21089a15d5936ced68f8c936192dedb535c74c90aa8b9cdbf7d1c1d8`.
- Focused test SHA256: `a806aa32d4760c1adb22cd5ab023d11df300e933bf89647db118dabf22581c9d`.

Each source snapshot preserves the exact raw source record, parsed revision, source URL/date, license, source text hash, source/parsed fingerprints, and snapshot/content hashes. The builder checks all six prior local pack hashes, selected source IDs, title/family collisions, exact source categories, and exact matches against the 54 planning recipe names (none found). It makes no global 6,056-record uniqueness claim.

## Verification and handoff

- `node tool/recipes/curated-seventh-build.mjs`: passed offline; reported 8 records, 73 listed lines, 2 procedural additions, 57 steps, 8 new labels, 0 runtime-ready; normalized pack SHA matched above.
- `node --test tool/recipes/curated-seventh-build.test.mjs`: 2/2 passed. Checks exact revision/provenance pins, recipe/source line counts, statuses and unresolved examples, then byte-for-byte rebuild of all pack files.
- No Flutter tests, app gates, integration, or source requests were run as part of this bounded pass.
- The assigned base commit was `153d45d2d4606c7ee4a4cd7806c9012272584122`. No Git commit or push was made; root owns shared integration and Git. Shared root-owned working changes were visible in the checkout (`docs/WORK-QUEUE.json` and `test/recipe_library_packaged_selection_test.dart`); this helper did not edit them.

**Next action:** ownership returns to root for independent review and shared library integration. No further seventh-pack records are planned in this subtask.
