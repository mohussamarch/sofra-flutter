import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'food_nutrition.dart';
import 'personal_recipe_draft.dart';
import 'recipe_catalog.dart';
import 'recipe_nutrition.dart';

/// Explicit private authoring review, never nutrition or scientific approval.
/// The complete original draft remains the source snapshot for this recipe.
class PersonalRecipeFinalization {
  PersonalRecipeFinalization({
    required PersonalRecipeDraft draft,
    required this.category,
    required this.description,
    required this.difficulty,
    required List<double> stepMinutes,
    required Map<String, String> ingredientIds,
    required this.reviewNote,
    required DateTime reviewedAt,
    required this.acknowledgeInstructionsAndInputs,
    required this.acknowledgeNutritionIncomplete,
  }) : draft = PersonalRecipeDraft.fromJson(draft.toJson()),
       stepMinutes = List.unmodifiable(stepMinutes),
       ingredientIds = Map.unmodifiable(ingredientIds),
       reviewedAt = reviewedAt.toUtc() {
    if (!acknowledgeInstructionsAndInputs || !acknowledgeNutritionIncomplete) {
      throw ArgumentError(
        'Explicit instructions/inputs and incomplete nutrition acknowledgements required',
      );
    }
    for (final text in [category, description, difficulty, reviewNote]) {
      _normalized(text);
    }
    final owned = this.draft;
    _normalized(owned.name);
    if (owned.cuisine == null ||
        owned.prepMinutes == null ||
        owned.cookMinutes == null ||
        owned.instructions.isEmpty ||
        owned.servings != owned.servings.truncateToDouble()) {
      throw ArgumentError(
        'Complete explicit recipe metadata and whole servings required',
      );
    }
    _normalized(owned.cuisine!);
    for (final text in owned.instructions) {
      _normalized(text);
    }
    if (this.stepMinutes.length != owned.instructions.length ||
        this.stepMinutes.any((v) => !v.isFinite || v < 0)) {
      throw ArgumentError('Exact finite nonnegative step durations required');
    }
    if (this.ingredientIds.length != owned.lines.length ||
        owned.lines.any((line) => !this.ingredientIds.containsKey(line.id))) {
      throw ArgumentError(
        'Exact inventory ingredient IDs required for all lines',
      );
    }
    for (final line in owned.lines) {
      _normalized(line.name);
      _normalized(this.ingredientIds[line.id]!);
      if ((line.input.amount == null && line.scales) ||
          line.input.quantityEstimated) {
        throw ArgumentError(
          'Unmeasured lines must be fixed; estimated quantities need a separate reviewed representation',
        );
      }
      final amount = line.input.amount;
      // Catalog scaling rounds supported unit names; never change base inputs.
      if (line.scales &&
          amount != null &&
          roundRecipeAmount(amount.value, amount.unit.name) != amount.value) {
        throw ArgumentError(
          'Scalable amount exceeds current catalog precision',
        );
      }
      if (_categoryPreparation(line.input.preparation)) {
        throw ArgumentError(
          'Category preparation acceptance requires review for the new recipe scope',
        );
      }
    }
    recipe = CatalogRecipe.fromJson({
      'id': recipeId,
      'name': owned.name,
      'cuisine': owned.cuisine,
      'category': category,
      'description': description,
      'difficulty': difficulty,
      'servings': owned.servings.toInt(),
      'prepTime': owned.prepMinutes,
      'cookTime': owned.cookMinutes,
      'totalTime': owned.prepMinutes! + owned.cookMinutes!,
      'ingredients': [
        for (final line in owned.lines)
          {
            'id': this.ingredientIds[line.id],
            'name': line.name,
            'amount': line.input.amount?.value,
            'unit': line.input.amount?.unit.name,
            'scale': line.scales,
            'optional': line.input.optional,
            'label': null,
            'display': null,
            'note': null,
          },
      ],
      'steps': [
        for (var i = 0; i < owned.instructions.length; i++)
          {
            'n': i + 1,
            'text': owned.instructions[i],
            'duration': this.stepMinutes[i],
            'passive': false,
            'tip': null,
          },
      ],
      'tags': <String>[],
      'notes': owned.note,
    });
  }

  final PersonalRecipeDraft draft;
  final String category, description, difficulty, reviewNote;
  final List<double> stepMinutes;
  final Map<String, String> ingredientIds;
  final DateTime reviewedAt;
  final bool acknowledgeInstructionsAndInputs, acknowledgeNutritionIncomplete;
  late final CatalogRecipe recipe;

  String get recipeId => 'personal:${jsonEncode([draft.id])}';
  String get familyId => 'personal-dish:${jsonEncode([draft.id])}';
  String get revisionId => 'personal-sha256:$fingerprint';

  /// sha256-utf8-dart-typed-json-sorted-object-keys, ordered lists retained.
  /// Hash the owned typed authoring/review payload, before derived recipe/IDs.
  String get fingerprint => sha256
      .convert(utf8.encode(jsonEncode(_canonical(_payload()))))
      .toString();

  Map<String, dynamic> _payload() => {
    'version': 1,
    'draft': draft.toJson(),
    'category': category,
    'description': description,
    'difficulty': difficulty,
    'stepMinutes': stepMinutes.toList(),
    'ingredientIds': Map<String, String>.from(ingredientIds),
    'reviewNote': reviewNote,
    'reviewedAt': reviewedAt.toIso8601String(),
    'acknowledgeInstructionsAndInputs': acknowledgeInstructionsAndInputs,
    'acknowledgeNutritionIncomplete': acknowledgeNutritionIncomplete,
  };

  Map<String, dynamic> toJson() => _map(
    _canonical({
      ..._payload(),
      'recipe': recipe.toJson(),
      'recipeId': recipeId,
      'familyId': familyId,
      'revisionId': revisionId,
      'fingerprint': fingerprint,
    }),
  );

  factory PersonalRecipeFinalization.fromJson(Map<String, dynamic> json) {
    try {
      if (json['version'] is! int ||
          json['version'] != 1 ||
          json['acknowledgeInstructionsAndInputs'] is! bool ||
          json['acknowledgeNutritionIncomplete'] is! bool) {
        throw const FormatException(
          'Invalid finalization version or acknowledgements',
        );
      }
      final at = DateTime.parse(json['reviewedAt'] as String);
      if (!at.isUtc || at.toIso8601String() != json['reviewedAt']) {
        throw const FormatException(
          'Finalization review timestamp must be canonical UTC',
        );
      }
      final rebuilt = PersonalRecipeFinalization(
        draft: PersonalRecipeDraft.fromJson(_map(json['draft'])),
        category: json['category'] as String,
        description: json['description'] as String,
        difficulty: json['difficulty'] as String,
        stepMinutes: (json['stepMinutes'] as List)
            .map((v) => (v as num).toDouble())
            .toList(),
        ingredientIds: Map<String, String>.from(json['ingredientIds'] as Map),
        reviewNote: json['reviewNote'] as String,
        reviewedAt: at,
        acknowledgeInstructionsAndInputs:
            json['acknowledgeInstructionsAndInputs'] as bool,
        acknowledgeNutritionIncomplete:
            json['acknowledgeNutritionIncomplete'] as bool,
      );
      if (!_same(json, rebuilt.toJson())) {
        throw const FormatException(
          'Finalization snapshot or derived identity mismatch',
        );
      }
      return rebuilt;
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('Malformed personal recipe finalization');
    }
  }

  /// Exact reviewed food snapshots only; meal optional choices remain explicit.
  List<RecipeFoodSelection> selectionsFor(String recipeRevisionKey) {
    if (recipeRevisionKey.trim().isEmpty) {
      throw ArgumentError('Missing recipe revision key');
    }
    return List.unmodifiable([
      for (var i = 0; i < draft.lines.length; i++)
        if (draft.lines[i].input.food != null)
          RecipeFoodSelection(
            recipeId: recipeId,
            recipeRevisionKey: recipeRevisionKey,
            line: i,
            food: draft.lines[i].input.food!,
            amountForm: draft.lines[i].input.amountForm,
            preparedForm: draft.lines[i].input.preparedForm,
            preparation: draft.lines[i].input.preparation,
            asPurchased: draft.lines[i].input.asPurchased,
          ),
    ]);
  }
}

void _normalized(String value) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw ArgumentError('Explicit normalized nonempty recipe text required');
  }
}

bool _categoryPreparation(PreparationTransform? transform) {
  if (transform == null) return false;
  const kind = 'accepted-category-preparation-estimate';
  return transform.id.startsWith('$kind:') ||
      (transform.evidence != null &&
          (jsonDecode(transform.evidence!) as Map)['kind'] == kind);
}

Map<String, dynamic> _map(Object? value) =>
    Map<String, dynamic>.from(value as Map);

Object? _canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: _canonical(value[key])};
  }
  if (value is List) return value.map(_canonical).toList();
  return value;
}

bool _same(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((k) => b.containsKey(k) && _same(a[k], b[k]));
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_same(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
