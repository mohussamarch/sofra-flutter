import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'id_mask.dart';
import 'scene_manifest.dart';

/// Low-resolution greyscale copy of a mask for cheap CPU sampling (particles).
class MaskSampler {
  MaskSampler(this.width, this.height, this.values, this.canvas);
  final int width, height;
  final Uint8List values;
  final ui.Size canvas;

  /// 0..1 intensity at a canvas-space point.
  double at(ui.Offset p) {
    final x = (p.dx / canvas.width * width).floor();
    final y = (p.dy / canvas.height * height).floor();
    if (x < 0 || y < 0 || x >= width || y >= height) return 0;
    return values[y * width + x] / 255;
  }

  /// Canvas-space points whose intensity exceeds [threshold], for spawning.
  List<ui.Offset> brightPoints(double threshold) => [
    for (var y = 0; y < height; y++)
      for (var x = 0; x < width; x++)
        if (values[y * width + x] / 255 > threshold)
          ui.Offset(
            (x + .5) / width * canvas.width,
            (y + .5) / height * canvas.height,
          ),
  ];
}

/// Makes the flat render backdrop transparent, in place. Flood-fills from the
/// image border over pixels within [tolerance] (sum of channel differences)
/// of the corner colour, so room pixels of a similar tone are never touched;
/// pixels bordering the fill fade by distance to soften the edge.
void keyOutBackdrop(
  Uint8List rgba,
  int width,
  int height, {
  int tolerance = 14,
}) {
  // A render that already has an alpha backdrop needs no keying.
  if (rgba[3] == 0) return;
  final kr = rgba[0], kg = rgba[1], kb = rgba[2];
  int dist(int p) =>
      (rgba[p * 4] - kr).abs() +
      (rgba[p * 4 + 1] - kg).abs() +
      (rgba[p * 4 + 2] - kb).abs();
  final keyed = Uint8List(width * height);
  final stack = <int>[];
  void seed(int p) {
    if (keyed[p] == 0 && dist(p) <= tolerance) {
      keyed[p] = 1;
      stack.add(p);
    }
  }

  for (var x = 0; x < width; x++) {
    seed(x);
    seed((height - 1) * width + x);
  }
  for (var y = 0; y < height; y++) {
    seed(y * width);
    seed(y * width + width - 1);
  }
  while (stack.isNotEmpty) {
    final p = stack.removeLast();
    final x = p % width, y = p ~/ width;
    if (x > 0) seed(p - 1);
    if (x < width - 1) seed(p + 1);
    if (y > 0) seed(p - width);
    if (y < height - 1) seed(p + width);
  }
  const soft = 30;
  for (var p = 0; p < keyed.length; p++) {
    if (keyed[p] == 1) {
      // Engine pixels are premultiplied: a clear pixel must carry no colour.
      rgba[p * 4] = rgba[p * 4 + 1] = rgba[p * 4 + 2] = rgba[p * 4 + 3] = 0;
      continue;
    }
    final x = p % width, y = p ~/ width;
    final edge =
        (x > 0 && keyed[p - 1] == 1) ||
        (x < width - 1 && keyed[p + 1] == 1) ||
        (y > 0 && keyed[p - width] == 1) ||
        (y < height - 1 && keyed[p + width] == 1);
    if (!edge) continue;
    final d = dist(p);
    if (d < tolerance + soft) {
      final alpha = (255 * (d - tolerance) / soft).round().clamp(0, 255);
      for (var ch = 0; ch < 3; ch++) {
        rgba[p * 4 + ch] = rgba[p * 4 + ch] * alpha ~/ 255;
      }
      rgba[p * 4 + 3] = alpha;
    }
  }
}

/// Decoded scene ready to paint. Call [dispose] when the scene leaves.
class LoadedScene {
  LoadedScene._(
    this.manifest,
    this.bases,
    this.backgrounds,
    this.idMask,
    this.windowMask,
    this.beams,
    this.doorFrames,
  );

  final SceneManifest manifest;
  final Map<String, ui.Image> bases;

  /// Backdrop colour around the room per mode, sampled from the image corner.
  final Map<String, ui.Color> backgrounds;
  final IdMask idMask;
  final ui.Image? windowMask;
  final Map<String, MaskSampler> beams;

  /// door id → mode → frames (only modes the pack provides).
  final Map<String, Map<String, List<ui.Image>>> doorFrames;

  List<ui.Image> framesFor(SceneDoor door, String mode) {
    final byMode = doorFrames[door.id]!;
    return byMode[mode] ?? byMode.values.first;
  }

  void dispose() {
    for (final i in bases.values) {
      i.dispose();
    }
    windowMask?.dispose();
    for (final byMode in doorFrames.values) {
      for (final frames in byMode.values) {
        for (final f in frames) {
          f.dispose();
        }
      }
    }
  }

  static Future<SceneManifest> loadManifest(
    AssetBundle bundle,
    String manifestAsset,
  ) async => SceneManifest.fromJson(
    jsonDecode(await bundle.loadString(manifestAsset, cache: false))
        as Map<String, dynamic>,
  );

  /// Loads `assets/scenes/<id>/manifest.json` and decodes what the viewer
  /// paints. Beam masks are sampled at [maskSampleWidth] px wide.
  /// With [keyBackdrop] the render's flat backdrop becomes transparent, so
  /// the room floats over whatever the host paints behind it.
  static Future<LoadedScene> load(
    AssetBundle bundle,
    String manifestAsset, {
    int maskSampleWidth = 240,
    bool keyBackdrop = false,
  }) async {
    final manifest = await loadManifest(bundle, manifestAsset);
    final dir = manifestAsset.substring(0, manifestAsset.lastIndexOf('/') + 1);
    Future<ui.Image> image(String path, {int? width}) async {
      final data = await bundle.load('$dir$path');
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        targetWidth: width,
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    }

    Future<Uint8List> rgba(ui.Image i) async {
      final bytes = await i.toByteData(format: ui.ImageByteFormat.rawRgba);
      return bytes!.buffer.asUint8List();
    }

    final canvas = manifest.canvas;
    final bases = <String, ui.Image>{};
    final backgrounds = <String, ui.Color>{};
    for (final mode in manifest.lightingModes) {
      final i = await image(mode.image);
      _checkSize(i, canvas, mode.image);
      if (keyBackdrop) {
        final px = await rgba(i);
        keyOutBackdrop(px, i.width, i.height);
        final keyed = Completer<ui.Image>();
        ui.decodeImageFromPixels(
          px,
          i.width,
          i.height,
          ui.PixelFormat.rgba8888,
          keyed.complete,
        );
        bases[mode.id] = await keyed.future;
        i.dispose();
        backgrounds[mode.id] = const ui.Color(0x00000000);
        continue;
      }
      bases[mode.id] = i;
      // Corner of a tiny decode: the backdrop colour outside the room.
      final tiny = await image(mode.image, width: 8);
      final px = await rgba(tiny);
      backgrounds[mode.id] = ui.Color.fromARGB(255, px[0], px[1], px[2]);
      tiny.dispose();
    }

    final maskImage = await image(manifest.idMask);
    _checkSize(maskImage, canvas, manifest.idMask);
    final idMask = IdMask.fromRgba(
      maskImage.width,
      maskImage.height,
      await rgba(maskImage),
      {for (final h in manifest.hotspots) h.color.toARGB32(): h.id},
    );
    maskImage.dispose();

    final windowMask = manifest.windowMask == null
        ? null
        : await image(manifest.windowMask!, width: canvas.width ~/ 2);

    final beams = <String, MaskSampler>{};
    for (final e in manifest.beamMasks.entries) {
      final i = await image(e.value, width: maskSampleWidth);
      final data = await rgba(i);
      final values = Uint8List(i.width * i.height);
      for (var p = 0; p < values.length; p++) {
        values[p] = data[p * 4];
      }
      beams[e.key] = MaskSampler(i.width, i.height, values, canvas);
      i.dispose();
    }

    final doorFrames = <String, Map<String, List<ui.Image>>>{};
    for (final door in manifest.doors) {
      final byMode = <String, List<ui.Image>>{};
      for (final e in door.framesByMode.entries) {
        final frames = <ui.Image>[];
        for (final path in e.value) {
          final f = await image(path);
          if (f.width != door.rect.width.round() ||
              f.height != door.rect.height.round()) {
            throw FormatException(
              '$path is ${f.width}×${f.height}, door rect is ${door.rect.size}',
            );
          }
          frames.add(f);
        }
        byMode[e.key] = frames;
      }
      doorFrames[door.id] = byMode;
    }

    return LoadedScene._(
      manifest,
      bases,
      backgrounds,
      idMask,
      windowMask,
      beams,
      doorFrames,
    );
  }

  static void _checkSize(ui.Image i, ui.Size canvas, String path) {
    if (i.width != canvas.width.round() || i.height != canvas.height.round()) {
      throw FormatException('$path is ${i.width}×${i.height}, canvas $canvas');
    }
  }
}
