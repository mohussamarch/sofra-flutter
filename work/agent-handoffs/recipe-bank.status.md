# Recipe bank collector status

- State: bounded six-candidate research batch complete; research-only, not runtime-ready.
- Source groups: 2. Wikibooks CC BY-SA 4.0 (license policy verified); USDA MyPlate preserved archive (license claim not verified against primary USDA source). These source groups remain separately attributed in JSON; each adapted Wikibooks record must retain attribution/change notice/share-alike.
- Candidates: 6; ingredient rows: 61; ordered Arabic step summaries: 46. Added Egyptian Koshari and Gulf/Saudi-associated Shitha.
- Checks: `node tool/recipes/validate-research.mjs` passed (6 candidates, all research-only, runtimeReadyCount 0); JSON/invariant check passed. No app tests/build needed or run.
- Blockers: four USDA records lack primary source confirmation; Shitha's version-specific permalink unavailable; candidate overlap decisions, canonical units/choice groups, missing aggregate durations, and explicit version/line nutrition review.
- Next: locate a Shitha revision permalink or replace with a Saudi recipe source with a revision ID; verify USDA sources; then curator review before any runtime revision. Full mapping and license notes in `recipe-bank.md`.
- Checkout: `E:\work\SOFRA\app`; base `7d9dcb4`; no commit/push; no server changes.
