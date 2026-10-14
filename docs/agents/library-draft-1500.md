# Library-to-private-draft review bridge — 14 October 2026

- Sole checkout E:\work\SOFRA\app; coordinator-supplied base0fcfffd. Actual usage before work3primary/16weekly, ordinary=true. No new network/source acquisition.
- Scope/ownership: only new lib/domain/recipe_library_draft.dart and test/recipe_library_draft_test.dart plus this handoff/status. Root owns KitchenService, shared docs, persistence integration, finalization guard, Git and full gate.
- Objective: connect readable library recipes to existing private ingredient/cooked calculators after explicit per-line review, preserving full source evidence and unknowns. No automatic food identity, amount, unit conversion, metadata, scaling, planning or source approval.

## API

- recipeLibrarySourceFingerprint(RecipeLibraryEntry entry): canonical typed sorted-object JSON SHA256 over the recipe's complete dedicated evidence snapshot, including original row/upstream source envelope and scoped attribution/policy.
- RecipeLibraryLineDecision(input:RecipeFoodInput,scales:bool,overrideSourceExclusion:bool,name:String?): required caller-owned input/forms/amount/food/optional selection and explicit scaling. All line indices, including supplemental/excluded source ingredients, must be covered exactly once.
- RecipeLibraryDraftReview.create(entry,expectedSourceFingerprint,draftId,revision,createdAt,servings,decisions; optional name/cuisine/prepMinutes/cookMinutes/note). Name and unchanged instructions can copy known source text. Servings are mandatory caller input; cuisine/times default unknown, never guessed from source names/ranges. Food/amount are never copied automatically, even for known source quantities.
- Immutable .draft, .sourceFingerprint, .fingerprint, .libraryEntryId, deep-owned .sourceSnapshot, .toJson(), strict .fromJson(Map), .assertSource(entry,{expectedFingerprint}).
- Whole persisted envelope keys schemaVersion/source/sourceFingerprint/draft/decisions/fingerprint. Decision records contain ordered line index+source-exclusion override; exact personal line identities, forms, food/quantity/optional flags/scaling remain in draft.lines. Full source and review fingerprints validate separately. Strict PersonalRecipeDraft decoder validates the draft. fromJson also checks source line count/order and unchanged instructions, source exclusion decisions and envelope fingerprints. Canonical fingerprints survive object-key reordering, retain list order and explicit nulls.

## Decisions and limits

- included:false source alternatives cannot become selected without explicit applicable override. Unused override flags reject. Exclusion itself is explicit through optional=true/selected=false RecipeFoodInput; no line silently disappears.
- Source snapshot retains full sourceRecord, sourceSnapshot, source URLs/cuisine evidence/family/method proposals, unknowns/gates/rights and yield/time ranges. Pack context keeps source policy, source/review/batch/retrieval/change-notice/limitations fields and only matching creator attribution. Unrelated videos, other creators, counts and family proposals are not duplicated into every draft.
- Existing PersonalRecipeDraft/RecipeFoodInput ownership and nutrient-gap rules remain authoritative. PreviewIngredients/previewCooked work from the explicitly supplied draft. No new persisted state write, publication, inventory, intake, Firebase, UI or clinical rule is introduced here.
- This checksum is a local consistency guard, not source permission or independent nutrient approval. Root will persist the entire envelope alongside the exact draft and block library-origin authoring publication pending a separate source/rights approval path. Do not save only .draft and discard the source review.

## Actual verification

- Observed core bridge failure at UnimplementedError before implementation.
-7focused Flutter tests passed, including actual24pinned library assets and the creator maqluba's unknown yield/cookTime/reuseRights and source cup quantities; no automatic food/amount bindings.
- Other cases: explicit food/quantity input through existing protein calculator and serving scaling; unknown metadata/quantities preserved; exact all-line review coverage; excluded alternatives and applicable overrides; full-source drift with same ID; caller mutation/deep-owned envelope; canonical roundtrip/object-key reorder; source/draft/decision/fingerprint corruption; matching creator/policy context without unrelated records.
- Final focused analyze of the2newsource/test files clean3.4s. No full Flutter gate, commit or push by this helper.
- Next: root reviews and atomically integrates complete librarySource envelope with draft persistence/reload/idempotent retries; blocks premature publication; runs integration/full gate and consolidates delivery docs/Git. Ownership returned to root; no further helper edits planned.
