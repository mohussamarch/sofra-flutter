import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/main.dart';

import 'support/demo_flow.dart';

void main() {
  testWidgets('a weekly menu becomes a priced month on the table', (
    tester,
  ) async {
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
    await tapKey(tester, 'nav-table');
    await tapKey(tester, 'open-month-plan');

    await tester.enterText(find.byKey(const ValueKey('month-budget')), '50000');
    await tester.pumpAndSettle();
    await tapKey(tester, 'month-cell-6-lunch');
    await tester.enterText(
      find.byKey(const ValueKey('month-pick-search')),
      'كشري',
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'month-pick-eg-koshari');
    await tester.tap(find.text('أكمل الأيام الفارغة'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'month-calc');
    expect(find.byKey(const ValueKey('month-unknown')), findsOneWidget);

    // Every missing price is the user's own; each save recalculates.
    Finder rows() => find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('month-price-'),
    );
    expect(rows(), findsWidgets);
    for (var guard = 0; guard < 40 && rows().evaluate().isNotEmpty; guard++) {
      final row = rows().first;
      await tester.ensureVisible(row);
      await tester.enterText(
        find.descendant(
          of: row,
          matching: find.byKey(const ValueKey('price-amount')),
        ),
        '5',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: row,
          matching: find.byKey(const ValueKey('price-save')),
        ),
      );
      await tester.pumpAndSettle();
    }
    expect(rows(), findsNothing);
    expect(find.byKey(const ValueKey('month-fits')), findsOneWidget);
    await tapKey(tester, 'month-accept');
    expect(find.byKey(const ValueKey('month-budget')), findsNothing);
    expect(find.byKey(const ValueKey('open-month-plan')), findsOneWidget);
    expect(find.textContaining('كشري'), findsWidgets);

    // The week's shopping list comes from those meals, after the stock.
    await tapKey(tester, 'open-shopping');
    expect(find.byKey(const ValueKey('shopping-total')), findsOneWidget);
    final first = find.byWidgetPredicate(
      (w) =>
          w is CheckboxListTile &&
          (w.key! as ValueKey<String>).value.startsWith('shopping-'),
    );
    expect(first, findsWidgets);
    await tester.tap(first.first);
    await tester.pumpAndSettle();
    await tapKey(tester, 'shopping-bought');
    expect(find.byKey(const ValueKey('shopping-total')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
