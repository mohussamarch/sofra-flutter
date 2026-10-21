# Fifth 1,000 source records — 2026-10-21

## Audited result

Converted exactly 1,000 records from the existing offline Spanish and German archives: 630 Spanish and 370 German. The pack contains 8,030 ingredient lines and 5,894 method steps. Strict source-text completeness is **846 records**; **154 remain incomplete**. Conversion count is not a complete-recipe count.

The completeness gate now requires explicit recognized source templates, no unresolved markup/editor artifacts, exact parsed ingredient text found in the pinned raw source, raw ingredient-list line count matching parsed count, and every parsed method step found in raw source with all raw method lines represented. This is a conservative text audit, not culinary validation. The selected pack has 978 records with verified raw ingredient coverage and 22 requiring review; 853 have verified raw method coverage and 147 require review. There are 12 flagged ingredient lines and 3 flagged method steps. No ingredient names or method text are blank.

The full candidate pool contains 853 Spanish and 544 German records. Strict-complete candidate counts are 476 Spanish and 373 German; incomplete counts are 377 and 171. Ingredient coverage review applies to 73 Spanish and 2 German candidates; method coverage review applies to 311 Spanish and 149 German candidates. The candidate audit counts overlap and are not exclusion totals. Four normalized content matches were excluded against the previous selection. The 1,000-record target was retained by including 154 explicitly incomplete records, each labeled accordingly.

The renderer uses explicit per-template arity/display-field schemas for `ing`, `coc`, `ute`, `ter`, `rec`, `tbc`, and `w`. Unsupported templates or arities remain visible and disqualify affected records from the complete count. Wiki file/image links, residual pipes, tooltips, editor artifacts, and HTML constructs remain visible and flagged. `es:156` and `es:162` fail the strict gate: their raw ingredient counts match parsed counts (15 and 12), but the parsed strings are not exact source literals because tooltip content was folded into them. Tests assert this. Raw method coverage is audited with the same explicit completeness outcome; prose omitted by parsing is disqualifying.

## Review state and rights

All records need culinary, quantity, and page-rights review. None is translated, runtime-ready, or nutrition-approved. Amounts, units, yield, time, and nutrition remain unknown. Cuisine is empty; source language is not used as cuisine. CC BY-SA 4.0 site-policy metadata is retained where available; page-level exceptions remain unreviewed and German source/license status is unverified. No rights approval is implied.

## Provenance

The converter validates frozen baseline manifest SHA `038a62a40cdd528855f5b0b97cbf0ee1e34aa78c0edb8019bd141a30a912435a` (23 prior packs / 4,530 rows) against the current shared manifest and checks pinned pack/snapshot hashes.

Spanish archive hashes: source `459fc5b1985bba90ce340c5e0cbb3f73ac68664fe6218b2cd8966a3fb0bb4842`; parsed `822b9613fda4cb9d0eac73fc83dd8f630220cad4d1ebd5150fdc35613dba485b`. German archive hashes: source pages `289fcde82d231300df6fc36eefe96bbc941d3fda3a086d468ff207957eb4e04a`; parsed candidates `6bbff318d7ba5af472cd7d129ffda7f68a8c1b844e6504821ff00137af1175ed`.

The generated output contains the normalized pack, report, frozen baseline copy, and exactly 1,000 raw source snapshots. The generator only removes stale generated snapshot names inside its owned folder; `--check` validates the exact snapshot set and output bytes. No network or new acquisition was used.

## Verification and limits

- `node --test tool/recipes/bulk-normalize-5000.test.mjs`
- `node tool/recipes/bulk-normalize-5000.mjs --check`

Source-text completeness does not imply culinary, rights, quantity, nutrition, or runtime approval. A read-only repeated-line probe found nine repeated method-line entries; `es:3519` has repeated occurrences not covered one-to-one, but it already fails method coverage (22 unmatched raw lines) and was already among the incomplete records, so the complete count did not change. A synthetic regression verifies repeated identical raw method lines cannot be satisfied by one parsed step. German snapshots retain the original archive record under `archivedSourceRecord`; the canonical `sourceRecord.recordId` maps from the archived `id`, with the original fields preserved. Snapshot tests verify `recordId`, `sourceId`, revision, timestamp, URL, source hash, and license match row provenance for all 1,000 records. Semantic and cross-language duplicate status is unknown. Root owns shared manifest/status/queue and Git integration; this work changed no shared files or Git state.
