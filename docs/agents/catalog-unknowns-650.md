# Unknown recipe metadata model

Objective: represent source-provenanced catalog recipes with unknown yield/timing without defaults, while retaining the legacy catalog contract.

Changes:
- `lib/domain/recipe_catalog.dart`: nullable servings, prep/cook totals and per-step durations require explicit `metadataPolicy: source-unknowns-v1` plus non-empty provenance notes. Policy is serialized only when present; legacy JSON shape stays unchanged. Unknown component time forces `totalTime: null`. Legacy null/malformed values remain rejected.
- `forServings(target, sourceServings: ...)` refuses unknown base yield unless a caller supplies a valid 1..1000 source yield for that call. That override is not stored back into the recipe. `ScaledCatalogRecipe.totalMinutes` remains null when a component is unknown. `schedule` throws `StateError` when any step duration is unknown.
- `lib/data/recipe_repository.dart` and `lib/domain/recipe_nutrition.dart` continue to validate/load nullable values. Nutrition fingerprints include nulls and retain the previous serialization shape for known recipes. KitchenService calls its existing `forServings(meal.servings)` boundary before stock, budget or nutrition calculations, so an unknown-yield recipe fails before calculation or writes; no automatic yield is invented.
- RecipeRevision's immutable copy through `toJson/fromJson` retains nulls, metadata policy and source notes. No plan/UI behavior claims these candidates are fully auto-plannable.
- `test/catalog_unknown_metadata_test.dart` covers opt-in/provenance enforcement, null round-trip, repository loading, explicit-yield scaling, unknown timing/schedule refusal, known legacy shape/fingerprint round-trip and immutable revision preservation. Two existing fixture tests add non-null assertions only for catalog-known fixtures.

Verification: focused `flutter test --no-pub test/catalog_unknown_metadata_test.dart test/catalog_expansion_test.dart test/nutrition_integration_test.dart` passed (11 tests); `flutter analyze --no-pub` clean. A first expected scaled-time assertion was corrected to the established recipe scaling formula; final run is green.

Unresolved: no source candidate was converted/loaded as part of this model task. The candidate workers/root own that. Root should review/integrate the additive schema field before registering source candidates. No shared status/handoff, source datasets, UI, Firebase or Git operations were changed by this worker.
