import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';
import 'package:tabkha_demo/domain/recipe_variants.dart';

import 'recipe_variants_test.dart' as fixture;

// Synthetic arithmetic/revision fixtures only, not published food quantities.
CatalogRecipe sourceRecipe() => CatalogRecipe.fromJson({
  ...fixture.recipe().toJson(),
  'ingredients': [
    {'id': 'sample', 'name': 'عينة', 'amount': 200, 'unit': 'g'},
    {
      'id': 'salt-pepper',
      'name': 'ملح وفلفل',
      'amount': null,
      'scale': false,
      'label': 'حسب الرغبة',
    },
    {'id': 'onion', 'name': 'بصل', 'amount': 2, 'unit': 'حبة'},
  ],
});
List<CatalogIngredient> components() => [
  CatalogIngredient.fromJson({
    'id': 'salt',
    'name': 'ملح اختبار',
    'amount': 1,
    'unit': 'g',
    'scale': false,
  }),
  CatalogIngredient.fromJson({
    'id': 'pepper',
    'name': 'فلفل اختبار',
    'amount': 2,
    'unit': 'g',
    'scale': true,
  }),
];
RecipeRevision split(
  RecipeRevision source, {
  List<CatalogIngredient>? parts,
  bool ack = true,
  String id = 'personal',
  String version = 'v1',
}) => buildIngredientSplitRevision(
  source: source,
  line: 1,
  components: parts ?? components(),
  variantId: id,
  revision: version,
  reviewNote: 'Synthetic review: complete replacement and unchanged instructions checked',
  reviewedAt: DateTime.utc(2026, 10, 13),
  acknowledgeCompleteReplacement: ack,
);
Future<({KitchenService k, fixture.Store store, RecipeRevision source})>
setup() async {
  final store = fixture.Store(),
      k = KitchenService(
        fixture.Store(),
        fixture.repository(value: sourceRecipe()),
      );
  final actual = KitchenService(store, k.recipes);
  await actual.load();
  final source = await actual.catalogRevision('fixture');
  return (k: actual, store: store, source: source);
}

void main() {
  test('split preserves complete parent content except exact ingredient replacement and new ID', () async {
    final f = await setup(), before = jsonEncode(f.source.toJson());
    final child = split(f.source);
    expect(child.parentKey, f.source.key);
    expect(child.kind, RecipeRevisionKind.personal);
    expect(child.recipe.ingredients.map((v) => v.id), [
      'sample',
      'salt',
      'pepper',
      'onion',
    ]);
    expect(
      child.recipe.steps.map((v) => v.toJson()).toList(),
      f.source.recipe.steps.map((v) => v.toJson()).toList(),
    );
    expect(
      child.recipe.forServings(4).quantity(child.recipe.ingredients[1]),
      1,
    );
    expect(
      child.recipe.forServings(4).quantity(child.recipe.ingredients[2]),
      4,
    );
    final round = RecipeRevision.fromJson(child.toJson());
    expect(round.toJson(), child.toJson());
    expect(jsonEncode(f.source.toJson()), before);
    final parts = components();
    final immutable = split(f.source, parts: parts);
    parts.clear();
    expect(immutable.ingredientSplitReview!.components.length, 2);
  });
  test('complete replacement acknowledgement and2distinct quantified components are mandatory', () async {
    final f = await setup();
    expect(() => split(f.source, ack: false), throwsArgumentError);
    expect(
      () => split(f.source, parts: components().take(1).toList()),
      throwsArgumentError,
    );
    expect(
      () => split(f.source, parts: [components().first, components().first]),
      throwsArgumentError,
    );
    expect(
      () => split(
        f.source,
        parts: [
          ...components().take(1),
          CatalogIngredient.fromJson({
            'id': 'pepper',
            'name': 'فلفل',
            'scale': false,
          }),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => split(
        f.source,
        parts: [
          ...components().take(1),
          CatalogIngredient.fromJson({
            'id': 'salt-pepper',
            'name': 'قديم',
            'amount': 1,
            'unit': 'g',
          }),
        ],
      ),
      throwsArgumentError,
    );
  });
  test('atomic service persists source review and failed save does not publish child', () async {
    final f = await setup(), before = f.k.snapshot;
    f.store.fail = true;
    Future<RecipeRevision> save() => f.k.splitRecipeIngredient(
      sourceRevisionKey: f.source.key,
      line: 1,
      components: components(),
      variantId: 'personal',
      revision: 'v1',
      reviewNote: 'Synthetic complete replacement/instructions reviewed',
      reviewedAt: DateTime.utc(2026, 10, 13),
      acknowledgeCompleteReplacement: true,
    );
    await expectLater(save(), throwsStateError);
    expect(f.k.snapshot, before);
    f.store.fail = false;
    final child = await save();
    expect(
      f
          .k
          .recipeBook
          .revisions[child.key]!
          .ingredientSplitReview!
          .sourceSnapshotVersion,
      recipeSnapshotVersion(f.source.recipe),
    );
    final reload = KitchenService(f.store, f.k.recipes);
    await reload.load();
    expect(reload.recipeBook.revisions[child.key]!.toJson(), child.toJson());
    expect((await save()).toJson(), child.toJson());
  });
  test('new revision never inherits bindings by shifted line and old plans stay pinned', () async {
    final f = await setup();
    await f.k.saveRecipeFoodSelection(fixture.selection(f.source));
    await f.k.plan(fixture.plan('old', 'fixture'));
    final child = split(f.source);
    await f.k.saveRecipeRevision(child);
    await f.k.plan(fixture.plan('new', 'personal'));
    expect((await f.k.recipeForMeal('old')).key, f.source.key);
    expect((await f.k.recipeForMeal('new')).key, child.key);
    final old = await f.k.previewIngredientNutrition('old'),
        fresh = await f.k.previewIngredientNutrition('new');
    expect(old.whole[NutrientId.protein]!.knownSubtotal, 20);
    expect(fresh.whole[NutrientId.protein]!.knownSubtotal, 0);
    expect(fresh.whole[NutrientId.protein]!.missing.length, 4);
    final newer = RecipeRevision(
      familyId: child.familyId,
      revision: 'v2',
      kind: RecipeRevisionKind.personal,
      parentKey: child.key,
      recipe: CatalogRecipe.fromJson({
        ...child.recipe.toJson(),
        'name': 'Synthetic next revision',
      }),
    );
    await f.k.saveRecipeRevision(newer);
    await f.k.saveRecipeRevision(child);
    expect(f.k.recipeBook.active['personal'], newer.key);
    expect((await f.k.recipeForMeal('new')).key, child.key);
  });
  test(
    'book rejects stale source evidence or changed unrelated contents',
    () async {
      final f = await setup();
      final child = split(f.source);
      final json = child.toJson();
      final review = Map<String, dynamic>.from(json['ingredientSplitReview']);
      review['sourceSnapshotVersion'] = 'stale';
      expect(
        () => f.k.recipeBook.addRevision(
          RecipeRevision.fromJson({...json, 'ingredientSplitReview': review}),
        ),
        throwsFormatException,
      );
      final changed = Map<String, dynamic>.from(json['recipe']);
      changed['name'] = 'unreviewed other edit';
      expect(
        () => f.k.recipeBook.addRevision(
          RecipeRevision.fromJson({...json, 'recipe': changed}),
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'completed history stays byte-equivalent after compound revision is added',
    () async {
      final f = await setup();
      await f.k.plan(fixture.plan('old', 'fixture'));
      await f.k.addStock(
        InventoryLot(
          id: 's',
          ingredientId: 'sample',
          quantity: 1000,
          unit: 'g',
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
      await f.k.addStock(
        InventoryLot(
          id: 'o',
          ingredientId: 'onion',
          quantity: 1000,
          unit: 'g',
          zone: StorageZone.fridge,
        ),
        newPurchase: false,
      );
      final old = await f.k.confirmCooking(
        'old',
        'op',
        omitUnmeasuredLines: {1},
        actualUsesByLine: {2: IngredientUse('onion', 150, 'g')},
      );
      final frozen = jsonEncode(old);
      await f.k.saveRecipeRevision(split(f.source));
      expect(jsonEncode(await f.k.confirmCooking('old', 'op')), frozen);
      expect(f.k.inventory.first.quantity, 800);
    },
  );
}
