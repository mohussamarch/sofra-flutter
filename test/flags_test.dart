import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/ui/flags.dart';

/// Catalog cuisines that are regional or mixed and deliberately show a globe.
const withoutFlag = {
  'شامي',
  'متوسطي',
  'كشميري',
  'تبتي',
  'آسيوي',
  'عالمي متنوع',
  'غير محدد',
  'أمريكي جنوبي',
};

Future<Set<String>> catalogCuisines({bool activeOnly = true}) async {
  final data =
      jsonDecode(await File('recipes/data/index.json').readAsString()) as Map;
  return {
    for (final r in data['recipes'] as List)
      if (!activeOnly || r['catalogStatus'] == 'active') r['cuisine'] as String,
  };
}

void main() {
  test(
    'every active catalog cuisine has a drawn flag or is a known globe',
    () async {
      final cuisines = await catalogCuisines();
      expect(cuisines, isNotEmpty);
      for (final cuisine in cuisines) {
        final code = flagCodeFor(cuisine);
        if (withoutFlag.contains(cuisine)) {
          expect(code, isNull, reason: cuisine);
        } else {
          expect(code, isNotNull, reason: cuisine);
          expect(CountryFlag.known(code!), isTrue, reason: '$cuisine → $code');
        }
      }
    },
  );

  test('flagCodeFor normalises its input', () {
    expect(flagCodeFor('مصري'), 'egyptian');
    expect(flagCodeFor('  مصري \n'), 'egyptian');
    expect(flagCodeFor('عُماني'), 'omani');
    expect(flagCodeFor('عماني'), 'omani');
    expect(flagCodeFor('اردني'), 'jordanian');
    expect(flagCodeFor('أردني'), 'jordanian');
    expect(flagCodeFor('ايطالي'), 'italian');
    expect(flagCodeFor('إيطالي   أمريكي'), 'american');
    expect(flagCodeFor('سوريّ'), 'syrian');
    expect(flagCodeFor('مصرية'), 'egyptian');
    expect(flagCodeFor('بنجابي'), 'indian');
    expect(flagCodeFor('سيتشواني'), 'chinese');
    expect(flagCodeFor('كاجوني'), 'american');
    expect(flagCodeFor('egyptian'), 'egyptian');
    expect(flagCodeFor('levantine'), isNull);
    expect(flagCodeFor('شامي'), isNull);
    expect(flagCodeFor('مريخي'), isNull);
    expect(flagCodeFor(''), isNull);
  });

  test('the onboarding cuisine-group codes keep their flags', () {
    for (final id in const [
      'egyptian',
      'saudi',
      'moroccan',
      'italian',
      'french',
      'greek',
      'spanish',
      'turkish',
      'chinese',
      'japanese',
      'indian',
      'thai',
      'korean',
      'mexican',
    ]) {
      expect(CountryFlag.known(id), isTrue, reason: id);
    }
    expect(CountryFlag.known('levantine'), isFalse);
    expect(CountryFlag.known('other'), isFalse);
  });

  testWidgets('every catalog cuisine flag renders', (tester) async {
    final cuisines = await tester.runAsync(
      () => catalogCuisines(activeOnly: false),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Wrap(
              children: [
                for (final c in cuisines!) ...[
                  CuisineFlag(c),
                  CuisineFlag(c, size: 20),
                  CuisineFlag(c, size: 28),
                ],
                for (final code in FlagPainter.drawn) CountryFlag(code),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.byIcon(Icons.public_rounded),
      findsNWidgets(3 * cuisines.where((c) => flagCodeFor(c) == null).length),
    );
  });
}
