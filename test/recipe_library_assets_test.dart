// Full pinned 6,648-entry source-bank integration; repeated SHA/coverage work
// exceeds the default 30s on this machine. No integrity assertion is skipped.
@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/recipe_library_assets.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';
import 'package:tabkha_demo/domain/recipe_library_coverage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('selected source library assets load without promoting planning data', () async {
    final repository = bundledRecipeLibrary();
    final entries = await repository.all();
    final audit = RecipeLibraryCoverageReport.fromEntries(entries);
    debugPrint(
      'SOURCE_LIBRARY_AUDIT ${jsonEncode({'recipes': audit.recipeCount, 'ingredients': audit.ingredientCount, 'quantityReviewLines': audit.quantityReviewLineCount, 'missingAmount': audit.missingAmountCount, 'missingUnit': audit.missingUnitCount, 'unitNeedsReview': audit.unitNeedsReviewCount, 'supplemental': audit.supplementalCount, 'optional': audit.optionalCount, 'runtimeApproved': audit.runtimeApprovedRecipes})}',
    );
    expect(entries, hasLength(6648));
    expect(entries.where((entry) => entry.runtimeReady), isEmpty);
    expect(entries.every((entry) => entry.nutrition == null), isTrue);
    final sourceLanguageEntries = entries
        .where(
          (entry) =>
              (entry.sourceRecord['translationStatus'] ??
                  (entry.sourceRecord['provenance']
                      as Map?)?['translationStatus']) ==
              'not-translated',
        )
        .toList();
    expect(sourceLanguageEntries, hasLength(6440));
    expect(
      sourceLanguageEntries.fold<int>(
        0,
        (n, entry) => n + entry.ingredients.length,
      ),
      55136,
    );
    expect(
      sourceLanguageEntries.fold<int>(
        0,
        (n, entry) => n + entry.stepsArabic.length,
      ),
      36988,
    );
    expect(
      sourceLanguageEntries.every(
        (entry) =>
            entry.sourceRecord['nameAr'] == null &&
            entry.titleAr.isNotEmpty &&
            entry.ingredients.every(
              (line) => line.amount == null && line.unit == null,
            ),
      ),
      isTrue,
    );
    expect(await repository.search('مقلوبة'), hasLength(2));
    expect(await repository.search('نان'), isNotEmpty);
    expect(await repository.search('حريرة'), isNotEmpty);
    expect(await repository.filterByCuisine('Moroccan'), hasLength(15));
    expect((await RecipeRepository().index), hasLength(363));
    expect(
      entries.where((entry) => entry.sourceSnapshot != null),
      hasLength(6504),
    );
    final frenchRecovery = entries
        .where((entry) => entry.sourceRecord['sourceTextRecovery'] != null)
        .toList();
    expect(frenchRecovery, hasLength(1000));
    expect(
      frenchRecovery.where(
        (entry) =>
            (entry.sourceRecord['sourceTextRecovery']
                as Map)['sourceTextWithoutUnresolvedMarkup'] ==
            true,
      ),
      hasLength(988),
    );
    expect(entries.every((entry) => entry.stepsArabic.isNotEmpty), isTrue);
    for (final cuisine in [
      'Omani',
      'Yemeni',
      'Filipino',
      'Singaporean',
      'Nepalese',
      'Bosnian',
      'Tibetan',
    ]) {
      expect(await repository.filterByCuisine(cuisine), isNotEmpty);
    }
    final partialSource = entries.firstWhere(
      (entry) => entry.id == 'nepali-food-recipes-aloo-bodi-tama-20261021',
    );
    expect(
      partialSource.sourceRecord['sourceEvidence']['methodCompleteInExtract'],
      isFalse,
    );
    expect(partialSource.runtimeReady, isFalse);
    final thue = entries.firstWhere(
      (entry) => entry.id == 'yowangdu-tibetan-thue-20261021',
    );
    expect(thue.sourceRecord['yield']['unit'], 'bricks');
    expect(thue.sourceRecord['yield']['servings'], isNull);
    for (final cuisine in [
      'Chinese',
      'Korean',
      'Indonesian',
      'Greek',
      'Caribbean',
      'Ethiopian',
      'Brazilian',
      'Swedish',
    ]) {
      expect(await repository.filterByCuisine(cuisine), isNotEmpty);
    }
    for (final cuisine in [
      'albanian',
      'argentine',
      'austrian',
      'bulgarian',
      'colombian',
      'cuban',
      'palestinian',
      'malaysian',
      'hungarian',
      'lebanese',
      'ghanaian',
      'tanzanian',
      'jamaican',
      'russian',
      'gambian',
      'ugandan',
      'cameroonian',
      'libyan',
      'zambian',
      'malawian',
      'norwegian',
    ]) {
      expect(await repository.filterByCuisine(cuisine), isNotEmpty);
    }
    final shawarma = entries.firstWhere(
      (e) => e.id == 'chef-omar-website-meat-shawarma',
    );
    expect(shawarma.sourceRecord['time']['totalMinutes'], isNull);
    expect(shawarma.sourceRecord['time']['publishedTotalMinutes'], 60);
    expect(shawarma.packMetadata['creator']['channelUrl'], isNull);

    final pasta = entries.firstWhere(
      (e) => e.id == 'manal-website-chicken-bechamel-pasta',
    );
    expect(pasta.ingredients.where((i) => i.supplemental), hasLength(3));
    expect(pasta.sourceRecord['yield']['amount'], isNull);
    final cake = entries.firstWhere((e) => e.id == 'manal-website-apple-cake');
    expect(cake.ingredients.first.amount, isNull);
    expect(cake.ingredients.first.sourceQuantityText, '5-4');
    expect(await repository.filterByCuisine('japanese'), hasLength(37));
    expect(await repository.filterByCuisine('thai'), hasLength(35));
  });
}
