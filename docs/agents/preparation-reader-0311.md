# Preparation category reader handoff — 2026-10-14

- Sole checkout: E:\work\SOFRA\app. Owner: prep_category_reader_0311; coordinator owns shared docs, KitchenService, domain, Git and integration.
- Objective: bounded explicit category-estimate acceptance for exact USDA168927/2018-04/generic/asSold, without new factors, scientific approval, or automatic application.
- Files: lib/data/preparation_category_repository.dart; test/preparation_category_repository_test.dart; this handoff and preparation-reader-0311.status.md. No source banks edited.

## Contract

- PreparationCategoryRepository({FoodAssetReader? read}).
- Future<List<String>> methods(FoodRecord food) returns immutable [0381,0382] after validating exact canonical food and local evidence. Unsupported food throws ArgumentError, invalid source evidence FormatException; failed load remains retryable.
- Future<PreparationTransform> accept(FoodRecord food,{required String retentionCode,required String reviewNote,required DateTime acceptedAt,required bool acknowledgeCategoryEstimate,required bool acknowledgeUnknownLicense}).
- Static bool isCategoryEstimate(PreparationTransform transform) recognizes evidence kind OR reserved ID prefix accepted-category-preparation-estimate:; removing kind alone cannot bypass the coordinator's validation gate.
- Static void validateAccepted(FoodRecord food,PreparationTransform transform) performs synchronous validation from the complete frozen envelope; rejects inconsistent evidence with FormatException. Extra root recipeId/recipeRevisionKey/line keys permitted; KitchenService owns exact recipe/line scope validation.
- Accepted transform ID: accepted-category-preparation-estimate:${food.key}:$retentionCode. Only asSold to cooked; estimated=true, massYield=null; three vitamin factors. 0381 gives C/thiamin/riboflavin 0.7/0.65/0.75; 0382 gives 0.6/0.55/0.75. Choose one method, no layering.

## Evidence and validation

- Exact canonical source food is reloaded through the same reader with FoodRepository.usdaFood('usda:168927',form:'asSold',nameAr:food.nameAr). Pinned full FoodRecord serialization excluding localized nameAr also protects saved validation from coordinated food/envelope edits. Branded/cooked/raw/other IDs, versions, values, sources and basis are rejected.
- Actual whole shard hash algorithm is preserved explicitly: UTF8 text of entire data/usda/shards/31.json, replace CRLF with LF only, no trimming or JSON reserialization; SHA256 7c425a180d54ba1a2d999f382823697cfc40d7d823c3f20689a0add494b9f81d. Stored in foodSourceFingerprint with algorithm sha256-utf8-entire-file-crlf-to-lf.
- Frozen review and retention-source metadata carry pinned canonical local SHA256 values; canonical encoding sorts map keys recursively, preserves array order, converts numbers to doubles, and JSON encodes. Review pin 8a32d8e120f96ae3bc8fe3bc9cc9c25e29856f408943ce20ef9b5b229dda13a1; source metadata 76b9bc8be7dad915935dc8d6afb85a67ff4672b82453726c830326604a66160c; food 1e5fc6d4480d23e17aa9a69a6e74b393df3c32ed6f1e7055bea35bf00d40558e. Pins derived from actual current fixtures, not invented source values.
- Both reviewed method sets crosschecked against retention-candidates: exact source archive SHA, 3 rows each, candidate IDs, nutrient mapping, source lines/hashes, percentages/fractions/units/group/method/date, unmapped status, empty foodIds and null yield/fraction.
- evidence kind accepted-category-preparation-estimate/schemaVersion1 contains full food, review, retentionSource, sourceCandidates, requiredActualMethod, selected code, retention, missingNutrients46, massYield/edibleFraction null, licenseStatus unknown, and runtimeTransformApproved/exactFoodMatchVerified/supportsFinishedRecipe/sourceSpecificLegalApproval false.
- acceptance holds caller date normalized to UTC, trimmed nonempty note and both true acknowledgements. Saved validation checks these along with source/forms/ID/factors/unknowns/food snapshot/review and row consistency.
- Local consistency pins are not upstream signatures, independent scientific approval, legal permission, or proof of actual cooking. A caller must explicitly select the matching actual method and acknowledge uncertainty. Remaining46nutrients, cooked mass and edible fraction remain unknown. No finished bechamel/full recipe or clinical claim.

## Verification actually run

- First test run failed because the repository did not exist. API-only stubs then produced behavioral RED: all6tests failed with UnimplementedError, proving missing behavior.
- After implementation: flutter.bat test --no-pub test/preparation_category_repository_test.dart exit0, 6/6passed, elapsed5.76s.
- Coverage: both methods and exact factors; UTC/frozen roundtrip/46unknowns; canonical-food/form/brand/nutrient mismatch; explicit acknowledgements/note/singlecode; review/source/row/factor/approval drift and retry; CRLF normalization versus whole-shard drift; frozen transform/evidence tampering including jointly changed food; permitted coordinator scope extras.
- dart.bat format ran only both owned Dart files. A brace-only guard cleanup followed; coordinator final integration/analyze/full gate will verify final formatted files. No full suite or analyze independently run by this agent to avoid concurrent Flutter startup lock.
- SDK: C:\Users\atgs0\Documents\Codex\2026-10-09\cooking-app-flutter\work\flutter_sdk\bin\flutter.bat; --no-pub used cached dependencies. E writes and Flutter launches used scoped approved escalation.
- No network/source acquisition, commits, Firebase/UI/APK/Drive/device changes. No preview process inspected or altered by this agent.

## Next action

Coordinator integrates exact revision/line evidence scope, validates recognized transforms on save/read/confirmation, adds separate cooking acknowledgement, runs required integration/full gates, consolidates shared handoff and commits/pushes. Research approval, broader food/method coverage, yield and reuse terms remain open. Agent edits complete; Git delivery is coordinator-owned.

