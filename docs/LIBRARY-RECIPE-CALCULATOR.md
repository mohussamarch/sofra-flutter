# Library recipes → private calculation drafts

Sole checkout: `E:\work\SOFRA\app`. Current implementation: HANDOFF §72. This bridge makes a readable source recipe usable by the existing calculation engine after explicit review. It does not declare the recipe nutritionally complete or approved for publication.

## Data flow and ownership

`RecipeLibraryRepository` → exact `RecipeLibraryEntry` → `RecipeLibraryDraftReview` → atomic `KitchenService.saveLibraryRecipeDraft` → `PersonalRecipeDraft.previewIngredients/previewCooked`.

The selected library now contains44 records from7 byte-pinned packs and28 upstream snapshots. Keep the full review envelope, not only its `.draft`. It contains schemaVersion, source, sourceFingerprint, draft, decisions and fingerprint. The source includes the complete selected source record, upstream snapshot where present, evidence URLs and relevant pack policy/creator attribution; unrelated recipes/videos/creators are excluded.

## Explicit decisions

- Every ingredient index must have exactly one `RecipeLibraryLineDecision`, including optional, supplemental and source-excluded alternatives. No source line silently disappears.
- Supply `RecipeFoodInput` with the reviewed identity, form, amount and inclusion choices. Supply scaling and any applicable source-exclusion override explicitly. Unknown food/quantity stays unknown; source text is not an automatic gram or food-ID mapping.
- Caller supplies servings. Cuisine/preparation/cooking metadata remain null unless explicitly supplied. Instructions retain their source order/text; time ranges and contradictory metadata stay in source evidence.
- `recipeLibrarySourceFingerprint(entry)` and review fingerprint pin local consistency. They are not source, rights or scientific approval.

## Calling code

```dart
final entry = (await library.all()).first;
// reviewedLines is Map<int, RecipeLibraryLineDecision>, covering every line.
final review = RecipeLibraryDraftReview.create(
  entry: entry,
  expectedSourceFingerprint: recipeLibrarySourceFingerprint(entry),
  draftId: draftId,
  revision: revision,
  createdAt: reviewedAt,
  servings: reviewedServings,
  decisions: reviewedLines,
);
await kitchen.saveLibraryRecipeDraft(
  review,
  library: library,
  acknowledgeInputsReviewed: true,
  reviewNote: reviewNote,
  reviewedAt: reviewedAt,
  expectedActiveKey: expectedActiveKey,
);
final result = review.draft.previewIngredients();
final savedEvidence = kitchen.libraryRecipeDraftReview(draftId);
```

Identifiers, review note, servings, times and line decisions come from the caller's review; the example does not supply fictitious source values. For cooked estimates, use the existing `previewCooked` contract and exact preparation evidence rather than a universal cooking multiplier. User display remains the approved5 nutrients; all49 can remain stored with coverage/unknowns.

## Persistence and publication

KitchenService clones the submitted review before awaiting, resolves its current library entry and checks full source consistency. It stores `librarySource` alongside the identical draft in one existing atomic write. Reload checks both envelopes and correspondence; failed persistence/850KB limit rolls back source and draft together. Identical older retries do not reactivate old revisions, and a generic authoring save cannot drop a draft's library origin.

`finalizePersonalRecipe` rejects library-origin drafts: the private calculator bridge cannot bypass the separate reviewed source-import/rights contract. From-scratch personal drafts retain their existing publication path. No stock, plan, intake, history or source approval is created by saving/calculating this draft. A caller must preserve provenance through this API rather than copying source content into a nominally from-scratch draft.

## Actual verification and next work

8 domain bridge tests and7 persistence/integration tests cover all-line decisions, excluded choices, source drift, owned snapshots, canonical roundtrip, malformed/tampered provenance, calculator use, stale retry, rollback and publication/origin guards. They are included in the full225 passing Flutter tests; full analyze clean7.2s. Synthetic food/protein values in tests are not approved real recipe bindings. Independent read-only review found no concrete must-fix.

Next: the external interface can consume these APIs and show review/status/coverage explicitly. Review real food identity/amount/form, source omissions and rights before promoting any library recipe into planning. UI activation and actual user/cloud state were not changed.

## Singular creator provenance fix — §72

Pack attribution can use either `creator` or `creators`. The bridge now collects only entries whose creatorId exactly matches the selected recipe and preserves them in the scoped creators list, removing exact canonical duplicates while retaining different evidence. Regression reproduced missing metadata before the fix and passed afterward. Old serialized envelopes are still decoded as stored; newly enriched source fingerprints can require review before assertSource/save against the current entry. No historical envelope is rewritten and no source/rights approval is implied.
