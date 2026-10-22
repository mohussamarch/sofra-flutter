import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';
import 'package:tabkha_demo/data/state_store.dart';
import 'package:tabkha_demo/domain/cooking_timer.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/market_profile.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';

class MemoryStore implements StateStore {
  Map<String, dynamic>? data;
  bool fail = false;
  @override
  String get label => 'test';
  @override
  Future<Map<String, dynamic>?> load() async => data == null
      ? null
      : jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  @override
  Future<void> save(Map<String, dynamic> value) async {
    await Future<void>.delayed(Duration.zero);
    if (fail) throw StateError('save failed');
    data = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  RecipeRepository repository() =>
      RecipeRepository(read: (path) => File(path).readAsString());
  InventoryLot lot(
    String id,
    String ingredient,
    double? quantity,
    String unit,
  ) => InventoryLot(
    id: id,
    ingredientId: ingredient,
    quantity: quantity,
    unit: unit,
    zone: StorageZone.pantry,
  );
  final now = DateTime(2026, 10, 12, 10);

  test(
    'all catalog assets parse with known scaling and explicit unknown guards',
    () async {
      final repo = repository(), all = await repo.loadAll();
      expect(all.length, 657);
      expect(
        (await repo.search(cuisine: 'سعودي')).length,
        greaterThanOrEqualTo(14),
      );
      expect((await repo.search(query: 'كُشري')).single['id'], 'eg-koshari');
      expect(roundRecipeAmount(.25, 'كوب'), .25);
      expect(roundRecipeAmount(8, 'كوب'), 8);
      expect(roundRecipeAmount(1.25, 'لتر'), 1.25);
      for (final recipe in all) {
        if (!recipe.hasKnownYield) {
          expect(() => recipe.forServings(4), throwsArgumentError);
          continue;
        }
        for (final count in [1, 2, 8, 12]) {
          final scaled = recipe.forServings(count);
          if (recipe.hasCompleteSchedule) {
            if (recipe.hasCompleteSchedule) {
              if (recipe.hasCompleteSchedule) {
                if (recipe.hasCompleteSchedule) {
            expect(scaled.schedule.length, recipe.steps.length);
          } else {
            expect(() => scaled.schedule, throwsStateError);
          }
              } else {
                expect(() => scaled.schedule, throwsStateError);
              }
            } else {
              expect(() => scaled.schedule, throwsStateError);
            }
          } else {
            expect(() => scaled.schedule, throwsStateError);
          }
          for (final ingredient in recipe.ingredients) {
            final amount = scaled.quantity(ingredient);
            if (!ingredient.scales) expect(amount, ingredient.amount);
            if (amount != null) expect(amount.isFinite, isTrue);
          }
        }
      }
      expect(() => all.first.forServings(0), throwsArgumentError);
    },
  );

  test(
    'catalog uses bundled Flutter assets and caches cuisine files by name',
    () async {
      expect((await RecipeRepository().loadAll()).length, 657);
      final reads = <String, int>{};
      final repo = RecipeRepository(
        read: (path) {
          reads[path] = (reads[path] ?? 0) + 1;
          return File(path).readAsString();
        },
      );
      await Future.wait([repo.get('eg-koshari'), repo.get('eg-molokhia')]);
      expect(reads['recipes/data/egyptian.json'], 1);
      expect(reads['recipes/data/index.json'], 1);
    },
  );

  test(
    'package quantities and allocation never guess units or count weights',
    () {
      expect(StockPurchase(count: 2, content: 5, unit: 'kg').quantity, 10);
      final uses = [
        IngredientUse('rice', 600, 'g'),
        IngredientUse('rice', 600, 'g'),
      ];
      final stock = [lot('a', 'rice', 1, 'kg')];
      final result = assessStock(uses, stock);
      expect(result.canCook, isFalse);
      expect(result.missing.single.quantity, closeTo(200, 1e-9));
      expect(stock.single.quantity, 1);
      expect(
        assessStock([IngredientUse('rice', 1, 'كوب')], stock).canCook,
        isFalse,
      );
      expect(
        assessStock(
          [IngredientUse('apple', 100, 'g')],
          [lot('b', 'apple', 2, 'count')],
        ).canCook,
        isFalse,
      );
      expect(
        assessStock(
          [IngredientUse('rice', 1, 'g')],
          [lot('x', 'rice', null, 'g')],
        ).canCook,
        isFalse,
      );
      expect(
        assessStock(
          [IngredientUse('rice', 1, 'كوب')],
          stock,
          rules: [UnitRule('rice', 'كوب', 'g', 200)],
        ).after.single.quantity,
        .8,
      );
      expect(
        () => StockPurchase(count: 1, content: double.nan, unit: 'g'),
        throwsArgumentError,
      );
    },
  );

  test(
    'one male household, stable seats, calendar and failed-save rollback',
    () async {
      final store = MemoryStore(),
          service = KitchenService(store, repository());
      await service.load();
      await service.saveMember(
        HouseholdMember(
          id: 'self',
          name: 'علي',
          age: 30,
          gender: MemberGender.male,
          hijab: true,
        ),
      );
      expect(service.snapshot['members'][0]['hijab'], isFalse);
      expect(service.snapshot['seats'], ['self', null, null]);
      await service.swapSeats(0, 2);
      await service.saveMember(
        HouseholdMember(
          id: 'self',
          name: 'علي',
          age: 31,
          gender: MemberGender.male,
        ),
      );
      expect(service.snapshot['seats'], [null, null, 'self']);
      await service.plan(
        PlannedMeal(
          id: 'lunch',
          date: '2026-10-12',
          slot: 'lunch',
          recipeId: 'eg-koshari',
          servings: 1,
        ),
      );
      await service.plan(
        PlannedMeal(
          id: 'snack',
          date: '2026-10-13',
          slot: 'snack',
          recipeId: 'eg-koshari',
          servings: 1,
        ),
      );
      expect(service.inventory, isEmpty);
      expect(service.calendar(now, CalendarMode.day).length, 1);
      expect(service.calendar(now, CalendarMode.week).length, 2);
      expect(
        CalendarRange(DateTime(2026, 12, 31), CalendarMode.month).end,
        DateTime(2027, 1, 1),
      );
      expect(() => parseDay('2026-02-31'), throwsFormatException);
      store.fail = true;
      await expectLater(
        service.setCountry(MarketCountry.saudi),
        throwsStateError,
      );
      expect(service.market.country, MarketCountry.egypt);
      store.fail = false;
      await service.setCountry(MarketCountry.saudi);
      final restored = KitchenService(store, repository());
      await restored.load();
      expect(restored.market.country, MarketCountry.saudi);
      expect(restored.snapshot['seats'], [null, null, 'self']);
    },
  );

  test(
    'confirmed cooking is atomic, idempotent on retry/reload and freezes cost',
    () async {
      final store = MemoryStore(),
          repo = repository(),
          service = KitchenService(store, repo);
      await service.load();
      final recipe = (await repo.get('eg-koshari')).forServings(4);
      for (final ingredient in recipe.recipe.ingredients) {
        final amount = recipe.quantity(ingredient);
        if (amount == null || ingredient.optional) continue;
        await service.addStock(
          lot(ingredient.id, ingredient.id, amount, ingredient.unit!),
          newPurchase: false,
        );
        await service.savePrice(
          MarketPrice(
            country: MarketCountry.egypt,
            ingredientId: ingredient.id,
            unit: ingredient.unit!,
            quantity: amount,
            amount: 10,
            recordedAt: now,
            source: 'user',
          ),
          userOverride: true,
        );
      }
      await service.plan(
        PlannedMeal(
          id: 'meal',
          date: '2026-10-12',
          slot: 'lunch',
          recipeId: 'eg-koshari',
          servings: 4,
        ),
      );
      final before = jsonEncode(service.snapshot);
      await expectLater(
        service.confirmCooking('meal', 'cook'),
        throwsStateError,
      ); // salt needs acknowledgement
      expect(jsonEncode(service.snapshot), before);
      store.fail = true;
      await expectLater(
        service.confirmCooking('meal', 'cook', omitUnmeasured: {'salt'}),
        throwsStateError,
      );
      expect(jsonEncode(service.snapshot), before);
      store.fail = false;
      final results = await Future.wait([
        service.confirmCooking(
          'meal',
          'cook',
          omitUnmeasured: {'salt'},
          cookedAt: now,
        ),
        service.confirmCooking(
          'meal',
          'cook',
          omitUnmeasured: {'salt'},
          cookedAt: now,
        ),
      ]);
      expect(results[0]['cost'], results[1]['cost']);
      expect((service.snapshot['history'] as List).length, 1);
      expect(service.inventory.every((v) => v.quantity == 0), isTrue);
      expect(
        (service.snapshot['purchases'] as List),
        isEmpty,
      ); // consumption is not a new cash expense
      final frozen = results.first['cost'];
      await service.savePrice(
        MarketPrice(
          country: MarketCountry.egypt,
          ingredientId: 'rice',
          unit: 'كوب',
          quantity: 1,
          amount: 100,
          recordedAt: now,
          source: 'user',
        ),
        userOverride: true,
      );
      final restored = KitchenService(store, repo);
      await restored.load();
      expect((await restored.confirmCooking('meal', 'cook'))['cost'], frozen);
      await expectLater(
        restored.confirmCooking('meal', 'different'),
        throwsStateError,
      );
    },
  );

  test('purchase switch, override pricing, country isolation and no budget carryover', () async {
    final service = KitchenService(MemoryStore(), repository());
    await service.load();
    await service.addStock(lot('old', 'orange', 2, 'kg'), newPurchase: false);
    await service.addStock(
      lot('new', 'orange', 1, 'kg'),
      newPurchase: true,
      paid: 40,
      purchasedAt: now,
    );
    final average = MarketPrice(
      country: MarketCountry.egypt,
      ingredientId: 'orange',
      unit: 'kg',
      quantity: 1,
      amount: 50,
      recordedAt: now,
      source: 'average',
    );
    await service.savePrice(average, userOverride: false);
    expect(service.estimatedCost(IngredientUse('orange', 500, 'g')), 25);
    await service.savePrice(
      MarketPrice(
        country: MarketCountry.egypt,
        ingredientId: 'orange',
        unit: 'kg',
        quantity: 1,
        amount: 60,
        recordedAt: now,
        source: 'user',
      ),
      userOverride: true,
    );
    await service.savePrice(average, userOverride: false);
    expect(service.estimatedCost(IngredientUse('orange', 1, 'kg')), 60);
    await service.saveBudget(
      BudgetPeriod(
        id: 'oct',
        start: '2026-10-01',
        end: '2026-11-01',
        limit: 100,
        country: MarketCountry.egypt,
      ),
    );
    expect(service.budgetSummary('oct', plannedPurchases: 80).overrun, 20);
    expect(service.budgetSummary('oct').spent, 40);
    await service.saveBudget(
      BudgetPeriod(
        id: 'nov',
        start: '2026-11-01',
        end: '2026-12-01',
        limit: 100,
        country: MarketCountry.egypt,
      ),
    );
    expect(service.budgetSummary('nov').remaining, 100);
    await service.setCountry(MarketCountry.saudi);
    expect(service.estimatedCost(IngredientUse('orange', 1, 'kg')), isNull);
    expect(service.budgetSummary('oct').spent, 40);
  });

  test('wall-clock timer survives background and pause; outside-session waits are manual', () {
    final timer = CookingTimer(durations: [60, 120, 0, 30]).start(now);
    final restored = CookingTimer.fromJson(timer.toJson())
        .at(now.add(const Duration(seconds: 90)));
    expect(restored.step, 1);
    expect(restored.remaining, 90);
    final paused = restored.pause(now.add(const Duration(seconds: 100)));
    expect(paused.at(now.add(const Duration(hours: 1))).remaining, 80);
    final waiting = timer.at(now.add(const Duration(hours: 1)));
    expect(waiting.needsManualAdvance, isTrue);
    expect(waiting.finished, isFalse);
    expect(
      waiting.advance(now).at(now.add(const Duration(seconds: 31))).finished,
      isTrue,
    );
  });

  test(
    'legacy migration preserves unknown root fields and needs explicit units',
    () async {
      final store = MemoryStore()
        ..data = {
          'schema': 1,
          'name': 'علي',
          'custom': 'keep',
          'stock': [
            {'id': 'rice', 'quantity': 500, 'zone': 'pantry'},
          ],
        };
      await expectLater(
        KitchenService(store, repository()).load(),
        throwsStateError,
      );
      final service = KitchenService(
        store,
        repository(),
        legacyUnits: {'rice': 'g'},
      );
      await service.load();
      expect(service.inventory.single.quantity, 500);
      await service.setCountry(MarketCountry.saudi);
      expect(store.data!['custom'], 'keep');
      expect(store.data!['name'], 'علي');
    },
  );
  test('timer state persists without a tick while the app is closed', () async {
    final store = MemoryStore();
    final service = KitchenService(store, repository());
    await service.load();
    await service.saveTimer('meal', CookingTimer(durations: [120]).start(now));
    final restored = KitchenService(store, repository());
    await restored.load();
    expect(
      restored.timer('meal', now.add(const Duration(seconds: 75)))!.remaining,
      45,
    );
    expect(CookingTimer(durations: const []).finished, isTrue);
  });
  test(
    'Dart matches the real TypeScript library in all 216 reference cases',
    () async {
      final expected = jsonDecode(
        await File('test/fixtures/recipe-parity.json').readAsString(),
      ) as List;
      final repo = repository();
      for (final row in expected) {
        final scaled = (await repo.get(row['id'] as String))
            .forServings(row['servings'] as int);
        expect(
          scaled.totalMinutes,
          row['totalMinutes'],
          reason: '${row['id']} total',
        );
        final ingredients = row['ingredients'] as List;
        for (var i = 0; i < ingredients.length; i++) {
          final actual = scaled.recipe.ingredients[i],
              wanted = ingredients[i] as List;
          expect(actual.id, wanted[0]);
          expect(
            scaled.quantity(actual),
            wanted[1],
            reason: '${row['id']}/${actual.id}/${row['servings']} quantity',
          );
          expect(
            scaled.display(actual),
            wanted[2],
            reason: '${row['id']}/${actual.id}/${row['servings']} display',
          );
        }
        final schedule = scaled.schedule, steps = row['steps'] as List;
        for (var i = 0; i < steps.length; i++) {
          expect(schedule[i].start, steps[i][0]);
          expect(schedule[i].end, steps[i][1]);
        }
      }
    },
  );
}
