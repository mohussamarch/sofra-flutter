import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';

void main() {
  RecipeRepository repo() =>
      RecipeRepository(read: (path) => File(path).readAsString());

  test('search finds recipes by ingredient after those named for it', () async {
    final r = repo();
    final rows = await r.search(query: 'باذنجان');
    final names = [for (final row in rows) row['name'] as String];
    expect(names, contains('فتة باذنجان'));
    final firstByIngredient = names.indexWhere((n) => !n.contains('باذنجان'));
    expect(firstByIngredient, greaterThan(0));
    expect(
      names.skip(firstByIngredient).every((n) => !n.contains('باذنجان')),
      isTrue,
      reason: 'name matches come first',
    );
  });

  test('search ignores the difference between ة and ه', () async {
    final rows = await repo().search(query: 'شكشوكه');
    expect(rows.map((r) => r['name']), contains('شكشوكة حجازية'));
  });

  test('meal kind and time filters narrow the list', () async {
    final r = repo();
    final soups = await r.search(kind: 'شوربة');
    expect(soups, isNotEmpty);
    expect(
      soups.every((s) => RecipeRepository.kindOf(s['category']) == 'شوربة'),
      isTrue,
    );
    final quick = await r.search(maxMinutes: 30);
    expect(quick, isNotEmpty);
    expect(
      quick.every((s) => s['totalTime'] is num && s['totalTime'] <= 30),
      isTrue,
      reason: 'unknown times never pass a time filter',
    );
  });

  test('kinds group the source categories', () {
    expect(RecipeRepository.kindOf('أطباق رئيسية'), 'رئيسي');
    expect(RecipeRepository.kindOf('طبق جانبي'), 'رئيسي');
    expect(RecipeRepository.kindOf('إفطار'), 'فطار');
    expect(RecipeRepository.kindOf('شوربات ويخنات'), 'شوربة');
    expect(RecipeRepository.kindOf('حساء'), 'شوربة');
    expect(RecipeRepository.kindOf('صلصات ومقبلات'), 'سلطة ومقبلات');
    expect(RecipeRepository.kindOf('حلوى'), 'حلويات');
    expect(RecipeRepository.kindOf('المعجنات والمخبوزات'), 'مخبوزات');
    expect(RecipeRepository.kindOf('مشروب'), isNull);
  });

  test('dishes join active recipes made in different ways', () async {
    final r = repo();
    final dishes = await r.dishes;
    final active = {for (final row in await r.index) row['id'] as String};
    final seen = <String>{};
    for (final d in dishes) {
      expect(d.recipes.length, greaterThanOrEqualTo(2), reason: d.id);
      for (final id in d.recipes) {
        expect(active, contains(id));
        expect(seen.add(id), isTrue, reason: '$id is in one dish only');
      }
    }
    final shakshuka = dishes.singleWhere((d) => d.id == 'shakshuka');
    final cuisines = {
      for (final id in shakshuka.recipes)
        (await r.index).singleWhere((row) => row['id'] == id)['cuisine'],
    };
    expect(cuisines, containsAll(['تونسي', 'سعودي']));
  });

  test('dishes.json matches its reviewed list', () async {
    final result = await Process.run('node', [
      'tool/recipes/build-dishes.mjs',
      '--check',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  });
}
