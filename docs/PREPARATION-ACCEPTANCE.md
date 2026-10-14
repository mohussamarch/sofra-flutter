# Explicit category preparation estimates

This is an internal backend contract; the current UI/APK does not call it.
Source review remains [PREPARATION-EVIDENCE.md](PREPARATION-EVIDENCE.md).

## Exact scope

`PreparationCategoryRepository` supports only the reviewed generic USDA
`usda:168927`, version `2018-04`, as-sold dry unenriched pasta. Methods are
`0381` (boil/drain) and `0382` (boil/drain/bake). The user must select the actual
method, acknowledge a category estimate and the unknown source-specific reuse
license, and provide a note and UTC acceptance time. This acknowledgement does
not establish permission to redistribute the source or scientific exactness.

The repository verifies the reviewed source shard using SHA256 of UTF8 text
after CRLF-to-LF normalization, not the downloaded/raw shard bytes. These are
different fingerprints. It checks the actual canonical FoodRecord, review and
retention candidate rows; local consistency is not independent authentication.
No automatic match by product name, cuisine, recipe name or barcode is made.

Only vitamin C, thiamin and riboflavin have category factors here. The other
46 factors, mass yield and edible fraction remain unknown. The primary five
display nutrients therefore do not gain cooked values from this review.
Already cooked, enriched, branded or otherwise different foods are unsupported.
The two methods are alternatives: never multiply `0381` by `0382`.

## Service use

```dart
final preparations = PreparationCategoryRepository();
await kitchen.acceptRecipePreparationEstimate(
  planId,
  preparations,
  line: lineIndex,
  retentionCode: '0381',
  reviewNote: actualMethodReview,
  acceptedAt: DateTime.now().toUtc(),
  acknowledgeCategoryEstimate: true,
  acknowledgeUnknownLicense: true,
);
```

First bind the exact food explicitly to the exact recipe revision/line.
Acceptance freezes source, factor rows, food and recipe scope; it does not
change stock, purchases, person intake or scientific approval lists. Replacing
an existing preparation needs `replaceExisting:true`; it replaces the whole
transform. An asynchronous plan/binding change rejects the stale acceptance.
Failed storage rolls back and permits retry.

`previewIngredientNutrition` continues to estimate the food before cooking.
`previewNutrition` uses the selected preparation conservatively; all missing
retention factors remain gaps. It does not certify a finished mixed dish.

```dart
await kitchen.confirmCooking(
  planId,
  operationId,
  acknowledgePreparationEstimates: true,
);
```

Confirmation requires this separate acknowledgement only for included lines
that use an accepted category estimate. Actual weighed grams do not remove
preparation uncertainty. Unselected optional and explicitly omitted unknown
lines do not use the estimate. Source quantity estimates have their own
`acknowledgeSourceMeasureEstimates` flag.

Cooking history freezes `estimatedPreparationLines` and
`preparationEstimateEvidence`; nutrition snapshot/confidence and any later
person portion retain `estimated:true`. Missing is not zero. Stock deduction is
atomic and once per operation; no person consumption event is created.

## Persistence and limits

Recognized reserved category transform IDs/evidence are checked when saving or
reading recipe bindings in KitchenService. Persisted evidence must retain exact
food/method/factor/confidence/recipe scope. This is not a signature over arbitrary
caller data or a replacement for source review. The existing generic/manual
PreparationTransform API remains available; it is not a scientifically approved
coefficient bank.

No measured cooked mass, macro retention, universal conversion, full bechamel
nutrition, clinical suitability, automatic source-bank promotion, UI or Firebase
integration is supplied by this unit. Broader food/method coverage and source
reuse review remain open research work.
