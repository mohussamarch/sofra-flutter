import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/scene/kitchen_scene.dart';
import 'package:tabkha_demo/scene/scene_assets.dart';
import 'package:tabkha_demo/scene/scene_manifest.dart';

const _manifestPath = 'assets/scenes/kitchen/manifest.json';

void main() {
  group('kitchen scene pack honours docs/SCENE-CONTRACT.md', () {
    final json = jsonDecode(
      File(_manifestPath).readAsStringSync(),
    ) as Map<String, dynamic>;
    final manifest = SceneManifest.fromJson(json);
    final dir = File(_manifestPath).parent.path;

    test('every listed file exists with matching size and sha256', () {
      for (final f in manifest.files) {
        final file = File('$dir/${f.path}');
        expect(file.existsSync(), isTrue, reason: f.path);
        final bytes = file.readAsBytesSync();
        expect(bytes.length, f.bytes, reason: f.path);
        expect(sha256.convert(bytes).toString(), f.sha256, reason: f.path);
      }
    });

    test('stays within the contract size budget', () {
      final total = manifest.files.fold<int>(0, (s, f) => s + f.bytes);
      expect(total, lessThan(4 * 1024 * 1024));
      for (final m in manifest.lightingModes) {
        final f = manifest.files.firstWhere((f) => f.path == m.image);
        expect(f.bytes, lessThan(400 * 1024), reason: m.image);
      }
    });

    test('every asset folder is declared in pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final folders = {
        for (final f in manifest.files)
          '$dir/${f.path}'.substring(0, '$dir/${f.path}'.lastIndexOf('/') + 1),
      };
      for (final folder in folders) {
        expect(pubspec, contains('- $folder'), reason: folder);
      }
    });
  });

  testWidgets('loads the pack, opens and closes the fridge', (tester) async {
    final scene = (await tester.runAsync(
      () => LoadedScene.load(rootBundle, _manifestPath),
    ))!;
    addTearDown(scene.dispose);
    expect(scene.bases.keys, ['morning', 'golden', 'night']);
    expect(
      scene.idMask.hitTest(scene.manifest.hotspot('fridge')!.bounds.center),
      'fridge',
    );

    final controller = KitchenSceneController();
    addTearDown(controller.dispose);
    final opened = <String>[], closed = <String>[], taps = <String>[];
    await tester.binding.setSurfaceSize(const Size(412, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(412, 900)),
        child: KitchenScene(
          scene: scene,
          controller: controller,
          minuteOfDay: 10 * 60,
          ambience: false,
          onHotspotTap: taps.add,
          onDoorOpened: opened.add,
          onDoorClosed: closed.add,
        ),
      ),
    );

    // Canvas 1440 fits 412 wide, vertically centred in 900.
    const scale = 412 / 1440;
    final fridge = scene.manifest.hotspot('fridge')!.bounds.center;
    final pantry = scene.manifest.hotspot('pantry')!.bounds.center;
    Offset toScreen(Offset p) =>
        Offset(p.dx * scale, (900 - 1440 * scale) / 2 + p.dy * scale);

    await tester.tapAt(toScreen(pantry));
    await tester.pump();
    expect(taps, ['pantry']);
    expect(controller.phase, DoorPhase.closed);

    await tester.tapAt(toScreen(fridge));
    await tester.pump();
    expect(controller.phase, DoorPhase.zoomingIn);
    await tester.tapAt(toScreen(pantry)); // ignored while busy
    await tester.pumpAndSettle();
    expect(controller.phase, DoorPhase.open);
    expect(opened, ['fridge']);
    expect(taps, ['pantry', 'fridge']);

    expect(controller.close(), isTrue);
    expect(controller.close(), isFalse);
    await tester.pumpAndSettle();
    expect(controller.phase, DoorPhase.closed);
    expect(closed, ['fridge']);
  });
}
