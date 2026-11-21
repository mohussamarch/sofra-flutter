import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/recipe_catalog.dart';
import '../l10n/dish_name.dart';
import 'online_recipe_library.dart';

export 'online_recipe_library.dart' show RecipeNotOnDevice;

typedef RecipeAssetReader = Future<String> Function(String path);

/// The recipe catalog. With a [library] the catalog and recipes come from the
/// online library kept on the device (memory, then device, then network);
/// the recipes bundled in the app ([read], rootBundle by default) are the
/// offline seed: the catalog until the first download, and a recipe's text
/// when it is neither on the device nor reachable.
class RecipeRepository {
  RecipeRepository({RecipeAssetReader? read, this.library})
    : _read = read ?? rootBundle.loadString {
    library?.validateIndex = (text) => _parseIndex(text);
    library?.addListener(_libraryChanged);
  }

  /// The app's repository: online library on the device, bundled seed.
  factory RecipeRepository.online() => RecipeRepository(
    library: OnlineRecipeLibrary(store: PreferencesLibraryStore()),
  );

  final RecipeAssetReader _read;
  final OnlineRecipeLibrary? library;
  Future<List<Map<String, dynamic>>>? _index;
  final _files = <String, Future<Map<String, CatalogRecipe>>>{};
  final _seedRows = <String, Map<String, dynamic>>{};
  final _bodies = <String, Future<CatalogRecipe>>{};
  List<Map<String, dynamic>> _groups = const [];
  String? _updatedAt;
  int _seenGeneration = 0;

  /// Bumps when a newer catalog replaced the one on screen.
  int get catalogGeneration => library?.generation ?? 0;

  void _libraryChanged() {
    final generation = catalogGeneration;
    if (generation == _seenGeneration) return;
    _seenGeneration = generation;
    _index = null;
    _dishes = null;
    _ingredients = null;
    _listing = null;
    _bodies.clear();
  }

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

  /// The date the catalog in use was published (the bundled one's date
  /// before the first download).
  Future<DateTime?> get catalogDate async {
    final published = await library?.publishedAt();
    if (published != null) return published;
    await retainedIndex;
    return DateTime.tryParse(_updatedAt ?? '');
  }

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
    final online = library;
    if (online != null) {
      try {
        final text = await online.catalogIndex();
        if (text != null) return _use(_parseIndex(text));
      } on Object {
        // A downloaded catalog that no longer reads: use the bundled one.
      }
    }
    return _use(_parseIndex(await _read('recipes/data/index.json')));
  }

  List<Map<String, dynamic>> _use(_ParsedIndex parsed) {
    _groups = parsed.groups ?? _groups;
    _updatedAt = parsed.updatedAt;
    return parsed.entries;
  }

  /// Image references a row may carry (none are published yet): an https
  /// URL or a path under img/ on the library site.
  static final _image = RegExp(
    r'^(https://[^\s"]+|img/[A-Za-z0-9_./-]+\.(webp|jpg|jpeg|png))$',
  );
  static bool _validImage(Object? v) =>
      v is String && _image.hasMatch(v) && !v.contains('..');

  /// Images are an extra: a bad reference is dropped, never the catalog.
  static void _keepValidImages(Map<String, dynamic> row) {
    if (row.containsKey('thumbnail') && !_validImage(row['thumbnail'])) {
      row.remove('thumbnail');
    }
    final photos = row['photos'];
    if (photos != null) {
      final kept = photos is List
          ? photos.where(_validImage).cast<String>().toList()
          : const <String>[];
      if (kept.isEmpty) {
        row.remove('photos');
      } else {
        row['photos'] = List<String>.unmodifiable(kept);
      }
    }
  }

  /// The card image of a catalog row, resolved against the library site;
  /// null when the row has none. Load it only while the card is on screen.
  Uri? thumbnailOf(Map<String, dynamic> row) => _imageUri(row['thumbnail']);

  /// Step photos of a catalog row, resolved; load them only once the recipe
  /// is opened.
  List<Uri> photosOf(Map<String, dynamic> row) => [
    for (final p in (row['photos'] as List?) ?? const []) ?_imageUri(p),
  ];

  Uri? _imageUri(Object? ref) {
    if (!_validImage(ref)) return null;
    final text = ref as String;
    if (text.startsWith('https://')) return Uri.tryParse(text);
    return library?.baseUrl.resolve(text);
  }

  /// Parses and checks a catalog index; throws when the app cannot use it.
  static _ParsedIndex _parseIndex(String text) {
    final json = jsonDecode(text) as Map<String, dynamic>;
    final allowedFiles = (json['cuisines'] as List)
        .map((v) => v['file'] as String)
        .toSet();
    if (allowedFiles.any((v) => !RegExp(r'^[a-z]+\.json$').hasMatch(v))) {
      throw const FormatException('Invalid recipe asset path');
    }
    final ids = <String>{};
    final entries = (json['recipes'] as List)
        .map((v) {
          final row = Map<String, dynamic>.from(v as Map);
          _keepValidImages(row);
          // The reviewed English name wins over the catalog's own.
          if (DishName.of(row['id']) case final name?) {
            row['nameEn'] = name.en;
          }
          final body = row['body'];
          if (body != null &&
              (body is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(body))) {
            throw const FormatException('Invalid recipe body hash');
          }
          final lines = row['ingredients'];
          if (lines != null) {
            // Listing lines must read like the recipe's own.
            for (final line in lines as List) {
              CatalogIngredient.fromJson(
                Map<String, dynamic>.from(line as Map),
              );
            }
          }
          if (!ids.add(row['id'] as String) ||
              !allowedFiles.contains(row['file'])) {
            throw const FormatException(
              'Duplicate recipe or unknown cuisine file',
            );
          }
          return Map<String, dynamic>.unmodifiable(row);
        })
        .toList(growable: false);
    List<Map<String, dynamic>>? parsedGroups;
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
      parsedGroups = List.unmodifiable(groups);
    }
    return _ParsedIndex(
      List.unmodifiable(entries),
      allowedFiles,
      parsedGroups,
      json['updatedAt'] as String?,
    );
  }

  /// Saved recipes the catalog no longer has, as rows marked `pinnedOnly`:
  /// they list under the saved filter only and open from their pinned copy.
  Future<List<Map<String, dynamic>>> pinnedOnlyRows() async {
    final online = library;
    if (online == null) return const [];
    // Held rows are off the catalog too: a saved one lists from its pin.
    final known = {for (final r in await index) r['id'] as String};
    return [
      for (final e in (await online.pinnedRows()).entries)
        if (!known.contains(e.key))
          Map<String, dynamic>.unmodifiable({
            ...e.value,
            'id': e.key,
            // The reviewed English name, as for catalog rows.
            if (DishName.of(e.key) case final name?) 'nameEn': name.en,
            'pinnedOnly': true,
          }),
    ];
  }

  /// Recipes whose name, English name or tags match, then (after them) the
  /// ones that only use the searched word as an ingredient. Filters narrow
  /// both: a cuisine or group, a source category, a meal kind ([kindOf]) and a
  /// longest total time in minutes (unknown times never pass a time filter).
  /// Saved recipes the library dropped come last, marked `pinnedOnly`.
  Future<List<Map<String, dynamic>>> search({
    String query = '',
    String? cuisine,
    String? cuisineGroup,
    String? category,
    String? kind,
    int? maxMinutes,
  }) async {
    final needle = _normalize(query);
    bool passes(Map<String, dynamic> r) {
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
    }

    // Old English spellings of reviewed names still find the dish.
    bool named(Map<String, dynamic> r) => _normalize(
      '${r['name']} ${r['nameEn'] ?? ''} '
      '${DishName.of(r['id'])?.also.join(' ') ?? ''} '
      '${((r['tags'] as List?) ?? const []).join(' ')}',
    ).contains(needle);
    final rows = (await index).where(passes).toList();
    final pinned = (await pinnedOnlyRows())
        .where((r) => passes(r) && (needle.isEmpty || named(r)))
        .toList();
    if (needle.isEmpty) return List.unmodifiable([...rows, ...pinned]);
    final byName = rows.where(named).toList();
    final lines = await _ingredientText;
    final byIngredient = rows
        .where((r) => !named(r) && (lines[r['id']] ?? '').contains(needle))
        .toList();
    return List.unmodifiable([...byName, ...byIngredient, ...pinned]);
  }

  /// Every active recipe's ingredient names, normalized, for search.
  Future<Map<String, String>> get _ingredientText => _ingredients ??=
      () async {
        final all = await listingRecipes();
        return {
          for (final r in all)
            r.id: _normalize(r.ingredients.map((i) => i.name).join(' | ')),
        };
      }().catchError((Object e) {
        _ingredients = null;
        throw e;
      });
  Future<Map<String, String>>? _ingredients;

  /// Every active recipe's ingredients and yield, for search and stock
  /// matching: from the catalog index when it lists them (the online
  /// library), else from the full recipes (the bundled seed).
  Future<List<CatalogRecipe>> listingRecipes() => _listing ??=
      () async {
        final rows = await index;
        return List<CatalogRecipe>.unmodifiable(
          await Future.wait(
            rows.map(
              (r) async => r['ingredients'] is List
                  ? CatalogRecipe.listing(r)
                  : await get(r['id'] as String),
            ),
          ),
        );
      }().catchError((Object e) {
        _listing = null;
        throw e;
      });
  Future<List<CatalogRecipe>>? _listing;

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
          final online = await library?.catalogDishes();
          json = jsonDecode(
            online ?? await _read('recipes/data/dishes.json'),
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
              _dish(d as Map<String, dynamic>, active),
        ]);
      }().catchError((Object e) {
        _dishes = null;
        throw e;
      });
  Future<List<Dish>>? _dishes;

  static Dish _dish(Map<String, dynamic> d, Set<String> active) {
    final recipes = List<String>.unmodifiable(
      (d['recipes'] as List).cast<String>().where(active.contains),
    );
    // A dish whose ways all carry the same reviewed English name is called
    // by it (Sayadieh); otherwise it has no English name.
    final names = {for (final id in recipes) DishName.of(id)?.en};
    return Dish(
      id: d['id'] as String,
      name: d['name'] as String,
      nameEn: names.length == 1 ? names.single : null,
      recipes: recipes,
    );
  }

  /// The full recipe. Online: memory, the device, the network, an older copy
  /// on the device, then the bundled seed; [RecipeNotOnDevice] when none has
  /// it. A saved recipe the library dropped opens from its pinned copy.
  Future<CatalogRecipe> get(String id, {bool includeHeld = false}) async {
    final entries = (await retainedIndex).where((v) => v['id'] == id);
    if (entries.isEmpty) {
      final pinned = await library?.pinnedCopy(id);
      if (pinned != null) return _parseBody(pinned.body, id);
      throw ArgumentError.value(id, 'recipeId');
    }
    final entry = entries.single;
    if (!includeHeld && _held(entry)) {
      // Off the catalog now, but saved: the user's pinned copy still opens.
      final pinned = await library?.pinnedCopy(id);
      if (pinned != null) return _parseBody(pinned.body, id);
      throw StateError('Recipe cuisine requires review before new selection');
    }
    final sha = entry['body'];
    if (library != null && sha is String) {
      final key = '$id@$sha';
      final opened = _bodies[key];
      if (opened != null) {
        library!.touch(id);
        return opened;
      }
      return _bodies[key] = _online(entry, sha).catchError((Object e) {
        _bodies.remove(key);
        throw e;
      });
    }
    return _seed(entry);
  }

  Future<CatalogRecipe> _online(
    Map<String, dynamic> entry,
    String sha, {
    bool retried = false,
  }) async {
    final id = entry['id'] as String;
    final online = library!;
    try {
      final recipe = _parseBody(await online.body(id, sha), id);
      _matches(recipe, entry);
      return recipe;
    } on RecipeMoved {
      // A newer library replaced this body: take its catalog, then ask once
      // more with the new hash.
      if (!retried) {
        final generation = catalogGeneration;
        await online.update(force: true, retryRejected: false);
        if (catalogGeneration != generation) {
          _libraryChanged();
          final fresh = (await retainedIndex).where((v) => v['id'] == id);
          final next = fresh.isEmpty ? null : fresh.single['body'];
          if (next is String && next != sha) {
            return _online(fresh.single, next, retried: true);
          }
        }
      }
    } on Object {
      // Not on the device, offline, or an older copy that no longer fits
      // the catalog: the bundled recipe, when the app has it.
    }
    try {
      return await _seed(entry);
    } on Object {
      // Neither: a saved recipe opens from the user's pinned copy, even when
      // the catalog has changed it since.
    }
    final pinned = await online.pinnedCopy(id);
    if (pinned != null) {
      try {
        return _parseBody(pinned.body, id);
      } on Object {
        // A pinned copy that no longer reads.
      }
    }
    throw RecipeNotOnDevice(id);
  }

  /// A saved recipe whose pinned copy is older than the catalog's (restored
  /// from the account, or pinned from the bundled text) is pinned again from
  /// the current catalog when it can be fetched; otherwise the copy stays.
  Future<void> refreshPin(String id) async {
    final online = library;
    if (online == null) return;
    final entries = (await index).where((v) => v['id'] == id);
    final copy = await online.pinnedCopy(id);
    if (entries.isEmpty || copy == null) return;
    final sha = entries.single['body'];
    if (sha is! String || sha == copy.sha256) return;
    try {
      await pin(id);
    } on Object {
      // Offline: the older copy keeps working.
    }
  }

  static CatalogRecipe _parseBody(String text, String id) {
    final recipe = CatalogRecipe.fromJson(
      Map<String, dynamic>.from(jsonDecode(text) as Map),
    );
    if (recipe.id != id) throw const FormatException('Recipe id mismatch');
    return recipe;
  }

  static void _matches(CatalogRecipe recipe, Map<String, dynamic> entry) {
    if (recipe.cuisine != entry['cuisine'] ||
        recipe.servings != entry['servings']) {
      throw const FormatException('Recipe index/data mismatch');
    }
  }

  Future<CatalogRecipe> _seed(Map<String, dynamic> entry) async {
    final id = entry['id'] as String;
    final file = entry['file'] as String;
    final recipes = await (_files[file] ??= _loadFile(file)
        .catchError((Object e) {
          _files.remove(file);
          throw e;
        }));
    final recipe = recipes[id];
    if (recipe == null) {
      throw const FormatException('Recipe index/data mismatch');
    }
    _matches(recipe, entry);
    return recipe;
  }

  Future<Map<String, CatalogRecipe>> _loadFile(String file) async {
    final json =
        jsonDecode(await _read('recipes/data/$file')) as Map<String, dynamic>;
    final result = <String, CatalogRecipe>{};
    for (final row in json['recipes'] as List) {
      final raw = Map<String, dynamic>.from(row as Map);
      final recipe = CatalogRecipe.fromJson(raw);
      if (result.containsKey(recipe.id)) {
        throw const FormatException('Duplicate recipe');
      }
      result[recipe.id] = recipe;
      _seedRows[recipe.id] = raw;
    }
    return Map.unmodifiable(result);
  }

  /// Keeps a saved recipe's full text on the device (never evicted). Its
  /// text is the library's, or the bundled one's before the first download.
  /// Throws [RecipeNotOnDevice] when neither is at hand.
  Future<void> pin(String id) async {
    final online = library;
    if (online == null) return;
    final entries = (await retainedIndex).where((v) => v['id'] == id);
    if (entries.isEmpty) {
      if (await online.pinnedCopy(id) != null) return;
      throw RecipeNotOnDevice(id);
    }
    final entry = entries.single;
    final row = {
      for (final e in entry.entries)
        if (e.key != 'ingredients') e.key: e.value,
    };
    final sha = entry['body'];
    if (sha is String) {
      try {
        final text = await online.body(id, sha);
        _matches(_parseBody(text, id), entry);
        await online.pin(id, row, text);
        return;
      } on Object {
        // Fall back to the bundled text below.
      }
    }
    try {
      await _seed(entry);
    } on Object {
      throw RecipeNotOnDevice(id);
    }
    await online.pin(id, row, jsonEncode(_seedRows[id]));
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

class _ParsedIndex {
  const _ParsedIndex(this.entries, this.files, this.groups, this.updatedAt);
  final List<Map<String, dynamic>> entries;
  final Set<String> files;
  final List<Map<String, dynamic>>? groups;
  final String? updatedAt;
}

/// One dish with its ways of making it, each a catalog recipe id.
class Dish {
  const Dish({
    required this.id,
    required this.name,
    required this.recipes,
    this.nameEn,
  });
  final String id, name;

  /// The English name, when every way shares one reviewed name.
  final String? nameEn;
  final List<String> recipes;
}
