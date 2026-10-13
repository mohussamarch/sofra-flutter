import 'dart:convert';

import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/models.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';
import 'package:tabkha_demo/domain/recipe_variants.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';

import 'recipe_variants_test.dart' as fixture;
import 'compound_revisions_test.dart' as compound;

// Synthetic revision/arithmetic fixtures; no culinary or clinical assertions.
RecipeRevision choose(
  RecipeRevision source, {
  bool ack = true,
  CatalogIngredient? selected,
  String variantId = 'choice-personal',
  String revision = 'v1',
}) => buildIngredientChoiceRevision(
  source: source,
  line: 1,
  selected: selected ?? compound.components().last,
  variantId: variantId,
  revision: revision,
  reviewNote:
      'Synthetic single replacement; quantities and instructions reviewed',
  reviewedAt: DateTime.utc(2026, 10, 14),
  acknowledgeCompleteReplacement: ack,
);

void main() {
  test('one explicit choice replaces one source line without adding all alternatives', () async {
    final f = await compound.setup(),
        before = jsonEncode(f.source.toJson()),
        child = choose(f.source);
    expect(child.recipe.ingredients.map((v) => v.id), [
      'sample',
      'pepper',
      'onion',
    ]);
    expect(
      child.recipe.forServings(4).quantity(child.recipe.ingredients[1]),
      4,
    );
    expect(
      child.recipe.steps.map((v) => v.toJson()).toList(),
      f.source.recipe.steps.map((v) => v.toJson()).toList(),
    );
    expect(child.parentKey, f.source.key);
    expect(child.ingredientChoiceReview!.selected.id, 'pepper');
    expect(RecipeRevision.fromJson(child.toJson()).toJson(), child.toJson());
    expect(jsonEncode(f.source.toJson()), before);
  });
  test('selection requires explicit acknowledgement, measured quantity and distinct identity', () async {
    final f = await compound.setup();
    expect(() => choose(f.source, ack: false), throwsArgumentError);
    expect(
      () => choose(
        f.source,
        selected: CatalogIngredient.fromJson({
          'id': 'other',
          'name': 'unknown',
          'scale': false,
        }),
      ),
      throwsArgumentError,
    );
    expect(
      () => choose(
        f.source,
        selected: CatalogIngredient.fromJson({
          'id': 'salt-pepper',
          'name': 'unresolved source',
          'amount': 1,
          'unit': 'g',
        }),
      ),
      throwsArgumentError,
    );
  });
  test('service saves atomically, reloads review and rejects altered duplicate retry', () async {
    final f = await compound.setup(), before = f.k.snapshot;
    Future<RecipeRevision> save({double amount = 2}) =>
        f.k.chooseRecipeIngredient(
          sourceRevisionKey: f.source.key,
          line: 1,
          selected: CatalogIngredient.fromJson({
            'id': 'pepper',
            'name': 'synthetic choice',
            'amount': amount,
            'unit': 'g',
          }),
          variantId: 'choice-personal',
          revision: 'v1',
          reviewNote: 'Synthetic explicit single replacement',
          reviewedAt: DateTime.utc(2026, 10, 14),
          acknowledgeCompleteReplacement: true,
        );
    f.store.fail = true;
    await expectLater(save(), throwsStateError);
    expect(f.k.snapshot, before);
    f.store.fail = false;
    final child = await save();
    expect((await save()).toJson(), child.toJson());
    final reload = KitchenService(f.store, f.k.recipes);
    await reload.load();
    expect(reload.recipeBook.revisions[child.key]!.toJson(), child.toJson());
    await expectLater(save(amount: 3), throwsStateError);
  });
  test('book rejects stale source, changed selected ingredient or unrelated recipe edits', () async {
    final f = await compound.setup(),
        child = choose(f.source),
        json = child.toJson();
    for (final edit in <void Function(Map<String, dynamic>)>[
      (j) {
        (j['ingredientChoiceReview'] as Map)['sourceSnapshotVersion'] = 'stale';
      },
      (j) {
        ((j['ingredientChoiceReview'] as Map)['selected'] as Map)['amount'] = 3;
      },
      (j) {
        (j['recipe'] as Map)['name'] = 'unreviewed change';
      },
      (j) {
        j['region'] = 'unreviewed region';
      },
      (j) {
        j['method'] = 'unreviewed method';
      },
    ]) {
      final changed = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
      edit(changed);
      expect(
        () => f.k.recipeBook.addRevision(RecipeRevision.fromJson(changed)),
        throwsFormatException,
      );
    }
  });
  test('old plans and bindings stay pinned; new choice gets no inherited nutrition', () async {
    final f = await compound.setup();
    await f.k.saveRecipeFoodSelection(fixture.selection(f.source));
    await f.k.plan(fixture.plan('old', 'fixture'));
    final child = choose(f.source);
    await f.k.saveRecipeRevision(child);
    await f.k.plan(fixture.plan('new', 'choice-personal'));
    expect((await f.k.recipeForMeal('old')).key, f.source.key);
    expect((await f.k.recipeForMeal('new')).key, child.key);
    expect(
      (await f.k.previewIngredientNutrition('old'))
          .whole[NutrientId.protein]!
          .knownSubtotal,
      20,
    );
    final fresh = await f.k.previewIngredientNutrition('new');
    expect(fresh.whole[NutrientId.protein]!.knownSubtotal, 0);
    expect(fresh.whole[NutrientId.protein]!.missing.length, 3);
    final newer = RecipeRevision(
      familyId: child.familyId,
      revision: 'v2',
      kind: RecipeRevisionKind.personal,
      parentKey: child.key,
      recipe: CatalogRecipe.fromJson({
        ...child.recipe.toJson(),
        'name': 'synthetic next revision',
      }),
    );
    await f.k.saveRecipeRevision(newer);
    await f.k.saveRecipeRevision(child);
    expect(f.k.recipeBook.active['choice-personal'], newer.key);
    expect((await f.k.recipeForMeal('new')).key, child.key);
  });
  test('completed history and prior inventory deduction stay frozen after a choice', () async {
    final f = await compound.setup();
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
    await f.k.saveRecipeRevision(choose(f.source));
    expect(jsonEncode(await f.k.confirmCooking('old', 'op')), frozen);
    expect(f.k.inventory.first.quantity, 800);
  });
  test('legacy books remain readable and split plus choice cannot certify one revision', () async {
    final f = await compound.setup(), legacy = f.k.recipeBook.toJson();
    for (final value in (legacy['revisions'] as Map).values) {
      (value as Map).remove('ingredientChoiceReview');
    }
    expect(
      RecipeBook.fromJson(legacy)
          .revisions[f.source.key]!
          .ingredientChoiceReview,
      isNull,
    );
    final child = choose(f.source), split = compound.split(f.source);
    expect(
      () => RecipeRevision.fromJson({
        ...child.toJson(),
        'ingredientSplitReview': split.ingredientSplitReview!.toJson(),
      }),
      throwsArgumentError,
    );
  });
}
