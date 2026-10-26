import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/community_backend.dart';
import '../data/demo_data.dart';
import '../data/food_repository.dart';
import '../data/recipe_photo_library.dart';
import '../data/kitchen_service.dart';
import '../data/recipe_repository.dart';
import '../data/state_store.dart';
import '../domain/ingredient_directory.dart';
import '../domain/kitchen_core.dart';
import '../domain/market_profile.dart';
import '../domain/models.dart';
import '../domain/monthly_budget_choices.dart';
import '../domain/monthly_budget_search.dart';
import '../domain/community.dart';
import '../domain/food_nutrition.dart';
import '../domain/personal_recipe_draft.dart';
import '../domain/personal_recipe_finalization.dart';
import '../domain/purchase_forecast.dart';
import '../domain/recipe_variants.dart';
import '../domain/recipe_catalog.dart';
import 'reminders.dart';
import 'scope.dart' show mealSlots;

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
    this.mealTimes = const {},
    this.remindBefore = 30,
    this.stockAlerts = true,
    this.area = '',
  });

  final String name, house;
  final bool onboarded, quickMeals, reduceMotion;
  final int servings;

  /// Cuisine group IDs from the catalog (e.g. `egyptian`).
  final Set<String> cuisines;
  final Set<String> allergies, meals, saved;

  /// Meal slot -> minutes after midnight, as the user set them. A slot with
  /// no time gets no meal reminder.
  final Map<String, int> mealTimes;

  /// Minutes before a meal's time to remind.
  final int remindBefore;

  /// Notify when cooking uses up an ingredient.
  final bool stockAlerts;

  /// City or district the user typed, for prices from people nearby.
  final String area;

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
    Map<String, int>? mealTimes,
    int? remindBefore,
    bool? stockAlerts,
    String? area,
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
    mealTimes: mealTimes ?? this.mealTimes,
    remindBefore: remindBefore ?? this.remindBefore,
    stockAlerts: stockAlerts ?? this.stockAlerts,
    area: area ?? this.area,
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
    'mealTimes': mealTimes,
    'remindBefore': remindBefore,
    'stockAlerts': stockAlerts,
    'area': area,
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
      mealTimes: {
        for (final e in ((root['mealTimes'] as Map?) ?? const {}).entries)
          if (e.key is String &&
              e.value is num &&
              e.value >= 0 &&
              e.value < 1440)
            e.key as String: (e.value as num).toInt(),
      },
      remindBefore: ((root['remindBefore'] as num?)?.toInt() ?? 30).clamp(
        0,
        240,
      ),
      stockAlerts: root['stockAlerts'] != false,
      area: root['area'] as String? ?? '',
    );
  }
}

/// What a scanned barcode is: the bundled product record when there is one,
/// and the kitchen ingredient the user linked it to before.
class ScannedProduct {
  const ScannedProduct(
    this.code, {
    this.name,
    this.brand,
    this.packageLabel,
    this.ingredientId,
  });
  final String code;
  final String? name, brand, packageLabel, ingredientId;
  bool get known => name != null;
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
    this.stockId,
  });
  final int index;
  final CatalogIngredient ingredient;
  final double? quantity;
  final LineStock status;

  /// Amount still needed in the recipe unit, for [LineStock.missing].
  final double? missing;

  /// The stock identity used when the line offers alternatives and a later
  /// one is the one in stock; null means the line's own identity.
  final String? stockId;
  bool get deducts => status == LineStock.inStock;

  /// Missing, but part of it is in stock and gets used.
  bool get partial =>
      status == LineStock.missing &&
      quantity != null &&
      missing != null &&
      missing! < quantity! - 1e-9;
}

/// A priced month: the user's weekly menu repeated over a calendar month,
/// checked against their budget with their own prices. Nothing is saved
/// until [SofraController.acceptMonth].
class MonthPlan {
  MonthPlan._(this.budget, this.preview, this.unmeasured);
  final BudgetPeriod budget;
  final MonthlyBudgetSearchPreview preview;

  /// Lines without an amount the user chose to leave out of the cost
  /// ("ملح حسب الرغبة"); empty when they were kept (and the cost unknown).
  final Set<String> unmeasured;

  MonthlyBudgetSearchResult get search => preview.search;
  MonthlyBudgetSearchOutcome get outcome => search.outcome;

  /// Cheapest option whose purchases fit the budget.
  MonthlyBudgetAssessment? get best => search.bestKnownAffordable;

  /// Cheapest fully priced option, affordable or not.
  MonthlyBudgetAssessment? get cheapest => search.eligibleRanked.firstOrNull;

  /// What still needs a price before the month can be judged, as
  /// stock id -> the unit the purchase is in.
  Map<String, String> get unpriced => {
    for (final a in search.comparison.unranked)
      for (final p in a.forecast.purchases)
        if (p.estimatedCost == null) p.use.ingredientId: p.use.unit,
  };

  /// Stock that is kept in a unit the recipes can't be converted to.
  Set<String> get unresolved => {
    for (final a in search.comparison.assessments) ...{
      ...a.forecast.unresolvedRequirements,
      ...a.forecast.unresolvedStock,
    },
  };
}

/// One ingredient of a recipe the user writes: a kitchen ingredient and an
/// amount they state, or no amount ("حسب الرغبة"), which never scales.
class MyRecipeLine {
  const MyRecipeLine(this.stockId, this.name, {this.amount, this.unit});
  final String stockId, name;
  final double? amount;

  /// g, kg, ml, l or count.
  final String? unit;
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
    ReminderSink? reminders,
    this.community,
    this.reopen,
    this.communityPreview = false,
  }) : persistent = store != null,
       reminders = reminders ?? SilentReminders(),
       recipes = recipes ?? RecipeRepository(),
       _readAsset = readAsset ?? rootBundle.loadString {
    kitchen = KitchenService(
      store ?? _MemoryStore(initialData),
      this.recipes,
      legacyUnits: {
        for (final e in demoIngredients.entries) e.key: e.value.unit,
      },
      stockIdOf: stockId,
      stockOptionsOf: stockOptions,
    );
  }

  final bool persistent;
  final RecipeRepository recipes;
  final Future<String> Function(String path) _readAsset;
  late final KitchenService kitchen;

  /// Phone notifications (silent in tests).
  final ReminderSink reminders;

  /// Shared kitchen and community; null when not signed in (local mode).
  final CommunityBackend? community;

  /// Reopens the session after joining or leaving a shared kitchen.
  final VoidCallback? reopen;

  /// The community runs on this device only (no account): nothing reaches
  /// other people.
  final bool communityPreview;

  /// Verified Arab cooking channels suggested in the community.
  Future<List<Creator>> creators() async {
    try {
      final json = jsonDecode(
        await _readAsset('assets/community/creators.json'),
      ) as Map<String, dynamic>;
      return [
        for (final c in json['creators'] as List)
          Creator.fromJson(Map<String, dynamic>.from(c as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<Story> postStory(String text, {String? dish, int colorIndex = 0}) =>
      _community.postStory(
        name: profile.houseName,
        text: text,
        dish: dish,
        colorIndex: colorIndex,
      );

  /// Canonical ingredient vocabulary; recipe lines map to it for stock.
  IngredientDirectory? directory;

  /// Stock identity of a recipe ingredient ID (identity until loaded).
  String stockId(String rawId) => directory?.stockId(rawId) ?? rawId;

  /// Names of the kitchen ingredients a recipe line maps to, for allergy
  /// reminders.
  Iterable<String> stockNames(CatalogIngredient line) sync* {
    for (final id in stockOptions(line.id)) {
      final entry = directory?.entry(id);
      if (entry != null) yield* [entry.name, ...entry.aliases];
    }
  }

  /// Stock identities a recipe line accepts, preferred first.
  List<String> stockOptions(String rawId) =>
      directory?.stockOptions(rawId) ?? [rawId];

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

  /// Barcode -> stock ingredient, as the user linked them.
  Map<String, String> _barcodes = {};
  late final FoodRepository foods = FoodRepository(read: _readAsset);

  /// Licensed dish photos bundled with the app (empty until added).
  late final RecipePhotoLibrary photos = RecipePhotoLibrary(read: _readAsset);

  /// A dish's photos; none when the library is missing or unreadable.
  Future<List<RecipePhoto>> photosOf(String recipeId) async {
    try {
      return await photos.photosOf(recipeId);
    } catch (_) {
      return const [];
    }
  }

  /// Looks a barcode up in the bundled Egypt/Saudi product bank and the
  /// user's own links. Nothing is guessed from the product name.
  Future<ScannedProduct> lookupBarcode(String raw) async {
    final code = raw.trim();
    Map<String, dynamic>? row;
    try {
      row = (await foods.products())
          .where((p) => p['barcode'] == code)
          .firstOrNull;
    } catch (_) {
      // The bank failed to load; the user's link still works.
    }
    String? text(Object? v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    final names = row?['names'] as Map?;
    return ScannedProduct(
      code,
      name: names == null
          ? null
          : text(names['ar']) ?? text(names['original']) ?? text(names['en']),
      brand: text(row?['brands']),
      packageLabel: text((row?['package'] as Map?)?['label']),
      ingredientId: _barcodes[code],
    );
  }

  /// Remembers which ingredient a barcode is, for the next scan.
  Future<void> linkBarcode(String code, String ingredientId) {
    _barcodes = {..._barcodes, code.trim(): ingredientId};
    return _save(() => kitchen.saveRootFields({'barcodeLinks': _barcodes}));
  }

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
      _barcodes = {
        for (final e in ((root['barcodeLinks'] as Map?) ?? {}).entries)
          if (e.value is String) e.key as String: e.value as String,
      };
      ready = true;
      loadError = null;
    } catch (e) {
      loadError = e;
    }
    notifyListeners();
    if (ready) unawaited(syncReminders());
  }

  /// Reschedules the coming week's meal and leftover reminders.
  Future<void> syncReminders({DateTime? now}) async {
    final titles = <String, String>{};
    for (final m in kitchen.plans.where((m) => !m.completed)) {
      try {
        titles[m.id] = await planTitle(m);
      } catch (_) {
        titles[m.id] = 'وجبة';
      }
    }
    await reminders.replaceScheduled(
      upcomingReminders(
        now: now ?? DateTime.now(),
        mealTimes: profile.mealTimes,
        before: profile.remindBefore,
        meals: kitchen.plans,
        titleOf: (m) => titles[m.id] ?? 'وجبة',
        slotName: (s) => mealSlots[s] ?? s,
        leftovers: leftovers,
      ),
    );
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
      unawaited(syncReminders());
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

  // ---- Month plan ---------------------------------------------------------

  /// Recipes the month can use: ones whose yield is known (in the source
  /// or reviewed by the user), so servings can be scaled.
  bool canPlanMonth(Map<String, dynamic> indexRow) =>
      indexRow['servings'] != null ||
      planningId(indexRow['id'] as String) != indexRow['id'];

  /// Saves the month's budget, repeats [menu] (weekday 1..7 and slot -> one
  /// or two recipe ids, every weekday filled for every slot) over the month,
  /// and prices it. A second recipe in a cell is a cheaper alternative the
  /// search may pick instead.
  Future<MonthPlan> previewMonth({
    required DateTime month,
    required double limit,
    required Map<(int, String), List<String>> menu,
    int? servings,
    bool omitUnmeasured = false,
    bool keepPlanned = false,
    DateTime? today,
    int maxEvaluations = 4000,
  }) async {
    final start = DateTime(month.year, month.month);
    final budget = BudgetPeriod(
      id: 'budget-${localDay(start).substring(0, 7)}',
      start: localDay(start),
      end: localDay(DateTime(month.year, month.month + 1)),
      limit: limit,
      country: kitchen.market.country,
    );
    await kitchen.saveBudget(budget);
    final slots = {for (final (_, slot) in menu.keys) slot}.toList();
    final people = servings ?? profile.servings;
    final template = [
      for (final MapEntry(key: (weekday, slot), value: ids) in menu.entries)
        WeeklyRecipeSlot(
          weekday: weekday,
          slot: slot,
          choices: [
            for (final (i, id) in ids.indexed)
              RecipePoolChoice(
                id: '$weekday-$slot-$i',
                recipeId: planningId(id),
                servings: people,
              ),
          ],
        ),
    ];
    final pools = await kitchen.generateMonthlyCandidatePools(
      budget.id,
      weeklyTemplate: template,
      requiredDailySlots: slots,
      maxPools: 31 * slots.length,
      maxCandidatesPerSlot: 2,
      acknowledgeRecipeEligibility: true,
    );
    // Days already gone are not planned; with [keepPlanned] neither are the
    // meals the user already put on the table.
    final from = localDay(today ?? DateTime.now());
    final taken = {
      if (keepPlanned)
        for (final p in kitchen.plans) (p.date, p.slot),
    };
    bool open(String date, String slot) =>
        date.compareTo(from) >= 0 && !taken.contains((date, slot));
    final openPools = {
      for (final e in pools.pools.entries)
        if (open(e.value.first.date, e.value.first.slot)) e.key: e.value,
    };
    if (openPools.isEmpty) throw StateError('No open days left this month');
    final preview = await kitchen.searchMonthlyBudgetChoices(
      budget.id,
      pools: openPools,
      maxEvaluations: maxEvaluations,
      requiredSlots: [
        for (final s in pools.requiredSlots)
          if (open(s.date, s.slot)) s,
      ],
      omitUnmeasuredLines: omitUnmeasured,
    );
    final unmeasured = <String>{};
    if (omitUnmeasured) {
      final meals = {
        for (final pool in preview.candidatesByPool.values)
          for (final meal in pool.values) meal.recipeRevisionKey: meal,
      };
      for (final meal in meals.values) {
        final r =
            kitchen.recipeBook.revisions[meal.recipeRevisionKey]?.recipe ??
            await recipes.get(meal.recipeId);
        for (final line in r.ingredients) {
          if (!line.optional && line.amount == null) {
            unmeasured.add(line.name);
          }
        }
      }
    }
    return MonthPlan._(budget, preview, unmeasured);
  }

  /// Writes the month's meals from the cheapest affordable option.
  /// Meals already on the table on the days and meals [plan] would fill.
  List<PlannedMeal> monthConflicts(MonthPlan plan) {
    final slots = {
      for (final pool in plan.preview.candidatesByPool.values)
        for (final m in pool.values) (m.date, m.slot),
    };
    return [
      for (final p in kitchen.plans)
        if (slots.contains((p.date, p.slot))) p,
    ];
  }

  /// Writes the month's meals from the cheapest affordable option. With
  /// [replace], uncooked meals already on those days come off the table
  /// once the month is saved; cooked ones stay as history.
  Future<bool> acceptMonth(MonthPlan plan, {bool replace = false}) {
    final best = plan.best;
    if (best == null) return Future.value(false);
    final old = replace ? monthConflicts(plan) : const <PlannedMeal>[];
    return _save(() async {
      await kitchen.acceptMonthlyBudgetSearchOption(
        plan.preview,
        optionId: best.option.id,
        planIdsByPool: {
          for (final pool in plan.preview.candidatesByPool.keys)
            pool: newId('meal'),
        },
      );
      for (final p in old) {
        if (!p.completed) await kitchen.removePlan(p.id);
      }
    });
  }

  /// A price the user typed: [amount] for [quantity] [unit] of a stock item.
  Future<bool> setUserPrice(
    String ingredientId,
    double quantity,
    String unit,
    double amount, {
    String source = 'user',
  }) => _save(
    () => kitchen.savePrice(
      MarketPrice(
        country: kitchen.market.country,
        ingredientId: ingredientId,
        unit: unit,
        quantity: quantity,
        amount: amount,
        recordedAt: DateTime.now(),
        source: source,
      ),
      userOverride: true,
    ),
  );

  // ---- Inventory ----------------------------------------------------------

  /// Lots with a known positive or unknown quantity; zero lots stay in data.
  List<InventoryLot> get stock =>
      kitchen.inventory.where((l) => l.quantity != 0).toList();

  /// Cooked dishes put away with servings left.
  List<LeftoverDish> get leftovers =>
      kitchen.leftovers.where((d) => d.servings > 0).toList();

  /// Puts what is left of a cooked meal in the fridge as covered dishes.
  /// Leftovers whose reminder day has come.
  List<LeftoverDish> leftoversDue(DateTime today) =>
      leftovers.where((d) => d.dueOn(today)).toList();

  Future<bool> saveLeftovers(
    String name,
    double servings, {
    DateTime? on,
    int? remindAfterDays,
  }) {
    if (servings <= 0) return Future.value(true);
    return _save(
      () => kitchen.saveLeftover(
        LeftoverDish(
          id: newId('leftover'),
          name: name,
          servings: servings,
          preparedOn: localDay(on ?? DateTime.now()),
          remindAfterDays: remindAfterDays,
        ),
      ),
    );
  }

  /// Warmed up and eaten: takes [servings] off a leftover dish.
  Future<bool> eatLeftover(String id, double servings) =>
      _save(() => kitchen.consumeLeftover(id, servings));

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

  /// What to buy for the uncooked meals of the coming [days], after what is
  /// already in stock (allocated once across all of them), with the user's
  /// prices where known.
  Future<PurchaseForecast> shoppingList(DateTime from, {int days = 7}) =>
      kitchen.previewPurchases([
        for (final m in upcoming(from, days: days))
          if (!m.completed) m.id,
      ]);

  /// The shopping list as plain text to send (WhatsApp or any app).
  String shoppingText(PurchaseForecast list) => [
    'قائمة الشراء من سفرة:',
    for (final p in list.purchases)
      '- ${ingredientName(p.use.ingredientId)}: ${amountText(p.use.ingredientId, p.use.quantity, p.use.unit)}',
  ].join('\n');

  /// The user bought these: they go into stock, each in its usual place.
  /// With what they say they paid ([paid], optional per item) it is logged as
  /// a purchase against the budget and kept as their price for next time;
  /// without it no price is invented and nothing is logged.
  Future<void> addBought(
    Iterable<IngredientUse> bought, {
    Map<IngredientUse, double> paid = const {},
  }) async {
    for (final use in bought) {
      final zone =
          directory?.entry(use.ingredientId)?.zone ??
          demoIngredients[use.ingredientId]?.zone ??
          StorageZone.pantry;
      final amount = paid[use];
      if (amount == null) {
        await _addAmount(use.ingredientId, use.quantity, use.unit, zone);
        continue;
      }
      final now = DateTime.now();
      await _save(() async {
        await kitchen.addStock(
          InventoryLot(
            id: newId('lot'),
            ingredientId: use.ingredientId,
            quantity: use.quantity,
            unit: use.unit,
            zone: zone,
          ),
          newPurchase: true,
          paid: amount,
          purchasedAt: now,
        );
        await kitchen.savePrice(
          MarketPrice(
            country: kitchen.market.country,
            ingredientId: use.ingredientId,
            unit: use.unit,
            quantity: use.quantity,
            amount: amount,
            recordedAt: now,
            source: 'user-purchase',
          ),
          userOverride: true,
        );
      });
    }
  }

  /// Energy and macronutrients per portion of a planned meal, only those
  /// whose every ingredient has a sourced food value; null when even energy
  /// is incomplete (most catalog recipes have no food bindings yet).
  Future<Map<NutrientId, double>?> portionNutrition(PlannedMeal meal) async {
    final RecipeNutritionResult result;
    try {
      result = await kitchen.previewNutrition(meal.id);
    } on Object {
      return null;
    }
    final energy = result.perPortion[NutrientId.energyKcal]?.value;
    if (energy == null) return null;
    return {
      NutrientId.energyKcal: energy,
      for (final id in const [
        NutrientId.protein,
        NutrientId.carbohydrate,
        NutrientId.fat,
      ])
        id: ?result.perPortion[id]?.value,
    };
  }

  // ---- The user's own recipes ----------------------------------------------

  /// Recipes the user wrote, newest publication of each.
  List<RecipeRevision> get myRecipes => [
    for (final r in kitchen.recipeBook.revisions.values)
      if (r.kind == RecipeRevisionKind.authored &&
          kitchen.recipeBook.active[r.variantId] == r.key)
        r,
  ];

  /// Saves and publishes a recipe the user wrote, so it can be planned and
  /// cooked like any other. Every amount, time and step is theirs; nutrition
  /// stays unknown (no food is matched). Returns its recipe id, or null when
  /// saving failed.
  Future<String?> createMyRecipe({
    required String name,
    required int servings,
    required String cuisine,
    required int prepMinutes,
    required int cookMinutes,
    required String category,
    required String description,
    required String difficulty,
    required List<MyRecipeLine> lines,
    required List<(String, double)> steps,
  }) async {
    if (!RecipeRepository.hasConcreteCuisine(cuisine.trim())) {
      throw ArgumentError('Name a specific cuisine');
    }
    const units = {
      'g': FoodQuantityUnit.g,
      'kg': FoodQuantityUnit.kg,
      'ml': FoodQuantityUnit.ml,
      'l': FoodQuantityUnit.l,
      'count': FoodQuantityUnit.count,
    };
    final now = DateTime.now().toUtc();
    final draft = PersonalRecipeDraft(
      id: newId('mine'),
      revision: 'v1',
      name: name.trim(),
      servings: servings.toDouble(),
      createdAt: now,
      cuisine: cuisine.trim(),
      prepMinutes: prepMinutes,
      cookMinutes: cookMinutes,
      instructions: [for (final (text, _) in steps) text.trim()],
      lines: [
        for (final (i, l) in lines.indexed)
          PersonalRecipeLine(
            id: 'line-$i',
            name: l.name,
            scales: l.amount != null,
            input: RecipeFoodInput(
              ingredientId: 'line-$i',
              food: null,
              amount: l.amount == null
                  ? null
                  : FoodAmount(value: l.amount!, unit: units[l.unit]!),
              amountForm: FoodForm.asSold,
              preparedForm: FoodForm.asSold,
            ),
          ),
      ],
    );
    final review = PersonalRecipeFinalization(
      draft: draft,
      category: category.trim(),
      description: description.trim(),
      difficulty: difficulty.trim(),
      stepMinutes: [for (final (_, minutes) in steps) minutes],
      ingredientIds: {for (final (i, l) in lines.indexed) 'line-$i': l.stockId},
      reviewNote: 'كتبها المستخدم بنفسه',
      reviewedAt: now,
      acknowledgeInstructionsAndInputs: true,
      acknowledgeNutritionIncomplete: true,
    );
    String? id;
    final ok = await _save(() async {
      await kitchen.savePersonalRecipeDraft(
        draft,
        acknowledgeInputsReviewed: true,
        reviewNote: 'كتبها المستخدم بنفسه',
        reviewedAt: now,
      );
      id = (await kitchen.finalizePersonalRecipe(review)).variantId;
    });
    return ok ? id : null;
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
        final options = stockOptions(ingredient.id);
        final id = options.first;
        StockAssessment assess(String id) => assessStock(
          [IngredientUse(id, quantity, ingredient.unit!)],
          after,
          rules: kitchen.unitRules,
        );
        final result = assess(id);
        final other = result.canCook
            ? null
            : options
                  .skip(1)
                  .map((o) => (o, assess(o)))
                  .where((r) => r.$2.canCook)
                  .firstOrNull;
        if (result.canCook || other != null) {
          after = (other?.$2 ?? result).after;
          lines.add(
            CookingLine(
              i,
              ingredient,
              quantity,
              LineStock.inStock,
              stockId: other?.$1,
            ),
          );
        } else if (result.unresolved.contains(id)) {
          lines.add(CookingLine(i, ingredient, quantity, LineStock.unresolved));
        } else {
          final short = result.missing.single.quantity;
          // Some is in stock: that part is used up, the rest is missing.
          if (short < quantity - 1e-9) after = result.after;
          lines.add(
            CookingLine(
              i,
              ingredient,
              quantity,
              LineStock.missing,
              missing: short,
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

  /// Confirms cooking: in-stock lines are deducted, partly stocked lines use
  /// up what there is; missing/unresolved lines are explicitly kept out of
  /// stock, unmeasured lines are omitted.
  /// [cookedLess]: partly stocked lines the user cooked with only what they
  /// had, so the meal used (and its nutrition counts) that smaller amount;
  /// the other partly stocked lines were topped up from outside.
  Future<Map<String, dynamic>?> cook(
    PlannedMeal meal,
    CookingCheck check,
    String operationId, {
    Set<int> cookedLess = const {},
  }) async {
    final less = {
      for (final l in check.lines)
        if (l.partial && cookedLess.contains(l.index)) l.index: l,
    };
    Map<String, dynamic>? record;
    final before = kitchen.inventory;
    final ok = await _save(() async {
      record = await kitchen.confirmCooking(
        meal.id,
        operationId,
        omitUnmeasuredLines: {
          for (final l in check.where(LineStock.unmeasured)) l.index,
        },
        untrackedStockLines: {
          for (final l in check.lines)
            if ((l.status == LineStock.missing && !l.partial) ||
                l.status == LineStock.unresolved)
              l.index,
        },
        partialStockLines: {
          for (final l in check.lines)
            if (l.partial && !less.containsKey(l.index)) l.index,
        },
        actualUsesByLine: {
          for (final MapEntry(key: i, value: l) in less.entries)
            i: IngredientUse(
              l.ingredient.id,
              l.quantity! - l.missing!,
              l.ingredient.unit!,
            ),
        },
        stockChoiceByLine: {
          for (final l in check.lines)
            if (l.stockId != null) l.index: l.stockId!,
        },
      );
    });
    if (ok && profile.stockAlerts) {
      final out = ranOut(before, kitchen.inventory);
      if (out.isNotEmpty) {
        unawaited(
          reminders.showNow(
            'خلص من المطبخ',
            '${out.map(ingredientName).join('، ')}. ضيفهم لقائمة الشراء.',
          ),
        );
      }
    }
    return ok ? record : null;
  }

  // ---- Shared kitchen and community --------------------------------------

  CommunityBackend get _community =>
      community ?? (throw StateError('Sign in to use the community'));

  /// Moves this kitchen into a new shared kitchen others can join.
  Future<String> shareKitchen() async {
    final id = await _community.createSharedKitchen(
      kitchen.document,
      profile.displayName,
    );
    reopen?.call();
    return id;
  }

  Future<String> joinKitchen(String code) async {
    final id = await _community.joinKitchen(code, profile.displayName);
    reopen?.call();
    return id;
  }

  Future<void> leaveKitchen(String kitchenId) async {
    await _community.leaveKitchen(kitchenId);
    reopen?.call();
  }

  /// Publishes one of the user's own recipes as they wrote it.
  Future<SharedRecipe> shareMyRecipe(RecipeRevision revision) async {
    final r = revision.recipe;
    final shared = SharedRecipe(
      id: '${_community.uid}-${r.id}'.replaceAll(
        RegExp(r'[^A-Za-z0-9_-]'),
        '-',
      ),
      authorUid: _community.uid,
      authorName: profile.displayName,
      title: r.name,
      cuisine: r.cuisine,
      servings: r.servings ?? (throw ArgumentError("Recipe has no servings")),
      lines: [
        for (final l in r.ingredients)
          SharedLine(
            l.name,
            amount: l.amount,
            unit: l.amount == null ? null : l.unit,
          ),
      ],
      steps: [for (final st in r.steps) st.text],
    );
    await _community.shareRecipe(shared);
    return shared;
  }

  Future<void> rateRecipe(String recipeId, int stars, String comment) =>
      _community.rate(
        recipeId,
        Rating(
          uid: _community.uid,
          name: profile.displayName,
          stars: stars,
          comment: comment,
        ),
      );

  /// Prices the user typed or paid, newest per ingredient and unit.
  List<MarketPrice> get myPrices {
    final country = kitchen.market.country;
    return [
      for (final v in (kitchen.snapshot['prices'] as List).cast<Map>())
        if (v['country'] == country.name &&
            v['override'] == true &&
            (v['source'] as String).startsWith('user'))
          MarketPrice(
            country: country,
            ingredientId: v['ingredientId'] as String,
            unit: v['unit'] as String,
            quantity: (v['quantity'] as num).toDouble(),
            amount: (v['amount'] as num).toDouble(),
            recordedAt: DateTime.parse(v['date'] as String),
            source: v['source'] as String,
          ),
    ];
  }

  /// Shares one of the user's prices with people in their area.
  Future<void> sharePrice(MarketPrice price) => _community.reportPrice(
    PriceReport(
      uid: _community.uid,
      country: market.code,
      area: profile.area,
      ingredientId: price.ingredientId,
      quantity: price.quantity,
      unit: price.unit,
      amount: price.amount,
      paidOn: price.recordedAt,
    ),
  );

  /// Area prices per (ingredient, unit), where at least two households
  /// reported one.
  Future<Map<(String, String), AreaPrice>> areaPrices({DateTime? today}) async {
    if (profile.area.trim().isEmpty) return const {};
    final reports = await _community.areaReports(market.code, profile.area);
    final result = <(String, String), AreaPrice>{};
    for (final key in {for (final r in reports) (r.ingredientId, r.unit)}) {
      final p = areaPrice(
        reports,
        ingredientId: key.$1,
        unit: key.$2,
        today: today ?? DateTime.now(),
      );
      if (p != null) result[key] = p;
    }
    return result;
  }

  /// Cooked meals as (date, recipe) pairs, for challenges.
  List<(String, String)> get cookedMeals => [
    for (final m in kitchen.plans)
      if (m.completed) (m.date, m.recipeId),
  ];

  /// Saves this week's progress on the shared leaderboard.
  Future<ChallengeEntry> joinChallenge({DateTime? today}) async {
    final day = today ?? DateTime.now();
    final c = challengeFor(day);
    final entry = ChallengeEntry(
      uid: _community.uid,
      name: profile.houseName,
      progress: challengeProgress(c, day, cookedMeals).clamp(0, 100),
      goal: c.goal,
    );
    await _community.saveChallengeEntry(weekKey(day), entry);
    return entry;
  }
}
