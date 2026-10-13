# OFF bank heartbeat — 13 October 2026

## Scope and checkout

- Dedicated helper run in `E:\work\SOFRA\app` only, at base `0d2b784b2f121a1a59369b0cf52563c6ea8489c3`.
- Modified data is limited to `data/food/openfoodfacts/**`; this handoff and its companion status are under `work/agent-handoffs/`. No shared docs, source code, or Git operations were performed.
- Pre-run live usage check: 25% primary, 17% weekly used; `ordinaryUsageAllowed=true`, below the 90% stop threshold and with the documented 10% reserve. The post-progress check was 26% primary, 18% weekly; ordinary usage remained allowed.

## Lock, requests, and process result

- Before launch, no `collection.lock` existed and no Node process was running. The first launch was denied by sandbox `EPERM` while creating the lock; it exited 1 and made zero requests. Scoped write access to the bank/handoff folders and network was then granted.
- The retry used the existing `tool/food/collect-incremental.mjs` CLI against the primary bank. Exactly two sequential requests were due; there were no failed HTTP/network attempts in this batch.
- `saudi-arabia/dairy`, page 3: success, 55 records, reported count 255; this category cursor is now done.
- `saudi-arabia/global`, page 4: success, 100 records, reported count 16,854; cursor advanced to page 5.
- The collector rebuilt the bank and the process exited with actual exit code 0. `collection.lock` was absent after exit and no Node collector remained.

## Resulting bank

- Product count: 1,793 before this batch (last status) to 1,888 after; net +95 unique products from 155 returned rows. Quarantine: 261 to 273 (+12); duplicate occurrences: 485 to 533 (+48). Archives: 55 to 57.
- Manifest reports source `https://world.openfoodfacts.org`, database license `ODbL-1.0`, contents license `DbCL-1.0`; each archive entry retains its request URL, retrieval timestamp, record count, and SHA-256.
- `raw/saudi-arabia-dairy-p3.json`: retrieved `2026-10-13T11:31:02.970Z`, 55 products, SHA-256 `4ae0ba53b18c75cb6a0fcd35e27add3ced7c632a61e70c3e4f7eaca5f296b977`.
- `raw/saudi-arabia-p4.json`: retrieved `2026-10-13T11:31:15.079Z`, 100 products, SHA-256 `0adfd83eca2a0cd688a560465352a31c2d99109358d860f5f41e5dc26dd84cf2`.
- Rebuilt products SHA-256: `8b1acd5aef724ffe4cce6e39cc63c90b5f045fc01cd255adf2eb86ae1e77458c`; index SHA-256: `9072b2677b49d4d6dac242e28ab1f4257046cd2d52d90236e4666f352d445d64`.
- Required real-bank check: `SOFRA_FOOD_BANK=E:/work/SOFRA/app/data/food/openfoodfacts node --test tool/food/import.test.mjs` — 5 passed, 0 failed (including actual bank hashes, identity, attribution, and source nutrient-value checks). No Flutter tests were needed.

## Next action

- Next eligible page: `saudi-arabia/global` page 5, due immediately at the next bounded collection cycle; last request was `2026-10-13T11:31:15.079Z`.
- Deferred failure remains `egypt/global` page 7, due `2026-10-13T12:54:39.414Z` (15:54:39.414 Arabia Standard Time). No retry was made during its backoff. Saudi dairy's previous failure cleared on success; Saudi global's prior network failure cleared on success.
- Recheck quota and collector ownership/lock before any later request; cap the next run at two due requests. Keep provenance and unknown nutrition basis unchanged.

## Follow-up bounded run — 13 October 2026, 12:06 UTC

- Fresh pre-run quota check: 34% primary, 19% weekly; ordinary allowed. Rechecked before the successful launch at 35% primary, 19% weekly; after progress it remained 35%/19%, ordinary allowed.
- The first CLI launch again failed before collection with sandbox `EPERM` creating `collection.lock` (exit 1, zero requests). No lock or Node collector remained. After scoped access to the bank and handoff folders plus network was renewed, the CLI ran normally.
- One due request succeeded: Saudi global page 5, 100 rows (`count=16854`), archive `raw/saudi-arabia-p5.json`, retrieved `2026-10-13T12:06:05.877Z`, archive SHA-256 `131e83cd69b8445bad3526a5df06c9dc72c9679194f241c56b8b6f647f18fbf2`. There were no HTTP or network failures. The collector rebuilt and exited with actual code 0; lock cleanup confirmed, no Node collector remained.
- Bank moved from 1,888 to 1,936 products (+48 net from 100 rows); quarantine 273→274; duplicate occurrences 533→584; archives 57→58. Manifest market counts EG 686 / SA 1,261; nutrition 1,400, core macros 1,282, ingredients 764, brands 1,427, declared allergens 398; all 1,936 remain unreviewed for nutrition basis. Database license ODbL-1.0; contents license DbCL-1.0.
- Bank-only verification rerun: 5 tests passed, 0 failed. Product SHA-256 `48eb821899985f637f80ee63b4e6092353e644c68a189ad1312d997a7733b99f`; index SHA-256 `531f23cff723e158b5adbaff7656c5722a8264ad4713c301ecd9645815a0fa70`.
- Next eligible Saudi global page is p6 at the next cycle. Egypt global p7 remains deferred until `2026-10-13T12:54:39.414Z`; no early retry. Check quota and lock again before collecting.

## Follow-up bounded run — 13 October 2026, 13:17 UTC

- Fresh usage before the run: 75% primary / 25% weekly used; ordinary usage allowed. It remained 75% / 25% after progress. The 90% stop threshold was not reached.
- Lock/process check before launch: no bank lock and no Node collector process. Two requests were issued sequentially from existing due cursors.
- Egypt global p7 succeeded: 100 rows, source count 4,447. Archive `raw/egypt-p7.json`, retrieved `2026-10-13T13:17:01.811Z`, SHA-256 `63186eb4fc2febb701ff4568551f99722b630fb184ec0ba012895e7d2800754c`.
- Saudi global p6 failed with HTTP 503. The checkpoint records `nextAttemptAt=2026-10-13T13:32:10.213Z`; no retry was made. This was the only failed source request in this batch.
- Collector summary reported 2 requests, at least one fetch, then the actual process exited with code 0. Lock was absent after exit and no Node process remained.
- Bank before/after: products 1,936→1,986 (+50 net from 100 returned rows); quarantined 274→302 (+28); duplicate occurrences 584→606 (+22); archives 58→59. Manifest market counts EG 736 / SA 1,261; nutrition 1,419; core macros 1,298; ingredients 771; brands 1,458; declared allergens 398; unreviewed nutrition basis 1,986. Source `https://world.openfoodfacts.org`; database license ODbL-1.0; contents license DbCL-1.0.
- Required real-bank validation: 5 tests passed, 0 failed. Product SHA-256 `3a02e42a06aaf13a8b122cd7fbf1f712b823ec88e48483cc15888d8e6c660c95`; index SHA-256 `a1ee0a0bdb81a4788a5893768563a1318c732237e709e9f88f24e025f012c6c6`.
- Next eligible page: Egypt global p8, due on the next cycle. Saudi global p6 is due again only after `2026-10-13T13:32:10.213Z`. Recheck quota and lock before the next maximum-two run.

## Follow-up bounded run — 13 October 2026, 13:46 UTC

- Fresh pre-run usage was 83% primary / 27% weekly used, ordinary usage allowed; post-run usage was 84% / 27%, ordinary still allowed (16% primary headroom remains).
- No lock file or Node collector process existed before start. The two pages due by checkpoint were Egypt global p8 and Saudi global p6; no retry was made before either deadline.
- Egypt global p8 returned HTTP 503; saved next attempt `2026-10-13T14:01:25.417Z`.
- Saudi global p6 returned HTTP 503; saved next attempt `2026-10-13T14:16:33.799Z`.
- Both attempts failed; no archive was added and no product bank rebuild ran (`fetched=false`). Collector process actually exited 0 after handling the failures. Lock was absent afterward and no Node process remained.
- Bank contents stayed unchanged: 1,986 products; 302 quarantined; 606 duplicate occurrences; 59 archives; markets EG 736 / SA 1,261. Product SHA-256 remains `3a02e42a06aaf13a8b122cd7fbf1f712b823ec88e48483cc15888d8e6c660c95`; index SHA-256 remains `a1ee0a0bdb81a4788a5893768563a1318c732237e709e9f88f24e025f012c6c6`. Since no archive/product bank data changed, the five real-bank tests were not rerun.
- Next due source is Egypt global p8 at `2026-10-13T14:01:25.417Z`; Saudi global p6 follows at `2026-10-13T14:16:33.799Z`. Recheck quota and ownership/lock before a later batch; do not retry earlier.

## Follow-up bounded run — 13 October 2026, 16:17 UTC

- Fresh pre-run usage 2% primary / 29% weekly used, ordinary allowed; post-run 3% / 29%, ordinary allowed. Lock/process check was clear before launch.
- Two due requests were attempted sequentially. Egypt global p8 returned HTTP 503; checkpoint next attempt `2026-10-13T16:46:55.583Z`. Saudi global p6 returned HTTP 503; checkpoint next attempt `2026-10-13T17:17:03.973Z`. No further retries were made.
- CLI summary was `requests=2`, `fetched=false`; actual process exited 0 after handling both errors. Lock absent after exit and no Node collector remained.
- No source archive was added and product bank is unchanged: 1,986 products, 302 quarantined, 606 duplicate occurrences, 59 archives; EG 736 / SA 1,261. Product SHA-256 remains `3a02e42a06aaf13a8b122cd7fbf1f712b823ec88e48483cc15888d8e6c660c95`; index SHA-256 remains `a1ee0a0bdb81a4788a5893768563a1318c732237e709e9f88f24e025f012c6c6`. No bank tests rerun because product/archive data did not change.
- Next due Egypt global p8 is `2026-10-13T16:46:55.583Z`; Saudi global p6 is `2026-10-13T17:17:03.973Z`. Recheck quota, lock and backoff before any later batch; no retries before those times.
