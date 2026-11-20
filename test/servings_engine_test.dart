import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/sofra_controller.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';
import 'package:tabkha_demo/domain/servings_engine.dart';
import 'package:tabkha_demo/domain/servings_tables.g.dart';

// Recipe data below is stored Arabic data, as in recipes/data.
final engine = ServingsEngine.shared;

ServingsEstimate run(
  String category,
  List<(String, String, num?, String?)> lines, {
  int? servings,
}) => engine.estimate(
  category: category,
  servings: servings,
  lines: [
    for (final (id, name, amount, unit) in lines)
      ServingsLine(id: id, name: name, amount: amount?.toDouble(), unit: unit),
  ],
);

Map<String, dynamic> catalogJson({
  int? servings,
  String category = 'طبق رئيسي',
  List<Map<String, dynamic>>? ingredients,
  Map<String, dynamic> extra = const {},
}) => {
  'id': 'servings-test',
  'name': 'مكرونة',
  'cuisine': 'مصري',
  'category': category,
  'description': 'وصفة اختبار',
  'difficulty': 'سهل',
  if (servings == null) 'metadataPolicy': CatalogRecipe.unknownMetadataPolicy,
  'servings': servings,
  'prepTime': 5,
  'cookTime': 10,
  'totalTime': 15,
  'ingredients':
      ingredients ??
      [
        {'id': 'pasta', 'name': 'مكرونة', 'amount': 1000, 'unit': 'جرام'},
        {'id': 'salt', 'name': 'ملح', 'amount': 1, 'unit': 'ملعقة صغيرة'},
      ],
  'steps': [
    {'n': 1, 'text': 'اسلق', 'duration': 10},
  ],
  'tags': <String>[],
  'notes': 'المصدر لا يذكر عدد الأفراد.',
  ...extra,
};

void main() {
  group('norm math', () {
    test('owner anchors', () {
      expect(run('طبق رئيسي', [('pasta', 'مكرونة', 1, 'كيلو')]).computed, 5);
      final kabsa = run('طبق رئيسي', [
        ('basmati-rice', 'أرز بسمتي', 1, 'كيلو'),
        ('lamb', 'لحم ضأن', 1, 'كيلو'),
      ]);
      expect((kabsa.computed! - 7).abs(), lessThanOrEqualTo(1));
      expect(kabsa.confidence, ServingsConfidence.high);
      expect(run('طبق رئيسي', [('chicken', 'فرخة', 1, 'حبة')]).computed, 4);
      expect(
        run('طبق رئيسي', [('molokhia', 'ملوخية', 400, 'جرام')]).computed,
        4,
      );
      expect(
        run('شوربة', [
          ('red-lentils', 'عدس أصفر', 1.5, 'كوب'),
          ('water', 'ماء', 1.75, 'لتر'),
        ]).computed,
        5,
      );
    });

    test('unit conversions: pounds, ounces, cups by density, pieces', () {
      expect(run('طبق رئيسي', [('beef', 'لحم', 2, 'رطل')]).people, 4.54);
      expect(run('طبق رئيسي', [('pasta', 'مكرونة', 16, 'oz')]).people, 2.27);
      // 1 cup rice = 200 g, 150 g per person.
      expect(run('طبق رئيسي', [('rice', 'أرز', 3, 'كوب')]).computed, 4);
      expect(
        run('طبق رئيسي', [('chicken-breast', 'صدور دجاج', 4, 'حبة')]).computed,
        5,
      );
      final range = run('طبق رئيسي', [('pasta', 'مكرونة', 1, 'كيلو')]).range!;
      expect(range, (4, 6));
    });

    test('unknown units and messy lines never crash', () {
      final r = run('طبق رئيسي', [
        ('pasta', 'مكرونة', 2, 'حفنة'),
        ('constructor', 'toString', 3, 'constructor'),
        ('', '', null, null),
        ('x', 'شيء', double.nan, 'كوب'),
      ]);
      expect(r.computed, isNull);
      expect(r.confidence, ServingsConfidence.none);
      expect(r.reason, isNotNull);
      expect(
        () => engine.estimateJson({
          'category': 3,
          'ingredients': [
            null,
            4,
            'x',
            {'amount': 'abc', 'unit': 7},
          ],
        }),
        returnsNormally,
      );
    });
  });

  group('dominant ingredient choice', () {
    test('spices, oils and sauces never drive; liquids only drive soups', () {
      final r = run('طبق رئيسي', [
        ('pasta', 'مكرونة', 500, 'جرام'),
        ('oil', 'زيت', 2, 'كوب'),
        ('tomato-paste', 'صلصة طماطم', 400, 'جرام'),
        ('water', 'ماء', 2, 'لتر'),
      ]);
      expect(r.drivers.map((d) => d.category), ['pastaDry']);
      expect(r.computed, 3);
    });

    test('eggs drive only without another protein', () {
      expect(run('فطار', [('eggs', 'بيض', 6, 'حبة')]).computed, 3);
      final withMeat = run('طبق رئيسي', [
        ('eggs', 'بيض', 6, 'حبة'),
        ('beef', 'لحم', 1, 'كيلو'),
      ]);
      expect(withMeat.drivers.map((d) => d.category), ['meatBoneless']);
    });

    test('keyword order: liver before chicken, mince before meat', () {
      final liver = engine.categoryOf(
        const ServingsLine(id: 'x-liver', name: 'كبدة فراخ'),
      );
      expect(liver, 'liver');
      final mince = engine.categoryOf(
        const ServingsLine(id: 'x-mince', name: 'لحم بقري مفروم'),
      );
      expect(mince, 'mince');
      final onion = engine.categoryOf(
        const ServingsLine(id: 'x-onion', name: 'بصل مفروم'),
      );
      expect(onion, isNull);
    });

    test(
      'desserts count flour as a dessert base; bases are not applicable',
      () {
        final cake = run('حلويات', [('flour', 'دقيق', 300, 'جرام')]);
        expect(cake.drivers.single.category, 'dessertBase');
        expect(cake.computed, 5);
        final sauce = run('صلصة', [('tomato', 'طماطم', 1, 'كيلو')]);
        expect(sauce.computed, isNull);
        expect(sauce.reason, 'notApplicable');
      },
    );

    test('several roles share the plate', () {
      final koshary = run('طبق رئيسي', [
        ('rice', 'أرز', 300, 'جرام'),
        ('lentils', 'عدس', 200, 'جرام'),
        ('pasta', 'مكرونة', 200, 'جرام'),
      ]);
      // One starch role: 2 + 2 + 1 people, no sharing factor.
      expect(koshary.people, 5);
    });
  });

  group('source cross-check', () {
    test('a plausible stated yield is kept', () {
      final r = run('طبق رئيسي', [
        ('pasta', 'مكرونة', 500, 'جرام'),
      ], servings: 3);
      expect(r.basis, ServingsBasisSource.source);
      expect(r.impliedPerPerson, 166.7);
    });

    test('an implausible one is rejected with a reason', () {
      final r = run('طبق رئيسي', [
        ('pasta', 'مكرونة', 500, 'جرام'),
      ], servings: 10);
      expect(r.basis, ServingsBasisSource.computed);
      expect(r.reason, 'sourceInflated');
      final cookies = run('حلويات', [
        ('flour', 'دقيق', 2, 'كوب'),
      ], servings: 36);
      expect(cookies.reason, 'sourceCountsPieces');
    });

    test('a low-confidence result does not reject the source', () {
      final r = run('طبق رئيسي', [
        ('pasta', 'مكرونة', 120, 'جرام'),
      ], servings: 4);
      expect(r.confidence, ServingsConfidence.low);
      expect(r.basis, ServingsBasisSource.source);
      expect(r.reason, 'sourceKeptLowConfidence');
    });
  });

  group('CatalogRecipe', () {
    test('a recipe without servings scales by the computed yield', () {
      final recipe = CatalogRecipe.fromJson(catalogJson());
      expect(recipe.servings, isNull);
      expect(recipe.effectiveServings, 5);
      expect(recipe.servingsComputedByApp, isTrue);
      expect(recipe.hasKnownYield, isTrue);
      final scaled = recipe.forServings(10);
      expect(scaled.factor, 2);
      expect(scaled.quantity(recipe.ingredients.first), 2000);
    });

    test('a stated yield is never overridden at runtime', () {
      final recipe = CatalogRecipe.fromJson(catalogJson(servings: 12));
      expect(recipe.effectiveServings, 12);
      expect(recipe.servingsComputedByApp, isFalse);
    });

    test('the build verdict is read, kept through toJson and applied', () {
      final verdict = run('طبق رئيسي', [
        ('pasta', 'مكرونة', 1000, 'جرام'),
      ], servings: 12);
      expect(verdict.basis, ServingsBasisSource.computed);
      final recipe = CatalogRecipe.fromJson(
        catalogJson(servings: 12, extra: verdict.toJson()),
      );
      expect(recipe.servings, 12);
      expect(recipe.effectiveServings, 5);
      expect(recipe.forServings(5).factor, 1);
      final again = CatalogRecipe.fromJson(recipe.toJson());
      expect(again.effectiveServings, 5);
      expect(again.toJson(), recipe.toJson());
    });

    test('no stored fields keeps toJson unchanged', () {
      final recipe = CatalogRecipe.fromJson(catalogJson(servings: 4));
      expect(
        recipe.toJson().keys.where(ServingsEstimate.fieldKeys.contains),
        isEmpty,
      );
    });

    test('index rows plan by the computed yield', () {
      final row = {
        'id': 'r1',
        'category': 'طبق رئيسي',
        'servings': null,
        'ingredients': [
          {'id': 'pasta', 'name': 'مكرونة', 'amount': 600, 'unit': 'جرام'},
        ],
      };
      expect(SofraController.rowServings(row), 3);
      expect(
        SofraController.rowServings({...row, 'ingredients': <Object>[]}),
        isNull,
      );
      expect(SofraController.rowServings({'id': 'r2', 'servings': 4}), 4);
    });
  });

  group('catalog-wide', () {
    final fixture = (jsonDecode(
      File('test/fixtures/servings-parity.json').readAsStringSync(),
    ) as List).cast<Map<String, dynamic>>();
    final files = <String, Object?>{};

    Map<String, dynamic> recipeAt(Map<String, dynamic> entry) {
      final json = files.putIfAbsent(
        entry['file'] as String,
        () => jsonDecode(File(entry['file'] as String).readAsStringSync()),
      );
      final rows = json is List ? json : (json as Map)['recipes'] as List;
      return Map<String, dynamic>.from(rows[entry['index'] as int] as Map);
    }

    test('the corpus is the one the node tool ran', () {
      expect(fixture.length, greaterThan(900));
    });

    test('Dart and node engines agree on every recipe', () {
      final mismatches = <String>[];
      for (final entry in fixture) {
        final recipe = recipeAt(entry);
        expect(recipe['id'], entry['id']);
        final actual = engine.estimateJson(recipe).toJson();
        final expected = {
          for (final key in ServingsEstimate.fieldKeys) key: entry[key],
        };
        if (!_same(actual, expected)) {
          mismatches.add('${entry['id']}: $actual != $expected');
        }
      }
      expect(mismatches, isEmpty, reason: mismatches.take(5).join('\n'));
    });

    test('every recipe gets a value or an explicit reason', () {
      var withValue = 0;
      for (final entry in fixture) {
        final r = engine.estimateJson(recipeAt(entry));
        if (r.hasValue) {
          withValue++;
          expect(r.computed, inInclusiveRange(1, 20));
          expect(r.range!.$1, lessThanOrEqualTo(r.computed!));
          expect(r.range!.$2, greaterThanOrEqualTo(r.computed!));
        } else {
          expect(r.reason, isNotNull, reason: entry['id'] as String);
        }
      }
      expect(withValue, greaterThan(fixture.length * 0.6));
    });

    test('catalog recipes parse and scale with the effective yield', () {
      for (final entry in fixture.where(
        (e) => (e['file'] as String).startsWith('recipes/data/'),
      )) {
        final recipe = CatalogRecipe.fromJson(recipeAt(entry));
        final yieldNow = recipe.effectiveServings;
        if (yieldNow == null) {
          expect(recipe.hasKnownYield, isFalse);
          continue;
        }
        expect(recipe.forServings(4).sourceServings, yieldNow);
      }
    });

    test('the compiled tables carry the current portion norms', () {
      final norms = jsonDecode(
        File('data/ingredients/portion-norms.json').readAsStringSync(),
      );
      final tables = jsonDecode(servingsTablesJson);
      expect(tables['norms'], norms['norms']);
      expect(tables['rules'], norms['rules']);
      final categories = jsonDecode(
        File('data/ingredients/portion-categories.json').readAsStringSync(),
      );
      expect(tables['keywords'], categories['keywords']);
      expect(tables['deny'], categories['deny']);
    });
  });
}

bool _same(Object? a, Object? b) {
  if (a is num && b is num) return a == b;
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((k) => b.containsKey(k) && _same(a[k], b[k]));
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_same(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
