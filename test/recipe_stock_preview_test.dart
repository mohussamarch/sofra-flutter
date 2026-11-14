import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/recipe_stock_preview.dart';
import 'package:tabkha_demo/app/sofra_controller.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/models.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';

import 'recipe_variants_test.dart' as fixtures;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SofraController> controllerFor(CatalogRecipe recipe) async {
    final controller = SofraController(
      recipes: fixtures.repository(value: recipe),
      readAsset: (asset) => File(asset).readAsString(),
    );
    addTearDown(controller.dispose);
    await controller.load();
    await controller.updateProfile((profile) => profile.copyWith(servings: 2));
    return controller;
  }

  test(
    'discovery uses amounts, conversions and invalidates when stock changes',
    () async {
      final controller = await controllerFor(fixtures.recipe());
      await controller.kitchen.addStock(
        InventoryLot(
          id: 'lot',
          ingredientId: 'sample',
          quantity: .1,
          unit: 'kg',
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
      final firstVersion = controller.stockDiscoveryVersion;
      expect(controller.stockDiscoveryVersion, firstVersion);
      var previews = await controller.stockRecipePreviews();
      expect(previews['fixture']!.ready, isFalse);
      expect(previews['fixture']!.missing, 1);
      expect(previews['fixture']!.available, 1);
      await controller.setQuantity('lot', .2);
      expect(controller.stockDiscoveryVersion, isNot(firstVersion));
      previews = await controller.stockRecipePreviews();
      expect(previews['fixture']!.ready, isTrue);
      expect(controller.kitchen.inventory.single.quantity, .2);
      await controller.updateProfile(
        (profile) => profile.copyWith(servings: 4),
      );
      expect(
        (await controller.stockRecipePreviews())['fixture']!.ready,
        isFalse,
      );
    },
  );

  test('discovery allocates repeated ingredient stock only once', () async {
    final recipe = CatalogRecipe.fromJson({
      ...fixtures.recipe().toJson(),
      'ingredients': [
        {'id': 'sample', 'name': 'عينة', 'amount': 150, 'unit': 'g'},
        {'id': 'sample', 'name': 'عينة', 'amount': 150, 'unit': 'g'},
      ],
    });
    final controller = await controllerFor(recipe);
    await controller.kitchen.addStock(
      InventoryLot(
        id: 'lot',
        ingredientId: 'sample',
        quantity: 200,
        unit: 'g',
        zone: StorageZone.pantry,
      ),
      newPurchase: false,
    );
    final preview = (await controller.stockRecipePreviews())['fixture']!;
    expect(preview.ready, isFalse);
    expect(preview.missing, 1);
    expect(controller.kitchen.inventory.single.quantity, 200);
  });

  test('discovery leaves incompatible units unresolved', () async {
    final controller = await controllerFor(fixtures.recipe());
    await controller.kitchen.addStock(
      InventoryLot(
        id: 'lot',
        ingredientId: 'sample',
        quantity: 10,
        unit: 'count',
        zone: StorageZone.pantry,
      ),
      newPurchase: false,
    );
    final preview = (await controller.stockRecipePreviews())['fixture']!;
    expect(preview.ready, isFalse);
    expect(preview.unknown, 1);
    expect(preview.present, 1);
    expect(preview.available, 0);
  });

  test(
    'unmeasured stock presence stays discoverable without readiness',
    () async {
      final recipe = CatalogRecipe.fromJson({
        ...fixtures.recipe().toJson(),
        'ingredients': [
          {'id': 'sample', 'name': 'عينة', 'amount': null, 'scale': false},
        ],
      });
      final controller = await controllerFor(recipe);
      expect((await controller.stockRecipePreviews())['fixture']!.present, 0);
      await controller.kitchen.addStock(
        InventoryLot(
          id: 'lot',
          ingredientId: 'sample',
          quantity: null,
          unit: 'g',
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
      var preview = (await controller.stockRecipePreviews())['fixture']!;
      expect(preview.present, 1);
      expect(preview.available, 0);
      expect(preview.ready, isFalse);
      expect(preview.label, contains('غير محسومة'));
      await controller.setQuantity('lot', 0);
      preview = (await controller.stockRecipePreviews())['fixture']!;
      expect(preview.present, 0);
    },
  );

  test(
    'direct cooking persists the selected slot and rejects unknown slots',
    () async {
      final controller = await controllerFor(fixtures.recipe());
      for (final slot in ['breakfast', 'lunch', 'dinner']) {
        final meal = await controller.prepareCooking(
          'fixture',
          servings: 2,
          slot: slot,
        );
        expect(meal!.slot, slot);
        expect(controller.kitchen.plans.last.slot, slot);
      }
      await expectLater(
        controller.prepareCooking('fixture', servings: 2, slot: 'invalid'),
        throwsArgumentError,
      );
      expect(controller.kitchen.plans, hasLength(3));
    },
  );

  test(
    'personal yield changes discovery without altering catalog yield',
    () async {
      final recipe = CatalogRecipe.fromJson({
        ...fixtures.recipe().toJson(),
        'servings': null,
        'metadataPolicy': CatalogRecipe.unknownMetadataPolicy,
        'notes': 'Synthetic unknown yield fixture',
      });
      final controller = await controllerFor(recipe);
      await controller.kitchen.addStock(
        InventoryLot(
          id: 'lot',
          ingredientId: 'sample',
          quantity: 200,
          unit: 'g',
          zone: StorageZone.pantry,
        ),
        newPurchase: false,
      );
      expect(
        (await controller.stockRecipePreviews())['fixture']!.yieldKnown,
        isFalse,
      );
      final version = controller.stockDiscoveryVersion;
      expect(await controller.reviewYield('fixture', 2), isTrue);
      expect(controller.stockDiscoveryVersion, isNot(version));
      expect(
        (await controller.stockRecipePreviews())['fixture']!.ready,
        isTrue,
      );
      expect((await controller.recipes.get('fixture')).servings, isNull);
    },
  );

  RecipeStockPreview preview(List<LineStock> statuses) {
    final recipe = fixtures.recipe();
    return RecipeStockPreview.fromCheck(
      CookingCheck(recipe.forServings(2), [
        for (final status in statuses)
          CookingLine(
            0,
            recipe.ingredients.first,
            200,
            status,
            missing: status == LineStock.missing ? 100 : null,
          ),
      ]),
    );
  }

  test('only fully measured requirements can be ready', () {
    expect(preview([LineStock.inStock]).ready, isTrue);
    expect(preview([LineStock.missing]).ready, isFalse);
    expect(preview([LineStock.unmeasured]).ready, isFalse);
    expect(preview([LineStock.unresolved]).ready, isFalse);
    expect(preview([LineStock.optional]).ready, isFalse);
    expect(preview([]).ready, isFalse);
  });

  test('partial stock is not readiness and unknowns stay explicit', () {
    final partial = preview([
      LineStock.inStock,
      LineStock.missing,
      LineStock.unmeasured,
    ]);
    expect(partial.available, 2);
    expect(partial.missing, 1);
    expect(partial.unknown, 1);
    expect(partial.ready, isFalse);
    expect(partial.label, contains('غير محسومة'));
  });

  test('unknown yield never produces ready stock', () {
    const unknown = RecipeStockPreview.unknownYield(2);
    expect(unknown.ready, isFalse);
    expect(unknown.available, 2);
    expect(unknown.label, contains('الحصص'));
  });
}
