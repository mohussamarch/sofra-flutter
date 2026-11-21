import 'dart:math' as math;

import '../l10n/l10n.dart';
import 'servings_engine.dart';

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
  CatalogStep.fromJson(
    Map<String, dynamic> json, {
    bool allowUnknownDuration = false,
  }) : number = (json['n'] as num).toInt(),
       text = _text(json['text'], 'step text'),
       minutes = json['duration'] == null && allowUnknownDuration
           ? null
           : _number(json['duration'], 'duration', zero: true),
       passive = json['passive'] == true,
       tip = json['tip'] as String?,
       videoStartSec = _second(json['videoStartSec']);
  final int number;
  final String text;
  final double? minutes;
  final bool passive;
  final String? tip;

  /// The second the step starts in the creator's video (see [RecipeVideo]);
  /// null when unknown or unsure.
  final int? videoStartSec;
  Map<String, dynamic> toJson() => {
    'n': number,
    'text': text,
    'duration': minutes,
    'passive': passive,
    'tip': tip,
    if (videoStartSec != null) 'videoStartSec': videoStartSec,
  };
}

/// A whole, non-negative count or second; anything else is unknown (these
/// source facts never make a recipe unreadable).
int? _second(Object? value) => value is int && value >= 0 ? value : null;

/// The creator's video a recipe comes from (docs/product/CREATORS-COMMUNITY.md).
/// Played embedded, never downloaded. Stats are a snapshot.
class RecipeVideo {
  const RecipeVideo({
    required this.platform,
    required this.id,
    required this.url,
    this.publishedAt,
    this.views,
    this.likes,
    this.thumbnailUrl,
    this.durationSec,
    this.recipeIndex = 1,
  });

  /// Null when [json] is not a usable video reference.
  static RecipeVideo? tryParse(Object? json) {
    if (json is! Map) return null;
    final platform = json['platform'];
    final id = json['id'];
    final url = json['url'];
    if (platform is! String ||
        id is! String ||
        id.isEmpty ||
        url is! String ||
        !url.startsWith('https://')) {
      return null;
    }
    final thumbnail = json['thumbnailUrl'];
    final published = json['publishedAt'];
    return RecipeVideo(
      platform: platform,
      id: id,
      url: url,
      publishedAt: published is String ? DateTime.tryParse(published) : null,
      views: _second(json['views']),
      likes: _second(json['likes']),
      thumbnailUrl: thumbnail is String && thumbnail.startsWith('https://')
          ? thumbnail
          : null,
      durationSec: _second(json['durationSec']),
      recipeIndex: _second(json['recipeIndex']) ?? 1,
    );
  }

  final String platform, id, url;
  final DateTime? publishedAt;
  final int? views, likes, durationSec;
  final String? thumbnailUrl;

  /// Which recipe of the video this is, when one video holds several.
  final int recipeIndex;

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'id': id,
    'url': url,
    'publishedAt': publishedAt?.toIso8601String().substring(0, 10),
    'views': views,
    'likes': likes,
    'thumbnailUrl': thumbnailUrl,
    'durationSec': durationSec,
    'recipeIndex': recipeIndex,
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
      metadataPolicy = json['metadataPolicy'] as String?,
      servings =
          json['servings'] == null &&
              json['metadataPolicy'] == unknownMetadataPolicy
          ? null
          : _number(json['servings'], 'servings').toInt(),
      prepMinutes =
          json['prepTime'] == null &&
              json['metadataPolicy'] == unknownMetadataPolicy
          ? null
          : _number(json['prepTime'], 'prepTime', zero: true),
      cookMinutes =
          json['cookTime'] == null &&
              json['metadataPolicy'] == unknownMetadataPolicy
          ? null
          : _number(json['cookTime'], 'cookTime', zero: true),
      ingredients = List.unmodifiable(
        (json['ingredients'] as List).map(
          (v) =>
              CatalogIngredient.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
      steps = List.unmodifiable(
        (json['steps'] as List).map(
          (v) => CatalogStep.fromJson(
            Map<String, dynamic>.from(v as Map),
            allowUnknownDuration:
                json['metadataPolicy'] == unknownMetadataPolicy,
          ),
        ),
      ),
      tags = List<String>.unmodifiable((json['tags'] as List).cast<String>()),
      notes = json['notes'] as String?,
      creatorId = _creator(json['creatorId']),
      video = RecipeVideo.tryParse(json['video']),
      storedServings = ServingsEstimate.fromJson(json) {
    final allowsUnknown = metadataPolicy == unknownMetadataPolicy;
    final rawSteps = json['steps'] as List;
    if ((metadataPolicy != null && !allowsUnknown) ||
        (allowsUnknown &&
            (!json.containsKey('servings') ||
                !json.containsKey('prepTime') ||
                !json.containsKey('cookTime') ||
                !json.containsKey('totalTime') ||
                rawSteps.any(
                  (v) =>
                      v is! Map ||
                      !Map<String, dynamic>.from(v).containsKey('duration'),
                ))) ||
        ((servings == null ||
                prepMinutes == null ||
                cookMinutes == null ||
                steps.any((step) => step.minutes == null)) &&
            (!allowsUnknown || notes == null || notes!.trim().isEmpty)) ||
        (servings != null && (servings! < 1 || servings != json['servings'])) ||
        ingredients.isEmpty ||
        steps.isEmpty) {
      throw const FormatException('Invalid recipe contents');
    }
    final total = json['totalTime'];
    if (prepMinutes == null || cookMinutes == null) {
      if (total != null) {
        throw const FormatException(
          'Unknown component times require unknown total',
        );
      }
    } else if (total is! num ||
        !total.isFinite ||
        total < 0 ||
        (prepMinutes! + cookMinutes! - total).abs() > 1e-6) {
      throw const FormatException('Recipe total time mismatch');
    }
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].number != i + 1) {
        throw const FormatException('Invalid step sequence');
      }
    }
  }

  /// Ingredients and yield only, from a catalog index row of the online
  /// library: for listing, search and stock matching. It has no steps,
  /// description or times; planning and cooking open the full recipe.
  CatalogRecipe.listing(Map<String, dynamic> row)
    : id = _text(row['id'], 'recipe id'),
      name = _text(row['name'], 'recipe name'),
      cuisine = _text(row['cuisine'], 'cuisine'),
      category = (row['category'] as String?) ?? '',
      description = '',
      difficulty = (row['difficulty'] as String?) ?? '',
      metadataPolicy = null,
      servings = row['servings'] == null
          ? null
          : _number(row['servings'], 'servings').toInt(),
      prepMinutes = null,
      cookMinutes = null,
      ingredients = List.unmodifiable(
        (row['ingredients'] as List).map(
          (v) =>
              CatalogIngredient.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
      steps = const [],
      tags = List<String>.unmodifiable(
        ((row['tags'] as List?) ?? const []).cast<String>(),
      ),
      notes = null,
      creatorId = _creator(row['creatorId']),
      video = null,
      storedServings = ServingsEstimate.fromJson(row);

  static String? _creator(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  final String id, name, cuisine, category, description, difficulty;
  static const unknownMetadataPolicy = 'source-unknowns-v1';
  final String? metadataPolicy;
  final int? servings;
  final double? prepMinutes, cookMinutes;

  /// The servings-engine fields written by the library build
  /// (tool/recipes/publish-library.mjs), when the recipe carries them.
  final ServingsEstimate? storedServings;

  static final _estimates = Expando<ServingsEstimate>('servings');

  /// The engine's verdict: the stored build-time fields, or computed here
  /// (recipes published before the fields existed, and the user's own).
  ServingsEstimate get servingsEstimate =>
      storedServings ??
      (_estimates[this] ??= ServingsEngine.shared.estimate(
        category: category,
        servings: servings,
        lines: [
          for (final i in ingredients)
            ServingsLine(
              id: i.id,
              name: i.name,
              amount: i.amount,
              unit: i.unit,
              optional: i.optional,
            ),
        ],
      ));

  /// How many people the whole recipe feeds, as the app scales it: the
  /// stated [servings] unless the library build rejected it as implausible
  /// (then the engine's number); without a stated value, the engine's number.
  /// A stated value is never overridden at runtime, so the user's own
  /// recipes and reviewed yields keep theirs.
  int? get effectiveServings {
    final stored = storedServings;
    if (servings != null) {
      if (stored != null &&
          stored.basis == ServingsBasisSource.computed &&
          stored.hasValue) {
        return stored.computed;
      }
      return servings;
    }
    final estimate = servingsEstimate;
    return estimate.hasValue ? estimate.computed : null;
  }

  /// Whether [effectiveServings] is the engine's number, not the source's.
  bool get servingsComputedByApp =>
      effectiveServings != null && effectiveServings != servings;

  bool get hasKnownYield => effectiveServings != null;
  bool get hasKnownTotalTime => prepMinutes != null && cookMinutes != null;
  bool get hasCompleteSchedule => steps.every((step) => step.minutes != null);
  double? get totalMinutes =>
      hasKnownTotalTime ? prepMinutes! + cookMinutes! : null;
  final List<CatalogIngredient> ingredients;
  final List<CatalogStep> steps;
  final List<String> tags;
  final String? notes;

  /// The creator who made the recipe (`yt:<channelId>`), when it comes from
  /// a creator's video; see creators.json in the online library.
  final String? creatorId;

  /// The source video, when the recipe comes from one.
  final RecipeVideo? video;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cuisine': cuisine,
    'category': category,
    'description': description,
    'difficulty': difficulty,
    if (metadataPolicy != null) 'metadataPolicy': metadataPolicy,
    'servings': servings,
    'prepTime': prepMinutes,
    'cookTime': cookMinutes,
    'totalTime': totalMinutes,
    'ingredients': ingredients.map((v) => v.toJson()).toList(),
    'steps': steps.map((v) => v.toJson()).toList(),
    'tags': tags.toList(),
    'notes': notes,
    if (creatorId != null) 'creatorId': creatorId,
    if (video != null) 'video': video!.toJson(),
    ...?storedServings?.toJson(),
  };

  ScaledCatalogRecipe forServings(int target, {int? sourceServings}) {
    if (target < 1 || target > 1000) {
      throw ArgumentError.value(target, 'servings');
    }
    final base = effectiveServings ?? sourceServings;
    if (base == null || base < 1 || base > 1000) {
      throw ArgumentError(
        'Explicit valid sourceServings required for unknown yield',
      );
    }
    return ScaledCatalogRecipe(this, target, base);
  }
}

class ScaledCatalogRecipe {
  ScaledCatalogRecipe(this.recipe, this.servings, [int? sourceServings])
    : sourceServings =
          recipe.effectiveServings ??
          sourceServings ??
          (throw ArgumentError('Explicit source yield required')) {
    if (servings < 1 ||
        servings > 1000 ||
        this.sourceServings < 1 ||
        this.sourceServings > 1000) {
      throw ArgumentError('Invalid target or source yield');
    }
  }
  final CatalogRecipe recipe;
  final int servings;
  final int sourceServings;
  double get factor => servings / sourceServings;
  double? quantity(CatalogIngredient ingredient) =>
      ingredient.quantityFor(factor);
  double? get prepMinutes => recipe.prepMinutes == null
      ? null
      : scaleRecipeMinutes(recipe.prepMinutes!, factor);
  double? get cookMinutes => recipe.cookMinutes == null
      ? null
      : scaleRecipeMinutes(recipe.cookMinutes!, factor);
  double? get totalMinutes => prepMinutes == null || cookMinutes == null
      ? null
      : prepMinutes! + cookMinutes!;
  List<RecipeScheduleStep> get schedule {
    if (!recipe.hasCompleteSchedule) {
      throw StateError(
        'Recipe schedule is incomplete because step durations are unknown',
      );
    }
    var cursor = 0.0;
    return List.unmodifiable(
      recipe.steps.map((step) {
        final duration = scaleRecipeMinutes(step.minutes!, factor);
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
      return ingredient.label ?? ingredient.note ?? L10n.current.dataToTaste;
    }
    if (ingredient.unit == _kilo && amount < 1) {
      return '${recipeNumber(roundRecipeAmount(amount * 1000, _gram))} '
          '${L10n.term(_gram)}';
    }
    final unit = ingredient.unit;
    return '${recipeNumber(amount)} ${unit == null ? '' : L10n.term(unit)}'
        .trim();
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

// Recipe units exactly as stored in recipes/data (Arabic data values).
const _kilo = 'كيلو'; // i18n-data
const _gram = 'جرام'; // i18n-data
const _quarterUnits = ['ملعقة صغيرة', 'ملعقة كبيرة', 'رشة']; // i18n-data
const _fineUnits = ['كوب', 'لتر', 'كيلو']; // i18n-data
const _metricUnits = ['جرام', 'مل']; // i18n-data
const _pieceUnits = [
  'حبة', // i18n-data
  'فص', // i18n-data
  'عود', // i18n-data
  'رغيف', // i18n-data
  'قرص', // i18n-data
  'ورقة', // i18n-data
  'حزمة', // i18n-data
];

/// Matches the corrected TypeScript library; display never supplies stock units.
double roundRecipeAmount(double amount, String? unit) {
  if (!amount.isFinite || amount < 0) {
    throw ArgumentError.value(amount, 'amount');
  }
  if (amount == 0) return 0;
  if (_quarterUnits.contains(unit)) {
    return amount < .25 ? .25 : _round((amount * 4).round() / 4, 3);
  }
  if (_fineUnits.contains(unit)) return _round(amount, 3);
  if (_metricUnits.contains(unit)) {
    return amount < 5
        ? _round((amount * 2).round() / 2, 2)
        : _round((amount / 5).round() * 5, 2);
  }
  if (_pieceUnits.contains(unit)) {
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
