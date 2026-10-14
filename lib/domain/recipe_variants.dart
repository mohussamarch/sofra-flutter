import 'dart:convert';

import 'recipe_catalog.dart';
import 'imported_recipe_candidate.dart';

String _requiredText(String value) {
  if (value.trim().isEmpty) throw ArgumentError('Missing recipe identity');
  return value;
}

enum RecipeRevisionKind { catalog, variant, personal, imported }

String sourceImportFamilyId(ImportedRecipeCandidate candidate) =>
    'source:${jsonEncode([candidate.sourceId, candidate.sourceRecipeId])}';
String sourceImportRevisionId(ImportedRecipeCandidate candidate) =>
    'transport-sha256:${candidate.transportSha256}';

/// Caller review evidence. Nutrition/measurement/retention remain unapproved.
class SourceRecipeImportReview {
  SourceRecipeImportReview({
    required ImportedRecipeCandidate candidate,
    required this.note,
    required DateTime reviewedAt,
    required this.acknowledgeSourceLicenseAndInstructions,
    required this.acknowledgeNutritionUnreviewed,
  }) : candidate = ImportedRecipeCandidate.fromJson(candidate.toJson()),
       reviewedAt = reviewedAt.toUtc() {
    _requiredText(note);
    if (!acknowledgeSourceLicenseAndInstructions ||
        !acknowledgeNutritionUnreviewed) {
      throw ArgumentError(
        'Explicit source/license/instructions and unknown nutrition review required',
      );
    }
  }
  final ImportedRecipeCandidate candidate;
  final String note;
  final DateTime reviewedAt;
  final bool acknowledgeSourceLicenseAndInstructions,
      acknowledgeNutritionUnreviewed;
  Map<String, dynamic> toJson() => {
    'version': 1,
    'candidate': candidate.toJson(),
    'note': note,
    'reviewedAt': reviewedAt.toIso8601String(),
    'acknowledgeSourceLicenseAndInstructions':
        acknowledgeSourceLicenseAndInstructions,
    'acknowledgeNutritionUnreviewed': acknowledgeNutritionUnreviewed,
  };
  factory SourceRecipeImportReview.fromJson(Map<String, dynamic> j) {
    const fields = [
      'version',
      'candidate',
      'note',
      'reviewedAt',
      'acknowledgeSourceLicenseAndInstructions',
      'acknowledgeNutritionUnreviewed',
    ];
    if (j['version'] != 1 ||
        j.length != fields.length ||
        !fields.every(j.containsKey)) {
      throw const FormatException('Source import review schema');
    }
    final stamp = j['reviewedAt'] as String;
    final date = DateTime.parse(stamp);
    if (!stamp.endsWith('Z') ||
        stamp.length < 20 ||
        date.toUtc().toIso8601String().substring(0, 19) !=
            stamp.substring(0, 19)) {
      throw const FormatException('Invalid source review UTC date');
    }
    return SourceRecipeImportReview(
      candidate: ImportedRecipeCandidate.fromJson(
        Map<String, dynamic>.from(j['candidate'] as Map),
      ),
      note: j['note'] as String,
      reviewedAt: date,
      acknowledgeSourceLicenseAndInstructions:
          j['acknowledgeSourceLicenseAndInstructions'] as bool,
      acknowledgeNutritionUnreviewed:
          j['acknowledgeNutritionUnreviewed'] as bool,
    );
  }
}

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

/// User review evidence, not source-authored recipe facts or inferred split ratios.
class IngredientSplitReview {
  IngredientSplitReview({
    required this.sourceRevisionKey,
    required this.sourceSnapshotVersion,
    required this.line,
    required List<CatalogIngredient> components,
    required this.note,
    required DateTime reviewedAt,
  }) : components = List.unmodifiable(
         components.map((v) => CatalogIngredient.fromJson(v.toJson())),
       ),
       reviewedAt = reviewedAt.toUtc() {
    _requiredText(sourceRevisionKey);
    _requiredText(sourceSnapshotVersion);
    _requiredText(note);
    if (line < 0 ||
        this.components.length < 2 ||
        this.components.any((v) => v.amount == null) ||
        this.components.map((v) => v.id).toSet().length !=
            this.components.length) {
      throw ArgumentError(
        'Complete split requires2+distinct quantified components',
      );
    }
  }
  final String sourceRevisionKey, sourceSnapshotVersion, note;
  final int line;
  final List<CatalogIngredient> components;
  final DateTime reviewedAt;
  Map<String, dynamic> toJson() => {
    'version': 1,
    'sourceRevisionKey': sourceRevisionKey,
    'sourceSnapshotVersion': sourceSnapshotVersion,
    'line': line,
    'components': components.map((v) => v.toJson()).toList(),
    'note': note,
    'reviewedAt': reviewedAt.toIso8601String(),
  };
  factory IngredientSplitReview.fromJson(Map<String, dynamic> j) {
    if (j['version'] != 1) {
      throw const FormatException('Ingredient split review version');
    }
    return IngredientSplitReview(
      sourceRevisionKey: j['sourceRevisionKey'] as String,
      sourceSnapshotVersion: j['sourceSnapshotVersion'] as String,
      line: j['line'] as int,
      components: (j['components'] as List)
          .map(
            (v) =>
                CatalogIngredient.fromJson(Map<String, dynamic>.from(v as Map)),
          )
          .toList(),
      note: j['note'] as String,
      reviewedAt: DateTime.parse(j['reviewedAt'] as String),
    );
  }
}

/// Caller-reviewed single replacement, not culinary equivalence or a food binding.
class IngredientChoiceReview {
  IngredientChoiceReview({
    required this.sourceRevisionKey,
    required this.sourceSnapshotVersion,
    required this.line,
    required CatalogIngredient selected,
    required this.note,
    required DateTime reviewedAt,
  }) : selected = CatalogIngredient.fromJson(selected.toJson()),
       reviewedAt = reviewedAt.toUtc() {
    _requiredText(sourceRevisionKey);
    _requiredText(sourceSnapshotVersion);
    _requiredText(note);
    if (line < 0 || this.selected.amount == null) {
      throw ArgumentError('Explicit quantified single choice required');
    }
  }
  final String sourceRevisionKey, sourceSnapshotVersion, note;
  final int line;
  final CatalogIngredient selected;
  final DateTime reviewedAt;
  Map<String, dynamic> toJson() => {
    'version': 1,
    'sourceRevisionKey': sourceRevisionKey,
    'sourceSnapshotVersion': sourceSnapshotVersion,
    'line': line,
    'selected': selected.toJson(),
    'note': note,
    'reviewedAt': reviewedAt.toIso8601String(),
  };
  factory IngredientChoiceReview.fromJson(Map<String, dynamic> j) {
    if (j['version'] != 1) {
      throw const FormatException('Ingredient choice review version');
    }
    return IngredientChoiceReview(
      sourceRevisionKey: j['sourceRevisionKey'] as String,
      sourceSnapshotVersion: j['sourceSnapshotVersion'] as String,
      line: j['line'] as int,
      selected: CatalogIngredient.fromJson(
        Map<String, dynamic>.from(j['selected'] as Map),
      ),
      note: j['note'] as String,
      reviewedAt: DateTime.parse(j['reviewedAt'] as String),
    );
  }
}

RecipeRevision buildIngredientChoiceRevision({
  required RecipeRevision source,
  required int line,
  required CatalogIngredient selected,
  required String variantId,
  required String revision,
  required String reviewNote,
  required DateTime reviewedAt,
  required bool acknowledgeCompleteReplacement,
}) {
  if (!acknowledgeCompleteReplacement) {
    throw ArgumentError(
      'Explicit single replacement/instruction review required',
    );
  }
  if (line < 0 || line >= source.recipe.ingredients.length) {
    throw RangeError('Source ingredient line');
  }
  final review = IngredientChoiceReview(
    sourceRevisionKey: source.key,
    sourceSnapshotVersion: recipeSnapshotVersion(source.recipe),
    line: line,
    selected: selected,
    note: reviewNote,
    reviewedAt: reviewedAt,
  );
  if (review.selected.id == source.recipe.ingredients[line].id) {
    throw ArgumentError('Choice cannot retain replaced unresolved identity');
  }
  final recipe = CatalogRecipe.fromJson({
    ...source.recipe.toJson(),
    'id': variantId,
    'ingredients': [
      ...source.recipe.ingredients.take(line).map((v) => v.toJson()),
      review.selected.toJson(),
      ...source.recipe.ingredients.skip(line + 1).map((v) => v.toJson()),
    ],
  });
  return RecipeRevision(
    familyId: source.familyId,
    revision: revision,
    kind: RecipeRevisionKind.personal,
    parentKey: source.key,
    region: source.region,
    method: source.method,
    recipe: recipe,
    ingredientChoiceReview: review,
  );
}

RecipeRevision buildIngredientSplitRevision({
  required RecipeRevision source,
  required int line,
  required List<CatalogIngredient> components,
  required String variantId,
  required String revision,
  required String reviewNote,
  required DateTime reviewedAt,
  required bool acknowledgeCompleteReplacement,
}) {
  if (!acknowledgeCompleteReplacement) {
    throw ArgumentError(
      'Explicit complete replacement/instruction review required',
    );
  }
  if (line < 0 || line >= source.recipe.ingredients.length) {
    throw RangeError('Source ingredient line');
  }
  final review = IngredientSplitReview(
    sourceRevisionKey: source.key,
    sourceSnapshotVersion: recipeSnapshotVersion(source.recipe),
    line: line,
    components: components,
    note: reviewNote,
    reviewedAt: reviewedAt,
  );
  if (review.components.any(
    (v) => v.id == source.recipe.ingredients[line].id,
  )) {
    throw ArgumentError(
      'Split components cannot retain the replaced compound identity',
    );
  }
  final recipe = CatalogRecipe.fromJson({
    ...source.recipe.toJson(),
    'id': variantId,
    'ingredients': [
      ...source.recipe.ingredients.take(line).map((v) => v.toJson()),
      ...review.components.map((v) => v.toJson()),
      ...source.recipe.ingredients.skip(line + 1).map((v) => v.toJson()),
    ],
  });
  return RecipeRevision(
    familyId: source.familyId,
    revision: revision,
    kind: RecipeRevisionKind.personal,
    parentKey: source.key,
    region: source.region,
    method: source.method,
    recipe: recipe,
    ingredientSplitReview: review,
  );
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
    this.ingredientSplitReview,
    this.ingredientChoiceReview,
    this.sourceImportReview,
  }) : recipe = CatalogRecipe.fromJson(recipe.toJson()) {
    _requiredText(familyId);
    _requiredText(revision);
    if (parentKey != null) _requiredText(parentKey!);
    if (kind == RecipeRevisionKind.personal && parentKey == null) {
      throw ArgumentError('Personal recipes require a source revision');
    }
    if (ingredientSplitReview != null &&
        (kind != RecipeRevisionKind.personal ||
            parentKey != ingredientSplitReview!.sourceRevisionKey)) {
      throw ArgumentError(
        'Split review must reference its personal revision parent',
      );
    }
    if (ingredientChoiceReview != null &&
        (kind != RecipeRevisionKind.personal ||
            parentKey != ingredientChoiceReview!.sourceRevisionKey ||
            ingredientSplitReview != null)) {
      throw ArgumentError(
        'Choice review must reference its personal revision parent and cannot also split',
      );
    }
    if (kind == RecipeRevisionKind.imported) {
      final review = sourceImportReview;
      if (review == null ||
          parentKey != null ||
          ingredientSplitReview != null ||
          ingredientChoiceReview != null ||
          region != null ||
          method != null ||
          familyId != sourceImportFamilyId(review.candidate) ||
          revision != sourceImportRevisionId(review.candidate) ||
          jsonEncode(this.recipe.toJson()) !=
              jsonEncode(review.candidate.recipe.toJson())) {
        throw ArgumentError(
          'Imported root must preserve exact source candidate, lineage and transport revision',
        );
      }
    } else if (sourceImportReview != null) {
      throw ArgumentError(
        'Source import evidence belongs only to an imported root',
      );
    }
    if (region != null) _requiredText(region!);
    if (method != null) _requiredText(method!);
  }
  final String familyId, revision;
  final RecipeRevisionKind kind;
  final CatalogRecipe recipe;
  final String? parentKey, region, method;
  final IngredientSplitReview? ingredientSplitReview;
  final IngredientChoiceReview? ingredientChoiceReview;
  final SourceRecipeImportReview? sourceImportReview;
  String get variantId => recipe.id;
  String get key => jsonEncode([variantId, revision]);
  Map<String, dynamic> toJson() => {
    'version': 1,
    'familyId': familyId,
    'revision': revision,
    'kind': kind.name,
    'recipe': recipe.toJson(),
    'parentKey': parentKey,
    'ingredientSplitReview': ingredientSplitReview?.toJson(),
    'ingredientChoiceReview': ingredientChoiceReview?.toJson(),
    'sourceImportReview': sourceImportReview?.toJson(),
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
      ingredientSplitReview: j['ingredientSplitReview'] == null
          ? null
          : IngredientSplitReview.fromJson(
              Map<String, dynamic>.from(j['ingredientSplitReview'] as Map),
            ),
      ingredientChoiceReview: j['ingredientChoiceReview'] == null
          ? null
          : IngredientChoiceReview.fromJson(
              Map<String, dynamic>.from(j['ingredientChoiceReview'] as Map),
            ),
      sourceImportReview: j['sourceImportReview'] == null
          ? null
          : SourceRecipeImportReview.fromJson(
              Map<String, dynamic>.from(j['sourceImportReview'] as Map),
            ),
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
    for (final revision in this.revisions.values) {
      final review = revision.ingredientSplitReview;
      if (review == null) continue;
      final source = this.revisions[review.sourceRevisionKey]!;
      if (review.sourceSnapshotVersion !=
              recipeSnapshotVersion(source.recipe) ||
          review.line >= source.recipe.ingredients.length ||
          review.components.any(
            (v) => v.id == source.recipe.ingredients[review.line].id,
          )) {
        throw const FormatException('Stale or invalid compound split source');
      }
      final expected = CatalogRecipe.fromJson({
        ...source.recipe.toJson(),
        'id': revision.variantId,
        'ingredients': [
          ...source.recipe.ingredients.take(review.line).map((v) => v.toJson()),
          ...review.components.map((v) => v.toJson()),
          ...source.recipe.ingredients
              .skip(review.line + 1)
              .map((v) => v.toJson()),
        ],
      });
      if (jsonEncode(expected.toJson()) !=
          jsonEncode(revision.recipe.toJson())) {
        throw const FormatException(
          'Unreviewed changes outside ingredient split',
        );
      }
    }
    for (final revision in this.revisions.values) {
      final review = revision.ingredientChoiceReview;
      if (review == null) continue;
      final source = this.revisions[review.sourceRevisionKey]!;
      if (review.sourceSnapshotVersion !=
              recipeSnapshotVersion(source.recipe) ||
          revision.region != source.region ||
          revision.method != source.method ||
          review.line >= source.recipe.ingredients.length ||
          review.selected.id == source.recipe.ingredients[review.line].id) {
        throw const FormatException(
          'Stale or invalid ingredient choice source',
        );
      }
      final expected = CatalogRecipe.fromJson({
        ...source.recipe.toJson(),
        'id': revision.variantId,
        'ingredients': [
          ...source.recipe.ingredients.take(review.line).map((v) => v.toJson()),
          review.selected.toJson(),
          ...source.recipe.ingredients
              .skip(review.line + 1)
              .map((v) => v.toJson()),
        ],
      });
      if (jsonEncode(expected.toJson()) !=
          jsonEncode(revision.recipe.toJson())) {
        throw const FormatException(
          'Unreviewed changes outside ingredient choice',
        );
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
