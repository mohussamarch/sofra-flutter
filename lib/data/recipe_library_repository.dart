import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';

import 'recipe_repository.dart';

Map<String, dynamic> _owned(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

class RecipeLibraryIngredient {
  const RecipeLibraryIngredient({
    required this.labelAr,
    required this.amount,
    required this.unit,
    required this.sourceQuantityText,
    this.optional = false,
    this.included,
    this.supplemental = false,
  });
  final String labelAr;
  final String? sourceQuantityText;
  final double? amount;
  final String? unit;
  final bool optional, supplemental;
  final bool? included;
  Map<String, dynamic> toJson() => {
    'labelAr': labelAr,
    'amount': amount,
    'unit': unit,
    'sourceQuantityText': sourceQuantityText,
    'optional': optional,
    'included': included,
    'supplemental': supplemental,
  };
}

class RecipeLibraryCuisine {
  RecipeLibraryCuisine({
    required this.id,
    required this.nameAr,
    required this.evidence,
    required Map<String, dynamic> source,
  }) : _source = _owned(source);
  final String id, nameAr, evidence;
  final Map<String, dynamic> _source;
  Map<String, dynamic> toJson() => _owned(_source);
}

/// Readable recipe evidence, never a planning or nutrition approval.
class RecipeLibraryEntry {
  RecipeLibraryEntry._({
    required this.id,
    required this.titleAr,
    required List<RecipeLibraryIngredient> ingredients,
    required List<String> stepsArabic,
    required List<String> sourceUrls,
    required List<RecipeLibraryCuisine> cuisineLabels,
    required this.familyId,
    required this.methodId,
    required Map<String, dynamic> sourceRecord,
    required Map<String, dynamic>? sourceSnapshot,
    required Map<String, dynamic> packMetadata,
  }) : ingredients = List.unmodifiable(ingredients),
       stepsArabic = List.unmodifiable(stepsArabic),
       sourceUrls = List.unmodifiable(sourceUrls),
       cuisineLabels = List.unmodifiable(cuisineLabels),
       _sourceRecord = _owned(sourceRecord),
       _sourceSnapshot = sourceSnapshot == null ? null : _owned(sourceSnapshot),
       _packMetadata = _owned(packMetadata);
  final String id, titleAr;
  final String? familyId, methodId;
  final List<RecipeLibraryIngredient> ingredients;
  final List<String> stepsArabic, sourceUrls;
  final List<RecipeLibraryCuisine> cuisineLabels;
  final Map<String, dynamic> _sourceRecord, _packMetadata;
  final Map<String, dynamic>? _sourceSnapshot;
  bool get runtimeReady => false;
  Object? get nutrition => null;
  Map<String, dynamic> get sourceRecord => _owned(_sourceRecord);
  Map<String, dynamic>? get sourceSnapshot =>
      _sourceSnapshot == null ? null : _owned(_sourceSnapshot);
  Map<String, dynamic> get packMetadata => _owned(_packMetadata);
  Map<String, dynamic> toJson() => {
    'id': id,
    'titleAr': titleAr,
    'ingredients': ingredients.map((v) => v.toJson()).toList(),
    'stepsArabic': List.of(stepsArabic),
    'sourceUrls': List.of(sourceUrls),
    'cuisineLabels': cuisineLabels.map((v) => v.toJson()).toList(),
    'familyId': familyId,
    'methodId': methodId,
    'runtimeReady': false,
    'nutrition': null,
    'sourceRecord': sourceRecord,
    'sourceSnapshot': sourceSnapshot,
    'packMetadata': packMetadata,
  };
}

/// A pinned, read-only cookbook. Integrity checks are not licence or food approval.
class RecipeLibraryRepository {
  RecipeLibraryRepository({
    required this.expectedManifestSha256,
    RecipeAssetReader? read,
    this.manifestPath = 'data/recipes/curated-local/flutter-manifest.json',
  }) : _read = read ?? rootBundle.loadString;
  final String expectedManifestSha256, manifestPath;
  final RecipeAssetReader _read;
  Future<List<RecipeLibraryEntry>>? _cached;

  Future<List<RecipeLibraryEntry>> all() =>
      _cached ??= _load().catchError((Object error) {
        _cached = null;
        throw error;
      });

  Future<List<RecipeLibraryEntry>> search(String query) async {
    final needle = _searchText(query);
    return List.unmodifiable(
      (await all()).where(
        (entry) => _searchText(
          '${entry.titleAr} ${entry.sourceRecord['name'] ?? ''} ${entry.ingredients.map((i) => i.labelAr).join(' ')}',
        ).contains(needle),
      ),
    );
  }

  Future<List<RecipeLibraryEntry>> filterByCuisine(String cuisine) async {
    final label = _searchText(cuisine);
    return List.unmodifiable(
      (await all()).where(
        (entry) => entry.cuisineLabels.any(
          (item) =>
              _searchText(item.id) == label ||
              _searchText(item.nameAr) == label,
        ),
      ),
    );
  }

  /// Only explicitly proposed local families; similarity never establishes one.
  Future<List<RecipeLibraryEntry>> familyCandidates(String familyId) async =>
      List.unmodifiable(
        (await all()).where((entry) => entry.familyId == familyId),
      );

  Future<Map<String, dynamic>> _readPinned(
    String path,
    String expectedSha,
  ) async {
    _safePath(path);
    _sha(expectedSha);
    final text = await _read(path);
    if (sha256.convert(utf8.encode(text)).toString() != expectedSha) {
      throw FormatException('Recipe library hash mismatch: $path');
    }
    final value = _map(jsonDecode(text), 'asset');
    if (value['schemaVersion'] != 1) {
      throw FormatException('Unsupported recipe library schema: $path');
    }
    return value;
  }

  Future<List<RecipeLibraryEntry>> _load() async {
    final manifest = await _readPinned(manifestPath, expectedManifestSha256);
    if (manifest['runtimeReady'] != false) {
      throw const FormatException('Cookbook cannot enable runtime recipes');
    }
    final entries = <RecipeLibraryEntry>[],
        ids = <String>{},
        packFiles = <String>{};
    for (final rawPack in _list(manifest['packs'], 'packs')) {
      final pack = _map(rawPack, 'pack'),
          kind = _text(_map(rawPack, 'pack')['kind'], 'pack kind');
      if (!{
        'curated-local',
        'creator-website',
        'creator-youtube',
      }.contains(kind)) {
        throw const FormatException('Unsupported recipe library kind');
      }
      final file = _text(pack['file'], 'pack file');
      _safePath(file);
      final prefix = kind == 'curated-local'
          ? 'data/recipes/curated-local/'
          : 'data/recipes/arabic-youtube/';
      if (!file.startsWith(prefix) || !packFiles.add(file)) {
        throw const FormatException('Duplicate or mismatched pack path');
      }
      final data = await _readPinned(file, _text(pack['sha256'], 'pack hash'));
      final snapshots = <String, Map<String, dynamic>>{},
          hashes = <String, String>{};
      for (final rawSource in _list(
        pack['sourceSnapshots'],
        'source snapshots',
      )) {
        final source = _map(rawSource, 'source snapshot');
        final path = _text(source['file'], 'snapshot file'),
            hash = _text(source['sha256'], 'snapshot hash');
        _safePath(path);
        if (kind != 'curated-local' ||
            !path.startsWith('data/recipes/curated-local/') ||
            hashes.containsKey(path) ||
            path == file) {
          throw const FormatException('Invalid or duplicate source snapshot');
        }
        hashes[path] = hash;
        snapshots[path] = await _readPinned(path, hash);
      }
      final usedSnapshots = <String>{};
      final metadata = Map<String, dynamic>.from(data)
        ..remove('recipes')
        ..remove('partialYoutubeRecipes');
      for (final rawRecipe in _list(data['recipes'], 'recipes')) {
        final row = _map(rawRecipe, 'recipe');
        Map<String, dynamic>? snapshot;
        if (kind == 'curated-local') {
          if (row['runtimeReady'] != false || row['nutrition'] != null) {
            throw const FormatException('Local cookbook approval changed');
          }
          final provenance = _map(row['provenance'], 'provenance');
          final path = _text(
            provenance['sourceSnapshotFile'],
            'provenance snapshot',
          );
          _safePath(path);
          snapshot = snapshots[path];
          if (snapshot == null ||
              provenance['sourceSnapshotSha256'] != hashes[path]) {
            throw const FormatException(
              'Undeclared or changed source snapshot',
            );
          }
          final original = _map(
            snapshot['sourceRecord'],
            'original source record',
          );
          for (final key in [
            'recordId',
            'sourceId',
            'sourceRevision',
            'sourceRevisionTimestamp',
            'sourceUrl',
            'sourceSha256',
            'license',
          ]) {
            if (!provenance.containsKey(key) ||
                !original.containsKey(key) ||
                !_sameJson(provenance[key], original[key])) {
              throw FormatException('Changed source provenance: $key');
            }
          }
          usedSnapshots.add(path);
        } else {
          if (row['sourceKind'] != kind ||
              row['runtimeReady'] == true ||
              row['nutrition'] != null) {
            throw const FormatException(
              'Creator cookbook source kind or approval mismatch',
            );
          }
        }
        if (kind == 'creator-website' &&
            row.containsKey('youtubeDerived') &&
            row['youtubeDerived'] != false) {
          throw const FormatException(
            'Website source cannot claim video derivation',
          );
        }
        if (kind == 'creator-youtube') {
          final id = row['sourceVideoId'];
          if (row['youtubeDerived'] != true ||
              id is! String ||
              !RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id) ||
              row['sourceUrl'] != 'https://www.youtube.com/watch?v=$id') {
            throw const FormatException('YouTube source identity mismatch');
          }
        }
        final entry = _entry(row, kind, snapshot, metadata);
        if (!ids.add(entry.id)) {
          throw const FormatException('Duplicate recipe library ID');
        }
        entries.add(entry);
      }
      if (usedSnapshots.length != snapshots.length) {
        throw const FormatException('Unused source snapshot manifest member');
      }
    }
    return List.unmodifiable(entries);
  }
}

RecipeLibraryEntry _entry(
  Map<String, dynamic> row,
  String kind,
  Map<String, dynamic>? snapshot,
  Map<String, dynamic> metadata,
) {
  final local = kind == 'curated-local';
  final ingredients = <RecipeLibraryIngredient>[];
  void ingredient(Object? raw, {bool supplemental = false}) {
    final value = _map(raw, 'ingredient'), amount = value['amount'];
    if (amount != null && (amount is! num || !amount.isFinite || amount < 0)) {
      throw const FormatException('Invalid source amount');
    }
    ingredients.add(
      RecipeLibraryIngredient(
        labelAr: _text(
          local
              ? value['nameAr'] ?? value['name']
              : value['labelAr'] ?? value['label'],
          'ingredient label',
        ),
        amount: (amount as num?)?.toDouble(),
        unit: _nullableText(value['unit'], 'ingredient unit'),
        sourceQuantityText: _nullableText(
          local ? value['sourceText'] : value['sourceQuantityText'],
          'source quantity text',
        ),
        optional: value['optional'] == true,
        included: value['included'] as bool?,
        supplemental: supplemental,
      ),
    );
  }

  for (final raw in _list(row['ingredients'], 'ingredients')) {
    ingredient(raw);
  }
  for (final raw in _list(
    row['supplementalIngredients'] ?? [],
    'supplemental ingredients',
  )) {
    ingredient(raw, supplemental: true);
  }
  final steps = _list(row['steps'], 'steps').map((raw) {
    final value = _map(raw, 'step');
    return _text(value['textAr'] ?? value['text'], 'step text');
  }).toList();
  if (ingredients.isEmpty || steps.isEmpty) {
    throw const FormatException('Cookbook record lacks ingredients or method');
  }
  final cuisines = <RecipeLibraryCuisine>[];
  if (local) {
    for (final raw in _list(row['cuisines'], 'cuisines')) {
      final value = _map(raw, 'cuisine'),
          provenance = _map(row['provenance'], 'provenance');
      if (value['sourceRecordId'] != provenance['recordId']) {
        throw const FormatException('Cuisine source mismatch');
      }
      cuisines.add(
        RecipeLibraryCuisine(
          id: _text(value['id'], 'cuisine id'),
          nameAr: _text(value['nameAr'], 'cuisine name'),
          evidence: _text(value['evidenceText'], 'cuisine evidence'),
          source: value,
        ),
      );
    }
  } else if (row['cuisine'] != null) {
    final value = _map(row['cuisine'], 'cuisine');
    if (value['value'] != null && value['evidence'] != null) {
      final label = _text(value['value'], 'cuisine label');
      cuisines.add(
        RecipeLibraryCuisine(
          id: label,
          nameAr: label,
          evidence: _text(value['evidence'], 'cuisine evidence'),
          source: value,
        ),
      );
    }
  }
  final provenance = local ? _map(row['provenance'], 'provenance') : row;
  final urls = <String>{_text(provenance['sourceUrl'], 'source URL')};
  if (row['evidenceUrl'] != null) {
    urls.add(_text(row['evidenceUrl'], 'evidence URL'));
  }
  return RecipeLibraryEntry._(
    id: _text(local ? row['id'] : row['recipeId'], 'recipe id'),
    titleAr: _text(
      local ? row['nameAr'] ?? row['name'] : row['title'],
      'recipe title',
    ),
    ingredients: ingredients,
    stepsArabic: steps,
    sourceUrls: urls.toList(),
    cuisineLabels: cuisines,
    familyId: local ? _nullableText(row['familyId'], 'family id') : null,
    methodId: local ? _nullableText(row['methodId'], 'method id') : null,
    sourceRecord: row,
    sourceSnapshot: snapshot,
    packMetadata: metadata,
  );
}

void _safePath(String path) {
  if (!RegExp(
        r'^data/recipes/(curated-local|arabic-youtube)/[A-Za-z0-9_./-]+\.json$',
      ).hasMatch(path) ||
      path.contains('..') ||
      path.contains('//') ||
      path.split('/').contains('.')) {
    throw FormatException('Unsafe recipe library path: $path');
  }
}

void _sha(String value) {
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) {
    throw const FormatException('Invalid recipe library SHA256');
  }
}

Map<String, dynamic> _map(Object? value, String field) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('Expected $field object');
  }
  return value;
}

List<dynamic> _list(Object? value, String field) {
  if (value is! List) throw FormatException('Expected $field list');
  return value;
}

String _text(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Expected $field text');
  }
  return value;
}

String? _nullableText(Object? value, String field) =>
    value == null ? null : _text(value, field);
String _searchText(String value) => value.trim().toLowerCase();
bool _sameJson(Object? first, Object? second) {
  if (first is Map && second is Map) {
    return first.length == second.length &&
        first.keys.every(
          (key) =>
              second.containsKey(key) && _sameJson(first[key], second[key]),
        );
  }
  if (first is List && second is List) {
    return first.length == second.length &&
        List.generate(
          first.length,
          (i) => i,
        ).every((i) => _sameJson(first[i], second[i]));
  }
  return first == second;
}
