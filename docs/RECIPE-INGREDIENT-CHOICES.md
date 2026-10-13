# Explicit ingredient choice revisions

Backend API for a caller-reviewed single replacement in an existing registered recipe. It does not parse alternative names, establish food equivalence, approve nutrition or import research recipes.

```dart
final child = await kitchen.chooseRecipeIngredient(
  sourceRevisionKey: exactSource.key,
  line: sourceLineIndex,
  selected: reviewedIngredient, // CatalogIngredient with explicit amount/unit
  variantId: privateVariantId,
  revision: newRevisionId,
  reviewNote: userReviewNote,
  reviewedAt: fixedReviewTime,
  acknowledgeCompleteReplacement: true,
);
```

The selected ingredient fully replaces one source row. The caller acknowledges that the preserved instructions remain appropriate. The resulting personal revision contains one chosen row, the other original rows and unchanged steps. Its parent, full source snapshot, selected ingredient, note and UTC date are retained in `IngredientChoiceReview`. Same-ID unresolved replacements and unknown selected amounts reject. Ingredient quantity/scale/optional flags are explicit caller inputs; the API does not choose a weight or optional inclusion itself.

`RecipeBook` verifies the exact source parent/snapshot and reconstructed complete recipe, including preserved region/method metadata. Other recipe edits require a later general revision. Split and single-choice evidence cannot both certify one child. Version1 books without the new optional field remain readable. Review evidence is caller-provided attestation, not independent proof of culinary equivalence or source authenticity; the existing full-content fingerprint is not a security signature.

KitchenService builds the immutable draft before awaiting repository/save work, then uses the existing atomic book writer. Failed saves do not publish it. Identical retries preserve newer active revisions; changed content under the same key rejects. Keep review dates and content fixed for request retries. Old plans stay pinned and completed cooking, nutrition, prices and stock deductions remain frozen.

New revisions require fresh `RecipeFoodSelection` bindings by exact revision/line. None are inherited, including unchanged rows. The generic food bank and research identity candidates do not become accepted identities through this API. Source form, actual quantities, preparation, retained nutrients and allergies still need their existing explicit review. Research recipes with unknown timing/servings are not silently converted into CatalogRecipe by this change. Recipe creation from scratch still requires its separate implementation.

The external UI can call this API through the single KitchenService owner. No new UI, Firebase migration, deployment or APK is included. Existing older clients must not concurrently rewrite the same state; compatibility with old books does not guarantee older writers preserve new nested evidence.

Verification:7new focused tests cover exact single replacement/scaling, acknowledgement/quantity/identity, rollback/reload/retry, stale/tampered source/selection/recipe/region/method, pinned plans/no inherited bindings, frozen cooking and deduction, legacy JSON and mutually exclusive evidence. Final full Flutter107tests passed; analyzer clean. Independent focused review found no must-fix; root subsequently reproduced and fixed metadata tampering, then reviewer confirmed the focused guard. Reviewer did not run tests. See HANDOFF§53.
