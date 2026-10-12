import 'dart:convert';

import 'recipe_catalog.dart';

String _requiredText(String value) {
  if (value.trim().isEmpty) throw ArgumentError('Missing recipe identity');
  return value;
}

enum RecipeRevisionKind { catalog, variant, personal }

class RecipeFamily {
  RecipeFamily({required this.id, required this.name}) {
    _requiredText(id);
    _requiredText(name);
  }
  final String id, name;
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory RecipeFamily.fromJson(Map<String, dynamic> j) =>
      RecipeFamily(id: j['id'] as String, name: j['name'] as String);
}

/// A complete immutable revision: no live inheritance of ingredients or steps.
class RecipeRevision {
  RecipeRevision({
    required this.familyId,
    required this.revision,
    required this.kind,
    required CatalogRecipe recipe,
    this.parentKey,
    this.region,
    this.method,
  }) : recipe = CatalogRecipe.fromJson(recipe.toJson()) {
    _requiredText(familyId);
    _requiredText(revision);
    if (parentKey != null) _requiredText(parentKey!);
    if (kind == RecipeRevisionKind.personal && parentKey == null) {
      throw ArgumentError('Personal recipes require a source revision');
    }
    if (region != null) _requiredText(region!);
    if (method != null) _requiredText(method!);
  }
  final String familyId, revision;
  final RecipeRevisionKind kind;
  final CatalogRecipe recipe;
  final String? parentKey, region, method;
  String get variantId => recipe.id;
  String get key => jsonEncode([variantId, revision]);
  Map<String, dynamic> toJson() => {
    'version': 1,
    'familyId': familyId,
    'revision': revision,
    'kind': kind.name,
    'recipe': recipe.toJson(),
    'parentKey': parentKey,
    'region': region,
    'method': method,
  };
  factory RecipeRevision.fromJson(Map<String, dynamic> j) {
    if (j['version'] != 1) {
      throw const FormatException('Recipe revision schema');
    }
    return RecipeRevision(
      familyId: j['familyId'] as String,
      revision: j['revision'] as String,
      kind: RecipeRevisionKind.values.byName(j['kind'] as String),
      recipe: CatalogRecipe.fromJson(
        Map<String, dynamic>.from(j['recipe'] as Map),
      ),
      parentKey: j['parentKey'] as String?,
      region: j['region'] as String?,
      method: j['method'] as String?,
    );
  }
}

/// Append-only revisions, with an explicit current choice for future plans.
class RecipeBook {
  RecipeBook._(
    Map<String, RecipeFamily> families,
    Map<String, RecipeRevision> revisions,
    Map<String, String> active,
  ) : families = Map.unmodifiable(families),
      revisions = Map.unmodifiable(revisions),
      active = Map.unmodifiable(active) {
    for (final entry in this.revisions.entries) {
      final revision = entry.value;
      if (entry.key != revision.key ||
          !this.families.containsKey(revision.familyId)) {
        throw const FormatException('Invalid recipe revision/family reference');
      }
      final visited = <String>{revision.key};
      var parent = revision.parentKey;
      while (parent != null) {
        final source = this.revisions[parent];
        if (!visited.add(parent) ||
            source == null ||
            source.familyId != revision.familyId) {
          throw const FormatException('Missing, cyclic or cross-family source');
        }
        parent = source.parentKey;
      }
    }
    for (final e in this.active.entries) {
      if (this.revisions[e.value]?.variantId != e.key) {
        throw const FormatException('Invalid active recipe reference');
      }
    }
    final identity = <String, RecipeRevision>{};
    for (final revision in this.revisions.values) {
      final previous = identity[revision.variantId];
      if (previous != null &&
          (previous.familyId != revision.familyId ||
              previous.kind != revision.kind)) {
        throw const FormatException('Recipe variant identity changed');
      }
      identity[revision.variantId] = revision;
    }
  }
  factory RecipeBook.empty() => RecipeBook._({}, {}, {});
  final Map<String, RecipeFamily> families;
  final Map<String, RecipeRevision> revisions;
  final Map<String, String> active;

  RecipeBook addFamily(RecipeFamily family) {
    final previous = families[family.id];
    if (previous != null && previous.name != family.name) {
      throw StateError('Recipe family identity is immutable');
    }
    return RecipeBook._({...families, family.id: family}, revisions, active);
  }

  RecipeBook addRevision(RecipeRevision revision) {
    final previous = revisions[revision.key];
    if (previous != null) {
      if (jsonEncode(previous.toJson()) != jsonEncode(revision.toJson())) {
        throw StateError('Cannot overwrite a recipe revision');
      }
      return this; // An idempotent retry never rolls back the active choice.
    }
    return RecipeBook._(
      families,
      {...revisions, revision.key: revision},
      {...active, revision.variantId: revision.key},
    );
  }

  List<RecipeRevision> variants(String familyId) => List.unmodifiable([
    for (final key in active.values)
      if (revisions[key]!.familyId == familyId) revisions[key]!,
  ]);

  Map<String, dynamic> toJson() => {
    'version': 1,
    'families': {for (final e in families.entries) e.key: e.value.toJson()},
    'revisions': {for (final e in revisions.entries) e.key: e.value.toJson()},
    'active': Map<String, String>.from(active),
  };
  factory RecipeBook.fromJson(Map<String, dynamic> j) {
    if (j['version'] != 1) throw const FormatException('Recipe book schema');
    final families = (j['families'] as Map).map(
      (k, v) => MapEntry(
        k as String,
        RecipeFamily.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
    );
    if (families.entries.any((e) => e.key != e.value.id)) {
      throw const FormatException('Recipe family key mismatch');
    }
    return RecipeBook._(
      families,
      (j['revisions'] as Map).map(
        (k, v) => MapEntry(
          k as String,
          RecipeRevision.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
      Map<String, String>.from(j['active'] as Map),
    );
  }
}

/// Full content fingerprint for catalog snapshots, not a security signature.
String recipeSnapshotVersion(CatalogRecipe recipe) {
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = (BigInt.one << 64) - BigInt.one;
  for (final byte in utf8.encode(jsonEncode(recipe.toJson()))) {
    hash = ((hash ^ BigInt.from(byte)) * prime) & mask;
  }
  return 'snapshot-fnv1a64:${hash.toRadixString(16).padLeft(16, '0')}';
}
