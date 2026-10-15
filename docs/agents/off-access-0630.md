# OFF access diagnostic — 0630

- Checkout: `E:\work\SOFRA\app`, branch `main`, starting HEAD `1872fdd88e27c88d521dd4877c7b53cb5fff2657`.
- Scope: one existing collector run, `maxRequests: 1`, using the submitted contact only to correct the request User-Agent. The private receipt and email were read locally and are not included here.
- Fresh account usage immediately before request: ordinary usage allowed; primary 3%, weekly 0%, below the 90% gate.
- Preflight: collector lock absent; saved OFF 401 gates had expired. Existing `nextJobIndex=41` selected `saudi-arabia/global`, page 11. No cursor reset or route/account/auth workaround.
- Request result: one GET returned OFF 503. Existing collector wrote its ordinary failure checkpoint; `runBatch` returned one failed result, `fetched=false`, and the node process exited 0 because the collector records request failures as data. It did not retry.
- Backoff/cursor: Saudi global remains page 11, failures 6, next attempt `2026-10-15T14:29:11.411Z`; next job index 0. The Egypt page 11 401 checkpoint is retained. Collector lock was removed on exit.
- Bank before/after: 2,378 products, 67 raw archives, 414 quarantined entries, 902 duplicate occurrences. Added/updated products 0; quarantine changes 0; no raw archive or derived-bank rebuild. Product SHA256 remains `f46156c4adb39025091f81ab9a5ab52d4e9afa030476153d4b856ca38304434e`; index SHA256 remains `0068758a5b1028e7690d555bfa4adc1d79cc939b84ee835274180fe436717d8f`.
- Tracked data diff is only `data/food/openfoodfacts/collection-state.json`: Saudi page failure count/backoff and request timestamp/round-robin index updated. No code changed. No tests were run; this was an external source-access diagnostic, not a product change.
- No further source request in this run. Next decision: honor the 503 backoff until its recorded deadline, then review the documented OFF export access path (their docs recommend exports for collections above a few hundred records) before deciding whether another single API diagnostic is useful. Recheck actual account limits immediately before any later request. Keep the 401 shared gate and all saved cursors intact.
