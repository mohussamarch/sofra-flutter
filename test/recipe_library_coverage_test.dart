import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/recipe_library_assets.dart';
import 'package:tabkha_demo/data/recipe_library_repository.dart';
import 'package:tabkha_demo/domain/recipe_library_coverage.dart';
import 'package:tabkha_demo/domain/recipe_library_draft.dart';

Future<List<RecipeLibraryEntry>> fixture({double? amount = 100}) async {
  const path = 'data/recipes/arabic-youtube/coverage-test.json';
  final pack = jsonEncode({
    'schemaVersion': 1,
    'sourcePolicy': {'sourceApproval': null, 'reuseRights': null},
    'recipes': [
      {
        'recipeId': 'coverage:one',
        'title': 'اختبار المصدر',
        'sourceKind': 'creator-website',
        'sourceUrl': 'https://example.org/recipe',
        'creatorId': 'one',
        'ingredients': [
          {
            'labelAr': 'دقيق',
            'amount': amount,
            'unit': 'g',
            'sourceQuantityText': '100 g',
          },
          {
            'labelAr': 'دقيق',
            'amount': null,
            'unit': null,
            'sourceQuantityText': 'as needed',
          },
          {
            'labelAr': 'زيت',
            'amount': 1,
            'unit': 'cup',
            'optional': true,
            'included': null,
          },
          {'labelAr': 'سمن', 'amount': 0, 'unit': 'g', 'included': false},
        ],
        'supplementalIngredients': [
          {'labelAr': 'خبز', 'amount': null, 'unit': null},
        ],
        'steps': [
          {'textAr': 'رتب المكونات وفق المصدر'},
        ],
      },
    ],
  });
  String hash(String s) => sha256.convert(utf8.encode(s)).toString();
  final manifest = jsonEncode({
    'schemaVersion': 1,
    'runtimeReady': false,
    'packs': [
      {
        'kind': 'creator-website',
        'file': path,
        'sha256': hash(pack),
        'sourceSnapshots': [],
      },
    ],
  });
  return RecipeLibraryRepository(
    expectedManifestSha256: hash(manifest),
    read: (p) async => p == path ? pack : manifest,
  ).all();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('indexed source gaps preserve repeated, optional, excluded and procedural lines', () async {
    final entries = await fixture();
    final report = RecipeLibraryCoverageReport.fromEntries(entries);
    expect(report.recipeCount, 1);
    expect(report.ingredientCount, 5);
    expect(report.quantityReviewLineCount, 4);
    expect(report.toJson()['quantityReviewLineCount'], 4);
    expect(report.missingAmountCount, 2);
    expect(report.missingUnitCount, 2);
    expect(report.nonPositiveAmountCount, 1);
    expect(report.unitNeedsReviewCount, 1);
    expect(report.supplementalCount, 1);
    expect(report.optionalCount, 1);
    final review = report.recipes.single;
    expect(
      review.sourceFingerprint,
      recipeLibrarySourceFingerprint(entries.single),
    );
    expect(review.lines.map((l) => l.lineIndex), [0, 1, 2, 3, 4]);
    expect(
      review.lines.where((l) => l.needsQuantityReview).map((l) => l.lineIndex),
      [1, 2, 3, 4],
    );
    expect(review.lines[1].sourceQuantityText, 'as needed');
    expect(review.lines[2].included, isNull);
    expect(review.lines[3].included, false);
    expect(review.lines.every((l) => l.requiresExplicitFoodReview), true);
    expect(report.runtimeApprovedRecipes, 0);
  });
  test(
    'returned reports own their lists and do not approve or change source data',
    () async {
      final entries = await fixture();
      final before = recipeLibrarySourceFingerprint(entries.single);
      final report = RecipeLibraryCoverageReport.fromEntries(entries);
      expect(() => report.recipes.clear(), throwsUnsupportedError);
      expect(() => report.recipes.single.lines.clear(), throwsUnsupportedError);
      final json = report.toJson();
      json['recipes'][0]['lines'][0]['labelAr'] = 'changed';
      expect(report.recipes.single.lines.first.labelAr, 'دقيق');
      expect(recipeLibrarySourceFingerprint(entries.single), before);
      expect(entries.single.nutrition, isNull);
      expect(entries.single.runtimeReady, false);
    },
  );
  test('source pin changes with source quantity and duplicate recipe inputs reject', () async {
    final a = await fixture(), b = await fixture(amount: 200);
    expect(
      RecipeLibraryCoverageReport.fromEntries(a)
          .recipes
          .single
          .sourceFingerprint,
      isNot(
        RecipeLibraryCoverageReport.fromEntries(b)
            .recipes
            .single
            .sourceFingerprint,
      ),
    );
    expect(
      () => RecipeLibraryCoverageReport.fromEntries([...a, ...a]),
      throwsArgumentError,
    );
    expect(RecipeLibraryCoverageReport.fromEntries([]).ingredientCount, 0);
    expect(
      RecipeLibraryCoverageReport.fromEntries([]).quantityReviewLineCount,
      0,
    );
  });
  test('actual selected cookbook reports all source lines with calculator-compatible pins', () async {
    final entries = await bundledRecipeLibrary().all();
    final report = RecipeLibraryCoverageReport.fromEntries(entries);
    expect(report.recipeCount, entries.length);
    expect(
      report.ingredientCount,
      entries.fold<int>(0, (n, e) => n + e.ingredients.length),
    );
    expect(report.missingAmountCount, greaterThan(0));
    expect(report.unitNeedsReviewCount, greaterThan(0));
    for (var i = 0; i < entries.length; i++) {
      expect(
        report.recipes[i].sourceFingerprint,
        recipeLibrarySourceFingerprint(entries[i]),
      );
      expect(report.recipes[i].lines.length, entries[i].ingredients.length);
    }
    expect(report.runtimeApprovedRecipes, 0);
    final summary = report.toJson()..remove('recipes');
    // ignore: avoid_print
    print('LIBRARY_COVERAGE ${jsonEncode(summary)}');
  });
}
