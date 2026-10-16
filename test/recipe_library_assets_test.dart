import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/recipe_library_assets.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'selected source library assets load without promoting planning data',
    () async {
      final repository = bundledRecipeLibrary();
      final entries = await repository.all();
      expect(entries, hasLength(3530));
      expect(entries.where((entry) => entry.runtimeReady), isEmpty);
      expect(entries.every((entry) => entry.nutrition == null), isTrue);
      final sourceLanguageEntries = entries
          .where(
            (entry) =>
                entry.sourceRecord['translationStatus'] == 'not-translated',
          )
          .toList();
      expect(sourceLanguageEntries, hasLength(3440));
      expect(
        sourceLanguageEntries.fold<int>(
          0,
          (n, entry) => n + entry.ingredients.length,
        ),
        30021,
      );
      expect(
        sourceLanguageEntries.fold<int>(
          0,
          (n, entry) => n + entry.stepsArabic.length,
        ),
        23723,
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
      expect((await RecipeRepository().index), hasLength(54));
      expect(
        entries.where((entry) => entry.sourceSnapshot != null),
        hasLength(3504),
      );
      expect(entries.every((entry) => entry.stepsArabic.isNotEmpty), isTrue);
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
      final cake = entries.firstWhere(
        (e) => e.id == 'manal-website-apple-cake',
      );
      expect(cake.ingredients.first.amount, isNull);
      expect(cake.ingredients.first.sourceQuantityText, '5-4');
      expect(await repository.filterByCuisine('japanese'), hasLength(37));
      expect(await repository.filterByCuisine('thai'), hasLength(35));
    },
  );
}
