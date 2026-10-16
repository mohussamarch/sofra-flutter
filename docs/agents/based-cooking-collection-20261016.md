# Based Cooking source acquisition — 16 October 2026

Sole application checkout: `E:\work\SOFRA\app`, branch `main`, base delivered commit `aa3d6fe738fb1e3dcfa042ec67e185243b69a8d1`. A source worker fetched a content-only sparse checkout on 15 October, then reached the account usage ceiling before finishing notes. Root resumed the same prepared unit after actual limits reset, with no further source network operation. All ownership is returned to root. This note describes the source unit; shared manifest, queue, status and Git remain coordinator-owned.

## Evidence and count

- First-party repository: https://github.com/LukeSmithxyz/based.cooking ; website links to it. Pinned Git commit `9d4a31a040eedd61e4fb608cb0c114ff9a7c4dd2`, timestamp `2026-09-09T08:51:41+02:00`.
- Cache `E:\work\SOFRA\source-cache\based-cooking-data` is source data, not another app checkout. Sparse content includes only `content/*.md`, `README.md` and `LICENSE.md`; no static, images, audio, video or archive download. Two Git network operations were recorded, but the underlying HTTP request count is unknown.
- README declares the website and content public domain; `README.source.md` and `LICENSE.source.md` retain exact pinned text, hashes and any contributor context. Per-page exceptions, attribution and app/runtime reuse review remain open. Public-domain declaration is evidence, not automatic runtime/legal approval.
- 441 Markdown files at that commit. 440 have nonempty actual ingredients and directions; `content/_index.md` rejected as metadata/nonrecipe. Canonical URL/id and normalized ingredient+method dedup against 3090 previously selected records and within the new pack yielded 440 accepted, 0 dedup rejections; semantic or cross-language distinct dishes are not asserted.
- This is **440 new source acquisitions**, not 1000. User batch target 1000 was missed by 560 because this source has only 440 accepted recipes at the pinned commit. The 3000 pre-existing archive conversions are counted separately and are not new acquisitions. No invented remainder.
- Pack `data/recipes/curated-local/based-cooking-20261015/normalized-recipes.json` has 3583 ingredient lines and 3243 method steps; 440 matching raw-text source snapshots. English retained as `sourceLanguage=en`, `translationStatus=not-translated`, Arabic fields null; names fall back for reading only. `cuisines=[]`, no approved new cuisine labels. All accepted amounts/units, time, yield, food binding, inclusion and optionality unknown; explicit `(optional)` phrases remain raw text and `optional=null` pending review. Nutrition/runtime/person claims absent.
- Each row pins the source commit/path/raw SHA, snapshot SHA, source URL, acquisition date and license evidence. Build reads pinned Git blobs locally with lazy fetch disabled, validates checkout HEAD/checkpoint and working text before output. This closes the review findings about optional defaults and mutable working-file provenance.

## Actual verification

- `node --test tool/recipes/collect-based-cooking.test.mjs`: 5 passed.
- `node tool/recipes/collect-based-cooking.mjs build`: succeeded offline, 440 accepted / 1 rejected / 560 shortfall / `priorRecordsChecked=3090`; pack SHA256 `a155d89532f4e4c0a185057ed2afbd7ae31288a1c3e3b9d295eac467adeaee3e`.
- After root registration, combined Node library/three archive converters/collector/watchdog gate: 45 passed. Manifest: 22 packs, 3504 snapshots, SHA256 `0de3aacf29146b8ad61ec5598bc570c33bbb27ece5c676c675f1a25dfacb491f`.
- Flutter library asset and coverage tests passed sequentially (5 total); parallel three-file run initially timed out at the 30-second per-test default with simultaneous large library loads. Draft tests separately passed 10. Actual coverage report has 3530 readable source records and 0 runtime approved recipes. The sequential gate isolates resource contention; no correctness failure was observed after sequential rerun.

## Next action

Find another independently licensed modern source, preferably documented Arabic creator content, with complete ingredients and directions; report actual source size and rights. Do not count this same commit again. Review translation, source-derived cuisine, exact quantities, forms, identity and per-page rights before promoting any new row to planning or nutrition. Root updates shared files/receipt and handles final commit/push.
