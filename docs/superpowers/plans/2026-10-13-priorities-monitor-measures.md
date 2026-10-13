# Priorities, progress monitor and household measures implementation plan

> **For agentic workers:** Use superpowers:executing-plans inline; one fresh review at final integration.

**Goal:** Execute the user-authorized roadmap, detect unexplained pauses, and deliver the first source-backed measurement unit.
**Architecture:** One persistent priority queue/read-only monitor under tool/work; one updated heartbeat starts with audit then executes ready work. Curated USDA portion asset stays separate from recipes/products; a typed read-only repository requires explicit source-portion acceptance and exact food version/form. No automatic inventory write.
**Tech Stack:** Existing Node standard library and Flutter/Dart, no new dependencies.
**Spec:** docs/RESEARCH-ROADMAP.md (user explicitly directs prioritize then implement autonomously; no redundant approval/worktree needed).

## Constraints and review focus

- Sole E checkout/main, source/health/price unknowns remain unknown; no UI/audio/images/Firebase/billing.
- Quota missing/false/90% blocks costly work; source503 blocks only its task; preserve backoff.
- Detect stale active work without starting another writer; dependency cycles/unknown IDs invalid.
- Exact food ID/version/form and source portion fields; no silent cup-volume/count conversion or cooked/raw substitution.
- Proposed grams are estimates, not actual weighed quantities or confirmation. No stock/history/person intake mutation.

## Tasks

- [x]1. Node monitor TDD: source waiting plus ready local work, stalled active task, quota limits/unknown, cycle/dependency validation, all-done and real queue audit; implement CLI read-only and test.
- [x]2. Household repository TDD: explicit acceptance, positive/fractional measure quantities, immutable options, unknown/mismatched food/form/source rejection, zero-option gaps, source scaling, read-only preview use. Validate103indexed options/hashes with Node. Existing data/nutrition asset directory already bundled.
- [x]3. Run meaningful full integration gates, fresh review and fix critical issues. Test actual watchdog manually. Update automation-2 through official tool, preserve thread/notification settings, cadence30minutes, combined worker+monitor to prevent concurrent writers. Verify actual saved schedule.
- [x]4. Mark only proven units done; leave measure-integration next. Update AGENTS/continuity/STATUS/HANDOFF and external receipt; commit/push/clean equality.

Ledger: cheap research agent owns household-measure JSON/handoff; root owns code/shared docs/queue. Source bank has103options/36foods with6explicit gaps, not approved user measures. Ruling: first catalog unit is read-only; persistent cooking integration remains task1b to avoid silently mixing planned source estimates with actual stock consumption. Existing user authorizes this scope and schedule update; preserve all prior decisions.
