# Food bank continuation — 0444

Checkout: `E:\work\SOFRA\app`, clean at start, `HEAD=origin/main=dc5973b271bc6bee1046ce511a70355690de1479`. Collection scope: only `data/food/openfoodfacts/**`; collector tool unchanged. Current data changes are ready for coordinator review; no commit made.

Quota checked before each invocation: ordinary usage allowed, 31%/5h and 62%/week before batch 1; 32%/5h and 62%/week before batch 2. Both below the 90% stop boundary. No reset credits used.

Two sequential capped invocations completed and fully polled (exit 0): 6 actual Open Food Facts requests total. Successes: `saudi-arabia/snacks` p1 (58 records), `saudi-arabia/dairy` p2 (100), `saudi-arabia/flour` p1 (14). Failures: `saudi-arabia/sweets` p1, `saudi-arabia/pulses` p1, and newly advanced `saudi-arabia/dairy` p3, all HTTP 503; backoff checkpoints retained. No request inferred from attempted/printed metadata. Collector lock absent at release.

Bank changed from 1,344 to 1,483 products (+139): EG 624 unchanged, SA 731→870 (+139), shared 11 unchanged. Archives 43→46 (+3); quarantine 184→189 (+5); duplicate occurrences 248→276 (+28); with nutrition 981→1,084 (+103); core macros 887→983 (+96); ingredients 551→627 (+76); brands 1,036→1,144 (+108); declared allergen tags 273→324 (+51). All 1,483 have unknown/unreviewed nutrition basis. No values, prices, popularity, or safety claims were inferred. OFF database license ODbL-1.0 and content license DbCL-1.0 retained; source/date/hash provenance is in the generated manifest and raw archives.

Actual bank verification once at release: `SOFRA_FOOD_BANK=E:/work/SOFRA/app/data/food/openfoodfacts node --test tool/food/import.test.mjs` — 5 passed, 0 failed, 0 skipped, including shipped bank hash, identity, attribution, and source nutrient checks. No collector code changed.

At `2026-10-13T01:47Z`, no unfinished cursor was due. Earliest next retry: Saudi beverages p4 `01:52:17Z`, Egypt global p6 `01:52:27Z`; then Saudi global p1 `01:59:29Z`, frozen p1 `01:59:37Z`, dairy p3 `02:01:53Z`, Egypt beverages p2 `02:05:13Z`, sweets p1 `02:46:06Z`, pulses p1 `02:46:44Z`. Exact next action: coordinator rechecks quota, lock, and due cursors before a later continuation. No wait loop run.
