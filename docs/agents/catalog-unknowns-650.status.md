# Status — catalog unknown metadata

Stage: model and focused verification complete; awaiting root review/integration.

- Unknown source yield/time are explicit nulls guarded by `metadataPolicy: source-unknowns-v1` and non-empty provenance notes.
- Automatic scaling refuses unknown base yield; explicit one-call source yield is supported. Incomplete schedules and total time remain unasserted.
- Legacy known recipes preserve their serialized shape and existing scaling behavior.
- Focused tests passed (11); analyzer clean. Details: `docs/agents/catalog-unknowns-650.md`.
- No claim that 650 candidates are loaded or fully auto-plannable.
