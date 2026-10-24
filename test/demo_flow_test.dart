import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/main.dart';
import 'package:tabkha_demo/ui/design.dart';

import 'support/demo_flow.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Tajawal');
    for (final weight in ['Regular', 'Medium', 'Bold', 'ExtraBold']) {
      font.addFont(rootBundle.load('assets/fonts/Tajawal-$weight.ttf'));
    }
    await font.load();
  });

  for (final size in const [Size(360, 800), Size(390, 844), Size(430, 932)]) {
    testWidgets('onboarding and cooking at ${size.width} x ${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(TabkhaApp(
          recipes: await warmRecipes(tester),
          readAsset: await warmAssets(tester),
        ));
      await tester.pumpAndSettle();
      await exerciseDemoFlow(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('required name, keyboard and enlarged text remain usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(TabkhaApp(
          recipes: await warmRecipes(tester),
          readAsset: await warmAssets(tester),
        ));
    await tester.pumpAndSettle();
    await tapKey(tester, 'onboarding-next');
    DepthButton nextButton() => tester.widget<DepthButton>(
      find.byKey(const ValueKey('onboarding-next')),
    );
    expect(nextButton().onPressed, isNull);
    await tester.enterText(find.byKey(const ValueKey('field-name')), '   ');
    await tester.pumpAndSettle();
    expect(nextButton().onPressed, isNull);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.enterText(find.byKey(const ValueKey('field-name')), 'مريم');
    await tester.pumpAndSettle();
    expect(nextButton().onPressed, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tapKey(tester, 'onboarding-next');
    }
    for (final tab in ['fridge', 'recipes', 'table', 'today']) {
      await tapKey(tester, 'nav-$tab');
    }
    expect(tester.takeException(), isNull);
  });
}
