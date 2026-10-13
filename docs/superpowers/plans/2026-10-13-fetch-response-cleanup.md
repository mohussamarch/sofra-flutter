# Fetch error response cleanup

Approved scope: safer food-bank import under recurring research, sole E checkout; no UI/Firebase changes. Observed collector printed results but did not exit during0750. Inspection finds HTTP error responses thrown before their body is consumed/cancelled. Undici official docs require body consumption or cancellation; this is a concrete resource leak risk, not yet proof of every process hang.

1. Regression first: real Web ReadableStream error body must be cancelled, no archive written; cancellation failure must not hide original HTTP status/backoff; null body safe; success archive unchanged.
2. Minimal change in tool/food/import.mjs only; coordinator owns tools, collector owns OFF data. Do not change request pacing, cursor/backoff, source records or timeout. Run targeted red/green and all related importer/scheduler/reference tests. Resume actual collector after gate and observe process exit.
3. Consolidate source/quality outcomes and cleanup evidence/limits in STATUS/HANDOFF; push completed tested changes. Do not claim all historical exit hangs resolved without observation.

Evidence: https://github.com/nodejs/undici#garbage-collection (body resources must be consumed or cancelled). Skills systematic-debugging and test-driven-development applied; existing user authorization covers import safety fixes without another approval or checkout.


Outcome: implemented minimal error-body cancellation, original status preserved even if cancellation fails. Initial2tests red because cancellation absent; final20related tests green including5response cases and a real local unfinished503/child natural-exit check. Cheap collector read-only review found no actionable issue. All live requests this run preceded fix and failed503, bank1690unchanged; process eventually exited0. No live retry post-fix because alljobsbackoff. Next live run observes exit; no claim of all past hangs resolved. Final push receipt outsideGit.
