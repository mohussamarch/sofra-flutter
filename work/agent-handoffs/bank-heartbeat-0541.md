# Food bank continuation — 0541

Checkout: `E:\work\SOFRA\app`, base `9fe4ca1019124bd91fe390ba9737823db07491eb`, clean at start. Collection was limited to the authorized Open Food Facts bank; collector/tool code unchanged.

Quota checked immediately before the batch: ordinary usage allowed, 36%/5h and 62%/week; both below the 90% stop boundary. No reset credits used. One sequential invocation completed and was fully polled (exit 0): 6 actual requests. Successes: Egypt beverages p2 (20), Saudi beverages p4 (55), Saudi frozen p1 (31), Egypt global p6 (100). Failures: Saudi global p1 and Saudi dairy p3, both HTTP 503; persisted backoff retained. No request outcome inferred from attempted metadata.

Bank changed from 1,483 to 1,625 products (+142): EG 624→686 (+62), SA 870→950 (+80), shared 11 unchanged. Archives 46→50 (+4); quarantine 189→244 (+55); duplicate occurrences 276→285 (+9); with nutrition 1,084→1,196 (+112); core macros 983→1,091 (+108); ingredients 627→649 (+22); brands 1,144→1,224 (+80); declared allergen tags 324→334 (+10). All 1,625 bases remain unknown/unreviewed. OFF database license ODbL-1.0 and content license DbCL-1.0 retained. Raw archives preserve source URL, retrieval date and per-archive hash; generated manifest/products/index hashes are retained. No values, prices, popularity, or safety claims inferred.

Actual bank verification run once at release: `$env:SOFRA_FOOD_BANK='E:/work/SOFRA/app/data/food/openfoodfacts'; & 'C:\Program Files\nodejs\node.exe' --test tool/food/import.test.mjs` — 5 passed, 0 failed, 0 skipped, including shipped bank hashes, identity, attribution, and source nutrient checks. No collector code changed.

At release 2026-10-13T02:44:53Z, no jobs were due; collector lock absent. Next retry: Saudi sweets p1 at 02:46:06.961Z, then Saudi pulses p1 at 02:46:44Z. Exact next action: coordinator rechecks quota, lock and due cursors before another bounded collection. No wait loop, commit or push run. Scoped files: `data/food/openfoodfacts/**`, this handoff and `bank-heartbeat-0541.status.md` only. No app/UI/Firebase/audio/image/APK/Hosting/Drive/device changes.
