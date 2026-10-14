import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../domain/food_nutrition.dart';
import 'food_repository.dart';

/// Explicit acceptance of one bounded category estimate, never exact-food,
/// finished-recipe, or source-specific legal approval.
class PreparationCategoryRepository {
  PreparationCategoryRepository({FoodAssetReader? read})
    : _read = read ?? rootBundle.loadString,
      _foods = FoodRepository(read: read);
  final FoodAssetReader _read;
  final FoodRepository _foods;
  Future<String>? _cached;

  static const _kind = 'accepted-category-preparation-estimate';
  static const _prefix = '$_kind:';
  static const _reviewPath = 'data/nutrition/preparation-category-review.json';
  static const _candidatesPath = 'data/nutrition/retention-candidates.json';
  static const _shardPath = 'data/usda/shards/31.json';
  static const _shardSha =
      '7c425a180d54ba1a2d999f382823697cfc40d7d823c3f20689a0add494b9f81d';
  // These pins detect local evidence drift. They are not upstream signatures,
  // an independent scientific review, or permission to reuse the source.
  static const _reviewSha =
      '8a32d8e120f96ae3bc8fe3bc9cc9c25e29856f408943ce20ef9b5b229dda13a1';
  static const _sourceSha =
      '76b9bc8be7dad915935dc8d6afb85a67ff4672b82453726c830326604a66160c';
  static const _foodSha =
      '1e5fc6d4480d23e17aa9a69a6e74b393df3c32ed6f1e7055bea35bf00d40558e';
  static const _mapping = {
    '401': NutrientId.vitaminC,
    '404': NutrientId.thiamin,
    '405': NutrientId.riboflavin,
  };
  static const _foodSourceFingerprint = {
    'file': _shardPath,
    'sha256': _shardSha,
    'algorithm': 'sha256-utf8-entire-file-crlf-to-lf',
  };

  static dynamic _canonical(dynamic value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: _canonical(value[key])};
    }
    if (value is List) return value.map(_canonical).toList();
    return value is num ? value.toDouble() : value;
  }

  static String _encoded(dynamic value) => jsonEncode(_canonical(value));
  static bool _same(dynamic a, dynamic b) => _encoded(a) == _encoded(b);
  static String _digest(dynamic value) =>
      sha256.convert(utf8.encode(_encoded(value))).toString();
  static void _need(bool valid) {
    if (!valid) {
      throw const FormatException('Invalid category preparation estimate');
    }
  }

  static bool _supportedFood(FoodRecord food) {
    final snapshot = food.toJson()..remove('nameAr');
    return food.id == 'usda:168927' &&
        food.version == '2018-04' &&
        food.kind == FoodKind.generic &&
        food.form == FoodForm.asSold &&
        _digest(snapshot) == _foodSha;
  }

  Future<String> _load() => _cached ??= _loadValidated();
  Future<String> _loadValidated() async {
    try {
      final texts = await Future.wait([
        _read(_reviewPath),
        _read(_candidatesPath),
        _read(_shardPath),
      ]);
      // Preserve the reviewed algorithm: entire UTF8 shard, only CRLF -> LF,
      // no trimming, parsed reserialization, or per-food snapshot substitution.
      _need(
        sha256
                .convert(utf8.encode(texts[2].replaceAll('\r\n', '\n')))
                .toString() ==
            _shardSha,
      );
      final review = jsonDecode(texts[0]) as Map;
      final bank = jsonDecode(texts[1]) as Map;
      _need(
        bank['schemaVersion'] == 1 &&
            bank['quantityKind'] == 'nutrientRetention' &&
            bank['approvedTransformCount'] == 0,
      );
      final rows = bank['entries'] as List;
      for (final code in ['0381', '0382']) {
        _validatedRows(
          review,
          bank['source'] as Map,
          rows.where((r) => r['retentionCode'] == code).toList(),
          code,
        );
      }
      return jsonEncode({
        'review': review,
        'retentionSource': bank['source'],
        'sourceCandidates': rows
            .where((r) => ['0381', '0382'].contains(r['retentionCode']))
            .toList(),
      });
    } catch (error) {
      _cached = null;
      if (error is FormatException) rethrow;
      // Failed IO can be retried, while malformed JSON/casts fail closed.
      if (error is TypeError || error is ArgumentError) {
        throw const FormatException('Invalid category preparation bank');
      }
      rethrow;
    }
  }

  static Map _method(Map review, String code) {
    _need(_digest(review) == _reviewSha);
    final methods = (review['methodOptions'] as List)
        .where((m) => m['retentionCode'] == code)
        .toList();
    _need(methods.length == 1);
    return methods.single as Map;
  }

  static List<Map> _validatedRows(
    Map review,
    Map source,
    List rows,
    String code,
  ) {
    final method = _method(review, code);
    _need(_digest(source) == _sourceSha && rows.length == 3);
    final result = <Map>[];
    for (final factor in method['factors'] as List) {
      final found = rows
          .where((r) => r['id'] == factor['candidateId'])
          .toList();
      _need(found.length == 1);
      final expected = {
        'retentionCode': code,
        'foodGroupCode': review['categoryAssessment']['foodGroupCode'],
        'description': method['description'],
        'nutrientNumber': factor['nutrientNumber'],
        'nutrientDescription': factor['nutrient'],
        'factorPercent': factor['factorPercent'],
        'sourceUpdated': method['sourceUpdated'],
        'sourceLine': factor['sourceLine'],
        'id': factor['candidateId'],
        'nutrientId': _mapping[factor['nutrientNumber']]!.name,
        'factor': factor['fraction'],
        'factorUnit': 'fraction',
        'status': 'source-extracted-unmapped',
        'foodIds': [],
        'massYield': null,
        'edibleFraction': null,
        'sourceLineSha256': factor['sourceLineSha256'],
      };
      _need(_same(found.single, expected));
      result.add(found.single as Map);
    }
    return result;
  }

  Future<Map> _forFood(FoodRecord food) async {
    if (!_supportedFood(food)) {
      throw ArgumentError(
        'Exact reviewed generic as-sold food snapshot required',
      );
    }
    final bank = jsonDecode(await _load()) as Map;
    final canonical = await _foods.usdaFood(
      'usda:168927',
      form: 'asSold',
      nameAr: food.nameAr,
    );
    if (!_same(canonical.toJson(), food.toJson())) {
      throw ArgumentError('Food differs from the canonical source snapshot');
    }
    return bank;
  }

  Future<List<String>> methods(FoodRecord food) async {
    await _forFood(food);
    return List.unmodifiable(['0381', '0382']);
  }

  static Map<NutrientId, double> _retention(List<Map> rows) => {
    for (final row in rows)
      _mapping[row['nutrientNumber']]!: (row['factor'] as num).toDouble(),
  };
  static List<String> _missing() => NutrientId.values
      .where((n) => !_mapping.values.contains(n))
      .map((n) => n.name)
      .toList();
  static FoodSource _source(Map source, String code) => FoodSource(
    id: 'usda-retention6',
    url: source['url'] as String,
    authority: 'USDA Agricultural Research Service, Nutrient Data Laboratory',
    license: source['license'] as String,
    retrievedAt: DateTime.parse(source['retrievedAt'] as String).toUtc(),
    version: source['publicationDate'] as String,
    recordId: code,
  );

  Future<PreparationTransform> accept(
    FoodRecord food, {
    required String retentionCode,
    required String reviewNote,
    required DateTime acceptedAt,
    required bool acknowledgeCategoryEstimate,
    required bool acknowledgeUnknownLicense,
  }) async {
    if (!acknowledgeCategoryEstimate ||
        !acknowledgeUnknownLicense ||
        reviewNote.trim().isEmpty ||
        !['0381', '0382'].contains(retentionCode)) {
      throw ArgumentError(
        'Select one actual method and acknowledge category estimate and unknown license',
      );
    }
    final bank = await _forFood(food);
    final review = bank['review'] as Map,
        source = bank['retentionSource'] as Map;
    final method = _method(review, retentionCode);
    final rows = _validatedRows(
      review,
      source,
      (bank['sourceCandidates'] as List)
          .where((r) => r['retentionCode'] == retentionCode)
          .toList(),
      retentionCode,
    );
    final retention = _retention(rows);
    final evidence = {
      'kind': _kind,
      'schemaVersion': 1,
      'food': food.toJson(),
      'foodSourceFingerprint': _foodSourceFingerprint,
      'retentionCode': retentionCode,
      'requiredActualMethod': method['requiredActualMethod'],
      'review': review,
      'retentionSource': source,
      'sourceCandidates': rows,
      'acceptance': {
        'acceptedAt': acceptedAt.toUtc().toIso8601String(),
        'reviewNote': reviewNote.trim(),
        'acknowledgeCategoryEstimate': true,
        'acknowledgeUnknownLicense': true,
      },
      'retention': {for (final e in retention.entries) e.key.name: e.value},
      'missingNutrients': _missing(),
      'massYield': null,
      'edibleFraction': null,
      'licenseStatus': 'unknown',
      'runtimeTransformApproved': false,
      'exactFoodMatchVerified': false,
      'supportsFinishedRecipe': false,
      'sourceSpecificLegalApproval': false,
    };
    final result = PreparationTransform(
      id: '$_prefix${food.key}:$retentionCode',
      sourceForm: FoodForm.asSold,
      targetForm: FoodForm.cooked,
      source: _source(source, retentionCode),
      retention: retention,
      estimated: true,
      evidence: jsonEncode(evidence),
    );
    validateAccepted(food, result);
    return result;
  }

  /// The reserved ID still triggers validation if kind was removed or changed.
  static bool isCategoryEstimate(PreparationTransform transform) {
    if (transform.id.startsWith(_prefix)) return true;
    try {
      return transform.evidence != null &&
          (jsonDecode(transform.evidence!) as Map)['kind'] == _kind;
    } catch (_) {
      return false;
    }
  }

  /// Synchronous frozen-evidence validation; no current assets are consulted.
  /// KitchenService may add recipeId/recipeRevisionKey/line scope at root;
  /// it owns checking that scope against the selected recipe and line.
  static void validateAccepted(
    FoodRecord food,
    PreparationTransform transform,
  ) {
    try {
      final e = jsonDecode(transform.evidence!) as Map;
      _need(
        e['kind'] == _kind &&
            e['schemaVersion'] == 1 &&
            _supportedFood(food) &&
            _same(e['food'], food.toJson()) &&
            _same(e['foodSourceFingerprint'], _foodSourceFingerprint),
      );
      final code = e['retentionCode'] as String;
      final review = e['review'] as Map, source = e['retentionSource'] as Map;
      final method = _method(review, code);
      final rows = _validatedRows(
        review,
        source,
        e['sourceCandidates'] as List,
        code,
      );
      final retention = _retention(rows);
      _need(
        transform.id == '$_prefix${food.key}:$code' &&
            transform.estimated &&
            transform.sourceForm == FoodForm.asSold &&
            transform.targetForm == FoodForm.cooked &&
            transform.massYield == null &&
            _same(transform.source.toJson(), _source(source, code).toJson()) &&
            _same(
              {
                for (final r in transform.retention.entries)
                  r.key.name: r.value,
              },
              {for (final r in retention.entries) r.key.name: r.value},
            ) &&
            _same(e['retention'], {
              for (final r in retention.entries) r.key.name: r.value,
            }),
      );
      final acceptance = e['acceptance'] as Map;
      final at = DateTime.tryParse(acceptance['acceptedAt'] as String);
      _need(
        at != null &&
            at.isUtc &&
            at.toIso8601String() == acceptance['acceptedAt'] &&
            acceptance['reviewNote'] is String &&
            (acceptance['reviewNote'] as String).trim().isNotEmpty &&
            acceptance['acknowledgeCategoryEstimate'] == true &&
            acceptance['acknowledgeUnknownLicense'] == true &&
            e['requiredActualMethod'] == method['requiredActualMethod'] &&
            _same(e['missingNutrients'], _missing()) &&
            e.containsKey('massYield') &&
            e['massYield'] == null &&
            e.containsKey('edibleFraction') &&
            e['edibleFraction'] == null &&
            e['licenseStatus'] == 'unknown' &&
            e['runtimeTransformApproved'] == false &&
            e['exactFoodMatchVerified'] == false &&
            e['supportsFinishedRecipe'] == false &&
            e['sourceSpecificLegalApproval'] == false,
      );
    } catch (_) {
      throw const FormatException(
        'Invalid accepted category preparation evidence',
      );
    }
  }
}
