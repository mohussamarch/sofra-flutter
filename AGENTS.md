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
- User explicitly authorized implementation and Firebase setup. Active milestone: authentication, persistence, and a testable Android APK. Follow the incremental execution plan.
