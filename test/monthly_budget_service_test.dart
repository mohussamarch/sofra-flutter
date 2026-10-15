import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/market_profile.dart';
import 'package:tabkha_demo/domain/models.dart';

import 'purchase_forecast_integration_test.dart' as forecast;
import 'recipe_variants_test.dart' as fixture;

BudgetPeriod budget({
  MarketCountry country = MarketCountry.egypt,
  double limit = 40,
}) => BudgetPeriod(
  id: 'october',
  start: '2026-10-01',
  end: '2026-11-01',
  limit: limit,
  country: country,
);
PlannedMeal candidate(
  String id, {
  String recipe = 'fixture',
  int servings = 2,
  String date = '2026-10-14',
  String slot = 'lunch',
  String? key,
  bool completed = false,
}) => PlannedMeal(
  id: id,
  date: date,
  slot: slot,
  recipeId: recipe,
  servings: servings,
  recipeRevisionKey: key,
  completed: completed,
);

Future<(KitchenService, Completer<void>, Completer<void>)> gatedKitchen(
  forecast.CountedStore store,
) async {
  final first = await forecast.kitchen(store);
  await first.saveBudget(budget());
  final entered = Completer<void>(), release = Completer<void>();
  final r = fixture.recipe();
  final repository = RecipeRepository(
    read: (path) async {
      if (path.endsWith('index.json')) {
        return jsonEncode({
          'cuisines': [
            {'file': 'test.json'},
          ],
          'recipes': [
            {
              'id': r.id,
              'file': 'test.json',
              'cuisine': r.cuisine,
              'servings': r.servings,
              'name': r.name,
              'tags': [],
            },
          ],
        });
      }
      entered.complete();
      await release.future;
      return jsonEncode({
        'recipes': [r.toJson()],
      });
    },
  );
  final k = KitchenService(store, repository);
  await k.load();
  return (k, entered, release);
}

class BlockingStore extends forecast.CountedStore {
  bool block = false;
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Future<void> save(Map<String, dynamic> value) async {
    if (block) {
      block = false;
      entered.complete();
      await release.future;
    }
    await super.save(value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses current stock, confirmed ledger and user price without saving candidates', () async {
    final store = forecast.CountedStore();
    final k = await forecast.kitchen(store);
    await k.saveBudget(budget());
    await k.savePrice(forecast.price('sample', 50), userOverride: false);
    await k.addStock(
      InventoryLot(
        id: 'stock',
        ingredientId: 'sample',
        quantity: 100,
        unit: 'g',
        zone: StorageZone.pantry,
      ),
      newPurchase: true,
      paid: 6,
      purchasedAt: DateTime(2026, 10, 14),
    );
    final pinned = (await k.recipeForMeal('p1')).key;
    final before = jsonEncode(k.snapshot),
        stored = jsonEncode(store.data),
        saves = store.saves;
    final result = await k.previewMonthlyBudgetChoices(
      'october',
      options: {
        'two-meals': [candidate('a'), candidate('b', date: '2026-10-15')],
        'small': [
          candidate('c', servings: 1, key: pinned),
          candidate('d', servings: 1, date: '2026-10-15', key: pinned),
        ],
      },
    );
    expect(result.spent, 6);
    expect(result.ranked.map((row) => row.option.id), ['small', 'two-meals']);
    expect(result.ranked.first.forecast.purchaseTotal, 6);
    expect(result.ranked.first.forecast.consumptionTotal, 12);
    expect(result.ranked.first.remainingAfterPurchases, 28);
    expect(result.ranked.last.forecast.purchaseTotal, 18);
    expect(result.coverage.length, 2);
    expect(result.assessments.first.option.meals.first.candidateId, pinned);
    expect(jsonEncode(k.snapshot), before);
    expect(jsonEncode(store.data), stored);
    expect(store.saves, saves);
    expect(k.plans.single.id, 'p1');
  });
  test(
    'unknown included lines stay unknown until explicit measurement',
    () async {
      final k = await forecast.kitchen(
        forecast.CountedStore(),
        recipe: forecast.unmeasuredRecipe(),
      );
      await k.saveBudget(budget());
      await k.savePrice(
        forecast.price('salt', 1, unit: 'g'),
        userOverride: true,
      );
      await k.savePrice(
        forecast.price('pepper', 2, unit: 'g'),
        userOverride: true,
      );
      final options = {
        'a': [candidate('meal')],
      };
      final unknown = await k.previewMonthlyBudgetChoices(
        'october',
        options: options,
      );
      expect(unknown.unranked.single.forecast.unresolvedRequirements, {
        'meal:1:salt',
      });
      expect(unknown.unranked.single.withinBudget, isNull);
      final optionalUnknown = await k.previewMonthlyBudgetChoices(
        'october',
        options: options,
        optionalLinesByOption: {
          'a': {
            'meal': {2},
          },
        },
        measuredByOption: {
          'a': {
            'meal': {1: IngredientUse('salt', 5, 'g')},
          },
        },
      );
      expect(optionalUnknown.unranked.single.forecast.unresolvedRequirements, {
        'meal:2:pepper',
      });
      final known = await k.previewMonthlyBudgetChoices(
        'october',
        options: options,
        optionalLinesByOption: {
          'a': {
            'meal': {2},
          },
        },
        measuredByOption: {
          'a': {
            'meal': {
              1: IngredientUse('salt', 5, 'g'),
              2: IngredientUse('pepper', 3, 'g'),
            },
          },
        },
      );
      expect(known.ranked.single.forecast.purchaseTotal, 23);
    },
  );

  test('owns all nested choices, candidate lists and unit rules before first await', () async {
    final k = await forecast.kitchen(
      forecast.CountedStore(),
      recipe: forecast.unmeasuredRecipe(),
    );
    await k.saveBudget(budget());
    await k.savePrice(forecast.price('salt', 1, unit: 'g'), userOverride: true);
    await k.savePrice(
      forecast.price('pepper', 2, unit: 'g'),
      userOverride: true,
    );
    await k.addStock(
      InventoryLot(
        id: 'pack',
        ingredientId: 'sample',
        quantity: 1,
        unit: 'count',
        zone: StorageZone.pantry,
      ),
      newPurchase: false,
    );
    final meals = [candidate('meal')], options = {'a': <PlannedMeal>[]};
    options['a'] = meals;
    final selected = {2},
        optionals = {
          'a': {'meal': <int>{}},
        };
    optionals['a']!['meal'] = selected;
    final measured = {
      1: IngredientUse('salt', 5, 'g'),
      2: IngredientUse('pepper', 3, 'g'),
    };
    final measuredMeals = {'meal': measured},
        measuredOptions = {'a': <String, Map<int, IngredientUse>>{}};
    measuredOptions['a'] = measuredMeals;
    final rules = [UnitRule('sample', 'count', 'g', 200)];
    final pending = k.previewMonthlyBudgetChoices(
      'october',
      options: options,
      optionalLinesByOption: optionals,
      measuredByOption: measuredOptions,
      rules: rules,
    );
    meals.clear();
    options.clear();
    selected.clear();
    optionals['a']!.clear();
    optionals.clear();
    measured.clear();
    measuredMeals.clear();
    measuredOptions.clear();
    rules.clear();
    final result = await pending;
    expect(result.ranked.single.forecast.purchaseTotal, 11);
    expect(result.ranked.single.forecast.consumptionTotal, 23);
    expect(
      result.assessments.single.option.meals.single.requirements.length,
      3,
    );
    expect(() => result.assessments.clear(), throwsUnsupportedError);
    expect(
      () => result.assessments.single.option.meals.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => result.assessments.single.option.meals.single.requirements.clear(),
      throwsUnsupportedError,
    );
  });

  test(
    'saved budget country must match and prices never cross countries',
    () async {
      final k = await forecast.kitchen(forecast.CountedStore());
      await k.saveBudget(budget(country: MarketCountry.saudi));
      final options = {
        'a': [candidate('meal')],
      };
      await expectLater(
        k.previewMonthlyBudgetChoices('october', options: options),
        throwsStateError,
      );
      await k.setCountry(MarketCountry.saudi);
      final unknown = await k.previewMonthlyBudgetChoices(
        'october',
        options: options,
      );
      expect(unknown.unranked.single.forecast.unpricedPurchases, {'sample'});
      await k.savePrice(
        forecast.price('sample', 20, country: MarketCountry.saudi),
        userOverride: true,
      );
      final result = await k.previewMonthlyBudgetChoices(
        'october',
        options: options,
      );
      expect(result.ranked.single.forecast.purchaseTotal, 4);
    },
  );

  test(
    'confirmed ledger is frozen and scoped while old stock is separate',
    () async {
      final store = forecast.CountedStore();
      final k = await forecast.kitchen(store);
      await k.saveBudget(budget());
      for (final purchase in [
        ('old', DateTime(2026, 9, 30), 10.0),
        ('paid', DateTime(2026, 10, 1), 6.0),
        ('next', DateTime(2026, 11, 1), 20.0),
      ]) {
        await k.addStock(
          InventoryLot(
            id: purchase.$1,
            ingredientId: 'sample',
            quantity: 10,
            unit: 'g',
            zone: StorageZone.pantry,
          ),
          newPurchase: true,
          paid: purchase.$3,
          purchasedAt: purchase.$2,
        );
      }
      await k.addStock(
        InventoryLot(
          id: 'existing',
          ingredientId: 'sample',
          quantity: 50,
          unit: 'g',
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
      await k.plan(candidate('past', date: '2026-09-29', servings: 1));
      await k.addStock(
        InventoryLot(
          id: 'extra',
          ingredientId: 'sample',
          quantity: 100,
          unit: 'g',
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
      await k.confirmCooking('past', 'cooked');
      final history = jsonEncode(k.snapshot['history']),
          purchases = jsonEncode(k.snapshot['purchases']);
      await k.savePrice(forecast.price('sample', 100), userOverride: true);
      final before = jsonEncode(k.snapshot), saves = store.saves;
      final result = await k.previewMonthlyBudgetChoices(
        'october',
        options: {
          'a': [candidate('meal')],
        },
      );
      expect(result.spent, 6);
      expect(result.remainingBeforePurchases, 34);
      expect(result.ranked.single.forecast.consumptionTotal, 20);
      expect(jsonEncode(k.snapshot['history']), history);
      expect(jsonEncode(k.snapshot['purchases']), purchases);
      expect(jsonEncode(k.snapshot), before);
      expect(store.saves, saves);
    },
  );

  test(
    'preserves a requested old pin and resolves an unpinned current revision',
    () async {
      final k = await forecast.kitchen(forecast.CountedStore());
      await k.saveBudget(budget());
      final base = await k.recipeForMeal('p1');
      final old = fixture.custom(base, 'v1', 100),
          current = fixture.custom(base, 'v2', 300);
      await k.saveRecipeRevision(old);
      await k.saveRecipeRevision(current);
      final result = await k.previewMonthlyBudgetChoices(
        'october',
        options: {
          'old': [
            candidate('meal', recipe: old.variantId, servings: 1, key: old.key),
          ],
          'current': [candidate('meal', recipe: old.variantId, servings: 1)],
        },
      );
      expect(result.ranked.map((row) => row.option.id), ['old', 'current']);
      expect(result.ranked.first.forecast.purchaseTotal, 3);
      expect(result.ranked.last.forecast.purchaseTotal, 9);
      expect(result.ranked.first.option.meals.single.candidateId, old.key);
      expect(result.ranked.last.option.meals.single.candidateId, current.key);
      expect(k.plans.single.id, 'p1');
    },
  );

  test('rejects unknown budget, completed candidates, scope errors and ignored line decisions', () async {
    final k = await forecast.kitchen(
      forecast.CountedStore(),
      recipe: forecast.unmeasuredRecipe(),
    );
    await k.saveBudget(budget());
    final options = {
      'a': [candidate('meal')],
    };
    await expectLater(
      k.previewMonthlyBudgetChoices('missing', options: options),
      throwsArgumentError,
    );
    await expectLater(
      k.previewMonthlyBudgetChoices('october', options: {}),
      throwsArgumentError,
    );
    await expectLater(
      k.previewMonthlyBudgetChoices(
        'october',
        options: {
          'a': [candidate('meal', completed: true)],
        },
      ),
      throwsStateError,
    );
    await expectLater(
      k.previewMonthlyBudgetChoices(
        'october',
        options: {
          'a': [candidate('meal'), candidate('meal', date: '2026-10-15')],
        },
      ),
      throwsArgumentError,
    );
    await expectLater(
      k.previewMonthlyBudgetChoices(
        'october',
        options: options,
        optionalLinesByOption: {'other': {}},
      ),
      throwsArgumentError,
    );
    await expectLater(
      k.previewMonthlyBudgetChoices(
        'october',
        options: options,
        measuredByOption: {'other': {}},
      ),
      throwsArgumentError,
    );
    await expectLater(
      k.previewMonthlyBudgetChoices(
        'october',
        options: options,
        optionalLinesByOption: {
          'a': {'other': {}},
        },
      ),
      throwsArgumentError,
    );
    await expectLater(
      k.previewMonthlyBudgetChoices(
        'october',
        options: options,
        measuredByOption: {
          'a': {'other': {}},
        },
      ),
      throwsArgumentError,
    );
    await expectLater(
      k.previewMonthlyBudgetChoices(
        'october',
        options: options,
        optionalLinesByOption: {
          'a': {
            'meal': {0},
          },
        },
      ),
      throwsArgumentError,
    );
    for (final measurement in [
      {0: IngredientUse('sample', 1, 'g')},
      {1: IngredientUse('wrong', 1, 'g')},
      {2: IngredientUse('pepper', 1, 'g')},
      {8: IngredientUse('salt', 1, 'g')},
    ]) {
      await expectLater(
        k.previewMonthlyBudgetChoices(
          'october',
          options: options,
          measuredByOption: {
            'a': {'meal': measurement},
          },
        ),
        throwsArgumentError,
      );
    }
    await expectLater(
      k.previewMonthlyBudgetChoices(
        'october',
        options: {
          'a': [candidate('meal', key: 'missing')],
        },
      ),
      throwsStateError,
    );
    final pin = (await k.recipeForMeal('p1')).key;
    await expectLater(
      k.previewMonthlyBudgetChoices(
        'october',
        options: {
          'a': [candidate('meal', recipe: 'wrong', key: pin)],
        },
      ),
      throwsStateError,
    );
    await expectLater(
      k.previewMonthlyBudgetChoices(
        'october',
        options: {
          'a': [candidate('meal')],
          'b': [candidate('meal', slot: 'dinner')],
        },
      ),
      throwsArgumentError,
    );
  });

  for (final mutation in ['price', 'budget', 'stock', 'revision']) {
    test(
      'rejects $mutation change during asynchronous current recipe resolution',
      () async {
        final store = forecast.CountedStore();
        final (k, entered, release) = await gatedKitchen(store);
        final pending = k.previewMonthlyBudgetChoices(
          'october',
          options: {
            'a': [candidate('meal')],
          },
        );
        await entered.future;
        switch (mutation) {
          case 'price':
            await k.savePrice(
              forecast.price('sample', 100),
              userOverride: true,
            );
          case 'budget':
            await k.saveBudget(budget(limit: 100));
          case 'stock':
            await k.addStock(
              InventoryLot(
                id: 'new',
                ingredientId: 'sample',
                quantity: 50,
                unit: 'g',
                zone: StorageZone.pantry,
              ),
              newPurchase: false,
            );
          case 'revision':
            final base = await k.recipeForMeal('p1');
            await k.saveRecipeRevision(fixture.custom(base, 'new', 100));
        }
        final saves = store.saves;
        final assertion = expectLater(pending, throwsStateError);
        release.complete();
        await assertion;
        expect(store.saves, saves);
      },
    );
  }

  test('unchanged delayed resolution succeeds and does not register or save a recipe', () async {
    final store = forecast.CountedStore();
    final (k, entered, release) = await gatedKitchen(store);
    final before = jsonEncode(k.snapshot), saves = store.saves;
    final pending = k.previewMonthlyBudgetChoices(
      'october',
      options: {
        'a': [candidate('meal')],
      },
    );
    await entered.future;
    release.complete();
    final result = await pending;
    expect(result.ranked.single.forecast.purchaseTotal, 12);
    expect(
      result.ranked.single.option.meals.single.candidateId,
      (await k.recipeForMeal('p1')).key,
    );
    expect(jsonEncode(k.snapshot), before);
    expect(store.saves, saves);
  });

  test(
    'waits for an in-flight save before the final freshness check',
    () async {
      final store = BlockingStore();
      final (k, entered, release) = await gatedKitchen(store);
      final pending = k.previewMonthlyBudgetChoices(
        'october',
        options: {
          'a': [candidate('meal')],
        },
      );
      await entered.future;
      store.block = true;
      final saving = k.savePrice(
        forecast.price('sample', 100),
        userOverride: true,
      );
      await store.entered.future;
      var completed = false;
      final observed = pending.then<void>(
        (_) {
          completed = true;
        },
        onError: (Object _, StackTrace _) {
          completed = true;
        },
      );
      final assertion = expectLater(pending, throwsStateError);
      release.complete();
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      store.release.complete();
      await saving;
      await assertion;
      await observed;
    },
  );
}
