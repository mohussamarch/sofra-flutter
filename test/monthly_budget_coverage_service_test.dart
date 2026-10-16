import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/monthly_budget_choices.dart';
import 'package:tabkha_demo/domain/monthly_budget_search.dart';

import 'monthly_budget_service_test.dart' as monthly;
import 'purchase_forecast_integration_test.dart' as forecast;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'service carries owned required slots into a read-only search',
    () async {
      final store = forecast.CountedStore();
      final k = await forecast.kitchen(store);
      await k.saveBudget(monthly.budget());
      await k.savePrice(forecast.price('sample', 50), userOverride: false);
      final required = [
        MonthlyBudgetCoverage('2026-10-14', 'lunch'),
        MonthlyBudgetCoverage('2026-10-15', 'lunch'),
      ];
      final before = jsonEncode(k.snapshot);
      final saves = store.saves;
      final pending = k.searchMonthlyBudgetChoices(
        'october',
        pools: {
          'first': [monthly.candidate('one')],
        },
        maxEvaluations: 1,
        requiredSlots: required,
      );
      required.clear();
      final result = await pending;
      expect(result.search.evaluatedCount, 1);
      expect(result.search.comparison.ranked.length, 1);
      expect(result.search.requiredCoverage!.missing.single.date, '2026-10-15');
      expect(result.search.outcome, MonthlyBudgetSearchOutcome.indeterminate);
      expect(result.search.bestKnownAffordable, isNull);
      expect(jsonEncode(k.snapshot), before);
      expect(store.saves, saves);
    },
  );

  test('service rejects invalid required slots without saving', () async {
    final store = forecast.CountedStore();
    final k = await forecast.kitchen(store);
    await k.saveBudget(monthly.budget());
    final before = jsonEncode(k.snapshot);
    final saves = store.saves;
    await expectLater(
      k.searchMonthlyBudgetChoices(
        'october',
        pools: {
          'first': [monthly.candidate('one')],
        },
        maxEvaluations: 1,
        requiredSlots: [
          MonthlyBudgetCoverage('2026-10-14', 'lunch'),
          MonthlyBudgetCoverage('2026-10-14', 'lunch'),
        ],
      ),
      throwsArgumentError,
    );
    expect(jsonEncode(k.snapshot), before);
    expect(store.saves, saves);
  });
}
