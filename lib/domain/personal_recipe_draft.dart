import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'food_nutrition.dart';

/// Exact caller-owned ingredient input; no identity or quantity is inferred.
class PersonalRecipeLine {
  PersonalRecipeLine({
    required this.id,
    required this.name,
    required RecipeFoodInput input,
    this.scales = true,
  }) : input = _ownedInput(input.toJson()) {
    _text(id, 'line id');
    _text(name, 'line name');
    if (id != this.input.ingredientId) {
      throw ArgumentError('Line and nutrition ingredient IDs must match');
    }
  }

  final String id, name;
  final RecipeFoodInput input;
  final bool scales;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'scales': scales,
    'input': input.toJson(),
  };

  factory PersonalRecipeLine.fromJson(Map<String, dynamic> json) => _decode(() {
    _keys(json, const ['id', 'name', 'scales', 'input']);
    if (json['scales'] is! bool) {
      throw const FormatException('Line scaling must be explicit');
    }
    return PersonalRecipeLine(
      id: json['id'] as String,
      name: json['name'] as String,
      scales: json['scales'] as bool,
      input: _ownedInput(_map(json['input'])),
    );
  });
}

/// An immutable private draft, separate from recipe catalog/plans/history.
/// Optional metadata and incomplete nutrition inputs remain unknown.
class PersonalRecipeDraft {
  PersonalRecipeDraft({
    required this.id,
    required this.revision,
    required this.name,
    required this.servings,
    required DateTime createdAt,
    required List<PersonalRecipeLine> lines,
    this.cuisine,
    this.prepMinutes,
    this.cookMinutes,
    List<String> instructions = const [],
    this.note,
  }) : createdAt = createdAt.toUtc(),
       lines = List.unmodifiable(
         lines.map((line) => PersonalRecipeLine.fromJson(line.toJson())),
       ),
       instructions = List.unmodifiable(instructions) {
    _text(id, 'draft id');
    _text(revision, 'draft revision');
    _text(name, 'draft name');
    _positive(servings, 'servings');
    if (cuisine != null) _text(cuisine!, 'cuisine');
    if (note != null) _text(note!, 'note');
    for (final minutes in [prepMinutes, cookMinutes]) {
      if (minutes != null && minutes < 0) {
        throw ArgumentError('Timing must be nonnegative when provided');
      }
    }
    for (final step in instructions) {
      _text(step, 'instruction');
    }
    if (this.lines.isEmpty ||
        this.lines.map((line) => line.id).toSet().length != this.lines.length) {
      throw ArgumentError('Draft requires nonempty unique ingredient lines');
    }
  }

  final String id, revision, name;
  final double servings;
  final DateTime createdAt;
  final List<PersonalRecipeLine> lines;
  final String? cuisine, note;
  final int? prepMinutes, cookMinutes;
  final List<String> instructions;

  String get key => jsonEncode([id, revision]);

  /// Local consistency pin: sha256-utf8-dart-typed-json-sorted-object-keys.
  /// Sort object keys recursively; preserve list order and optional nulls.
  /// This checks local content consistency, never source approval.
  String get fingerprint =>
      sha256.convert(utf8.encode(jsonEncode(_sortedJson(toJson())))).toString();

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'id': id,
    'revision': revision,
    'name': name,
    'servings': servings,
    'createdAt': createdAt.toIso8601String(),
    'lines': lines.map((line) => line.toJson()).toList(),
    'cuisine': cuisine,
    'prepMinutes': prepMinutes,
    'cookMinutes': cookMinutes,
    'instructions': instructions.toList(),
    'note': note,
  };

  factory PersonalRecipeDraft.fromJson(Map<String, dynamic> json) =>
      _decode(() {
        _keys(json, const [
          'schemaVersion',
          'id',
          'revision',
          'name',
          'servings',
          'createdAt',
          'lines',
          'cuisine',
          'prepMinutes',
          'cookMinutes',
          'instructions',
          'note',
        ]);
        if (json['schemaVersion'] is! int || json['schemaVersion'] != 1) {
          throw const FormatException('Unsupported private draft schema');
        }
        final at = DateTime.parse(json['createdAt'] as String);
        if (!at.isUtc || json['createdAt'] != at.toIso8601String()) {
          throw const FormatException('Draft timestamp must be canonical UTC');
        }
        return PersonalRecipeDraft(
          id: json['id'] as String,
          revision: json['revision'] as String,
          name: json['name'] as String,
          servings: (json['servings'] as num).toDouble(),
          createdAt: at,
          lines: (json['lines'] as List)
              .map((line) => PersonalRecipeLine.fromJson(_map(line)))
              .toList(),
          cuisine: json['cuisine'] as String?,
          prepMinutes: json['prepMinutes'] as int?,
          cookMinutes: json['cookMinutes'] as int?,
          instructions: (json['instructions'] as List).cast<String>(),
          note: json['note'] as String?,
        );
      });

  /// Input estimate only. A cooked measurement is never reinterpreted as raw.
  RecipeNutritionResult previewIngredients({double? servings}) =>
      _preview(servings: servings, ingredientOnly: true);

  /// Cooking remains unknown unless exact form/retention inputs support it.
  RecipeNutritionResult previewCooked({
    double? servings,
    double? cookedYieldGrams,
  }) => _preview(servings: servings, cookedYieldGrams: cookedYieldGrams);

  RecipeNutritionResult _preview({
    double? servings,
    double? cookedYieldGrams,
    bool ingredientOnly = false,
  }) {
    final portions = servings ?? this.servings;
    _positive(portions, 'preview servings');
    final factor = portions / this.servings;
    return calculateRecipeNutrition(
      recipeId: id,
      recipeVersion: revision,
      portions: portions,
      cookedYieldGrams: cookedYieldGrams,
      inputs: lines.map((line) {
        final input = line.input;
        return RecipeFoodInput(
          ingredientId: line.id,
          food: input.food,
          amount: input.amount == null
              ? null
              : FoodAmount(
                  value: input.amount!.value * (line.scales ? factor : 1),
                  unit: input.amount!.unit,
                ),
          amountForm: input.amountForm,
          preparedForm: ingredientOnly
              ? input.food?.form ?? input.preparedForm
              : input.preparedForm,
          quantityEstimated: input.quantityEstimated,
          optional: input.optional,
          selected: input.selected,
          asPurchased: input.asPurchased,
          preparation: ingredientOnly ? null : input.preparation,
        );
      }).toList(),
    );
  }
}

Object? _sortedJson(Object? value) {
  if (value is Map<String, dynamic>) {
    final keys = value.keys.toList()..sort();
    return {for (final key in keys) key: _sortedJson(value[key])};
  }
  if (value is List) return value.map(_sortedJson).toList();
  return value;
}

RecipeFoodInput _ownedInput(Map<String, dynamic> json) {
  final owned = _map(jsonDecode(jsonEncode(json)));
  final input = RecipeFoodInput.fromJson(owned);
  // Legacy food parsers have permissive defaults. Require the complete typed
  // representation here, including explicit booleans, nulls and known fields.
  if (!_sameJson(owned, input.toJson())) {
    throw const FormatException('Incomplete or malformed explicit food input');
  }
  return input;
}

bool _sameJson(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((key) => b.containsKey(key) && _sameJson(a[key], b[key]));
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        List.generate(
          a.length,
          (index) => index,
        ).every((index) => _sameJson(a[index], b[index]));
  }
  return a == b;
}

Map<String, dynamic> _map(Object? value) =>
    Map<String, dynamic>.from(value as Map);

void _keys(Map<String, dynamic> json, List<String> fields) {
  if (json.length != fields.length ||
      fields.any((field) => !json.containsKey(field))) {
    throw const FormatException('Unexpected or missing draft fields');
  }
}

T _decode<T>(T Function() read) {
  try {
    return read();
  } on FormatException {
    rethrow;
  } on Object {
    throw const FormatException('Malformed private recipe draft');
  }
}

void _text(String value, String field) {
  if (value.trim().isEmpty) throw ArgumentError('Missing $field');
}

void _positive(double value, String field) {
  if (!value.isFinite || value <= 0) throw ArgumentError('Invalid $field');
}
