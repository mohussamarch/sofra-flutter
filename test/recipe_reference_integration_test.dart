import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tabkha_demo/data/recipe_reference_repository.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';
import 'package:tabkha_demo/domain/recipe_variants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/kitchen_service.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/recipe_nutrition.dart';

import 'recipe_variants_test.dart' as fixture;

Map<String, dynamic> entry(RecipeRevision r) => {
  'recipeId': r.variantId,
  'line': 0,
  'ingredientId': r.recipe.ingredients[0].id,
  'expectedName': r.recipe.ingredients[0].name,
  'recipeSnapshotVersion': recipeSnapshotVersion(r.recipe),
  'recipeSourceSha256': 'a' * 64,
  'recipeSourceFile': 'synthetic-test.json',
  'requiresUserChoice': false,
  'blocked': false,
  'issues': <String>[],
  'candidates': [
    {
      'foodId': 'usda:170000',
      'form': 'raw',
      'sourceDescription': 'Onions, raw',
      'sourceVersion': '2018-04',
      'rationale': 'Synthetic identity fixture, not a real recipe review',
    },
  ],
};
RecipeReferenceRepository references(List<Map<String, dynamic>> entries) =>
    RecipeReferenceRepository(
      read: (p) async => p.endsWith('recipe-reference-review.json')
          ? jsonEncode({
              'schemaVersion': 1,
              'reviewedDate': '2026-10-13',
              'entries': entries,
            })
          : File(p).readAsString(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'ingredient estimate cannot pretend to be prepared nutrition or intake',
    () async {
      final service = KitchenService(fixture.Store(), fixture.repository());
      await service.load();
      final revision = await service.catalogRevision('fixture');
      await service.saveRecipeFoodSelection(
        RecipeFoodSelection.fromJson({
          ...fixture.selection(revision).toJson(),
          'preparedForm': 'cooked',
        }),
      );
      await service.plan(fixture.plan('meal', 'fixture'));
      final before = service.snapshot;
      final prepared = await service.previewNutrition('meal');
      expect(prepared.whole[NutrientId.protein]!.value, isNull);
      final dynamic input = await (service as dynamic)
          .previewIngredientNutrition('meal');
      expect(input.basis, 'ingredientInput');
      expect(input.whole[NutrientId.protein].value, 20);
      expect(input.perPortion[NutrientId.protein].value, 10);
      expect(input.whole[NutrientId.fibre].value, isNull);
      expect(service.snapshot, before);
      expect(
        (await service.previewNutrition('meal'))
            .whole[NutrientId.protein]!
            .value,
        isNull,
      );
    },
  );
  test('reference acceptance is explicit; stale snapshots and invalid choices fail', () async {
    final k = KitchenService(fixture.Store(), fixture.repository());
    await k.load();
    final revision = await k.catalogRevision('fixture');
    final repo = references([entry(revision)]);
    await expectLater(
      repo.resolve(revision, acknowledgeGenericReferences: false),
      throwsArgumentError,
    );
    final accepted = await repo.resolve(
      revision,
      acknowledgeGenericReferences: true,
    );
    expect(accepted.selections.single.recipeRevisionKey, revision.key);
    expect(accepted.selections.single.referenceReviewId, isNotEmpty);
    final changed = RecipeRevision(
      familyId: revision.familyId,
      revision: 'changed',
      kind: RecipeRevisionKind.variant,
      recipe: fixture.recipe(amount: 300),
    );
    await expectLater(
      repo.resolve(changed, acknowledgeGenericReferences: true),
      throwsStateError,
    );
    await expectLater(
      repo.resolve(
        revision,
        acknowledgeGenericReferences: true,
        choices: {0: 'not-a-food'},
      ),
      throwsArgumentError,
    );
    await expectLater(
      references([entry(revision), entry(revision)])
          .resolve(revision, acknowledgeGenericReferences: true),
      throwsFormatException,
    );
    final staleFood = entry(revision);
    (staleFood['candidates'] as List)[0]['sourceVersion'] = 'wrong';
    await expectLater(
      references([staleFood])
          .resolve(revision, acknowledgeGenericReferences: true),
      throwsStateError,
    );
  });

  test(
    'ambiguous choices and compound rows cannot silently become one food',
    () async {
      final k = KitchenService(fixture.Store(), fixture.repository());
      await k.load();
      final revision = await k.catalogRevision('fixture');
      final ambiguous = {...entry(revision), 'requiresUserChoice': true};
      expect(
        (await references([
          ambiguous,
        ]).resolve(revision, acknowledgeGenericReferences: true)).selections,
        isEmpty,
      );
      expect(
        (await references([ambiguous]).resolve(
          revision,
          acknowledgeGenericReferences: true,
          choices: {0: 'usda:170000'},
        )).selections,
        hasLength(1),
      );
      final blocked = {...ambiguous, 'blocked': true};
      expect(
        (await references([
          blocked,
        ]).resolve(revision, acknowledgeGenericReferences: true)).selections,
        isEmpty,
      );
      await expectLater(
        references([blocked]).resolve(
          revision,
          acknowledgeGenericReferences: true,
          choices: {0: 'usda:170000'},
        ),
        throwsArgumentError,
      );
    },
  );

  test('reference application preserves user selections and rolls back failed saves', () async {
    final store = fixture.Store(),
        k = KitchenService(fixture.Store(), fixture.repository());
    final service = KitchenService(store, fixture.repository());
    await service.load();
    final revision = await service.catalogRevision('fixture');
    await service.plan(fixture.plan('meal', 'fixture'));
    await service.saveRecipeFoodSelection(fixture.selection(revision));
    final repo = references([entry(revision)]);
    final kept = await service.applyRecipeReferences(
      'meal',
      repo,
      acknowledgeGenericReferences: true,
    );
    expect(kept.preservedLines, [0]);
    expect(kept.appliedLines, isEmpty);
    expect(
      (await service.previewNutrition('meal')).whole[NutrientId.protein]!.value,
      20,
    );
    final before = service.snapshot;
    store.fail = true;
    await expectLater(
      service.applyRecipeReferences(
        'meal',
        repo,
        acknowledgeGenericReferences: true,
        replaceExisting: true,
      ),
      throwsStateError,
    );
    expect(service.snapshot, before);
    store.fail = false;
    final saved = await service.applyRecipeReferences(
      'meal',
      repo,
      acknowledgeGenericReferences: true,
      replaceExisting: true,
    );
    expect(saved.appliedLines, [0]);
    expect(
      (await service.previewNutrition('meal')).whole[NutrientId.protein]!.value,
      isNull,
    );
    final restored = KitchenService(store, fixture.repository());
    await restored.load();
    expect(restored.snapshot, service.snapshot);
    expect(
      (await restored.previewIngredientNutrition('meal'))
          .whole[NutrientId.protein]!
          .value,
      isNotNull,
    );
    await k.load(); // independent owner cannot see another store's selections
    expect(k.snapshot['nutrition'], isNull);
  });

  test(
    'quantity form remains explicit and missing measures stay unknown',
    () async {
      final k = KitchenService(fixture.Store(), fixture.repository());
      await k.load();
      final r = await k.catalogRevision('fixture');
      await k.plan(fixture.plan('meal', 'fixture'));
      await k.saveRecipeFoodSelection(
        RecipeFoodSelection.fromJson({
          ...fixture.selection(r).toJson(),
          'amountForm': 'cooked',
          'preparedForm': 'cooked',
        }),
      );
      expect(
        (await k.previewIngredientNutrition('meal'))
            .whole[NutrientId.protein]!
            .value,
        isNull,
      );
    },
  );

  test(
    'shipped bechamel proposals bind only accepted references with honest gaps',
    () async {
      Future<String> read(String p) => File(p).readAsString();
      final k = KitchenService(fixture.Store(), RecipeRepository(read: read));
      await k.load();
      await k.plan(fixture.plan('bechamel', 'eg-bechamel-pasta'));
      final repo = RecipeReferenceRepository(read: read),
          revision = await k.recipeForMeal('bechamel');
      final proposed = await repo.reviewFor(revision);
      expect(proposed, hasLength(10));
      final minimal = await k.applyRecipeReferences(
        'bechamel',
        repo,
        acknowledgeGenericReferences: true,
      );
      expect(minimal.appliedLines, [
        2,
        7,
      ]); // optional nutmeg is stored, not included automatically
      final accepted = await k.applyRecipeReferences(
        'bechamel',
        repo,
        acknowledgeGenericReferences: true,
        choices: {0: 'usda:168927', 1: 'usda:171790'},
      );
      expect(accepted.appliedLines, [0, 1]);
      expect(accepted.preservedLines, [2, 7]);
      final input = await k.previewIngredientNutrition('bechamel');
      expect(input.whole[NutrientId.protein]!.knownSubtotal, greaterThan(0));
      expect(
        input.whole[NutrientId.protein]!.value,
        isNull,
      ); // onions unweighed, other required rows unbound
      expect(
        input.whole[NutrientId.protein]!.missing.any(
          (v) => v.reason == NutrientGapReason.incompatibleUnit,
        ),
        isTrue,
      );
      expect(
        (await k.previewNutrition('bechamel')).whole[NutrientId.protein]!.value,
        isNull,
      );
      await expectLater(
        k.applyRecipeReferences(
          'bechamel',
          repo,
          acknowledgeGenericReferences: true,
          choices: {9: 'usda:173468'},
        ),
        throwsArgumentError,
      );
      expect(k.snapshot['history'], isEmpty);
    },
  );
  test('choices are captured before asynchronous metadata loading', () async {
    final k = KitchenService(fixture.Store(), fixture.repository());
    await k.load();
    final r = await k.catalogRevision('fixture');
    final gate = Completer<String>();
    final repo = RecipeReferenceRepository(
      read: (p) => p.endsWith('recipe-reference-review.json')
          ? gate.future
          : File(p).readAsString(),
    );
    final choices = <int, String>{0: 'usda:170000'};
    final pending = repo.resolve(
      r,
      acknowledgeGenericReferences: true,
      choices: choices,
    );
    choices[0] = 'not-a-food';
    gate.complete(
      jsonEncode({
        'schemaVersion': 1,
        'reviewedDate': '2026-10-13',
        'entries': [entry(r)],
      }),
    );
    expect((await pending).selections.single.food.id, 'usda:170000');
  });

  test(
    'all shipped proposals match current immutable recipe snapshots',
    () async {
      Future<String> read(String p) => File(p).readAsString();
      final recipes = await RecipeRepository(read: read).loadAll();
      final repo = RecipeReferenceRepository(read: read);
      var count = 0, covered = 0;
      for (final recipe in recipes) {
        final revision = RecipeRevision(
          familyId: 'dish:${recipe.id}',
          revision: recipeSnapshotVersion(recipe),
          kind: RecipeRevisionKind.catalog,
          recipe: recipe,
        );
        final entries = await repo.reviewFor(revision);
        count += entries.length;
        if (entries.isNotEmpty) covered++;
      }
      expect(count, 197);
      expect(covered, 53);
    },
  );

  test(
    'changed plan during reference loading cannot receive old bindings',
    () async {
      final service = KitchenService(fixture.Store(), fixture.repository());
      await service.load();
      final old = await service.catalogRevision('fixture');
      await service.plan(fixture.plan('meal', 'fixture'));
      final gate = Completer<String>(), entered = Completer<void>();
      final repo = RecipeReferenceRepository(
        read: (p) {
          if (p.endsWith('recipe-reference-review.json')) {
            entered.complete();
            return gate.future;
          }
          return File(p).readAsString();
        },
      );
      final pending = service.applyRecipeReferences(
        'meal',
        repo,
        acknowledgeGenericReferences: true,
      );
      await entered.future;
      final changed = fixture.custom(old, 'changed', 300);
      await service.saveRecipeRevision(changed);
      await service.plan(
        fixture.plan('meal', changed.variantId, key: changed.key),
      );
      final before = service.snapshot;
      final check = expectLater(pending, throwsStateError);
      gate.complete(
        jsonEncode({
          'schemaVersion': 1,
          'reviewedDate': '2026-10-13',
          'entries': [entry(old)],
        }),
      );
      await check;
      expect(service.snapshot, before);
    },
  );
}
