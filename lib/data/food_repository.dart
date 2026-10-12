import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/food_nutrition.dart';

typedef FoodAssetReader = Future<String> Function(String path);

/// Licensed source banks remain separate; selection never matches names silently.
class FoodRepository {
  FoodRepository({FoodAssetReader? read})
    : _read = read ?? rootBundle.loadString;
  final FoodAssetReader _read;
  final Map<String, Future<dynamic>> _cache = {};
  Future<dynamic> _json(String path) => _cache.putIfAbsent(path, () async {
    try {
      return jsonDecode(await _read(path));
    } catch (_) {
      _cache.remove(path);
      rethrow;
    }
  });
  Future<List<Map<String, dynamic>>> usdaIndex() async =>
      ((await _json('data/usda/index.json'))['foods'] as List)
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();

  Future<List<Map<String, dynamic>>> products() async {
    final rows = await (_products ??= _loadProducts());
    return (jsonDecode(jsonEncode(rows)) as List)
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>>? _products;
  Future<List<Map<String, dynamic>>> _loadProducts() async {
    try {
      final text = await _read('data/food/openfoodfacts/products.jsonl');
      final rows = const LineSplitter()
          .convert(text)
          .where((v) => v.trim().isNotEmpty)
          .map((v) => Map<String, dynamic>.from(jsonDecode(v) as Map))
          .toList();
      return rows;
    } catch (_) {
      _products = null;
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> search({
    String query = '',
    String? market,
    bool packagedOnly = false,
    int limit = 40,
  }) async {
    if (limit < 1 || limit > 500) throw ArgumentError('Invalid search limit');
    if (market != null && !{'EG', 'SA'}.contains(market)) {
      throw ArgumentError('Unknown market');
    }
    String norm(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll(RegExp('[أإآ]'), 'ا')
        .replaceAll('ى', 'ي');
    final q = norm(query.trim());
    final result = <Map<String, dynamic>>[];
    for (final p in await products()) {
      final countries = (p['markets'] as List? ?? []).cast<String>();
      if (market != null &&
          !countries.any(
            (v) =>
                v == market ||
                v == (market == 'EG' ? 'en:egypt' : 'en:saudi-arabia'),
          )) {
        continue;
      }
      if (norm(
        jsonEncode([p['names'], p['brands'], p['barcode'], p['categories']]),
      ).contains(q)) {
        result.add(Map<String, dynamic>.from(p));
      }
      if (result.length >= limit) return result;
    }
    if (!packagedOnly) {
      for (final row in await usdaIndex()) {
        if (norm('${row['name']} ${row['id']} ${row['category']}')
            .contains(q)) {
          result.add(row);
        }
        if (result.length >= limit) break;
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> usdaRaw(String id) async {
    final entry = (await usdaIndex()).where((v) => v['id'] == id).single;
    final filename = entry['file'] as String;
    if (!RegExp(r'^\d{2}\.json$').hasMatch(filename)) {
      throw const FormatException('Invalid USDA shard');
    }
    final rows = await _json('data/usda/shards/$filename') as List;
    return Map<String, dynamic>.from(
      jsonDecode(jsonEncode(rows.where((v) => v['id'] == id).single)) as Map,
    );
  }

  /// The caller explicitly selects form from the source description. US values
  /// do not assert a local product match, halal status or allergen absence.
  Future<FoodRecord> usdaFood(
    String id, {
    required String form,
    String? nameAr,
  }) async {
    final row = await usdaRaw(id);
    if (!{'raw', 'cooked', 'asSold', 'prepared'}.contains(form)) {
      throw ArgumentError('Food form');
    }
    final seen = <String>{};
    final values = <Map<String, dynamic>>[];
    final definitions =
        (await _json('data/usda/nutrient-definitions.json'))['nutrients']
            as Map;
    for (final raw in row['nutrients'] as List) {
      final mapped = _fdcNutrients[raw[0]];
      if (mapped == null || !seen.add(mapped.$1)) continue;
      final sourceUnit = (definitions['${raw[0]}']['unit'] as String)
          .toLowerCase();
      final target = mapped.$2.toLowerCase();
      if (sourceUnit != target &&
          !(target == 'ug' && {'µg', 'μg'}.contains(sourceUnit))) {
        continue;
      }
      values.add({
        'id': mapped.$1,
        'unit': mapped.$2,
        'value': raw[1],
        'qualifier': 'exact',
        'method': raw[2] == 'A' ? 'analytical' : 'estimated',
        'sourceId': 'usda',
        'note': 'FDC nutrient ${raw[0]}; derivation ${raw[2]}',
      });
    }
    return FoodRecord.fromJson({
      'id': id,
      'version': row['version'],
      'nameAr': nameAr ?? row['name'],
      'nameEn': row['name'],
      'kind': 'generic',
      'form': form,
      'nutrition': {
        'basis': {'amount': 100, 'unit': 'g'},
        'values': values,
      },
      'sources': [
        {
          'id': 'usda',
          'authority': 'USDA FoodData Central',
          'license': 'CC0-1.0',
          'url':
              'https://fdc.nal.usda.gov/food-details/${row['fdcId']}/nutrients',
          'licenseUrl': 'https://fdc.nal.usda.gov/api-guide/',
          'retrievedAt': '2026-10-12T00:00:00Z',
          'version': row['version'],
          'recordId': '${row['fdcId']}',
        },
      ],
      'allergens': [],
      'components': [],
      'compoundIngredientsComplete': false,
    });
  }

  Future<Map<String, dynamic>> productRaw(String barcode) async =>
      (await products()).where((p) => p['barcode'] == barcode).single;

  /// A market-specific product snapshot. Ambiguous OFF basis remains unknown
  /// until the exact label is reviewed; package mass is not proof of basis.
  Future<FoodRecord> packagedFood(
    String barcode, {
    required String market,
    NutritionBasis? reviewedBasis,
    FoodSource? reviewSource,
  }) async {
    if (!{'EG', 'SA'}.contains(market)) throw ArgumentError('Unknown market');
    if ((reviewedBasis == null) != (reviewSource == null)) {
      throw ArgumentError('Label basis review requires its evidence source');
    }
    if (reviewedBasis != null &&
        (reviewedBasis.amount != 100 ||
            !{
              FoodQuantityUnit.g,
              FoodQuantityUnit.ml,
            }.contains(reviewedBasis.unit))) {
      throw ArgumentError('OFF facts are per100g or per100ml');
    }
    final row = await productRaw(barcode);
    if (!(row['markets'] as List).contains(market)) {
      throw StateError('Product market not sourced');
    }
    final source = row['source'] as Map;
    final sourceId = 'off';
    final names = row['names'] as Map;
    final brands = (row['brands'] as String? ?? '').trim();
    if (brands.isEmpty) {
      throw StateError('Product has no sourced brand; review required');
    }
    final values = <Map<String, dynamic>>[];
    final warnings = ((row['quality'] as Map?)?['warnings'] as List? ?? [])
        .cast<String>();
    final invalidFacts = warnings.any(
      (v) => {
        'source-data-quality-errors',
        'energy-units-inconsistent',
        'sugars-exceed-carbohydrates',
      }.contains(v),
    );
    for (final entry in ((row['nutrition'] as Map)['asSold'] as Map).entries) {
      final mapped = _offNutrients[entry.key];
      if (mapped == null) continue;
      final fact = entry.value as Map;
      final unit = fact['unit'] as String?;
      var value = (fact['value'] as num).toDouble();
      if (unit == 'g' && mapped.$2 == 'mg') {
        value *= 1000;
      } else if (unit == 'mg' && mapped.$2 == 'ug') {
        value *= 1000;
      } else if (unit == 'g' && mapped.$2 == 'ug') {
        value *= 1000000;
      } else if (unit != mapped.$2) {
        continue;
      }
      final modifier = fact['modifier'];
      final exact =
          !invalidFacts &&
          (modifier == null || modifier == '' || modifier == '=');
      final less = !invalidFacts && modifier == '<';
      values.add({
        'id': mapped.$1,
        'unit': mapped.$2,
        'value': exact || less ? value : null,
        'qualifier': exact
            ? 'exact'
            : less
            ? 'lessThan'
            : 'unknown',
        'method': 'estimated',
        'sourceId': sourceId,
        'note':
            'Community label data; ${fact['sourceField']}; modifier $modifier',
      });
    }
    final allergens = <Map<String, dynamic>>[];
    final declarations = row['allergens'] as Map;
    for (final pair in [
      ('declaredTags', 'contains'),
      ('traceTags', 'mayContain'),
    ]) {
      for (final tag in declarations[pair.$1] as List) {
        final id = canonicalAllergenId(
          (tag as String).replaceFirst(RegExp(r'^[a-z]{2}:'), ''),
        );
        if (allergens.any((a) => a['allergenId'] == id)) continue;
        allergens.add({
          'allergenId': id,
          'status': pair.$2,
          'evidence': 'Source-reported label tag: $tag',
          'sourceId': sourceId,
        });
      }
    }
    final p = row['package'] as Map;
    final quantity = p['quantity'] as num?;
    final punit = p['unit'];
    return FoodRecord.fromJson({
      'id': row['id'],
      'version': 'off:${source['lastModifiedEpoch'] ?? source['retrievedAt']}',
      'nameAr': (names['ar'] as String?)?.isNotEmpty == true
          ? names['ar']
          : names['original'],
      'nameEn': names['en'],
      'kind': 'packaged',
      'form': 'asSold',
      'brand': brands,
      'market': market,
      'gtin': barcode,
      if (quantity != null &&
          quantity > 0 &&
          {'g', 'kg', 'ml', 'l', 'count'}.contains(punit))
        'packageQuantity': {'value': quantity, 'unit': punit},
      'nutrition': {
        'basis': reviewedBasis?.toJson() ?? {'amount': 100, 'unit': 'unknown'},
        'values': values,
      },
      'sources': [
        {
          'id': sourceId,
          'url': source['url'],
          'authority': 'Open Food Facts community',
          'license': 'ODbL-1.0 / DbCL-1.0',
          'licenseUrl': 'https://world.openfoodfacts.org/terms-of-use',
          'retrievedAt': source['retrievedAt'],
          'recordId': barcode,
        },
        if (reviewSource != null) reviewSource.toJson(),
      ],
      'allergens': allergens,
      'components': [],
      'compoundIngredientsComplete': false,
    });
  }
}

const _offNutrients = <String, (String, String)>{
  'energy-kcal': ('energyKcal', 'kcal'),
  'energy': ('energyKj', 'kJ'),
  'proteins': ('protein', 'g'),
  'carbohydrates': ('carbohydrate', 'g'),
  'fat': ('fat', 'g'),
  'fiber': ('fibre', 'g'),
  'sugars': ('totalSugars', 'g'),
  'added-sugars': ('addedSugars', 'g'),
  'saturated-fat': ('saturatedFat', 'g'),
  'trans-fat': ('transFat', 'g'),
  'monounsaturated-fat': ('monounsaturatedFat', 'g'),
  'polyunsaturated-fat': ('polyunsaturatedFat', 'g'),
  'sodium': ('sodium', 'mg'),
  'salt': ('salt', 'g'),
  'cholesterol': ('cholesterol', 'mg'),
  'calcium': ('calcium', 'mg'),
  'iron': ('iron', 'mg'),
  'magnesium': ('magnesium', 'mg'),
  'phosphorus': ('phosphorus', 'mg'),
  'potassium': ('potassium', 'mg'),
  'zinc': ('zinc', 'mg'),
  'selenium': ('selenium', 'ug'),
  'iodine': ('iodine', 'ug'),
  'vitamin-c': ('vitaminC', 'mg'),
  'vitamin-d': ('vitaminD', 'ug'),
  'vitamin-e': ('vitaminE', 'mg'),
  'vitamin-k': ('vitaminK', 'ug'),
  'vitamin-b1': ('thiamin', 'mg'),
  'vitamin-b2': ('riboflavin', 'mg'),
  'vitamin-pp': ('niacin', 'mg'),
  'vitamin-b6': ('vitaminB6', 'mg'),
  'vitamin-b9': ('folate', 'ug'),
  'vitamin-b12': ('vitaminB12', 'ug'),
};

// Distinct vitamin/folate definitions are intentionally not combined.
const _fdcNutrients = <int, (String, String)>{
  1008: ('energyKcal', 'kcal'),
  1062: ('energyKj', 'kJ'),
  1003: ('protein', 'g'),
  1004: ('fat', 'g'),
  1005: ('carbohydrateByDifference', 'g'),
  1079: ('fibre', 'g'),
  2000: ('totalSugars', 'g'),
  1235: ('addedSugars', 'g'),
  1009: ('starch', 'g'),
  1018: ('alcohol', 'g'),
  1051: ('water', 'g'),
  1258: ('saturatedFat', 'g'),
  1257: ('transFat', 'g'),
  1292: ('monounsaturatedFat', 'g'),
  1293: ('polyunsaturatedFat', 'g'),
  1253: ('cholesterol', 'mg'),
  1093: ('sodium', 'mg'),
  1087: ('calcium', 'mg'),
  1089: ('iron', 'mg'),
  1090: ('magnesium', 'mg'),
  1091: ('phosphorus', 'mg'),
  1092: ('potassium', 'mg'),
  1095: ('zinc', 'mg'),
  1098: ('copper', 'mg'),
  1101: ('manganese', 'mg'),
  1103: ('selenium', 'ug'),
  1100: ('iodine', 'ug'),
  1106: ('vitaminARae', 'ug'),
  1105: ('retinol', 'ug'),
  1107: ('betaCarotene', 'ug'),
  1162: ('vitaminC', 'mg'),
  1114: ('vitaminD', 'ug'),
  1109: ('vitaminE', 'mg'),
  1185: ('vitaminK', 'ug'),
  1165: ('thiamin', 'mg'),
  1166: ('riboflavin', 'mg'),
  1167: ('niacin', 'mg'),
  1175: ('vitaminB6', 'mg'),
  1177: ('folate', 'ug'),
  1190: ('folateDfe', 'ug'),
  1186: ('folicAcid', 'ug'),
  1187: ('foodFolate', 'ug'),
  1178: ('vitaminB12', 'ug'),
  1180: ('choline', 'mg'),
};
