import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/look.dart';
import 'package:tabkha_demo/l10n/l10n.dart';
import 'package:tabkha_demo/main.dart';
import 'package:tabkha_demo/ui/brand_logo.dart';

import 'support/demo_flow.dart';

Finder _logo(String path) => find.byKey(ValueKey('brand-logo:$path'));

void main() {
  tearDown(() => SofraLook.notifier.value = const SofraLook());

  test('every logo bitmap exists at 1x, 2x and 3x', () {
    for (final english in [false, true]) {
      for (final dark in [false, true]) {
        final path = SofraLogo.asset(english: english, dark: dark);
        final name = path.split('/').last;
        for (final dir in ['', '2.0x/', '3.0x/']) {
          expect(
            File('assets/brand/$dir$name').existsSync(),
            isTrue,
            reason: '$dir$name',
          );
        }
      }
    }
  });

  for (final language in AppLanguage.values) {
    for (final appearance in [Appearance.light, Appearance.dark]) {
      testWidgets('the logo follows ${language.name}, ${appearance.name}', (
        tester,
      ) async {
        SofraLook.notifier.value = SofraLook(
          language: language,
          appearance: appearance,
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: language.locale,
            supportedLocales: L10n.supportedLocales,
            localizationsDelegates: L10n.delegates,
            home: const LookRoot(child: Scaffold(body: SofraLogo())),
          ),
        );
        await tester.pump();
        final path = SofraLogo.asset(
          english: language == AppLanguage.en,
          dark: appearance == Appearance.dark,
        );
        expect(_logo(path), findsOneWidget);
        // Read aloud as the app's name, not as an image file.
        expect(
          find.bySemanticsLabel(L10n.of(language).appTitle),
          findsOneWidget,
        );
      });
    }
  }

  Future<void> pumpApp(WidgetTester tester) async {
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
  }

  testWidgets('the welcome and the home header carry the logo, ar then en', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(_logo('assets/brand/logo-ar.png'), findsOneWidget);
    // The old fork-and-knife beside the name is gone.
    expect(find.byIcon(Icons.restaurant_rounded), findsNothing);

    await tapKey(tester, 'lang-en');
    expect(_logo('assets/brand/logo-en.png'), findsOneWidget);
    expect(_logo('assets/brand/logo-ar.png'), findsNothing);

    await completeOnboarding(tester);
    expect(_logo('assets/brand/logo-en.png'), findsOneWidget);
  });

  testWidgets('a dark phone shows the dark logo', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(_logo('assets/brand/logo-ar-dark.png'), findsOneWidget);
    await completeOnboarding(tester);
    expect(_logo('assets/brand/logo-ar-dark.png'), findsOneWidget);
  });
}
