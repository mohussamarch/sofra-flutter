import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/demo_data.dart';
import '../data/kitchen_service.dart';
import '../data/recipe_repository.dart';
import '../data/state_store.dart';
import '../domain/ingredient_directory.dart';
import '../domain/kitchen_core.dart';
import '../domain/market_profile.dart';
import '../domain/models.dart';
import '../domain/recipe_catalog.dart';

/// Household preferences kept beside `kitchen` in the same state document.
class Profile {
  const Profile({
    this.name = '',
    this.house = '',
    this.onboarded = false,
    this.servings = 4,
    this.cuisines = const {'egyptian'},
    this.allergies = const {},
    this.meals = const {'غدا', 'عشا'},
    this.saved = const {},
    this.quickMeals = true,
    this.reduceMotion = false,
  });

  final String name, house;
  final bool onboarded, quickMeals, reduceMotion;
  final int servings;

  /// Cuisine group IDs from the catalog (e.g. `egyptian`).
  final Set<String> cuisines;
  final Set<String> allergies, meals, saved;

  String get displayName => name.trim().isEmpty ? 'صاحب السفرة' : name.trim();
  String get houseName =>
      house.trim().isEmpty ? 'بيت $displayName' : house.trim();

  Profile copyWith({
    String? name,
    String? house,
    bool? onboarded,
    int? servings,
    Set<String>? cuisines,
    Set<String>? allergies,
    Set<String>? meals,
    Set<String>? saved,
    bool? quickMeals,
    bool? reduceMotion,
  }) => Profile(
    name: name ?? this.name,
    house: house ?? this.house,
    onboarded: onboarded ?? this.onboarded,
    servings: servings ?? this.servings,
    cuisines: cuisines ?? this.cuisines,
    allergies: allergies ?? this.allergies,
    meals: meals ?? this.meals,
    saved: saved ?? this.saved,
    quickMeals: quickMeals ?? this.quickMeals,
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );

  static const _legacyCuisines = {
    'مصري': 'egyptian',
    'شامي': 'levantine',
    'خليجي': 'saudi',
    'إيطالي': 'italian',
  };

  Map<String, Object?> toJson() => {
    'name': name,
    'house': house,
    'onboarded': onboarded,
    'servings': servings,
    'cuisineGroups': cuisines.toList(),
    'allergies': allergies.toList(),
    'meals': meals.toList(),
    'saved': saved.toList(),
    'quickMeals': quickMeals,
    'reduceMotion': reduceMotion,
  };

  factory Profile.fromRoot(Map<String, dynamic> root) {
    Set<String> strings(String key, Set<String> fallback) {
      final v = root[key];
      return v is List ? v.whereType<String>().toSet() : fallback;
    }

    // Older builds stored Arabic cuisine labels under `cuisines`.
    final groups = root['cuisineGroups'] is List
        ? strings('cuisineGroups', const {})
        : {
            for (final c in strings('cuisines', const {'مصري'}))
              ?_legacyCuisines[c],
          };
    return Profile(
      name: root['name'] as String? ?? '',
      house: root['house'] as String? ?? '',
      onboarded: root['onboarded'] == true,
      servings: ((root['servings'] as num?)?.toInt() ?? 4).clamp(1, 12),
      cuisines: groups,
      allergies: strings('allergies', const {}),
      meals: strings('meals', const {'غدا', 'عشا'}),
      saved: strings('saved', const {}),
      quickMeals: root['quickMeals'] != false,
      reduceMotion: root['reduceMotion'] == true,
    );
  }
}

/// Stock status of one recipe line against the current inventory.
enum LineStock { inStock, missing, unresolved, unmeasured, optional }

class CookingLine {
  CookingLine(
    this.index,
    this.ingredient,
    this.quantity,
    this.status, {
    this.missing,
  });
  final int index;
  final CatalogIngredient ingredient;
  final double? quantity;
  final LineStock status;

  /// Amount still needed in the recipe unit, for [LineStock.missing].
  final double? missing;
  bool get deducts => status == LineStock.inStock;
}

/// Per-line preview used by the table and the cooking confirmation sheet.
class CookingCheck {
  CookingCheck(this.scaled, this.lines);
  final ScaledCatalogRecipe scaled;
  final List<CookingLine> lines;
  Iterable<CookingLine> where(LineStock s) => lines.where((l) => l.status == s);
  bool get allInStock => lines.every(
    (l) => l.status == LineStock.inStock || l.status == LineStock.optional,
  );
}

class _MemoryStore implements StateStore {
  _MemoryStore(this.data);
  Map<String, dynamic>? data;
  @override
  String get label => 'غير محفوظ (تجربة)';
  @override
  Future<Map<String, dynamic>?> load() async => data;
  @override
  Future<void> save(Map<String, dynamic> value) async =>
      data = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
}

/// The app's single state owner: wraps [KitchenService] (the only writer of
/// the state document) and exposes what the screens read and do.
class SofraController extends ChangeNotifier {
  SofraController({
    StateStore? store,
    Map<String, dynamic>? initialData,
    RecipeRepository? recipes,
    Future<String> Function(String path)? readAsset,
  }) : persistent = store != null,
       recipes = recipes ?? RecipeRepository(),
       _readAsset = readAsset ?? rootBundle.loadString {
    kitchen = KitchenService(
      store ?? _MemoryStore(initialData),
      this.recipes,
      legacyUnits: {
        for (final e in demoIngredients.entries) e.key: e.value.unit,
      },
      stockIdOf: stockId,
    );
  }

  final bool persistent;
  final RecipeRepository recipes;
  final Future<String> Function(String path) _readAsset;
  late final KitchenService kitchen;

  /// Canonical ingredient vocabulary; recipe lines map to it for stock.
  IngredientDirectory? directory;

  /// Stock identity of a recipe ingredient ID (identity until loaded).
  String stockId(String rawId) => directory?.stockId(rawId) ?? rawId;

  bool ready = false;
  Object? loadError;
  bool saving = false;
  String? saveError;
  Future<void> Function()? _retry;
  Profile profile = const Profile();
  int _seq = 0;

  /// Unique within this session even when the clock does not move.
  String newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
  Map<String, String> _labels = {};

  String get storeLabel => kitchen.store.label;
  MarketProfile get market => kitchen.market;

  Future<void> load() async {
    try {
      directory ??= await IngredientDirectory.load(_readAsset);
      await kitchen.load();
      final root = kitchen.rootFields;
      profile = Profile.fromRoot(root);
      _labels = {
        for (final e in ((root['ingredientLabels'] as Map?) ?? {}).entries)
          e.key as String: e.value as String,
      };
      ready = true;
      loadError = null;
    } catch (e) {
      loadError = e;
    }
    notifyListeners();
  }

  /// Runs one write; on failure keeps it for [retrySave] and shows the banner.
  Future<bool> _save(Future<void> Function() write) async {
    saving = true;
    saveError = null;
    notifyListeners();
    try {
      await write();
      _retry = null;
      saving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _retry = write;
      saving = false;
      saveError = e is StateConflict
          ? 'بيانات حسابك اتغيرت على جهاز تاني. اقفل وافتح التطبيق لتحميل آخر نسخة؛ التعديلات هنا لم تُحفظ.'
          : 'آخر تعديل لسه متحفظش. راجع الاتصال وجرب الحفظ تاني قبل الخروج.';
      notifyListeners();
      return false;
    }
  }

  Future<void> retrySave() async {
    final retry = _retry;
    if (retry != null) await _save(retry);
  }

  /// Profile edits show immediately; a failed save keeps them on screen and
  /// the retry writes the latest profile.
  Future<void> updateProfile(Profile Function(Profile) change) {
    profile = change(profile);
    notifyListeners();
    return _save(() => kitchen.saveRootFields(profile.toJson()));
  }

  Future<void> setCountry(MarketCountry country) =>
      _save(() => kitchen.setCountry(country));

  // ---- Inventory ----------------------------------------------------------

  /// Lots with a known positive or unknown quantity; zero lots stay in data.
  List<InventoryLot> get stock =>
      kitchen.inventory.where((l) => l.quantity != 0).toList();

  /// Cooked dishes put away with servings left.
  List<LeftoverDish> get leftovers =>
      kitchen.leftovers.where((d) => d.servings > 0).toList();

  String ingredientName(String id) =>
      directory?.entry(id)?.name ??
      demoIngredients[id]?.name ??
      _labels[id] ??
      id.replaceAll('-', ' ');

  String? category(String id) =>
      directory?.entry(id)?.category ?? demoIngredients[id]?.category;

  /// Adds to stock as something the user already has (not a purchase).
  Future<void> addIngredient(
    String ingredientId,
    double amount,
    String unit,
    StorageZone zone,
  ) => _addAmount(ingredientId, amount, unit, zone);

  /// Quick "+" step in an entry's default unit.
  static double quickStep(String unit) => switch (Units.canonical(unit)) {
    'g' || 'ml' => 100,
    _ => 1,
  };

  /// Unit name for this ingredient: a counted piece uses its own word
  /// ("فرخة" rather than "حبة").
  String unitName(String id, String unit, {double amount = 1}) {
    final e = directory?.entry(id);
    if (Units.canonical(unit) == 'count' && e?.pieceName != null) {
      final n = amount.roundToDouble() == amount ? amount.toInt() : null;
      return n != null && n >= 3 && n <= 10
          ? e!.piecePlural ?? e.pieceName!
          : e!.pieceName!;
    }
    return Units.label(unit);
  }

  /// "3 فراخ", "1.5 كيلو".
  String amountText(String id, double amount, String unit) =>
      '${recipeNumber(amount)} ${unitName(id, unit, amount: amount)}';

  /// The user's own measure of one [unit] of this ingredient, in [to]
  /// (grams or millilitres).
  double? measureOf(String id, String unit, [String to = 'g']) {
    final from = Units.canonical(unit);
    for (final r in kitchen.unitRules) {
      if (r.ingredientId == id && r.from == from && r.to == to) {
        return r.factor;
      }
    }
    return null;
  }

  double? _convert(double amount, String from, String to, String id) =>
      Units.convert(
        amount,
        from,
        to,
        ingredientId: id,
        rules: kitchen.unitRules,
      );

  Future<void> _addAmount(
    String ingredientId,
    double amount,
    String unit,
    StorageZone zone,
  ) => _save(() async {
    // Merge into a lot in the same place when the units convert exactly.
    final same = kitchen.inventory.where(
      (l) =>
          l.ingredientId == ingredientId &&
          l.zone == zone &&
          l.quantity != null &&
          _convert(1, unit, l.unit, ingredientId) != null,
    );
    if (same.isNotEmpty) {
      final lot = same.first;
      final added = _convert(amount, unit, lot.unit, ingredientId)!;
      await kitchen.setStockQuantity(lot.id, lot.quantity! + added);
    } else {
      await kitchen.addStock(
        InventoryLot(
          id: newId('lot'),
          ingredientId: ingredientId,
          quantity: amount,
          unit: unit,
          zone: zone,
        ),
        newPurchase: false,
      );
    }
  });

  Future<void> setQuantity(String lotId, double quantity) =>
      _save(() => kitchen.setStockQuantity(lotId, quantity));

  Future<void> loadSample() async {
    for (final item in demoStarterStock) {
      await addIngredient(
        item.ingredientId,
        item.quantity,
        demoIngredients[item.ingredientId]!.unit,
        item.zone,
      );
    }
  }

  /// Saves "1 [from] of this ingredient = [factor] [to]", entered by the user.
  Future<bool> saveUnitRule(
    String ingredientId,
    String from,
    String to,
    double factor,
  ) => _save(
    () => kitchen.saveUnitRule(UnitRule(ingredientId, from, to, factor)),
  );

  /// Unit of the first stock lot with a known quantity, if any.
  String? stockUnit(String ingredientId) => kitchen.inventory
      .where((l) => l.ingredientId == ingredientId && l.quantity != null)
      .map((l) => l.unit)
      .firstOrNull;

  /// Records the missing amounts as stock the user says they now have. No
  /// price is invented: this is not logged as a purchase.
  Future<void> addMissing(CookingCheck check) async {
    final labels = <String, String>{};
    for (final line in check.where(LineStock.missing)) {
      final i = line.ingredient;
      final id = stockId(i.id);
      labels.putIfAbsent(id, () => i.name);
      await _addAmount(
        id,
        line.missing!,
        i.unit!,
        directory?.entry(id)?.zone ??
            demoIngredients[id]?.zone ??
            StorageZone.pantry,
      );
    }
    final unknown = {
      for (final e in labels.entries)
        if (directory?.entry(e.key) == null &&
            !demoIngredients.containsKey(e.key) &&
            _labels[e.key] != e.value)
          e.key: e.value,
    };
    if (unknown.isNotEmpty) {
      _labels = {..._labels, ...unknown};
      await _save(() => kitchen.saveRootFields({'ingredientLabels': _labels}));
    }
  }

  // ---- Recipes and planning ----------------------------------------------

  static String yieldVariantId(String recipeId) => 'yield-$recipeId';

  /// Recipe used for scaling and planning: the reviewed yield variant when the
  /// catalog source does not state its servings.
  Future<CatalogRecipe> planningRecipe(String recipeId) async {
    final active = kitchen.recipeBook.active[yieldVariantId(recipeId)];
    if (active != null) return kitchen.recipeBook.revisions[active]!.recipe;
    return recipes.get(recipeId);
  }

  String planningId(String recipeId) =>
      kitchen.recipeBook.active.containsKey(yieldVariantId(recipeId))
      ? yieldVariantId(recipeId)
      : recipeId;

  /// The user states how many people the whole source recipe feeds; stored as
  /// a personal revision, the catalog source stays unchanged.
  Future<bool> reviewYield(String recipeId, int servings) => _save(() async {
    final source = await kitchen.catalogRevision(recipeId);
    await kitchen.reviewRecipeYield(
      sourceRevisionKey: source.key,
      baseServings: servings,
      variantId: yieldVariantId(recipeId),
      revision: newId('v'),
      reviewNote: 'المستخدم حدد إن الوصفة كلها تكفي $servings أفراد',
      reviewedAt: DateTime.now(),
      acknowledgeWholeRecipeYield: true,
      expectedActiveKey: kitchen.recipeBook.active[yieldVariantId(recipeId)],
    );
  });

  List<PlannedMeal> plansOn(DateTime day) =>
      kitchen.calendar(day, CalendarMode.day);

  List<PlannedMeal> upcoming(DateTime from, {int days = 7}) =>
      kitchen.plans.where((p) {
        final d = parseDay(p.date);
        final start = DateTime(from.year, from.month, from.day);
        return !d.isBefore(start) &&
            d.isBefore(start.add(Duration(days: days)));
      }).toList()..sort((a, b) => a.date.compareTo(b.date));

  Future<bool> planMeal(
    String recipeId, {
    required DateTime day,
    required String slot,
    required int servings,
  }) => _save(
    () => kitchen.plan(
      PlannedMeal(
        id: newId('meal'),
        date: localDay(day),
        slot: slot,
        recipeId: planningId(recipeId),
        servings: servings,
      ),
    ),
  );

  Future<bool> removePlan(String id) => _save(() => kitchen.removePlan(id));

  Future<CatalogRecipe> recipeForPlan(String planId) async =>
      (await kitchen.recipeForMeal(planId)).recipe;

  /// Catalog name for a plan's recipe (yield variants keep the source name).
  Future<String> planTitle(PlannedMeal meal) async =>
      (await recipeForPlan(meal.id)).name;

  /// Line-by-line stock check that allocates lots once across the recipe.
  CookingCheck checkStock(ScaledCatalogRecipe scaled) {
    var after = kitchen.inventory;
    final lines = <CookingLine>[];
    final rows = scaled.recipe.ingredients;
    for (var i = 0; i < rows.length; i++) {
      final ingredient = rows[i];
      final quantity = scaled.quantity(ingredient);
      if (ingredient.optional) {
        lines.add(CookingLine(i, ingredient, quantity, LineStock.optional));
      } else if (quantity == null) {
        lines.add(CookingLine(i, ingredient, null, LineStock.unmeasured));
      } else if (ingredient.unit == null || quantity <= 0) {
        lines.add(CookingLine(i, ingredient, quantity, LineStock.unresolved));
      } else {
        final id = stockId(ingredient.id);
        final use = IngredientUse(id, quantity, ingredient.unit!);
        final result = assessStock([use], after, rules: kitchen.unitRules);
        if (result.canCook) {
          after = result.after;
          lines.add(CookingLine(i, ingredient, quantity, LineStock.inStock));
        } else if (result.unresolved.contains(id)) {
          lines.add(CookingLine(i, ingredient, quantity, LineStock.unresolved));
        } else {
          lines.add(
            CookingLine(
              i,
              ingredient,
              quantity,
              LineStock.missing,
              missing: result.missing.single.quantity,
            ),
          );
        }
      }
    }
    return CookingCheck(scaled, List.unmodifiable(lines));
  }

  Future<CookingCheck> checkPlan(PlannedMeal meal) async {
    final recipe = await recipeForPlan(meal.id);
    return checkStock(recipe.forServings(meal.servings));
  }

  /// Confirms cooking: in-stock lines are deducted; missing/unresolved lines
  /// are explicitly kept out of stock, unmeasured lines are omitted.
  Future<Map<String, dynamic>?> cook(
    PlannedMeal meal,
    CookingCheck check,
    String operationId,
  ) async {
    Map<String, dynamic>? record;
    final ok = await _save(() async {
      record = await kitchen.confirmCooking(
        meal.id,
        operationId,
        omitUnmeasuredLines: {
          for (final l in check.where(LineStock.unmeasured)) l.index,
        },
        untrackedStockLines: {
          for (final l in check.lines)
            if (l.status == LineStock.missing ||
                l.status == LineStock.unresolved)
              l.index,
        },
      );
    });
    return ok ? record : null;
  }
}
