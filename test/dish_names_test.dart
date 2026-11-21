import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/look.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';
import 'package:tabkha_demo/features/dish_name_view.dart';
import 'package:tabkha_demo/l10n/dish_names.g.dart';
import 'package:tabkha_demo/l10n/l10n.dart';
import 'package:tabkha_demo/main.dart';
import 'package:tabkha_demo/ui/design.dart';

import 'support/demo_flow.dart';

Map<String, dynamic> _glossary() =>
    jsonDecode(File('data/dish-names/glossary.json').readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> _entries() =>
    (_glossary()['entries'] as List).cast<Map<String, dynamic>>();

Future<void> _pumpApp(WidgetTester tester) async {
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

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const ValueKey('recipe-search')), text);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => SofraLook.notifier.value = const SofraLook());

  test('the generated names match the glossary, entry for entry', () {
    final entries = _entries();
    expect(dishNames.length, entries.length);
    final uses = <String, int>{};
    for (final e in entries) {
      uses[e['en'] as String] = (uses[e['en'] as String] ?? 0) + 1;
    }
    for (final e in entries) {
      final name = dishNames[e['id']];
      expect(name, isNotNull, reason: '${e['id']}');
      expect(name!.en, e['en'], reason: '${e['id']}');
      expect(name.say, e['pronunciation'], reason: '${e['id']}');
      final shared = uses[e['en']]! > 1;
      expect(name.countryEn, shared ? e['country']['en'] : null);
      expect(name.countryAr, shared ? e['country']['ar'] : null);
    }
  });

  test('every glossary dish is a catalog recipe with the same Arabic '
      'name, and the catalog shows the glossary English name', () async {
    final index = jsonDecode(
      File('recipes/data/index.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final arabic = {
      for (final r in index['recipes'] as List) r['id']: r['name'],
    };
    for (final e in _entries()) {
      expect(arabic[e['id']], e['ar'], reason: '${e['id']}');
    }

    final repo = RecipeRepository(read: (p) => File(p).readAsString());
    final rows = {
      for (final r in await repo.retainedIndex) r['id'] as String: r,
    };
    for (final MapEntry(key: id, value: name) in dishNames.entries) {
      expect(rows[id]!['nameEn'], name.en, reason: id);
    }
    // Decided spellings reach the catalog.
    expect(rows['eg-koshari']!['nameEn'], 'Koshary');
    expect(rows['sh-kafta-kefta']!['nameEn'], 'Grilled Kafta');
    expect(rows['eg-fatta']!['nameEn'], 'Fattah');
    // Recipes outside the glossary keep their own English name.
    expect(rows['it-carbonara']!['nameEn'], 'Carbonara');
  });

  test('only names shared across countries carry a country', () {
    final tagged = {
      for (final e in dishNames.entries)
        if (e.value.countryEn != null) e.key,
    };
    expect(tagged, {'eg-sayadeya', 'sa-sayadeyah', 'eg-bessara', 'ma-bessara'});
    expect(dishNames['eg-bessara']!.country, 'مصري');
    SofraLook.notifier.value = const SofraLook(language: AppLanguage.en);
    expect(dishNames['ma-bessara']!.country, 'Moroccan');
    expect(dishNames['eg-koshari']!.country, isNull);
  });

  test('a dish whose ways share one English name is called by it', () async {
    final repo = RecipeRepository(read: (p) => File(p).readAsString());
    final dishes = {for (final d in await repo.dishes) d.id: d};
    expect(dishes['sayadieh']!.nameEn, 'Sayadieh');
    // Ways with different names: the dish has no English name of its own.
    expect(dishes['fatteh']!.nameEn, isNull);
  });

  test(
    'old English spellings still find the dish, and are never shown',
    () async {
      final repo = RecipeRepository(read: (p) => File(p).readAsString());
      Future<List<String>> ids(String q) async => [
        for (final r in await repo.search(query: q)) r['id'] as String,
      ];
      expect(await ids('Koshari'), contains('eg-koshari'));
      expect(await ids('Stuffed Grape Leaves'), isNotEmpty);
      expect(await ids('Shish Tawook'), isNotEmpty);
      expect(await ids('Taameya'), contains('eg-taameya'));
      // The shown name is the reviewed one, not the old spelling.
      final rows = {
        for (final r in await repo.retainedIndex) r['id'] as String: r,
      };
      expect(rows['eg-koshari']!['nameEn'], 'Koshary');
      expect(dishNames['eg-koshari']!.also, ['Koshari']);
    },
  );

  for (final english in [true, false]) {
    testWidgets('the country tag replaces the cuisine tag '
        '(${english ? 'English' : 'Arabic'})', (tester) async {
      await _pumpApp(tester);
      await completeOnboarding(tester);
      SofraLook.notifier.value = SofraLook(
        language: english ? AppLanguage.en : AppLanguage.ar,
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'nav-recipes');
      await _search(tester, english ? 'Bissara' : 'بصارة');

      final country = english ? 'Egyptian' : 'مصري';
      final card = find.byKey(const ValueKey('recipe-eg-bessara'));
      expect(card, findsOneWidget);
      final tag = find.byKey(const ValueKey('country-tag-eg-bessara'));
      expect(
        find.descendant(of: tag, matching: find.text(country)),
        findsOneWidget,
      );
      // Paper (the recipe book) lists cuisine in a details line; cards use
      // SoftTag. Either way the country is said once, by the tag.
      final paper = find
          .ancestor(of: card, matching: find.byType(Paper))
          .evaluate()
          .isNotEmpty;
      expect(
        find.descendant(of: card, matching: find.text(country)),
        findsOneWidget,
        reason: paper ? 'paper' : 'card',
      );
      expect(
        find.descendant(of: card, matching: find.textContaining(country)),
        findsOneWidget,
      );

      await tester.tap(card);
      await tester.pumpAndSettle();
      final title = find.byKey(const ValueKey('recipe-title'));
      expect(
        find.descendant(of: title, matching: find.text(country)),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => w is SoftTag && w.text == country),
        findsOneWidget,
        reason: 'only the country tag, no plain cuisine tag',
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is SoftTag && w.text == country && w.leading != null,
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('the country tag renders on the book paper', (tester) async {
    SofraLook.notifier.value = const SofraLook(language: AppLanguage.en);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Paper(
            child: DishTitle(
              'Bissara',
              recipeId: 'ma-bessara',
              style: Sofra.heading(18),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Moroccan'), findsOneWidget);
    expect(find.byType(CountryNameTag), findsOneWidget);
  });

  testWidgets('a shared name shows its country tag; others show none', (
    tester,
  ) async {
    await _pumpApp(tester);
    await completeOnboarding(tester);
    SofraLook.notifier.value = const SofraLook(language: AppLanguage.en);
    await tester.pumpAndSettle();
    await tapKey(tester, 'nav-recipes');

    await _search(tester, 'Bissara');
    for (final id in ['eg-bessara', 'ma-bessara']) {
      final card = find.byKey(ValueKey('recipe-$id'));
      expect(card, findsOneWidget, reason: id);
      expect(
        find.descendant(
          of: card,
          matching: find.byKey(ValueKey('country-tag-$id')),
        ),
        findsOneWidget,
        reason: id,
      );
    }
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('country-tag-ma-bessara')),
        matching: find.text('Moroccan'),
      ),
      findsOneWidget,
    );

    await _search(tester, 'Koshary');
    expect(find.byKey(const ValueKey('recipe-eg-koshari')), findsOneWidget);
    expect(find.byKey(const ValueKey('country-tag-eg-koshari')), findsNothing);
    expect(find.byType(CountryNameTag), findsNothing);
  });

  testWidgets('the recipe title has an (i) with the pronunciation', (
    tester,
  ) async {
    await _pumpApp(tester);
    await completeOnboarding(tester);
    await tapKey(tester, 'nav-recipes');
    await _search(tester, 'كشري');
    await tapKey(tester, 'recipe-eg-koshari');

    final title = find.byKey(const ValueKey('recipe-title'));
    expect(title, findsOneWidget);
    final info = find.descendant(
      of: title,
      matching: find.byKey(const ValueKey('pronunciation-info')),
    );
    expect(info, findsOneWidget);
    final tip = tester.widget<Tooltip>(info);
    expect(tip.richMessage!.toPlainText(), contains('KOH-sha-ree'));
    expect(tip.richMessage!.toPlainText(), contains('Koshary'));
    expect(
      tip.richMessage!.toPlainText(),
      contains(L10n.current.detailPronunciation),
    );
    // Not written next to the name.
    expect(find.text('KOH-sha-ree'), findsNothing);

    await tester.ensureVisible(info);
    await tester.tap(info);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.textContaining('KOH-sha-ree', findRichText: true),
      findsWidgets,
    );
    await tester.pumpAndSettle(const Duration(seconds: 7));
  });

  testWidgets('a plain English name has no (i)', (tester) async {
    await _pumpApp(tester);
    await completeOnboarding(tester);
    await tapKey(tester, 'nav-recipes');
    await _search(tester, 'رز بلبن');
    await tapKey(tester, 'recipe-eg-rice-pudding');
    expect(find.byKey(const ValueKey('recipe-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('pronunciation-info')), findsNothing);
  });
}
