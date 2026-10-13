import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:tabkha_demo/domain/recipe_catalog.dart';

void main() {
  test(
    'Node structural candidate loads/scales through real Flutter catalog',
    () async {
      final process = await Process.run(
        Platform.environment['SOFRA_NODE'] ?? 'node',
        ['tool/recipes/runtime-adapter.emit-fixture.mjs'],
      );
      expect(process.exitCode, 0, reason: '${process.stderr}');
      final envelope =
          jsonDecode(process.stdout as String) as Map<String, dynamic>;
      final recipe = CatalogRecipe.fromJson(
        Map<String, dynamic>.from(envelope['recipe'] as Map),
      );
      expect(recipe.id, 'import:fixture');
      expect(recipe.servings, 2);
      expect(recipe.ingredients.map((v) => v.id), ['flour', 'water']);
      expect(recipe.ingredients.map((v) => v.quantityFor(2)), [200, 400]);
      expect(recipe.steps.map((v) => v.minutes), [2, 10]);
      expect(recipe.steps.last.passive, true);
      expect(recipe.forServings(4).servings, 4);
      expect(envelope['runtimeReady'], false);
      expect((envelope['nutrition'] as Map)['runtimeBindings'], isEmpty);
      expect(((envelope['provenance'] as Map)['lines'] as List).length, 2);
    },
  );
}
