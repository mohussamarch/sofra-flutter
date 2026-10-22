import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';
import 'package:tabkha_demo/domain/recipe_variants.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/models.dart';

import 'recipe_variants_test.dart' as f;

CatalogRecipe unknownYield() => CatalogRecipe.fromJson({
  ...f.recipe().toJson(),
  'metadataPolicy': 'source-unknowns-v1',
  'servings': null,
  'prepTime': null,
  'cookTime': null,
  'totalTime': null,
  'steps': [
    {'n': 1, 'text': 'Synthetic step', 'duration': null},
  ],
  'notes': 'Synthetic source evidence; unpublished yield, no food claim.',
});
Future<({KitchenService k, f.Store store, RecipeRevision source})>
setup() async {
  final store = f.Store();
  final k = KitchenService(store, f.repository(value: unknownYield()));
  await k.load();
  final source = await k.catalogRevision('fixture');
  return (k: k, store: store, source: source);
}

Future<RecipeRevision> review(
  KitchenService k,
  RecipeRevision source, {
  int servings = 3,
  bool ack = true,
  String id = 'my-yield',
  String revision = 'v1',
  String note = 'Synthetic explicit whole-batch yield review',
  String? expected,
}) async => await k.reviewRecipeYield(
  sourceRevisionKey: source.key,
  baseServings: servings,
  variantId: id,
  revision: revision,
  reviewNote: note,
  reviewedAt: DateTime.utc(2026, 10, 22),
  acknowledgeWholeRecipeYield: ack,
  expectedActiveKey: expected,
);

void main() {
  test('whole-batch yield review persists a personal child and unlocks exact scaling', () async {
    final s = await setup();
    final before = jsonEncode(s.source.toJson());
    expect(() => s.source.recipe.forServings(6), throwsArgumentError);
    final child = await review(s.k, s.source);
    expect(child.kind, RecipeRevisionKind.personal);
    expect(child.parentKey, s.source.key);
    expect(child.recipe.servings, 3);
    expect(
      child.recipe.forServings(6).quantity(child.recipe.ingredients.single),
      400,
    );
    expect(child.recipe.prepMinutes, isNull);
    expect(child.recipe.totalMinutes, isNull);
    expect(() => child.recipe.forServings(6).schedule, throwsStateError);
    expect(jsonEncode(s.source.toJson()), before);
    final evidence = child.toJson()['yieldReview'] as Map;
    expect(evidence['sourceRevisionKey'], s.source.key);
    expect(evidence['baseServings'], 3);
    final reload = KitchenService(s.store, s.k.recipes);
    await reload.load();
    expect(reload.recipeBook.revisions[child.key]!.toJson(), child.toJson());
    expect(reload.recipeBook.revisions[s.source.key]!.recipe.servings, isNull);
    expect((await reload.recipes.get('fixture')).servings, isNull);
  });
  test('acknowledgement, positive bounded yield and explicit identity/note required', () async {
    final s = await setup();
    final before = jsonEncode(s.k.snapshot);
    for (final n in [0, -1, 1001]) {
      await expectLater(
        review(s.k, s.source, servings: n),
        throwsArgumentError,
      );
    }
    await expectLater(review(s.k, s.source, ack: false), throwsArgumentError);
    await expectLater(
      review(s.k, s.source, id: 'fixture'),
      throwsArgumentError,
    );
    await expectLater(review(s.k, s.source, note: ' '), throwsArgumentError);
    expect(jsonEncode(s.k.snapshot), before);
  });
  test('review changes only recipe ID/yield and legacy revision shape stays unchanged', () async {
    final s = await setup();
    expect(s.source.toJson().containsKey('yieldReview'), isFalse);
    final child = await review(s.k, s.source);
    expect(child.recipe.toJson(), {
      ...s.source.recipe.toJson(),
      'id': 'my-yield',
      'servings': 3,
    });
    expect(child.toJson()['yieldReview'], isNotNull);
  });
  test('book rejects tampered source fingerprint, yield or unrelated recipe content', () async {
    final s = await setup();
    final child = await review(s.k, s.source);
    for (final what in [
      'fingerprint',
      'yield',
      'ingredients',
      'timing',
      'parent',
    ]) {
      final raw = jsonDecode(
        jsonEncode(s.k.recipeBook.toJson()),
      ) as Map<String, dynamic>;
      final revision = (raw['revisions'] as Map)[child.key] as Map;
      if (what == 'fingerprint') {
        (revision['yieldReview'] as Map)['sourceSnapshotVersion'] = 'fake';
      }
      if (what == 'yield') {
        (revision['recipe'] as Map)['servings'] = 9;
      }
      if (what == 'ingredients') {
        (((revision['recipe'] as Map)['ingredients'] as List).first
                as Map)['amount'] =
            1;
      }
      if (what == 'timing') {
        (revision['recipe'] as Map)['prepTime'] = 1;
        (revision['recipe'] as Map)['cookTime'] = 1;
        (revision['recipe'] as Map)['totalTime'] = 2;
      }
      if (what == 'parent') {
        (revision['yieldReview'] as Map)['sourceRevisionKey'] = 'missing';
      }
      expect(
        () => RecipeBook.fromJson(raw),
        throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
      );
    }
  });
  test(
    'save failure rolls back; identical retries do not reactivate old versions',
    () async {
      final s = await setup();
      final before = jsonEncode(s.k.snapshot);
      s.store.fail = true;
      await expectLater(review(s.k, s.source), throwsStateError);
      expect(jsonEncode(s.k.snapshot), before);
      s.store.fail = false;
      final first = await review(s.k, s.source);
      final second = await review(
        s.k,
        s.source,
        servings: 4,
        revision: 'v2',
        expected: first.key,
      );
      await review(s.k, s.source);
      expect(s.k.recipeBook.active['my-yield'], second.key);
      await expectLater(
        review(s.k, s.source, servings: 5, revision: 'v3', expected: first.key),
        throwsStateError,
      );
      await expectLater(review(s.k, s.source, servings: 4), throwsStateError);
    },
  );
  test('existing pins stay unchanged; explicit reviewed meal can cook without inventing timing', () async {
    final s = await setup();
    await s.k.plan(f.plan('old', 'fixture', key: s.source.key));
    final before = s.k.snapshot;
    final child = await review(s.k, s.source);
    for (final key in [
      'inventory',
      'history',
      'purchases',
      'prices',
      'budgets',
      'plans',
    ]) {
      expect(s.k.snapshot[key], before[key]);
    }
    expect(s.k.snapshot['nutrition'], before['nutrition']);
    expect((await s.k.recipeForMeal('old')).recipe.servings, isNull);
    await s.k.addStock(
      InventoryLot(
        id: 'sample-lot',
        ingredientId: 'sample',
        quantity: 500,
        unit: 'جرام',
        zone: StorageZone.pantry,
      ),
      newPurchase: false,
    );
    await s.k.plan(
      PlannedMeal(
        id: 'new',
        date: '2026-10-22',
        slot: 'lunch',
        recipeId: child.variantId,
        recipeRevisionKey: child.key,
        servings: 6,
      ),
    );
    await s.k.confirmCooking(
      'new',
      'cook-review',
      cookedAt: DateTime.utc(2026, 10, 22),
    );
    expect(s.k.inventory.single.quantity, 100);
    expect(
      s.k.plans.singleWhere((x) => x.id == 'old').recipeRevisionKey,
      s.source.key,
    );
  });
  test(
    'competing reviews cannot overwrite an unseen active revision',
    () async {
      final s = await setup();
      final results = await Future.wait([
        review(
          s.k,
          s.source,
          revision: 'a',
        ).then((_) => true).catchError((Object _) => false),
        review(
          s.k,
          s.source,
          revision: 'b',
        ).then((_) => true).catchError((Object _) => false),
      ]);
      expect(results.where((x) => x).length, 1);
      expect(
        s.k.recipeBook.revisions.values
            .where((x) => x.kind == RecipeRevisionKind.personal)
            .length,
        1,
      );
    },
  );

  test(
    'persisted yield review requires explicit durable acknowledgement',
    () async {
      final s = await setup();
      final child = await review(s.k, s.source);
      final evidence = child.toJson()['yieldReview'] as Map;
      expect(evidence['acknowledgeWholeRecipeYield'], isTrue);
      for (final mode in ['missing', 'false']) {
        final raw = jsonDecode(
          jsonEncode(s.k.recipeBook.toJson()),
        ) as Map<String, dynamic>;
        final value =
            ((raw['revisions'] as Map)[child.key] as Map)['yieldReview'] as Map;
        if (mode == 'missing') {
          value.remove('acknowledgeWholeRecipeYield');
        } else {
          value['acknowledgeWholeRecipeYield'] = false;
        }
        expect(
          () => RecipeBook.fromJson(raw),
          throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
        );
      }
    },
  );
}
