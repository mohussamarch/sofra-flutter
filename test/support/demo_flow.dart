import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';

Future<void> tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  expect(target, findsOneWidget, reason: key);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

/// Taps the single widget whose ValueKey string starts with [prefix].
Future<void> tapKeyPrefix(WidgetTester tester, String prefix) async {
  final target = find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith(prefix),
  );
  expect(target, findsOneWidget, reason: prefix);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

/// Catalog files read from disk outside fake async. The repository is built
/// here so its futures belong to the test zone and complete on pump; futures
/// completed inside runAsync never resume under fake time.
Future<RecipeRepository> warmRecipes(WidgetTester tester) async {
  final files = (await tester.runAsync(() async {
    final dir = Directory('recipes/data');
    return {
      for (final f in dir.listSync().whereType<File>())
        if (f.path.endsWith('.json'))
          'recipes/data/${f.uri.pathSegments.last}': await f.readAsString(),
    };
  }))!;
  return RecipeRepository(read: (path) async => files[path]!);
}

/// Ingredient directory files read from disk, served inside the test zone.
Future<Future<String> Function(String)> warmAssets(WidgetTester tester) async {
  final files = (await tester.runAsync(() async {
    return {
      for (final name in ['vocabulary.json', 'directory.json'])
        'data/ingredients/$name': await File('data/ingredients/$name')
            .readAsString(),
      for (final path in [
        'assets/community/creators.json',
        'assets/recipe-photos/manifest.json',
      ])
        path: await File(path).readAsString(),
    };
  }))!;
  return (path) async => files[path]!;
}

/// Back to the home kitchen: a page's back arrow, or the open tab again.
Future<void> goHome(WidgetTester tester) async {
  for (final key in ['page-back', 'nav-active']) {
    if (find.byKey(ValueKey(key)).evaluate().isNotEmpty) {
      await tapKey(tester, key);
      return;
    }
  }
}

/// Back to the home kitchen, then one of its corner circles.
Future<void> openCorner(WidgetTester tester, String circle) async {
  await goHome(tester);
  await tapKey(tester, 'circle-$circle');
}

/// The stock page, through the kitchen (no render in tests, so its stand-in).
Future<void> openStock(WidgetTester tester) async {
  await goHome(tester);
  await tapKey(tester, 'open-stock');
}

Future<void> completeOnboarding(WidgetTester tester) async {
  await tapKey(tester, 'onboarding-next');
  await tester.enterText(find.byKey(const ValueKey('field-name')), 'مريم');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
  for (var i = 0; i < 5; i++) {
    await tapKey(tester, 'onboarding-next');
  }
  expect(find.byKey(const ValueKey('nav-recipes')), findsOneWidget);
}

String stockQuantity(WidgetTester tester, String id) =>
    tester.widget<Text>(find.byKey(ValueKey('stock-quantity-$id'))).data!;

/// Onboarding → sample stock → one more onion → plan koshari → cook. Koshari
/// needs 3 onions (count, unscaled); other lines are missing, in different
/// units or unmeasured, so only the onions are deducted.
Future<void> exerciseDemoFlow(WidgetTester tester) async {
  await completeOnboarding(tester);
  await openStock(tester);
  await tapKey(tester, 'add-sample-stock');
  expect(stockQuantity(tester, 'rice'), contains('500'));
  expect(stockQuantity(tester, 'onion'), contains('2'));
  await tapKey(tester, 'add-ingredients');
  await tapKey(tester, 'add-stock-onion');
  await tapKey(tester, 'add-stock-open-rice');
  await tester.enterText(find.byKey(const ValueKey('add-amount')), '250');
  await tapKey(tester, 'add-unit-g');
  await tapKey(tester, 'add-stock-save');
  await tapKey(tester, 'add-stock-done');
  await tapKey(tester, 'nav-recipes');
  await tester.enterText(find.byKey(const ValueKey('recipe-search')), 'كشري');
  await tester.pumpAndSettle();
  await tapKey(tester, 'recipe-eg-koshari');
  expect(find.text('موجود عندك'), findsOneWidget);
  await tapKey(tester, 'plan-meal');
  await tapKey(tester, 'plan-confirm');

  // Planning reserves no inventory.
  await openStock(tester);
  expect(stockQuantity(tester, 'onion'), contains('3'));
  await openCorner(tester, 'profile');
  expect(find.textContaining('مريم'), findsWidgets);
  await tapKey(tester, 'nav-table');
  await tapKeyPrefix(tester, 'start-cooking-');
  while (find
      .byKey(const ValueKey('next-cooking-step'))
      .evaluate()
      .isNotEmpty) {
    await tapKey(tester, 'next-cooking-step');
  }
  await tapKey(tester, 'finish-cooking');
  expect(find.text('هيتخصم'), findsOneWidget);
  expect(find.text('مش هيتخصم'), findsOneWidget);
  await tapKey(tester, 'confirm-cooking');
  expect(find.byKey(const ValueKey('cooking-success')), findsOneWidget);
  // One and a half servings are left and go to the fridge.
  await tapKey(tester, 'leftover-more');
  await tapKey(tester, 'leftover-more');
  await tapKey(tester, 'leftover-more');
  await tapKey(tester, 'leftover-less');
  expect(find.text('1 حصة'), findsOneWidget);
  await tapKey(tester, 'save-leftovers');
  expect(find.byKey(const ValueKey('leftovers-saved')), findsOneWidget);
  await tapKey(tester, 'after-cooking-kitchen');
  expect(find.byKey(const ValueKey('stock-quantity-onion')), findsNothing);
  expect(stockQuantity(tester, 'rice'), contains('750'));
}
