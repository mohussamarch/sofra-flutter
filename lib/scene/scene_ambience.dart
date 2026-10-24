import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'scene_assets.dart';

/// Placeholder "alive kitchen" effects drawn in canvas space over the base:
/// birds behind the window and a breathing night lamp. Dust in the sunbeam
/// waits for a rendered loop from Blender (CPU dots looked fake).
/// Codex sprites replace the vector birds once the contract adds them.
class SceneAmbience {
  SceneAmbience(this.scene, {int seed = 7}) : _random = math.Random(seed);

  final LoadedScene scene;
  final math.Random _random;
  final _birds = <_Bird>[];
  double _nextBird = 4;

  /// Advances the simulation to [seconds] since start.
  void tick(double seconds, Map<String, double> weights) {
    final window = scene.manifest.rects['window'];
    if (window != null && seconds >= _nextBird) {
      _nextBird = seconds + 7 + _random.nextDouble() * 14;
      final leftToRight = _random.nextBool();
      _birds.add(
        _Bird(
          born: seconds,
          y: window.top + window.height * (.15 + _random.nextDouble() * .45),
          speed: window.width * (.45 + _random.nextDouble() * .35),
          leftToRight: leftToRight,
          size: 7 + _random.nextDouble() * 5,
          flap: 7 + _random.nextDouble() * 4,
        ),
      );
    }
    _birds.removeWhere((b) => seconds - b.born > 8);
  }

  void paint(Canvas canvas, double seconds, Map<String, double> weights) {
    _paintLamp(canvas, seconds, weights['night'] ?? 0);
    _paintBirds(canvas, seconds, 1 - (weights['night'] ?? 0));
  }

  void _paintLamp(Canvas canvas, double seconds, double night) {
    final lamp = scene.manifest.points['ceilingLamp'];
    if (lamp == null || night <= .01) return;
    final breath = .5 + .5 * math.sin(seconds * 1.1);
    final alpha = night * (.05 + .035 * breath);
    const radius = 420.0;
    canvas.drawCircle(
      lamp,
      radius,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(lamp, radius, [
          const Color(0xFFFFD9A0).withValues(alpha: alpha),
          const Color(0x00FFD9A0),
        ]),
    );
  }

  void _paintBirds(Canvas canvas, double seconds, double day) {
    final window = scene.manifest.rects['window'];
    final mask = scene.windowMask;
    if (window == null || mask == null || day <= .01 || _birds.isEmpty) return;
    canvas.saveLayer(window, Paint());
    final paint = Paint()
      ..color = const Color(0xFF3A3A44).withValues(alpha: .8 * day)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (final b in _birds) {
      final travelled = (seconds - b.born) * b.speed;
      final x = b.leftToRight
          ? window.left - 20 + travelled
          : window.right + 20 - travelled;
      final y = b.y + math.sin((seconds - b.born) * 2) * 4;
      final lift = math.sin(seconds * b.flap) * b.size * .55;
      canvas.drawPath(
        Path()
          ..moveTo(x - b.size, y - lift)
          ..quadraticBezierTo(x - b.size * .45, y - b.size * .35, x, y)
          ..quadraticBezierTo(
            x + b.size * .45,
            y - b.size * .35,
            x + b.size,
            y - lift,
          ),
        paint,
      );
    }
    final canvasRect = ui.Offset.zero & scene.manifest.canvas;
    canvas.drawImageRect(
      mask,
      ui.Offset.zero & ui.Size(mask.width.toDouble(), mask.height.toDouble()),
      canvasRect,
      Paint()..blendMode = BlendMode.dstIn,
    );
    canvas.restore();
  }
}

class _Bird {
  _Bird({
    required this.born,
    required this.y,
    required this.speed,
    required this.leftToRight,
    required this.size,
    required this.flap,
  });
  final double born, y, speed, size, flap;
  final bool leftToRight;
}
