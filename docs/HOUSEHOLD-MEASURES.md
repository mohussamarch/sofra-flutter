# Household source measures API

## Scope and evidence

`data/nutrition/household-measures-review.json` contains 36 exact USDA food/form entries, 103 source-indexed portion options across 30 entries, and 6 explicit gaps. USDA CC0 source version, description, shard, canonical-LF SHA256, URL and all five original portion fields are retained. RACC-only entries are gaps, not household utensil measurements. This is a curated source estimate catalogue, not an approved user conversion bank or a claim about common Egyptian/Saudi package sizes.

`lib/data/household_measure_repository.dart` loads the existing bundled nutrition asset. Options require exact generic food ID/form/version/description and match the live bundled source portion fields. Different food forms are never substituted. Missing options stay missing. Source hashes are verified by the Node build/review gate; the runtime verifies the selected food and portion fields, not a new whole-shard crypto read on every request.

## Read-only use

```dart
final food = await foods.usdaFood(foodId, form: explicitlySelectedForm);
final measures = HouseholdMeasureRepository(foods: foods);
final review = await measures.optionsFor(food);
// The plan must already have an explicitly accepted food selection for this revision/line.
// Present review.options with their source modifier/description and limitations.
final proposal = await measures.resolve(
  food,
  optionId: explicitlySelectedOptionId,
  measureQuantity: userQuantity,
  acknowledgeExactSourcePortion: true, // actual explicit acceptance, not a default
);
final preview = await kitchen.previewIngredientNutrition(
  planId,
  measuredLines: {lineIndex: proposal.amount},
);
// proposal.toJson() exposes original evidence; no state write happens here.
```

Grams = sourceGramWeight × measureQuantity / sourceAmount. Quantity must be positive and finite; overflow is rejected. A source cup/chopped onion/count size is not a universal density or a weighed quantity. Raw source labels may contain “undetermined”; show the source modifier/description, and do not infer a volume from that marker.

`proposal.estimated` is always true; basis is `edibleInput`. The input preview remains an estimate. Prepared recipe nutrition still needs preparation/yield evidence, and no per-person consumption is inferred. No stock, cost, plan, history or user selection is changed by this repository.

## Persistent acceptance and confirmed cooking — implemented

```dart
await kitchen.acceptRecipeHouseholdMeasure(
  planId, measures,
  line: lineIndex,
  optionId: userSelectedOptionId,
  measureQuantity: equivalentBaseRecipePortions,
  acknowledgeExactSourcePortion: true, // explicit review of equivalence to BASE line
  replaceExisting: false, // existing measured or accepted choice requires explicit replacement
);
// Option A: user actually measured the amount for THIS cooking, including numeric/count rows.
await kitchen.confirmCooking(planId, operationId,
  actualUsesByLine: {lineIndex: IngredientUse(ingredientId, actualGrams, 'g')},
);
// Option B: user explicitly accepts source-estimated quantities at confirmation.
await kitchen.confirmCooking(planId, operationId,
  acknowledgeSourceMeasureEstimates: true,
);
```

An existing food selection is required for the exact revision/line. Edible input form must match food form; as-purchased/nonconsumed material requires separate review. Already quantified mass/volume recipe lines cannot be overridden by a source portion acceptance. The quantity parameter describes the equivalent BASE recipe line, not the currently scaled meal or an actual weighed use. Each accepted choice preserves immutable serialized proposal evidence, revision, line and acceptance time in RecipeFoodSelection.householdMeasureEvidence. Stored choice replacement is explicit; async plan/food-binding changes reject and failed saves roll back. Old version1 selections without the new optional field remain readable and eligible for acceptance.

Preview scales accepted source grams by the recipe row's scale flag; explicit measuredLines overrides them. At confirmation, actualUsesByLine is a copied per-cooking input and can override numeric nominal/count amounts. Existing measuredUsesByLine/measuredUses remain actual overrides for legacy unmeasured rows; their original restrictions remain. Conflicting actual APIs/omit are rejected. Actual cooking quantities take priority over source estimates; unused optional lines are ignored. Source estimates require acknowledgeSourceMeasureEstimates=true at confirmation, even after acceptance. Without it, confirmation rejects before a state change.

The resolved use drives stock, price calculation and nutrition together. Cooking snapshots freeze estimatedSourceMeasureLines, actualMeasuredLines and sourceMeasureEvidence; retries reuse the original receipt and do not deduct again. RecipeFoodInput.quantityEstimated survives serialization and marks contributing NutrientTotal.estimated=true even if nutrient concentration is analytical. An actual weight clears quantity-estimate status; independently estimated nutrient concentration still remains estimated. Recipe snapshot retains the source FoodRecord and accepted quantities. No automatic person intake is recorded; PersonNutrientValue confidence aggregation is a later people-task gap.

## Remaining work

Compound rows need a new recipe revision with separately reviewed amounts and food identities; no automatic split ratios, copied bindings by shifted line index, or salt-only substitution. Preparation/yield/retention still needs evidence. The new API is not wired to the external UI or an APK this delivery.

## Verification

- Eleven integration tests cover save/reload/scaling/non-scaling/optional amounts, explicit acceptance/replacement, legacy JSON compatibility, race rejection, save failure rollback, consistent stock/cost/nutrition, once-only receipts, actual overrides, invalid/conflicting units and tampered evidence.
- Fresh review P2: analytical protein with a source-derived quantity incorrectly returned estimated=false. Reproduced using shipped dry pasta usda:168927; fixed with persistent quantityEstimated and round-trip/actual-weight regression checks.
- Full gate this integration:86Flutter tests, no analyzer issues,33related Node tests including2CLI safety tests. Prior catalogue36foods/103options/6gaps unchanged. See HANDOFF§31.
