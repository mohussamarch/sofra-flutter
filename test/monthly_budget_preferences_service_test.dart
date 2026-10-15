import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/monthly_budget_preferences.dart';

import 'monthly_budget_service_test.dart' as monthly;
import 'purchase_forecast_integration_test.dart' as forecast;
import 'recipe_variants_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('service derives exact recipe IDs and applies explicit diversity without writing', () async {
    final store = forecast.CountedStore();
    final k = await forecast.kitchen(store);
    await k.saveBudget(monthly.budget());
    final base = await k.recipeForMeal('p1'),
        other = fixture.custom(await k.recipeForMeal('p1'), 'b', 300);
    await k.saveRecipeRevision(other);
    final before = jsonEncode(k.snapshot),
        stored = jsonEncode(store.data),
        saves = store.saves;
    final result = await k.searchMonthlyBudgetChoices(
      'october',
      maxEvaluations: 4,
      recipePreferences: MonthlyBudgetRecipePreferences(
        maxOccurrencesByRecipe: {'fixture': 1},
        minimumDistinctRecipes: 2,
      ),
      pools: {
        'first': [
          monthly.candidate('a1', key: base.key),
          monthly.candidate('b1', recipe: other.variantId),
        ],
        'second': [
          monthly.candidate('a2', key: base.key, date: '2026-10-15'),
          monthly.candidate('b2', recipe: other.variantId, date: '2026-10-15'),
        ],
      },
    );
    expect(result.search.comparison.ranked.first.option.id, 'choice:0,0');
    expect(
      result.search.bestKnownAffordable!.option.meals.map(
        (meal) => meal.candidateId,
      ),
      ['a1', 'b2'],
    );
    expect(result.search.eligibleCount, 2);
    expect(result.search.eligibleRanked.length, 2);
    expect(result.search.candidateRecipeIds.values.toSet(), {
      'fixture',
      other.variantId,
    });
    expect(result.search.recipePreferences!.minimumDistinctRecipes, 2);
    expect(jsonEncode(k.snapshot), before);
    expect(jsonEncode(store.data), stored);
    expect(store.saves, saves);
  });

  test('different pins and serving sizes of one recipe share the same explicit repeat identity', () async {
    final k = await forecast.kitchen(forecast.CountedStore());
    await k.saveBudget(monthly.budget());
    final base = await k.recipeForMeal('p1');
    final old = fixture.custom(base, 'v1', 100),
        current = fixture.custom(base, 'v2', 300);
    await k.saveRecipeRevision(old);
    await k.saveRecipeRevision(current);
    final result = await k.searchMonthlyBudgetChoices(
      'october',
      maxEvaluations: 1,
      recipePreferences: MonthlyBudgetRecipePreferences(
        maxOccurrencesByRecipe: {old.variantId: 1},
      ),
      pools: {
        'first': [
          monthly.candidate(
            'old',
            recipe: old.variantId,
            key: old.key,
            servings: 1,
          ),
        ],
        'second': [
          monthly.candidate(
            'current',
            recipe: old.variantId,
            date: '2026-10-15',
            servings: 2,
          ),
        ],
      },
    );
    expect(result.search.eligibleCount, 0);
    expect(result.search.bestKnownAffordable, isNull);
    expect(
      result.search.preferenceViolationsByOption.values.single.single.actual,
      2,
    );
    expect(
      result.candidatesByPool['first']!['old']!.recipeRevisionKey,
      old.key,
    );
    expect(
      result.candidatesByPool['second']!['current']!.recipeRevisionKey,
      current.key,
    );
  });

  test('service owns preferences before await and returns immutable accepted limits', () async {
    final k = await forecast.kitchen(forecast.CountedStore());
    await k.saveBudget(monthly.budget());
    final maxima = {'fixture': 0};
    final preferences = MonthlyBudgetRecipePreferences(
      maxOccurrencesByRecipe: maxima,
    );
    final pending = k.searchMonthlyBudgetChoices(
      'october',
      maxEvaluations: 1,
      recipePreferences: preferences,
      pools: {
        'one': [monthly.candidate('meal')],
      },
    );
    maxima.clear();
    final result = await pending;
    expect(result.search.eligibleCount, 0);
    expect(result.search.recipePreferences!.maxOccurrencesByRecipe, {
      'fixture': 0,
    });
    expect(result.search.recipePreferences, isNot(same(preferences)));
    expect(
      () => result.search.recipePreferences!.maxOccurrencesByRecipe.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => result.search.candidateRecipeIds.clear(),
      throwsUnsupportedError,
    );
    expect(() => result.search.eligibleRanked.clear(), throwsUnsupportedError);
  });

  test('preferences preserve stale rejection while resolving an unevaluated candidate', () async {
    final store = forecast.CountedStore();
    final (k, entered, release) = await monthly.gatedKitchen(store);
    final pin = (await k.recipeForMeal('p1')).key;
    final pending = k.searchMonthlyBudgetChoices(
      'october',
      maxEvaluations: 1,
      recipePreferences: MonthlyBudgetRecipePreferences(
        maxOccurrencesByRecipe: {'fixture': 0},
      ),
      pools: {
        'one': [
          monthly.candidate('evaluated', key: pin),
          monthly.candidate('unevaluated'),
        ],
      },
    );
    await entered.future.timeout(const Duration(seconds: 5));
    await k.savePrice(forecast.price('sample', 100), userOverride: true);
    final assertion = expectLater(pending, throwsStateError);
    release.complete();
    await assertion;
  });

  test('excluded unevaluated candidates still require valid revisions and line decisions', () async {
    final k = await forecast.kitchen(forecast.CountedStore());
    await k.saveBudget(monthly.budget());
    final preferences = MonthlyBudgetRecipePreferences(
      maxOccurrencesByRecipe: {'fixture': 0},
    );
    await expectLater(
      k.searchMonthlyBudgetChoices(
        'october',
        maxEvaluations: 1,
        recipePreferences: preferences,
        pools: {
          'one': [
            monthly.candidate('a'),
            monthly.candidate('bad', key: 'missing'),
          ],
        },
      ),
      throwsStateError,
    );
    await expectLater(
      k.searchMonthlyBudgetChoices(
        'october',
        maxEvaluations: 1,
        recipePreferences: preferences,
        pools: {
          'one': [monthly.candidate('a'), monthly.candidate('bad')],
        },
        optionalLinesByPool: {
          'one': {
            'bad': {0},
          },
        },
      ),
      throwsArgumentError,
    );
  });
}
