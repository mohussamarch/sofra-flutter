# Fifth 1,000 batch status — 2026-10-21

- Converted records: 1,000 (630 Spanish, 370 German); strict-complete visible ingredient/method records: 846; incomplete selected: 154.
- Text totals: 8,030 ingredient lines and 5,894 method steps; blank ingredient names/method text: 0.
- Raw coverage: ingredients verified 978 / review 22; methods verified 853 / review 147. Flagged unresolved markup: 12 ingredient lines and 3 method steps.
- Full candidate pool: 476/853 Spanish and 373/544 German strict complete; remaining candidates incomplete. Review counts: ingredient 73 Spanish / 2 German; method 311 Spanish / 149 German. These sets overlap.
- `es:156` / `es:162` fail strict completeness due to tooltip contamination; unsupported template arguments, HTML, residual pipes and missing raw-section coverage also disqualify records.
- 0 new acquisitions, translated, runtime-ready, or nutrition-approved. Quantities, yield, time, nutrition and cuisine remain unknown/unassigned. Page rights are unreviewed.
- Frozen baseline SHA: `038a62a40cdd528855f5b0b97cbf0ee1e34aa78c0edb8019bd141a30a912435a`.
- Repeated-line guard: `es:3519` has repeated raw method lines not covered one-to-one, but it already fails raw method coverage and was already incomplete; complete count remains 846. Synthetic regression covers a repeated-line false pass.
- All 1,000 snapshot provenance keys are tested. German raw source records are preserved verbatim under `archivedSourceRecord`; canonical `sourceRecord.recordId` maps from original `id`.
- Pack SHA: `54243d124c4648021ae169dc00283ecf19fd29fa176fcbe0c1eeba30241fc62d`.
- Focused tests: 8/8; converter `--check` passed. Root handles shared manifest/status/queue and Git integration.
