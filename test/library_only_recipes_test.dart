import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';

/// Creators' video recipes live only in the online library
/// (recipes/library-only, published by tool/recipes/publish-library.mjs);
/// the app bundles recipes/data alone, and that seed must not grow.
void main() {
  Map<String, dynamic> json(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  test('the bundled recipe seed did not grow', () {
    final index = json('recipes/data/index.json');
    final rows = index['recipes'] as List;
    expect(rows.length, lessThanOrEqualTo(789));
    expect(
      rows.where((r) => r['catalogStatus'] == 'active').length,
      lessThanOrEqualTo(495),
    );
    var bodies = 0;
    for (final c in index['cuisines'] as List) {
      final file = File('recipes/data/${c['file']}');
      if (file.existsSync()) {
        bodies += (json(file.path)['recipes'] as List).length;
      }
    }
    expect(bodies, lessThanOrEqualTo(789));
    // Nothing under recipes/library-only is an app asset.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('library-only')));
    expect(
      pubspec,
      isNot(contains(RegExp(r'^\s*- recipes/\s*$', multiLine: true))),
    );
    final ids = {for (final r in rows) r['id']};
    for (final r
        in json('recipes/library-only/youtube.json')['recipes'] as List) {
      expect(ids, isNot(contains(r['id'])));
    }
  });

  test('library recipes read in the app with their creator and video', () {
    final recipes =
        json('recipes/library-only/youtube.json')['recipes'] as List;
    expect(recipes, isNotEmpty);
    for (final raw in recipes) {
      final recipe = CatalogRecipe.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
      expect(recipe.creatorId, startsWith('yt:UC'), reason: recipe.id);
      expect(recipe.video?.platform, 'youtube', reason: recipe.id);
      expect(recipe.video?.url, raw['video']['url']);
      final starts = [for (final s in raw['steps'] as List) s['videoStartSec']];
      expect(recipe.steps.map((s) => s.videoStartSec), starts);
      // Round trip keeps the new fields.
      final again = CatalogRecipe.fromJson(recipe.toJson());
      expect(again.creatorId, recipe.creatorId);
      expect(again.video?.id, recipe.video?.id);
      expect(again.steps.map((s) => s.videoStartSec), starts);
    }
  });

  test('source facts never make a recipe unreadable', () {
    final video = RecipeVideo.tryParse({
      'platform': 'youtube',
      'id': 'abc',
      'url': 'https://www.youtube.com/watch?v=abc',
      'views': -1,
      'publishedAt': 'soon',
    });
    expect(video?.views, isNull);
    expect(video?.publishedAt, isNull);
    expect(RecipeVideo.tryParse({'id': 'abc'}), isNull);
    expect(RecipeVideo.tryParse('x'), isNull);
  });
}
