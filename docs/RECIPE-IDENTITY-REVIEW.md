# Bulk recipe identity review contract

`tool/recipes/review-target.mjs` is an offline research boundary. `reviewTarget(recipe,lineIndex)` pins current source record/revision/SHA, parser versions, exact line ID/text/index and a canonical SHA of the entire derived recipe. Changing any recipe metadata invalidates its target. `snapshotFingerprint` accepts finite JSON values and ignores object key order.

`validateIdentityProposal(proposal,currentRecipe,foodSnapshots)` requires schemaVersion1/status `identity-proposal-unreviewed`, target, candidates and issues. Each candidate has foodId, foodVersion, foodSnapshotSha256 and rationale. The caller must load authoritative current food snapshots in a Map; IDs, versions and canonical full-snapshot hashes must match. Unknown/duplicate identities, stale recipes, changed foods, extra selection/quantity/nutrition/approval fields fail. Empty candidate lists require recorded issues. Candidate and recipe inputs are not mutated.

This validates snapshot consistency, not evidence truth, food equivalence, clinical safety, portions, approval or nutritional basis. No real bulk food proposals have been curated, persisted or applied. No runtime importer or automatic calculation is added. Exact IDs/provenance and separate user acceptance remain required; source or/optional cues never auto-select/exclude. Existing54 recipe review flow remains separate.

6 new tests passed within54 related recipe tests. Initial test run failed because the module did not yet exist; no claim of a prior behavioral-stub regression. Fixtures are synthetic and contain no asserted nutritional facts. Next: authoritative food reader + curated explicit identity/alternative proposals, then runtime acceptance/import.

Actual integration check: unresolved review targets validated against all2788current source recipes; no food bindings/proposals were written. Latest quota87%/27%ordinary=true. Both collector locks absent and original runtime/UI/catalogue unchanged.
