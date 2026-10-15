import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/market_profile.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/monthly_budget_search.dart';

import 'monthly_budget_service_test.dart' as monthly;
import 'purchase_forecast_integration_test.dart' as forecast;
import 'recipe_variants_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('searches explicit serving candidates with current prices, shared stock and exact pin evidence without saving', () async {
    final store = forecast.CountedStore();
    final k = await forecast.kitchen(store);
    await k.saveBudget(monthly.budget(limit: 4));
    await k.savePrice(forecast.price('sample', 50), userOverride: false);
    await k.addStock(
      InventoryLot(
        id: 'stock',
        ingredientId: 'sample',
        quantity: 250,
        unit: 'g',
        zone: StorageZone.pantry,
      ),
      newPurchase: true,
      paid: 3,
      purchasedAt: DateTime(2026, 10, 14),
    );
    final key = (await k.recipeForMeal('p1')).key;
    final before = jsonEncode(k.snapshot),
        stored = jsonEncode(store.data),
        saves = store.saves;
    final result = await k.searchMonthlyBudgetChoices(
      'october',
      maxEvaluations: 10,
      pools: {
        'first': [
          monthly.candidate('left-large', key: key),
          monthly.candidate('left-small', servings: 1),
        ],
        'second': [
          monthly.candidate('right-large', date: '2026-10-15'),
          monthly.candidate('right-small', date: '2026-10-15', servings: 1),
        ],
      },
    );
    expect(result.search.totalCombinations, BigInt.from(4));
    expect(result.search.evaluatedCount, 4);
    expect(result.search.outcome, MonthlyBudgetSearchOutcome.affordableFound);
    expect(result.search.comparison.spent, 3);
    expect(
      result.search.comparison.assessments.first.forecast.purchaseTotal,
      9,
    );
    expect(
      result.search.bestKnownAffordable!.option.meals.map(
        (meal) => meal.candidateId,
      ),
      ['left-small', 'right-small'],
    );
    expect(result.search.bestKnownAffordable!.forecast.purchaseTotal, 0);
    expect(result.search.bestKnownAffordable!.forecast.consumptionTotal, 12);
    expect(
      result.candidatesByPool['first']!['left-small']!.recipeRevisionKey,
      key,
    );
    expect(result.candidatesByPool['first']!['left-small']!.servings, 1);
    expect(
      result.candidatesByPool['second']!['right-large']!.date,
      '2026-10-15',
    );
    expect(result.search.comparison.coverage.length, 2);
    expect(jsonEncode(k.snapshot), before);
    expect(jsonEncode(store.data), stored);
    expect(store.saves, saves);
  });
  test(
    'keeps huge combination counts exact and cost evaluations capped',
    () async {
      final k = await forecast.kitchen(forecast.CountedStore());
      await k.saveBudget(monthly.budget());
      final key = (await k.recipeForMeal('p1')).key;
      final result = await k.searchMonthlyBudgetChoices(
        'october',
        maxEvaluations: 3,
        pools: {
          for (var i = 0; i < 70; i++)
            'pool-$i': [
              monthly.candidate('a-$i', key: key, slot: 'slot-$i'),
              monthly.candidate('b-$i', key: key, slot: 'slot-$i', servings: 1),
            ],
        },
      );
      expect(result.search.totalCombinations, BigInt.one << 70);
      expect(result.search.evaluatedCount, 3);
      expect(result.search.truncated, isTrue);
      expect(result.search.outcome, MonthlyBudgetSearchOutcome.indeterminate);
      expect(result.candidatesByPool.length, 70);
      expect(
        result.candidatesByPool['pool-69']!['b-69']!.recipeRevisionKey,
        key,
      );
      expect(
        result.search.comparison.assessments
            .map(
              (row) => row.option.meals
                  .skip(68)
                  .map((meal) => meal.candidateId)
                  .toList(),
            )
            .toList(),
        [
          ['a-68', 'a-69'],
          ['a-68', 'b-69'],
          ['b-68', 'a-69'],
        ],
      );
    },
  );

  test('unknown included or optional needs and stock remain indeterminate until explicit', () async {
    final k = await forecast.kitchen(
      forecast.CountedStore(),
      recipe: forecast.unmeasuredRecipe(),
    );
    await k.saveBudget(monthly.budget());
    await k.savePrice(forecast.price('salt', 1, unit: 'g'), userOverride: true);
    await k.savePrice(
      forecast.price('pepper', 2, unit: 'g'),
      userOverride: true,
    );
    final pools = {
      'one': [monthly.candidate('meal')],
    };
    final unknown = await k.searchMonthlyBudgetChoices(
      'october',
      pools: pools,
      maxEvaluations: 1,
    );
    expect(unknown.search.unknownCostCount, 1);
    expect(unknown.search.outcome, MonthlyBudgetSearchOutcome.indeterminate);
    expect(
      unknown.search.comparison.unranked.single.forecast.unresolvedRequirements,
      {'meal:1:salt'},
    );
    final optionalUnknown = await k.searchMonthlyBudgetChoices(
      'october',
      pools: pools,
      maxEvaluations: 1,
      optionalLinesByPool: {
        'one': {
          'meal': {2},
        },
      },
      measuredByPool: {
        'one': {
          'meal': {1: IngredientUse('salt', 5, 'g')},
        },
      },
    );
    expect(
      optionalUnknown
          .search
          .comparison
          .unranked
          .single
          .forecast
          .unresolvedRequirements,
      {'meal:2:pepper'},
    );
    final measured = {
      'one': {
        'meal': {
          1: IngredientUse('salt', 5, 'g'),
          2: IngredientUse('pepper', 3, 'g'),
        },
      },
    };
    final known = await k.searchMonthlyBudgetChoices(
      'october',
      pools: pools,
      maxEvaluations: 1,
      optionalLinesByPool: {
        'one': {
          'meal': {2},
        },
      },
      measuredByPool: measured,
    );
    expect(known.search.outcome, MonthlyBudgetSearchOutcome.affordableFound);
    expect(known.search.bestKnownAffordable!.forecast.purchaseTotal, 23);
    await k.addStock(
      InventoryLot(
        id: 'unknown',
        ingredientId: 'sample',
        quantity: null,
        unit: 'g',
        zone: StorageZone.pantry,
      ),
      newPurchase: false,
    );
    final unknownStock = await k.searchMonthlyBudgetChoices(
      'october',
      pools: pools,
      maxEvaluations: 1,
      optionalLinesByPool: {
        'one': {
          'meal': {2},
        },
      },
      measuredByPool: measured,
    );
    expect(
      unknownStock.search.outcome,
      MonthlyBudgetSearchOutcome.indeterminate,
    );
    expect(
      unknownStock.search.comparison.unranked.single.forecast.unresolvedStock,
      {'sample'},
    );
    expect(unknownStock.search.comparison.unranked.single.withinBudget, isNull);
  });

  test(
    'owns all nested requests and exposes immutable exact candidate evidence',
    () async {
      final k = await forecast.kitchen(
        forecast.CountedStore(),
        recipe: forecast.unmeasuredRecipe(),
      );
      await k.saveBudget(monthly.budget());
      await k.savePrice(
        forecast.price('salt', 1, unit: 'g'),
        userOverride: true,
      );
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
      final meals = [monthly.candidate('meal')],
          pools = {'one': <PlannedMeal>[]};
      pools['one'] = meals;
      final selected = {2}, optionalMeals = {'meal': <int>{}};
      optionalMeals['meal'] = selected;
      final optionals = {'one': optionalMeals};
      final measured = {
        1: IngredientUse('salt', 5, 'g'),
        2: IngredientUse('pepper', 3, 'g'),
      };
      final measuredMeals = {'meal': measured},
          measurements = {'one': <String, Map<int, IngredientUse>>{}};
      measurements['one'] = measuredMeals;
      final rules = [UnitRule('sample', 'count', 'g', 200)];
      final pending = k.searchMonthlyBudgetChoices(
        'october',
        pools: pools,
        maxEvaluations: 1,
        optionalLinesByPool: optionals,
        measuredByPool: measurements,
        rules: rules,
      );
      meals.clear();
      pools.clear();
      selected.clear();
      optionalMeals.clear();
      optionals.clear();
      measured.clear();
      measuredMeals.clear();
      measurements.clear();
      rules.clear();
      final result = await pending;
      expect(result.search.bestKnownAffordable!.forecast.purchaseTotal, 11);
      expect(
        result.candidatesByPool['one']!['meal']!.recipeRevisionKey,
        isNotNull,
      );
      expect(() => result.candidatesByPool.clear(), throwsUnsupportedError);
      expect(
        () => result.candidatesByPool['one']!.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => result.search.comparison.assessments.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => result
            .search
            .comparison
            .assessments
            .single
            .option
            .meals
            .single
            .requirements
            .clear(),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'uses only saved budget country and current private user-first prices',
    () async {
      final k = await forecast.kitchen(forecast.CountedStore());
      await k.saveBudget(monthly.budget(country: MarketCountry.saudi));
      final pools = {
        'one': [monthly.candidate('meal')],
      };
      await expectLater(
        k.searchMonthlyBudgetChoices(
          'october',
          pools: pools,
          maxEvaluations: 1,
        ),
        throwsStateError,
      );
      await k.setCountry(MarketCountry.saudi);
      final unknown = await k.searchMonthlyBudgetChoices(
        'october',
        pools: pools,
        maxEvaluations: 1,
      );
      expect(unknown.search.outcome, MonthlyBudgetSearchOutcome.indeterminate);
      expect(
        unknown.search.comparison.unranked.single.forecast.unpricedPurchases,
        {'sample'},
      );
      await k.savePrice(
        forecast.price('sample', 20, country: MarketCountry.saudi),
        userOverride: true,
      );
      await k.savePrice(
        forecast.price('sample', 10, country: MarketCountry.saudi),
        userOverride: false,
      );
      final result = await k.searchMonthlyBudgetChoices(
        'october',
        pools: pools,
        maxEvaluations: 1,
      );
      expect(result.search.bestKnownAffordable!.forecast.purchaseTotal, 4);
    },
  );

  test(
    'rejects every unexamined bad candidate, revision, decision and pool shape',
    () async {
      final k = await forecast.kitchen(forecast.CountedStore());
      await k.saveBudget(monthly.budget());
      final key = (await k.recipeForMeal('p1')).key;
      final valid = monthly.candidate('valid', key: key);
      for (final invalid in [
        monthly.candidate('bad', completed: true),
        monthly.candidate('bad', key: 'missing'),
        monthly.candidate('bad', recipe: 'wrong', key: key),
        monthly.candidate('bad', recipe: 'not-in-repository'),
      ]) {
        await expectLater(
          k.searchMonthlyBudgetChoices(
            'october',
            maxEvaluations: 1,
            pools: {
              'one': [valid, invalid],
            },
          ),
          throwsA(anyOf(isA<StateError>(), isA<ArgumentError>())),
        );
      }
      final pools = {
        'one': [valid, monthly.candidate('unexamined', key: key)],
      };
      for (final measurement in [
        {0: IngredientUse('sample', 1, 'g')},
        {5: IngredientUse('sample', 1, 'g')},
      ]) {
        await expectLater(
          k.searchMonthlyBudgetChoices(
            'october',
            maxEvaluations: 1,
            pools: pools,
            measuredByPool: {
              'one': {'unexamined': measurement},
            },
          ),
          throwsArgumentError,
        );
      }
      await expectLater(
        k.searchMonthlyBudgetChoices(
          'october',
          maxEvaluations: 1,
          pools: pools,
          optionalLinesByPool: {
            'one': {
              'unexamined': {0},
            },
          },
        ),
        throwsArgumentError,
      );
      await expectLater(
        k.searchMonthlyBudgetChoices(
          'october',
          maxEvaluations: 1,
          pools: pools,
          optionalLinesByPool: {'other': {}},
        ),
        throwsArgumentError,
      );
      await expectLater(
        k.searchMonthlyBudgetChoices(
          'october',
          maxEvaluations: 1,
          pools: pools,
          measuredByPool: {'other': {}},
        ),
        throwsArgumentError,
      );
      await expectLater(
        k.searchMonthlyBudgetChoices(
          'october',
          maxEvaluations: 1,
          pools: pools,
          optionalLinesByPool: {
            'one': {'other': {}},
          },
        ),
        throwsArgumentError,
      );
      await expectLater(
        k.searchMonthlyBudgetChoices(
          'october',
          maxEvaluations: 1,
          pools: pools,
          measuredByPool: {
            'one': {'other': {}},
          },
        ),
        throwsArgumentError,
      );
      for (final invalidPools in <Map<String, List<PlannedMeal>>>[
        {},
        {'one': []},
        {
          ' ': [valid],
        },
        {
          'one': [valid, valid],
        },
        {
          'one': [monthly.candidate(' ')],
        },
        {
          'one': [valid, monthly.candidate('b', date: '2026-10-15')],
        },
        {
          'one': [valid, monthly.candidate('b', slot: 'dinner')],
        },
        {
          'one': [valid],
          'two': [monthly.candidate('same-slot')],
        },
      ]) {
        await expectLater(
          k.searchMonthlyBudgetChoices(
            'october',
            pools: invalidPools,
            maxEvaluations: 1,
          ),
          throwsArgumentError,
        );
      }
    },
  );

  test('retains requested old revision and pins a null current resolution separately', () async {
    final k = await forecast.kitchen(forecast.CountedStore());
    await k.saveBudget(monthly.budget());
    final base = await k.recipeForMeal('p1');
    final old = fixture.custom(base, 'v1', 100),
        current = fixture.custom(base, 'v2', 300);
    await k.saveRecipeRevision(old);
    await k.saveRecipeRevision(current);
    final result = await k.searchMonthlyBudgetChoices(
      'october',
      maxEvaluations: 2,
      pools: {
        'one': [
          monthly.candidate(
            'old',
            recipe: old.variantId,
            servings: 1,
            key: old.key,
          ),
          monthly.candidate('current', recipe: old.variantId, servings: 1),
        ],
      },
    );
    expect(
      result.search.comparison.ranked.map((row) => row.forecast.purchaseTotal),
      [3, 9],
    );
    expect(
      result.search.bestKnownAffordable!.option.meals.single.candidateId,
      'old',
    );
    expect(result.candidatesByPool['one']!['old']!.recipeRevisionKey, old.key);
    expect(
      result.candidatesByPool['one']!['current']!.recipeRevisionKey,
      current.key,
    );
  });

  for (final mutation in ['price', 'budget', 'stock', 'revision']) {
    test(
      'rejects $mutation change while resolving an unevaluated candidate',
      () async {
        final store = forecast.CountedStore();
        final (k, entered, release) = await monthly.gatedKitchen(store);
        final key = (await k.recipeForMeal('p1')).key;
        final pending = k.searchMonthlyBudgetChoices(
          'october',
          maxEvaluations: 1,
          pools: {
            'one': [
              monthly.candidate('evaluated', key: key),
              monthly.candidate('unevaluated'),
            ],
          },
        );
        await entered.future.timeout(const Duration(seconds: 5));
        switch (mutation) {
          case 'price':
            await k.savePrice(
              forecast.price('sample', 100),
              userOverride: true,
            );
          case 'budget':
            await k.saveBudget(monthly.budget(limit: 100));
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
        final assertion = expectLater(pending, throwsStateError),
            saves = store.saves;
        release.complete();
        await assertion;
        expect(store.saves, saves);
      },
    );
  }

  test(
    'waits for an in-flight write before the final snapshot guard',
    () async {
      final store = monthly.BlockingStore();
      final (k, entered, release) = await monthly.gatedKitchen(store);
      final key = (await k.recipeForMeal('p1')).key;
      final pending = k.searchMonthlyBudgetChoices(
        'october',
        maxEvaluations: 1,
        pools: {
          'one': [
            monthly.candidate('evaluated', key: key),
            monthly.candidate('unevaluated'),
          ],
        },
      );
      await entered.future.timeout(const Duration(seconds: 5));
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

  test('rejects unknown budget, invalid cap, nonmonthly period or unevaluated out-of-month pool', () async {
    final k = await forecast.kitchen(forecast.CountedStore());
    await k.saveBudget(monthly.budget());
    final pools = {
      'one': [monthly.candidate('meal')],
    };
    await expectLater(
      k.searchMonthlyBudgetChoices('missing', pools: pools, maxEvaluations: 1),
      throwsArgumentError,
    );
    for (final max in [0, -1]) {
      await expectLater(
        k.searchMonthlyBudgetChoices(
          'october',
          pools: pools,
          maxEvaluations: max,
        ),
        throwsArgumentError,
      );
    }
    await k.saveBudget(
      BudgetPeriod(
        id: 'not-month',
        start: '2026-10-02',
        end: '2026-11-01',
        limit: 40,
        country: MarketCountry.egypt,
      ),
    );
    await expectLater(
      k.searchMonthlyBudgetChoices(
        'not-month',
        pools: pools,
        maxEvaluations: 1,
      ),
      throwsArgumentError,
    );
    await expectLater(
      k.searchMonthlyBudgetChoices(
        'october',
        pools: {
          'one': [monthly.candidate('meal')],
          'two': [monthly.candidate('outside', date: '2026-11-01')],
        },
        maxEvaluations: 1,
      ),
      throwsArgumentError,
    );
  });

  test('resolves and returns unevaluated pins on an unchanged snapshot without registering or saving', () async {
    final store = forecast.CountedStore();
    final (k, entered, release) = await monthly.gatedKitchen(store);
    final key = (await k.recipeForMeal('p1')).key;
    final before = jsonEncode(k.snapshot),
        stored = jsonEncode(store.data),
        saves = store.saves;
    final pending = k.searchMonthlyBudgetChoices(
      'october',
      maxEvaluations: 1,
      pools: {
        'one': [
          monthly.candidate('evaluated', key: key),
          monthly.candidate('unevaluated'),
        ],
      },
    );
    await entered.future.timeout(const Duration(seconds: 5));
    release.complete();
    final result = await pending;
    expect(result.search.evaluatedCount, 1);
    expect(result.search.totalCombinations, BigInt.two);
    expect(result.search.truncated, isTrue);
    expect(result.search.outcome, MonthlyBudgetSearchOutcome.indeterminate);
    expect(result.search.bestKnownAffordable, isNotNull);
    expect(
      result.candidatesByPool['one']!['unevaluated']!.recipeRevisionKey,
      key,
    );
    expect(jsonEncode(k.snapshot), before);
    expect(jsonEncode(store.data), stored);
    expect(store.saves, saves);
  });
}
