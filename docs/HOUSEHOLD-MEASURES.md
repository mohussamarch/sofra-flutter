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

## Next integration contract — not implemented by this catalogue

Persist exact recipe revision/line/food/form/option acceptance and evidence; mark source estimates separately from actual user weights. Decide how scaling and explicit replacement work, then ensure confirmation uses one quantity consistently for stock, cost and nutrient snapshots, with once-only deduction and save-failure rollback. Existing count-unit and measured-override restrictions must be handled with regression tests; do not silently pass a source estimate as a measured actual use. Compound rows require a new recipe revision before split bindings. This remains `measure-integration` in WORK-QUEUE.json.

## Verification

- Flutter household test: all 36 entries/103 portions/6 gaps; explicit acceptance; fractional scaling; invalid quantity/selection/version/form/source rejection; read-only KitchenService input preview with unchanged snapshot.
- Node household test: exact source-indexed fields, identity, provenance, canonical-LF hashes, no invented quantities/RACC conversion and aggregate counts.
- Full integration this delivery: 75 Flutter tests, clean analyze, 31 related Node tests. See HANDOFF section30 for review and delivery details.
