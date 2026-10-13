import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/person_nutrition.dart';
import 'package:tabkha_demo/domain/recipe_nutrition.dart';

import 'food_nutrition_test.dart' as fixture;

void main() {
  test('preparation uncertainty survives serialization, arithmetic and person adapter', () {
    final transform = PreparationTransform.fromJson({
      'id': 'synthetic-estimate',
      'sourceForm': 'raw',
      'targetForm': 'cooked',
      'source': fixture.source.toJson(),
      'massYield': null,
      'retention': {'protein': 0.5},
      'estimated': true,
      'evidence': '{"test":"synthetic evidence only"}',
    });
    expect(transform.toJson()['estimated'], true);
    expect(
      transform.toJson()['evidence'],
      '{"test":"synthetic evidence only"}',
    );
    final result = fixture.calculate([
      fixture.input(
        'sample',
        fixture.food(),
        preparedForm: FoodForm.cooked,
        preparation: transform,
      ),
    ]);
    expect(result.whole[NutrientId.protein]!.value, 10);
    expect(result.whole[NutrientId.protein]!.estimated, true);
    expect(result.whole[NutrientId.energyKcal]!.value, isNull);
    final batch = nutritionMealBatch(
      result,
      batchId: 'batch',
      sourceSnapshotId: 'test',
    );
    expect(batch.nutrients['protein']!.toJson()['estimated'], true);
    final reloaded = MealBatch.fromJson(batch.toJson());
    final ledger = NutritionLedger.empty()
        .addBatch(reloaded)
        .append(
          NutritionEvent(
            id: 'eat',
            batchId: 'batch',
            kind: NutritionEventKind.consumed,
            personId: 'member',
            portion: PortionAmount(0.5, PortionUnit.batchFraction),
            day: '2026-10-13',
            actorId: 'test',
            recordedAt: DateTime.utc(2026, 10, 13),
          ),
        );
    final report = ledger.report(
      personId: 'member',
      day: '2026-10-13',
      kind: NutritionEventKind.consumed,
    );
    expect(report.nutrients['protein']!.value, 5);
    expect(report.nutrients['protein']!.toJson()['estimated'], true);
  });

  test(
    'old person confidence stays unknown, never silently upgraded to exact',
    () {
      final value = PersonNutrientValue.fromJson({
        'knownSubtotal': 12,
        'complete': true,
        'unit': 'g',
      });
      expect(value.toJson().containsKey('estimated'), true);
      expect(value.toJson()['estimated'], isNull);
      final old = PreparationTransform.fromJson({
        'id': 'legacy',
        'sourceForm': 'raw',
        'targetForm': 'cooked',
        'source': fixture.source.toJson(),
        'massYield': null,
        'retention': {'protein': 0.5},
      });
      expect(old.toJson()['estimated'], false);
    },
  );

  test(
    'source quantity estimates survive the adapter even without preparation',
    () {
      final input = RecipeFoodInput.fromJson({
        ...fixture.input('sample', fixture.food()).toJson(),
        'quantityEstimated': true,
      });
      final result = fixture.calculate([input]);
      final batch = nutritionMealBatch(
        result,
        batchId: 'quantity',
        sourceSnapshotId: 'test',
      );
      expect(batch.nutrients['protein']!.toJson()['estimated'], true);
      expect(batch.nutrients['protein']!.value, 20);
    },
  );

  test('report merges true, false and legacy unknown confidence without losing gaps', () {
    MealBatch batch(String id, bool? estimated, {bool complete = true}) =>
        MealBatch(
          id: id,
          recipeId: 'fixture',
          sourceSnapshotId: 'test',
          nutrients: {
            'protein': PersonNutrientValue.fromJson({
              'knownSubtotal': 10,
              'complete': complete,
              'unit': 'g',
              'estimated': estimated,
            }),
          },
        );
    NutritionEvent eat(String id, String batchId) => NutritionEvent(
      id: id,
      batchId: batchId,
      kind: NutritionEventKind.consumed,
      personId: 'member',
      portion: PortionAmount(0.5, PortionUnit.batchFraction),
      day: '2026-10-13',
      actorId: 'test',
      recordedAt: DateTime.utc(2026, 10, 13),
    );
    PersonNutrientValue report(NutritionLedger ledger) => ledger
        .report(
          personId: 'member',
          day: '2026-10-13',
          kind: NutritionEventKind.consumed,
        )
        .nutrients['protein']!;
    var ledger = NutritionLedger.empty()
        .addBatch(batch('exact', false))
        .append(eat('e1', 'exact'));
    expect(report(ledger).toJson()['estimated'], false);
    ledger = ledger.addBatch(batch('old', null)).append(eat('e2', 'old'));
    expect(report(ledger).toJson()['estimated'], isNull);
    ledger = ledger
        .addBatch(batch('estimate', true, complete: false))
        .append(eat('e3', 'estimate'));
    expect(report(ledger).toJson()['estimated'], true);
    expect(report(ledger).value, isNull);
    expect(report(ledger).knownSubtotal, 15);
    final loaded = NutritionLedger.fromJson(ledger.toJson());
    expect(report(loaded).toJson(), report(ledger).toJson());
  });
}
