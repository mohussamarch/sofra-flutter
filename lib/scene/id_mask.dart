import 'dart:typed_data';
import 'dart:ui' show Offset;

/// Pixel-exact hit testing against a flat-colour ID mask. Stores one byte per
/// pixel (palette index, 0 = nothing) instead of the decoded RGBA buffer.
class IdMask {
  IdMask._(this.width, this.height, this._indices, this.ids);

  /// [rgba] is the decoded mask (4 bytes per pixel). [palette] maps 0xRRGGBB to
  /// hotspot id. Unknown non-black colours throw: the contract forbids them.
  factory IdMask.fromRgba(
    int width,
    int height,
    Uint8List rgba,
    Map<int, String> palette,
  ) {
    if (rgba.length != width * height * 4) {
      throw ArgumentError('RGBA length does not match $width×$height');
    }
    if (palette.length > 254) throw ArgumentError('Palette too large');
    final ids = <String>[''];
    final indexByColor = <int, int>{};
    palette.forEach((color, id) {
      indexByColor[color & 0xFFFFFF] = ids.length;
      ids.add(id);
    });
    final indices = Uint8List(width * height);
    final unknown = <int>{};
    for (var i = 0, p = 0; i < indices.length; i++, p += 4) {
      final color = rgba[p] << 16 | rgba[p + 1] << 8 | rgba[p + 2];
      if (color == 0) continue;
      final index = indexByColor[color];
      if (index == null) {
        unknown.add(color);
      } else {
        indices[i] = index;
      }
    }
    if (unknown.isNotEmpty) {
      final sample = unknown
          .take(5)
          .map((c) => '#${c.toRadixString(16).padLeft(6, '0')}');
      throw FormatException(
        'ID mask has ${unknown.length} colours outside the palette: '
        '${sample.join(', ')}',
      );
    }
    return IdMask._(width, height, indices, List.unmodifiable(ids));
  }

  final int width, height;
  final Uint8List _indices;
  final List<String> ids;

  /// Hotspot at [canvasPoint], or the nearest one within [slop] pixels so a
  /// fingertip near a thin edge still hits. Returns null for empty space.
  String? hitTest(Offset canvasPoint, {double slop = 0}) {
    final cx = canvasPoint.dx.floor(), cy = canvasPoint.dy.floor();
    final direct = _at(cx, cy);
    if (direct != 0 || slop <= 0) return direct == 0 ? null : ids[direct];
    final r = slop.ceil(), r2 = slop * slop;
    var best = 0, bestDistance = double.infinity;
    for (var dy = -r; dy <= r; dy++) {
      for (var dx = -r; dx <= r; dx++) {
        final d = (dx * dx + dy * dy).toDouble();
        if (d > r2 || d >= bestDistance) continue;
        final index = _at(cx + dx, cy + dy);
        if (index != 0) {
          best = index;
          bestDistance = d;
        }
      }
    }
    return best == 0 ? null : ids[best];
  }

  int _at(int x, int y) =>
      x < 0 || y < 0 || x >= width || y >= height ? 0 : _indices[y * width + x];

  /// Alpha-only RGBA buffer of one hotspot inside [left,top,w,h], used for the
  /// tap highlight without keeping a full-canvas image per hotspot.
  Uint8List silhouette(String id, int left, int top, int w, int h) {
    final index = ids.indexOf(id);
    final out = Uint8List(w * h * 4);
    if (index <= 0) return out;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (_at(left + x, top + y) == index) {
          final p = (y * w + x) * 4;
          out[p] = out[p + 1] = out[p + 2] = out[p + 3] = 255;
        }
      }
    }
    return out;
  }
}
