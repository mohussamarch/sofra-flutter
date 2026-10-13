# Independent read-only review — identity readers and collector recovery

- Reviewer: existing preparation_evidence agent; no edits, network calls, tests or collection performed by reviewer.
- Scope: usda-review-reader/validate-identity-bank/recipe-review-reader and tests; first-review metadata; pendingRequest changes and three collector regressions.
- Result: no concrete correctness findings. Recipe/food provenance and derived-source reconstruction guards were consistent; pending and generator cursors remained separate across bounded runs.
- Limits: unsigned local manifests/source snapshots are consistency anchors, not independent upstream authentication. CLI lock check is point in time; concurrent indexer reads are not atomic and should fail hashes/re-extraction if mixed.
- Parent verification:75relatedNode tests passed;8156actualUSDA snapshots validated;8proposals/14candidates/3foods remained unreviewed; live pending recovery completed30pages with actualexit0 and no pending cursor.
- Next: use these guards during more curation and runtime admission; do not treat research proposals as accepted identity, quantity or nutrition.
- Root owns shared docs, commit/push and external receipt. No separate reviewer branch or uncommitted edits.