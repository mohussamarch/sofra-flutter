# Native imported candidate reader — 0229

Selected checkout: `E:\work\SOFRA\app` only. Coordinator owns shared handoff, Git, Node transport and KitchenService/revision integration.

## Objective and files

Implement native Dart consumption and persisted revalidation of the Node-validated structural source candidate. Assigned edits only:

- `lib/domain/imported_recipe_candidate.dart`: `ImportedRecipeCandidate.fromTransport`, `fromJson`, `transportSha256`, immutable `CatalogRecipe`, source IDs, cloned provenance, unmodifiable remaining gates, and owned `toJson` wrapper.
- `test/imported_recipe_candidate_test.dart`: 27 focused native tests using the synthetic Node emitter `tool/recipes/runtime-adapter.emit-fixture.mjs --transport`; no shipped fixture recipe/assets.
- `pubspec.yaml` and `pubspec.lock`: direct exact `crypto: 3.0.7`, resolved from existing cache with `flutter pub get --offline`.
- This handoff and `native-reader-0229.status.md`.

## Decisions and validation

Transport is the exact four-field Node contract: schemaVersion1, encoding `utf8-json`, original JSON payload string and lowercase hex SHA256. Trusted caller `expectedSha256` must match both the reported digest and SHA256 of the unchanged UTF-8 payload. Persistence retains `{version:1, expectedSha256, transport}` and revalidates the full wrapper on reload, avoiding Dart/Node canonical numeric serialization differences. The payload string retains original scientific notation, JSON numbers, nulls, and licence facts.

Native validation requires exact candidate/recipe/provenance/review/line/component/raw-food shapes, candidate status unapproved, runtimeReady=false, nutrition unreviewed with no bindings, and all four remaining gates in order. It requires valid source hashes, attribution URL, nonempty licence evidence, real UTC review timestamps, ordered unique source line targets anchored to the same full source fingerprint/source IDs/revision/SHA/parser versions, full once-only ordered runtime coverage, explicit split/choice/exclusion dispositions, component identity/form/optional consistency, positive measured quantities, explicit booleans and sequential steps.

Inputs are copied. The original wrapper remains private; provenance and serialization results are fresh deep copies, and remaining gates cannot be mutated. Existing CatalogRecipe owns immutable ingredient/step/tag collections.

## Verification actually run

1. `flutter pub get --offline` via `C:\Users\atgs0\Documents\Codex\2026-10-09\cooking-app-flutter\work\flutter_sdk\bin\flutter.bat`: exit0, added cached crypto3.0.7 only.
2. `flutter test test/imported_recipe_candidate_test.dart --reporter compact` before implementation: exit1, expected missing reader file/type compile-red.
3. `dart format lib/domain/imported_recipe_candidate.dart test/imported_recipe_candidate_test.dart`: exit0, both files formatted.
4. Same focused native Flutter test after implementation: exit0, **27/27 passed**, 7.8s command wall time. Cases include stale/report/reference hashes, missing provenance, smuggled approval, gates/bindings, licence/source URL/source SHA/review date, stale/duplicate/source mapping guards, full runtime coverage/order, ingredient form/identity/raw-food reference, explicit quantities/scale/optional, fractional step index, ownership, persisted revalidation, original exponent payload and unknown/null licence facts.

No full suite/analyzer/APK/device test was run by this worker; coordinator will run final integration/global verification after all writers finish. Other tests observed by coordinator are separate evidence.

## Limits and exact next action

Expected SHA must be supplied from the trusted validated-artifact pipeline. Local digests are consistency checks, not source authenticity, culinary completeness, legal/medical/scientific approval. Dart cannot reconstruct the archived source/draft/metadata/food snapshots from this envelope; those opaque fingerprints retain format and internal anchor checks, with Node authoritative reconstruction performed before packing. Raw USDA references remain unreviewed references, never runtime bindings. No actual source recipe imported by this worker; no user/cloud/Firebase/billing writes, UI changes, recipe-bank edits or shipping recipe/assets changes.

Coordinator: integrate immutable import registration/history behavior, review the reader, run final full Flutter/Node/analyzer gates, consolidate tracked/external handoffs, and commit/push/receipt under the mandatory protocol. This worker performed no Git mutations/commits and left no commands or servers running; preview ownership remains for coordinator to inspect at delivery.
