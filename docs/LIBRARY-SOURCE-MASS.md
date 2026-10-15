# Declared source mass to private recipe review

`RecipeLibraryMassProposal` in `lib/domain/recipe_library_draft.dart` helps callers reuse a reviewed numeric mass already declared in a pinned source. It does not parse quantities from free text.

## Proposal

Call `fromSource(entry, expectedSourceFingerprint, lineIndex, acknowledgeDeclaredSourceMass)` using named parameters. Acknowledgement must be true, the complete recipe source fingerprint must match, and the line must exist. Only a finite positive numeric `amount` with exactly `g` or `kg` is supported. The amount/unit stay as declared; raw source quantity text and line identity remain available through `ingredient`. Unknown values, ranges without a numeric amount, cups, counts, volumes and other units require separate explicit review. No density, edible fraction, serving scaling or cooking yield is inferred.

Acknowledgement means the caller has reviewed the numeric declaration against the source, including any contradictory notes or alternatives. A numeric field alone cannot settle those ambiguities. The proposal is not proof that anyone weighed that ingredient.

## Explicit decision

`toDecision` requires the caller's current entry, private ingredient ID, food (nullable), amount form, prepared form, optional/included choices, as-purchased choice, preparation (nullable), scaling choice and source-exclusion override. It checks the current full source pin again and preserves the existing applicable-only source exclusion override. No excluded alternative becomes selected automatically.

The returned `RecipeLibraryLineDecision` always has `input.quantityEstimated == true`. This confidence flag survives the existing `RecipeLibraryDraftReview` serialization and atomic private save. There is no setter or argument in this helper for claiming measured quantity. Actual weighing uses the separate explicit input path. Existing cooking/stock acknowledgement for estimated quantities remains required.

The helper does not save, bind to shared recipes, approve a food identity, create a plan/intake/stock deduction, publish content, resolve missing preparation evidence or approve nutrition/licensing. Saving the complete library review continues through KitchenService with its current source guard.

## Verification

Four focused tests cover g/kg preservation and estimated review roundtrip, unknown/unsupported/zero rejection (negative source values already rejected by the reader), stale pin/index/acknowledgement rejection and explicit applicable exclusion overrides. They pass with the ten existing source review tests (14/14). The first run failed on absent API; subsequent fixture failures were repaired by using a dynamic owned JSON map and respecting the existing negative-source reader validation, without relaxing production guards.
