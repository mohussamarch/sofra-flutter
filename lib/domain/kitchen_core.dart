import 'dart:math' as math;

import 'models.dart';
import 'market_profile.dart';

void requireAmount(double value, {bool zero = false}) {
  if (!value.isFinite || (zero ? value < 0 : value <= 0)) {
    throw ArgumentError.value(value, 'quantity');
  }
}

String localDay(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
DateTime parseDay(String value) {
  final date = DateTime.tryParse(value);
  if (date == null || localDay(date) != value) {
    throw FormatException('Invalid date: $value');
  }
  return DateTime(date.year, date.month, date.day);
}

enum MemberGender { unspecified, male, female }

class HouseholdMember {
  HouseholdMember({
    required this.id,
    required this.name,
    required this.age,
    this.gender = MemberGender.unspecified,
    bool hijab = false,
    List<String> allergies = const [],
    this.healthNote = '',
    List<String> favorites = const [],
  }) : allergies = List.unmodifiable(allergies),
       favorites = List.unmodifiable(favorites),
       hijab = gender == MemberGender.male ? false : hijab {
    if (id.isEmpty || name.trim().isEmpty || age < 0 || age > 120) {
      throw ArgumentError('Invalid member');
    }
  }
  final String id, name, healthNote;
  final int age;
  final MemberGender gender;
  final bool hijab;
  final List<String> allergies, favorites;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'gender': gender.name,
    'hijab': hijab,
    'allergies': allergies,
    'healthNote': healthNote,
    'favorites': favorites,
  };
  factory HouseholdMember.fromJson(Map<String, dynamic> v) => HouseholdMember(
    id: v['id'] as String,
    name: v['name'] as String,
    age: v['age'] as int,
    gender: MemberGender.values.byName(v['gender'] as String? ?? 'unspecified'),
    hijab: v['hijab'] == true,
    allergies: List<String>.from(v['allergies'] as List? ?? []),
    healthNote: v['healthNote'] as String? ?? '',
    favorites: List<String>.from(v['favorites'] as List? ?? []),
  );
}

class InventoryLot {
  InventoryLot({
    required this.id,
    required this.ingredientId,
    required this.quantity,
    required String unit,
    required this.zone,
  }) : unit = Units.canonical(unit) {
    if (id.isEmpty || ingredientId.isEmpty || unit.isEmpty) {
      throw ArgumentError('Invalid stock');
    }
    if (quantity != null) requireAmount(quantity!, zero: true);
  }
  final String id, ingredientId, unit;
  final double? quantity;
  final StorageZone zone;
  InventoryLot withQuantity(double amount) => InventoryLot(
    id: id,
    ingredientId: ingredientId,
    quantity: amount,
    unit: unit,
    zone: zone,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'ingredientId': ingredientId,
    'quantity': quantity,
    'unit': unit,
    'zone': zone.name,
  };
  factory InventoryLot.fromJson(Map<String, dynamic> v) => InventoryLot(
    id: v['id'] as String,
    ingredientId: v['ingredientId'] as String,
    quantity: (v['quantity'] as num?)?.toDouble(),
    unit: v['unit'] as String,
    zone: StorageZone.values.byName(v['zone'] as String),
  );
}

/// Only explicit packages: no assumed supermarket sizes or count-to-weight guesses.
class StockPurchase {
  StockPurchase({
    required this.count,
    required this.content,
    required this.unit,
  }) {
    requireAmount(count);
    requireAmount(content);
    if (Units.canonical(unit).isEmpty) {
      throw ArgumentError('Missing package unit');
    }
  }
  final double count, content;
  final String unit;
  double get quantity => count * content;
}

class UnitRule {
  UnitRule(this.ingredientId, String from, String to, this.factor)
    : from = Units.canonical(from),
      to = Units.canonical(to) {
    requireAmount(factor);
  }
  final String ingredientId, from, to;
  final double factor;
  Map<String, dynamic> toJson() => {
    'ingredientId': ingredientId,
    'from': from,
    'to': to,
    'factor': factor,
  };
  factory UnitRule.fromJson(Map<String, dynamic> v) => UnitRule(
    v['ingredientId'] as String,
    v['from'] as String,
    v['to'] as String,
    (v['factor'] as num).toDouble(),
  );
}

class Units {
  static const _synonyms = {
    'جم': 'g',
    'جرام': 'g',
    'غرام': 'g',
    'grams': 'g',
    'gram': 'g',
    'g': 'g',
    'كيلو': 'kg',
    'كجم': 'kg',
    'كيلوغرام': 'kg',
    'كيلوجرام': 'kg',
    'kg': 'kg',
    'مل': 'ml',
    'مللي': 'ml',
    'ملليلتر': 'ml',
    'مليلتر': 'ml',
    'ml': 'ml',
    'لتر': 'l',
    'l': 'l',
    'ديسيلتر': 'dl',
    'dl': 'dl',
    'ملعقة كبيرة': 'tbsp',
    'م.ك': 'tbsp',
    'T': 'tbsp',
    'tbsp': 'tbsp',
    'tablespoon': 'tbsp',
    'tablespoons': 'tbsp',
    'ملعقة صغيرة': 'tsp',
    'م.ص': 'tsp',
    't': 'tsp',
    'tsp': 'tsp',
    'teaspoon': 'tsp',
    'teaspoons': 'tsp',
    'كوب': 'cup',
    'أكواب': 'cup',
    'cup': 'cup',
    'cups': 'cup',
    'رطل': 'lb',
    'lb': 'lb',
    'pound': 'lb',
    'pounds': 'lb',
    'أونصة': 'oz',
    'أونصات': 'oz',
    'oz': 'oz',
    'ounce': 'oz',
    'ounces': 'oz',
    'كوارت': 'qt',
    'qt': 'qt',
    'باينت': 'pt',
    'pt': 'pt',
    'حبة': 'count',
    'حبات': 'count',
    'count': 'count',
  };
  static String canonical(String unit) => _synonyms[unit.trim()] ?? unit.trim();

  /// Definitional factors only (exact by definition, never density guesses):
  /// cup is the 240 ml measuring cup, oz is the weight ounce. Volume and
  /// weight stay separate dimensions; crossing them needs an explicit rule.
  static (String, double) _base(String unit) => switch (canonical(unit)) {
    'kg' => ('g', 1000),
    'lb' => ('g', 453.59237),
    'oz' => ('g', 28.349523125),
    'l' => ('ml', 1000),
    'dl' => ('ml', 100),
    'cup' => ('ml', 240),
    'tbsp' => ('ml', 15),
    'tsp' => ('ml', 5),
    'qt' => ('ml', 946.352946),
    'pt' => ('ml', 473.176473),
    final v => (v, 1),
  };
  static double? convert(
    double quantity,
    String from,
    String to, {
    required String ingredientId,
    List<UnitRule> rules = const [],
  }) {
    requireAmount(quantity, zero: true);
    final a = _base(from), b = _base(to);
    if (a.$1 == b.$1) return quantity * a.$2 / b.$2;
    for (final rule in rules.where((v) => v.ingredientId == ingredientId)) {
      final rFrom = _base(rule.from), rTo = _base(rule.to);
      if (a.$1 == rFrom.$1 && b.$1 == rTo.$1) {
        return quantity * a.$2 / rFrom.$2 * rule.factor * rTo.$2 / b.$2;
      }
      if (a.$1 == rTo.$1 && b.$1 == rFrom.$1) {
        return quantity * a.$2 / rTo.$2 / rule.factor * rFrom.$2 / b.$2;
      }
    }
    return null;
  }
}

class IngredientUse {
  IngredientUse(this.ingredientId, this.quantity, String unit)
    : unit = Units.canonical(unit) {
    requireAmount(quantity);
  }
  final String ingredientId, unit;
  final double quantity;
  Map<String, dynamic> toJson() => {
    'ingredientId': ingredientId,
    'quantity': quantity,
    'unit': unit,
  };
}

class StockAssessment {
  StockAssessment(this.after, this.missing, this.unresolved);
  final List<InventoryLot> after;
  final List<IngredientUse> missing;
  final Set<String> unresolved;
  bool get canCook => missing.isEmpty;
}

/// Allocates all requirements together, so duplicate ingredients cannot double-spend a lot.
StockAssessment assessStock(
  List<IngredientUse> uses,
  List<InventoryLot> stock, {
  List<UnitRule> rules = const [],
}) {
  if (stock.map((s) => s.id).toSet().length != stock.length) {
    throw ArgumentError('Duplicate stock lot IDs');
  }
  final after = List<InventoryLot>.of(stock),
      missing = <IngredientUse>[],
      unresolved = <String>{};
  for (final use in uses) {
    var remaining = use.quantity;
    for (var i = 0; i < after.length && remaining > 1e-9; i++) {
      final item = after[i];
      if (item.ingredientId != use.ingredientId) continue;
      if (item.quantity == null) {
        unresolved.add(item.ingredientId);
        continue;
      }
      final available = Units.convert(
        item.quantity!,
        item.unit,
        use.unit,
        ingredientId: item.ingredientId,
        rules: rules,
      );
      if (available == null) {
        unresolved.add(item.ingredientId);
        continue;
      }
      final taken = math.min(remaining, available);
      final inLot = Units.convert(
        taken,
        use.unit,
        item.unit,
        ingredientId: item.ingredientId,
        rules: rules,
      )!;
      after[i] = item.withQuantity(math.max(0, item.quantity! - inLot));
      remaining -= taken;
    }
    if (remaining > 1e-9) {
      missing.add(IngredientUse(use.ingredientId, remaining, use.unit));
    }
  }
  return StockAssessment(
    List.unmodifiable(after),
    List.unmodifiable(missing),
    Set.unmodifiable(unresolved),
  );
}

enum CalendarMode { day, week, month }

class CalendarRange {
  CalendarRange(DateTime date, CalendarMode mode) {
    final day = DateTime(date.year, date.month, date.day);
    start = switch (mode) {
      CalendarMode.day => day,
      CalendarMode.week => day.subtract(Duration(days: day.weekday - 1)),
      CalendarMode.month => DateTime(day.year, day.month),
    };
    end = switch (mode) {
      CalendarMode.day => DateTime(day.year, day.month, day.day + 1),
      CalendarMode.week => start.add(const Duration(days: 7)),
      CalendarMode.month => DateTime(day.year, day.month + 1),
    };
  }
  late final DateTime start, end;
  bool includes(String date) {
    final day = parseDay(date);
    return !day.isBefore(start) && day.isBefore(end);
  }
}

class PlannedMeal {
  PlannedMeal({
    required this.id,
    required this.date,
    required this.slot,
    required this.recipeId,
    required this.servings,
    this.completed = false,
    this.recipeRevisionKey,
  }) {
    parseDay(date);
    if (id.isEmpty ||
        slot.trim().isEmpty ||
        recipeId.isEmpty ||
        (recipeRevisionKey != null && recipeRevisionKey!.trim().isEmpty) ||
        servings < 1 ||
        servings > 1000) {
      throw ArgumentError('Invalid meal');
    }
  }
  final String id, date, slot, recipeId;
  final int servings;
  final bool completed;
  final String? recipeRevisionKey;
  PlannedMeal done() => PlannedMeal(
    id: id,
    date: date,
    slot: slot,
    recipeId: recipeId,
    servings: servings,
    completed: true,
    recipeRevisionKey: recipeRevisionKey,
  );
  PlannedMeal withRecipeRevision(String key) => PlannedMeal(
    id: id,
    date: date,
    slot: slot,
    recipeId: recipeId,
    servings: servings,
    completed: completed,
    recipeRevisionKey: key,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'slot': slot,
    'recipeId': recipeId,
    'servings': servings,
    'completed': completed,
    'recipeRevisionKey': recipeRevisionKey,
  };
  factory PlannedMeal.fromJson(Map<String, dynamic> v) => PlannedMeal(
    id: v['id'] as String,
    date: v['date'] as String,
    slot: v['slot'] as String,
    recipeId: v['recipeId'] as String,
    servings: v['servings'] as int,
    completed: v['completed'] == true,
    recipeRevisionKey: v['recipeRevisionKey'] as String?,
  );
}

class LeftoverDish {
  LeftoverDish({
    required this.id,
    required this.name,
    required this.servings,
    required this.preparedOn,
  }) {
    requireAmount(servings, zero: true);
    if (id.isEmpty || name.trim().isEmpty) {
      throw ArgumentError('Invalid leftover');
    }
    parseDay(preparedOn);
  }
  final String id, name, preparedOn;
  final double servings;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'servings': servings,
    'preparedOn': preparedOn,
  };
  factory LeftoverDish.fromJson(Map<String, dynamic> v) => LeftoverDish(
    id: v['id'] as String,
    name: v['name'] as String,
    servings: (v['servings'] as num).toDouble(),
    preparedOn: v['preparedOn'] as String,
  );
}

class BudgetPeriod {
  BudgetPeriod({
    required this.id,
    required this.start,
    required this.end,
    required this.limit,
    required this.country,
  }) {
    if (id.isEmpty) throw ArgumentError('Invalid budget ID');
    requireAmount(limit, zero: true);
    if (!parseDay(end).isAfter(parseDay(start))) {
      throw ArgumentError('Invalid budget period');
    }
  }
  final String id, start, end;
  final double limit;
  final MarketCountry country;
  bool includes(DateTime date) =>
      !date.isBefore(parseDay(start)) && date.isBefore(parseDay(end));
  Map<String, dynamic> toJson() => {
    'id': id,
    'start': start,
    'end': end,
    'limit': limit,
    'country': country.name,
  };
  factory BudgetPeriod.fromJson(Map<String, dynamic> v) => BudgetPeriod(
    id: v['id'] as String,
    start: v['start'] as String,
    end: v['end'] as String,
    limit: (v['limit'] as num).toDouble(),
    country: MarketCountry.values.byName(v['country'] as String),
  );
}

class MoneyEntry {
  MoneyEntry({
    required this.id,
    required this.amount,
    required this.country,
    required this.date,
    required this.note,
  }) {
    requireAmount(amount, zero: true);
  }
  final String id, note;
  final double amount;
  final MarketCountry country;
  final DateTime date;
  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'country': country.name,
    'date': date.toIso8601String(),
    'note': note,
  };
  factory MoneyEntry.fromJson(Map<String, dynamic> v) => MoneyEntry(
    id: v['id'] as String,
    amount: (v['amount'] as num).toDouble(),
    country: MarketCountry.values.byName(v['country'] as String),
    date: DateTime.parse(v['date'] as String),
    note: v['note'] as String,
  );
}

class BudgetSummary {
  BudgetSummary(
    BudgetPeriod period,
    List<MoneyEntry> purchases, {
    required this.plannedPurchases,
  }) : spent = purchases
           .where((p) => p.country == period.country && period.includes(p.date))
           .fold(0.0, (a, p) => a + p.amount),
       limit = period.limit {
    requireAmount(plannedPurchases, zero: true);
  }
  final double spent, limit, plannedPurchases;
  double get remaining => limit - spent;
  double get overrun => math.max(0, spent + plannedPurchases - limit);
  // Each period has its own explicit limit. No automatic carryover.
}
