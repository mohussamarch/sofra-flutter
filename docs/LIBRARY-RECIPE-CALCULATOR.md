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

## Current inputs and source triage — §76

The earlier44-record/7-pack counts above are historical. Current selected library63 records/10 packs/44 source snapshots. `RecipeLibraryCoverageReport` offers source-only indexed triage with `recipeLibrarySourceFingerprint`, raw quantities and optional/excluded/procedural flags; it does not inspect saved decisions, supply a gram conversion, or accept a FoodRecord. Every-line explicit `RecipeLibraryLineDecision` and all source/publication guards above still apply. RECIPE-LIBRARY-COVERAGE.md explains the counters and limits.

## Recipe-scoped source request evidence — §77

Current library65 records/11 packs/44 snapshots. Source extraction can include a pack sourceIndex table and a row sourceEvidence.sourceIndex reference. The private review envelope now retains only requests whose exact URL belongs to that entry, preserving original index/request values and both indexed extraction and failed direct access outcomes. Look up by each stored index field, not the subset list position; indexes are not renumbered. Other recipe/listing/video requests are omitted.

Explicit tables must retain the row's referenced index; malformed/duplicate indexes, invalid request ordinals or unrelated URLs reject before new review creation and during fromJson. The source request subset contributes to the existing source fingerprint. Legacy envelopes without the table still decode; an enriched current source requires explicit re-review rather than silently refreshing the old pin. No body hash or source/authentication/rights approval is invented. The actual two new records are worker-acquired indexed official website extracts; direct opening one recipe returned a relaunch page. Full body archive and channel identity remain unknown.

## Current §79 — food search for a pinned ingredient

Current66records/12packs/44snapshots. Create RecipeLibraryFoodSearch with existing FoodRepository, supply an entry, its expectedsourceFingerprint, lineIndex and explicitnonemptyquery. Result carries owned food search candidates plus original ingredient/source pin; duplicate ingredient names remain separate. Use selected IDs through existing food readers and explicit line decisions. Choosing a result does not establish recipe identity, accepted conversion, food form, local SKU or source rights; saveLibraryRecipeDraft checks current source as before. Market filters packaged rows only; USDA is generic. No saved user state is written by search. Truecreator-youtube row sourceVideoId/URL/description access evidence survives private review/roundtrip; legacy omitted website derivation remains readable, explicit conflict rejects. See BACKEND-API.md andHANDOFF§79.

## Current §80 — selected identity before line decisions

Currentlibrary70/13packs/48snapshots. resolveUsdaCandidate returnsauser-selectedgenericFoodRecordafterpin/resultmembership/ack/form/index-vs-rawname-versionchecks. It suppliesnoamountoracceptedrecipebinding; callerstillcovers everylineexplicitly,thenexistingatomicprivate-draftsave verifiescurrentlibrary. Currententryisprovidedbycallerandbankreaderscacheassets;dataversionconflictsrequireconsistentcurrentbankreload/review. LIBRARY-FOOD-SELECTION.md gives fullcontract. No automaticcompoundingredient or householdmeasure conversion. Actualsourceaudit642of722quantitygaps/0runtimeapprovals.

## Current §81 — source-scoped package choice

Current78 entries/14packs/56snapshots. Food search can now resolve an explicitly chosen package after source pin, market and whole-row consistency checks. Optional label basis evidence must name the chosen barcode; unknown basis remains a calculation gap. This returns a FoodRecord, followed by the same explicit per-line quantity/form/inclusion/scaling decisions and complete atomic private-review save. Source quantity audit715/797 is source-only and never saved-user review completion. LIBRARY-FOOD-SELECTION.md defines both generic and packaged branches.


## Current §82

RecipeLibraryMassProposal.fromSource requires full source fingerprint, exact line and explicit acknowledgement of an existing positive numeric g/kg declaration. It preserves amount/unit/raw text without parsing or conversion. toDecision rechecks current recipe/source and applicable exclusion override; food/forms/inclusion/scaling/as-purchased/preparation remain explicit and quantityEstimated is always true. No measurement, food match, source approval or state write. Contract docs/LIBRARY-SOURCE-MASS.md. 84 readable source records =62 offline archive +21 creator website +1 indexed video description;15 pinned packs/62 snapshots,51 local source cuisine/region labels. Planning54/4 and reviewed method family1 unchanged;0 new runtime/nutrition approvals. Final258Flutter/27relatedNode/analyze clean; earlier counts are historical.
