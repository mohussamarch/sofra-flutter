import 'dart:convert';

import '../domain/kitchen_core.dart';
import '../domain/food_nutrition.dart';
import '../domain/person_nutrition.dart';
import '../domain/recipe_nutrition.dart';
import '../domain/recipe_catalog.dart';
import '../domain/recipe_variants.dart';
import '../domain/cooking_timer.dart';
import '../domain/market_profile.dart';
import '../domain/models.dart';
import 'recipe_repository.dart';
import 'recipe_reference_repository.dart';
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
    final nutrition = kitchen['nutrition'];
    if (nutrition != null) {
      final n = Map<String, dynamic>.from(nutrition as Map);
      if (n['version'] != 1) {
        throw const FormatException('Unsupported nutrition schema');
      }
      for (final v in (n['profiles'] as Map).values) {
        NutritionPersonProfile.fromJson(Map<String, dynamic>.from(v as Map));
      }
      for (final v in (n['selections'] as Map).values) {
        RecipeFoodSelection.fromJson(Map<String, dynamic>.from(v as Map));
      }
      NutritionLedger.fromJson(Map<String, dynamic>.from(n['ledger'] as Map));
    }
    final book = _recipeBook(kitchen);
    for (final raw in kitchen['plans'] as List) {
      final meal = PlannedMeal.fromJson(Map<String, dynamic>.from(raw as Map));
      if (meal.recipeRevisionKey != null &&
          book.revisions[meal.recipeRevisionKey]?.variantId != meal.recipeId) {
        throw const FormatException(
          'Planned recipe revision is missing or mismatched',
        );
      }
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
      // Firestore's current state document has a hard size limit. Keep margin
      // for field overhead and fail without deleting historical records.
      if (utf8.encode(jsonEncode(next)).length > 850000) {
        throw StateError(
          'State archive required before further saves (850KB guard)',
        );
      }
      await store.save(next);
      _root = next;
    });
    _tail = result.catchError((Object _) {});
    return result;
  }

  Map<String, dynamic> _nutrition(Map<String, dynamic> k) => k.putIfAbsent(
    'nutrition',
    () => <String, dynamic>{
      'version': 1,
      'profiles': <String, dynamic>{},
      'selections': <String, dynamic>{},
      'ledger': NutritionLedger.empty().toJson(),
    },
  ) as Map<String, dynamic>;

  NutritionLedger get nutritionLedger {
    final n = snapshot['nutrition'] as Map?;
    return n == null
        ? NutritionLedger.empty()
        : NutritionLedger.fromJson(
            Map<String, dynamic>.from(n['ledger'] as Map),
          );
  }

  NutritionPersonProfile? nutritionProfile(String memberId) {
    final n = snapshot['nutrition'] as Map?;
    final raw = (n?['profiles'] as Map?)?[memberId];
    return raw == null
        ? null
        : NutritionPersonProfile.fromJson(
            Map<String, dynamic>.from(raw as Map),
          );
  }

  Future<void> saveNutritionProfile(NutritionPersonProfile profile) => _write((
    k,
  ) {
    if (!(k['members'] as List).any((v) => v['id'] == profile.memberId)) {
      throw StateError('Nutrition profile must reference a household member');
    }
    (_nutrition(k)['profiles'] as Map)[profile.memberId] = profile.toJson();
  });

  RecipeBook _recipeBook(Map<String, dynamic> k) => k['recipeBook'] == null
      ? RecipeBook.empty()
      : RecipeBook.fromJson(Map<String, dynamic>.from(k['recipeBook'] as Map));

  RecipeBook get recipeBook => _recipeBook(snapshot);

  RecipeRevision _catalogDraft(CatalogRecipe recipe) => RecipeRevision(
    familyId: 'dish:${recipe.id}',
    revision: recipeSnapshotVersion(recipe),
    kind: RecipeRevisionKind.catalog,
    recipe: recipe,
  );

  RecipeBook _registerCatalog(RecipeBook book, RecipeRevision revision) {
    if (!book.families.containsKey(revision.familyId)) {
      book = book.addFamily(
        RecipeFamily(id: revision.familyId, name: revision.recipe.name),
      );
    }
    return book.addRevision(revision);
  }

  Future<RecipeRevision> catalogRevision(String recipeId) async {
    final revision = _catalogDraft(await recipes.get(recipeId));
    await _write((k) {
      k['recipeBook'] = _registerCatalog(_recipeBook(k), revision).toJson();
    });
    return revision;
  }

  Future<void> saveRecipeFamily(RecipeFamily family) => _write((k) {
    k['recipeBook'] = _recipeBook(k).addFamily(family).toJson();
  });

  Future<void> saveRecipeRevision(RecipeRevision revision) async {
    if (revision.kind == RecipeRevisionKind.catalog ||
        (await recipes.index).any((v) => v['id'] == revision.variantId)) {
      throw StateError('Custom recipes cannot overwrite catalog identities');
    }
    await _write((k) {
      k['recipeBook'] = _recipeBook(k).addRevision(revision).toJson();
    });
  }

  Future<RecipeRevision> _resolveMeal(PlannedMeal meal) async {
    final book = recipeBook;
    if (meal.recipeRevisionKey != null) {
      final revision = book.revisions[meal.recipeRevisionKey];
      if (revision == null || revision.variantId != meal.recipeId) {
        throw StateError('Unknown or mismatched recipe revision');
      }
      return revision;
    }
    final active = book.revisions[book.active[meal.recipeId]];
    if (active != null && active.kind != RecipeRevisionKind.catalog) {
      return active;
    }
    return _catalogDraft(await recipes.get(meal.recipeId));
  }

  Future<RecipeRevision> recipeForMeal(String planId) =>
      _resolveMeal(plans.where((v) => v.id == planId).single);

  Future<void> saveRecipeFoodSelection(RecipeFoodSelection selection) async {
    final revision = selection.recipeRevisionKey == null
        ? _catalogDraft(await recipes.get(selection.recipeId))
        : recipeBook.revisions[selection.recipeRevisionKey];
    if (revision == null || revision.variantId != selection.recipeId) {
      throw StateError('Selection must reference the exact recipe revision');
    }
    if (selection.line >= revision.recipe.ingredients.length) {
      throw RangeError('Recipe line');
    }
    final scoped = RecipeFoodSelection.fromJson({
      ...selection.toJson(),
      'recipeRevisionKey': revision.key,
    });
    await _write((k) {
      if (revision.kind == RecipeRevisionKind.catalog) {
        k['recipeBook'] = _registerCatalog(_recipeBook(k), revision).toJson();
      }
      (_nutrition(k)['selections'] as Map)[scoped.key] = scoped.toJson();
    });
  }

  /// Resolve outside the transaction, then atomically save exact revision bindings.
  /// Existing user-reviewed selections are preserved unless replacement is explicit.
  Future<RecipeReferenceApplication> applyRecipeReferences(
    String planId,
    RecipeReferenceRepository references, {
    required bool acknowledgeGenericReferences,
    Map<int, String> choices = const {},
    bool replaceExisting = false,
  }) async {
    final submittedChoices = Map<int, String>.from(choices);
    final meal = plans.where((v) => v.id == planId).single;
    if (meal.completed) {
      throw StateError('Cannot change a cooked meal reference review');
    }
    final revision = await _resolveMeal(meal);
    final resolution = await references.resolve(
      revision,
      acknowledgeGenericReferences: acknowledgeGenericReferences,
      choices: submittedChoices,
    );
    final applied = <int>[], preserved = <int>[];
    if (resolution.selections.isNotEmpty) {
      await _write((k) {
        final current = (k['plans'] as List)
            .where((v) => v['id'] == planId)
            .single;
        if (current['completed'] == true ||
            current['recipeRevisionKey'] != revision.key) {
          throw StateError('Plan changed during reference review');
        }
        final selections = _nutrition(k)['selections'] as Map;
        for (final selection in resolution.selections) {
          if (selections.containsKey(selection.key) && !replaceExisting) {
            preserved.add(selection.line);
          } else {
            selections[selection.key] = selection.toJson();
            applied.add(selection.line);
          }
        }
      });
    }
    return RecipeReferenceApplication(
      resolution: resolution,
      appliedLines: applied,
      preservedLines: preserved,
    );
  }

  List<RecipeFoodSelection> _foodSelections(
    Map<String, dynamic> k,
    RecipeRevision revision,
  ) {
    final n = k['nutrition'] as Map?;
    return ((n?['selections'] as Map?)?.values ?? const [])
        .map(
          (v) =>
              RecipeFoodSelection.fromJson(Map<String, dynamic>.from(v as Map)),
        )
        .where(
          (v) =>
              v.recipeId == revision.variantId &&
              v.recipeRevisionKey == revision.key,
        )
        .toList();
  }

  Future<RecipeNutritionResult> previewNutrition(
    String planId, {
    Set<String> optionalIds = const {},
    Set<int>? optionalLines,
    Set<int> excludedLines = const {},
    Map<int, FoodAmount> measuredLines = const {},
    double? cookedYieldGrams,
  }) async {
    final meal = plans.where((v) => v.id == planId).single;
    final revision = await _resolveMeal(meal);
    return assessRecipeNutrition(
      scaled: revision.recipe.forServings(meal.servings),
      selections: _foodSelections(snapshot, revision),
      recipeRevisionKey: revision.key,
      optionalIds: optionalIds,
      optionalLines: optionalLines,
      excludedLines: excludedLines,
      measuredLines: measuredLines,
      cookedYieldGrams: cookedYieldGrams,
    );
  }

  /// A separate input-only estimate; never used for cooked history or intake.
  /// Quantity form is preserved: cooked weights cannot be reinterpreted as raw.
  Future<IngredientNutritionEstimate> previewIngredientNutrition(
    String planId, {
    Set<String> optionalIds = const {},
    Set<int>? optionalLines,
    Set<int> excludedLines = const {},
    Map<int, FoodAmount> measuredLines = const {},
  }) async {
    final meal = plans.where((v) => v.id == planId).single;
    final revision = await _resolveMeal(meal);
    final inputs = _foodSelections(snapshot, revision)
        .map(
          (v) => RecipeFoodSelection.fromJson({
            ...v.toJson(),
            'preparedForm': v.food.form.name,
            'preparation': null,
          }),
        )
        .toList();
    return IngredientNutritionEstimate(
      assessRecipeNutrition(
        scaled: revision.recipe.forServings(meal.servings),
        selections: inputs,
        recipeRevisionKey: revision.key,
        optionalIds: optionalIds,
        optionalLines: optionalLines,
        excludedLines: excludedLines,
        measuredLines: measuredLines,
      ),
    );
  }

  /// Product snacks and planned meal batches may be explicitly registered.
  /// Cooked recipe batches are created atomically by confirmCooking instead.
  Future<void> recordNutritionEvents({
    MealBatch? batch,
    required List<NutritionEvent> events,
  }) => _write((k) {
    final n = _nutrition(k);
    var ledger = NutritionLedger.fromJson(
      Map<String, dynamic>.from(n['ledger'] as Map),
    );
    if (batch != null) ledger = ledger.addBatch(batch);
    for (final event in events) {
      if (event.personId != null &&
          !(k['members'] as List).any((v) => v['id'] == event.personId) &&
          !ledger.events.any((v) => v.personId == event.personId)) {
        throw StateError('Unknown nutrition person');
      }
      ledger = ledger.append(event);
    }
    n['ledger'] = ledger.toJson();
  });

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
    final revision = await _resolveMeal(meal);
    final pinned = meal.withRecipeRevision(revision.key);
    await _write((k) {
      if (revision.kind == RecipeRevisionKind.catalog) {
        k['recipeBook'] = _registerCatalog(_recipeBook(k), revision).toJson();
      }
      final plans = k['plans'] as List,
          index = plans.indexWhere((v) => v['id'] == meal.id);
      if (meal.completed || (index >= 0 && plans[index]['completed'] == true)) {
        throw StateError('Cannot replace a cooked meal');
      }
      if (index < 0) {
        plans.add(pinned.toJson());
      } else {
        plans[index] = pinned.toJson();
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
  /// ingredients support line-specific selection and measurement. Legacy ID
  /// inputs are only safe for unique lines; no quantity is guessed from a label.
  Future<Map<String, dynamic>> confirmCooking(
    String planId,
    String operationId, {
    Set<String> optionalIds = const {},
    Set<int>? optionalLines,
    Map<int, IngredientUse> measuredUsesByLine = const {},
    Set<int> omitUnmeasuredLines = const {},
    Map<String, IngredientUse> measuredUses = const {},
    Set<String> omitUnmeasured = const {},
    List<UnitRule> rules = const [],
    DateTime? cookedAt,
    double? cookedYieldGrams,
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
    final revision = await _resolveMeal(meal);
    final scaled = revision.recipe.forServings(meal.servings);
    final rows = scaled.recipe.ingredients;
    bool validLine(int i) => i >= 0 && i < rows.length;
    if (optionalLines != null && optionalIds.isNotEmpty) {
      throw ArgumentError(
        'Choose optional ingredients by IDs or lines, not both',
      );
    }
    if ((optionalLines ?? {}).any((i) => !validLine(i) || !rows[i].optional) ||
        omitUnmeasuredLines.any(
          (i) => !validLine(i) || scaled.quantity(rows[i]) != null,
        ) ||
        measuredUsesByLine.entries.any(
          (e) =>
              !validLine(e.key) ||
              scaled.quantity(rows[e.key]) != null ||
              e.value.ingredientId != rows[e.key].id,
        )) {
      throw ArgumentError('Invalid optional/measured/omitted recipe line');
    }
    final uses = <IngredientUse>[];
    final actualMeasured = <int, IngredientUse>{};
    final omittedLines = <int>{};
    final selectedOptionalLines = <int>{};
    for (var i = 0; i < rows.length; i++) {
      final ingredient = rows[i];
      if (ingredient.optional) {
        if (!(optionalLines?.contains(i) ??
            optionalIds.contains(ingredient.id))) {
          continue;
        }
        selectedOptionalLines.add(i);
      }
      final quantity = scaled.quantity(ingredient);
      if (quantity == null) {
        if (omitUnmeasuredLines.contains(i) ||
            omitUnmeasured.contains(ingredient.id)) {
          if (measuredUsesByLine.containsKey(i) ||
              measuredUses.containsKey(ingredient.id)) {
            throw ArgumentError('Cannot both measure and omit a recipe line');
          }
          omittedLines.add(i);
          continue;
        }
        final explicit = measuredUsesByLine[i] ?? measuredUses[ingredient.id];
        if (!measuredUsesByLine.containsKey(i) &&
            measuredUses.containsKey(ingredient.id) &&
            rows
                    .where(
                      (r) =>
                          r.id == ingredient.id && scaled.quantity(r) == null,
                    )
                    .length >
                1) {
          throw StateError(
            'Repeated unmeasured ingredient requires line-specific measurements',
          );
        }
        if (explicit == null || explicit.ingredientId != ingredient.id) {
          throw StateError(
            'Review unmeasured recipe line $i: ${ingredient.id}',
          );
        }
        uses.add(explicit);
        actualMeasured[i] = explicit;
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
      if (current.recipeRevisionKey != meal.recipeRevisionKey ||
          current.recipeId != meal.recipeId ||
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
      if (revision.kind == RecipeRevisionKind.catalog) {
        k['recipeBook'] = _registerCatalog(_recipeBook(k), revision).toJson();
      }
      list[index] = current.withRecipeRevision(revision.key).done().toJson();
      final measuredLines = <int, FoodAmount>{};
      for (var i = 0; i < scaled.recipe.ingredients.length; i++) {
        final row = scaled.recipe.ingredients[i], explicit = actualMeasured[i];
        if (scaled.quantity(row) == null && explicit != null) {
          final unit = nutritionUnit(explicit.unit);
          if (unit == null) {
            throw StateError(
              'Review actual measurement unit for recipe line $i',
            );
          }
          measuredLines[i] = FoodAmount(value: explicit.quantity, unit: unit);
        }
      }
      final nutrition = assessRecipeNutrition(
        scaled: scaled,
        selections: _foodSelections(k, revision),
        recipeRevisionKey: revision.key,
        optionalLines: selectedOptionalLines,
        excludedLines: omittedLines,
        measuredLines: measuredLines,
        cookedYieldGrams: cookedYieldGrams,
      );
      final n = _nutrition(k), allergenIds = <String>{};
      for (final raw in (n['profiles'] as Map).values) {
        final profile = NutritionPersonProfile.fromJson(
          Map<String, dynamic>.from(raw as Map),
        );
        allergenIds.addAll(profile.allergies.map((v) => v.allergenId));
      }
      final batch = nutritionMealBatch(
        nutrition,
        batchId: 'cooked:$operationId',
        sourceSnapshotId: operationId,
        allergenIds: allergenIds,
      );
      final ledger = NutritionLedger.fromJson(
        Map<String, dynamic>.from(n['ledger'] as Map),
      );
      n['ledger'] = ledger.addBatch(batch).toJson();
      history.add({
        'operationId': operationId,
        'planId': planId,
        'recipeId': meal.recipeId,
        'recipeRevision': revision.toJson(),
        'recipeFamily': _recipeBook(k).families[revision.familyId]!.toJson(),
        'servings': meal.servings,
        'cookedAt': (cookedAt ?? DateTime.now()).toIso8601String(),
        'country': k['country'],
        'currency': MarketProfile.fromCode(k['country'] as String).currency,
        'consumed': uses.map((v) => v.toJson()).toList(),
        'omittedUnmeasured': omitUnmeasured.toList(),
        'selectedOptional': optionalIds.toList(),
        'selectedOptionalLines': selectedOptionalLines.toList(),
        'omittedUnmeasuredLines': omittedLines.toList(),
        'nutrition': nutrition.toJson(),
        'nutritionBatchId': batch.id,
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
