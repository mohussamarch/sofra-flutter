# Nutrition core agent handoff

- Canonical checkout: `E:\work\SOFRA\app`; coordinator owns commit/push and shared handoff.
- Owned files: `lib/domain/food_nutrition.dart`, `test/food_nutrition_test.dart`.
- Added immutable versioned generic/exact packaged food models, source/license/record provenance, GTIN checksum, market/form, package quantities, basis g/ml/serving/unknown, explicit measured conversions, compound refs and evidence-backed allergen declarations. Forty-nine distinct nutrient IDs use fixed units; vitamin A/RAE, folate/DFE and sodium/salt are never silently interchanged.
- `calculateRecipeNutrition` requires recipe ID/version, selected inputs and portions; returns whole/perPortion and optional per100g only when final yield supplied. Each nutrient has knownSubtotal, complete/value, explicit ingredient gaps and estimated flag. Missing is never zero; bounds/trace are not exact values. Sources and exclusions survive JSON roundtrip snapshots.
- `RecipeFoodInput` explicitly states amountForm and preparedForm. Cross-form calculations require matching preparation facts; mass yield converts prepared weight back to source weight but does not scale nutrient totals. Each retention fraction is separately required. Unknown density/count weights/edible fractions are gaps. Raw sums are explicitly raw and cannot be labeled measured cooked nutrition.
- Allergen absent means unknown; nested contains/mayContain propagate, cycles/missing components stay unknown. Only explicit evidenced freeFrom declaration establishes that statement for a product; free component statements do not prove lack of cross-contact.
- Checks actually run: 12 focused Flutter tests passed; dart format applied; focused dart analyze reports no issues after correcting brace style. No UI, Firebase, assets, APK, server or shared docs touched.
- Integration contract sent to coordinator and people agent. Coordinator should adapt USDA/OFF records and canonical recipe bindings, bridge reports to people snapshots, and run the combined suite. OFF ambiguous 100g/100ml basis must remain `unknown` until label review. Source retrieval/license does not itself verify nutritional accuracy or redistribution permission.
- Limit: this is arithmetic/data infrastructure. No invented food facts, dietary prescriptions, per-person targets or automatic clinical advice. Prepared yield and retention need source facts or explicitly user-supplied records. No new commits from this agent.

## Coordinator-requested review

- Canonical allergen aliases added for exact OFF/English vocabulary (egg/eggs, soy/soybeans, peanut, treeNuts, sesame and others). Declaration evidence retains original tag. Unknown/custom IDs remain exact; wheat and gluten are distinct; no individual nut/family inference. Duplicate aliases on one food now reject rather than conflicting silently; adapters should coalesce canonical IDs with contains precedence.
- Compound lookup verifies the referenced food/version matches the catalog record key. No source or scientific nutrient map changes in core.
- Read-only root review reported corrupt source unit handling, recipe version fingerprinting, canonical allergen coalescing and explicit nonconsumed exclusions to coordinator. Coordinator owns those integration fixes.
- Review verification: 14 focused tests passed after the two new cases; formatting applied. Focused Dart analysis result is reported to coordinator separately.

## Carbohydrate definition review

- Registry now has **49** IDs: `carbohydrate` for unspecified label definition, `carbohydrateByDifference` and `availableCarbohydrate` remain separate. No implicit merging, fibre subtraction, net-carbohydrate derivation or shared target assumption.
- USDA Foundation documentation confirms by-difference includes dietary fibre and source/label methods differ: https://fdc.nal.usda.gov/Foundation_Foods_Documentation/ . Coordinator owns USDA1005 adapter mapping to byDifference and keeping OFF generic until definition review.
- Final focused result: 15 nutrition core tests passed after the carbohydrate-definition split. Previous focused analysis after alias review was clean; coordinator runs the combined final gate.
