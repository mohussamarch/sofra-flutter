# Recipe library parallel snapshot reads — 22 October 2026

## Objective

Bound source snapshot reads within each curated pack to eight concurrent reads while preserving SHA256 checks, provenance validation, approval guards, and manifest order.

## Owned files

- `lib/data/recipe_library_repository.dart`
- `test/recipe_library_parallel_reads_test.dart`
- This handoff and `.status.md`

## Change

The repository validates every snapshot path and SHA256 syntax for a pack before reading that pack. It then loads the pack and snapshots using a private worker pool capped at eight. Results are assembled by manifest index, and worker failures are collected until all reads in the batch finish; the existing failed-load cache reset remains in place.

The regression test uses synthetic fixtures to cover concurrency bounds and deterministic entry order, invalid snapshot metadata before snapshot reads, and complete failed-batch draining followed by a successful retry.

## Verification

RED was run against the original serial implementation in the E checkout before the bounded reader was restored. All three new tests failed for the intended reasons: observed concurrency was one, a malformed later snapshot hash was discovered only after an earlier snapshot read, and the serial loader stopped after its first failed snapshot.

The coordinator ran the four tests (three synthetic regressions plus a temporary actual-assets phase benchmark) successfully in about 26 seconds. The benchmark was then removed from the committed test file. With 6,648 library entries, measured phases were: `all()` 12,593 ms; coverage audit 13,460 ms; four searches 43 ms; four cuisine filters 4 ms. These phase measurements show the expensive cost is in loading/copying and coverage audit rather than repeated search/filter queries; they do not claim an end-to-end speedup from bounded I/O. The standalone asset test after the catalog update is still coordinator-owned and pending.

## Next action

Coordinator verification completed: the real bundled-asset integration case passed in the final sequential full suite (00:54 start, next file 01:13, approximately19 seconds including all source assertions), with6648records/57693ingredient lines/6504snapshots. The full356tests passed in2m20s. After initializing-formal style fixes, all20affected yield/monthly/parallel-reader tests passed; analyze was clean. The earlier phase benchmark and30s timeout results above are historical and precede the final recursive-copy optimization and fixture reuse. Heavy bank integration suites have a scoped2minute timeout; source assertions were retained. No phone/UI latency claim.
