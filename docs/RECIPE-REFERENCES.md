# Recipe reference proposals and ingredient estimates

Sole checkout `E:\work\SOFRA\app`. Backend integration only; the external UI and existing APK do not gain this flow automatically.

## Data contract

`data/nutrition/recipe-reference-review.json` holds197 reviewed identity proposals across53/54 recipes and605 catalogue lines. It uses36 USDA generic references underCC0:153 recommendations and44 entries needing choices. All10 bechamel lines have proposals, including a blocked compound seasoning line. This is0 confirmed complete nutrition bindings; no user selections were preinstalled.

An entry identifies recipe ID, exact line/ingredient/name, full runtime recipe snapshot version, original quantity/unit/optional status, canonical-LF source SHA256, source candidate ID/version/description/form/rationale and unresolved issues. These proposals do not establish the actual brand, local market identity, ingredient weight, edible fraction, allergen absence or cooking retention. USDA and OFF licenses stay separate.

## Apply through the single state owner

```dart
final references = RecipeReferenceRepository(); // lazy bundled asset + USDA reader
final revision = await kitchen.recipeForMeal(planId);
final proposals = await references.reviewFor(revision);
// Present candidate descriptions/forms/issues. Blocked entries cannot be selected.
final result = await kitchen.applyRecipeReferences(
  planId, references,
  acknowledgeGenericReferences: acceptedGenericEstimates,
  choices: chosenFoodIds, // Map<int,String>: recipe line -> explicit USDA ID
);
final applied = result.appliedLines;
final kept = result.preservedLines;
```

`acknowledgeGenericReferences` must be true. A single unambiguous recommendation can be saved only after that acceptance. Ambiguous entries remain unbound until a valid explicit choice; unrelated choices, duplicate review entries, blocked compounds, stale recipe snapshots and changed food source descriptions/versions fail. Candidate lists are not popularity rankings.

Application saves all resolved lines atomically to the exact planned revision. User bindings are preserved unless `replaceExisting:true` is explicitly supplied. `resolution` contains proposals/issues, not proof that every proposal was saved: inspect applied/preserved lines, then preview from KitchenService. Save failure publishes no state. If the plan is replaced or cooked during loading, application fails. Legacy unpinned plans must first be saved with `plan(...)` to pin their resolved revision. Completed cooking history is frozen.

Selections persist `referenceReviewId` and `referenceEvidence` alongside the source food snapshot. No source data is copied into person profiles wholesale. Failed asset reads can be retried. Sources are loaded only as needed; the reference artifact is not a merged retail database.

## Two distinct estimates

```dart
final inputs = await kitchen.previewIngredientNutrition(
  planId,
  measuredLines: measuredEdibleInputs, // Map<int,FoodAmount>, actual selected quantities
  optionalLines: selectedOptionalLines,
);
assert(inputs.basis == 'ingredientInput' && inputs.estimated);
final protein = inputs.whole[NutrientId.protein]!;
final completeInputValue = protein.value; // null if any selected required input is unknown
final partialKnownValue = protein.knownSubtotal; // label as partial, never total meal nutrition
final gaps = protein.missing;
final prepared = await kitchen.previewNutrition(planId);
```

The input wrapper is deliberately not a `RecipeNutritionResult` or `MealBatch`; it cannot be passed to `nutritionMealBatch`. It has whole/perPortion values and per-nutrient gaps, but no invented cooked per100g or person intake. It removes cooking transforms for input-only assessment while preserving quantity form; a cooked weight cannot be reinterpreted as raw weight. Missing conversions, missing nutrients and unknown basis remain gaps. A complete input value remains an estimate of ingredients, not measured cooked composition.

`previewNutrition` and `confirmCooking` retain conservative preparation rules. Raw/asSold to cooked requires explicit sourced preparation evidence; no universal retention=1. Actual cooking freezes its own result from actual choices/measurements and deducts stock once. Preview does not deduct stock, modify money/history or record personal intake. Display only the approved primary5 via `primaryDisplayNutrients`; retain all49 internally.

## Bechamel review gaps

- Dry pasta: enriched/unenriched choice; drained boiling/rinsing losses unknown.
- Minced meat: species and fat percentage require explicit selection.
- Onion: raw generic reference accepted only as a proposal; medium count needs measured edible grams or independently reviewed conversion.
- Butter/ghee: dairy/vegetable form and total allocation between roux, sauteing and tray grease need review.
- Flour and milk: type, enrichment/fortification and fat level; spoon/cup weights unknown.
- Cheese: mozzarella candidates exist; no exact Roumy reference was identified and none is silently substituted.
- Nutmeg/tomato: optional inclusion explicit; paste versus sauce and quantities need review.
- Salt and pepper are components of one compound line, not alternatives. Split them into separately measured lines in a new recipe revision and review/bind that new snapshot, or add an explicit multi-component model later. Do not bind the whole line to salt alone.

Accordingly, accepting references improves the known subtotal, but a full bechamel nutrient value stays null until the remaining identities/measurements/preparation gaps are resolved. Confirmed values and actual intake must not be inferred from coverage counts.

## Maintaining review evidence

1. Review changed recipe source and candidate evidence; preserve unknowns and explicit blocked/choice flags.
2. Run `node --test tool/nutrition/reference-review.test.mjs`. The guard checks canonical-LF recipe and USDA index hashes, source lines/quantity/unit/optional fields and exact USDA identities/basis. Changed preparation steps also change the whole-file source hash.
3. Run `dart run tool/nutrition/stamp_reference_review.dart` from the app root, with Node onPATH. The stamper runs the read-only source guard before writing runtime fingerprints; it cannot silently bless an old review against new source bytes. Fingerprints are content identifiers, not security signatures.
4. Run Flutter integration tests. All197 proposals must match full current typed snapshots. Refreshing review evidence requires actual review, not simply replacing a hash to make a test pass.

Primary methodology: [FAO recipe procedures](https://www.fao.org/4/y4705e/y4705e23.htm) distinguish raw inputs from cooked composition using yield/retention and losses. [USDA retention factors](https://www.ars.usda.gov/ARSUserFiles/80400530/pdf/retn06.pdf) are food/method/nutrient specific, not a universal preservation guarantee. USDA source identity/provenance references are recorded inside the artifact.

Next work: measured/sourced household measures and preparation evidence, broader candidate coverage with explicit review, label-basis validation, then external UI integration. No UI redesign, audio, image generation, Firebase/Auth/rules/billing, APK, Hosting or Drive change in this delivery.
