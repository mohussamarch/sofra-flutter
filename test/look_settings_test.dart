import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/look.dart';
import 'package:tabkha_demo/app/sofra_controller.dart';
import 'package:tabkha_demo/main.dart';
import 'package:tabkha_demo/ui/design.dart';

import 'support/demo_flow.dart';

List<double> _apply(List<double> m, List<double> rgb) => [
  for (var i = 0; i < 3; i++)
    m[i * 5] * rgb[0] + m[i * 5 + 1] * rgb[1] + m[i * 5 + 2] * rgb[2],
];

void main() {
  test('the look is saved with the profile and read back', () {
    const p = Profile(
      appearance: Appearance.dark,
      textStep: 2,
      colorVision: ColorVision.deutan,
      reduceMotion: true,
    );
    final back = Profile.fromRoot(p.toJson());
    expect(back.look, p.look);
    expect(back.look.textScale, 1.3);
    // Older documents have none of it.
    expect(Profile.fromRoot(const {}).look, const SofraLook());
    expect(
      Profile.fromRoot(const {'textStep': 9, 'appearance': 'x'}).look,
      const SofraLook(textStep: 2),
    );
  });

  test('colour correction keeps greys and moves what the eye mixes up', () {
    expect(colorCorrection(ColorVision.none), isNull);
    for (final v in ColorVision.values.skip(1)) {
      final m = colorCorrection(v)!;
      expect(m.length, 20);
      for (final grey in [0.0, .5, 1.0]) {
        for (final c in _apply(m, [grey, grey, grey])) {
          expect(c, closeTo(grey, .02), reason: '$v keeps grey $grey');
        }
      }
      final red = _apply(m, [1, 0, 0]);
      final green = _apply(m, [0, 1, 0]);
      expect(red, isNot(equals([1, 0, 0])), reason: '$v shifts pure red');
      expect(green, isNot(equals([0, 1, 0])), reason: '$v shifts green');
    }
  });

  testWidgets('settings change the appearance, text size, colours and motion', (
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
    await tapKey(tester, 'circle-settings');
    expect(Sofra.isDark, isFalse);

    await tapKey(tester, 'look-appearance-dark');
    expect(Sofra.isDark, isTrue);
    final context = tester.element(find.byKey(const ValueKey('look-motion')));
    expect(Theme.of(context).brightness, Brightness.dark);

    // The largest text still fits the settings page.
    await tapKey(tester, 'look-text-2');
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.byKey(const ValueKey('look-motion'))),
      ).scale(10),
      closeTo(13, .01),
    );

    expect(find.byType(ColorFiltered), findsNothing);
    await tapKey(tester, 'look-vision');
    await tapKey(tester, 'look-vision-deutan');
    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(find.text('الأخضر'), findsOneWidget);

    await tapKey(tester, 'look-motion');
    expect(
      MediaQuery.disableAnimationsOf(
        tester.element(find.byKey(const ValueKey('look-motion'))),
      ),
      isTrue,
    );

    // Every main screen still lays out in the dark at the largest text.
    await tapKey(tester, 'page-back');
    for (final tab in ['nav-recipes', 'nav-table', 'nav-today']) {
      if (find.byKey(ValueKey(tab)).evaluate().isEmpty) continue;
      await tapKey(tester, tab);
    }

    await tapKey(tester, 'circle-settings');
    await tapKey(tester, 'look-appearance-light');
    expect(Sofra.isDark, isFalse);
    await tapKey(tester, 'look-text-0');
    await tapKey(tester, 'look-vision');
    await tapKey(tester, 'look-vision-none');
    expect(find.byType(ColorFiltered), findsNothing);
  });
}
