# Native reviewed source recipe import

The backend now reads a verified structural candidate and explicitly registers an immutable source-derived recipe through KitchenService. No UI entry, source-bank promotion or automatic nutrition binding is enabled. Real source review coverage remains open; shipped54recipes unchanged.

## Pipeline and API

1. Use authoritative source/raw-food readers and registered draft files. Resolve explicit draft decisions/metadata; unknown time/servings/quantities block adaptation.
2. buildRuntimeRecipeCandidate + validateRuntimeRecipeCandidate rebuild against current source/draft/metadata/raw-food snapshots. packRuntimeRecipeCandidate then emits schemaVersion1/encoding=utf8-json/payload/exact UTF8 SHA256.
3. Native reader requires expectedSha256 from the caller's trusted artifact reference. Do not treat an unverified wrapper's own sha256 field as an independent trusted reference. Exact payload text is hashed using cached crypto3.0.7; Dart does not reserialize JS numbers to reconstruct opaque upstream fingerprints.
4. Explicitly review source licence/page exceptions, instructions/choices/quantities and canonical ingredient IDs, and acknowledge unreviewed nutrition. Then register the selected candidate through the single state owner.

```dart
final candidate = ImportedRecipeCandidate.fromTransport(
  transport,
  expectedSha256: verifiedArtifactSha256,
);
final revision = await kitchen.importSourceRecipe(
  candidate: candidate,
  reviewNote: sourceLicenseAndInstructionsReviewNote,
  reviewedAt: reviewTime,
  acknowledgeSourceLicenseAndInstructions: true,
  acknowledgeNutritionUnreviewed: true,
);
// Plan by revision.variantId; KitchenService pins the exact immutable revision.
```

Importing is caller review evidence, not scientific/authenticity/legal certification. Hashes are local consistency checks; the expected artifact reference is a trust boundary. Preserve original licence, attribution URL, page/revision IDs, source SHA/parser guards, change notice and every source-to-runtime line map. Source recipe ID contains the page identity; raw reader/index remains authoritative for that page. Never save only the naked recipe JSON.

## Native and persistence contracts

- ImportedRecipeCandidate validates exact transport/reference SHA, candidate/recipe/provenance shapes, source URLs/SHA/UTC notes, every source line and ordered complete runtime mapping, exclusion/split cardinality, raw-food reference SHA, boolean/quantity/time requirements, unapproved nutrition and all remaining gates.
- Catalog text that Dart would trim (IDs/names/cuisine/category/description/difficulty/instruction text) must already be normalized. Node and native reject padding; raw source/provenance notes, units, forms/tags/tips remain preserved as entered. This prevents reviewed identity changing during CatalogRecipe conversion.
- Owned original payload/provenance survive roundtrip; getters/toJson return copies and CatalogRecipe/gates are immutable. fromJson revalidates the stored transport.
- SourceRecipeImportReview stores full candidate, UTC date/note and explicit source/licence/instructions + unknown-nutrition acknowledgements. Family derives from structured sourceId/recipeId; revision derives from exact transport SHA. RecipeRevisionKind.imported is a root with no parent/region/method/split/choice evidence and must match the full candidate recipe and derived lineage exactly.
- importSourceRecipe clones/revalidates before awaiting, checks shipping identity collisions, then atomically adds family/revision through existing save/rollback/850KB guard. saveRecipeRevision cannot bypass explicit import review. Identical retries do not rewind newer active revisions; changed evidence for the same immutable key fails.
- Old plans/history/costs/inventory deductions stay pinned; importing alone does not consume stock, replan, create purchases, write intake or accept food/clinical rules. Existing books without sourceImportReview remain readable. Existing clients do not understand the new imported enum value: deploy a compatible client before enabling this API in a real UI/shared state. No user cloud state was changed here.
- Raw USDA refs are provenance only. Runtime FoodRecord/form/basis/measurement/retention need separate explicit review. saveRecipeFoodSelection binds a selected exact imported revision/line via the existing calculator. New imports inherit zero bindings; missing nutrients stay missing. Candidate runtimeReady=false remains the archived pipeline status, not a claim that nutrition became approved after registration.

## Verification

Final full142Flutter tests passed after the normalization fix; one additional named nutrition-binding integration test passed afterward (production code unchanged), analyzer clean.28native reader tests and7source import cases covered within these runs; previous full141 was superseded.46linked Node tests passed;5actual bank tests passed on final changed food bytes. No APK/new S24/Drive/Firebase changes.

Tests are synthetic/mocked: exact transport and metadata corruption, missing/implicit fields, sparse/malformed mappings, ownership, old-book reading, atomic save failure/retry/reload, review acknowledgements, immutable family/version/recipe guards, frozen old plans/history/deduction,850KB rollback, and explicit revision-only nutrition with incomplete coverage. No actual source-bank recipe was promoted or asserted nutritionally complete.

Reader worker used direct cached crypto3.0.7 via flutter pub get --offline; no online dependency fetch. Root review reproduced padded runtime IDs in both Node/native; regression failed before targeted normalization checks, then all gates passed. Independent review confirmed the fix; no remaining concrete must-fix.

Quantity/import infrastructure units are complete. Scientific recipe coverage stays open in recipe-coverage/source-bank/preparation tasks; infrastructure completion never means all records are approved. Next core priority is explicit preparation-evidence acceptance/acknowledgement, followed by private from-scratch authoring. Source collection remains a bounded helper lane.
