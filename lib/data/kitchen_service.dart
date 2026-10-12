import 'dart:convert';

import '../domain/kitchen_core.dart';
import '../domain/cooking_timer.dart';
import '../domain/market_profile.dart';
import '../domain/models.dart';
import 'recipe_repository.dart';
import 'state_store.dart';

Map<String, dynamic> _clone(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
Map<String, dynamic> _fresh() => {
  'version': 1,
  'country': 'EG',
  'members': [],
  'seats': [],
  'inventory': [],
  'leftovers': [],
  'plans': [],
  'history': [],
  'prices': [],
  'purchases': [],
  'budgets': [],
};

/// One state owner for the future UI. Writes are atomic and published only after
/// the existing local/Firestore store succeeds; stale cloud writes still fail.
class KitchenService {
  KitchenService(this.store, this.recipes, {this.legacyUnits = const {}});
  final StateStore store;
  final RecipeRepository recipes;
  final Map<String, String> legacyUnits;
  Map<String, dynamic>? _root;
  Future<void> _tail = Future.value();
  Map<String, dynamic> get snapshot {
    if (_root == null) throw StateError('Load before use');
    return _clone(_root!['kitchen'] as Map<String, dynamic>);
  }

  MarketProfile get market =>
      MarketProfile.fromCode(snapshot['country'] as String?);
  List<InventoryLot> get inventory => List.unmodifiable(
    (snapshot['inventory'] as List).map(
      (v) => InventoryLot.fromJson(Map<String, dynamic>.from(v as Map)),
    ),
  );
  List<PlannedMeal> get plans => List.unmodifiable(
    (snapshot['plans'] as List).map(
      (v) => PlannedMeal.fromJson(Map<String, dynamic>.from(v as Map)),
    ),
  );

  Future<void> load() async {
    await _tail;
    final root =
        await store.load() ?? {'schema': 1, 'name': '', 'stock': <dynamic>[]};
    if (root['schema'] != 1) {
      throw const FormatException('Unsupported state schema');
    }
    final raw = root['kitchen'];
    final kitchen = raw == null
        ? _fresh()
        : Map<String, dynamic>.from(raw as Map);
    if (root['country'] == 'EG' || root['country'] == 'SA') {
      kitchen['country'] = root['country'];
    }
    if (kitchen['version'] != 1) {
      throw const FormatException('Unsupported kitchen schema');
    }
    if (raw == null) {
      final rows = root['stock'] as List? ?? [];
      final migrated = <Map<String, dynamic>>[];
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i] as Map, id = row['id'] as String;
        final unit = legacyUnits[id];
        if (unit == null) throw StateError('Missing legacy unit for $id');
        migrated.add(
          InventoryLot(
            id: 'legacy-$i',
            ingredientId: id,
            quantity: (row['quantity'] as num).toDouble(),
            unit: unit,
            zone: StorageZone.values.byName(row['zone'] as String),
          ).toJson(),
        );
      }
      kitchen['inventory'] = migrated;
    }
    for (final row in kitchen['inventory'] as List) {
      InventoryLot.fromJson(Map<String, dynamic>.from(row as Map));
    }
    for (final row in kitchen['members'] as List) {
      HouseholdMember.fromJson(Map<String, dynamic>.from(row as Map));
    }
    for (final row in kitchen['plans'] as List) {
      PlannedMeal.fromJson(Map<String, dynamic>.from(row as Map));
    }
    root['kitchen'] = kitchen;
    _root = _clone(root);
  }

  Future<void> _write(void Function(Map<String, dynamic>) change) {
    final result = _tail.then((_) async {
      if (_root == null) throw StateError('Load before saving');
      final next = _clone(_root!);
      change(next['kitchen'] as Map<String, dynamic>);
      if (jsonEncode(next) == jsonEncode(_root)) return;
      next['country'] = (next['kitchen'] as Map)['country'];
      await store.save(next);
      _root = next;
    });
    _tail = result.catchError((Object _) {});
    return result;
  }

  Future<void> saveTimer(String id, CookingTimer timer) => _write((k) {
    if (id.isEmpty) throw ArgumentError('Missing timer ID');
    final timers = k.putIfAbsent('timers', () => <String, dynamic>{}) as Map;
    timers[id] = timer.toJson();
  });

  CookingTimer? timer(String id, DateTime now) {
    final timers = snapshot['timers'] as Map?;
    final value = timers?[id];
    return value == null
        ? null
        : CookingTimer.fromJson(Map<String, dynamic>.from(value as Map))
              .at(now);
  }

  Future<void> setCountry(MarketCountry country) =>
      _write((k) => k['country'] = MarketProfile(country).code);

  Future<void> saveMember(HouseholdMember member) => _write((k) {
    final members = k['members'] as List,
        index = members.indexWhere((v) => v['id'] == member.id);
    final seats = k['seats'] as List;
    while (seats.length < 3) {
      seats.add(null);
    }
    if (index < 0) {
      members.add(member.toJson());
      final empty = seats.indexOf(null);
      if (empty < 0) {
        seats.add(member.id);
      } else {
        seats[empty] = member.id;
      }
    } else {
      members[index] = member.toJson();
    }
  });

  Future<void> swapSeats(int a, int b) => _write((k) {
    final seats = k['seats'] as List;
    if (a < 0 || b < 0 || a >= seats.length || b >= seats.length) {
      throw RangeError('Seat index');
    }
    final old = seats[a];
    seats[a] = seats[b];
    seats[b] = old;
  });

  Future<void> removeMember(String id) => _write((k) {
    (k['members'] as List).removeWhere((v) => v['id'] == id);
    final seats = k['seats'] as List;
    for (var i = 0; i < seats.length; i++) {
      if (seats[i] == id) seats[i] = null;
    }
  });

  Future<void> addStock(
    InventoryLot lot, {
    required bool newPurchase,
    double? paid,
    DateTime? purchasedAt,
  }) => _write((k) {
    final items = k['inventory'] as List;
    if (items.any((v) => v['id'] == lot.id)) {
      throw StateError('Stock lot already exists');
    }
    if (items.length >= 1000) throw StateError('Inventory limit reached');
    if (newPurchase) {
      if (paid == null || purchasedAt == null) {
        throw ArgumentError('Confirm purchase amount and date');
      }
      final entry = MoneyEntry(
        id: 'purchase-${lot.id}',
        amount: paid,
        country: MarketProfile.fromCode(k['country'] as String).country,
        date: purchasedAt,
        note: lot.ingredientId,
      );
      (k['purchases'] as List).add(entry.toJson());
    }
    items.add(lot.toJson());
  });

  Future<void> setStockQuantity(String lotId, double? quantity) => _write((k) {
    if (quantity != null) requireAmount(quantity, zero: true);
    final row =
        (k['inventory'] as List).where((v) => v['id'] == lotId).single as Map;
    row['quantity'] = quantity;
  });

  Future<void> saveLeftover(LeftoverDish dish) => _write((k) {
    final list = k['leftovers'] as List,
        index = list.indexWhere((v) => v['id'] == dish.id);
    if (index < 0) {
      list.add(dish.toJson());
    } else {
      list[index] = dish.toJson();
    }
  });
  Future<void> consumeLeftover(String id, double servings) => _write((k) {
    requireAmount(servings);
    final row =
        (k['leftovers'] as List).where((v) => v['id'] == id).single as Map;
    final available = (row['servings'] as num).toDouble();
    if (available < servings) throw StateError('Insufficient leftovers');
    row['servings'] = available - servings;
  });

  Future<void> plan(PlannedMeal meal) async {
    await recipes.get(meal.recipeId);
    await _write((k) {
      final plans = k['plans'] as List,
          index = plans.indexWhere((v) => v['id'] == meal.id);
      if (meal.completed || (index >= 0 && plans[index]['completed'] == true)) {
        throw StateError('Cannot replace a cooked meal');
      }
      if (index < 0) {
        plans.add(meal.toJson());
      } else {
        plans[index] = meal.toJson();
      }
    });
  }

  Future<void> removePlan(String id) => _write((k) {
    final list = k['plans'] as List;
    if (list.any((v) => v['id'] == id && v['completed'] == true)) {
      throw StateError('Cannot remove cooking history');
    }
    list.removeWhere((v) => v['id'] == id);
  });
  List<PlannedMeal> calendar(DateTime date, CalendarMode mode) =>
      plans.where((p) => CalendarRange(date, mode).includes(p.date)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  Future<void> savePrice(MarketPrice price, {required bool userOverride}) =>
      _write((k) {
        final list = k['prices'] as List;
        list.removeWhere(
          (v) =>
              v['country'] == price.country.name &&
              v['ingredientId'] == price.ingredientId &&
              v['unit'] == Units.canonical(price.unit) &&
              v['override'] == userOverride,
        );
        list.add({
          'country': price.country.name,
          'ingredientId': price.ingredientId,
          'unit': Units.canonical(price.unit),
          'quantity': price.quantity,
          'amount': price.amount,
          'date': price.recordedAt.toIso8601String(),
          'source': price.source,
          'override': userOverride,
        });
      });
  static double? _cost(
    Map<String, dynamic> k,
    IngredientUse use,
    List<UnitRule> rules,
  ) {
    final market = MarketProfile.fromCode(k['country'] as String).country.name;
    final prices =
        (k['prices'] as List)
            .where(
              (v) =>
                  v['country'] == market &&
                  v['ingredientId'] == use.ingredientId,
            )
            .toList()
          ..sort(
            (a, b) => (b['override'] == true ? 1 : 0).compareTo(
              a['override'] == true ? 1 : 0,
            ),
          );
    for (final p in prices) {
      final amount = Units.convert(
        use.quantity,
        use.unit,
        p['unit'] as String,
        ingredientId: use.ingredientId,
        rules: rules,
      );
      if (amount != null) {
        return amount / (p['quantity'] as num) * (p['amount'] as num);
      }
    }
    return null;
  }

  double? estimatedCost(IngredientUse use, {List<UnitRule> rules = const []}) =>
      _cost(snapshot, use, rules);

  Future<void> saveBudget(BudgetPeriod budget) => _write((k) {
    final list = k['budgets'] as List,
        index = list.indexWhere((v) => v['id'] == budget.id);
    if (index < 0) {
      list.add(budget.toJson());
    } else {
      list[index] = budget.toJson();
    }
  });
  BudgetSummary budgetSummary(String id, {double plannedPurchases = 0}) {
    final k = snapshot;
    final budget = BudgetPeriod.fromJson(
      Map<String, dynamic>.from(
        (k['budgets'] as List).where((v) => v['id'] == id).single as Map,
      ),
    );
    final purchases = (k['purchases'] as List)
        .map((v) => MoneyEntry.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
    return BudgetSummary(budget, purchases, plannedPurchases: plannedPurchases);
  }

  /// Caller must explicitly resolve/acknowledge unmeasured ingredients. Optional
  /// ingredients are selected by ID, and no quantity is guessed from a label.
  Future<Map<String, dynamic>> confirmCooking(
    String planId,
    String operationId, {
    Set<String> optionalIds = const {},
    Map<String, IngredientUse> measuredUses = const {},
    Set<String> omitUnmeasured = const {},
    List<UnitRule> rules = const [],
    DateTime? cookedAt,
  }) async {
    if (operationId.trim().isEmpty) throw ArgumentError('Missing operation ID');
    final old = (snapshot['history'] as List).where(
      (v) => v['operationId'] == operationId,
    );
    if (old.isNotEmpty) {
      if (old.single['planId'] != planId) {
        throw StateError('Operation ID reused for another meal');
      }
      return Map<String, dynamic>.from(old.single as Map);
    }
    final meal = plans.where((p) => p.id == planId).single;
    final scaled = (await recipes.get(meal.recipeId))
        .forServings(meal.servings);
    final uses = <IngredientUse>[];
    for (final ingredient in scaled.recipe.ingredients) {
      if (ingredient.optional && !optionalIds.contains(ingredient.id)) continue;
      final quantity = scaled.quantity(ingredient);
      if (quantity == null) {
        final explicit = measuredUses[ingredient.id];
        if (explicit != null && explicit.ingredientId == ingredient.id) {
          uses.add(explicit);
        } else if (!omitUnmeasured.contains(ingredient.id)) {
          throw StateError('Review unmeasured ingredient: ${ingredient.id}');
        }
      } else {
        uses.add(IngredientUse(ingredient.id, quantity, ingredient.unit!));
      }
    }
    await _write((k) {
      final history = k['history'] as List;
      final previous = history.where((v) => v['operationId'] == operationId);
      if (previous.isNotEmpty) {
        if (previous.single['planId'] != planId) {
          throw StateError('Operation ID reused');
        }
        return;
      }
      final list = k['plans'] as List,
          index = list.indexWhere((v) => v['id'] == planId);
      if (index < 0 || list[index]['completed'] == true) {
        throw StateError('Meal missing or already cooked');
      }
      final current = PlannedMeal.fromJson(
        Map<String, dynamic>.from(list[index] as Map),
      );
      if (current.recipeId != meal.recipeId ||
          current.servings != meal.servings) {
        throw StateError('Meal changed; review again');
      }
      final stock = (k['inventory'] as List)
          .map(
            (v) => InventoryLot.fromJson(Map<String, dynamic>.from(v as Map)),
          )
          .toList();
      final assessment = assessStock(uses, stock, rules: rules);
      if (!assessment.canCook) {
        throw StateError('Insufficient stock or unresolved units');
      }
      var total = 0.0;
      final unknown = <String>[];
      for (final use in uses) {
        final value = _cost(k, use, rules);
        if (value == null) {
          unknown.add(use.ingredientId);
        } else {
          total += value;
        }
      }
      k['inventory'] = assessment.after.map((v) => v.toJson()).toList();
      list[index] = current.done().toJson();
      history.add({
        'operationId': operationId,
        'planId': planId,
        'recipeId': meal.recipeId,
        'servings': meal.servings,
        'cookedAt': (cookedAt ?? DateTime.now()).toIso8601String(),
        'country': k['country'],
        'currency': MarketProfile.fromCode(k['country'] as String).currency,
        'consumed': uses.map((v) => v.toJson()).toList(),
        'omittedUnmeasured': omitUnmeasured.toList(),
        'selectedOptional': optionalIds.toList(),
        'cost': unknown.isEmpty ? total : null,
        'knownCost': total,
        'unpricedIngredients': unknown,
      });
    });
    return Map<String, dynamic>.from(
      (snapshot['history'] as List)
              .where((v) => v['operationId'] == operationId)
              .single
          as Map,
    );
  }
}
