import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/food_repository.dart';
import 'package:tabkha_demo/data/recipe_library_assets.dart';
import 'package:tabkha_demo/data/recipe_library_food_search.dart';
import 'package:tabkha_demo/data/recipe_library_repository.dart';
import 'package:tabkha_demo/domain/recipe_library_draft.dart';

import 'recipe_library_repository_test.dart' as fixtures;

class FoodAssets {
  int reads = 0;
  final release = Completer<void>();
  bool delayed = false;
  Future<String> read(String path) async {
    reads++;
    if (delayed) await release.future;
    if (path == 'data/food/openfoodfacts/products.jsonl') {
      return [
        {
          'barcode': '100',
          'names': {'en': 'Rice bag'},
          'markets': ['EG'],
          'evidence': {'status': 'unreviewed'},
        },
        {
          'barcode': '200',
          'names': {'en': 'Rice bag'},
          'markets': ['SA'],
        },
      ].map(jsonEncode).join('\n');
    }
    if (path == 'data/usda/index.json') {
      return jsonEncode({
        'foods': [
          {
            'id': 'usda:1',
            'name': 'Rice, white, raw',
            'category': 'Grains',
            'file': '01.json',
            'version': 'v1',
          },
          {
            'id': 'usda:2',
            'name': 'Wheat flour',
            'category': 'Grains',
            'file': '01.json',
            'version': 'v1',
          },
        ],
      });
    }
    throw StateError('Unexpected source read: $path');
  }
}

Future<RecipeLibraryEntry> entry({double? amount = 2}) async {
  final f = fixtures.LibraryFixture();
  f.local = jsonDecode(jsonEncode(f.local)) as Map<String, dynamic>;
  f.local['recipes'][0]['ingredients'][0]['amount'] = amount;
  f.local['recipes'][0]['ingredients'].add({
    'nameAr': 'دقيق',
    'amount': null,
    'unit': null,
    'sourceText': 'as needed',
    'optional': true,
    'included': false,
  });
  f.rebuild();
  return (await f.repository().all()).first;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'food search pins exact duplicate source line and keeps raw unknowns',
    () async {
      final e = await entry(), assets = FoodAssets();
      final before = recipeLibrarySourceFingerprint(e);
      final result =
          await RecipeLibraryFoodSearch(
            foods: FoodRepository(read: assets.read),
          ).search(
            entry: e,
            expectedSourceFingerprint: before,
            lineIndex: 1,
            query: ' RICE ',
            market: 'EG',
            limit: 5,
          );
      expect(result.recipeId, e.id);
      expect(result.sourceFingerprint, before);
      expect(result.lineIndex, 1);
      expect(result.query, 'RICE');
      expect(result.market, 'EG');
      expect(result.ingredient.labelAr, 'دقيق');
      expect(result.ingredient.amount, isNull);
      expect(result.ingredient.sourceQuantityText, 'as needed');
      expect(result.ingredient.included, false);
      expect(result.ingredient.optional, true);
      expect(result.candidates.map((r) => r['barcode'] ?? r['id']), [
        '100',
        'usda:1',
      ]);
      expect(result.requiresExplicitReview, true);
      expect(result.toJson()['runtimeApproved'], false);
      expect(recipeLibrarySourceFingerprint(e), before);
      expect(e.runtimeReady, false);
      expect(e.nutrition, isNull);
    },
  );
  test(
    'stale source, invalid index and blank query reject before bank reads',
    () async {
      final e = await entry(),
          changed = await entry(amount: 3),
          assets = FoodAssets();
      final search = RecipeLibraryFoodSearch(
        foods: FoodRepository(read: assets.read),
      );
      Future<Object> run({String? pin, int line = 0, String query = 'rice'}) =>
          search.search(
            entry: changed,
            expectedSourceFingerprint:
                pin ?? recipeLibrarySourceFingerprint(changed),
            lineIndex: line,
            query: query,
          );
      await expectLater(
        run(pin: recipeLibrarySourceFingerprint(e)),
        throwsStateError,
      );
      await expectLater(run(line: -1), throwsArgumentError);
      await expectLater(
        run(line: changed.ingredients.length),
        throwsArgumentError,
      );
      await expectLater(run(query: ' \t '), throwsArgumentError);
      expect(assets.reads, 0);
    },
  );
  test('returned candidate evidence and JSON cannot change later results or source cache', () async {
    final e = await entry(), assets = FoodAssets();
    final search = RecipeLibraryFoodSearch(
      foods: FoodRepository(read: assets.read),
    );
    Future<RecipeLibraryFoodSearchResult> run() => search.search(
      entry: e,
      expectedSourceFingerprint: recipeLibrarySourceFingerprint(e),
      lineIndex: 0,
      query: 'rice',
    );
    final first = await run();
    final candidates = first.candidates;
    expect(() => candidates.clear(), throwsUnsupportedError);
    candidates[0]['evidence']['status'] = 'approved';
    candidates[2]['name'] = 'changed';
    final json = first.toJson();
    json['candidates'][0]['names']['en'] = 'changed';
    json['ingredient']['labelAr'] = 'changed';
    expect(first.candidates[0]['evidence']['status'], 'unreviewed');
    expect(first.candidates[2]['name'], 'Rice, white, raw');
    expect((await run()).candidates[0]['names']['en'], 'Rice bag');
    expect(first.ingredient.labelAr, 'دقيق');
  });
  test('packaged market scope, limit, empty matches and asynchronous source context stay distinct', () async {
    final e = await entry(), assets = FoodAssets()..delayed = true;
    final search = RecipeLibraryFoodSearch(
      foods: FoodRepository(read: assets.read),
    );
    final pending = search.search(
      entry: e,
      expectedSourceFingerprint: recipeLibrarySourceFingerprint(e),
      lineIndex: 2,
      query: 'rice',
      market: 'SA',
      packagedOnly: true,
      limit: 1,
    );
    await entry(
      amount: 10,
    ); // A separate revision cannot replace this request's pinned source.
    assets.release.complete();
    final result = await pending;
    expect(result.ingredient.supplemental, true);
    expect(result.candidates.single['barcode'], '200');
    expect(result.packagedOnly, true);
    expect(result.limit, 1);
    final none = await search.search(
      entry: e,
      expectedSourceFingerprint: result.sourceFingerprint,
      lineIndex: 0,
      query: 'no-such-food',
    );
    expect(none.candidates, isEmpty);
    expect(none.requiresExplicitReview, true);
    for (final args in [
      (market: 'US', limit: 1),
      (market: 'EG', limit: 0),
      (market: 'SA', limit: 501),
    ]) {
      await expectLater(
        search.search(
          entry: e,
          expectedSourceFingerprint: result.sourceFingerprint,
          lineIndex: 0,
          query: 'rice',
          market: args.market,
          limit: args.limit,
        ),
        throwsArgumentError,
      );
    }
  });
  test('bundled library ingredient can search actual licensed food banks without automatic binding', () async {
    final entries = await bundledRecipeLibrary().all();
    final e = entries.firstWhere((v) => v.ingredients.isNotEmpty);
    final result = await RecipeLibraryFoodSearch(foods: FoodRepository())
        .search(
          entry: e,
          expectedSourceFingerprint: recipeLibrarySourceFingerprint(e),
          lineIndex: 0,
          query: 'rice',
          limit: 3,
        );
    expect(result.candidates, isNotEmpty);
    expect(result.candidates.length, lessThanOrEqualTo(3));
    expect(result.recipeId, e.id);
    expect(result.sourceFingerprint, recipeLibrarySourceFingerprint(e));
    expect(result.ingredient.toJson(), e.ingredients.first.toJson());
    expect(result.requiresExplicitReview, true);
    expect(e.nutrition, isNull);
  });
}
