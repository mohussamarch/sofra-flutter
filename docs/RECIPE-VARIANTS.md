# Recipe families, variants and frozen revisions

Canonical checkout: `E:\work\SOFRA\app`. Backend API only; no new UI or authored food variants.

## Identity and persistence

- `RecipeFamily`: stable dish identity/name. `RecipeRevision`: a complete immutable `CatalogRecipe`, variant ID, revision, kind (`catalog`, `variant`, `personal`), family, optional region/method and source revision (`parentKey`). Personal recipes require a source. Parents must exist in the same family; inheritance is historical, never live.
- `RecipeBook`: append-only revisions and active revision per variant. Reusing a revision key with different content is rejected. Repeating an identical save does not roll back the active version. Identity cannot change family/kind.
- Built-in recipes enter the book lazily through `catalogRevision` or planning. Initial family is `dish:<recipeId>`; full content gets an FNV1a64 fingerprint (not a security signature). Existing recipes are not automatically grouped as equivalent dishes.
- `KitchenService` remains the single writer. State has optional `recipeBook` version1, preserving existing kitchen schema. The850KB document guard still applies; unlimited revision history needs later archival work.

## UI integration sequence

```dart
final source = await kitchen.catalogRevision('eg-bechamel-pasta');
final personal = RecipeRevision(
  familyId: source.familyId,
  revision: 'v1',
  kind: RecipeRevisionKind.personal,
  parentKey: source.key,
  recipe: CatalogRecipe.fromJson({
    ...source.recipe.toJson(),
    'id': 'my-bechamel',
    // Supply the user's complete ingredients/steps/metadata here.
  }),
);
await kitchen.saveRecipeRevision(personal);
// plan(PlannedMeal(recipeId: personal.variantId, ...)) pins its active revision.
// Use recipeForMeal(planId) to read the exact planned recipe revision.
final choices = kitchen.recipeBook.variants(source.familyId);
```

Use `saveRecipeFamily` for another dish, then `saveRecipeRevision` for full variants. Built-in catalogue IDs cannot be overwritten by custom variants. Next edit is a new revision, not mutation of the existing one. Use an explicit `recipeRevisionKey` in a plan to choose an older stored version. `RecipeRepository.get` alone cannot resolve personal or pinned older content.

## Nutrition, optional lines and cooking

- Every `RecipeFoodSelection` belongs to exact `recipeRevisionKey` plus recipe ID and line number. Bind each revision explicitly after review; do not carry bindings to a new ingredient list automatically.
- Prefer `optionalLines`, `measuredUsesByLine` and `omitUnmeasuredLines` in `confirmCooking`. Repeated ingredient IDs can occur on independent recipe lines. Legacy ID measurements are rejected for repeated unmeasured IDs. Measurements and omissions on the same line conflict. Unsupported actual measurement units require review before confirmation; they never fall back to an older reviewed weight.
- `previewNutrition` accepts `optionalLines`, `measuredLines` and `excludedLines`. Preview and confirmation must use the same choices; confirmation calculates its own result from actual consumption inputs.
- Cooking atomically freezes the full recipe/family, selected/omitted lines, costs, nutrition and batch ledger alongside stock deduction. Operation IDs remain idempotent. No selected ingredients is rejected with rollback, not reported as zero-food cooking.
- Old unversioned nutrition bindings remain stored but are excluded until explicitly reviewed and saved against a revision. Old unpinned plans resolve the current bundled recipe until pinned by saving/cooking; historical ingredients cannot be reconstructed retroactively.
- Completed history keeps its snapshot even after catalogue updates or custom edits. Nutrition unknowns remain unknown; no automatic intake for people.

## Current limits / next task

54 original recipes preserved;605 review lines and0 verified nutrition bindings. This delivers the mechanism, not populated regional variants or complete recipe nutrition. Next: source-review bechamel ingredients/forms/units and label basis, bind them to a pinned revision, then connect the external UI to this API. No pricing feed, medical targets, Blender models or interface changes were added.
