/// Food facts and arithmetic. No dietary targets, medical rules or guessed data.
library;

enum NutrientUnit { kcal, kJ, g, mg, ug }

enum NutrientId {
  energyKcal(NutrientUnit.kcal),
  energyKj(NutrientUnit.kJ),
  protein(NutrientUnit.g),
  // Source definitions differ: USDA by-difference includes dietary fibre;
  // label carbohydrate must not silently share that analytical definition.
  carbohydrate(NutrientUnit.g),
  carbohydrateByDifference(NutrientUnit.g),
  availableCarbohydrate(NutrientUnit.g),
  fat(NutrientUnit.g),
  saturatedFat(NutrientUnit.g),
  transFat(NutrientUnit.g),
  monounsaturatedFat(NutrientUnit.g),
  polyunsaturatedFat(NutrientUnit.g),
  fibre(NutrientUnit.g),
  totalSugars(NutrientUnit.g),
  addedSugars(NutrientUnit.g),
  starch(NutrientUnit.g),
  polyols(NutrientUnit.g),
  alcohol(NutrientUnit.g),
  sodium(NutrientUnit.mg),
  salt(NutrientUnit.g),
  cholesterol(NutrientUnit.mg),
  calcium(NutrientUnit.mg),
  iron(NutrientUnit.mg),
  magnesium(NutrientUnit.mg),
  phosphorus(NutrientUnit.mg),
  potassium(NutrientUnit.mg),
  zinc(NutrientUnit.mg),
  copper(NutrientUnit.mg),
  manganese(NutrientUnit.mg),
  selenium(NutrientUnit.ug),
  iodine(NutrientUnit.ug),
  vitaminA(NutrientUnit.ug),
  vitaminARae(NutrientUnit.ug),
  retinol(NutrientUnit.ug),
  betaCarotene(NutrientUnit.ug),
  vitaminC(NutrientUnit.mg),
  vitaminD(NutrientUnit.ug),
  vitaminE(NutrientUnit.mg),
  vitaminK(NutrientUnit.ug),
  thiamin(NutrientUnit.mg),
  riboflavin(NutrientUnit.mg),
  niacin(NutrientUnit.mg),
  vitaminB6(NutrientUnit.mg),
  folate(NutrientUnit.ug),
  folateDfe(NutrientUnit.ug),
  folicAcid(NutrientUnit.ug),
  foodFolate(NutrientUnit.ug),
  vitaminB12(NutrientUnit.ug),
  choline(NutrientUnit.mg),
  water(NutrientUnit.g);

  const NutrientId(this.unit);
  final NutrientUnit unit;
}

/// User-approved compact summary order; storage and arithmetic retain all IDs.
/// Total sugar and total fat each appear once, without subtype duplication.
const primaryDisplayNutrients = <NutrientId>[
  NutrientId.energyKcal,
  NutrientId.protein,
  NutrientId.totalSugars,
  NutrientId.fibre,
  NutrientId.fat,
];

enum NutrientQualifier { exact, lessThan, trace, unknown }

enum NutrientMethod { label, analytical, calculated, estimated, unknown }

enum FoodKind { generic, packaged }

enum FoodForm { raw, cooked, asSold, prepared }

enum FoodQuantityUnit { g, kg, ml, l, count, serving, unknown }

enum AllergenStatus { contains, mayContain, freeFrom, unknown }

/// Exact vocabulary aliases only, including Open Food Facts English taxonomy
/// tags. No fuzzy matching, translation guessing or family/member inference.
/// Wheat allergy and gluten restriction remain separate identifiers.
String canonicalAllergenId(String value) {
  final trimmed = value.trim();
  final token = trimmed.toLowerCase();
  final key = token.startsWith('en:') ? token.substring(3) : token;
  return const <String, String>{
        'egg': 'egg',
        'eggs': 'egg',
        'milk': 'milk',
        'soy': 'soy',
        'soya': 'soy',
        'soybean': 'soy',
        'soybeans': 'soy',
        'wheat': 'wheat',
        'gluten': 'gluten',
        'cereals-containing-gluten': 'gluten',
        'peanut': 'peanut',
        'peanuts': 'peanut',
        'groundnut': 'peanut',
        'groundnuts': 'peanut',
        'nuts': 'treeNuts',
        'tree-nut': 'treeNuts',
        'tree-nuts': 'treeNuts',
        'treenuts': 'treeNuts',
        'sesame': 'sesame',
        'sesame-seed': 'sesame',
        'sesame-seeds': 'sesame',
        'fish': 'fish',
        'crustacean': 'crustaceans',
        'crustaceans': 'crustaceans',
        'mollusc': 'molluscs',
        'molluscs': 'molluscs',
        'mollusk': 'molluscs',
        'mollusks': 'molluscs',
        'celery': 'celery',
        'mustard': 'mustard',
        'lupin': 'lupin',
        'lupins': 'lupin',
        'lupine': 'lupin',
        'sulphite': 'sulphites',
        'sulphites': 'sulphites',
        'sulfite': 'sulphites',
        'sulfites': 'sulphites',
        'sulphur-dioxide-and-sulphites': 'sulphites',
        'sulfur-dioxide-and-sulfites': 'sulphites',
      }[key] ??
      trimmed;
}

double _positive(num value, String field) {
  if (!value.isFinite || value <= 0) throw ArgumentError('Invalid $field');
  return value.toDouble();
}

double _nonnegative(num value, String field) {
  if (!value.isFinite || value < 0) throw ArgumentError('Invalid $field');
  return value.toDouble();
}

String _required(String value, String field) {
  if (value.trim().isEmpty) throw ArgumentError('Missing $field');
  return value;
}

Map<String, dynamic> _map(Object? value) =>
    Map<String, dynamic>.from(value as Map);
T _enum<T extends Enum>(List<T> values, Object? value) => values.firstWhere(
  (item) => item.name == value,
  orElse: () => throw FormatException('Unknown enum value: $value'),
);

/// Provenance is retained in snapshots, including redistribution terms.
class FoodSource {
  FoodSource({
    required this.id,
    required this.url,
    required this.authority,
    required this.license,
    required this.retrievedAt,
    this.licenseUrl,
    this.version,
    this.recordId,
  }) {
    _required(id, 'source id');
    _required(authority, 'authority');
    _required(license, 'license');
    if (!Uri.parse(url).hasScheme) throw ArgumentError('Source URL required');
    if (!retrievedAt.isUtc) throw ArgumentError('retrievedAt must be UTC');
  }
  final String id, url, authority, license;
  final String? licenseUrl, version, recordId;
  final DateTime retrievedAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'authority': authority,
    'license': license,
    'licenseUrl': licenseUrl,
    'retrievedAt': retrievedAt.toIso8601String(),
    'version': version,
    'recordId': recordId,
  };
  factory FoodSource.fromJson(Map<String, dynamic> j) => FoodSource(
    id: j['id'] as String,
    url: j['url'] as String,
    authority: j['authority'] as String,
    license: j['license'] as String,
    licenseUrl: j['licenseUrl'] as String?,
    retrievedAt: DateTime.parse(j['retrievedAt'] as String),
    version: j['version'] as String?,
    recordId: j['recordId'] as String?,
  );
}

class NutrientValue {
  NutrientValue({
    required this.value,
    this.qualifier = NutrientQualifier.exact,
    this.method = NutrientMethod.label,
    this.sourceId,
    this.note,
  }) {
    if (value != null) _nonnegative(value!, 'nutrient value');
    if ((qualifier == NutrientQualifier.exact ||
            qualifier == NutrientQualifier.lessThan) &&
        value == null) {
      throw ArgumentError('Numeric qualifiers require a value');
    }
    if ((qualifier == NutrientQualifier.unknown ||
            qualifier == NutrientQualifier.trace) &&
        value != null) {
      throw ArgumentError('Unknown/trace must not masquerade as a number');
    }
  }
  final double? value;
  final NutrientQualifier qualifier;
  final NutrientMethod method;
  final String? sourceId, note;
  bool get quantified => qualifier == NutrientQualifier.exact;
  Map<String, dynamic> toJson() => {
    'value': value,
    'qualifier': qualifier.name,
    'method': method.name,
    'sourceId': sourceId,
    'note': note,
  };
  factory NutrientValue.fromJson(Map<String, dynamic> j) => NutrientValue(
    value: (j['value'] as num?)?.toDouble(),
    qualifier: _enum(NutrientQualifier.values, j['qualifier']),
    method: _enum(NutrientMethod.values, j['method']),
    sourceId: j['sourceId'] as String?,
    note: j['note'] as String?,
  );
}

class NutritionBasis {
  NutritionBasis({required num amount, required this.unit})
    : amount = _positive(amount, 'basis amount') {
    if (![
      FoodQuantityUnit.g,
      FoodQuantityUnit.ml,
      FoodQuantityUnit.serving,
      FoodQuantityUnit.unknown,
    ].contains(unit)) {
      throw ArgumentError('Nutrition basis is g, ml, serving or unknown');
    }
  }
  final double amount;
  final FoodQuantityUnit unit;
  Map<String, dynamic> toJson() => {'amount': amount, 'unit': unit.name};
  factory NutritionBasis.fromJson(Map<String, dynamic> j) => NutritionBasis(
    amount: j['amount'] as num,
    unit: _enum(FoodQuantityUnit.values, j['unit']),
  );
}

class NutrientProfile {
  NutrientProfile({
    required this.basis,
    required Map<NutrientId, NutrientValue> values,
  }) : values = Map.unmodifiable(values);
  final NutritionBasis basis;
  final Map<NutrientId, NutrientValue> values;
  Map<String, dynamic> toJson() => {
    'basis': basis.toJson(),
    'values': [
      for (final e in values.entries)
        {'id': e.key.name, 'unit': e.key.unit.name, ...e.value.toJson()},
    ],
  };
  factory NutrientProfile.fromJson(Map<String, dynamic> j) {
    final values = <NutrientId, NutrientValue>{};
    for (final raw in j['values'] as List) {
      final item = _map(raw);
      final id = _enum(NutrientId.values, item['id']);
      if (values.containsKey(id)) {
        throw const FormatException('Duplicate nutrient');
      }
      if (item['unit'] != id.unit.name) {
        throw const FormatException('Nutrient unit mismatch');
      }
      values[id] = NutrientValue.fromJson(item);
    }
    return NutrientProfile(
      basis: NutritionBasis.fromJson(_map(j['basis'])),
      values: values,
    );
  }
}

/// These are measured conversion facts for this exact food/form, not defaults.
class FoodConversion {
  FoodConversion({
    this.gramsPerMl,
    this.gramsPerCount,
    this.gramsPerServing,
    this.edibleFraction,
    required this.sourceId,
  }) {
    _required(sourceId, 'conversion source');
    for (final v in [gramsPerMl, gramsPerCount, gramsPerServing]) {
      if (v != null) _positive(v, 'mass conversion');
    }
    if (edibleFraction != null &&
        (!edibleFraction!.isFinite ||
            edibleFraction! <= 0 ||
            edibleFraction! > 1)) {
      throw ArgumentError('Edible fraction must be >0 and <=1');
    }
  }
  final double? gramsPerMl, gramsPerCount, gramsPerServing, edibleFraction;
  final String sourceId;
  Map<String, dynamic> toJson() => {
    'gramsPerMl': gramsPerMl,
    'gramsPerCount': gramsPerCount,
    'gramsPerServing': gramsPerServing,
    'edibleFraction': edibleFraction,
    'sourceId': sourceId,
  };
  factory FoodConversion.fromJson(Map<String, dynamic> j) => FoodConversion(
    gramsPerMl: (j['gramsPerMl'] as num?)?.toDouble(),
    gramsPerCount: (j['gramsPerCount'] as num?)?.toDouble(),
    gramsPerServing: (j['gramsPerServing'] as num?)?.toDouble(),
    edibleFraction: (j['edibleFraction'] as num?)?.toDouble(),
    sourceId: j['sourceId'] as String,
  );
}

class AllergenDeclaration {
  AllergenDeclaration({
    required String allergenId,
    required this.status,
    this.evidence,
    this.sourceId,
  }) : allergenId = canonicalAllergenId(allergenId) {
    _required(allergenId, 'allergen id');
    if (status != AllergenStatus.unknown &&
        (evidence == null ||
            evidence!.trim().isEmpty ||
            sourceId == null ||
            sourceId!.trim().isEmpty)) {
      throw ArgumentError('Allergen declarations require evidence and source');
    }
  }
  final String allergenId;
  final AllergenStatus status;
  final String? evidence, sourceId;
  Map<String, dynamic> toJson() => {
    'allergenId': allergenId,
    'status': status.name,
    'evidence': evidence,
    'sourceId': sourceId,
  };
  factory AllergenDeclaration.fromJson(Map<String, dynamic> j) =>
      AllergenDeclaration(
        allergenId: j['allergenId'] as String,
        status: _enum(AllergenStatus.values, j['status']),
        evidence: j['evidence'] as String?,
        sourceId: j['sourceId'] as String?,
      );
}

class FoodComponent {
  FoodComponent({
    required this.foodId,
    required this.foodVersion,
    this.label,
    this.massFraction,
  }) {
    _required(foodId, 'component id');
    _required(foodVersion, 'component version');
    if (massFraction != null &&
        (!massFraction!.isFinite || massFraction! <= 0 || massFraction! > 1)) {
      throw ArgumentError('Invalid compound ingredient mass fraction');
    }
  }
  final String foodId, foodVersion;
  final String? label;
  final double? massFraction;
  Map<String, dynamic> toJson() => {
    'foodId': foodId,
    'foodVersion': foodVersion,
    'label': label,
    'massFraction': massFraction,
  };
  factory FoodComponent.fromJson(Map<String, dynamic> j) => FoodComponent(
    foodId: j['foodId'] as String,
    foodVersion: j['foodVersion'] as String,
    label: j['label'] as String?,
    massFraction: (j['massFraction'] as num?)?.toDouble(),
  );
}

class FoodRecord {
  FoodRecord({
    required this.id,
    required this.version,
    required this.nameAr,
    required this.kind,
    required this.form,
    required this.nutrition,
    required List<FoodSource> sources,
    this.nameEn,
    this.brand,
    this.market,
    this.gtin,
    this.packageQuantity,
    this.conversion,
    List<AllergenDeclaration> allergens = const [],
    List<FoodComponent> components = const [],
    this.compoundIngredientsComplete = false,
  }) : sources = List.unmodifiable(sources),
       allergens = List.unmodifiable(allergens),
       components = List.unmodifiable(components) {
    _required(id, 'food id');
    _required(version, 'food version');
    _required(nameAr, 'food name');
    if (sources.isEmpty) throw ArgumentError('Food requires provenance');
    final sourceIds = sources.map((s) => s.id).toSet();
    if (sourceIds.length != sources.length) {
      throw ArgumentError('Duplicate source id');
    }
    if (kind == FoodKind.packaged &&
        (brand == null ||
            brand!.trim().isEmpty ||
            market == null ||
            market!.trim().isEmpty)) {
      throw ArgumentError('Packaged food requires brand and market');
    }
    if (gtin != null && !_validGtin(gtin!)) throw ArgumentError('Invalid GTIN');
    final allergenIds = allergens.map((a) => a.allergenId).toSet();
    if (allergenIds.length != allergens.length) {
      throw ArgumentError('Duplicate allergen');
    }
    for (final s in [
      conversion?.sourceId,
      ...nutrition.values.values.map((n) => n.sourceId),
      ...allergens.map((a) => a.sourceId),
    ]) {
      if (s != null && !sourceIds.contains(s)) {
        throw ArgumentError('Unknown source reference: $s');
      }
    }
    if (components.fold<double>(0, (s, c) => s + (c.massFraction ?? 0)) >
        1 + 1e-9) {
      throw ArgumentError('Compound mass fractions exceed one');
    }
  }
  final String id, version, nameAr;
  final String? nameEn, brand, market, gtin;
  final FoodKind kind;
  final FoodForm form;
  final NutrientProfile nutrition;
  final FoodAmount? packageQuantity;
  final FoodConversion? conversion;
  final List<FoodSource> sources;
  final List<AllergenDeclaration> allergens;
  final List<FoodComponent> components;
  final bool compoundIngredientsComplete;
  String get key => '$id@$version';
  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'kind': kind.name,
    'form': form.name,
    'brand': brand,
    'market': market,
    'gtin': gtin,
    'packageQuantity': packageQuantity?.toJson(),
    'nutrition': nutrition.toJson(),
    'conversion': conversion?.toJson(),
    'sources': sources.map((s) => s.toJson()).toList(),
    'allergens': allergens.map((a) => a.toJson()).toList(),
    'components': components.map((c) => c.toJson()).toList(),
    'compoundIngredientsComplete': compoundIngredientsComplete,
  };
  factory FoodRecord.fromJson(Map<String, dynamic> j) => FoodRecord(
    id: j['id'] as String,
    version: j['version'] as String,
    nameAr: j['nameAr'] as String,
    nameEn: j['nameEn'] as String?,
    kind: _enum(FoodKind.values, j['kind']),
    form: _enum(FoodForm.values, j['form']),
    brand: j['brand'] as String?,
    market: j['market'] as String?,
    gtin: j['gtin'] as String?,
    packageQuantity: j['packageQuantity'] == null
        ? null
        : FoodAmount.fromJson(_map(j['packageQuantity'])),
    nutrition: NutrientProfile.fromJson(_map(j['nutrition'])),
    conversion: j['conversion'] == null
        ? null
        : FoodConversion.fromJson(_map(j['conversion'])),
    sources: (j['sources'] as List)
        .map((s) => FoodSource.fromJson(_map(s)))
        .toList(),
    allergens: ((j['allergens'] as List?) ?? [])
        .map((a) => AllergenDeclaration.fromJson(_map(a)))
        .toList(),
    components: ((j['components'] as List?) ?? [])
        .map((c) => FoodComponent.fromJson(_map(c)))
        .toList(),
    compoundIngredientsComplete: j['compoundIngredientsComplete'] == true,
  );
}

bool _validGtin(String value) {
  if (![8, 12, 13, 14].contains(value.length) ||
      !RegExp(r'^\d+$').hasMatch(value)) {
    return false;
  }
  var sum = 0;
  for (var i = value.length - 2, weight = 3; i >= 0; i--, weight = 4 - weight) {
    sum += int.parse(value[i]) * weight;
  }
  return (10 - sum % 10) % 10 == int.parse(value[value.length - 1]);
}

class FoodAmount {
  FoodAmount({required num value, required this.unit})
    : value = _positive(value, 'food amount') {
    if (unit == FoodQuantityUnit.unknown) {
      throw ArgumentError('Measured amount requires a known unit');
    }
  }
  final double value;
  final FoodQuantityUnit unit;
  Map<String, dynamic> toJson() => {'value': value, 'unit': unit.name};
  factory FoodAmount.fromJson(Map<String, dynamic> j) => FoodAmount(
    value: j['value'] as num,
    unit: _enum(FoodQuantityUnit.values, j['unit']),
  );
}

/// massYield = prepared edible mass / starting edible mass. It never changes
/// nutrient totals by itself; retention is a separate fact for each nutrient.
class PreparationTransform {
  PreparationTransform({
    required this.id,
    required this.sourceForm,
    required this.targetForm,
    required this.source,
    this.massYield,
    required Map<NutrientId, double> retention,
  }) : retention = Map.unmodifiable(retention) {
    _required(id, 'preparation id');
    if (sourceForm == targetForm) {
      throw ArgumentError('Preparation forms must differ');
    }
    if (massYield != null) _positive(massYield!, 'mass yield');
    for (final v in retention.values) {
      if (!v.isFinite || v < 0 || v > 1) {
        throw ArgumentError('Invalid nutrient retention');
      }
    }
  }
  final String id;
  final FoodForm sourceForm, targetForm;
  final FoodSource source;
  final double? massYield;
  final Map<NutrientId, double> retention;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceForm': sourceForm.name,
    'targetForm': targetForm.name,
    'source': source.toJson(),
    'massYield': massYield,
    'retention': {for (final e in retention.entries) e.key.name: e.value},
  };
  factory PreparationTransform.fromJson(Map<String, dynamic> j) =>
      PreparationTransform(
        id: j['id'] as String,
        sourceForm: _enum(FoodForm.values, j['sourceForm']),
        targetForm: _enum(FoodForm.values, j['targetForm']),
        source: FoodSource.fromJson(_map(j['source'])),
        massYield: (j['massYield'] as num?)?.toDouble(),
        retention: _map(j['retention']).map(
          (k, v) =>
              MapEntry(_enum(NutrientId.values, k), (v as num).toDouble()),
        ),
      );
}

class RecipeFoodInput {
  RecipeFoodInput({
    required this.ingredientId,
    required this.food,
    required this.amount,
    required this.amountForm,
    required this.preparedForm,
    this.quantityEstimated = false,
    this.optional = false,
    this.selected = true,
    this.asPurchased = false,
    this.preparation,
  }) {
    _required(ingredientId, 'recipe ingredient id');
    if (!optional && !selected) {
      throw ArgumentError('Required ingredient cannot be excluded');
    }
  }
  final String ingredientId;
  final FoodRecord? food;
  final FoodAmount? amount;
  final FoodForm amountForm, preparedForm;
  final bool optional, selected, asPurchased;
  final bool quantityEstimated;
  final PreparationTransform? preparation;
  Map<String, dynamic> toJson() => {
    'ingredientId': ingredientId,
    'food': food?.toJson(),
    'amount': amount?.toJson(),
    'quantityEstimated': quantityEstimated,
    'amountForm': amountForm.name,
    'preparedForm': preparedForm.name,
    'optional': optional,
    'selected': selected,
    'asPurchased': asPurchased,
    'preparation': preparation?.toJson(),
  };
  factory RecipeFoodInput.fromJson(Map<String, dynamic> j) => RecipeFoodInput(
    ingredientId: j['ingredientId'] as String,
    food: j['food'] == null ? null : FoodRecord.fromJson(_map(j['food'])),
    amount: j['amount'] == null ? null : FoodAmount.fromJson(_map(j['amount'])),
    quantityEstimated: j['quantityEstimated'] == true,
    amountForm: _enum(FoodForm.values, j['amountForm']),
    preparedForm: _enum(FoodForm.values, j['preparedForm']),
    optional: j['optional'] == true,
    selected: j['selected'] != false,
    asPurchased: j['asPurchased'] == true,
    preparation: j['preparation'] == null
        ? null
        : PreparationTransform.fromJson(_map(j['preparation'])),
  );
}

enum NutrientGapReason {
  unmappedFood,
  unmeasuredAmount,
  incompatibleUnit,
  missingNutrient,
  nonNumericNutrient,
  formMismatch,
  missingPreparation,
  missingMassYield,
  missingRetention,
  missingEdibleFraction,
  unknownBasis,
}

class NutrientGap {
  const NutrientGap(this.ingredientId, this.reason);
  final String ingredientId;
  final NutrientGapReason reason;
  Map<String, dynamic> toJson() => {
    'ingredientId': ingredientId,
    'reason': reason.name,
  };
  factory NutrientGap.fromJson(Map<String, dynamic> j) => NutrientGap(
    j['ingredientId'] as String,
    _enum(NutrientGapReason.values, j['reason']),
  );
}

class NutrientTotal {
  NutrientTotal({
    required this.nutrient,
    required num knownSubtotal,
    required List<NutrientGap> missing,
    this.estimated = false,
  }) : knownSubtotal = _nonnegative(knownSubtotal, 'nutrient subtotal'),
       missing = List.unmodifiable(missing);
  final NutrientId nutrient;
  final double knownSubtotal;
  final List<NutrientGap> missing;
  final bool estimated;
  bool get complete => missing.isEmpty;
  double? get value => complete ? knownSubtotal : null;
  NutrientTotal scaled(double factor) => NutrientTotal(
    nutrient: nutrient,
    knownSubtotal: knownSubtotal * _positive(factor, 'scale'),
    missing: missing,
    estimated: estimated,
  );
  Map<String, dynamic> toJson() => {
    'unit': nutrient.unit.name,
    'knownSubtotal': knownSubtotal,
    'value': value,
    'complete': complete,
    'estimated': estimated,
    'missing': missing.map((m) => m.toJson()).toList(),
  };
  factory NutrientTotal.fromJson(NutrientId id, Map<String, dynamic> j) {
    if (j['unit'] != id.unit.name) {
      throw const FormatException('Result unit mismatch');
    }
    final total = NutrientTotal(
      nutrient: id,
      knownSubtotal: j['knownSubtotal'] as num,
      missing: (j['missing'] as List)
          .map((m) => NutrientGap.fromJson(_map(m)))
          .toList(),
      estimated: j['estimated'] == true,
    );
    if (j['complete'] != total.complete || j['value'] != total.value) {
      throw const FormatException('Inconsistent nutrition result');
    }
    return total;
  }
}

class RecipeNutritionResult {
  RecipeNutritionResult({
    required this.recipeId,
    required this.recipeVersion,
    required num portions,
    required Map<NutrientId, NutrientTotal> whole,
    required List<RecipeFoodInput> snapshot,
    num? cookedYieldGrams,
  }) : portions = _positive(portions, 'portions'),
       whole = Map.unmodifiable(whole),
       snapshot = List.unmodifiable(snapshot),
       cookedYieldGrams = cookedYieldGrams == null
           ? null
           : _positive(cookedYieldGrams, 'cooked yield') {
    _required(recipeId, 'recipe id');
    _required(recipeVersion, 'recipe version');
    for (final entry in whole.entries) {
      if (entry.key != entry.value.nutrient) {
        throw ArgumentError('Nutrient key mismatch');
      }
    }
  }
  final String recipeId, recipeVersion;
  final double portions;
  final double? cookedYieldGrams;
  final Map<NutrientId, NutrientTotal> whole;
  final List<RecipeFoodInput> snapshot;
  Map<NutrientId, NutrientTotal> get perPortion => Map.unmodifiable(
    whole.map((k, v) => MapEntry(k, v.scaled(1 / portions))),
  );
  Map<NutrientId, NutrientTotal>? get per100g => cookedYieldGrams == null
      ? null
      : Map.unmodifiable(
          whole.map((k, v) => MapEntry(k, v.scaled(100 / cookedYieldGrams!))),
        );
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'recipeId': recipeId,
    'recipeVersion': recipeVersion,
    'portions': portions,
    'cookedYieldGrams': cookedYieldGrams,
    'whole': {for (final e in whole.entries) e.key.name: e.value.toJson()},
    'snapshot': snapshot.map((s) => s.toJson()).toList(),
  };
  factory RecipeNutritionResult.fromJson(Map<String, dynamic> j) {
    if (j['schemaVersion'] != 1) {
      throw const FormatException('Unknown nutrition snapshot schema');
    }
    return RecipeNutritionResult(
      recipeId: j['recipeId'] as String,
      recipeVersion: j['recipeVersion'] as String,
      portions: j['portions'] as num,
      cookedYieldGrams: j['cookedYieldGrams'] as num?,
      whole: _map(j['whole']).map((k, v) {
        final id = _enum(NutrientId.values, k);
        return MapEntry(id, NutrientTotal.fromJson(id, _map(v)));
      }),
      snapshot: (j['snapshot'] as List)
          .map((s) => RecipeFoodInput.fromJson(_map(s)))
          .toList(),
    );
  }
}

/// Resolves exact units only. No default tablespoon, cup, piece or density.
double? _grams(FoodAmount amount, FoodConversion? c) => switch (amount.unit) {
  FoodQuantityUnit.g => amount.value,
  FoodQuantityUnit.kg => amount.value * 1000,
  FoodQuantityUnit.ml =>
    c?.gramsPerMl == null ? null : amount.value * c!.gramsPerMl!,
  FoodQuantityUnit.l =>
    c?.gramsPerMl == null ? null : amount.value * 1000 * c!.gramsPerMl!,
  FoodQuantityUnit.count =>
    c?.gramsPerCount == null ? null : amount.value * c!.gramsPerCount!,
  FoodQuantityUnit.serving =>
    c?.gramsPerServing == null ? null : amount.value * c!.gramsPerServing!,
  FoodQuantityUnit.unknown => null,
};
double? _basisAmount(FoodAmount amount, FoodRecord food) {
  final b = food.nutrition.basis;
  if (b.unit == amount.unit) return amount.value;
  if (b.unit == FoodQuantityUnit.ml && amount.unit == FoodQuantityUnit.l) {
    return amount.value * 1000;
  }
  final grams = _grams(amount, food.conversion);
  if (grams == null) return null;
  return switch (b.unit) {
    FoodQuantityUnit.g => grams,
    FoodQuantityUnit.ml =>
      food.conversion?.gramsPerMl == null
          ? null
          : grams / food.conversion!.gramsPerMl!,
    FoodQuantityUnit.serving =>
      food.conversion?.gramsPerServing == null
          ? null
          : grams / food.conversion!.gramsPerServing!,
    _ => null,
  };
}

RecipeNutritionResult calculateRecipeNutrition({
  required String recipeId,
  required String recipeVersion,
  required List<RecipeFoodInput> inputs,
  required num portions,
  num? cookedYieldGrams,
}) {
  final ids = inputs.map((i) => i.ingredientId).toSet();
  if (ids.length != inputs.length) {
    throw ArgumentError('Duplicate recipe ingredient id');
  }
  final selected = inputs.where((i) => !i.optional || i.selected).toList();
  if (selected.isEmpty) {
    throw ArgumentError('Recipe has no selected ingredients');
  }
  final totals = <NutrientId, NutrientTotal>{};
  for (final nutrient in NutrientId.values) {
    var subtotal = 0.0;
    var estimated = false;
    final missing = <NutrientGap>[];
    for (final input in selected) {
      NutrientGapReason? gap;
      final food = input.food;
      final amount = input.amount;
      final preparation = input.preparation;
      double? basisAmount;
      var retention = 1.0;
      if (food == null) {
        gap = NutrientGapReason.unmappedFood;
      } else if (amount == null) {
        gap = NutrientGapReason.unmeasuredAmount;
      } else {
        basisAmount = _basisAmount(amount, food);
        if (basisAmount == null) {
          gap = food.nutrition.basis.unit == FoodQuantityUnit.unknown
              ? NutrientGapReason.unknownBasis
              : NutrientGapReason.incompatibleUnit;
        }
        if (input.asPurchased) {
          final fraction = food.conversion?.edibleFraction;
          if (fraction == null) {
            gap = NutrientGapReason.missingEdibleFraction;
          } else if (basisAmount != null) {
            basisAmount *= fraction;
          }
        }
        if (preparation != null &&
            (preparation.sourceForm != food.form ||
                preparation.targetForm != input.preparedForm)) {
          gap = NutrientGapReason.formMismatch;
        } else if (input.preparedForm != food.form && preparation == null) {
          gap = NutrientGapReason.missingPreparation;
        }
        if (input.amountForm != food.form) {
          if (preparation == null ||
              input.amountForm != preparation.targetForm) {
            gap = NutrientGapReason.formMismatch;
          } else if (preparation.massYield == null) {
            gap = NutrientGapReason.missingMassYield;
          } else if (amount.unit != FoodQuantityUnit.g &&
              amount.unit != FoodQuantityUnit.kg) {
            // Density and piece masses describe the source form, not cooked form.
            gap = NutrientGapReason.incompatibleUnit;
          } else if (basisAmount != null) {
            basisAmount /= preparation.massYield!;
          }
        }
        if (preparation != null && gap == null) {
          final r = preparation.retention[nutrient];
          if (r == null) {
            gap = NutrientGapReason.missingRetention;
          } else {
            retention = r;
          }
        }
        final value = food.nutrition.values[nutrient];
        if (gap == null && value == null) {
          gap = NutrientGapReason.missingNutrient;
        }
        if (gap == null && !value!.quantified) {
          gap = NutrientGapReason.nonNumericNutrient;
        }
        if (gap == null) {
          final contribution =
              value!.value! *
              basisAmount! /
              food.nutrition.basis.amount *
              retention;
          subtotal += contribution;
          estimated =
              estimated ||
              input.quantityEstimated ||
              value.method == NutrientMethod.estimated;
        }
      }
      if (gap != null) missing.add(NutrientGap(input.ingredientId, gap));
    }
    totals[nutrient] = NutrientTotal(
      nutrient: nutrient,
      knownSubtotal: subtotal,
      missing: missing,
      estimated: estimated,
    );
  }
  return RecipeNutritionResult(
    recipeId: recipeId,
    recipeVersion: recipeVersion,
    portions: portions,
    whole: totals,
    snapshot: inputs,
    cookedYieldGrams: cookedYieldGrams,
  );
}

/// Missing declarations are unknown. A verified free-from statement is scoped
/// to that exact record/version/market; it is never inferred from the name.
AllergenStatus foodAllergenStatus(
  FoodRecord food,
  String allergenId, {
  Map<String, FoodRecord> catalog = const {},
  Set<String> visited = const {},
}) {
  if (visited.contains(food.key)) return AllergenStatus.unknown;
  final path = {...visited, food.key};
  final canonicalId = canonicalAllergenId(allergenId);
  final declarations = food.allergens.where((a) => a.allergenId == canonicalId);
  final own = declarations.isEmpty
      ? AllergenStatus.unknown
      : declarations.single.status;
  if (own == AllergenStatus.contains) return own;
  final nested = <AllergenStatus>[];
  for (final component in food.components) {
    final expectedKey = '${component.foodId}@${component.foodVersion}';
    final child = catalog[expectedKey];
    nested.add(
      child == null || child.key != expectedKey
          ? AllergenStatus.unknown
          : foodAllergenStatus(
              child,
              allergenId,
              catalog: catalog,
              visited: path,
            ),
    );
  }
  if (nested.contains(AllergenStatus.contains)) return AllergenStatus.contains;
  if (own == AllergenStatus.mayContain ||
      nested.contains(AllergenStatus.mayContain)) {
    return AllergenStatus.mayContain;
  }
  if (own == AllergenStatus.freeFrom) return own;
  // Free component declarations do not establish absence of cross-contact in
  // the finished product. Only an explicit product statement can do that.
  return AllergenStatus.unknown;
}

AllergenStatus recipeAllergenStatus(
  List<RecipeFoodInput> inputs,
  String allergenId, {
  Map<String, FoodRecord> catalog = const {},
}) {
  final statuses = inputs
      .where((i) => !i.optional || i.selected)
      .map(
        (i) => i.food == null
            ? AllergenStatus.unknown
            : foodAllergenStatus(i.food!, allergenId, catalog: catalog),
      )
      .toList();
  if (statuses.contains(AllergenStatus.contains)) {
    return AllergenStatus.contains;
  }
  if (statuses.contains(AllergenStatus.mayContain)) {
    return AllergenStatus.mayContain;
  }
  if (statuses.isEmpty || statuses.contains(AllergenStatus.unknown)) {
    return AllergenStatus.unknown;
  }
  return AllergenStatus.freeFrom;
}
