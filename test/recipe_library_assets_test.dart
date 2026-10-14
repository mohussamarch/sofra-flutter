import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/recipe_library_assets.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'selected Arabic library assets load without promoting planning data',
    () async {
      final repository = bundledRecipeLibrary();
      final entries = await repository.all();
      expect(entries, hasLength(44));
      expect(entries.where((entry) => entry.runtimeReady), isEmpty);
      expect(entries.every((entry) => entry.nutrition == null), isTrue);
      expect(await repository.search('مقلوبة'), hasLength(2));
      expect(await repository.search('نان'), isNotEmpty);
      expect(await repository.search('حريرة'), isNotEmpty);
      expect(await repository.filterByCuisine('Moroccan'), hasLength(10));
      expect((await RecipeRepository().index), hasLength(54));
      expect(
        entries.where((entry) => entry.sourceSnapshot != null),
        hasLength(28),
      );
      expect(entries.every((entry) => entry.stepsArabic.isNotEmpty), isTrue);
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
      expect(await repository.filterByCuisine('japanese'), hasLength(1));
      expect(await repository.filterByCuisine('thai'), hasLength(1));
    },
  );
}
