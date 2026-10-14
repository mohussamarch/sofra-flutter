import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/recipe_library_repository.dart';
import 'package:tabkha_demo/data/recipe_library_assets.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/recipe_library_draft.dart';

import 'recipe_library_repository_test.dart' as fixtures;
import 'personal_recipe_draft_test.dart' as nutrition;

RecipeLibraryLineDecision decision(
  int line, {
  FoodRecord? food,
  double? grams,
  bool scales = false,
  bool optional = false,
  bool selected = true,
  bool override = false,
}) => RecipeLibraryLineDecision(
  input: RecipeFoodInput(
    ingredientId: 'private-line-$line',
    food: food,
    amount: grams == null
        ? null
        : FoodAmount(value: grams, unit: FoodQuantityUnit.g),
    amountForm: FoodForm.raw,
    preparedForm: FoodForm.raw,
    optional: optional,
    selected: selected,
  ),
  scales: scales,
  overrideSourceExclusion: override,
);
RecipeLibraryDraftReview makeReview(
  RecipeLibraryEntry entry, {
  Map<int, RecipeLibraryLineDecision>? choices,
  String? pin,
}) => RecipeLibraryDraftReview.create(
  entry: entry,
  expectedSourceFingerprint: pin ?? recipeLibrarySourceFingerprint(entry),
  draftId: 'private',
  revision: 'v1',
  createdAt: DateTime.utc(2026, 10, 14),
  servings: 3,
  decisions:
      choices ??
      {for (var i = 0; i < entry.ingredients.length; i++) i: decision(i)},
);

void main() {
  test('bridges every explicit line while retaining unknown quantities metadata and full source', () async {
    final entry = (await fixtures.LibraryFixture().repository().all()).first;
    final review = makeReview(entry), draft = makeReview(entry).draft;
    expect(draft.name, entry.titleAr);
    expect(draft.instructions, entry.stepsArabic);
    expect(draft.cuisine, isNull);
    expect(draft.prepMinutes, isNull);
    expect(draft.cookMinutes, isNull);
    expect(draft.servings, 3);
    expect(draft.lines.length, 2);
    for (final line in draft.lines) {
      expect(line.input.food, isNull);
      expect(line.input.amount, isNull);
      expect(line.scales, isFalse);
    }
    expect(draft.previewIngredients().whole[NutrientId.protein]!.value, isNull);
    expect(review.libraryEntryId, entry.id);
    expect(review.sourceSnapshot['sourceRecord']['yield']['max'], 4);
    expect(
      review.sourceSnapshot['sourceSnapshot']['sourceRecord']['license']['id'],
      'CC BY-SA',
    );
    expect(
      review
          .sourceSnapshot['sourceRecord']['gates']['inventoryIdentityApproved'],
      isFalse,
    );
    review.assertSource(entry);
  });
  test('explicit reviewed inputs use existing calculator and honor per-line scaling', () async {
    final entry = (await fixtures.LibraryFixture().repository().all()).first;
    final review = makeReview(
      entry,
      choices: {
        0: decision(0, food: nutrition.fixtureFood(), grams: 100, scales: true),
        1: decision(1, optional: true, selected: false),
      },
    );
    expect(
      review.draft.previewIngredients().whole[NutrientId.protein]!.value,
      10,
    );
    expect(
      review.draft
          .previewIngredients(servings: 6)
          .whole[NutrientId.protein]!
          .value,
      20,
    );
    expect(review.draft.lines.first.input.ingredientId, 'private-line-0');
  });
  test('all positions need review and excluded source alternatives need explicit override', () async {
    final fixture = fixtures.LibraryFixture();
    (fixture.local['recipes'] as List).first['ingredients'][0]['included'] =
        false;
    fixture.rebuild();
    final entry = (await fixture.repository().all()).first;
    expect(
      () => makeReview(entry, choices: {0: decision(0)}),
      throwsArgumentError,
    );
    expect(
      () => makeReview(
        entry,
        choices: {0: decision(0), 1: decision(1), 2: decision(2)},
      ),
      throwsArgumentError,
    );
    expect(() => makeReview(entry), throwsArgumentError);
    final excluded = makeReview(
      entry,
      choices: {
        0: decision(0, optional: true, selected: false),
        1: decision(1),
      },
    );
    expect(excluded.draft.lines.first.input.selected, isFalse);
    final changed = makeReview(
      entry,
      choices: {0: decision(0, override: true), 1: decision(1)},
    );
    expect(changed.draft.lines.first.input.selected, isTrue);
    expect(
      () => makeReview(
        entry,
        choices: {
          0: decision(0, override: true),
          1: decision(1, override: true),
        },
      ),
      throwsArgumentError,
    );
  });
  test(
    'full source change invalidates review even with the same library ID',
    () async {
      final fixture = fixtures.LibraryFixture();
      final original = (await fixture.repository().all()).first,
          pin = recipeLibrarySourceFingerprint(
            (await fixture.repository().all()).first,
          );
      final review = makeReview(original);
      (fixture.local['recipes'] as List).first['steps'][0]['textAr'] =
          'changed instruction';
      fixture.rebuild();
      final changed = (await fixture.repository().all()).first;
      expect(changed.id, original.id);
      expect(() => makeReview(changed, pin: pin), throwsStateError);
      expect(() => review.assertSource(changed), throwsStateError);
      expect(
        () => review.assertSource(original, expectedFingerprint: '0' * 64),
        throwsStateError,
      );
    },
  );
  test('owned envelope roundtrips and rejects source draft decision and fingerprint drift', () async {
    final entry = (await fixtures.LibraryFixture().repository().all()).first;
    final choices = {0: decision(0), 1: decision(1)};
    final review = makeReview(entry, choices: choices),
        fingerprint = makeReview(entry, choices: choices).fingerprint;
    choices.clear();
    final json = review.toJson(),
        restored = RecipeLibraryDraftReview.fromJson(review.toJson());
    expect(restored.fingerprint, fingerprint);
    expect(restored.draft.fingerprint, review.draft.fingerprint);
    (json['source']['sourceRecord']['gates'] as Map).clear();
    expect(review.sourceSnapshot['sourceRecord']['gates'], isNotEmpty);
    final raw = review.sourceSnapshot;
    raw.clear();
    expect(review.libraryEntryId, entry.id);
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (j) => j['source']['titleAr'] = 'changed',
      (j) => j['draft']['servings'] = 5,
      (j) => j['decisions'][0]['overrideSourceExclusion'] = true,
      (j) => j['sourceFingerprint'] = 'f' * 64,
      (j) => j['fingerprint'] = 'f' * 64,
    ]) {
      final modified = review.toJson();
      mutate(modified);
      expect(
        () => RecipeLibraryDraftReview.fromJson(modified),
        throwsFormatException,
      );
    }
    final reordered = Map<String, dynamic>.from(
      nutrition.reversedMaps(review.toJson()) as Map,
    );
    expect(
      RecipeLibraryDraftReview.fromJson(reordered).fingerprint,
      fingerprint,
    );
  });
  test('creator context keeps only matching attribution and rights without unrelated catalog', () async {
    final fixture = fixtures.LibraryFixture();
    fixture.creator['videos'] = [
      {'large': 'unrelated'},
    ];
    (fixture.creator['creators'] as List).add({
      'creatorId': 'another',
      'name': 'unrelated creator',
    });
    fixture.rebuild();
    final entry = (await fixture.repository().all()).last,
        review = makeReview((await fixture.repository().all()).last);
    final metadata = review.sourceSnapshot['packMetadata'] as Map;
    expect(metadata.containsKey('videos'), isFalse);
    expect((metadata['creators'] as List).single['creatorId'], 'chef');
    expect(metadata['sourcePolicy']['reuseRights'], isNull);
    expect(review.draft.lines.single.input.amount, isNull);
    expect(review.sourceSnapshot['sourceRecord']['yield'], isNull);
    review.assertSource(entry);
  });
  test('actual pinned cookbook unknowns stay source evidence instead of automatic calorie inputs', () async {
    final entries = await RecipeLibraryRepository(
      expectedManifestSha256: recipeLibraryManifestSha256,
      read: (path) => File(path).readAsString(),
    ).all();
    expect(entries.length, 31);
    final entry = entries.firstWhere(
      (value) => value.id == 'manal-website-chicken-eggplant-maqluba',
    );
    expect(entry.ingredients.any((line) => line.amount == null), isTrue);
    expect(entry.ingredients.any((line) => line.unit == 'cup'), isTrue);
    final review = makeReview(entry);
    expect(review.sourceSnapshot['sourceRecord']['yield'], isNull);
    expect(review.sourceSnapshot['sourceRecord']['cookTime'], isNull);
    expect(review.sourceSnapshot['sourceRecord']['reuseRights'], isNull);
    expect(
      review.draft.lines.every(
        (line) => line.input.food == null && line.input.amount == null,
      ),
      isTrue,
    );
    expect(
      review.draft.previewIngredients().whole[NutrientId.energyKcal]!.value,
      isNull,
    );
    expect(
      RecipeLibraryDraftReview.fromJson(review.toJson()).sourceFingerprint,
      review.sourceFingerprint,
    );
  });
}
