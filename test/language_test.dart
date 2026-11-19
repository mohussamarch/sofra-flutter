import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/look.dart';
import 'package:tabkha_demo/app/sofra_controller.dart';
import 'package:tabkha_demo/l10n/l10n.dart';
import 'package:tabkha_demo/main.dart';

import 'support/demo_flow.dart';

void main() {
  tearDown(() => SofraLook.notifier.value = const SofraLook());

  test('the language is saved with the profile and read back', () {
    const english = Profile(language: AppLanguage.en);
    expect(english.toJson()['language'], 'en');
    final back = Profile.fromRoot(english.toJson());
    expect(back.language, AppLanguage.en);
    expect(back.look.language, AppLanguage.en);
    expect(back.copyWith(textStep: 1).language, AppLanguage.en);
    expect(Profile.fromRoot(const Profile().toJson()).language, AppLanguage.ar);
    // Documents saved before the language existed, or with an unknown one,
    // stay Arabic.
    expect(Profile.fromRoot(const {}).language, AppLanguage.ar);
    expect(Profile.fromRoot(const {'language': 'fr'}).language, AppLanguage.ar);
  });

  test('strings follow the published language, digits stay Latin', () {
    expect(L10n.current.langToggle, 'English');
    SofraLook.notifier.value = const SofraLook(language: AppLanguage.en);
    expect(L10n.isEnglish, isTrue);
    expect(L10n.current.langToggle, 'العربية');
    expect(L10n.pick('كشري', 'Koshari'), 'Koshari');
    expect(L10n.pick('كشري', null), 'كشري');
    SofraLook.notifier.value = const SofraLook();
    expect(L10n.pick('كشري', 'Koshari'), 'كشري');
    for (final language in AppLanguage.values) {
      final t = L10n.of(language);
      expect(RegExp(r'[٠-٩۰-۹]').hasMatch(t.appTitle), isFalse);
    }
  });

  testWidgets('the setup pill switches to English and left to right', (
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
    TextDirection direction() => Directionality.of(
      tester.element(find.byKey(const ValueKey('onboarding-next'))),
    );
    expect(direction(), TextDirection.rtl);
    expect(find.text('English'), findsOneWidget);

    await tapKey(tester, 'lang-toggle');
    expect(direction(), TextDirection.ltr);
    expect(find.text('العربية'), findsOneWidget);
    final material = MaterialLocalizations.of(
      tester.element(find.byKey(const ValueKey('onboarding-next'))),
    );
    expect(material.backButtonTooltip, 'Back');

    // And back.
    await tapKey(tester, 'lang-toggle');
    expect(direction(), TextDirection.rtl);
  });

  testWidgets(
    'in English, setup and the main tabs read English, left to right',
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
      final en = L10n.of(AppLanguage.en);
      final ar = L10n.of(AppLanguage.ar);

      await tapKey(tester, 'lang-toggle');
      expect(find.text(en.onbWelcomeTitle), findsOneWidget);
      expect(find.text(en.onbStart), findsOneWidget);
      expect(find.text(en.onbEgypt), findsOneWidget);

      await completeOnboarding(tester);
      expect(
        Directionality.of(
          tester.element(find.byKey(const ValueKey('nav-recipes'))),
        ),
        TextDirection.ltr,
      );
      for (final label in [en.appTabToday, en.appTabRecipes]) {
        expect(find.text(label), findsWidgets, reason: label);
      }

      // Each main tab: no UI string from the Arabic table is on screen
      // (recipe names without English data and the typed name may be).
      final arabicUi = {
        for (final s in [
          ar.appTabToday,
          ar.appTabRecipes,
          ar.appTabStock,
          ar.appTabPlan,
          ar.appTabSettings,
          ar.appCommunity,
        ])
          s,
      };
      for (final tab in ['recipes', 'today', 'kitchen', 'table']) {
        if (find.byKey(ValueKey('nav-$tab')).evaluate().isEmpty) continue;
        await tapKey(tester, 'nav-$tab');
        expect(
          Directionality.of(tester.element(find.byKey(ValueKey('nav-$tab')))),
          TextDirection.ltr,
        );
        for (final s in arabicUi) {
          expect(find.text(s), findsNothing, reason: '«$s» on $tab');
        }
      }
      await tapKey(tester, 'nav-recipes');
      expect(find.text(en.appTabRecipes), findsWidgets);

      // Back to Arabic from settings.
      await tapKey(tester, 'circle-settings');
      await tapKey(tester, 'look-lang-ar');
      expect(
        Directionality.of(
          tester.element(find.byKey(const ValueKey('look-lang-en'))),
        ),
        TextDirection.rtl,
      );
      expect(find.text(ar.lookLanguage), findsOneWidget);
    },
  );
}
