# Agent handoff and economical execution

## Start

1. Read `docs/STATUS.md` first; keep it under 50 lines.
2. Search `docs/HANDOFF.md` for the relevant topic, then read only that section and the source files needed for the task.
3. Check the current diff before editing. Treat previous test results as historical evidence, not proof of later changes.

## During work

- Keep one owner per edited file when agents are used. Delegate only under applicable authorization.
- Do not repeat a completed investigation unless new evidence or changed files require it.
- Use focused verification; run a full gate at a meaningful integration point or when a concrete risk requires it.
- Preserve the existing implementation and approved scope; collect future ideas separately.

## Before finishing or handing work off

- Update `docs/HANDOFF.md`: objective, changes and file paths, decisions and reasons, verification actually run and results, unresolved issues, and exact next action.
- Update `docs/STATUS.md`: current stage, latest completed work, blocker, and next action, with pointers to relevant handoff sections.
- Record important findings, not raw transcripts, repeated plans, full logs, credentials, or tokens.
- A delegated agent reports its handoff entry to the coordinator; the coordinator consolidates the shared summary to avoid concurrent edits.
- Do not claim code, deployment, external setup, or tests were completed unless verified.

## Current constraints

- Test device: Samsung Galaxy S24 Ultra. Android APK is the preferred native test artifact.
- Firebase: dedicated project `sofra-c03a1`, created and supplied by the user; CLI access verified. Do not modify other projects or enable billing.
- User explicitly authorized implementation and Firebase setup; accounts, persistence and test APK are verified. Current design prototype source: design-preview/. Keep kitchen isometric, fridge one-point frontal perspective, characters flat and animated. No further image generation or music; sound effects cancelled for now. Review the interactive prototype before porting its design to Flutter.

## Mandatory user handoff protocol — 12 October 2026

- Select one checkout per work session and record its absolute path in the handoff. GitHub `origin/main` is the reference. Current selected checkout: `E:\work\SOFRA\app`; the Codex checkout is an inactive snapshot. Do not edit both independently.
- Before delivery, commit all completed changes and push them to `origin main`; verify clean status and matching local/remote commits. Keep unfinished work on a named branch and record it. Do not leave uncommitted work.
- Update `docs/STATUS.md` and relevant `docs/HANDOFF.md` sections with changes and paths, decisions/reasons, checks actually run/results, open issues and the exact next action. Historical results must be labelled as historical.
- When working in the E checkout, also update `E:\work\SOFRA\STATUS.md`, `HANDOFF.md` and `DELIVERY.json` outside Git. Record the final pushed commit hash there after committing the tracked handoff. The tracked handoff records its base commit and points to this final receipt to avoid a self-referential hash.
- End the handoff with the commit information and whether preview servers remain running: port, process identity, source checkout and restart command, or explicitly closed. Inspect the owning process before stopping it.
- For every newly built APK, record filename/version, source commit, SHA256, absolute location, actual S24 Ultra test status and actual Drive upload status. Do not label a previous APK as newly built or tested.
- Record every Firebase change precisely. Only `sofra-c03a1` is authorized; no other project and no billing activation.
- Explicitly record any changed user decisions, including audio, image generation, kitchen/fridge geometry or inventory deduction. Preserve existing decisions unless the user changes them.
- Never write credentials, passwords, tokens or private keys into handoff files or source control.

## Current scope — backend first

- User now asks to complete missing logic without redesigning interfaces; the visual UI will be built elsewhere. Only the subsequently requested functional UI changes are authorized here: male/hijab correction and ordering, general language and EG/SA selection, removing Home from bottom navigation with entry inside Today/Kitchen, a day/week/month meal calendar, and explicit new-purchase selection.
- Backend integration guide: docs/BACKEND-API.md. Use KitchenService as the single state owner in the new UI; do not run legacy UI and new backend writers over the same state simultaneously.
- Financial decisions are explicit in docs/MONEY-RULES.md: budget covers new purchases only; user override before average; alert and suggest without automatic plan edits; explicit purchase toggle; confirmed history prices frozen; no automatic monthly carryover.
- Do not invent current prices, nutrition or medical rules. Nutrition core and sourced banks are authorized/implemented: docs/FOOD-DATA-ARCHITECTURE.md. Recipe/label review coverage, price sources, automatic budget generation and alternatives remain incomplete. Missing data stays unknown.


## Nutrition and external Blender design

- Food API: docs/FOOD-DATA-ARCHITECTURE.md. Keep USDA CC0 and OFF ODbL/DbCL banks separate; preserve provenance, unknowns, exact form/basis and distinct nutrient definitions.
- Recipe selections are explicit per revision and line.54recipes have605review lines and0fully verified bindings.197 generic identity proposals across53recipes now load through RecipeReferenceRepository; see docs/RECIPE-REFERENCES.md. Explicit acceptance/choices, blocked compounds, exact snapshot/source guards and separate ingredient-input estimates are mandatory. Legacy/demo UI does not gain nutrition automatically.
- KitchenService remains the only state owner; cooking freezes nutrition without automatic intake. Preserve append-only corrections and850KBguard. No Firebase migration/billing occurred.
- Blender brief: docs/BLENDER-DESIGN-BRIEF.md. No models/renderer built or thread created. Renderer requires a small asset test onS24Ultra. No UI redesign/audio/image generation authorized by this brief.

## Continuous food bank work

- User explicitly authorizes ongoing economical research and one cheap collection agent. Follow docs/FOOD-BANK-CONTINUITY.md: no arbitrary final record count; checkpoint and resume, check quota with a10%reserve, and preserve quality/source licenses. Never infer successful collection from an attempted request.

## Nutrition summary display

- User-approved summary: energyKcal, protein, totalSugars, fibre, fat, in this order, via primaryDisplayNutrients. Show total fat once; retain all49nutrient fields for future detail. Missing values remain unknown. Do not redesign UI here.

## Recipe revisions and generated cache

- Follow docs/RECIPE-VARIANTS.md. Preserve full immutable snapshots and revision-specific nutrition bindings. Prefer line indices for repeated ingredient choices/measurements. Unknown legacy bindings require explicit re-review.
- Only checkout E:\work\SOFRA\app is active. Its ignored `.dart_tool` and `build` are junctions to C:\Users\atgs0\Documents\Codex\2026-10-09\cooking-app-flutter\work\sofra-generated-cache. These are generated caches, not a second project. Inspect junction targets before cleanup; never recursively remove a computed target without validating its scope.


## Priorities and pause diagnosis — 13 October 2026

- User explicitly asks to prioritize all research/logic/banks and execute in order. Read docs/RESEARCH-ROADMAP.md and docs/WORK-QUEUE.json after STATUS; the older bank-only schedule no longer describes the whole scope.
- automation-2 is one combined monitor/worker every30minutes. Check actual usage then run tool/work/watchdog.mjs with actual --primary/--weekly/--ordinary. Missing/false/90% prevents costly work. A source backoff delays that source, not independent local implementation.
- One checkout/one owner. Diagnose active task progress with its own lastProgress taskId or lastAttemptAt fallback; after60minutes inspect owner/process/evidence before resuming or releasing it. Do not start a second writer or refresh timestamps as fake progress.
- Current completed units: monitor, source measure catalogue and persistent measure integration. See docs/HOUSEHOLD-MEASURES.md: explicit per-revision/line acceptance, source estimate versus actual quantity, acknowledgement before estimated deduction, atomic stock/cost/nutrition consistency and frozen confidence. Compound-revisions is now implemented (COMPOUND-REVISIONS.md), with explicit quantities/full parent guard/new bindings. Next preparation-evidence has4official sources but0approved factors; distinguish data CC0 from unknown document license, keep unarchived hashes null, never apply a universal macro multiplier.
- Close a proven unit with relevant tests/queue evidence/commit/push, then take the next available unit while capacity permits. Product collection remains a helper lane with one cheap gpt-6-luna/medium collector and short context; preserve lock/backoff and its handoff/status. No automatic clinical rules, invented prices or conversions.
