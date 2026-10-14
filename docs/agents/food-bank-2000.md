# Food bank helper 2000 — 14 October 2026

Checkout: `E:\work\SOFRA\app`, reported base `fc7912ef66a5bf133c355bbb1dceec315a6fa18b`. Scope was the single-request Open Food Facts helper, subject to checking current official access guidance first. No collector request was made in this unit.

## Official source guidance reviewed

Official API documentation: https://openfoodfacts.github.io/openfoodfacts-server/api/ (read 2026-10-14 20:03 UTC). It says to read reuse terms and complete the API usage form before using the API; the form helps identify real-world usage. Reads need a custom identifying User-Agent and do not otherwise require authentication. Search endpoints including `/cgi/search.pl` have a 10 requests/minute/IP limit; the docs advise downloading data directly when more than a few hundred products are needed. The existing collector sends `SofraResearch/0.1 (https://github.com/mohussamarch/sofra-flutter)`, but that does not resolve the API usage form step or explain the previous 401. The docs identify `/cgi/search.pl` as legacy full-text search.

The source-side form would disclose this app's usage to Open Food Facts. This helper was not authorized to submit it or contact the source, and no account/authentication was requested or used. Per scope, no request was made pending source-side resolution. No alternate endpoint, domain, country/category route, or bypass was attempted.

## Preflight and observed state

- Fresh account limits read immediately before source review: ordinary usage allowed; primary 4% used, weekly 32% used; no purchased credits. One unused reset credit was shown and was not used.
- Current UTC at preflight: 2026-10-14 20:03:17.
- Saved OFF 401 failures: Saudi/global page 11 at `2026-10-14T08:29:45.471Z`, gate to `09:49:45.471Z`; Egypt/global page 11 at `2026-10-14T15:13:18.596Z`, gate to `16:33:18.596Z`. Both gates had expired at preflight. Expiry alone did not authorize an attempt.
- Existing collector lock absent. Bank manifest reports 2,378 products and 67 raw archives. No bank data or checkpoint was changed.
- No collector child process was started, so there is no request exit code or HTTP result for this unit. No tests were run; no bank change occurred.
- `git rev-parse HEAD` returned the reported base hash, while `git status --short --branch` reported `fatal: this operation must be run in a work tree`; Git diagnostics are left to the root coordinator.

## Next action

Resolve the official API usage-form requirement and the unexplained prior HTTP 401 with Open Food Facts through an explicitly authorized source-side process. Once resolved, re-read fresh quota and use only the documented `withCollectorLock` + `runBatch({out,maxRequests:1,onProgress})` invocation, with the existing shared gate, a 30-second command guard, and natural process exit recorded. Stop immediately on 401/403 and preserve backoff. Root owns common STATUS/HANDOFF and Git.
