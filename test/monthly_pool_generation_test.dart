import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/market_profile.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';
import 'package:tabkha_demo/domain/recipe_variants.dart';

import 'recipe_variants_test.dart' as f;
import 'purchase_forecast_integration_test.dart' as store;
import 'recipe_yield_review_test.dart' as yield_fixture;

BudgetPeriod month({String start = '2028-02-01', String end = '2028-03-01'}) =>
    BudgetPeriod(
      id: 'month',
      start: start,
      end: end,
      limit: 10000,
      country: MarketCountry.egypt,
    );
List<WeeklyRecipeSlot> template() => List.generate(
  7,
  (i) => WeeklyRecipeSlot(
    weekday: i + 1,
    slot: 'lunch',
    choices: [
      const RecipePoolChoice(id: 'one', recipeId: 'fixture', servings: 1),
      const RecipePoolChoice(id: 'two', recipeId: 'fixture', servings: 2),
    ],
  ),
);
void main() {
  Future<({KitchenService k, store.CountedStore s})> setup({
    bool unknown = false,
  }) async {
    final s = store.CountedStore();
    final k = KitchenService(
      s,
      f.repository(value: unknown ? yield_fixture.unknownYield() : f.recipe()),
    );
    await k.load();
    await k.saveBudget(month());
    return (k: k, s: s);
  }

  Future<MonthlyCandidatePools> generate(
    KitchenService k, {
    List<WeeklyRecipeSlot>? pattern,
    int maxPools = 31,
    int maxCandidates = 2,
    bool ack = true,
  }) => k.generateMonthlyCandidatePools(
    'month',
    weeklyTemplate: pattern ?? template(),
    requiredDailySlots: ['lunch'],
    maxPools: maxPools,
    maxCandidatesPerSlot: maxCandidates,
    acknowledgeRecipeEligibility: ack,
  );
  test('stored personal snapshot cannot bypass the concrete-cuisine rule for a new plan', () async {
    final (k: k, s: _) = await setup();
    final parent = await k.catalogRevision('fixture');
    final child = RecipeRevision(
      familyId: parent.familyId,
      revision: 'v1',
      kind: RecipeRevisionKind.personal,
      parentKey: parent.key,
      recipe: CatalogRecipe.fromJson({
        ...parent.recipe.toJson(),
        'id': 'unclassified-personal',
        'cuisine': 'غير محدد',
      }),
    );
    await k.saveRecipeRevision(child);
    await expectLater(
      k.plan(f.plan('blocked-plan', child.variantId)),
      throwsStateError,
    );
    expect(k.plans, isEmpty);
    expect(k.recipeBook.revisions[child.key], isNotNull);
  });
  test('expands an explicit weekly pattern across a leap month with exact pins and no writes', () async {
    final (k: k, s: s) = await setup();
    final before = jsonEncode(k.snapshot), saves = s.saves;
    final result = await generate(k);
    expect(result.pools, hasLength(29));
    expect(result.requiredSlots, hasLength(29));
    expect(result.requiredSlots.first.date, '2028-02-01');
    expect(result.requiredSlots.last.date, '2028-02-29');
    expect(result.pools.values.every((v) => v.length == 2), isTrue);
    expect(
      result.pools.values
          .expand((v) => v)
          .every((m) => m.recipeRevisionKey != null && !m.completed),
      isTrue,
    );
    expect(s.saves, saves);
    expect(jsonEncode(k.snapshot), before);
    final preview = await k.searchMonthlyBudgetChoices(
      'month',
      pools: result.pools,
      requiredSlots: result.requiredSlots,
      maxEvaluations: 1,
    );
    expect(preview.search.requiredCoverage!.coversRequired, isTrue);
    expect(preview.search.totalCombinations, BigInt.from(2).pow(29));
    expect(k.plans, isEmpty);
  });
  test('rejects missing weekdays, duplicate slots, missing acknowledgement and explicit caps', () async {
    final (k: k, s: _) = await setup();
    await expectLater(
      generate(k, pattern: template().sublist(1)),
      throwsArgumentError,
    );
    await expectLater(
      generate(k, pattern: [...template(), template().first]),
      throwsArgumentError,
    );
    await expectLater(generate(k, ack: false), throwsArgumentError);
    await expectLater(generate(k, maxPools: 28), throwsArgumentError);
    await expectLater(generate(k, maxCandidates: 1), throwsArgumentError);
    await expectLater(
      generate(
        k,
        pattern: [
          for (final t in template())
            WeeklyRecipeSlot(weekday: t.weekday, slot: t.slot, choices: []),
        ],
      ),
      throwsArgumentError,
    );
  });
  test('unknown yield cannot silently use four servings or generate priced candidates', () async {
    final (k: k, s: s) = await setup(unknown: true);
    final before = s.saves;
    await expectLater(generate(k), throwsArgumentError);
    expect(s.saves, before);
  });
  test('owns template inputs and immutable generated collections', () async {
    final (k: k, s: _) = await setup();
    final pattern = template();
    final pending = generate(k, pattern: pattern);
    pattern.clear();
    final result = await pending;
    expect(result.pools, hasLength(29));
    expect(() => result.pools.clear(), throwsUnsupportedError);
    expect(() => result.pools.values.first.clear(), throwsUnsupportedError);
    expect(() => result.requiredSlots.clear(), throwsUnsupportedError);
  });
  test('intervening queued write rejects generation rather than returning stale eligibility', () async {
    final (k: k, s: _) = await setup();
    final pending = generate(k);
    final checked = expectLater(pending, throwsStateError);
    await k.saveBudget(month());
    await checked;
  });
  test('requires exactly one whole saved calendar month', () async {
    final (k: k, s: _) = await setup();
    await k.saveBudget(month(start: '2028-02-02'));
    await expectLater(generate(k), throwsArgumentError);
  });
  test(
    'a generated unsaved catalog pin cannot silently resolve changed content',
    () async {
      final (k: k, s: _) = await setup();
      final generated = await generate(k);
      final changed = CatalogRecipe.fromJson({
        ...f.recipe().toJson(),
        'name': 'Changed synthetic source',
      });
      final second = KitchenService(
        store.CountedStore(),
        f.repository(value: changed),
      );
      await second.load();
      await second.saveBudget(month());
      await expectLater(
        second.searchMonthlyBudgetChoices(
          'month',
          pools: generated.pools,
          requiredSlots: generated.requiredSlots,
          maxEvaluations: 1,
        ),
        throwsStateError,
      );
      expect(second.plans, isEmpty);
    },
  );
  test(
    'an unresolved cuisine is never eligible merely because yield is known',
    () async {
      final value = CatalogRecipe.fromJson({
        ...f.recipe().toJson(),
        'cuisine': 'غير محدد',
      });
      final k = KitchenService(
        store.CountedStore(),
        f.repository(value: value),
      );
      await k.load();
      await k.saveBudget(month());
      await expectLater(generate(k), throwsStateError);
    },
  );
}
