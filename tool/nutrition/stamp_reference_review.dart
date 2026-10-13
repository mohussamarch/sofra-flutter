import 'dart:convert';
import 'dart:io';

import 'package:tabkha_demo/domain/recipe_catalog.dart';
import 'package:tabkha_demo/domain/recipe_variants.dart';

// Build-time stamping, never automatic runtime acceptance of changed recipes.
void main() {
  final validation = Process.runSync('node', [
    'tool/nutrition/validate-reference-review.mjs',
  ]);
  if (validation.exitCode != 0) {
    stderr.write(validation.stderr);
    exitCode = validation.exitCode;
    return;
  }

  final file = File('data/nutrition/recipe-reference-review.json');
  final j = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final sourceFiles = <String, Map<String, CatalogRecipe>>{};
  for (final raw in j['entries'] as List) {
    final entry = raw as Map<String, dynamic>,
        path = entry['recipeSourceFile'] as String;
    final recipes = sourceFiles.putIfAbsent(
      path,
      () => {
        for (final r
            in jsonDecode(File(path).readAsStringSync())['recipes'] as List)
          (r['id'] as String): CatalogRecipe.fromJson(
            Map<String, dynamic>.from(r as Map),
          ),
      },
    );
    final recipe = recipes[entry['recipeId']]!;
    final row = recipe.ingredients[entry['line'] as int];
    if (row.id != entry['ingredientId'] || row.name != entry['expectedName']) {
      throw StateError('Stale source line');
    }
    entry['recipeSnapshotVersion'] = recipeSnapshotVersion(recipe);
  }
  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(j)}\n');
  stdout.writeln('Stamped ${(j['entries'] as List).length} reference entries');
}
