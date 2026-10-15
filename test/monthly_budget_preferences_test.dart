import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/market_profile.dart';
import 'package:tabkha_demo/domain/monthly_budget_preferences.dart';
import 'package:tabkha_demo/domain/monthly_budget_search.dart';

import 'monthly_budget_search_test.dart' as fixture;

Map<MonthlyBudgetCandidateKey, String> identities(
  List<MonthlyBudgetSlotPool> pools,
  Map<String, String> recipeByCandidate,
) => {
  for (final pool in pools)
    for (final meal in pool.candidates)
      (date: meal.date, slot: meal.slot, candidateId: meal.candidateId):
          recipeByCandidate[meal.candidateId]!,
};

MonthlyBudgetSearchResult search(
  List<MonthlyBudgetSlotPool> pools, {
  MonthlyBudgetRecipePreferences? preferences,
  Map<MonthlyBudgetCandidateKey, String> context = const {},
  int max = 20,
  double? Function(MarketCountry, IngredientUse)? cost,
}) => searchMonthlyBudgetChoices(
  period: fixture.month(),
  confirmedPurchases: [],
  stock: [],
  maxEvaluations: max,
  pools: pools,
  recipePreferences: preferences,
  candidateRecipeIds: context,
  estimateCost: cost ?? ((_, use) => use.quantity * 0.04),
);
void main() {
  test('repeat and diversity preferences constrain the best known option', () {
    final result = searchMonthlyBudgetChoices(
      period: fixture.month(),
      confirmedPurchases: [],
      stock: [],
      maxEvaluations: 4,
      pools: [
        fixture.pool([fixture.meal('a1', 10), fixture.meal('b1', 20)]),
        fixture.pool([
          fixture.meal('a2', 10, date: '2026-10-02'),
          fixture.meal('b2', 20, date: '2026-10-02'),
        ], date: '2026-10-02'),
      ],
      recipePreferences: MonthlyBudgetRecipePreferences(
        maxOccurrencesByRecipe: {'recipe-a': 1},
        minimumDistinctRecipes: 2,
      ),
      candidateRecipeIds: {
        (date: '2026-10-01', slot: 'dinner', candidateId: 'a1'): 'recipe-a',
        (date: '2026-10-01', slot: 'dinner', candidateId: 'b1'): 'recipe-b',
        (date: '2026-10-02', slot: 'dinner', candidateId: 'a2'): 'recipe-a',
        (date: '2026-10-02', slot: 'dinner', candidateId: 'b2'): 'recipe-b',
      },
      estimateCost: (_, use) => use.quantity * 0.04,
    );
    expect(
      result.bestKnownAffordable!.option.meals.map((meal) => meal.candidateId),
      ['a1', 'b2'],
    );
  });
  test('explicit zero exclusion and conflicting diversity yield reasons without relaxation', () {
    final pools = [
      fixture.pool([fixture.meal('a', 10)]),
    ];
    final result = search(
      pools,
      context: identities(pools, {'a': 'recipe-a'}),
      preferences: MonthlyBudgetRecipePreferences(
        maxOccurrencesByRecipe: {'recipe-a': 0},
        minimumDistinctRecipes: 2,
      ),
    );
    expect(result.eligibleCount, 0);
    expect(result.eligibleRanked, isEmpty);
    expect(result.bestKnownAffordable, isNull);
    expect(
      result.outcome,
      MonthlyBudgetSearchOutcome.noAffordableInSuppliedPools,
    );
    expect(result.comparison.ranked.single.withinBudget, isTrue);
    final reasons = result.preferenceViolationsByOption.values.single;
    expect(reasons.map((reason) => reason.kind), [
      MonthlyBudgetPreferenceViolationKind.maximumOccurrences,
      MonthlyBudgetPreferenceViolationKind.minimumDistinctRecipes,
    ]);
    expect(
      (reasons.first.recipeId, reasons.first.actual, reasons.first.limit),
      ('recipe-a', 1, 0),
    );
    expect((reasons.last.actual, reasons.last.limit), (1, 2));
    expect(() => reasons.clear(), throwsUnsupportedError);
  });

  test('absent or empty preferences preserve old search and reject invalid explicit limits', () {
    final pools = [
      fixture.pool([fixture.meal('a', 10), fixture.meal('b', 20)]),
    ];
    final absent = search(pools),
        empty = search(pools, preferences: MonthlyBudgetRecipePreferences());
    expect(absent.recipePreferences, isNull);
    expect(absent.eligibleCount, 2);
    expect(empty.eligibleRanked, empty.comparison.ranked);
    expect(
      absent.bestKnownAffordable!.option.id,
      empty.bestKnownAffordable!.option.id,
    );
    expect(absent.outcome, empty.outcome);
    expect(empty.candidateRecipeIds, isEmpty);
    for (final minimum in [0, -1]) {
      expect(
        () => MonthlyBudgetRecipePreferences(minimumDistinctRecipes: minimum),
        throwsArgumentError,
      );
    }
    expect(
      () => MonthlyBudgetRecipePreferences(maxOccurrencesByRecipe: {' ': 1}),
      throwsArgumentError,
    );
    expect(
      () => MonthlyBudgetRecipePreferences(maxOccurrencesByRecipe: {'a': -1}),
      throwsArgumentError,
    );
  });

  test('all unexamined recipe identities validate before pricing and no scope is ignored', () {
    final pools = [
      fixture.pool([fixture.meal('a', 10), fixture.meal('unexamined', 20)]),
    ];
    final complete = identities(pools, {
      'a': 'recipe-a',
      'unexamined': 'recipe-b',
    });
    final firstOnly = Map<MonthlyBudgetCandidateKey, String>.of(complete)
      ..removeWhere((key, _) => key.candidateId == 'unexamined');
    final blank = Map<MonthlyBudgetCandidateKey, String>.of(complete);
    blank[(date: '2026-10-01', slot: 'dinner', candidateId: 'unexamined')] =
        ' ';
    final extra = Map<MonthlyBudgetCandidateKey, String>.of(complete)
      ..[(date: '2026-10-02', slot: 'dinner', candidateId: 'other')] = 'other';
    final wrongScope = Map<MonthlyBudgetCandidateKey, String>.of(complete)
      ..removeWhere((key, _) => key.candidateId == 'unexamined')
      ..[(date: '2026-10-01', slot: 'lunch', candidateId: 'unexamined')] =
          'recipe-b';
    for (final context in [{}, firstOnly, blank, extra, wrongScope]) {
      var calls = 0;
      expect(
        () => search(
          pools,
          max: 1,
          context: Map<MonthlyBudgetCandidateKey, String>.from(context),
          preferences: MonthlyBudgetRecipePreferences(
            minimumDistinctRecipes: 1,
          ),
          cost: (_, _) {
            calls++;
            return 1;
          },
        ),
        throwsArgumentError,
      );
      expect(calls, 0);
    }
    expect(() => search(pools, context: firstOnly), throwsArgumentError);
  });

  test('rejected combinations consume the cap and unknown rejected costs stay indeterminate', () {
    final pools = [
      fixture.pool([fixture.meal('excluded', 10), fixture.meal('allowed', 20)]),
    ];
    final context = identities(pools, {'excluded': 'a', 'allowed': 'b'});
    final preferences = MonthlyBudgetRecipePreferences(
      maxOccurrencesByRecipe: {'a': 0},
    );
    final capped = search(
      pools,
      max: 1,
      context: context,
      preferences: preferences,
    );
    expect(capped.evaluatedCount, 1);
    expect(capped.eligibleCount, 0);
    expect(capped.bestKnownAffordable, isNull);
    expect(capped.outcome, MonthlyBudgetSearchOutcome.indeterminate);
    final complete = search(
      pools,
      max: 2,
      context: context,
      preferences: preferences,
    );
    expect(
      complete.bestKnownAffordable!.option.meals.single.candidateId,
      'allowed',
    );
    expect(complete.outcome, MonthlyBudgetSearchOutcome.affordableFound);
    final unknown = search(
      pools,
      context: context,
      preferences: preferences,
      cost: (_, use) => use.quantity == 10 ? null : 1,
    );
    expect(unknown.unknownCostCount, 1);
    expect(
      unknown.bestKnownAffordable!.option.meals.single.candidateId,
      'allowed',
    );
    expect(unknown.outcome, MonthlyBudgetSearchOutcome.indeterminate);
    final eligibleUnknown = search(
      [
        fixture.pool([fixture.meal('u', 1)]),
      ],
      context: identities(
        [
          fixture.pool([fixture.meal('u', 1)]),
        ],
        {'u': 'b'},
      ),
      preferences: MonthlyBudgetRecipePreferences(minimumDistinctRecipes: 1),
      cost: (_, _) => null,
    );
    expect(eligibleUnknown.eligibleCount, 1);
    expect(eligibleUnknown.eligibleRanked, isEmpty);
  });

  test('owns preferences and identity context before callbacks and returns immutable evidence', () {
    final pools = [
      fixture.pool([fixture.meal('a', 10)]),
      fixture.pool([
        fixture.meal('b', 20, date: '2026-10-02'),
      ], date: '2026-10-02'),
    ];
    final context = identities(pools, {'a': 'a', 'b': 'b'}), maxima = {'a': 1};
    final preferences = MonthlyBudgetRecipePreferences(
      maxOccurrencesByRecipe: maxima,
      minimumDistinctRecipes: 2,
    );
    final result = search(
      pools,
      context: context,
      preferences: preferences,
      cost: (_, use) {
        context.clear();
        maxima.clear();
        pools.clear();
        return use.quantity * 0.04;
      },
    );
    expect(result.eligibleCount, 1);
    expect(result.recipePreferences!.maxOccurrencesByRecipe, {'a': 1});
    expect(result.candidateRecipeIds.length, 2);
    expect(() => result.candidateRecipeIds.clear(), throwsUnsupportedError);
    expect(
      () => result.recipePreferences!.maxOccurrencesByRecipe.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => result.preferenceViolationsByOption.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => result.preferenceViolationsByOption.values.single.clear(),
      throwsUnsupportedError,
    );
    expect(() => result.eligibleRanked.clear(), throwsUnsupportedError);
  });

  test('counts proposal slots once regardless of amounts and keeps exact case-sensitive recipe IDs', () {
    final pools = [
      fixture.pool([fixture.meal('tiny', 1)]),
      fixture.pool([
        fixture.meal('large', 40, date: '2026-10-02'),
      ], date: '2026-10-02'),
    ];
    final repeated = search(
      pools,
      context: identities(pools, {'tiny': 'recipe', 'large': 'recipe'}),
      preferences: MonthlyBudgetRecipePreferences(
        maxOccurrencesByRecipe: {'recipe': 1},
      ),
    );
    final reason = repeated.preferenceViolationsByOption.values.single.single;
    expect((reason.actual, reason.limit), (2, 1));
    final distinct = search(
      pools,
      context: identities(pools, {'tiny': 'recipe', 'large': 'Recipe'}),
      preferences: MonthlyBudgetRecipePreferences(minimumDistinctRecipes: 2),
    );
    expect(distinct.eligibleCount, 1);
  });

  test('an impossible explicit minimum returns scoped evidence without filling missing month slots', () {
    final pools = [
      fixture.pool([fixture.meal('a', 10)]),
    ];
    final result = search(
      pools,
      context: identities(pools, {'a': 'a'}),
      preferences: MonthlyBudgetRecipePreferences(minimumDistinctRecipes: 3),
    );
    expect(result.comparison.coverage.length, 1);
    expect(result.evaluatedCount, 1);
    expect(result.eligibleCount, 0);
    expect(
      result.outcome,
      MonthlyBudgetSearchOutcome.noAffordableInSuppliedPools,
    );
    expect(result.preferenceViolationsByOption.values.single.single.limit, 3);
  });
}
