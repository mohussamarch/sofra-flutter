import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';
import 'package:tabkha_demo/domain/recipe_nutrition.dart';
import 'package:tabkha_demo/domain/recipe_variants.dart';

Map<String, dynamic> recipeJson({
  bool unknownPolicy = true,
  int? servings,
  num? prepTime,
  num? cookTime,
  num? stepDuration,
}) => {
  'id': 'source-partial',
  'name': 'وصفة مصدرية',
  'cuisine': 'عربي',
  'category': 'طبق',
  'description': 'مصدر محفوظ',
  'difficulty': 'سهل',
  if (unknownPolicy) 'metadataPolicy': CatalogRecipe.unknownMetadataPolicy,
  'servings': servings,
  'prepTime': prepTime,
  'cookTime': cookTime,
  'totalTime': prepTime == null || cookTime == null
      ? null
      : prepTime + cookTime,
  'ingredients': [
    {'id': 'i1', 'name': 'ماء', 'amount': 1, 'unit': 'كوب', 'scale': true},
  ],
  'steps': [
    {'n': 1, 'text': 'اخلط', 'duration': stepDuration},
    {'n': 2, 'text': 'قدّم', 'duration': 0},
  ],
  'tags': <String>[],
  'notes': 'الكمية والوقت غير منشورين في المصدر؛ محفوظان كمجهولين.',
};

void main() {
  test('nonfinite known totals reject before trusted recipe serialization', () {
    for (final value in [double.nan, double.infinity, -double.infinity, -1]) {
      final row = recipeJson(
        unknownPolicy: false,
        servings: 2,
        prepTime: 3,
        cookTime: 7,
        stepDuration: 10,
      )..['totalTime'] = value;
      expect(() => CatalogRecipe.fromJson(row), throwsFormatException);
    }
  });

  test(
    'public scaling constructor keeps legacy arity and validates boundaries',
    () {
      final known = CatalogRecipe.fromJson(
        recipeJson(
          unknownPolicy: false,
          servings: 2,
          prepTime: 3,
          cookTime: 7,
          stepDuration: 10,
        ),
      );
      expect(ScaledCatalogRecipe(known, 4).factor, 2);
      expect(() => ScaledCatalogRecipe(known, 0), throwsArgumentError);
      expect(() => ScaledCatalogRecipe(known, 1001), throwsArgumentError);
      final unknown = CatalogRecipe.fromJson(recipeJson());
      expect(() => ScaledCatalogRecipe(unknown, 2), throwsArgumentError);
      for (final value in [0, -1, 1001]) {
        expect(
          () => ScaledCatalogRecipe(unknown, 2, value),
          throwsArgumentError,
        );
      }
      expect(ScaledCatalogRecipe(unknown, 4, 2).factor, 2);
      expect(unknown.servings, isNull);
      expect(unknown.toJson()['servings'], isNull);
    },
  );

  test(
    'unknowns require explicit opt-in and provenance, and round-trip as null',
    () {
      expect(
        () => CatalogRecipe.fromJson(recipeJson(unknownPolicy: false)),
        throwsFormatException,
      );
      final json = recipeJson()..['notes'] = null;
      expect(() => CatalogRecipe.fromJson(json), throwsFormatException);
      final implicitYield = recipeJson()..remove('servings');
      expect(
        () => CatalogRecipe.fromJson(implicitYield),
        throwsFormatException,
      );

      final recipe = CatalogRecipe.fromJson(recipeJson());
      expect(recipe.servings, isNull);
      expect(recipe.prepMinutes, isNull);
      expect(recipe.cookMinutes, isNull);
      expect(recipe.totalMinutes, isNull);
      expect(recipe.steps.first.minutes, isNull);
      final restored = CatalogRecipe.fromJson(recipe.toJson());
      expect(restored.toJson(), recipe.toJson());
      expect(restored.ingredients, hasLength(1));
      expect(restored.steps, hasLength(2));
      final forgedTotal = recipeJson()..['totalTime'] = 1;
      expect(() => CatalogRecipe.fromJson(forgedTotal), throwsFormatException);
      final revision = RecipeRevision(
        familyId: 'source-partial-family',
        revision: 'source-r1',
        kind: RecipeRevisionKind.catalog,
        recipe: recipe,
      );
      expect(revision.recipe.toJson(), recipe.toJson());
    },
  );

  test(
    'unknown yield blocks scaling unless caller supplies valid source yield',
    () {
      final recipe = CatalogRecipe.fromJson(recipeJson());
      expect(() => recipe.forServings(4), throwsArgumentError);
      expect(
        () => recipe.forServings(4, sourceServings: 0),
        throwsArgumentError,
      );
      expect(recipe.forServings(4, sourceServings: 2).factor, 2);
      expect(recipe.forServings(4, sourceServings: 2).servings, 4);
    },
  );

  test(
    'incomplete timing stays unknown and cannot create an asserted schedule',
    () {
      final recipe = CatalogRecipe.fromJson(recipeJson());
      final scaled = recipe.forServings(2, sourceServings: 2);
      expect(scaled.prepMinutes, isNull);
      expect(scaled.cookMinutes, isNull);
      expect(scaled.totalMinutes, isNull);
      expect(() => scaled.schedule, throwsStateError);
    },
  );

  test('known legacy shape and fingerprint stay unchanged', () {
    final json = recipeJson(
      unknownPolicy: false,
      servings: 2,
      prepTime: 3,
      cookTime: 7,
      stepDuration: 10,
    );
    final recipe = CatalogRecipe.fromJson(json);
    expect(CatalogRecipe.fromJson(recipe.toJson()).toJson(), recipe.toJson());
    expect(recipe.toJson().containsKey('metadataPolicy'), isFalse);
    expect(
      recipeNutritionVersion(CatalogRecipe.fromJson(recipe.toJson())),
      recipeNutritionVersion(recipe),
    );
    expect(recipe.forServings(4).totalMinutes, 14);
    expect(recipe.forServings(4).schedule.first.minutes, 14);
  });

  test('repository reads opted-in unknown metadata and checks nullable index yield', () async {
    final row = recipeJson();
    row['id'] = 'source-partial';
    final files = <String, String>{
      'recipes/data/index.json': '{"cuisines":[{"file":"test.json"}],"recipes":[{"id":"source-partial","file":"test.json","cuisine":"عربي","servings":null}]}',
      'recipes/data/test.json': '{"recipes":[${_encode(row)}]}',
    };
    final repo = RecipeRepository(read: (path) async => files[path]!);
    final loaded = await repo.get('source-partial');
    expect(loaded.servings, isNull);
    expect(loaded.notes, contains('مصدر'));
  });
}

String _encode(Map<String, dynamic> json) {
  // Keep this test's assets independent of disk and of generated app data.
  return const JsonEncoder().convert(json);
}
