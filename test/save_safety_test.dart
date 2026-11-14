import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/sofra_controller.dart';
import 'package:tabkha_demo/data/state_store.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/models.dart';

/// A store shared by two "devices": each keeps the revision it loaded, as
/// the cloud store does, and a stale save is a conflict.
class Shared {
  Map<String, dynamic>? data;
  int revision = 0;
}

class Device implements StateStore {
  Device(this.shared);
  final Shared shared;
  int? seen;
  bool offline = false;
  int saves = 0;

  @override
  String get label => 'جهاز';

  @override
  Future<Map<String, dynamic>?> load() async {
    seen = shared.revision;
    return shared.data == null
        ? null
        : jsonDecode(jsonEncode(shared.data)) as Map<String, dynamic>;
  }

  @override
  Future<void> save(Map<String, dynamic> value) async {
    if (offline) throw StateError('offline');
    if (seen != shared.revision) throw StateConflict();
    saves++;
    shared.data = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
    seen = ++shared.revision;
  }
}

Future<SofraController> open(StateStore store) async {
  final c = SofraController(
    store: store,
    readAsset: (path) => File(path).readAsString(),
  );
  await c.load();
  return c;
}

double? amount(SofraController c, String id) => c.kitchen.inventory
    .where((l) => l.ingredientId == id)
    .map((l) => l.quantity)
    .fold<double?>(null, (a, q) => (a ?? 0) + (q ?? 0));

void main() {
  test('a later success does not hide an earlier failed save', () async {
    final device = Device(Shared());
    final c = await open(device);
    device.offline = true;
    expect(await c.addIngredient('rice', 1, 'kg', StorageZone.pantry), false);
    device.offline = false;
    expect(await c.addIngredient('eggs', 6, 'count', StorageZone.fridge), true);
    expect(c.saveError, isNotNull, reason: 'the rice is still unsaved');
    await c.retrySave();
    expect(c.saveError, isNull);
    expect(amount(c, 'rice'), 1);
    expect(amount(c, 'eggs'), 6);
  });

  test('two failed saves are both kept and retried in order', () async {
    final device = Device(Shared());
    final c = await open(device);
    device.offline = true;
    await c.addIngredient('rice', 1, 'kg', StorageZone.pantry);
    await c.addIngredient('rice', 2, 'kg', StorageZone.pantry);
    expect(c.saveError, contains('2'));
    device.offline = false;
    await c.retrySave();
    expect(c.saveError, isNull);
    expect(amount(c, 'rice'), 3);
  });

  test('quick repeated adds all count', () async {
    final c = await open(Device(Shared()));
    await Future.wait([
      for (var i = 0; i < 5; i++)
        c.addIngredient('eggs', 1, 'count', StorageZone.fridge),
    ]);
    expect(amount(c, 'eggs'), 5);
    expect(
      c.kitchen.inventory.where((l) => l.ingredientId == 'eggs').length,
      1,
    );
  });

  test('bought items go in one save; a retry does not log twice', () async {
    final device = Device(Shared());
    final c = await open(device);
    final rice = IngredientUse('rice', 2, 'kg');
    final eggs = IngredientUse('eggs', 12, 'count');
    device.offline = true;
    expect(await c.addBought([rice, eggs], paid: {rice: 80}), false);
    expect(c.kitchen.inventory, isEmpty, reason: 'all or none');
    device.offline = false;
    await c.retrySave();
    await c.retrySave();
    expect(amount(c, 'rice'), 2);
    expect(amount(c, 'eggs'), 12);
    expect(((c.kitchen.snapshot['purchases']) as List).length, 1);
  });

  test(
    'a change saved from another device is loaded, then ours applied',
    () async {
      final shared = Shared();
      final a = await open(Device(shared));
      final b = await open(Device(shared));
      expect(await a.addIngredient('rice', 1, 'kg', StorageZone.pantry), true);
      expect(await b.addIngredient('rice', 2, 'kg', StorageZone.pantry), true);
      expect(b.saveError, isNull);
      expect(amount(b, 'rice'), 3, reason: 'both additions are kept');
    },
  );
}
