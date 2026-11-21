import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/look.dart';
import 'package:tabkha_demo/l10n/l10n.dart';
import 'package:tabkha_demo/main.dart';
import 'package:tabkha_demo/ui/brand_logo.dart';
import 'package:tabkha_demo/ui/session_gate.dart';

import 'support/demo_flow.dart';

Finder _logo(String path) => find.byKey(ValueKey('brand-logo:$path'));

/// Width and height from a PNG's IHDR chunk.
(int, int) _pngSize(String path) {
  final b = File(path).readAsBytesSync();
  expect(b.sublist(1, 4), ascii.encode('PNG'), reason: path);
  final d = ByteData.sublistView(b);
  return (d.getUint32(16), d.getUint32(20));
}

/// PNG colour type: 2 is RGB, 6 is RGBA.
int _pngColourType(String path) => File(path).readAsBytesSync()[25];

const _android = 'android/app/src/main/res';
const _ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

void main() {
  tearDown(() => SofraLook.notifier.value = const SofraLook());

  test('every logo bitmap is drawn at 1x to 4x of the same box', () {
    for (final english in [false, true]) {
      for (final dark in [false, true]) {
        final path = SofraLogo.asset(english: english, dark: dark);
        final name = path.split('/').last;
        final (w1, h1) = _pngSize('assets/brand/$name');
        expect(h1, SofraLogo.maxHeight, reason: name);
        for (final (ratio, dir) in [(2, '2.0x/'), (3, '3.0x/'), (4, '4.0x/')]) {
          final file = 'assets/brand/$dir$name';
          expect(_pngSize(file), (w1 * ratio, h1 * ratio), reason: file);
          expect(_pngColourType(file), 6, reason: '$file keeps its alpha');
          // Not an empty canvas: a drawn wordmark compresses to kilobytes.
          expect(File(file).lengthSync(), greaterThan(2000), reason: file);
        }
      }
    }
  });

  test('Android launcher icons: every density, adaptive with themed layer', () {
    const scales = {
      'mdpi': 1.0,
      'hdpi': 1.5,
      'xhdpi': 2.0,
      'xxhdpi': 3.0,
      'xxxhdpi': 4.0,
    };
    scales.forEach((density, scale) {
      final dir = '$_android/mipmap-$density';
      final legacy = (48 * scale).round();
      final layer = (108 * scale).round();
      expect(_pngSize('$dir/ic_launcher.png'), (legacy, legacy));
      expect(_pngSize('$dir/ic_launcher_round.png'), (legacy, legacy));
      expect(_pngSize('$dir/ic_launcher_foreground.png'), (layer, layer));
      expect(_pngSize('$dir/ic_launcher_monochrome.png'), (layer, layer));
    });
    for (final name in ['ic_launcher', 'ic_launcher_round']) {
      final xml = File('$_android/mipmap-anydpi-v26/$name.xml')
          .readAsStringSync();
      expect(xml, contains('@color/ic_launcher_background'));
      expect(xml, contains('@mipmap/ic_launcher_foreground'));
      expect(xml, contains('@mipmap/ic_launcher_monochrome'));
    }
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
    expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher_round"'));
  });

  testWidgets('iOS app icons: every size, opaque, Sofra not Flutter', (
    tester,
  ) async {
    final images =
        (jsonDecode(File('$_ios/Contents.json').readAsStringSync())
                as Map<String, dynamic>)['images']
            as List<dynamic>;
    expect(images, isNotEmpty);
    for (final e in images.cast<Map<String, dynamic>>()) {
      final file = '$_ios/${e['filename']}';
      final pt = double.parse((e['size'] as String).split('x').first);
      final px = (pt * int.parse((e['scale'] as String)[0])).round();
      expect(_pngSize(file), (px, px), reason: file);
      // The App Store refuses an icon with an alpha channel.
      expect(_pngColourType(file), 2, reason: '$file is opaque RGB');
    }
    // The corner of the store icon is Sofra's accent (#B4522F), where
    // Flutter's default icon was white and blue.
    final corner = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(
        File('$_ios/Icon-App-1024x1024@1x.png').readAsBytesSync(),
      );
      final image = (await codec.getNextFrame()).image;
      final rgba = (await image.toByteData())!;
      return [for (var i = 0; i < 3; i++) rgba.getUint8(i)];
    });
    expect(corner, isNotNull);
    expect((corner![0] - 0xB4).abs(), lessThan(4), reason: '$corner');
    expect((corner[1] - 0x52).abs(), lessThan(4), reason: '$corner');
    expect((corner[2] - 0x2F).abs(), lessThan(4), reason: '$corner');
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

  testWidgets('the Arabic wordmark is drawn a little taller than the English', (
    tester,
  ) async {
    Future<double> heightIn(AppLanguage language) async {
      SofraLook.notifier.value = SofraLook(language: language);
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(language),
          locale: language.locale,
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: L10n.delegates,
          home: const LookRoot(
            child: Scaffold(body: Center(child: SofraLogo(height: 40))),
          ),
        ),
      );
      await tester.pump();
      return tester.getSize(find.byType(Image)).height;
    }

    expect(await heightIn(AppLanguage.en), 40);
    expect(await heightIn(AppLanguage.ar), 40 * SofraLogo.arabicScale);
    expect(40 * SofraLogo.arabicScale, lessThanOrEqualTo(SofraLogo.maxHeight));
  });

  testWidgets('the sign-in page carries the logo, not the fork and knife', (
    tester,
  ) async {
    for (final language in AppLanguage.values) {
      SofraLook.notifier.value = SofraLook(language: language);
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(language),
          locale: language.locale,
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: L10n.delegates,
          home: const LookRoot(child: SignInPage()),
        ),
      );
      await tester.pump();
      expect(
        _logo(
          SofraLogo.asset(english: language == AppLanguage.en, dark: false),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.restaurant_rounded), findsNothing);
    }
  });

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

  testWidgets('the settings page ends on the logo and its footer line', (
    tester,
  ) async {
    await pumpApp(tester);
    await completeOnboarding(tester);
    await tapKey(tester, 'circle-settings');
    final logo = _logo('assets/brand/logo-ar.png');
    expect(logo, findsOneWidget);
    final footer = L10n.of(AppLanguage.ar).profFooter;
    expect(find.text(footer), findsOneWidget);
    // The logo says the name, so the line under it does not repeat it.
    expect(footer, isNot(contains('سفرة')));
    expect(
      tester.getTopLeft(find.text(footer)).dy,
      greaterThan(tester.getBottomLeft(logo).dy),
    );
    expect(L10n.of(AppLanguage.en).commTitle, 'Sofra Community');
  });

  testWidgets('"Sofra Community" keeps its words whole on a phone', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapKey(tester, 'lang-en');
    await completeOnboarding(tester);
    await openCorner(tester, 'community');
    final title = find.byKey(const ValueKey('community-welcome'));
    expect(tester.widget<Text>(title).data, 'Sofra Community');
    final style = tester.widget<Text>(title).style!;
    // Two lines, "Sofra" and "Community": no word is broken across lines.
    expect(
      tester.getSize(title).height,
      lessThanOrEqualTo(2 * style.fontSize! * style.height! + 1),
    );
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
