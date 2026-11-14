import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/features/today_screen.dart';
import 'package:tabkha_demo/features/daily_home_screen.dart';
import 'package:tabkha_demo/app/scope.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/main.dart';

import 'support/demo_flow.dart';
import 'recipe_variants_test.dart' as fixtures;

void main() {
  testWidgets('native destinations and explicit kitchen entry', (tester) async {
    await tester.pumpWidget(
      TabkhaApp(
        recipes: await warmRecipes(tester),
        readAsset: await warmAssets(tester),
        showScene: false,
      ),
    );
    await tester.pumpAndSettle();
    await completeOnboarding(tester);
    for (final destination in ['today', 'recipes', 'stock', 'table']) {
      expect(find.byKey(ValueKey('nav-$destination')), findsOneWidget);
    }
    expect(find.byType(TodayScreen), findsNothing);
    await tapKey(tester, 'discover-from-stock');
    expect(find.byKey(const ValueKey('recipe-search')), findsOneWidget);
    await tapKey(tester, 'nav-recipes');
    expect(find.byKey(const ValueKey('recipe-search')), findsOneWidget);
    expect(find.byType(TodayScreen), findsNothing);
    await tester.tap(find.text('الكل'));
    await tester.enterText(find.byKey(const ValueKey('recipe-search')), 'كشري');
    await tester.pumpAndSettle();
    await tapKey(tester, 'recipe-eg-koshari');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('recipe-search')))
          .controller!
          .text,
      'كشري',
    );
    await tapKey(tester, 'nav-stock');
    await tapKey(tester, 'open-kitchen-3d');
    expect(find.byType(TodayScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsNothing);
    expect(find.byKey(const ValueKey('open-kitchen-3d')), findsOneWidget);
    await tapKey(tester, 'nav-table');
    expect(find.byKey(const ValueKey('open-month-plan')), findsOneWidget);
    expect(find.byKey(const ValueKey('open-shopping')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('uncertain stock matches appear only in from-stock discovery', (
    tester,
  ) async {
    await tester.pumpWidget(
      TabkhaApp(
        recipes: fixtures.repository(),
        readAsset: await warmAssets(tester),
        showScene: false,
      ),
    );
    await tester.pumpAndSettle();
    await completeOnboarding(tester);
    final controller = SofraScope.controllerOf(
      tester.element(find.byType(DailyHomeScreen)),
    );
    await controller.kitchen.addStock(
      InventoryLot(
        id: 'lot',
        ingredientId: 'sample',
        quantity: 2,
        unit: 'count',
        zone: StorageZone.pantry,
      ),
      newPurchase: false,
    );
    await tapKey(tester, 'discover-from-stock');
    expect(find.byKey(const ValueKey('recipe-fixture')), findsOneWidget);
    expect(find.textContaining('غير محسومة'), findsWidgets);
    await tester.tap(find.text('جاهزة بالموجود'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recipe-fixture')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cook now skips the planner and only consumes after confirmation',
    (tester) async {
      await tester.pumpWidget(
        TabkhaApp(
          recipes: fixtures.repository(),
          readAsset: await warmAssets(tester),
          showScene: false,
        ),
      );
      await tester.pumpAndSettle();
      await completeOnboarding(tester);
      final controller = SofraScope.controllerOf(
        tester.element(find.byType(DailyHomeScreen)),
      );
      await controller.kitchen.addStock(
        InventoryLot(
          id: 'lot',
          ingredientId: 'sample',
          quantity: 400,
          unit: 'g',
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
      await tapKey(tester, 'discover-from-stock');
      expect(find.text('جاهزة بالموجود'), findsWidgets);
      await tapKey(tester, 'recipe-fixture');
      await tapKey(tester, 'cook-slot-dinner');
      await tapKey(tester, 'cook-now');
      expect(find.byKey(const ValueKey('plan-confirm')), findsNothing);
      expect(controller.kitchen.plans, hasLength(1));
      expect(controller.kitchen.plans.single.slot, 'dinner');
      expect(controller.kitchen.inventory.single.quantity, 400);
      await tapKey(tester, 'finish-cooking');
      expect(controller.kitchen.inventory.single.quantity, 400);
      await tapKey(tester, 'confirm-cooking');
      expect(find.byKey(const ValueKey('cooking-success')), findsOneWidget);
      expect(controller.kitchen.inventory.single.quantity, 0);
      expect(controller.kitchen.plans.single.completed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
