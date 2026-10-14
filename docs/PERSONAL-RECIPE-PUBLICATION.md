# Publishing a personal draft for planning and cooking

Internal backend API; no UI, Firebase migration or new APK was enabled.
Start with [PERSONAL-RECIPE-DRAFTS.md](PERSONAL-RECIPE-DRAFTS.md).

## Explicit review

`PersonalRecipeFinalization` freezes the entire saved draft, category,
description, difficulty, one explicit duration per instruction, inventory
ingredient IDs per stable draft line, review note/time and two acknowledgements:
instructions/inputs reviewed and nutrition may be incomplete.

Draft cuisine, preparation/cooking times, instructions and whole serving count
must be present. Missing metadata is rejected; no fake parent or zero is added.
An explicitly entered zero duration remains valid. Ingredient IDs are chosen by
the caller, never inferred from food names, barcodes or nutrient-source IDs.

Unknown food stays unbound. Unknown quantity can publish only when its line
does not scale; existing cooking confirmation requires actual use or explicit
omission. Generic quantityEstimated inputs cannot publish because the current
recipe selection format cannot preserve that quantity evidence. They remain
usable in the draft calculator until a separate reviewed representation exists.
Accepted category preparation scoped to another recipe also requires fresh
review. These inputs are rejected, never silently upgraded.

Scalable base quantities must survive existing CatalogRecipe rounding unchanged;
for example .001g cannot silently become zero. Fixed non-scaling .001g is valid.
Changing servings uses the existing catalog rounding rules. Review the published
amounts; input drafts retain their exact original quantities and forms.

## Publication

```dart
final review = PersonalRecipeFinalization(
  draft: savedDraft,
  category: category,
  description: description,
  difficulty: difficulty,
  stepMinutes: explicitMinutes,
  ingredientIds: explicitInventoryIdsByDraftLine,
  reviewNote: note,
  reviewedAt: DateTime.now().toUtc(),
  acknowledgeInstructionsAndInputs: true,
  acknowledgeNutritionIncomplete: true,
);
final revision = await kitchen.finalizePersonalRecipe(
  review,
  expectedActiveRecipeKey: previousPublishedKey, // null for first publication
);
```

The source draft must be saved, active and unchanged. Recipe identity is derived
from draft identity; revision identity is a SHA256 of the complete typed review.
Full evidence serializes with sorted object keys, preserving array order. These
are consistency identifiers, not source authentication or scientific approval.

Publication atomically saves the new `authored` root, family, full review and
explicit revision/line food selections. It has no parent. Stale active draft or
recipe, storage failure and the850KBstate guard roll back the whole write.
Generic saveRecipeRevision cannot bypass this publication path. An identical
old retry never reactivates an old version or rewrites later food reviews.

## Existing planning and cooking

Use the returned revision ID/key with the existing plan API. Existing input and
cooked previews, stock/cost checks and once-only confirmCooking now apply.
Food snapshots keep versions, sources, forms and preparation gaps. Future
versions do not alter old plans, history or food bindings. Optional ingredients
are still selected explicitly for each meal; draft selection is retained in the
review snapshot, not imposed on future meals. No person intake event is added.

Legacy state remains readable. Older clients cannot read kind=authored; require
a compatible client before shared writes or UI activation. Unknown nutrition is
not zero and a reviewed recipe is not a certified health recommendation.

Keep the original review object across retries; changing its timestamp or note changes the revision identity.
