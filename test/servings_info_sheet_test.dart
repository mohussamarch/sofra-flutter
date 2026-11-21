import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/main.dart';

import 'support/demo_flow.dart';

// Arabic below is stored recipe data and the app's Arabic copy, as shown.
void main() {
  testWidgets(
    'a computed yield: the tag, its (i) sheet with the basis, and adjusting it',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        TabkhaApp(
          recipes: await warmRecipes(tester),
          readAsset: await warmAssets(tester),
          showScene: false,
        ),
      );
      await tester.pumpAndSettle();
      await completeOnboarding(tester);
      await tapKey(tester, 'nav-recipes');
      await tester.enterText(
        find.byKey(const ValueKey('recipe-search')),
        'بيلاف يوناني',
      );
      await tester.pumpAndSettle();
      // Greek pilaf: a side dish whose source states no yield; 300 g rice at
      // a side portion (75 g) feeds 4.
      await tapKey(tester, 'recipe-fiw650-52264');
      expect(find.text('تكفي 4 أفراد'), findsOneWidget);
      expect(find.byKey(const ValueKey('cook-now')), findsOneWidget);

      await tapKey(tester, 'servings-info');
      final basis = tester.widget<Text>(
        find.byKey(const ValueKey('servings-basis')),
      );
      expect(basis.data, contains('300'));
      expect(basis.data, contains('75'));
      expect(basis.data, isNot(contains('،  ')));
      final sheet = find.byType(BottomSheet);
      final apply = find.descendant(
        of: sheet,
        matching: find.byKey(const ValueKey('servings-adjust')),
      );
      expect(
        find.descendant(of: apply, matching: find.text('تطبيق')),
        findsOneWidget,
      );
      // Unchanged: tapping apply does nothing.
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.tap(
        find.descendant(of: sheet, matching: find.byIcon(Icons.add_rounded)),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: sheet, matching: find.byIcon(Icons.add_rounded)),
      );
      await tester.pumpAndSettle();
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BottomSheet), findsNothing);
      // The user's number now drives the recipe.
      expect(find.text('تكفي 6 أفراد'), findsOneWidget);
    },
  );

  testWidgets(
    'several drivers: own amounts, estimates marked, a shared plate',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        TabkhaApp(
          recipes: await warmRecipes(tester),
          readAsset: await warmAssets(tester),
          showScene: false,
        ),
      );
      await tester.pumpAndSettle();
      await completeOnboarding(tester);
      await tapKey(tester, 'nav-recipes');
      await tester.enterText(
        find.byKey(const ValueKey('recipe-search')),
        'ملفوف محشي هنغاري',
      );
      await tester.pumpAndSettle();
      // Hungarian stuffed cabbage: 1 lb mince and one large head of cabbage.
      await tapKey(tester, 'recipe-fiw650-52303');
      // The counter's hint ties the household number to the recipe's.
      final hint = tester.widget<Text>(
        find.byKey(const ValueKey('servings-scaled')),
      );
      expect(hint.data, contains('6'));
      // "Not stated by the source" is not shown next to the yield.
      expect(find.text('غير محدد بالمصدر'), findsNothing);

      await tapKey(tester, 'servings-info');
      final basis = tester
          .widget<Text>(find.byKey(const ValueKey('servings-basis')))
          .data!;
      expect(basis, contains('454'));
      expect(basis, isNot(contains('455')));
      // The head of cabbage keeps the recipe's own "1"; its weight is marked
      // as an estimate.
      expect(basis, contains('نحو'));
      expect(basis, contains('يأخذ كل فرد جزءًا'));
      expect(tester.takeException(), isNull);
    },
  );
}
