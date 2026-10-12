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
- Do not invent current prices, nutrition or medical rules. Price sources, nutrition coverage, automatic budget plan generation and alternatives are later work. Missing data stays unknown.
