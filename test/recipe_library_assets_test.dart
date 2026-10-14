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
      expect(entries, hasLength(31));
      expect(entries.where((entry) => entry.runtimeReady), isEmpty);
      expect(entries.every((entry) => entry.nutrition == null), isTrue);
      expect(await repository.search('مقلوبة'), hasLength(2));
      expect(await repository.search('نان'), isNotEmpty);
      expect(await repository.search('حريرة'), isNotEmpty);
      expect(await repository.filterByCuisine('Moroccan'), hasLength(10));
      expect((await RecipeRepository().index), hasLength(54));
      expect(
        entries.where((entry) => entry.sourceSnapshot != null),
        hasLength(20),
      );
      expect(entries.every((entry) => entry.stepsArabic.isNotEmpty), isTrue);
    },
  );
}
