import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/market_profile.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/monthly_budget_choices.dart';
import 'package:tabkha_demo/domain/monthly_budget_search.dart';

BudgetPeriod month({
  double limit = 4,
  MarketCountry country = MarketCountry.egypt,
  String start = '2026-10-01',
  String end = '2026-11-01',
}) => BudgetPeriod(
  id: 'month',
  start: start,
  end: end,
  limit: limit,
  country: country,
);
MonthlyBudgetMeal meal(
  String id,
  double amount, {
  String date = '2026-10-01',
  String slot = 'dinner',
  String ingredient = 'rice',
  Set<String> unresolved = const {},
}) => MonthlyBudgetMeal(
  date: date,
  slot: slot,
  candidateId: id,
  requirements: [IngredientUse(ingredient, amount, 'g')],
  unresolvedRequirements: unresolved,
);
MonthlyBudgetSlotPool pool(
  List<MonthlyBudgetMeal> meals, {
  String date = '2026-10-01',
  String slot = 'dinner',
}) => MonthlyBudgetSlotPool(date: date, slot: slot, candidates: meals);
InventoryLot lot(
  double? amount, {
  String ingredient = 'rice',
  String unit = 'g',
}) => InventoryLot(
  id: '$ingredient-lot',
  ingredientId: ingredient,
  quantity: amount,
  unit: unit,
  zone: StorageZone.pantry,
);
MoneyEntry purchase(
  double amount, {
  String date = '2026-10-01',
  MarketCountry country = MarketCountry.egypt,
}) => MoneyEntry(
  id: '$date-${country.name}',
  amount: amount,
  country: country,
  date: DateTime.parse(date),
  note: 'Synthetic test purchase',
);
MonthlyBudgetSearchResult search(
  List<MonthlyBudgetSlotPool> pools, {
  BudgetPeriod? period,
  int max = 20,
  List<MoneyEntry> purchases = const [],
  List<InventoryLot> stock = const [],
  List<UnitRule> rules = const [],
  double? Function(MarketCountry, IngredientUse)? cost,
}) => searchMonthlyBudgetChoices(
  period: period ?? month(),
  confirmedPurchases: purchases,
  stock: stock,
  pools: pools,
  maxEvaluations: max,
  rules: rules,
  estimateCost: cost ?? ((_, use) => use.quantity * 0.04),
);

void main() {
  test('enumerates complete options with shared stock once and frozen country spending', () {
    final stock = [lot(250)];
    final result = search(
      [
        pool([meal('first-large', 200), meal('first-small', 100)]),
        pool([
          meal('second-large', 200, date: '2026-10-02'),
          meal('second-small', 100, date: '2026-10-02'),
        ], date: '2026-10-02'),
      ],
      stock: stock,
      purchases: [
        purchase(3),
        purchase(100, date: '2026-09-30'),
        purchase(100, country: MarketCountry.saudi),
      ],
    );
    expect(result.totalCombinations, BigInt.from(4));
    expect(result.evaluatedCount, 4);
    expect(result.truncated, isFalse);
    expect(result.unknownCostCount, 0);
    expect(result.outcome, MonthlyBudgetSearchOutcome.affordableFound);
    expect(
      result.bestKnownAffordable!.option.meals.map((row) => row.candidateId),
      ['first-small', 'second-small'],
    );
    expect(result.bestKnownAffordable!.forecast.purchaseTotal, 0);
    expect(result.bestKnownAffordable!.forecast.consumptionTotal, 8);
    expect(result.comparison.assessments.first.forecast.purchaseTotal, 6);
    expect(result.comparison.spent, 3);
    expect(result.comparison.coverage.length, 2);
    expect(stock.single.quantity, 250);
  });
  test(
    'a cap is indeterminate both with and without a known affordable option',
    () {
      final pools = [
        pool([meal('expensive', 200), meal('cheap', 10)]),
      ];
      final capped = search(pools, max: 1);
      expect(capped.totalCombinations, BigInt.two);
      expect(capped.evaluatedCount, 1);
      expect(capped.truncated, isTrue);
      expect(capped.outcome, MonthlyBudgetSearchOutcome.indeterminate);
      expect(capped.bestKnownAffordable, isNull);
      final exhaustive = search(pools, max: 2);
      expect(
        exhaustive.bestKnownAffordable!.option.meals.single.candidateId,
        'cheap',
      );
      expect(exhaustive.outcome, MonthlyBudgetSearchOutcome.affordableFound);
      final affordablePrefix = search([
        pool([meal('cheap', 10), meal('expensive', 200)]),
      ], max: 1);
      expect(affordablePrefix.bestKnownAffordable, isNotNull);
      expect(
        affordablePrefix.outcome,
        MonthlyBudgetSearchOutcome.indeterminate,
      );
    },
  );

  test(
    'unknown price, quantity or stock keeps exhaustive search indeterminate',
    () {
      final result = search(
        [
          pool([
            meal('known', 100),
            meal('unknown-price', 100, ingredient: 'oil'),
            meal('unknown-stock', 100, ingredient: 'beans'),
            meal('unknown-quantity', 100, unresolved: {'line:2'}),
          ]),
        ],
        stock: [lot(null, ingredient: 'beans')],
        cost: (_, use) =>
            use.ingredientId == 'oil' ? null : use.quantity * 0.04,
      );
      expect(result.truncated, isFalse);
      expect(result.evaluatedCount, 4);
      expect(result.unknownCostCount, 3);
      expect(result.outcome, MonthlyBudgetSearchOutcome.indeterminate);
      expect(
        result.bestKnownAffordable!.option.meals.single.candidateId,
        'known',
      );
      for (final row in result.comparison.unranked) {
        expect(row.withinBudget, isNull);
        expect(row.remainingAfterPurchases, isNull);
      }
      expect(result.comparison.unranked[0].forecast.unpricedPurchases, {'oil'});
      expect(result.comparison.unranked[1].forecast.unresolvedStock, {'beans'});
      expect(result.comparison.unranked[2].forecast.unresolvedRequirements, {
        'line:2',
      });
    },
  );

  test('exhaustive negative outcome is scoped to supplied pools and known zero is affordable', () {
    final result = search([
      pool([meal('a', 200), meal('b', 300)]),
    ]);
    expect(result.evaluatedCount, 2);
    expect(result.truncated, isFalse);
    expect(
      result.outcome,
      MonthlyBudgetSearchOutcome.noAffordableInSuppliedPools,
    );
    expect(result.bestKnownAffordable, isNull);
    expect(result.comparison.coverage.length, 1);
    final free = search(
      [
        pool([meal('zero', 100)]),
      ],
      period: month(limit: 0),
      cost: (_, _) => 0,
    );
    expect(free.unknownCostCount, 0);
    expect(free.outcome, MonthlyBudgetSearchOutcome.affordableFound);
    expect(free.bestKnownAffordable!.forecast.purchaseTotal, 0);
  });

  test(
    'validates all unexamined candidates and pools before invoking pricing',
    () {
      final valid = meal('valid', 100);
      final invalidCandidates = [
        meal('', 100),
        meal('wrong-day', 100, date: '2026-10-02'),
        meal('wrong-slot', 100, slot: 'lunch'),
        meal('missing-id', 100, ingredient: ' '),
        MonthlyBudgetMeal(
          date: '2026-10-01',
          slot: 'dinner',
          candidateId: 'missing-unit',
          requirements: [IngredientUse('rice', 1, '')],
        ),
        meal('missing-unknown-id', 100, unresolved: {' '}),
      ];
      for (final invalid in invalidCandidates) {
        var calls = 0;
        expect(
          () => search(
            [
              pool([valid, invalid]),
            ],
            max: 1,
            cost: (_, _) {
              calls++;
              return 1;
            },
          ),
          throwsArgumentError,
        );
        expect(calls, 0);
      }
      final invalidPools = <List<MonthlyBudgetSlotPool>>[
        [],
        [pool([])],
        [
          pool([valid, valid]),
        ],
        [
          pool([valid]),
          pool([valid]),
        ],
        [
          pool([valid]),
          pool([meal('out', 100, date: '2026-11-01')], date: '2026-11-01'),
        ],
        [
          pool([valid]),
          pool([meal('blank', 100, slot: ' ')], slot: ' '),
        ],
      ];
      for (final pools in invalidPools) {
        var calls = 0;
        expect(
          () => search(
            pools,
            max: 1,
            cost: (_, _) {
              calls++;
              return 1;
            },
          ),
          throwsArgumentError,
        );
        expect(calls, 0);
      }
      for (final maximum in [0, -1]) {
        expect(
          () => search(
            [
              pool([valid]),
            ],
            max: maximum,
            cost: (_, _) => throw StateError('must not price invalid inputs'),
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => search(
          [
            pool([valid]),
          ],
          period: month(start: '2026-10-02'),
          cost: (_, _) => throw StateError('must validate month first'),
        ),
        throwsArgumentError,
      );
      expect(
        () => search(
          [
            pool([valid]),
          ],
          rules: [UnitRule('', 'g', 'kg', 0.001)],
          cost: (_, _) => throw StateError('must validate rules first'),
        ),
        throwsArgumentError,
      );
    },
  );

  test('large products use exact BigInt count and evaluate only a bounded odometer prefix', () {
    final pools = [
      for (var i = 0; i < 70; i++)
        pool([
          meal('a-$i', 1, slot: 'slot-$i'),
          meal('b-$i', 2, slot: 'slot-$i'),
        ], slot: 'slot-$i'),
    ];
    var calls = 0;
    final result = search(
      pools,
      max: 3,
      cost: (_, use) {
        calls++;
        return use.quantity;
      },
    );
    expect(result.totalCombinations, BigInt.one << 70);
    expect(result.evaluatedCount, 3);
    expect(result.truncated, isTrue);
    expect(result.outcome, MonthlyBudgetSearchOutcome.indeterminate);
    expect(calls, 6);
    final tails = result.comparison.assessments
        .map(
          (row) => row.option.meals
              .skip(68)
              .map((meal) => meal.candidateId)
              .toList(),
        )
        .toList();
    expect(tails, [
      ['a-68', 'a-69'],
      ['a-68', 'b-69'],
      ['b-68', 'a-69'],
    ]);
  });

  test('owns snapshot collections before callback reentry and exposes immutable results', () {
    final candidateInput = [meal('a', 300), meal('b', 400)];
    final pools = [pool(candidateInput)];
    final stock = [lot(1, unit: 'count')];
    final purchases = [purchase(5)];
    final rules = [UnitRule('rice', 'count', 'g', 200)];
    var called = false;
    final result = search(
      pools,
      period: month(limit: 40),
      stock: stock,
      purchases: purchases,
      rules: rules,
      cost: (_, use) {
        if (!called) {
          called = true;
          pools.clear();
          stock.clear();
          purchases.clear();
          rules.clear();
          candidateInput.clear();
        }
        return use.quantity * 0.04;
      },
    );
    expect(result.evaluatedCount, 2);
    expect(result.comparison.spent, 5);
    expect(
      result.comparison.assessments.map((row) => row.forecast.purchaseTotal),
      [4, 8],
    );
    expect(() => result.comparison.assessments.clear(), throwsUnsupportedError);
    expect(() => result.comparison.ranked.clear(), throwsUnsupportedError);
    expect(() => result.comparison.coverage.clear(), throwsUnsupportedError);
    expect(
      () => result.comparison.assessments.first.option.meals.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => result.comparison.assessments.first.option.meals.first.requirements
          .clear(),
      throwsUnsupportedError,
    );
    final ownedCandidates = [meal('one', 1)];
    final ownedPool = pool(ownedCandidates);
    ownedCandidates.clear();
    expect(ownedPool.candidates.length, 1);
    expect(() => ownedPool.candidates.clear(), throwsUnsupportedError);
  });

  test(
    'evaluates whole options without assuming price monotonicity for pruning',
    () {
      final result = search(
        [
          pool([meal('smaller-expensive', 100), meal('larger-cheap', 200)]),
        ],
        period: month(limit: 2),
        cost: (_, use) => use.quantity >= 200 ? 1 : 100,
      );
      expect(result.evaluatedCount, 2);
      expect(result.outcome, MonthlyBudgetSearchOutcome.affordableFound);
      expect(
        result.bestKnownAffordable!.option.meals.single.candidateId,
        'larger-cheap',
      );
    },
  );

  test('invalid callback amounts and financial overflow reject instead of claiming affordability', () {
    final pools = [
      pool([meal('a', 100)]),
    ];
    for (final amount in [double.nan, double.infinity, -1.0]) {
      expect(() => search(pools, cost: (_, _) => amount), throwsArgumentError);
    }
    expect(
      () => search(
        pools,
        purchases: [
          purchase(double.maxFinite),
          purchase(double.maxFinite, date: '2026-10-02'),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => search(
        pools,
        purchases: [purchase(double.maxFinite)],
        cost: (_, _) => double.maxFinite,
      ),
      throwsArgumentError,
    );
  });

  test('permits a recipe in different slots and ties follow stable vector IDs lexically', () {
    final repeated = search([
      pool([meal('same-recipe', 10)]),
      pool([meal('same-recipe', 10, date: '2026-10-02')], date: '2026-10-02'),
    ]);
    expect(repeated.totalCombinations, BigInt.one);
    expect(repeated.evaluatedCount, 1);
    expect(repeated.comparison.coverage.length, 2);
    final tied = search([
      pool([for (var i = 0; i < 12; i++) meal('candidate-$i', 1)]),
    ], max: 12);
    expect(tied.comparison.assessments.map((row) => row.option.id), [
      for (var i = 0; i < 12; i++) 'choice:$i',
    ]);
    expect(tied.comparison.ranked.take(4).map((row) => row.option.id), [
      'choice:0',
      'choice:1',
      'choice:10',
      'choice:11',
    ]);
    expect(tied.bestKnownAffordable!.option.id, 'choice:0');
  });
}
