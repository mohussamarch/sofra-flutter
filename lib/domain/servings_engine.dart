import 'dart:convert';
import 'dart:math' as math;

import 'servings_tables.g.dart';

/// How sure the engine is of its own number.
enum ServingsConfidence { high, medium, low, none }

/// Where the yield the app uses comes from.
enum ServingsBasisSource { source, computed, user, none }

/// One ingredient (or a group of the same kind) the number rests on.
class ServingsDriver {
  const ServingsDriver({
    required this.ingredientId,
    required this.category,
    required this.amount,
    required this.unit,
    required this.people,
  });

  /// The first ingredient line of the group ("pasta").
  final String ingredientId;

  /// The portion norm it was measured against ("pastaDry").
  final String category;

  /// Total amount in the norm's unit: g, ml or count.
  final double amount;
  final String unit;

  /// How many people that amount feeds on its own.
  final double people;

  Map<String, Object?> toJson() => {
    'ingredientId': ingredientId,
    'category': category,
    'amount': amount,
    'unit': unit,
    'people': people,
  };

  static ServingsDriver fromJson(Map<String, dynamic> json) => ServingsDriver(
    ingredientId: json['ingredientId'] as String,
    category: json['category'] as String,
    amount: (json['amount'] as num).toDouble(),
    unit: json['unit'] as String,
    people: (json['people'] as num).toDouble(),
  );
}

/// The engine's verdict on one recipe: the four fields the library build
/// writes on every recipe (`servingsComputed`, `servingsRange`,
/// `servingsBasis`, `servingsConfidence`), plus working values.
class ServingsEstimate {
  const ServingsEstimate({
    required this.computed,
    required this.range,
    required this.confidence,
    required this.basis,
    required this.drivers,
    this.reason,
    this.impliedPerPerson,
    this.kind,
    this.people,
  });

  /// The four field names, as stored on index rows and recipe bodies.
  static const fieldKeys = {
    'servingsComputed',
    'servingsRange',
    'servingsBasis',
    'servingsConfidence',
  };

  final int? computed;
  final (int, int)? range;
  final ServingsConfidence confidence;

  /// `source` when the stated yield is kept (plausible, or the engine is not
  /// sure enough to reject it), `computed` when the engine's number is used,
  /// `none` when there is neither.
  final ServingsBasisSource basis;
  final List<ServingsDriver> drivers;

  /// Why there is no number, or why the stated yield was rejected or kept.
  final String? reason;
  final double? impliedPerPerson;
  final String? kind;

  /// The unrounded number of people.
  final double? people;

  bool get hasValue =>
      computed != null && confidence != ServingsConfidence.none;

  /// The driver feeding the most people: the one the info sheet names.
  ServingsDriver? get mainDriver => drivers.isEmpty
      ? null
      : drivers.reduce((a, b) => b.people > a.people ? b : a);

  Map<String, Object?> toJson() => {
    'servingsComputed': computed,
    'servingsRange': range == null ? null : [range!.$1, range!.$2],
    'servingsBasis': {
      'source': basis.name,
      'drivers': [for (final d in drivers) d.toJson()],
      if (impliedPerPerson != null) 'impliedPerPerson': impliedPerPerson,
      if (reason != null) 'reason': reason,
    },
    'servingsConfidence': confidence.name,
  };

  /// The stored fields of a row or body, or null when it has none.
  static ServingsEstimate? fromJson(Map<String, dynamic> json) {
    final confidence = json['servingsConfidence'];
    final basis = json['servingsBasis'];
    if (confidence is! String || basis is! Map) return null;
    final c = ServingsConfidence.values.where((v) => v.name == confidence);
    final b = ServingsBasisSource.values.where(
      (v) => v.name == basis['source'],
    );
    if (c.isEmpty || b.isEmpty) {
      throw const FormatException('Invalid servings fields');
    }
    final range = json['servingsRange'];
    final computed = json['servingsComputed'];
    if ((computed != null && (computed is! num || computed < 1)) ||
        (range != null && (range is! List || range.length != 2))) {
      throw const FormatException('Invalid servings fields');
    }
    return ServingsEstimate(
      computed: (computed as num?)?.toInt(),
      range: range == null
          ? null
          : ((range as List)[0] as num, range[1] as num).toInts(),
      confidence: c.single,
      basis: b.single,
      drivers: [
        for (final d in (basis['drivers'] as List? ?? const []))
          ServingsDriver.fromJson(Map<String, dynamic>.from(d as Map)),
      ],
      reason: basis['reason'] as String?,
      impliedPerPerson: (basis['impliedPerPerson'] as num?)?.toDouble(),
    );
  }
}

extension on (num, num) {
  (int, int) toInts() => ($1.toInt(), $2.toInt());
}

/// One ingredient line as the engine reads it.
class ServingsLine {
  const ServingsLine({
    required this.id,
    required this.name,
    this.amount,
    this.unit,
    this.optional = false,
  });
  final String id, name;
  final double? amount;
  final String? unit;
  final bool optional;
}

class _Group {
  _Group(this.category, this.role, this.unit);
  final String category, role, unit;
  double amount = 0, people = 0;
  final ids = <String>[];
  final vias = <String>[];
}

class _Role {
  _Role(this.role);
  final String role;
  double people = 0;
  final groups = <_Group>[];
}

/// Decides how many people a recipe feeds from per-person portion norms
/// (data/ingredients/portion-norms.json): one person's dry pasta is about
/// 200 g, rice 150 g, boneless meat 200 g, a whole chicken feeds 4, and so
/// on. A yield stated by the source only confirms it. Pure: no I/O, the
/// tables are compiled in (servings_tables.g.dart). Mirrored line by line in
/// tool/recipes/servings-engine.mjs; both must agree on every recipe.
class ServingsEngine {
  ServingsEngine(Map<String, dynamic> tables)
    : _norms = Map<String, dynamic>.from(tables['norms'] as Map),
      _units = Map<String, dynamic>.from(tables['units'] as Map),
      _rules = Map<String, dynamic>.from(tables['rules'] as Map),
      _cupG = Map<String, dynamic>.from(tables['cupG'] as Map),
      _driving = Map<String, String>.from(tables['driving'] as Map),
      _aliases = Map<String, String>.from(tables['aliases'] as Map),
      _known = Set<String>.from(tables['known'] as List),
      _knownNames = Set<String>.from(tables['knownNames'] as List),
      _deny = _re(tables['deny'] as String),
      _keywords = [
        for (final k in tables['keywords'] as List)
          (_re((k as List)[0] as String), k[1] as String),
      ],
      _kinds = [
        for (final k in tables['kinds'] as List)
          (_re((k as List)[0] as String), k[1] as String),
      ],
      _defaultKind = tables['defaultKind'] as String,
      _priority = {
        for (final e in (tables['priority'] as Map).entries)
          e.key as String: List<String>.from(e.value as List),
      },
      _piece = _re((tables['units'] as Map)['piecePattern'] as String);

  /// The engine over the compiled repository tables.
  static final ServingsEngine shared = ServingsEngine(
    Map<String, dynamic>.from(jsonDecode(servingsTablesJson) as Map),
  );

  static RegExp _re(String pattern) => RegExp(pattern, caseSensitive: false);

  final Map<String, dynamic> _norms, _units, _rules, _cupG;
  final Map<String, String> _driving, _aliases;
  final Set<String> _known, _knownNames;
  final RegExp _deny, _piece;
  final List<(RegExp, String)> _keywords, _kinds;
  final String _defaultKind;
  final Map<String, List<String>> _priority;

  Map<String, dynamic> _norm(String category) =>
      Map<String, dynamic>.from(_norms[category] as Map);

  /// Per-person norm of [category] in its unit (200 for pastaDry), or null.
  double? perPerson(String category) =>
      (_norms[category] as Map?)?['per'] == null
      ? null
      : ((_norms[category] as Map)['per'] as num).toDouble();

  String? normUnit(String category) =>
      (_norms[category] as Map?)?['unit'] as String?;

  String kindOf(String? category) {
    final text = (category ?? '').trim();
    for (final (re, kind) in _kinds) {
      if (re.hasMatch(text)) return kind;
    }
    return _defaultKind;
  }

  /// The portion category of one line, or null when it never drives.
  String? categoryOf(ServingsLine line) {
    final id = line.id.trim();
    final name = line.name.trim();
    final driving = _driving[id];
    if (driving != null) return driving;
    final alias = _aliases[name];
    if (alias != null) return alias;
    if (_known.contains(id) || _knownNames.contains(name)) return null;
    if (_deny.hasMatch(name) || _deny.hasMatch(id)) return null;
    for (final (re, category) in _keywords) {
      if (re.hasMatch(name) || re.hasMatch(id)) return category;
    }
    return null;
  }

  /// A line without a category that is still understood: a known
  /// vocabulary item, or something that never drives (oil, spice, sauce).
  bool understood(ServingsLine line) {
    final id = line.id.trim();
    final name = line.name.trim();
    return _known.contains(id) ||
        _knownNames.contains(name) ||
        _deny.hasMatch(name) ||
        _deny.hasMatch(id);
  }

  static double? _amount(ServingsLine line) {
    final a = line.amount;
    return a != null && a.isFinite && a > 0 ? a : null;
  }

  double? _unitFactor(String table, String unit) =>
      ((_units[table] as Map)[unit] as num?)?.toDouble();

  /// Amount of [line] in [category]'s unit, and how it was converted.
  (double, String)? convert(ServingsLine line, String category) {
    final a = _amount(line);
    if (a == null) return null;
    final norm = _norm(category);
    final u = (line.unit ?? '').trim().toLowerCase();
    if (norm['unit'] == 'count') {
      return u.isEmpty || _piece.hasMatch(u) ? (a, 'count') : null;
    }
    final mass = _unitFactor('mass', u);
    if (mass != null) return (a * mass, 'mass');
    final volume = _unitFactor('volume', u);
    if (volume != null) return (a * volume, 'volume');
    final cup = _unitFactor('cup', u);
    if (cup != null) {
      final g = (_cupG[line.id.trim()] ?? norm['cupG']) as num?;
      return g == null ? null : (a * cup * g, 'cup');
    }
    final piece = norm['pieceG'] as num?;
    if (u.isNotEmpty && _piece.hasMatch(u) && piece != null) {
      return (a * piece, 'piece');
    }
    return null;
  }

  double? _roughGrams(ServingsLine line, String? category) {
    final a = _amount(line);
    if (a == null) return null;
    final u = (line.unit ?? '').trim().toLowerCase();
    final norm = category == null ? null : _norm(category);
    final mass = _unitFactor('mass', u);
    if (mass != null) return a * mass;
    final volume = _unitFactor('volume', u);
    if (volume != null) return a * volume;
    final cup = _unitFactor('cup', u);
    if (cup != null) {
      return a * cup * ((norm?['cupG'] ?? _units['genericCupG']) as num);
    }
    if (u.isEmpty || _piece.hasMatch(u)) {
      return a * ((norm?['pieceG'] ?? _units['genericPieceG']) as num);
    }
    return null;
  }

  String _role(String category) => _norm(category)['role'] as String;

  String? _inContext(String kind, String category) {
    final role = _role(category);
    if (kind == 'soup' || kind == 'drink') {
      if (role != 'liquid') return null;
      return kind == 'drink' ? 'drink' : 'soupLiquid';
    }
    if (role == 'liquid') {
      return kind == 'dessert' && category == 'milkDessert' ? category : null;
    }
    if (category == 'eggsMain' && kind != 'main' && kind != 'salad') {
      return null;
    }
    if (category == 'saladVeg' && kind != 'salad') return null;
    if (kind == 'salad' && role == 'veg') return 'saladVeg';
    if (kind == 'dip' && role == 'starch') return 'dipBase';
    if (kind == 'dessert' && category == 'flourBread') return 'dessertBase';
    return category;
  }

  static double _r2(double v) => (v * 100).round() / 100;
  static double _r1(double v) => (v * 10).round() / 10;

  /// The verdict for a recipe of [category] stating [servings] (or null)
  /// with [lines]. Never throws on unknown units or messy lines.
  ServingsEstimate estimate({
    required String? category,
    required int? servings,
    required List<ServingsLine> lines,
  }) {
    final kind = kindOf(category);
    final stated = servings != null && servings > 0 ? servings : null;
    final noneBasis = stated == null
        ? ServingsBasisSource.none
        : ServingsBasisSource.source;
    if (kind == 'base') {
      return ServingsEstimate(
        computed: null,
        range: null,
        confidence: ServingsConfidence.none,
        basis: noneBasis,
        drivers: const [],
        reason: 'notApplicable',
        kind: kind,
      );
    }
    var total = 0.0, unmapped = 0.0;
    var categorized = 0;
    final byCategory = <String, _Group>{};
    for (final line in lines) {
      if (line.optional) continue;
      final base = categoryOf(line);
      final g = _roughGrams(line, base);
      if (g != null) {
        total += g;
        if (base == null && !understood(line)) unmapped += g;
      }
      if (base == null) continue;
      categorized++;
      final category = _inContext(kind, base);
      if (category == null) continue;
      final amount = convert(line, category);
      if (amount == null || !(amount.$1 > 0)) continue;
      final norm = _norm(category);
      final group = byCategory.putIfAbsent(
        category,
        () => _Group(category, norm['role'] as String, norm['unit'] as String),
      );
      group.amount += amount.$1;
      group.people += amount.$1 / (norm['per'] as num);
      group.ids.add(line.id.trim());
      group.vias.add(amount.$2);
    }
    var groups = byCategory.values.toList();
    if (groups.any((g) => g.role == 'protein' && g.category != 'eggsMain')) {
      groups = groups.where((g) => g.category != 'eggsMain').toList();
    }
    final roles = <String, _Role>{};
    for (final g in groups) {
      final role = roles.putIfAbsent(g.role, () => _Role(g.role));
      role.people += g.people;
      role.groups.add(g);
    }
    final minPeople = (_rules['driverMinPeople'] as num).toDouble();
    final drivers = [
      for (final r in _priority[kind] ?? const <String>[])
        if (roles[r] != null && roles[r]!.people >= minPeople) roles[r]!,
    ];
    final mappedShare = total > 0 ? 1 - unmapped / total : 1.0;
    if (drivers.isEmpty) {
      return ServingsEstimate(
        computed: null,
        range: null,
        confidence: ServingsConfidence.none,
        basis: noneBasis,
        drivers: const [],
        reason: groups.isNotEmpty
            ? 'driverTooSmall'
            : categorized > 0
            ? 'noMeasuredDriver'
            : 'noDriverIngredient',
        kind: kind,
      );
    }
    final values = [for (final d in drivers) d.people];
    final sum = values.fold(0.0, (s, v) => s + v);
    final n = drivers.length;
    final p = n == 1
        ? sum
        : sum * ((_rules['combine'] as Map)['${math.min(n, 3)}'] as num);
    final clamp = _rules['clamp'] as List;
    final lo = (clamp[0] as num).toInt(), hi = (clamp[1] as num).toInt();
    final spreadRange = _rules['range'] as List;
    final computed = math.max(lo, math.min(hi, p.round()));
    final range = (
      math.min(computed, math.max(lo, (p * (spreadRange[0] as num)).floor())),
      math.max(computed, math.min(hi, (p * (spreadRange[1] as num)).ceil())),
    );
    final firm = values.where((v) => v >= 1).toList();
    final spread = firm.length > 1
        ? firm.reduce(math.max) / firm.reduce(math.min)
        : 1.0;
    final used = [for (final d in drivers) ...d.groups];
    final natural = Set<String>.from(_rules['naturalPieceCategories'] as List);
    final pieceOnly = used.every(
      (g) => g.vias.every((v) => v == 'piece') && !natural.contains(g.category),
    );
    final conf = Map<String, dynamic>.from(_rules['confidence'] as Map);
    final ServingsConfidence confidence;
    if (spread > (conf['mediumAgree'] as num) ||
        1 - mappedShare > (conf['lowUnmappedShare'] as num) ||
        pieceOnly ||
        (n == 1 && p < (conf['smallSinglePeople'] as num))) {
      confidence = ServingsConfidence.low;
    } else if (n >= 2 &&
        spread <= (conf['highAgree'] as num) &&
        mappedShare >= (conf['highMappedShare'] as num)) {
      confidence = ServingsConfidence.high;
    } else {
      confidence = ServingsConfidence.medium;
    }
    var dominant = used.first;
    for (final g in used) {
      if (g.people > dominant.people) dominant = g;
    }
    var basis = ServingsBasisSource.computed;
    String? reason;
    double? implied;
    if (stated != null) {
      final norm = _norm(dominant.category);
      final value = (norm['per'] as num) * p / stated;
      implied = _r1(value);
      final band = norm['band'] as List;
      if (value >= (band[0] as num) && value <= (band[1] as num)) {
        basis = ServingsBasisSource.source;
      } else if (confidence == ServingsConfidence.low) {
        basis = ServingsBasisSource.source;
        reason = 'sourceKeptLowConfidence';
      } else {
        reason = _mismatch(kind, stated, p, mappedShare);
      }
    }
    return ServingsEstimate(
      computed: computed,
      range: range,
      confidence: confidence,
      basis: basis,
      drivers: [
        for (final g in used)
          ServingsDriver(
            ingredientId: g.ids.first,
            category: g.category,
            amount: _r1(g.amount),
            unit: g.unit,
            people: _r2(g.people),
          ),
      ],
      reason: reason,
      impliedPerPerson: implied,
      kind: kind,
      people: _r2(p),
    );
  }

  String _mismatch(String kind, int stated, double p, double mappedShare) {
    final gap = (_rules['mappingGapMappedShare'] as num).toDouble();
    if (stated > p) {
      if ((kind == 'dessert' || kind == 'bread') &&
          stated / p >= (_rules['sourceCountsPiecesRatio'] as num)) {
        return 'sourceCountsPieces';
      }
      if (mappedShare < gap) return 'mappingGap';
      return 'sourceInflated';
    }
    if (mappedShare < gap) return 'mappingGap';
    return 'driverAmbiguous';
  }

  /// [estimate] over a loosely typed recipe map (a catalog body, an index
  /// row or an import candidate). Lines that are not maps are skipped.
  ServingsEstimate estimateJson(Map<String, dynamic> recipe) {
    final raw = recipe['servings'];
    final servings = raw is num && raw == raw.roundToDouble() && raw > 0
        ? raw.toInt()
        : null;
    return estimate(
      category: recipe['category'] is String
          ? recipe['category'] as String
          : null,
      servings: servings,
      lines: [
        for (final line in (recipe['ingredients'] as List? ?? const []))
          if (line is Map && line['optional'] != true)
            ServingsLine(
              id: line['id'] is String ? line['id'] as String : '',
              name: line['name'] is String ? line['name'] as String : '',
              amount: _number(line['amount']),
              unit: line['unit'] is String ? line['unit'] as String : null,
            ),
      ],
    );
  }

  static double? _number(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }
}
