# Independent review — recipe yield acceptance — 2026-10-22

## Finding

**[P2] The explicit whole-recipe yield acknowledgement is bypassable and is not persisted.** The supported builder gates on `acknowledgeWholeRecipeYield` (`lib/domain/recipe_variants.dart:310-325`), and `KitchenService.reviewRecipeYield` requires and forwards the flag (`lib/data/kitchen_service.dart:613-634`). However, the persisted `RecipeYieldReview` type has a public constructor with no acknowledgement field and its schema/serializer omit that field (`lib/domain/recipe_yield_review.dart:2-30,32-57`). `RecipeRevision` accepts any matching `yieldReview` on a personal revision (`lib/domain/recipe_variants.dart:386-395`), while `RecipeBook` validates source fingerprint and exact recipe content but never the acknowledgement (`lib/domain/recipe_variants.dart:601-620`). The public `KitchenService.saveRecipeRevision` accepts such a personal revision and persists it (`lib/data/kitchen_service.dart:591-608`). A caller can therefore construct matching yield evidence directly and save it without ever setting the acknowledgement; after reload, there is no durable field proving the required acknowledgement occurred.

Persist the required acknowledgement in `RecipeYieldReview` and reject false/missing evidence during construction and deserialization, or make the review constructible only through a gated factory with an equivalently enforced serialized proof. Add a persistence test that attempts direct construction and reload with the acknowledgement absent/false.

## Review scope

Inspected `recipe_yield_review.dart`, the yield branches and book validation in `recipe_variants.dart`, `KitchenService.reviewRecipeYield` / `saveRecipeRevision`, and `test/recipe_yield_review_test.dart`. No Flutter commands, network calls, or source edits were made. No second concrete issue found in the inspected integrity, pinning, retry, and write-serialization paths.

## Coordinator resolution

P2 closed: persisted required acknowledgeWholeRecipeYield=true in constructor/schema, false/missing rejected by decoding and generic save/reload. Added direct tamper regression; all8yield tests passed in the final full suite. Original finding above is historical.
