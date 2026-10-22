import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/domain/monthly_budget_choices.dart';

import 'monthly_budget_service_test.dart' as monthly;
import 'purchase_forecast_integration_test.dart' as forecast;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({KitchenService kitchen, forecast.CountedStore store})> prepared({
    double limit = 40,
  }) async {
    final store = forecast.CountedStore();
    final kitchen = await forecast.kitchen(store);
    await kitchen.saveBudget(monthly.budget(limit: limit));
    return (kitchen: kitchen, store: store);
  }

  Future<MonthlyBudgetSearchPreview> preview(
    KitchenService kitchen, {
    int maxEvaluations = 1,
  }) => kitchen.searchMonthlyBudgetChoices(
    'october',
    maxEvaluations: maxEvaluations,
    requiredSlots: const [
      MonthlyBudgetCoverage('2026-10-14', 'lunch'),
      MonthlyBudgetCoverage('2026-10-15', 'dinner'),
    ],
    pools: {
      'lunch-pool': [
        monthly.candidate('lunch-first', date: '2026-10-14'),
        monthly.candidate('lunch-second', date: '2026-10-14', servings: 1),
      ],
      'dinner-pool': [
        monthly.candidate('dinner-first', date: '2026-10-15', slot: 'dinner'),
        monthly.candidate(
          'dinner-second',
          date: '2026-10-15',
          slot: 'dinner',
          servings: 1,
        ),
      ],
    },
  );

  test('accepts one known affordable evaluated option in a single write with exact pinned plans', () async {
    final (kitchen: k, store: store) = await prepared();
    final result = await preview(k);
    final selected = result.search.comparison.assessments.single;
    expect(selected.withinBudget, isTrue);
    expect(result.search.truncated, isTrue);
    final before = k.snapshot;
    final savesBefore = store.saves;

    final retry = await preview(k);
    final retryOption = retry.search.comparison.assessments.single;
    final accepted = await k.acceptMonthlyBudgetSearchOption(
      retry,
      optionId: retryOption.option.id,
      planIdsByPool: {
        'lunch-pool': 'accepted-lunch',
        'dinner-pool': 'accepted-dinner',
      },
    );

    expect(store.saves, savesBefore + 1);
    expect(accepted, hasLength(2));
    expect(accepted.map((meal) => meal.id), [
      'accepted-lunch',
      'accepted-dinner',
    ]);
    expect(accepted.map((meal) => meal.recipeRevisionKey).toSet().length, 1);
    expect(accepted.every((meal) => meal.recipeRevisionKey != null), isTrue);
    expect(
      k.plans
          .where((meal) => meal.id.startsWith('accepted-'))
          .map((meal) => meal.toJson())
          .toList(),
      accepted.map((meal) => meal.toJson()).toList(),
    );
    for (final key in [
      'inventory',
      'prices',
      'purchases',
      'budgets',
      'nutrition',
    ]) {
      expect(
        k.snapshot[key],
        before[key],
        reason: '$key must not change during plan acceptance',
      );
    }
    expect(() => accepted.clear(), throwsUnsupportedError);
  });

  test(
    'rejects acceptance when the search omitted explicit required coverage',
    () async {
      final (kitchen: k, store: store) = await prepared();
      final result = await k.searchMonthlyBudgetChoices(
        'october',
        maxEvaluations: 1,
        pools: {
          'lunch-pool': [monthly.candidate('lunch-first', date: '2026-10-14')],
        },
      );
      final selected = result.search.comparison.assessments.single;
      final savesBefore = store.saves;

      await expectLater(
        k.acceptMonthlyBudgetSearchOption(
          result,
          optionId: selected.option.id,
          planIdsByPool: const {'lunch-pool': 'new-lunch'},
        ),
        throwsStateError,
      );
      expect(store.saves, savesBefore);
    },
  );
  test('rejects an unknown or unaffordable option without saving', () async {
    final (kitchen: k, store: store) = await prepared(limit: 1);
    final result = await preview(k, maxEvaluations: 2);
    final savesBefore = store.saves;

    await expectLater(
      k.acceptMonthlyBudgetSearchOption(
        result,
        optionId: 'not-evaluated',
        planIdsByPool: const {'lunch-pool': 'x', 'dinner-pool': 'y'},
      ),
      throwsArgumentError,
    );
    final unaffordable = result.search.comparison.assessments.firstWhere(
      (assessment) => assessment.withinBudget == false,
    );
    await expectLater(
      k.acceptMonthlyBudgetSearchOption(
        result,
        optionId: unaffordable.option.id,
        planIdsByPool: const {'lunch-pool': 'x', 'dinner-pool': 'y'},
      ),
      throwsStateError,
    );
    expect(store.saves, savesBefore);
  });

  test(
    'requires an exact unique mapping from selected pools to new plan IDs',
    () async {
      final (kitchen: k, store: store) = await prepared();
      final result = await preview(k);
      final selected = result.search.comparison.assessments.single;
      final savesBefore = store.saves;

      for (final mapping in [
        const {'lunch-pool': 'one'},
        const {'lunch-pool': 'one', 'dinner-pool': 'one'},
        const {'lunch-pool': ' ', 'dinner-pool': 'two'},
        const {'lunch-pool': 'one', 'dinner-pool': 'two', 'extra': 'three'},
      ]) {
        await expectLater(
          k.acceptMonthlyBudgetSearchOption(
            result,
            optionId: selected.option.id,
            planIdsByPool: mapping,
          ),
          throwsArgumentError,
        );
      }
      expect(store.saves, savesBefore);
    },
  );

  test('rejects stale or foreign previews before writing', () async {
    final (kitchen: k, store: store) = await prepared();
    final result = await preview(k);
    final selected = result.search.comparison.assessments.single;
    await k.savePrice(forecast.price('sample', 61), userOverride: true);
    final savesBefore = store.saves;

    await expectLater(
      k.acceptMonthlyBudgetSearchOption(
        result,
        optionId: selected.option.id,
        planIdsByPool: const {'lunch-pool': 'one', 'dinner-pool': 'two'},
      ),
      throwsStateError,
    );
    final other = await prepared();
    final otherSavesBefore = other.store.saves;
    await expectLater(
      other.kitchen.acceptMonthlyBudgetSearchOption(
        result,
        optionId: selected.option.id,
        planIdsByPool: const {'lunch-pool': 'one', 'dinner-pool': 'two'},
      ),
      throwsStateError,
    );
    expect(store.saves, savesBefore);
    expect(other.store.saves, otherSavesBefore);
  });

  test('refuses replacement by default and allows only explicit uncooked replacement', () async {
    final (kitchen: k, store: store) = await prepared();
    await k.plan(monthly.candidate('existing'));
    final result = await preview(k);
    final selected = result.search.comparison.assessments.single;
    final savesBefore = store.saves;

    await expectLater(
      k.acceptMonthlyBudgetSearchOption(
        result,
        optionId: selected.option.id,
        planIdsByPool: const {
          'lunch-pool': 'existing',
          'dinner-pool': 'new-dinner',
        },
      ),
      throwsStateError,
    );
    final retry = await preview(k);
    final retryOption = retry.search.comparison.assessments.single;
    final accepted = await k.acceptMonthlyBudgetSearchOption(
      retry,
      optionId: retryOption.option.id,
      planIdsByPool: const {
        'lunch-pool': 'existing',
        'dinner-pool': 'new-dinner',
      },
      allowReplaceUncooked: true,
    );
    expect(store.saves, savesBefore + 1);
    expect(accepted.map((meal) => meal.id), ['existing', 'new-dinner']);
    expect(
      k.plans.where((meal) => meal.id == 'existing').single.date,
      '2026-10-14',
    );
  });

  test('store failure leaves every plan unchanged', () async {
    final (kitchen: k, store: store) = await prepared();
    final result = await preview(k);
    final selected = result.search.comparison.assessments.single;
    final before = jsonEncode(k.snapshot);
    store.fail = true;

    await expectLater(
      k.acceptMonthlyBudgetSearchOption(
        result,
        optionId: selected.option.id,
        planIdsByPool: const {
          'lunch-pool': 'new-lunch',
          'dinner-pool': 'new-dinner',
        },
      ),
      throwsStateError,
    );
    expect(jsonEncode(k.snapshot), before);
  });

  test(
    'rejects a preview whose explicit required coverage is incomplete',
    () async {
      final (kitchen: k, store: store) = await prepared();
      final result = await k.searchMonthlyBudgetChoices(
        'october',
        maxEvaluations: 2,
        requiredSlots: const [
          MonthlyBudgetCoverage('2026-10-14', 'lunch'),
          MonthlyBudgetCoverage('2026-10-15', 'dinner'),
          MonthlyBudgetCoverage('2026-10-16', 'breakfast'),
        ],
        pools: {
          'lunch-pool': [monthly.candidate('lunch-first', date: '2026-10-14')],
          'dinner-pool': [
            monthly.candidate(
              'dinner-first',
              date: '2026-10-15',
              slot: 'dinner',
            ),
          ],
        },
      );
      final selected = result.search.comparison.assessments.single;
      final savesBefore = store.saves;

      await expectLater(
        k.acceptMonthlyBudgetSearchOption(
          result,
          optionId: selected.option.id,
          planIdsByPool: const {
            'lunch-pool': 'new-lunch',
            'dinner-pool': 'new-dinner',
          },
        ),
        throwsStateError,
      );
      expect(store.saves, savesBefore);
    },
  );
}
