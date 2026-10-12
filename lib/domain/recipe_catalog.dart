import 'dart:math' as math;

double _number(Object? value, String field, {bool zero = false}) {
  if (value is! num || !value.isFinite || (zero ? value < 0 : value <= 0)) {
    throw FormatException('Invalid $field');
  }
  return value.toDouble();
}

String _text(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid $field');
  }
  return value.trim();
}

class CatalogIngredient {
  CatalogIngredient.fromJson(Map<String, dynamic> json)
    : id = _text(json['id'], 'ingredient id'),
      name = _text(json['name'], 'ingredient name'),
      amount = json['amount'] == null
          ? null
          : _number(json['amount'], 'amount'),
      unit = json['unit'] as String?,
      scales = json['scale'] != false,
      optional = json['optional'] == true,
      label = json['label'] as String?,
      display = json['display'] as String?,
      note = json['note'] as String? {
    if (amount != null && (unit == null || unit!.trim().isEmpty)) {
      throw const FormatException('Measured ingredients require a unit');
    }
    if (amount == null && scales) {
      throw const FormatException('Unmeasured ingredients must not scale');
    }
  }
  final String id, name;
  final double? amount;
  final String? unit, label, display, note;
  final bool scales, optional;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'unit': unit,
    'scale': scales,
    'optional': optional,
    'label': label,
    'display': display,
    'note': note,
  };

  double? quantityFor(double factor) => amount == null || !scales
      ? amount
      : roundRecipeAmount(amount! * factor, unit);
}

class CatalogStep {
  CatalogStep.fromJson(Map<String, dynamic> json)
    : number = (json['n'] as num).toInt(),
      text = _text(json['text'], 'step text'),
      minutes = _number(json['duration'], 'duration', zero: true),
      passive = json['passive'] == true,
      tip = json['tip'] as String?;
  final int number;
  final String text;
  final double minutes;
  final bool passive;
  final String? tip;
  Map<String, dynamic> toJson() => {
    'n': number,
    'text': text,
    'duration': minutes,
    'passive': passive,
    'tip': tip,
  };
}

class CatalogRecipe {
  CatalogRecipe.fromJson(Map<String, dynamic> json)
    : id = _text(json['id'], 'recipe id'),
      name = _text(json['name'], 'recipe name'),
      cuisine = _text(json['cuisine'], 'cuisine'),
      category = _text(json['category'], 'category'),
      description = _text(json['description'], 'description'),
      difficulty = _text(json['difficulty'], 'difficulty'),
      servings = _number(json['servings'], 'servings').toInt(),
      prepMinutes = _number(json['prepTime'], 'prepTime', zero: true),
      cookMinutes = _number(json['cookTime'], 'cookTime', zero: true),
      ingredients = List.unmodifiable(
        (json['ingredients'] as List).map(
          (v) =>
              CatalogIngredient.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
      steps = List.unmodifiable(
        (json['steps'] as List).map(
          (v) => CatalogStep.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
      tags = List<String>.unmodifiable((json['tags'] as List).cast<String>()),
      notes = json['notes'] as String? {
    if (servings < 1 ||
        servings != json['servings'] ||
        ingredients.isEmpty ||
        steps.isEmpty) {
      throw const FormatException('Invalid recipe contents');
    }
    if ((prepMinutes + cookMinutes - (json['totalTime'] as num)).abs() > 1e-6) {
      throw const FormatException('Recipe total time mismatch');
    }
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].number != i + 1) {
        throw const FormatException('Invalid step sequence');
      }
    }
  }
  final String id, name, cuisine, category, description, difficulty;
  final int servings;
  final double prepMinutes, cookMinutes;
  final List<CatalogIngredient> ingredients;
  final List<CatalogStep> steps;
  final List<String> tags;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cuisine': cuisine,
    'category': category,
    'description': description,
    'difficulty': difficulty,
    'servings': servings,
    'prepTime': prepMinutes,
    'cookTime': cookMinutes,
    'totalTime': prepMinutes + cookMinutes,
    'ingredients': ingredients.map((v) => v.toJson()).toList(),
    'steps': steps.map((v) => v.toJson()).toList(),
    'tags': tags.toList(),
    'notes': notes,
  };

  ScaledCatalogRecipe forServings(int target) {
    if (target < 1 || target > 1000) {
      throw ArgumentError.value(target, 'servings');
    }
    return ScaledCatalogRecipe(this, target);
  }
}

class ScaledCatalogRecipe {
  ScaledCatalogRecipe(this.recipe, this.servings);
  final CatalogRecipe recipe;
  final int servings;
  double get factor => servings / recipe.servings;
  double? quantity(CatalogIngredient ingredient) =>
      ingredient.quantityFor(factor);
  double get prepMinutes => scaleRecipeMinutes(recipe.prepMinutes, factor);
  double get cookMinutes => scaleRecipeMinutes(recipe.cookMinutes, factor);
  double get totalMinutes => prepMinutes + cookMinutes;
  List<RecipeScheduleStep> get schedule {
    var cursor = 0.0;
    return List.unmodifiable(
      recipe.steps.map((step) {
        final duration = scaleRecipeMinutes(step.minutes, factor);
        final start = cursor;
        cursor += duration;
        return RecipeScheduleStep(step, start, cursor);
      }),
    );
  }

  String display(CatalogIngredient ingredient) {
    if (ingredient.display != null) return ingredient.display!;
    final amount = quantity(ingredient);
    if (amount == null) {
      return ingredient.label ?? ingredient.note ?? 'حسب الرغبة';
    }
    if (ingredient.unit == 'كيلو' && amount < 1) {
      return '${recipeNumber(roundRecipeAmount(amount * 1000, 'جرام'))} جرام';
    }
    return '${recipeNumber(amount)} ${ingredient.unit ?? ''}'.trim();
  }
}

class RecipeScheduleStep {
  const RecipeScheduleStep(this.step, this.start, this.end);
  final CatalogStep step;
  final double start, end;
  double get minutes => end - start;
  bool get outsideSession => minutes == 0;
}

double _round(double value, int places) {
  final p = math.pow(10, places);
  return (value * p + 2.220446049250313e-16).round() / p;
}

/// Matches the corrected TypeScript library; display never supplies stock units.
double roundRecipeAmount(double amount, String? unit) {
  if (!amount.isFinite || amount < 0) {
    throw ArgumentError.value(amount, 'amount');
  }
  if (amount == 0) return 0;
  if (['ملعقة صغيرة', 'ملعقة كبيرة', 'رشة'].contains(unit)) {
    return amount < .25 ? .25 : _round((amount * 4).round() / 4, 3);
  }
  if (['كوب', 'لتر', 'كيلو'].contains(unit)) return _round(amount, 3);
  if (['جرام', 'مل'].contains(unit)) {
    return amount < 5
        ? _round((amount * 2).round() / 2, 2)
        : _round((amount / 5).round() * 5, 2);
  }
  if (['حبة', 'فص', 'عود', 'رغيف', 'قرص', 'ورقة', 'حزمة'].contains(unit)) {
    return math.max(.5, _round((amount * 2).round() / 2, 2));
  }
  return _round(amount, 2);
}

double scaleRecipeMinutes(double minutes, double factor) {
  if (!minutes.isFinite || minutes < 0 || !factor.isFinite || factor <= 0) {
    throw ArgumentError('Invalid minutes/factor');
  }
  if (minutes == 0) return 0;
  return math
      .max(
        1,
        (minutes * (factor <= 1 ? math.max(factor, .5) : math.sqrt(factor)))
            .round(),
      )
      .toDouble();
}

String recipeNumber(double value) {
  final fractions = <double, String>{
    .125: '⅛',
    .25: '¼',
    .375: '⅜',
    .5: '½',
    .625: '⅝',
    .75: '¾',
    .875: '⅞',
  };
  final whole = value.floor();
  final fraction = value - whole;
  if (fraction < .015) return '$whole';
  for (final entry in fractions.entries) {
    if ((fraction - entry.key).abs() < .02) {
      return '${whole == 0 ? '' : whole}${entry.value}';
    }
  }
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}
