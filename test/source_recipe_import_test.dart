import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/domain/imported_recipe_candidate.dart';
import 'package:tabkha_demo/domain/recipe_variants.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';

import 'recipe_variants_test.dart' as fixture;

Future<ImportedRecipeCandidate> readCandidate([
  List<String> flags = const [],
]) async {
  final p = await Process.run(Platform.environment['SOFRA_NODE'] ?? 'node', [
    'tool/recipes/runtime-adapter.emit-fixture.mjs',
    '--transport',
    ...flags,
  ]);
  expect(p.exitCode, 0, reason: '${p.stderr}');
  final j = jsonDecode(p.stdout as String) as Map<String, dynamic>;
  return ImportedRecipeCandidate.fromTransport(
    j,
    expectedSha256: j['sha256'] as String,
  );
}

Future<RecipeRevision> save(
  KitchenService k,
  ImportedRecipeCandidate c, {
  String note = 'Explicit synthetic source/license/instruction review',
  bool sourceAck = true,
  bool nutritionAck = true,
}) => k.importSourceRecipe(
  candidate: c,
  reviewNote: note,
  reviewedAt: DateTime.utc(2026, 10, 14),
  acknowledgeSourceLicenseAndInstructions: sourceAck,
  acknowledgeNutritionUnreviewed: nutritionAck,
);

void main() {
  late ImportedRecipeCandidate first, second;
  setUpAll(() async {
    first = await readCandidate();
    second = await readCandidate(['--second']);
  });
  test('import persists complete source envelope/review with immutable root and no nutrition bindings', () async {
    final store = fixture.Store();
    final service = KitchenService(store, fixture.repository());
    await service.load();
    final revision = await save(service, first);
    expect(revision.kind, RecipeRevisionKind.imported);
    expect(revision.parentKey, isNull);
    expect(revision.sourceImportReview!.candidate.provenance, first.provenance);
    expect(service.recipeBook.families.length, 1);
    expect(service.inventory, isEmpty);
    expect(service.plans, isEmpty);
    expect(service.snapshot['nutrition'], isNull);
    final reload = KitchenService(store, fixture.repository());
    await reload.load();
    expect(
      reload.recipeBook.revisions[revision.key]!.toJson(),
      revision.toJson(),
    );
    final altered = revision.sourceImportReview!.toJson();
    (altered['candidate'] as Map).clear();
    expect(revision.sourceImportReview!.candidate.recipe.id, first.recipe.id);
    await expectLater(service.saveRecipeRevision(revision), throwsStateError);
  });
  test('failed import save rolls back family/revisions and retry preserves newer active choice', () async {
    final store = fixture.Store();
    final service = KitchenService(store, fixture.repository());
    await service.load();
    store.fail = true;
    await expectLater(save(service, first), throwsStateError);
    expect(service.recipeBook.revisions, isEmpty);
    expect(service.recipeBook.families, isEmpty);
    store.fail = false;
    final old = await save(service, first);
    final newer = await save(service, second);
    await save(service, first);
    expect(service.recipeBook.active[first.recipe.id], newer.key);
    await expectLater(
      save(service, first, note: 'Changed evidence for same immutable key'),
      throwsStateError,
    );
    expect(service.recipeBook.revisions.length, 2);
    expect(
      service.recipeBook.revisions[old.key]!.recipe.ingredients.first.amount,
      100,
    );
  });
  test('explicit source/license/instructions and unknown nutrition acknowledgements required before state changes', () async {
    final k = KitchenService(fixture.Store(), fixture.repository());
    await k.load();
    await expectLater(save(k, first, sourceAck: false), throwsArgumentError);
    await expectLater(save(k, first, nutritionAck: false), throwsArgumentError);
    await expectLater(save(k, first, note: ''), throwsArgumentError);
    expect(k.recipeBook.revisions, isEmpty);
  });
  test('full candidate/recipe/family/version guards reject tampering and legacy books stay readable', () async {
    final k = KitchenService(fixture.Store(), fixture.repository());
    await k.load();
    final imported = await save(k, first);
    for (final edit in <void Function(Map<String, dynamic>)>[
      (j) => (j['recipe'] as Map)['name'] = 'Unreviewed name',
      (j) => (j['recipe'] as Map)['ingredients'][0]['amount'] = 99,
      (j) => j['familyId'] = 'other-family',
      (j) => j['revision'] = 'arbitrary-version',
      (j) => j['sourceImportReview'] = null,
      (j) => j['parentKey'] = 'other-parent',
    ]) {
      final changed =
          jsonDecode(jsonEncode(imported.toJson())) as Map<String, dynamic>;
      edit(changed);
      expect(
        () => RecipeRevision.fromJson(changed),
        throwsA(anyOf(isA<ArgumentError>(), isA<FormatException>())),
      );
    }
    final base = RecipeRevision(
      familyId: 'family',
      revision: 'v1',
      kind: RecipeRevisionKind.catalog,
      recipe: fixture.recipe(),
    );
    final legacy = base.toJson()..remove('sourceImportReview');
    expect(RecipeRevision.fromJson(legacy).sourceImportReview, isNull);
  });
  test('old plans, confirmed history and inventory deductions remain frozen after importing a new revision', () async {
    final k = KitchenService(fixture.Store(), fixture.repository());
    await k.load();
    final old = await save(k, first);
    await k.plan(fixture.plan('old', old.variantId));
    for (final pair in [('flour', 'g'), ('water', 'ml')]) {
      await k.addStock(
        InventoryLot(
          id: pair.$1,
          ingredientId: pair.$1,
          quantity: 1000,
          unit: pair.$2,
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
    }
    final history = await k.confirmCooking('old', 'one-operation');
    final frozen = jsonEncode(history);
    final newer = await save(k, second);
    expect((await k.recipeForMeal('old')).key, old.key);
    expect(jsonEncode(await k.confirmCooking('old', 'one-operation')), frozen);
    expect(k.inventory.map((l) => l.quantity), [900, 800]);
    await k.plan(fixture.plan('new', newer.variantId));
    expect((await k.recipeForMeal('new')).key, newer.key);
    final nutrition = await k.previewIngredientNutrition('new');
    expect(nutrition.whole[NutrientId.protein]!.missing.length, 2);
    expect(nutrition.whole[NutrientId.protein]!.complete, false);
  });
  test('explicit runtime food binding uses existing calculator only for its imported revision', () async {
    final k = KitchenService(fixture.Store(), fixture.repository());
    await k.load();
    final old = await save(k, first);
    await k.saveRecipeFoodSelection(fixture.selection(old));
    await k.plan(fixture.plan('bound-old', old.variantId));
    final bound = await k.previewIngredientNutrition('bound-old');
    expect(bound.whole[NutrientId.protein]!.knownSubtotal, 10);
    expect(bound.whole[NutrientId.protein]!.missing.length, 1);
    final next = await save(k, second);
    await k.plan(fixture.plan('unbound-new', next.variantId));
    final unbound = await k.previewIngredientNutrition('unbound-new');
    expect(unbound.whole[NutrientId.protein]!.knownSubtotal, 0);
    expect(unbound.whole[NutrientId.protein]!.missing.length, 2);
    expect((await k.recipeForMeal('bound-old')).key, old.key);
  });

  test('850KB import guard does not partially save source evidence or alter existing revisions', () async {
    final store = fixture.Store(),
        k = KitchenService(store, fixture.repository());
    await k.load();
    final old = await save(k, first);
    final large = await readCandidate(['--large']);
    await expectLater(save(k, large), throwsStateError);
    expect(k.recipeBook.revisions.length, 1);
    expect(k.recipeBook.active[first.recipe.id], old.key);
    final reload = KitchenService(store, fixture.repository());
    await reload.load();
    expect(reload.recipeBook.revisions.length, 1);
  });
}
