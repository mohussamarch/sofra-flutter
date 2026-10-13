import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/food_nutrition.dart';
import 'food_repository.dart';

String _text(dynamic v) {
  if (v is! String || v.trim().isEmpty) {
    throw const FormatException('Missing measure evidence');
  }
  return v;
}

double _positive(dynamic v) {
  if (v is! num || !v.isFinite || v <= 0) {
    throw const FormatException('Invalid source portion quantity');
  }
  return v.toDouble();
}

class HouseholdMeasureOption {
  HouseholdMeasureOption._(Map<String, dynamic> j)
    : id = _text(j['id']),
      sourcePortionIndex = j['sourcePortionIndex'] as int,
      amount = _positive(j['amount']),
      gramWeight = _positive(j['gramWeight']),
      measureUnit = _text(j['measureUnit']),
      modifier = j['modifier'] as String?,
      description = j['description'] as String?,
      label = _text(j['label']),
      rationale = _text(j['rationale']) {
    if (sourcePortionIndex < 0 ||
        [
          measureUnit,
          modifier,
          description,
        ].any((v) => v?.toUpperCase().contains('RACC') == true)) {
      throw const FormatException('Unusable source portion');
    }
  }
  final String id, measureUnit, label, rationale;
  final String? modifier, description;
  final int sourcePortionIndex;
  final double amount, gramWeight;
}

class HouseholdMeasureReview {
  HouseholdMeasureReview._(Map<String, dynamic> j)
    : foodId = _text(j['foodId']),
      version = _text(j['sourceVersion']),
      sourceDescription = _text(j['sourceDescription']),
      sourceFile = _text(j['sourceFile']),
      sourceSha256 = _text(j['sourceSha256']),
      sourceUrl = _text(j['sourceUrl']),
      form = FoodForm.values.byName(_text(j['form'])),
      options = List.unmodifiable(
        (j['options'] as List).map(
          (v) => HouseholdMeasureOption._(Map<String, dynamic>.from(v as Map)),
        ),
      ),
      issues = List.unmodifiable((j['issues'] as List).cast<String>()) {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(sourceSha256) ||
        options.map((v) => v.id).toSet().length != options.length ||
        options.map((v) => v.sourcePortionIndex).toSet().length !=
            options.length ||
        (options.isEmpty && issues.isEmpty)) {
      throw const FormatException('Invalid measure review');
    }
  }
  final String foodId,
      version,
      sourceDescription,
      sourceFile,
      sourceSha256,
      sourceUrl;
  final FoodForm form;
  final List<HouseholdMeasureOption> options;
  final List<String> issues;
}

/// Explicitly accepted source portion estimate. Never an actual weighed quantity.
/// No automatic stock, cost, history or person-intake write is attached to this.
class HouseholdMeasureProposal {
  HouseholdMeasureProposal._(this.review, this.option, this.measureQuantity)
    : amount = FoodAmount(
        value: option.gramWeight * measureQuantity / option.amount,
        unit: FoodQuantityUnit.g,
      );
  final HouseholdMeasureReview review;
  final HouseholdMeasureOption option;
  final double measureQuantity;
  final FoodAmount amount;
  bool get estimated => true;
  String get basis => 'edibleInput';
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'foodId': review.foodId,
    'foodVersion': review.version,
    'form': review.form.name,
    'optionId': option.id,
    'measureQuantity': measureQuantity,
    'amount': amount.toJson(),
    'estimated': true,
    'basis': basis,
    'sourceEvidence': {
      'url': review.sourceUrl,
      'file': review.sourceFile,
      'sha256': review.sourceSha256,
      'sourceDescription': review.sourceDescription,
      'sourcePortionIndex': option.sourcePortionIndex,
      'sourceAmount': option.amount,
      'sourceGramWeight': option.gramWeight,
      'measureUnit': option.measureUnit,
      'modifier': option.modifier,
      'description': option.description,
      'rationale': option.rationale,
    },
    'issues': review.issues,
  };
}

class HouseholdMeasureRepository {
  HouseholdMeasureRepository({FoodAssetReader? read, FoodRepository? foods})
    : _read = read ?? rootBundle.loadString,
      _foods = foods ?? FoodRepository(read: read);
  final FoodAssetReader _read;
  final FoodRepository _foods;
  Future<List<HouseholdMeasureReview>>? _reviews;
  Future<List<HouseholdMeasureReview>> _load() => _reviews ??= _loadAll();
  Future<List<HouseholdMeasureReview>> _loadAll() async {
    try {
      final j = jsonDecode(
        await _read('data/nutrition/household-measures-review.json'),
      ) as Map;
      if (j['schemaVersion'] != 1 || j['licenseCC0'] != true) {
        throw const FormatException('Measure bank schema/license');
      }
      final rows = (j['entries'] as List)
          .map(
            (v) =>
                HouseholdMeasureReview._(Map<String, dynamic>.from(v as Map)),
          )
          .toList();
      if (rows.map((v) => jsonEncode([v.foodId, v.form.name])).toSet().length !=
          rows.length) {
        throw const FormatException('Duplicate measure review');
      }
      return List.unmodifiable(rows);
    } catch (_) {
      _reviews = null;
      rethrow;
    }
  }

  Future<HouseholdMeasureReview> optionsFor(FoodRecord food) async {
    final found = (await _load())
        .where((v) => v.foodId == food.id && v.form == food.form)
        .toList();
    if (found.length != 1) {
      throw StateError('No reviewed source measures for exact food/form');
    }
    final review = found.single;
    if (food.kind != FoodKind.generic ||
        food.version != review.version ||
        food.nameEn != review.sourceDescription) {
      throw StateError('Food identity changed; measure review required');
    }
    final raw = await _foods.usdaRaw(food.id);
    if (raw['version'] != review.version ||
        raw['name'] != review.sourceDescription) {
      throw StateError('Source food changed; measure review required');
    }
    final portions = raw['portions'] as List;
    for (final option in review.options) {
      if (option.sourcePortionIndex >= portions.length) {
        throw StateError('Source portion removed');
      }
      final p = portions[option.sourcePortionIndex] as Map;
      if (p['amount'] != option.amount ||
          p['gramWeight'] != option.gramWeight ||
          p['measureUnit'] != option.measureUnit ||
          p['modifier'] != option.modifier ||
          p['description'] != option.description) {
        throw StateError('Source portion changed; re-review required');
      }
    }
    return review;
  }

  Future<HouseholdMeasureProposal> resolve(
    FoodRecord food, {
    required String optionId,
    required double measureQuantity,
    required bool acknowledgeExactSourcePortion,
  }) async {
    if (!acknowledgeExactSourcePortion ||
        !measureQuantity.isFinite ||
        measureQuantity <= 0) {
      throw ArgumentError(
        'Explicit source measure acceptance and positive quantity required',
      );
    }
    final review = await optionsFor(food),
        found = review.options.where((v) => v.id == optionId).toList();
    if (found.length != 1) {
      throw ArgumentError('Unknown source portion choice');
    }
    return HouseholdMeasureProposal._(review, found.single, measureQuantity);
  }
}
