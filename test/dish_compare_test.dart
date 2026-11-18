import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';
import 'package:tabkha_demo/features/dish_sheet.dart';
import 'package:tabkha_demo/features/recipe_detail_screen.dart';
import 'package:tabkha_demo/main.dart';

import 'support/demo_flow.dart';

void main() {
  test('compared ingredients: each once, with the ways that use it', () async {
    final repo = RecipeRepository(read: (p) => File(p).readAsString());
    final a = await repo.get('lv-shakshuka');
    final b = await repo.get('sa-shakshoka-hejazi');
    final lines = compareIngredients([a, b]);
    final ids = [for (final l in lines) l.id];
    expect(ids.toSet().length, ids.length, reason: 'no ingredient twice');
    expect(ids.toSet(), {
      ...a.ingredients.map((i) => i.id),
      ...b.ingredients.map((i) => i.id),
    });
    for (final l in lines) {
      expect(l.ways, [
        if (a.ingredients.any((i) => i.id == l.id)) 0,
        if (b.ingredients.any((i) => i.id == l.id)) 1,
      ]);
    }
    expect(
      lines.where((l) => l.ways.length == 2),
      isNotEmpty,
      reason: 'both shakshukas share eggs at least',
    );
  });

  test('Arabic counting and time ranges for dish cards', () {
    expect(countriesLabel(2), 'بلدان');
    expect(countriesLabel(4), '4 بلاد');
    expect(countriesLabel(12), '12 بلدًا');
    expect(
      dishTime([
        {'totalTime': 20},
        {'totalTime': 45},
      ]),
      '20–45 دقيقة',
    );
    expect(
      dishTime([
        {'totalTime': 30},
        {'totalTime': 30},
      ]),
      '30 دقيقة',
    );
    expect(
      dishTime([
        {'totalTime': 30},
        {'totalTime': null},
      ]),
      'الوقت غير محدد',
    );
  });

  testWidgets('a dish card opens its ways compared; a country opens its way', (
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
    await tapKey(tester, 'nav-recipes');
    await tester.enterText(
      find.byKey(const ValueKey('recipe-search')),
      'شكشوكة',
    );
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('dish-lv-shakshuka'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text('بلدان')),
      findsOneWidget,
    );
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();

    // No country chosen: one list, the bar, and a pointer to it.
    expect(find.byKey(const ValueKey('compare-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('country-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('compare-pick')), findsOneWidget);
    expect(find.byKey(const ValueKey('cook-now')), findsNothing);

    await tapKey(tester, 'way-sa-shakshoka-hejazi');
    expect(find.byKey(const ValueKey('compare-title')), findsNothing);
    expect(find.byKey(const ValueKey('cook-now')), findsOneWidget);
    expect(find.text('شكشوكة حجازية'), findsWidgets);

    // The chosen country again: back to comparing.
    await tapKey(tester, 'way-sa-shakshoka-hejazi');
    expect(find.byKey(const ValueKey('compare-title')), findsOneWidget);
  });
}
