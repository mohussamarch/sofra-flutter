# German Wikibooks recipe expansion

This isolated research lane uses the official German Wikibooks `Kochbuch/` namespace-0 prefix. It does not change existing language banks or runtime data. Siteinfo verifies German, namespace 0, and sitewide CC BY-SA 4.0; page exceptions and third-party attributions remain unreviewed.

## Current evidence — 2026-10-14

- Eight successful official API requests occurred: the original siteinfo plus two initial pagesets, three continuation pagesets, and two prefix-recovery pagesets. Six response wrappers are currently archived (siteinfo + three continuation + two recovery); the two original pageset bodies were overwritten and are unavailable. Each retained wrapper contains exact UTF-8 response bytes, base64, SHA256, request URL, retrieval time, and HTTP status. Recovery wrappers explicitly mark `retrievalKind: new-prefix-recovery`.
- Current retrieval set contains 250 distinct fixed page revisions: the newest 100 pages re-retrieved from the prefix start and the preserved 150-page continuation slice. The first two recovery calls returned 50 pages each and continue beyond the checkpoint after the first 100. The extractor rejects repeated page IDs/revisions across archives.
- Offline extraction produced 177 research candidates, 1,493 literal ingredient lines, 998 preparation lines/paragraphs, and 73 source pages not parsed into candidates.
- Canonical amount/unit/food binding, step duration, serving count, cuisine, and nutrition remain unknown/null. There are zero runtime imports, nutrient bindings, and approved cuisines. Source categories remain unreviewed labels.

## Archive incident and repair

The earlier continuation collector's PowerShell `Get-ChildItem -Filter '[0-9][0-9]-pages.json'` selected no files. It then started numbering at 01 and overwrote the initial pageset archive names while collecting the later continuation. The three new raw responses were preserved as `04-pages.body/json`, `05-pages.body/json`, and `06-pages.body/json` with their original response bytes and digests. The earlier 100-page response bodies and their original retrieval metadata were not recoverable from the checkout's temp directory or staged work files; they are not represented as original evidence.

To restore coverage, two new official prefix-start requests were made after a fresh usage check (35% primary, 80% weekly, ordinary usage allowed). They are archived as `07-prefix-recovery-new.body/json` and `08-prefix-recovery-new.body/json`; their fresh retrieval timestamps and new hashes are preserved, and they are explicitly labeled as new retrievals. This is a new evidence set, not a restoration of the missing original bytes. All six page archives are distinct by page ID and fixed revision. No error, retry, or alternate route occurred in the recovery.

Page-response evidence hashes: `04` `19c359ec82206284840395e4e245cddc04c8e12a55bf7edd9bff0e3c7a86e5e1`; `05` `ac385f4a1775aa403f75515c0dae7765b8a76ed02f0330302965e06735e18ecc`; `06` `63089136d22243b58e7178e57e8af5d917d75bdf9ea125a06e8b2830d4bbcf5b`; `07` `db5336cec63ea72fd3b988b5ef2e87979a3504522bcac82fb18d58095e1de0e0`; `08` `227ce4c821799b0ee2b97e422c4725e1145a02e11f6353967f023c0627128b59`.

The collector now derives its next sequence from literal approved archive-name patterns, includes recovery archives in that selection, checks destination collisions, moves each completed temporary body without replacement, and uses `FileMode.CreateNew` for metadata and failure archives. `tool/recipes/test-de-wikibooks-archive-safety.ps1` verifies sequence selection, collision rejection, and preservation of existing bytes.

## Files and verification

- `data/recipes/source-discovery/de-wikibooks/`: immutable response bodies/wrappers, current extracted source pages and candidates, index, and continuation checkpoint.
- `tool/recipes/extract-de-wikibooks-research.mjs`: deterministic offline section extraction and response hash/byte, site-policy, page ID, and fixed-revision checks.
- `tool/recipes/fetch-de-wikibooks-next-batch.ps1`: bounded continuation collector; verifies local lock/process state and stops on the first error without retry or route change.
- `tool/recipes/de-wikibooks-archive-safety.psm1` and `tool/recipes/test-de-wikibooks-archive-safety.ps1`: collision-safe archive sequencing/writes and regression check.

Verified with a fresh extraction (250 pages, 177 candidates, 1,493 ingredient lines, 998 steps), a PowerShell parser check of the collector, and the archive collision regression (`archive-safety=passed collision-rejected=1 existing-bytes-preserved=1`). Re-running the extractor validates body hashes against raw bytes and wrapper text, and produces the indexed output digests.

Next continuation is `gapcontinue=Kochbuch/_Gnocchi_mit_Lauch_und_Schinken`, `continue=gapcontinue||`. Before any further calls, refresh usage and inspect the source lock/backoff. The source prefix is not exhausted; no global completion cap is implied. Root owns shared status/handoff and Git integration.
