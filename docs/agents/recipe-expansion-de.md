# German Wikibooks recipe expansion

This isolated research lane uses the official German Wikibooks `Kochbuch/` namespace-0 prefix. It does not change existing language banks or runtime data. Siteinfo verifies German, namespace 0, and sitewide CC BY-SA 4.0; page exceptions and third-party attributions remain unreviewed.

## Current evidence — 2026-10-14

- Seventeen successful official API requests occurred: the original siteinfo plus two initial pagesets, twelve continuation pagesets, and two prefix-recovery pagesets. Fifteen response wrappers are archived (siteinfo + twelve continuation + two recovery); the two original pageset bodies were overwritten and are unavailable. Each retained wrapper contains exact UTF-8 response bytes, base64, SHA256, request URL, retrieval time, and HTTP status. Recovery wrappers explicitly mark `retrievalKind: new-prefix-recovery`.
- Current retrieval set contains 700 distinct fixed page revisions: 100 pages re-retrieved from the prefix start and 600 pages from the preserved continuation slices. The extractor rejects repeated page IDs/revisions across archives.
- Offline extraction produced 481 research candidates, 4,121 literal ingredient lines, 2,784 preparation lines/paragraphs, and 219 source pages not parsed into candidates.
- Canonical amount/unit/food binding, step duration, serving count, cuisine, and nutrition remain unknown/null. There are zero runtime imports, nutrient bindings, and approved cuisines. Source categories remain unreviewed labels.

## Archive incident and repair

The earlier continuation collector's PowerShell `Get-ChildItem -Filter '[0-9][0-9]-pages.json'` selected no files. It then started numbering at 01 and overwrote the initial pageset archive names while collecting the later continuation. The three new raw responses were preserved as `04-pages.body/json`, `05-pages.body/json`, and `06-pages.body/json` with their original response bytes and digests. The earlier 100-page response bodies and their original retrieval metadata were not recoverable from the checkout's temp directory or staged work files; they are not represented as original evidence.

To restore coverage, two new official prefix-start requests were made after a fresh usage check (35% primary, 80% weekly, ordinary usage allowed). They are archived as `07-prefix-recovery-new.body/json` and `08-prefix-recovery-new.body/json`; their fresh retrieval timestamps and new hashes are preserved, and they are explicitly labeled as new retrievals. This is a new evidence set, not a restoration of the missing original bytes. All six page archives are distinct by page ID and fixed revision. No error, retry, or alternate route occurred in the recovery.

Page-response hashes: `04` `19c359ec82206284840395e4e245cddc04c8e12a55bf7edd9bff0e3c7a86e5e1`; `05` `ac385f4a1775aa403f75515c0dae7765b8a76ed02f0330302965e06735e18ecc`; `06` `63089136d22243b58e7178e57e8af5d917d75bdf9ea125a06e8b2830d4bbcf5b`; `07` `db5336cec63ea72fd3b988b5ef2e87979a3504522bcac82fb18d58095e1de0e0`; `08` `227ce4c821799b0ee2b97e422c4725e1145a02e11f6353967f023c0627128b59`; `09` `9a55c7da50727c7d421ba121c62c6bc1b289b21f7194f7b12daeab9907c6e76b`; `10` `51eadcd9cecd2950d6f12fde55507407a561526c47d409d291cf8647d44e9f0d`; `11` `7a290198761958bd8bff11f3ef94bfb9a7a028f86e7baa38cbae49f462e0509b`.

Page-response hashes `12`–`14`: `12` `46eeb4b7312fb0325e90537c587ca0737951f694eb6ece0a81bfa4162b1aa606`; `13` `43d8d5660692f0dc399b97d62e5b526a14ab65a4bb16a99c6af2f2042dffe31d`; `14` `3b49f490d63d32aeda13b0b8e70fbe50b2e03e2a0469abff77c989dbec60181a`.

Latest page-response hashes: `15` `d6e9461092cea4c424b65ffa73b0c5ab4f17e46605e2c1660244cbe85dedc66d`; `16` `0be1044233ae02e90afc525e64f84d7a55ede50027e95ba36abdfa85e09c3846`; `17` `12bcb46dfe7f87358995598557ad22cb426248a866996be70f8a03ec48c399eb`.

The collector now derives its next sequence from literal approved archive-name patterns, includes recovery archives in that selection, checks destination collisions, moves each completed temporary body without replacement, and uses `FileMode.CreateNew` for metadata and failure archives. A resumed invocation initially failed locally before any request because PowerShell returned a number type incompatible with `D2` formatting; it recorded zero successes, preserved the cursor, and set no backoff. Root corrected the sequence conversion and tests before this batch. `tool/recipes/test-de-wikibooks-archive-safety.ps1` verifies sequence selection, collision rejection, and preservation of existing bytes.

## Files and verification

- `data/recipes/source-discovery/de-wikibooks/`: immutable response bodies/wrappers, current extracted source pages and candidates, index, and continuation checkpoint.
- `tool/recipes/extract-de-wikibooks-research.mjs`: deterministic offline section extraction and response hash/byte, site-policy, page ID, and fixed-revision checks.
- `tool/recipes/fetch-de-wikibooks-next-batch.ps1`: bounded continuation collector; verifies local lock/process state and stops on the first error without retry or route change.
- `tool/recipes/de-wikibooks-archive-safety.psm1` and `tool/recipes/test-de-wikibooks-archive-safety.ps1`: collision-safe archive sequencing/writes and regression check.

Latest batch: three sequential official requests, all HTTP 200, after quota check at 78% primary / 87% weekly with ordinary use allowed. The earlier local-formatting failure made zero source requests and created no backoff. Verified with extraction (700 pages, 481 candidates, 4,121 ingredient lines, 2,784 steps), response and sidecar hash checks, 700 unique page IDs, and unknown/null invariants.

Next continuation is `gapcontinue=Kochbuch/_Sexy_Cupcake`, `continue=gapcontinue||`. Before any further calls, refresh usage and inspect the source lock/backoff. The source prefix is not exhausted; no global completion cap is implied. Root owns shared status/handoff and Git integration.
