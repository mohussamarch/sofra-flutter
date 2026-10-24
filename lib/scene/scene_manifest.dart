import 'dart:ui' show Color, Offset, Rect, Size;

/// Parsed `sofra.scene/1` manifest; contract in docs/SCENE-CONTRACT.md.
/// Paths are resolved against the manifest directory; all coordinates are
/// canvas pixels with a top-left origin.
class SceneManifest {
  SceneManifest._({
    required this.sceneId,
    required this.revision,
    required this.approved,
    required this.canvas,
    required this.lightingModes,
    required this.idMask,
    required this.hotspots,
    required this.windowMask,
    required this.beamMasks,
    required this.points,
    required this.rects,
    required this.doors,
    required this.details,
    required this.files,
  });

  static const schema = 'sofra.scene/1';
  static const knownHotspots = {
    'fridge',
    'freezer',
    'pantry',
    'stove',
    'sink',
    'window',
    'shelves',
  };

  final String sceneId, revision;
  final bool approved;
  final Size canvas;
  final List<LightingMode> lightingModes;
  final String idMask;
  final List<SceneHotspot> hotspots;
  final String? windowMask;
  final Map<String, String> beamMasks;
  final Map<String, Offset> points;
  final Map<String, Rect> rects;
  final List<SceneDoor> doors;
  final List<SceneDetail> details;
  final List<SceneFile> files;

  Iterable<String> get modeIds => lightingModes.map((m) => m.id);
  SceneHotspot? hotspot(String id) =>
      hotspots.where((h) => h.id == id).firstOrNull;
  SceneDoor? doorFor(String hotspotId) =>
      doors.where((d) => d.hotspot == hotspotId).firstOrNull;

  /// Every image path the manifest references, in a stable order.
  Set<String> get referencedPaths => {
    ...lightingModes.map((m) => m.image),
    idMask,
    ?windowMask,
    ...beamMasks.values,
    for (final d in doors) ...d.framesByMode.values.expand((f) => f),
    for (final d in details) ...d.imagesByMode.values,
  };

  /// Throws [SceneManifestException] listing every violation found.
  factory SceneManifest.fromJson(Map<String, dynamic> json) {
    final p = _Parser();
    if (json['schema'] != schema) {
      p.fail('schema must be "$schema", got ${json['schema']}');
    }
    final sceneId = p.string(json, 'sceneId');
    final revision = p.string(json, 'revision');
    final approved = json['approved'] is bool
        ? json['approved'] as bool
        : p.fail<bool>('approved must be a boolean', false);

    final canvasJson = p.map(json, 'canvas');
    final canvas = Size(
      p.number(canvasJson, 'width', positive: true),
      p.number(canvasJson, 'height', positive: true),
    );
    if (canvas.width < 1080 ||
        canvas.width > 2048 ||
        canvas.height < 1080 ||
        canvas.height > 2048) {
      p.fail('canvas must be 1080..2048 px per side, got $canvas');
    }

    final modes = <LightingMode>[];
    for (final m in p.list(json, 'lightingModes')) {
      if (m is! Map<String, dynamic>) {
        p.fail('lightingModes entries must be objects');
        continue;
      }
      modes.add(LightingMode(p.string(m, 'id'), p.path(m, 'image')));
    }
    if (modes.isEmpty || modes.length > 8) {
      p.fail('lightingModes must have 1..8 entries');
    }
    p.unique(modes.map((m) => m.id), 'lightingModes id');
    final modeIds = modes.map((m) => m.id).toSet();

    final idMask = p.path(json, 'idMask');

    final hotspots = <SceneHotspot>[];
    for (final h in p.list(json, 'hotspots')) {
      if (h is! Map<String, dynamic>) {
        p.fail('hotspots entries must be objects');
        continue;
      }
      final id = p.string(h, 'id');
      if (!knownHotspots.contains(id)) p.fail('unknown hotspot id "$id"');
      final color = p.color(h, 'color');
      if (color == 0xFF000000) p.fail('hotspot $id must not be black');
      hotspots.add(
        SceneHotspot(id, Color(color), p.rect(h, 'bounds', canvas: canvas)),
      );
    }
    if (hotspots.isEmpty) p.fail('hotspots must not be empty');
    p.unique(hotspots.map((h) => h.id), 'hotspot id');
    p.unique(hotspots.map((h) => h.color.toARGB32()), 'hotspot color');

    final masks = json['masks'] == null
        ? const <String, dynamic>{}
        : p.map(json, 'masks');
    final windowMask = masks['window'] == null ? null : p.path(masks, 'window');
    final beamMasks = <String, String>{};
    if (masks['beam'] != null) {
      final beam = p.map(masks, 'beam');
      for (final mode in beam.keys) {
        if (!modeIds.contains(mode)) p.fail('beam mask for unknown mode $mode');
        beamMasks[mode] = p.path(beam, mode);
      }
    }

    final points = <String, Offset>{};
    if (json['points'] != null) {
      final raw = p.map(json, 'points');
      for (final k in raw.keys) {
        final v = p.numbers(raw, k, 2);
        if (v != null) points[k] = Offset(v[0], v[1]);
      }
    }
    final rects = <String, Rect>{};
    if (json['rects'] != null) {
      final raw = p.map(json, 'rects');
      for (final k in raw.keys) {
        rects[k] = p.rect(raw, k, canvas: canvas);
      }
    }

    final hotspotIds = hotspots.map((h) => h.id).toSet();
    final doors = <SceneDoor>[];
    for (final d in json['doors'] == null ? const [] : p.list(json, 'doors')) {
      if (d is! Map<String, dynamic>) {
        p.fail('doors entries must be objects');
        continue;
      }
      final id = p.string(d, 'id');
      final hotspot = p.string(d, 'hotspot');
      if (!hotspotIds.contains(hotspot)) {
        p.fail('door $id references missing hotspot $hotspot');
      }
      final rect = p.rect(d, 'rect', canvas: canvas);
      final framesByMode = <String, List<String>>{};
      final raw = p.map(d, 'framesByMode');
      for (final mode in raw.keys) {
        if (!modeIds.contains(mode)) p.fail('door $id: unknown mode $mode');
        final frames = raw[mode];
        if (frames is! List || frames.length < 2 || frames.length > 24) {
          p.fail('door $id/$mode needs 2..24 frames');
          continue;
        }
        framesByMode[mode] = [
          for (final f in frames)
            f is String && _validPath(f)
                ? f
                : p.fail('door $id/$mode: invalid frame path $f', ''),
        ];
      }
      if (framesByMode.isEmpty) p.fail('door $id has no frames');
      if (framesByMode.values.map((f) => f.length).toSet().length > 1) {
        p.fail('door $id: frame counts differ between modes');
      }
      doors.add(SceneDoor(id, hotspot, rect, framesByMode));
    }
    p.unique(doors.map((d) => d.id), 'door id');
    p.unique(doors.map((d) => d.hotspot), 'door hotspot');

    final details = <SceneDetail>[];
    for (final d
        in json['details'] == null ? const [] : p.list(json, 'details')) {
      if (d is! Map<String, dynamic>) {
        p.fail('details entries must be objects');
        continue;
      }
      final id = p.string(d, 'id');
      final rect = p.rect(d, 'rect', canvas: canvas, allowOverflow: true);
      final images = <String, String>{};
      final raw = p.map(d, 'imagesByMode');
      for (final mode in raw.keys) {
        if (!modeIds.contains(mode)) p.fail('detail $id: unknown mode $mode');
        images[mode] = p.path(raw, mode);
      }
      if (images.isEmpty) p.fail('detail $id has no images');
      details.add(SceneDetail(id, rect, images));
    }
    p.unique(details.map((d) => d.id), 'detail id');

    final files = <SceneFile>[];
    for (final f in p.list(json, 'files')) {
      if (f is! Map<String, dynamic>) {
        p.fail('files entries must be objects');
        continue;
      }
      final sha = p.string(f, 'sha256');
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha)) {
        p.fail('files: invalid sha256 for ${f['path']}');
      }
      files.add(
        SceneFile(
          p.path(f, 'path'),
          p.number(f, 'bytes', positive: true).toInt(),
          sha,
        ),
      );
    }
    p.unique(files.map((f) => f.path), 'files path');

    final manifest = SceneManifest._(
      sceneId: sceneId,
      revision: revision,
      approved: approved,
      canvas: canvas,
      lightingModes: List.unmodifiable(modes),
      idMask: idMask,
      hotspots: List.unmodifiable(hotspots),
      windowMask: windowMask,
      beamMasks: Map.unmodifiable(beamMasks),
      points: Map.unmodifiable(points),
      rects: Map.unmodifiable(rects),
      doors: List.unmodifiable(doors),
      details: List.unmodifiable(details),
      files: List.unmodifiable(files),
    );
    final listed = files.map((f) => f.path).toSet();
    for (final path in manifest.referencedPaths) {
      if (path.isNotEmpty && !listed.contains(path)) {
        p.fail('$path is referenced but missing from files');
      }
    }
    if (p.problems.isNotEmpty) throw SceneManifestException(p.problems);
    return manifest;
  }
}

class LightingMode {
  const LightingMode(this.id, this.image);
  final String id, image;
}

class SceneHotspot {
  const SceneHotspot(this.id, this.color, this.bounds);
  final String id;
  final Color color;
  final Rect bounds;
}

/// Opaque full-scene patches that replace [rect]; frame 0 is closed.
class SceneDoor {
  const SceneDoor(this.id, this.hotspot, this.rect, this.framesByMode);
  final String id, hotspot;
  final Rect rect;
  final Map<String, List<String>> framesByMode;
  int get frameCount => framesByMode.values.first.length;

  /// Spike packs may ship frames for a single mode; fall back to the first.
  List<String> framesFor(String mode) =>
      framesByMode[mode] ?? framesByMode.values.first;
}

class SceneDetail {
  const SceneDetail(this.id, this.rect, this.imagesByMode);
  final String id;
  final Rect rect;
  final Map<String, String> imagesByMode;
}

class SceneFile {
  const SceneFile(this.path, this.bytes, this.sha256);
  final String path, sha256;
  final int bytes;
}

class SceneManifestException implements Exception {
  SceneManifestException(List<String> problems)
    : problems = List.unmodifiable(problems);
  final List<String> problems;
  @override
  String toString() => 'SceneManifestException:\n- ${problems.join('\n- ')}';
}

bool _validPath(String path) =>
    path.isNotEmpty &&
    !path.startsWith('/') &&
    !path.contains('\\') &&
    !path.split('/').contains('..');

class _Parser {
  final problems = <String>[];

  T fail<T>(String problem, [T? fallback]) {
    problems.add(problem);
    return fallback as T;
  }

  String string(Map<String, dynamic> json, String key) {
    final v = json[key];
    return v is String && v.isNotEmpty ? v : fail('$key must be a string', '');
  }

  String path(Map<String, dynamic> json, String key) {
    final v = json[key];
    return v is String && _validPath(v)
        ? v
        : fail('$key must be a relative path inside the scene, got $v', '');
  }

  double number(
    Map<String, dynamic> json,
    String key, {
    bool positive = false,
  }) {
    final v = json[key];
    if (v is num && v.isFinite && (!positive || v > 0)) return v.toDouble();
    return fail('$key must be a${positive ? ' positive' : ''} number', 0.0);
  }

  Map<String, dynamic> map(Map<String, dynamic> json, String key) {
    final v = json[key];
    return v is Map<String, dynamic>
        ? v
        : fail('$key must be an object', <String, dynamic>{});
  }

  List<dynamic> list(Map<String, dynamic> json, String key) {
    final v = json[key];
    return v is List ? v : fail('$key must be a list', const []);
  }

  List<double>? numbers(Map<String, dynamic> json, String key, int length) {
    final v = json[key];
    if (v is List &&
        v.length == length &&
        v.every((e) => e is num && e.isFinite)) {
      return [for (final e in v) (e as num).toDouble()];
    }
    return fail('$key must be $length numbers', null);
  }

  Rect rect(
    Map<String, dynamic> json,
    String key, {
    required Size canvas,
    bool allowOverflow = false,
  }) {
    final v = numbers(json, key, 4);
    if (v == null) return Rect.zero;
    final r = Rect.fromLTWH(v[0], v[1], v[2], v[3]);
    if (v[2] <= 0 || v[3] <= 0) {
      return fail('$key must have a positive size', r);
    }
    if (!allowOverflow &&
        (r.left < 0 ||
            r.top < 0 ||
            r.right > canvas.width ||
            r.bottom > canvas.height)) {
      return fail('$key $v lies outside the canvas', r);
    }
    return r;
  }

  int color(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is String && RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(v)) {
      return 0xFF000000 | int.parse(v.substring(1), radix: 16);
    }
    return fail('$key must be #RRGGBB, got $v', 0xFF000000);
  }

  void unique(Iterable<Object> values, String label) {
    final seen = <Object>{};
    for (final v in values) {
      if (!seen.add(v)) fail('duplicate $label: $v');
    }
  }
}
