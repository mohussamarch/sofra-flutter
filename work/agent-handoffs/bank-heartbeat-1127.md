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
