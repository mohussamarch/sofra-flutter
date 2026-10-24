import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'models.dart';

/// One canonical kitchen-stock ingredient from
/// `data/ingredients/vocabulary.json`. The zone is a storage suggestion only.
class IngredientEntry {
  const IngredientEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultUnit,
    required this.aliases,
    required this.zone,
  });

  final String id, name, category, defaultUnit;
  final List<String> aliases;
  final StorageZone zone;

  factory IngredientEntry.fromJson(Map<String, Object?> json) {
    String text(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Ingredient field "$key" is missing', json);
      }
      return value;
    }

    final zoneName = text('zone');
    final zone = StorageZone.values.where((z) => z.name == zoneName);
    if (zone.isEmpty) {
      throw FormatException('Unknown storage zone "$zoneName"', json);
    }
    final aliases = json['aliases'];
    if (aliases is! List || aliases.any((a) => a is! String)) {
      throw FormatException('Ingredient aliases must be strings', json);
    }
    return IngredientEntry(
      id: text('id'),
      name: text('name'),
      category: text('category'),
      defaultUnit: text('defaultUnit'),
      aliases: List.unmodifiable(aliases.cast<String>()),
      zone: zone.single,
    );
  }
}

/// Canonical ingredient vocabulary plus the generated rawId -> canonicalId
/// map (`tool/ingredients/build-directory.mjs`). Used for kitchen stock only.
class IngredientDirectory {
  IngredientDirectory._(this._entries, this._byId, this._idMap);

  static const vocabularyPath = 'data/ingredients/vocabulary.json';
  static const directoryPath = 'data/ingredients/directory.json';

  final List<IngredientEntry> _entries;
  final Map<String, IngredientEntry> _byId;
  final Map<String, String> _idMap;

  static Future<IngredientDirectory> load(
    Future<String> Function(String path) read,
  ) async {
    final results = await Future.wait([
      read(vocabularyPath),
      read(directoryPath),
    ]);
    final vocabularyText = results[0].replaceAll('\r\n', '\n');
    final directory = jsonDecode(results[1]);
    if (directory is! Map<String, Object?> || directory['version'] != 1) {
      throw const FormatException('Unsupported ingredient directory version');
    }
    final digest = sha256.convert(utf8.encode(vocabularyText)).toString();
    if (directory['vocabularySha256'] != digest) {
      throw const FormatException(
        'Ingredient directory is stale for the current vocabulary',
      );
    }

    final raw = jsonDecode(vocabularyText);
    if (raw is! List) {
      throw const FormatException('Ingredient vocabulary must be a list');
    }
    final entries = <IngredientEntry>[];
    final byId = <String, IngredientEntry>{};
    final terms = <String, String>{};
    for (final item in raw) {
      if (item is! Map<String, Object?>) {
        throw const FormatException('Ingredient entry must be an object');
      }
      final entry = IngredientEntry.fromJson(item);
      if (byId.containsKey(entry.id)) {
        throw FormatException('Duplicate ingredient id "${entry.id}"');
      }
      for (final term in [entry.name, ...entry.aliases]) {
        final key = normalizeArabic(term);
        final owner = terms[key];
        if (owner != null && owner != entry.id) {
          throw FormatException(
            'Ingredient alias "$term" is shared by $owner and ${entry.id}',
          );
        }
        terms[key] = entry.id;
      }
      byId[entry.id] = entry;
      entries.add(entry);
    }

    final idMapRaw = directory['idMap'];
    if (idMapRaw is! Map<String, Object?>) {
      throw const FormatException('Ingredient directory idMap is missing');
    }
    final idMap = <String, String>{};
    for (final MapEntry(:key, :value) in idMapRaw.entries) {
      if (value is! String || !byId.containsKey(value)) {
        throw FormatException('idMap["$key"] points to unknown "$value"');
      }
      idMap[key] = value;
    }
    return IngredientDirectory._(
      List.unmodifiable(entries),
      Map.unmodifiable(byId),
      Map.unmodifiable(idMap),
    );
  }

  List<IngredientEntry> get entries => _entries;

  IngredientEntry? entry(String id) => _byId[id];

  /// The stock identity for a recipe line's ingredient id.
  String stockId(String rawId) => _idMap[rawId] ?? rawId;

  /// Arabic-normalized substring search over names and aliases. Name matches
  /// come before alias-only matches (exact before partial within each);
  /// otherwise vocabulary order is kept.
  List<IngredientEntry> search(String q) {
    final query = normalizeArabic(q);
    if (query.isEmpty) return const [];
    final ranked = <List<IngredientEntry>>[[], [], [], []];
    for (final entry in _entries) {
      final name = normalizeArabic(entry.name);
      final aliases = entry.aliases.map(normalizeArabic);
      if (name == query) {
        ranked[0].add(entry);
      } else if (name.contains(query)) {
        ranked[1].add(entry);
      } else if (aliases.contains(query)) {
        ranked[2].add(entry);
      } else if (aliases.any((a) => a.contains(query))) {
        ranked[3].add(entry);
      }
    }
    return [for (final group in ranked) ...group];
  }

  /// Alef variants to ا, ة to ه, ى to ي, tashkeel and tatweel removed.
  static String normalizeArabic(String value) => value
      .replaceAll(RegExp('[ً-ٰٟـ]'), '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
