import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/recipe_library_draft.dart';

import 'recipe_library_repository_test.dart' as fixtures;

RecipeLibraryLineDecision fixturesDecision() => RecipeLibraryLineDecision(
  input: RecipeFoodInput(
    ingredientId: 'video-line',
    food: null,
    amount: null,
    amountForm: FoodForm.raw,
    preparedForm: FoodForm.raw,
  ),
  scales: false,
  overrideSourceExclusion: false,
);

fixtures.LibraryFixture videoFixture([
  Map<String, dynamic> changes = const {},
]) {
  final f = fixtures.LibraryFixture();
  final row = f.creator['recipes'][0] as Map<String, dynamic>;
  row.addAll({
    'sourceKind': 'creator-youtube',
    'youtubeDerived': true,
    'sourceVideoId': 'Abc_123-xyz',
    'sourceUrl': 'https://www.youtube.com/watch?v=Abc_123-xyz',
    'evidenceUrl': 'https://www.youtube.com/watch?v=Abc_123-xyz',
    'sourceEvidence': {
      'acquisitionMethod': 'worker-primary-search-extract',
      'fullPageRetrievedByWorker': false,
      'ingredientListCompleteInExtract': true,
    },
    ...changes,
  });
  f.rebuild();
  f.manifest['packs'][1]['kind'] = 'creator-youtube';
  f.pinManifest();
  return f;
}

void main() {
  test('website provenance rejects explicit video or unknown derivation, preserving omitted legacy fields', () async {
    final legacy = fixtures.LibraryFixture();
    expect(
      (await legacy.repository().all()).last.sourceRecord['youtubeDerived'],
      isNull,
    );
    for (final value in [true, null, 'true']) {
      final f = fixtures.LibraryFixture();
      f.creator['recipes'][0]['youtubeDerived'] = value;
      f.rebuild();
      await expectLater(f.repository().all(), throwsFormatException);
    }
  });
  test('pinned video-description facts stay distinct from website, direct body and approval', () async {
    final f = videoFixture();
    final e = (await f.repository().all()).last;
    expect(e.sourceRecord['sourceKind'], 'creator-youtube');
    expect(e.sourceRecord['youtubeDerived'], true);
    expect(e.sourceRecord['sourceVideoId'], 'Abc_123-xyz');
    expect(
      e.sourceRecord['sourceEvidence']['fullPageRetrievedByWorker'],
      false,
    );
    expect(
      e.sourceRecord['sourceEvidence']['ingredientListCompleteInExtract'],
      true,
    );
    expect(e.runtimeReady, false);
    expect(e.nutrition, isNull);
    final review = RecipeLibraryDraftReview.create(
      entry: e,
      expectedSourceFingerprint: recipeLibrarySourceFingerprint(e),
      draftId: 'video-private',
      revision: 'r1',
      createdAt: DateTime.utc(2026, 10, 15),
      servings: 1,
      decisions: {0: fixturesDecision()},
    );
    expect(
      review.sourceSnapshot['sourceRecord']['sourceVideoId'],
      'Abc_123-xyz',
    );
    RecipeLibraryDraftReview.fromJson(review.toJson()).assertSource(e);
  });
  test('video kind, derivation, identity, canonical URL and approval gates cannot disagree', () async {
    for (final changes in <Map<String, dynamic>>[
      {'sourceKind': 'creator-website'},
      {'youtubeDerived': false},
      {'youtubeDerived': null},
      {'sourceVideoId': 'invalid'},
      {'sourceVideoId': null},
      {'sourceUrl': 'https://www.youtube.com/watch?v=Zbc_123-xyz'},
      {'sourceUrl': 'https://example.org/watch?v=Abc_123-xyz'},
      {'sourceUrl': 'http://www.youtube.com/watch?v=Abc_123-xyz'},
      {'runtimeReady': true},
      {'nutrition': <String, dynamic>{}},
    ]) {
      await expectLater(
        videoFixture(changes).repository().all(),
        throwsFormatException,
      );
    }
    final mismatched = videoFixture();
    mismatched.manifest['packs'][1]['kind'] = 'creator-website';
    mismatched.pinManifest();
    await expectLater(mismatched.repository().all(), throwsFormatException);
  });
}
