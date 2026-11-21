import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tabkha_demo/app/scope.dart';
import 'package:tabkha_demo/app/sofra_controller.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/features/kitchen_screen.dart';
import 'package:tabkha_demo/features/month_plan_screen.dart';
import 'package:tabkha_demo/features/shopping_sheet.dart';
import 'package:tabkha_demo/l10n/l10n.dart';

import 'recipe_variants_test.dart' as f;
import 'sofra_controller_test.dart' show threeLines;

class _Nav implements SofraNav {
  final notes = <String>[];
  @override
  void notify(String text) => notes.add(text);
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

Future<SofraController> _controller() async {
  final c = SofraController(
    store: f.Store(),
    recipes: f.repository(value: threeLines()),
    readAsset: (path) => File(path).readAsString(),
  );
  await c.load();
  return c;
}

Widget _host(SofraController c, _Nav nav, Widget child) => MaterialApp(
  locale: const Locale('ar'),
  supportedLocales: L10n.supportedLocales,
  localizationsDelegates: L10n.delegates,
  home: SofraScope(
    controller: c,
    nav: nav,
    child: Scaffold(body: child),
  ),
);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('the month budget field starts with the saved budget', (
    tester,
  ) async {
    final c = await tester.runAsync(_controller) as SofraController;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    await tester.runAsync(
      () => c.kitchen.saveBudget(
        BudgetPeriod(
          id: 'budget-${localDay(start).substring(0, 7)}',
          start: localDay(start),
          end: localDay(DateTime(now.year, now.month + 1)),
          limit: 4200,
          country: c.kitchen.market.country,
        ),
      ),
    );
    expect(c.savedMonthLimit(now), 4200);
    expect(c.savedMonthLimit(DateTime(now.year + 5, 1)), isNull);
    await tester.pumpWidget(_host(c, _Nav(), const MonthPlanScreen()));
    await tester.pump();
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('month-budget')),
    );
    expect(field.controller!.text, '4200');
  });

  testWidgets('the stock quantity dialog has an explicit delete action', (
    tester,
  ) async {
    final c = await tester.runAsync(_controller) as SofraController;
    await tester.runAsync(
      () => c.kitchen.addStock(
        InventoryLot(
          id: 'lot-a',
          ingredientId: 'sample',
          quantity: 500,
          unit: 'g',
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      ),
    );
    final nav = _Nav();
    late BuildContext ctx;
    await tester.pumpWidget(
      _host(
        c,
        nav,
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );
    final lot = c.kitchen.inventory.single;
    unawaited(editStockQuantity(ctx, lot));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('stock-delete')));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(c.kitchen.inventory.single.quantity, 0);
    expect(nav.notes, isNotEmpty);
  });

  test('missing nutrition is counted per distinct ingredient', () {
    final result = RecipeNutritionResult(
      recipeId: 'r',
      recipeVersion: '1',
      portions: 2,
      whole: {
        NutrientId.energyKcal: NutrientTotal(
          nutrient: NutrientId.energyKcal,
          knownSubtotal: 100,
          missing: [
            NutrientGap('a', NutrientGapReason.values.first),
            NutrientGap('b', NutrientGapReason.values.first),
            NutrientGap('a', NutrientGapReason.values.first),
          ],
        ),
      },
      snapshot: const [],
    );
    expect(SofraController.missingNutritionIngredients(result), 2);
    expect(
      SofraController.missingNutritionIngredients(
        RecipeNutritionResult(
          recipeId: 'r',
          recipeVersion: '1',
          portions: 1,
          whole: const {},
          snapshot: const [],
        ),
      ),
      0,
    );
  });

  testWidgets('shopping ticks survive closing the sheet', (tester) async {
    final c = await tester.runAsync(_controller) as SofraController;
    final today = DateTime.now();
    await tester.runAsync(() async {
      await c.kitchen.plan(
        PlannedMeal(
          id: 'm1',
          date: localDay(today),
          slot: 'lunch',
          recipeId: 'fixture',
          servings: 2,
        ),
      );
    });
    final forecast = await tester.runAsync(() => c.shoppingList(today));
    final first = forecast!.purchases.first.use.ingredientId;
    Future<void> open() async {
      await tester.pumpWidget(_host(c, _Nav(), const ShoppingSheet()));
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
        if (find.byKey(ValueKey('shopping-$first')).evaluate().isNotEmpty) {
          break;
        }
      }
    }

    await open();
    await tester.tap(find.byKey(ValueKey('shopping-$first')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    expect(
      await SharedPreferencesAsync().getStringList('sofra.shopping.bought'),
      [first],
    );
    await open();
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(ValueKey('shopping-$first')))
          .value,
      isTrue,
    );
  });
}
