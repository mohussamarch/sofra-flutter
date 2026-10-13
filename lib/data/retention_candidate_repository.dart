import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/food_nutrition.dart';
import 'food_repository.dart';

/// Immutable submission for data review, never an approved food match/transform.
class PreparationMatchProposal {
  PreparationMatchProposal._(Map<String, dynamic> value)
    : _json = jsonEncode(value);
  final String _json;
  bool get canApply => false;
  Map<String, dynamic> toJson() => jsonDecode(_json) as Map<String, dynamic>;
}

class RetentionCandidateRepository {
  RetentionCandidateRepository({FoodAssetReader? read})
    : _read = read ?? rootBundle.loadString;
  final FoodAssetReader _read;
  Future<String>? _cached;
  Future<String> _load() => _cached ??= _loadValidated();
  Future<String> _loadValidated() async {
    try {
      final text = await _read('data/nutrition/retention-candidates.json');
      try {
        _validate(jsonDecode(text) as Map);
      } catch (_) {
        throw const FormatException(
          'Invalid unapproved retention candidate bank',
        );
      }
      return text;
    } catch (_) {
      _cached = null;
      rethrow;
    }
  }

  static const _mapping = {
    '401': 'vitaminC',
    '404': 'thiamin',
    '405': 'riboflavin',
  };
  static void _validate(Map j) {
    void need(bool valid) {
      if (!valid) {
        throw const FormatException('Retention evidence');
      }
    }

    bool hash(dynamic v) =>
        v is String && RegExp(r'^[a-f0-9]{64}$').hasMatch(v);
    final source = j['source'] as Map, rows = j['entries'] as List;
    need(
      j['schemaVersion'] == 1 &&
          j['approvedTransformCount'] == 0 &&
          j['quantityKind'] == 'nutrientRetention' &&
          rows.isNotEmpty,
    );
    need(
      hash(source['sha256']) &&
          source['url'] ==
              'https://www.ars.usda.gov/ARSUserFiles/80400535/Data/retn/retn06.txt' &&
          source['license'] is String &&
          DateTime.tryParse(source['retrievedAt'] as String? ?? '') != null,
    );
    final ids = <String>{}, groups = <String, String>{};
    for (final raw in rows) {
      final e = raw as Map,
          code = e['retentionCode'] as String,
          number = e['nutrientNumber'] as String;
      final percent = e['factorPercent'], factor = e['factor'];
      need(
        RegExp(r'^\d{4}$').hasMatch(code) &&
            _mapping[number] == e['nutrientId'] &&
            e['id'] == 'usda-retention6:$code:$number' &&
            ids.add(e['id'] as String),
      );
      need(
        percent is num &&
            percent.isFinite &&
            percent >= 0 &&
            percent <= 100 &&
            factor is num &&
            factor.isFinite &&
            factor == percent / 100,
      );
      need(
        e['factorUnit'] == 'fraction' &&
            e['status'] == 'source-extracted-unmapped' &&
            (e['foodIds'] as List).isEmpty &&
            e['massYield'] == null &&
            e['edibleFraction'] == null,
      );
      need(
        e['sourceLine'] is int &&
            e['sourceLine'] > 0 &&
            hash(e['sourceLineSha256']) &&
            e['description'] is String &&
            (e['description'] as String).trim().isNotEmpty,
      );
      final group = jsonEncode([e['description'], e['foodGroupCode']]);
      need(!groups.containsKey(code) || groups[code] == group);
      groups[code] = group;
    }
  }

  Future<List<String>> codes() async {
    final j = jsonDecode(await _load()) as Map;
    final codes =
        (j['entries'] as List)
            .map((v) => v['retentionCode'] as String)
            .toSet()
            .toList()
          ..sort();
    return List.unmodifiable(codes);
  }

  Future<PreparationMatchProposal> proposeMatch(
    FoodRecord food, {
    required String retentionCode,
    required FoodForm targetForm,
    required String reviewNote,
    required bool acknowledgeNotApproved,
  }) async {
    if (!acknowledgeNotApproved ||
        reviewNote.trim().isEmpty ||
        food.kind != FoodKind.generic ||
        !food.id.startsWith('usda:') ||
        ![FoodForm.raw, FoodForm.asSold].contains(food.form) ||
        targetForm != FoodForm.cooked) {
      throw ArgumentError(
        'Explicit unapproved review of an exact generic input food and cooked target required',
      );
    }
    final j = jsonDecode(await _load()) as Map;
    final rows = (j['entries'] as List)
        .where((v) => v['retentionCode'] == retentionCode)
        .toList();
    if (rows.isEmpty) {
      throw StateError('No extracted candidate for requested preparation code');
    }
    final present = rows.map((v) => v['nutrientId']).toSet();
    return PreparationMatchProposal._({
      'schemaVersion': 1,
      'status': 'matching-review-requested',
      'canApply': false,
      'foodMatchVerified': false,
      'food': food.toJson(),
      'sourceForm': food.form.name,
      'targetForm': targetForm.name,
      'retentionCode': retentionCode,
      'sourceDescription': rows.first['description'],
      'source': j['source'],
      'sourceCandidates': rows,
      'retention': {for (final row in rows) row['nutrientId']: row['factor']},
      'missingNutrients': NutrientId.values
          .where((v) => !present.contains(v.name))
          .map((v) => v.name)
          .toList(),
      'massYield': null,
      'edibleFraction': null,
      'licenseStatus': 'unknown',
      'reviewNote': reviewNote.trim(),
      'requestedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
