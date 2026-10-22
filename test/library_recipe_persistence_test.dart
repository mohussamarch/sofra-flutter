// Full pinned 6,648-entry source-bank integration; repeated SHA/coverage work
// exceeds the default 30s on this machine. No integrity assertion is skipped.
@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/data/recipe_library_assets.dart';
import 'package:tabkha_demo/data/recipe_library_repository.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/recipe_library_draft.dart';
import 'package:tabkha_demo/domain/personal_recipe_finalization.dart';
import 'package:tabkha_demo/domain/personal_recipe_draft.dart';

import 'personal_recipe_draft_test.dart' as food;
import 'recipe_variants_test.dart' as fixtures;

// Reuse one verified immutable bundled snapshot across persistence scenarios.
final _bundled = bundledRecipeLibrary();

Future<RecipeLibraryDraftReview> reviewed({String revision = 'v1'}) async {
  final entry = (await _bundled.all()).singleWhere(
    (e) => e.id == 'curated-local:141667',
  );
  return RecipeLibraryDraftReview.create(
    entry: entry,
    expectedSourceFingerprint: recipeLibrarySourceFingerprint(entry),
    draftId: 'library-private',
    revision: revision,
    createdAt: DateTime.utc(2026, 10, 14),
    servings: 4,
    cuisine: 'synthetic test cuisine',
    prepMinutes: 1,
    cookMinutes: 0,
    decisions: {
      for (var i = 0; i < entry.ingredients.length; i++)
        i: RecipeLibraryLineDecision(
          input: RecipeFoodInput(
            ingredientId: 'explicit-$i',
            food: food.fixtureFood(),
            amount: FoodAmount(value: 100, unit: FoodQuantityUnit.g),
            amountForm: FoodForm.raw,
            preparedForm: FoodForm.raw,
          ),
          scales: true,
          overrideSourceExclusion: false,
        ),
    },
  );
}

Future<void> save(
  KitchenService k,
  RecipeLibraryDraftReview value, {
  String? expected,
  RecipeLibraryRepository? library,
}) => k.saveLibraryRecipeDraft(
  value,
  library: library ?? _bundled,
  acknowledgeInputsReviewed: true,
  reviewNote:
      'Synthetic explicit test review; no source or nutritional approval',
  reviewedAt: DateTime.utc(2026, 10, 14),
  expectedActiveKey: expected,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('real source becomes persisted private calculator draft with its full provenance', () async {
    final store = fixtures.Store(),
        k = KitchenService(fixtures.Store(), fixtures.repository());
    final service = KitchenService(store, fixtures.repository());
    await service.load();
    final r = await reviewed();
    await save(service, r);
    expect(
      service.libraryRecipeDraftReview(r.draft.id)!.fingerprint,
      r.fingerprint,
    );
    expect(
      service
          .previewPersonalRecipeIngredients(r.draft.id)
          .whole[NutrientId.protein]!
          .value,
      40,
    );
    expect(service.recipeBook.revisions, isEmpty);
    expect(service.snapshot['inventory'], isEmpty);
    expect(service.snapshot['plans'], isEmpty);
    await k.load();
    final reloaded = KitchenService(store, fixtures.repository());
    await reloaded.load();
    expect(reloaded.libraryRecipeDraftReview(r.draft.id)!.toJson(), r.toJson());
  });
  test(
    'failed save rolls back provenance and draft together, retry succeeds',
    () async {
      final store = fixtures.Store(),
          k = KitchenService(fixtures.Store(), fixtures.repository());
      final service = KitchenService(store, fixtures.repository());
      await service.load();
      final before = jsonEncode(service.snapshot), r = await reviewed();
      store.fail = true;
      await expectLater(save(service, r), throwsStateError);
      expect(jsonEncode(service.snapshot), before);
      expect(service.libraryRecipeDraftReview(r.draft.id), isNull);
      store.fail = false;
      await save(service, r);
      await k.load();
      expect(service.personalRecipeDrafts, hasLength(1));
    },
  );
  test('old identical retries never reactivate prior draft or replace its source review', () async {
    final k = KitchenService(fixtures.Store(), fixtures.repository());
    await k.load();
    final old = await reviewed(), newer = await reviewed(revision: 'v2');
    await save(k, old);
    await save(k, newer, expected: old.draft.key);
    await save(k, old);
    expect(k.personalRecipeDraft(old.draft.id)!.key, newer.draft.key);
    expect(
      k.libraryRecipeDraftReview(old.draft.id)!.fingerprint,
      newer.fingerprint,
    );
    expect(
      k
          .libraryRecipeDraftReview(old.draft.id, revisionKey: old.draft.key)!
          .fingerprint,
      old.fingerprint,
    );
  });
  test('unverified current library refuses before any state write', () async {
    final k = KitchenService(fixtures.Store(), fixtures.repository());
    await k.load();
    final before = jsonEncode(k.snapshot);
    await expectLater(
      save(
        k,
        await reviewed(),
        library: RecipeLibraryRepository(expectedManifestSha256: '0' * 64),
      ),
      throwsFormatException,
    );
    expect(jsonEncode(k.snapshot), before);
  });
  test(
    'stored provenance tampering rejects reload instead of detaching the draft',
    () async {
      final store = fixtures.Store(),
          service = KitchenService(fixtures.Store(), fixtures.repository());
      final k = KitchenService(store, fixtures.repository());
      await k.load();
      final r = await reviewed();
      await save(k, r);
      store.data!['kitchen']['personalRecipeDrafts']['revisions'][r
              .draft
              .key]['librarySource']['draft']['name'] =
          'changed after review';
      final corrupt = KitchenService(store, fixtures.repository());
      await expectLater(corrupt.load(), throwsFormatException);
      await service.load();
    },
  );
  test(
    'generic authoring cannot remove source origin on retry or revision',
    () async {
      final k = KitchenService(fixtures.Store(), fixtures.repository());
      await k.load();
      final r = await reviewed();
      await save(k, r);
      final before = jsonEncode(k.snapshot);
      Future<void> generic(PersonalRecipeDraft d) => k.savePersonalRecipeDraft(
        d,
        acknowledgeInputsReviewed: true,
        reviewNote:
            'Synthetic explicit test review; no source or nutritional approval',
        reviewedAt: DateTime.utc(2026, 10, 14),
        expectedActiveKey: r.draft.key,
      );
      await expectLater(generic(r.draft), throwsStateError);
      final changed = r.draft.toJson()..['revision'] = 'v2';
      await expectLater(
        generic(PersonalRecipeDraft.fromJson(changed)),
        throwsStateError,
      );
      expect(jsonEncode(k.snapshot), before);
    },
  );
  test('private library calculation cannot bypass source import approval into planning', () async {
    final k = KitchenService(fixtures.Store(), fixtures.repository());
    await k.load();
    final r = await reviewed();
    await save(k, r);
    final review = PersonalRecipeFinalization(
      draft: r.draft,
      category: 'test',
      description: 'test',
      difficulty: 'test',
      stepMinutes: List.generate(
        r.draft.instructions.length,
        (i) => i == 0 ? 1 : 0,
      ),
      ingredientIds: {for (final line in r.draft.lines) line.id: line.id},
      reviewNote: 'test',
      reviewedAt: DateTime.utc(2026, 10, 14),
      acknowledgeInstructionsAndInputs: true,
      acknowledgeNutritionIncomplete: true,
    );
    await expectLater(k.finalizePersonalRecipe(review), throwsStateError);
    expect(k.recipeBook.revisions, isEmpty);
  });
}
