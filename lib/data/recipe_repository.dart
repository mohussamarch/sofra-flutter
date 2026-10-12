import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/recipe_catalog.dart';

typedef RecipeAssetReader = Future<String> Function(String path);

class RecipeRepository {
  RecipeRepository({RecipeAssetReader? read})
    : _read = read ?? rootBundle.loadString;
  final RecipeAssetReader _read;
  Future<List<Map<String, dynamic>>>? _index;
  final _files = <String, Future<Map<String, CatalogRecipe>>>{};
  Set<String> _allowedFiles = {};

  Future<List<Map<String, dynamic>>> get index =>
      _index ??= _loadIndex().catchError((Object e) {
        _index = null;
        throw e;
      });

  Future<List<Map<String, dynamic>>> _loadIndex() async {
    final json = jsonDecode(
      await _read('recipes/data/index.json'),
    ) as Map<String, dynamic>;
    _allowedFiles = (json['cuisines'] as List)
        .map((v) => v['file'] as String)
        .toSet();
    if (_allowedFiles.any((v) => !RegExp(r'^[a-z]+\.json$').hasMatch(v))) {
      throw const FormatException('Invalid recipe asset path');
    }
    final ids = <String>{};
    final entries = (json['recipes'] as List)
        .map((v) {
          final row = Map<String, dynamic>.from(v as Map);
          if (!ids.add(row['id'] as String) ||
              !_allowedFiles.contains(row['file'])) {
            throw const FormatException(
              'Duplicate recipe or unknown cuisine file',
            );
          }
          return Map<String, dynamic>.unmodifiable(row);
        })
        .toList(growable: false);
    return List.unmodifiable(entries);
  }

  Future<List<Map<String, dynamic>>> search({
    String query = '',
    String? cuisine,
    String? category,
  }) async {
    final needle = _normalize(query);
    return (await index)
        .where((r) {
          if (cuisine != null && r['cuisine'] != cuisine) return false;
          if (category != null && r['category'] != category) return false;
          return _normalize(
            '${r['name']} ${r['nameEn'] ?? ''} ${(r['tags'] as List).join(' ')}',
          ).contains(needle);
        })
        .toList(growable: false);
  }

  Future<CatalogRecipe> get(String id) async {
    final entries = (await index).where((v) => v['id'] == id);
    if (entries.isEmpty) throw ArgumentError.value(id, 'recipeId');
    final entry = entries.single;
    final file = entry['file'] as String;
    final recipes = await (_files[file] ??= _loadFile(file)
        .catchError((Object e) {
          _files.remove(file);
          throw e;
        }));
    final recipe = recipes[id];
    if (recipe == null ||
        recipe.cuisine != entry['cuisine'] ||
        recipe.servings != entry['servings']) {
      throw const FormatException('Recipe index/data mismatch');
    }
    return recipe;
  }

  Future<Map<String, CatalogRecipe>> _loadFile(String file) async {
    final json =
        jsonDecode(await _read('recipes/data/$file')) as Map<String, dynamic>;
    final result = <String, CatalogRecipe>{};
    for (final row in json['recipes'] as List) {
      final recipe = CatalogRecipe.fromJson(
        Map<String, dynamic>.from(row as Map),
      );
      if (result.containsKey(recipe.id)) {
        throw const FormatException('Duplicate recipe');
      }
      result[recipe.id] = recipe;
    }
    return Map.unmodifiable(result);
  }

  Future<List<CatalogRecipe>> loadAll() async =>
      Future.wait((await index).map((v) => get(v['id'] as String)));

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[ًٌٍَُِّْـ]'), '')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .trim();
}
