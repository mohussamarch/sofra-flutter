import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/market_profile.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/monthly_budget_choices.dart';

BudgetPeriod month({
  double limit = 30,
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
  String ingredient,
  double amount, {
  String date = '2026-10-01',
  String slot = 'dinner',
  Set<String> unresolved = const {},
}) => MonthlyBudgetMeal(
  date: date,
  slot: slot,
  candidateId: '$ingredient-meal',
  requirements: [IngredientUse(ingredient, amount, 'g')],
  unresolvedRequirements: unresolved,
);
MonthlyBudgetOption option(String id, List<MonthlyBudgetMeal> meals) =>
    MonthlyBudgetOption(id: id, meals: meals);
InventoryLot lot(String ingredient, double? amount, {String unit = 'g'}) =>
    InventoryLot(
      id: '$ingredient-lot',
      ingredientId: ingredient,
      quantity: amount,
      unit: unit,
      zone: StorageZone.pantry,
    );
MoneyEntry purchase(
  String id,
  double amount,
  String date, {
  MarketCountry country = MarketCountry.egypt,
}) => MoneyEntry(
  id: id,
  amount: amount,
  country: country,
  date: DateTime.parse(date),
  note: 'Synthetic confirmed purchase',
);

MonthlyBudgetComparison compare(
  List<MonthlyBudgetOption> options, {
  BudgetPeriod? period,
  List<MoneyEntry> purchases = const [],
  List<InventoryLot> stock = const [],
  double? Function(MarketCountry, IngredientUse)? cost,
  List<UnitRule> rules = const [],
}) => compareMonthlyBudgetChoices(
  period: period ?? month(),
  confirmedPurchases: purchases,
  stock: stock,
  options: options,
  rules: rules,
  estimateCost: cost ?? ((country, use) => use.quantity * 0.04),
);

void main() {
  test(
    'ranks whole alternatives by new purchases with shared stock once each',
    () {
      final stock = [lot('rice', 750)];
      final options = [
        option('rice', [
          meal('rice', 500),
          meal('rice', 500, date: '2026-10-02'),
        ]),
        option('oil', [meal('oil', 200), meal('oil', 200, date: '2026-10-02')]),
      ];
      final result = compare(
        options,
        stock: stock,
        purchases: [purchase('paid', 5, '2026-10-03')],
      );
      expect(result.ranked.map((x) => x.option.id), ['rice', 'oil']);
      expect(result.ranked.first.forecast.purchaseTotal, 10);
      expect(result.ranked.first.forecast.consumptionTotal, 40);
      expect(result.ranked.first.remainingAfterPurchases, 15);
      expect(result.ranked.first.overrun, 0);
      expect(result.ranked.first.withinBudget, isTrue);
      expect(result.spent, 5);
      expect(result.remainingBeforePurchases, 25);
      expect(stock.single.quantity, 750);
      expect(options.first.meals.first.requirements.single.quantity, 500);
      expect(result.coverage.map((x) => '${x.date}/${x.slot}'), [
        '2026-10-01/dinner',
        '2026-10-02/dinner',
      ]);
    },
  );
  test('unknown price, quantity and relevant stock remain unranked', () {
    final result = compare(
      [
        option('known', [meal('rice', 100)]),
        option('price', [meal('oil', 100)]),
        option('stock', [meal('beans', 100)]),
        option('quantity', [
          meal('rice', 100, unresolved: {'recipe:line:2'}),
        ]),
      ],
      stock: [lot('beans', null)],
      cost: (_, use) => use.ingredientId == 'oil' ? null : 4,
    );
    expect(result.ranked.single.option.id, 'known');
    expect(result.unranked.map((row) => row.option.id), [
      'price',
      'stock',
      'quantity',
    ]);
    for (final row in result.unranked) {
      expect(row.forecast.purchaseTotal, isNull);
      expect(row.remainingAfterPurchases, isNull);
      expect(row.overrun, isNull);
      expect(row.withinBudget, isNull);
    }
    expect(result.unranked[0].forecast.unpricedPurchases, {'oil'});
    expect(result.unranked[1].forecast.unresolvedStock, {'beans'});
    expect(result.unranked[2].forecast.unresolvedRequirements, {
      'recipe:line:2',
    });
  });

  test(
    'existing stock is free to this budget while consumption price is unknown',
    () {
      final result = compare(
        [
          option('stocked', [meal('rice', 100)]),
        ],
        period: month(limit: 0),
        stock: [lot('rice', 100)],
        cost: (_, _) => null,
      );
      final row = result.ranked.single;
      expect(row.forecast.purchaseTotal, 0);
      expect(row.forecast.consumptionTotal, isNull);
      expect(row.withinBudget, isTrue);
      expect(row.remainingAfterPurchases, 0);
    },
  );

  test('confirmed spending is country and end-exclusive month scoped', () {
    final result = compare(
      [
        option('a', [meal('rice', 100)]),
      ],
      purchases: [
        purchase('start', 5, '2026-10-01'),
        purchase('last', 6, '2026-10-31T23:59:59'),
        purchase('old', 100, '2026-09-30'),
        purchase('next', 100, '2026-11-01'),
        purchase('saudi', 100, '2026-10-15', country: MarketCountry.saudi),
      ],
    );
    expect(result.spent, 11);
    expect(result.remainingBeforePurchases, 19);
    expect(result.ranked.single.remainingAfterPurchases, 15);
    final next = compare(
      [
        option('a', [meal('rice', 100, date: '2026-11-01')]),
      ],
      period: month(start: '2026-11-01', end: '2026-12-01'),
      purchases: [purchase('old', 5, '2026-10-01')],
    );
    expect(next.remainingBeforePurchases, 30);
  });

  test(
    'receives explicit country pricing and reports an overrun without editing',
    () {
      final prices = {MarketCountry.egypt: 4.0, MarketCountry.saudi: 8.0};
      final selected = option('caller-choice', [meal('rice', 100)]);
      final options = [selected];
      final row = compare(
        options,
        period: month(limit: 5, country: MarketCountry.saudi),
        purchases: [
          purchase('paid', 2, '2026-10-01', country: MarketCountry.saudi),
        ],
        cost: (country, _) => prices[country],
      ).ranked.single;
      expect(row.forecast.purchaseTotal, 8);
      expect(row.remainingAfterPurchases, -5);
      expect(row.overrun, 5);
      expect(row.withinBudget, isFalse);
      expect(options.single, same(selected));
      expect(selected.meals.single.candidateId, 'rice-meal');
    },
  );

  test(
    'preserves explicit unit conversions and never assumes count-to-mass',
    () {
      final options = [
        option('rice', [meal('rice', 100)]),
      ];
      final stock = [lot('rice', 1, unit: 'count')];
      expect(
        compare(options, stock: stock).unranked.single.forecast.unresolvedStock,
        {'rice'},
      );
      final resolved = compare(
        options,
        stock: stock,
        rules: [UnitRule('rice', 'count', 'g', 200)],
      );
      expect(resolved.ranked.single.forecast.purchaseTotal, 0);
      expect(stock.single.quantity, 1);
    },
  );

  test(
    'coverage can be partial and reordered but must be identical and unique',
    () {
      final result = compare([
        option('b', [meal('rice', 100, date: '2026-10-02'), meal('rice', 100)]),
        option('a', [meal('oil', 100), meal('oil', 100, date: '2026-10-02')]),
      ]);
      expect(result.coverage.length, 2);
      expect(result.coverage.first.date, '2026-10-01');
      expect(result.ranked.map((row) => row.option.id), ['a', 'b']);
      expect(
        () => compare([
          option('a', [meal('rice', 100)]),
          option('b', [meal('rice', 100, slot: 'lunch')]),
        ]),
        throwsArgumentError,
      );
      expect(
        () => compare([
          option('a', [meal('rice', 100), meal('oil', 100)]),
        ]),
        throwsArgumentError,
      );
    },
  );

  test(
    'validates calendar month including year rollover and leap February',
    () {
      for (final dates in [
        ('2026-12-01', '2027-01-01', '2026-12-31'),
        ('2028-02-01', '2028-03-01', '2028-02-29'),
      ]) {
        expect(
          compare(
            [
              option('a', [meal('rice', 100, date: dates.$3)]),
            ],
            period: month(start: dates.$1, end: dates.$2),
          ).coverage.single.date,
          dates.$3,
        );
      }
      for (final dates in [
        ('2026-10-02', '2026-11-01'),
        ('2026-10-01', '2026-10-31'),
        ('2026-10-01', '2026-12-01'),
      ]) {
        expect(
          () => compare([
            option('a', [meal('rice', 100, date: '2026-10-03')]),
          ], period: month(start: dates.$1, end: dates.$2)),
          throwsArgumentError,
        );
      }
      expect(
        () => compare([
          option('a', [meal('rice', 100, date: '2026-11-01')]),
        ]),
        throwsArgumentError,
      );
    },
  );

  test('rejects missing options, missing identity and ambiguous options', () {
    expect(() => compare([]), throwsArgumentError);
    expect(
      () => compare([
        option('', [meal('rice', 1)]),
      ]),
      throwsArgumentError,
    );
    expect(() => compare([option('a', [])]), throwsArgumentError);
    expect(
      () => compare([
        option('a', [meal('rice', 1)]),
        option('a', [meal('oil', 1)]),
      ]),
      throwsArgumentError,
    );
    expect(
      () => compare([
        option('a', [
          MonthlyBudgetMeal(
            date: '2026-10-01',
            slot: ' ',
            candidateId: 'a',
            requirements: [],
          ),
        ]),
      ]),
      throwsArgumentError,
    );
    expect(
      () => compare([
        option('a', [
          MonthlyBudgetMeal(
            date: '2026-10-01',
            slot: 'dinner',
            candidateId: ' ',
            requirements: [],
          ),
        ]),
      ]),
      throwsArgumentError,
    );
  });

  test(
    'owns inputs and exposes immutable assessment and coverage collections',
    () {
      final requirements = [IngredientUse('rice', 100, 'g')];
      final unknown = <String>{};
      final meals = [
        MonthlyBudgetMeal(
          date: '2026-10-01',
          slot: 'dinner',
          candidateId: 'a',
          requirements: requirements,
          unresolvedRequirements: unknown,
        ),
      ];
      final candidate = option('a', meals);
      requirements.clear();
      unknown.add('later');
      meals.clear();
      final options = [candidate];
      final result = compare(options);
      options.clear();
      expect(result.ranked.single.forecast.purchaseTotal, 4);
      expect(
        result.assessments.single.option.meals.single.requirements.length,
        1,
      );
      expect(() => result.assessments.clear(), throwsUnsupportedError);
      expect(() => result.ranked.clear(), throwsUnsupportedError);
      expect(() => result.unranked.clear(), throwsUnsupportedError);
      expect(() => result.coverage.clear(), throwsUnsupportedError);
      expect(() => candidate.meals.clear(), throwsUnsupportedError);
      expect(
        () => candidate.meals.single.requirements.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => candidate.meals.single.unresolvedRequirements.clear(),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'rejects nonfinite pricing and overflow rather than claiming affordability',
    () {
      final options = [
        option('a', [meal('rice', 100)]),
      ];
      for (final value in [double.nan, double.infinity, -1.0]) {
        expect(
          () => compare(options, cost: (_, _) => value),
          throwsArgumentError,
        );
      }
      expect(
        () => compare(
          options,
          purchases: [
            purchase('a', double.maxFinite, '2026-10-01'),
            purchase('b', double.maxFinite, '2026-10-02'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => compare(
          options,
          purchases: [purchase('a', double.maxFinite, '2026-10-01')],
          cost: (_, _) => double.maxFinite,
        ),
        throwsArgumentError,
      );
    },
  );
}
