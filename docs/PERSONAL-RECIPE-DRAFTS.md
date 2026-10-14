# Personal recipes from scratch: draft calculator and persistence

This backend API creates user-owned drafts without a CatalogRecipe parent.
It does not introduce an authoring screen or a new APK/cloud migration.

## Structure

`PersonalRecipeDraft` owns id/revision/name/servings/UTC creation time, immutable
`PersonalRecipeLine` inputs, optional cuisine/preparation and cooking minutes,
instructions and note. Missing cuisine/time stays null; unknown food/quantity
stays unknown. It is valid to save a draft before all ingredients are identified.
Each line has a stable unique id, display name, explicit `RecipeFoodInput` and
whether its amount scales with the serving count. Repeated foods can have
different line IDs. Required/optional/selected/form/quantity-estimate fields
remain explicit. No amount or food identity is inferred from the line name.

Ingredient food snapshots retain version, sources, nutrient units and confidence.
The draft owns serialized copies, validates complete typed JSON on reload, and
uses a local SHA256 fingerprint with sorted object keys; array order remains
significant. This is a local consistency identifier, not scientific approval or
an upstream source signature.

## Saving and reading

```dart
await kitchen.savePersonalRecipeDraft(
  draft,
  acknowledgeInputsReviewed: true,
  reviewNote: inputReview,
  reviewedAt: DateTime.now().toUtc(),
  expectedActiveKey: previousActiveKey, // null only for a new identity
);
final saved = kitchen.personalRecipeDraft(draft.id);
final old = kitchen.personalRecipeDraft(draft.id, revisionKey: oldRevisionKey);
```

State namespace `personalRecipeDrafts` contains version1, immutable revisions
and active pointers. Review acknowledgement records what the caller checked;
it does not certify ingredients or health suitability. A changed recipe uses a
new revision and the exact expected active key. Same-key conflicting data
rejects. Replaying an identical older save does not reactivate the old version.
Save failure, a stale concurrent revision or the850KBstate guard rolls back.
Legacy state without this namespace remains readable.

## Nutrition

```dart
final beforeCooking = kitchen.previewPersonalRecipeIngredients(
  draft.id, servings: requestedServings,
);
final conservativeCooked = kitchen.previewPersonalRecipeCooked(
  draft.id, servings: requestedServings,
  cookedYieldGrams: measuredCookedWeight,
);
```

Both APIs call the existing49nutrient calculator. Line quantities scale only
where explicitly allowed; optional selection and unknown coverage are retained.
Input preview removes cooking transforms and keeps the actual quantity form.
Cooked preview uses explicit preparation evidence and leaves missing factors
unknown. An unknown nutrient is not zero. Source quantity and preparation
confidence are preserved; an ingredient total is not a certified cooked result.

An accepted category preparation scoped to a different registered recipe cannot
be copied into a new draft. A draft-specific acceptance flow remains future work.
The existing generic/manual transform API does not become an approved coefficient
bank through this feature.

## Remaining work

Drafts are not automatically registered in the shipping recipe book, meal plans,
stock deductions, prices or person intake. Finalizing a complete reviewed draft
into an immutable plannable recipe needs an explicit bridge that handles missing
CatalogRecipe times/cuisine/steps and carries its food bindings and provenance.
Do not invent zeros or fake parents to cross that boundary. The original54recipes
and research source banks are unchanged. UI design, Firebase, audio and APK
integration remain outside this unit.
