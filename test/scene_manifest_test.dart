import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/scene/id_mask.dart';
import 'package:tabkha_demo/scene/scene_lighting.dart';
import 'package:tabkha_demo/scene/scene_manifest.dart';

const _sha = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

Map<String, dynamic> manifest() => {
  'schema': 'sofra.scene/1',
  'sceneId': 'kitchen',
  'revision': 'test',
  'approved': false,
  'canvas': {'width': 1440, 'height': 1440},
  'lightingModes': [
    {'id': 'morning', 'image': 'm.webp'},
    {'id': 'night', 'image': 'n.webp'},
  ],
  'idMask': 'id.png',
  'hotspots': [
    {
      'id': 'fridge',
      'color': '#FF0000',
      'bounds': [900, 450, 300, 480],
    },
    {
      'id': 'pantry',
      'color': '#0000FF',
      'bounds': [200, 480, 180, 440],
    },
  ],
  'masks': {
    'beam': {'morning': 'beam.png'},
  },
  'points': {
    'ceilingLamp': [720, 465.5],
  },
  'doors': [
    {
      'id': 'fridge',
      'hotspot': 'fridge',
      'rect': [844, 447, 411, 540],
      'framesByMode': {
        'morning': ['d0.webp', 'd1.webp'],
      },
    },
  ],
  'files': [
    for (final f in [
      'm.webp',
      'n.webp',
      'id.png',
      'beam.png',
      'd0.webp',
      'd1.webp',
    ])
      {'path': f, 'bytes': 10, 'sha256': _sha},
  ],
};

List<String> problems(Map<String, dynamic> json) {
  try {
    SceneManifest.fromJson(json);
    return const [];
  } on SceneManifestException catch (e) {
    return e.problems;
  }
}

void main() {
  group('SceneManifest', () {
    test('parses a valid manifest', () {
      final m = SceneManifest.fromJson(manifest());
      expect(m.modeIds, ['morning', 'night']);
      expect(m.hotspot('fridge')!.color, const Color(0xFFFF0000));
      expect(m.doorFor('fridge')!.frameCount, 2);
      expect(m.doorFor('fridge')!.framesFor('night'), ['d0.webp', 'd1.webp']);
      expect(m.points['ceilingLamp'], const Offset(720, 465.5));
      expect(m.referencedPaths, hasLength(6));
    });

    test('collects every violation at once', () {
      final json = manifest()
        ..['schema'] = 'sofra.scene/2'
        ..['idMask'] = '../escape.png';
      (json['hotspots'] as List).add({
        'id': 'garage',
        'color': '#FF0000',
        'bounds': [1400, 0, 100, 10],
      });
      final found = problems(json);
      expect(found, contains(startsWith('schema')));
      expect(found, contains(startsWith('idMask must be a relative path')));
      expect(found, contains('unknown hotspot id "garage"'));
      expect(found, contains(startsWith('duplicate hotspot color')));
      expect(found, contains(contains('outside the canvas')));
    });

    test('rejects unlisted files, black hotspots and bad door frames', () {
      final json = manifest();
      (json['files'] as List).removeWhere((f) => f['path'] == 'n.webp');
      (json['hotspots'] as List)[1]['color'] = '#000000';
      final door = (json['doors'] as List).single as Map<String, dynamic>;
      door['framesByMode'] = {
        'morning': ['d0.webp', 'd1.webp'],
        'night': ['d0.webp'],
        'noon': ['d0.webp', 'd1.webp'],
      };
      final found = problems(json);
      expect(found, contains('n.webp is referenced but missing from files'));
      expect(found, contains('hotspot pantry must not be black'));
      expect(found, contains('door fridge/night needs 2..24 frames'));
      expect(found, contains('door fridge: unknown mode noon'));
    });

    test('rejects canvas outside the supported range', () {
      final json = manifest()..['canvas'] = {'width': 512, 'height': 512};
      expect(problems(json), contains(startsWith('canvas must be')));
    });
  });

  group('IdMask', () {
    // 4×3 mask: red at (1,1) and (2,1), blue at (3,2).
    IdMask mask() {
      final rgba = Uint8List(4 * 3 * 4);
      void put(int x, int y, int r, int g, int b) {
        final p = (y * 4 + x) * 4;
        rgba
          ..[p] = r
          ..[p + 1] = g
          ..[p + 2] = b
          ..[p + 3] = 255;
      }

      put(1, 1, 255, 0, 0);
      put(2, 1, 255, 0, 0);
      put(3, 2, 0, 0, 255);
      return IdMask.fromRgba(4, 3, rgba, {
        0xFFFF0000: 'fridge',
        0xFF0000FF: 'pantry',
      });
    }

    test('hits exact pixels and ignores empty space', () {
      final m = mask();
      expect(m.hitTest(const Offset(1.5, 1.2)), 'fridge');
      expect(m.hitTest(const Offset(3.9, 2.9)), 'pantry');
      expect(m.hitTest(const Offset(0.5, 0.5)), isNull);
      expect(m.hitTest(const Offset(-5, 99)), isNull);
    });

    test('slop finds the nearest hotspot', () {
      final m = mask();
      expect(m.hitTest(const Offset(0.5, 0.5), slop: 1.5), 'fridge');
      expect(m.hitTest(const Offset(3.5, 0.5), slop: 1), isNull);
      expect(m.hitTest(const Offset(3.5, 0.5), slop: 1.5), 'fridge');
    });

    test('rejects colours outside the palette', () {
      final rgba = Uint8List(4)..[1] = 9;
      expect(
        () => IdMask.fromRgba(1, 1, rgba, {0xFFFF0000: 'fridge'}),
        throwsFormatException,
      );
    });

    test('silhouette marks only the hotspot', () {
      final s = mask().silhouette('fridge', 1, 1, 3, 1);
      expect([s[3], s[7], s[11]], [255, 255, 0]);
    });
  });

  group('LightingSchedule', () {
    final schedule = LightingSchedule.provisional();
    double w(Map<String, double> m, String k) => m[k] ?? 0;

    test('holds a single mode between transitions', () {
      expect(schedule.weightsAt(12 * 60), {'morning': 1.0});
      expect(schedule.weightsAt(23 * 60), {'night': 1.0});
      expect(schedule.weightsAt(2 * 60), {'night': 1.0});
      expect(schedule.weightsAt(17.5 * 60), {'golden': 1.0});
    });

    test('cross-fades smoothly around a change, summing to one', () {
      final change = 18 * 60 + 30.0;
      final start = schedule.weightsAt(change - 22.4);
      final mid = schedule.weightsAt(change);
      final end = schedule.weightsAt(change + 22.4);
      expect(w(start, 'golden'), greaterThan(.99));
      expect(w(mid, 'golden'), closeTo(.5, 1e-9));
      expect(w(mid, 'night'), closeTo(.5, 1e-9));
      expect(w(end, 'night'), greaterThan(.99));
      for (var m = change - 30; m <= change + 30; m += 1.7) {
        final weights = schedule.weightsAt(m);
        expect(weights.values.reduce((a, b) => a + b), closeTo(1, 1e-9));
        expect(weights.length, lessThanOrEqualTo(2));
      }
    });

    test('wraps across midnight', () {
      final s = LightingSchedule(const [
        LightingKey(0, 'night'),
        LightingKey(12 * 60, 'morning'),
      ], transitionMinutes: 60);
      final atMidnight = s.weightsAt(0);
      expect(w(atMidnight, 'night'), closeTo(.5, 1e-9));
      expect(w(s.weightsAt(1439.9), 'morning'), greaterThan(.4));
    });

    test('restricts to the modes a pack provides', () {
      final s = schedule.restrictTo(['morning', 'night']);
      expect(s.keys.map((k) => k.mode), ['morning', 'night']);
      expect(s.weightsAt(3 * 60), {'night': 1.0});
      expect(
        LightingSchedule.provisional().restrictTo(['night']).weightsAt(9 * 60),
        {'night': 1.0},
      );
    });

    test('rejects modes shorter than the fade', () {
      expect(
        () => LightingSchedule(const [
          LightingKey(0, 'night'),
          LightingKey(10, 'morning'),
        ]),
        throwsArgumentError,
      );
    });
  });
}
