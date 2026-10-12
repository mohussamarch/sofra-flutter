import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> completeOnboarding(WidgetTester tester) async {
  await tapKey(tester, 'onboarding-next');
  await tester.enterText(find.byKey(const ValueKey('field-name')), 'مريم');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
  for (var i = 0; i < 5; i++) {
    await tapKey(tester, 'onboarding-next');
  }
  expect(find.byKey(const ValueKey('nav-today')), findsOneWidget);
}

String stockQuantity(WidgetTester tester, String id) =>
    tester.widget<Text>(find.byKey(ValueKey('stock-quantity-$id'))).data!;

Future<void> exerciseDemoFlow(WidgetTester tester) async {
  await completeOnboarding(tester);
  await tapKey(tester, 'nav-fridge');
  await tapKey(tester, 'add-sample-stock');
  final riceBefore = stockQuantity(tester, 'rice');
  expect(riceBefore, contains('500'));
  await tapKey(tester, 'nav-recipes');
  await tapKey(tester, 'recipe-chicken-rice');
  expect(find.textContaining('200'), findsWidgets);
  await tapKey(tester, 'plan-meal');

  // Planning reserves no inventory. Switching tabs must preserve the plan.
  await tapKey(tester, 'nav-fridge');
  expect(stockQuantity(tester, 'rice'), riceBefore);
  await tapKey(tester, 'open-home-settings');
  expect(find.textContaining('مريم'), findsWidgets);
  await tapKey(tester, 'nav-table');
  await tapKey(tester, 'simulate-shopping');
  await tapKey(tester, 'start-cooking');
  for (var i = 0; i < 3; i++) {
    await tapKey(tester, 'next-cooking-step');
  }
  await tapKey(tester, 'finish-cooking');
  expect(find.byKey(const ValueKey('cooking-success')), findsOneWidget);
  await tapKey(tester, 'nav-fridge');
  expect(stockQuantity(tester, 'rice'), contains('100'));
}
