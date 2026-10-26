import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/main.dart';

import 'support/demo_flow.dart';

void main() {
  testWidgets('a recipe the user writes lands in the book and on the table', (
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
    await tapKey(tester, 'my-recipe-new');

    Future<void> type(String key, String text) async {
      await tester.enterText(find.byKey(ValueKey(key)), text);
      await tester.pumpAndSettle();
    }

    await type('my-recipe-name', 'رز بالشعرية بتاعنا');
    await type('my-recipe-description', 'زي البيت');
    await type('my-recipe-prep', '5');
    await type('my-recipe-cook', '20');
    await tester.tap(find.text('+ مكوّن'));
    await tester.pumpAndSettle();
    await type('my-recipe-ingredient-search', 'رز');
    await tapKey(tester, 'my-recipe-pick-rice');
    await type('my-recipe-amount', '200');
    await type('my-recipe-step-0', 'حمّر الشعرية وضيف الرز وسيبه يستوي');
    await type('my-recipe-step-minutes-0', '25');
    await tapKey(tester, 'my-recipe-save');
    expect(find.byKey(const ValueKey('my-recipe-name')), findsNothing);

    await tapKeyPrefix(tester, 'my-recipe-personal');
    await tapKey(tester, 'my-recipe-plan');
    await tapKey(tester, 'nav-table');
    expect(find.textContaining('رز بالشعرية بتاعنا'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
