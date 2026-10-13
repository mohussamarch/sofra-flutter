# Food bank continuation — 0750 UTC

Checkout: `E:\work\SOFRA\app`; authorized base `e636b4bb130e0464c3c75ccd24ef534d0905f93b`. Initial Git status could not be read (`fatal: this operation must be run in a work tree`); source and checkpoint files were readable. Collector lock was absent.

Quota before and after collection: ordinary usage allowed; 46%/5h and 64%/week, below the 90% stop threshold. No reset credits used. One collector invocation was fully observed: 2 actual requests, 0 successes, 2 HTTP 503 failures (Saudi Arabia dairy p3 and Egypt global p7). Pacing/checkpoint behavior persisted backoff. Collector output reported 2 requests and `fetched:false`; it had printed its result but its process did not exit, so it was interrupted after confirming the checkpoint had been written. No lock remained afterward. No archive/product additions or bank rebuild occurred.

Current checkpoint: Saudi Arabia dairy p3 next 06:52:13Z; Egypt global p7 next 05:52:21Z; Saudi Arabia global p1 remains due 05:50:13Z. A due-cursor scan at 04:52Z found no due jobs. Next action: coordinator rechecks quota/lock at or after 05:50:13Z; if due, run a paced batch and observe process exit.

Bank counts remain at baseline: 1,690 products (EG686/SA1015/shared11), 52 archives, quarantine247, duplicate occurrences302, nutrition1239, core1131, ingredients680, brands1277, declared allergen tags352. Unknown nutrition bases remain unknown. No fabricated values, prices, popularity, or safety claims. Source provenance and licenses unchanged.

Final verification: `SOFRA_FOOD_BANK=E:/work/SOFRA/app/data/food/openfoodfacts node --test --test-reporter=dot tool/food/import.test.mjs` with `C:\Program Files\nodejs\node.exe` — 5 passed, 0 failed.

Scoped files only: `data/food/openfoodfacts/**`, `work/agent-handoffs/bank-heartbeat-0750.md`, and `work/agent-handoffs/bank-heartbeat-0750.status.md`. No app/UI/Firebase/billing/APK/Hosting/Drive/device/audio/image/commit changes. Preview server not touched; historical status lists port8766, PID31004, `design-preview/serve.cjs`.
