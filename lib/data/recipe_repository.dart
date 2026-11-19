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
  List<Map<String, dynamic>> _groups = const [];

  /// Fifteen primary groups and one secondary group; recipes retain origins.
  Future<List<Map<String, dynamic>>> get cuisineGroups async {
    await retainedIndex;
    return _groups;
  }

  /// Retains historical IDs and source work even when cuisine review is pending.
  Future<List<Map<String, dynamic>>> get retainedIndex =>
      _index ??= _loadIndex().catchError((Object e) {
        _index = null;
        throw e;
      });

  Future<List<Map<String, dynamic>>> get index async =>
      List.unmodifiable((await retainedIndex).where((row) => !_held(row)));

  static bool hasConcreteCuisine(String value) =>
      value.trim().isNotEmpty &&
      !const {
        'غير محدد', // i18n-data
        'عالمي متنوع', // i18n-data
        'آسيوي', // i18n-data
        'أمريكي جنوبي', // i18n-data
      }.contains(value);

  static bool _held(Map<String, dynamic> row) =>
      row['catalogStatus'] == 'held-cuisine' ||
      // Needs pork or alcohol: off the catalog by the owner's decision.
      row['catalogStatus'] == 'held-content' ||
      row['cuisine'] is! String ||
      !hasConcreteCuisine(row['cuisine'] as String);

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
    if (json['cuisineGroups'] != null) {
      final groups = (json['cuisineGroups'] as List)
          .map(
            (v) => Map<String, dynamic>.unmodifiable({
              ...v as Map<String, dynamic>,
              'members': List<String>.unmodifiable(v['members'] as List),
            }),
          )
          .toList();
      if (groups.length != 16 ||
          groups.last['id'] != 'other' ||
          groups.map((g) => g['id']).toSet().length != 16) {
        throw const FormatException(
          'Exactly15 primary cuisines plus other required',
        );
      }
      for (var i = 0; i < 15; i++) {
        if (groups[i]['kind'] != 'primary' || groups[i]['order'] != i + 1) {
          throw const FormatException('Invalid primary cuisine order');
        }
      }
      final allMembers = <String>{};
      for (final group in groups) {
        final members = group['members'] as List<String>;
        if (group['id'] is! String ||
            (group['id'] as String).trim().isEmpty ||
            group['name'] is! String ||
            (group['name'] as String).trim().isEmpty ||
            members.any((m) => !hasConcreteCuisine(m) || !allMembers.add(m))) {
          throw const FormatException(
            'Invalid or duplicate cuisine membership',
          );
        }
        final rows = entries
            .where((r) => !_held(r) && r['cuisineGroup'] == group['id'])
            .toList();
        if (group['count'] != rows.length ||
            rows.any((r) => !members.contains(r['cuisine']))) {
          throw const FormatException('Cuisine group count or origin mismatch');
        }
      }
      final ids = groups.map((g) => g['id']).toSet();
      if (entries.any(
        (r) => _held(r)
            ? r['cuisineGroup'] != null
            : r['catalogStatus'] != 'active' ||
                  !ids.contains(r['cuisineGroup']),
      )) {
        throw const FormatException(
          'Unclassified or unmapped cuisine membership',
        );
      }
      _groups = List.unmodifiable(groups);
    }
    return List.unmodifiable(entries);
  }

  /// Recipes whose name, English name or tags match, then (after them) the
  /// ones that only use the searched word as an ingredient. Filters narrow
  /// both: a cuisine or group, a source category, a meal kind ([kindOf]) and a
  /// longest total time in minutes (unknown times never pass a time filter).
  Future<List<Map<String, dynamic>>> search({
    String query = '',
    String? cuisine,
    String? cuisineGroup,
    String? category,
    String? kind,
    int? maxMinutes,
  }) async {
    final needle = _normalize(query);
    final rows = (await index).where((r) {
      if (cuisine != null && r['cuisine'] != cuisine) return false;
      if (cuisineGroup != null && r['cuisineGroup'] != cuisineGroup) {
        return false;
      }
      if (category != null && r['category'] != category) return false;
      if (kind != null && kindOf(r['category'] as String?) != kind) {
        return false;
      }
      if (maxMinutes != null) {
        final t = r['totalTime'];
        if (t is! num || t > maxMinutes) return false;
      }
      return true;
    }).toList();
    if (needle.isEmpty) return List.unmodifiable(rows);
    bool named(Map<String, dynamic> r) => _normalize(
      '${r['name']} ${r['nameEn'] ?? ''} ${(r['tags'] as List).join(' ')}',
    ).contains(needle);
    final byName = rows.where(named).toList();
    final lines = await _ingredientText;
    final byIngredient = rows
        .where((r) => !named(r) && (lines[r['id']] ?? '').contains(needle))
        .toList();
    return List.unmodifiable([...byName, ...byIngredient]);
  }

  /// Every active recipe's ingredient names, normalized, for search.
  Future<Map<String, String>> get _ingredientText => _ingredients ??=
      () async {
        final all = await loadAll();
        return {
          for (final r in all)
            r.id: _normalize(r.ingredients.map((i) => i.name).join(' | ')),
        };
      }().catchError((Object e) {
        _ingredients = null;
        throw e;
      });
  Future<Map<String, String>>? _ingredients;

  /// Meal kinds shown as filters, in display order.
  static const kinds = [
    'رئيسي', // i18n-data
    'فطار', // i18n-data
    'شوربة', // i18n-data
    'سلطة ومقبلات', // i18n-data
    'حلويات', // i18n-data
    'مخبوزات', // i18n-data
  ];

  /// Words that mark a baked-goods source category (normalized Arabic).
  static const _bakedWords = ['مخبوز', 'خبز', 'معجنات', 'عجين']; // i18n-data

  /// The meal kind of a source category, or null when it fits none (sauces,
  /// drinks, spice mixes, unknown).
  static String? kindOf(String? category) {
    final c = _normalize(category ?? '');
    if (c.contains('رئيسي') || c.contains('جانبي')) return 'رئيسي'; // i18n-data
    if (c.contains('فطار') || c.contains('فطور')) return 'فطار'; // i18n-data
    if (c.contains('شورب') || c.contains('حساء')) return 'شوربة'; // i18n-data
    final salad = c.contains('سلط') || c.contains('مقبلات'); // i18n-data
    if (salad) return 'سلطة ومقبلات'; // i18n-data
    if (c.contains('حلو')) return 'حلويات'; // i18n-data
    if (_bakedWords.any(c.contains)) return 'مخبوزات'; // i18n-data
    return null;
  }

  /// Dishes made several ways (countries or methods), from the reviewed
  /// recipes/data/dishes.json. Only active recipes count; a dish with fewer
  /// than two left is dropped.
  Future<List<Dish>> get dishes => _dishes ??=
      () async {
        final active = {for (final r in await index) r['id'] as String};
        final Map<String, dynamic> json;
        try {
          json = jsonDecode(
            await _read('recipes/data/dishes.json'),
          ) as Map<String, dynamic>;
        } on Object {
          // Grouping is an extra: without the file every recipe stands alone.
          return const <Dish>[];
        }
        final list = json['dishes'];
        if (list is! List) return const <Dish>[];
        return List<Dish>.unmodifiable([
          for (final d in list)
            if ((d['recipes'] as List).where(active.contains).length >= 2)
              Dish(
                id: d['id'] as String,
                name: d['name'] as String,
                recipes: List.unmodifiable(
                  (d['recipes'] as List).cast<String>().where(active.contains),
                ),
              ),
        ]);
      }().catchError((Object e) {
        _dishes = null;
        throw e;
      });
  Future<List<Dish>>? _dishes;

  Future<CatalogRecipe> get(String id, {bool includeHeld = false}) async {
    final entries = (await retainedIndex).where((v) => v['id'] == id);
    if (entries.isEmpty) throw ArgumentError.value(id, 'recipeId');
    final entry = entries.single;
    if (!includeHeld && _held(entry)) {
      throw StateError('Recipe cuisine requires review before new selection');
    }
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

  Future<List<CatalogRecipe>> loadAll({bool includeHeld = false}) async =>
      Future.wait(
        (await (includeHeld ? retainedIndex : index)).map(
          (v) => get(v['id'] as String, includeHeld: includeHeld),
        ),
      );

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[ًٌٍَُِّْـ]'), '') // i18n-data
      .replaceAll(RegExp('[أإآ]'), 'ا') // i18n-data
      .replaceAll('ى', 'ي') // i18n-data
      .replaceAll('ة', 'ه') // i18n-data
      .trim();
}

/// One dish with its ways of making it, each a catalog recipe id.
class Dish {
  const Dish({required this.id, required this.name, required this.recipes});
  final String id, name;
  final List<String> recipes;
}
