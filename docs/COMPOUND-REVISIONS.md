# Explicit compound ingredient revisions

This is a backend review mechanism, not authored recipe ratios or automatically approved food bindings. Register the exact source first via catalogRevision, or use an already stored personal/variant revision. All quantities are supplied by the caller.

```dart
final child = await kitchen.splitRecipeIngredient(
  sourceRevisionKey: exactSource.key,
  line: compoundLineIndex,
  components: userReviewedComponents, // List<CatalogIngredient>,2+distinct quantified IDs
  variantId: personalVariantId, // cannot overwrite a built-in catalogue ID
  revision: newRevisionId,
  reviewNote: userReviewNote,
  reviewedAt: fixedReviewTime, // preserve for idempotent request retries
  acknowledgeCompleteReplacement: true,
);
```

Acknowledgement affirms that these components fully replace the selected base-recipe line and the preserved recipe instructions remain appropriate. No ratio, name interpretation, culinary equivalence or nutrition identity is inferred. Two IDs with different names are not proof of food identity: explicit food bindings are still required after review. Single-component salt-only substitution for salt+pepper is not accepted as a split. Unknown component amounts reject; they must be reviewed rather than divided from the compound label.

IngredientSplitReview retains source revision key/full snapshot fingerprint, line, immutable components, note and UTC date. Each component has its own scale/optional/unit flags. The builder creates a complete personal revision, replacing only that row and recipe ID. RecipeBook checks its exact parent and expected complete recipe; unrelated edits require a separate subsequent revision. Existing code may still create general personal revisions through saveRecipeRevision; this split-specific evidence is not proof for other edits.

KitchenService copies the draft before awaits and saves through the existing atomic book writer. Duplicate identical saves do not reset a newer active revision. Dates/content must be the same on a retry; reusing a key with different review data rejects. Save failure does not publish the revision. Existing plans are never replanned, completed cooking stays frozen and version1 books without this optional field remain readable.

Every new revision starts without automatic nutrition binding inheritance, including unchanged/shifted lines. Review/save RecipeFoodSelection per exact revision/line. Catalogue reference proposals cannot be blindly restamped onto changed ingredients; they require a fresh source review. No new authored recipes, catalogue mutations, nutritional facts, UI or APK are included.

Verification:6new tests cover full immutable contents/scaling, explicit complete replacement/quantities, rollback/reload/retry, old pins and zero inherited bindings, stale/tampered source evidence, frozen history. Full92Flutter tests passed and analyze clean. Independent focused review found no must-fix defects; reviewer did not rerun tests. See HANDOFF§32.


## Explicit single ingredient choice API

[RECIPE-INGREDIENT-CHOICES.md](RECIPE-INGREDIENT-CHOICES.md): KitchenService.chooseRecipeIngredient creates one caller-reviewed quantified replacement as a new personal revision. Source/full snapshot/region/method and complete expected recipe guarded;old plans/history frozen,no inherited nutrition bindings.7newtests/full107Fluttertests/analyzeclean. Research source promotion and private from-scratch creation remain separate.
