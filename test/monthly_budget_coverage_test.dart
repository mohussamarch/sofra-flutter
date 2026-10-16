import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/monthly_budget_choices.dart';
import 'package:tabkha_demo/domain/monthly_budget_coverage.dart';
import 'package:tabkha_demo/domain/monthly_budget_search.dart';

import 'monthly_budget_search_test.dart' as fixture;

MonthlyBudgetCoverage slot(String date, String name) =>
    MonthlyBudgetCoverage(date, name);

void main() {
  test(
    'missing declared slots gate affordability but preserve financial evidence',
    () {
      final result = searchMonthlyBudgetChoices(
        period: fixture.month(),
        confirmedPurchases: [],
        stock: [],
        pools: [
          fixture.pool([fixture.meal('cheap', 10)]),
        ],
        maxEvaluations: 1,
        requiredSlots: [
          slot('2026-10-01', 'dinner'),
          slot('2026-10-02', 'dinner'),
        ],
        estimateCost: (_, use) => use.quantity * 0.04,
      );
      expect(result.truncated, isFalse);
      expect(result.unknownCostCount, 0);
      expect(result.comparison.ranked.length, 1);
      expect(result.comparison.ranked.single.withinBudget, isTrue);
      expect(result.bestKnownAffordable, isNull);
      expect(result.outcome, MonthlyBudgetSearchOutcome.indeterminate);
      expect(result.requiredCoverage!.missing.single.date, '2026-10-02');
      expect(result.requiredCoverage!.coversRequired, isFalse);
    },
  );

  test('full declared coverage permits affordability and reports extra supplied slots', () {
    final result = searchMonthlyBudgetChoices(
      period: fixture.month(),
      confirmedPurchases: [],
      stock: [],
      pools: [
        fixture.pool([fixture.meal('one', 10)]),
        fixture.pool([
          fixture.meal('two', 10, date: '2026-10-02'),
        ], date: '2026-10-02'),
      ],
      maxEvaluations: 1,
      requiredSlots: [slot('2026-10-01', 'dinner')],
      estimateCost: (_, use) => use.quantity * 0.04,
    );
    expect(result.requiredCoverage!.coversRequired, isTrue);
    expect(result.requiredCoverage!.additional.single.date, '2026-10-02');
    expect(result.outcome, MonthlyBudgetSearchOutcome.affordableFound);
    expect(result.bestKnownAffordable, isNotNull);
  });

  test('validates all caller-required slots before price callbacks', () {
    final invalid = [
      <MonthlyBudgetCoverage>[],
      [slot('2026-10-01', 'dinner'), slot('2026-10-01', 'dinner')],
      [slot('2026-10-01', ' ')],
      [slot('2026-11-01', 'dinner')],
      [slot('2026-10-32', 'dinner')],
    ];
    for (final required in invalid) {
      var calls = 0;
      expect(
        () => searchMonthlyBudgetChoices(
          period: fixture.month(),
          confirmedPurchases: [],
          stock: [],
          pools: [
            fixture.pool([fixture.meal('one', 10)]),
          ],
          maxEvaluations: 1,
          requiredSlots: required,
          estimateCost: (_, _) {
            calls++;
            return 1;
          },
        ),
        throwsA(anyOf(isA<ArgumentError>(), isA<FormatException>())),
      );
      expect(calls, 0);
    }
  });

  test('assessment owns sorted slot lists and never infers daily meals', () {
    final required = [
      slot('2026-10-31', 'breakfast'),
      slot('2026-10-01', 'dinner'),
    ];
    final supplied = [slot('2026-10-01', 'dinner')];
    final result = assessMonthlyBudgetSlotCoverage(
      period: fixture.month(),
      requiredSlots: required,
      suppliedSlots: supplied,
    );
    required.clear();
    supplied.clear();
    expect(result.required.map((row) => row.date), [
      '2026-10-01',
      '2026-10-31',
    ]);
    expect(result.missing.single.date, '2026-10-31');
    expect(result.additional, isEmpty);
    expect(() => result.missing.clear(), throwsUnsupportedError);
  });
}
