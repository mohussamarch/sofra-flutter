import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'scene_assets.dart';

/// Placeholder "alive kitchen" effects drawn in canvas space over the base:
/// dust in the sunbeam, birds behind the window, a breathing night lamp.
/// Codex sprites replace the vector birds once the contract adds them.
class SceneAmbience {
  SceneAmbience(this.scene, {int seed = 7}) : _random = math.Random(seed) {
    for (final e in scene.beams.entries) {
      _beamPoints[e.key] = e.value.brightPoints(.3);
    }
  }

  final LoadedScene scene;
  final math.Random _random;
  final _beamPoints = <String, List<ui.Offset>>{};
  final _motes = <_Mote>[];
  final _birds = <_Bird>[];
  double _lastSeconds = 0, _nextBird = 4;

  static const _moteCount = 45;

  /// Advances the simulation to [seconds] since start.
  void tick(double seconds, Map<String, double> weights) {
    final dt = (seconds - _lastSeconds).clamp(0, .1).toDouble();
    _lastSeconds = seconds;
    final sunMode = _dominantBeamMode(weights);
    final points = sunMode == null ? null : _beamPoints[sunMode];
    if (points != null && points.isNotEmpty) {
      while (_motes.length < _moteCount) {
        _motes.add(_spawnMote(points, seconds, warmStart: _motes.isEmpty));
      }
    }
    for (var i = _motes.length - 1; i >= 0; i--) {
      final m = _motes[i];
      m.position +=
          m.velocity * dt +
          ui.Offset(math.sin(seconds * m.wobble + m.phase) * 3 * dt, 0);
      if (seconds - m.born > m.life) {
        if (points == null || points.isEmpty) {
          _motes.removeAt(i);
        } else {
          _motes[i] = _spawnMote(points, seconds);
        }
      }
    }
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

  String? _dominantBeamMode(Map<String, double> weights) {
    String? best;
    var bestWeight = 0.0;
    weights.forEach((mode, w) {
      if (scene.beams.containsKey(mode) && w > bestWeight) {
        best = mode;
        bestWeight = w;
      }
    });
    return best;
  }

  _Mote _spawnMote(
    List<ui.Offset> points,
    double now, {
    bool warmStart = false,
  }) {
    final base = points[_random.nextInt(points.length)];
    final life = 6 + _random.nextDouble() * 7;
    return _Mote(
      position:
          base +
          ui.Offset(
            (_random.nextDouble() - .5) * 12,
            (_random.nextDouble() - .5) * 12,
          ),
      velocity: ui.Offset(
        (_random.nextDouble() - .5) * 6,
        -2 - _random.nextDouble() * 5,
      ),
      born: warmStart ? now - _random.nextDouble() * life : now,
      life: life,
      radius: 1.2 + _random.nextDouble() * 1.8,
      wobble: .6 + _random.nextDouble(),
      phase: _random.nextDouble() * math.pi * 2,
    );
  }

  void paint(Canvas canvas, double seconds, Map<String, double> weights) {
    _paintLamp(canvas, seconds, weights['night'] ?? 0);
    _paintMotes(canvas, seconds, weights);
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

  void _paintMotes(Canvas canvas, double seconds, Map<String, double> weights) {
    var sun = 0.0;
    weights.forEach((mode, w) {
      if (scene.beams.containsKey(mode)) sun += w;
    });
    final sampler = scene.beams[_dominantBeamMode(weights)];
    if (sun <= .01 || sampler == null) return;
    final paint = Paint()..blendMode = BlendMode.plus;
    for (final m in _motes) {
      final age = (seconds - m.born) / m.life;
      final fade = math.sin(age.clamp(0, 1) * math.pi);
      final light = sampler.at(m.position);
      final alpha = (sun * fade * light * .5).clamp(0, 1).toDouble();
      if (alpha < .02) continue;
      paint.color = const Color(0xFFFFF1C9).withValues(alpha: alpha);
      canvas.drawCircle(m.position, m.radius, paint);
    }
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

class _Mote {
  _Mote({
    required this.position,
    required this.velocity,
    required this.born,
    required this.life,
    required this.radius,
    required this.wobble,
    required this.phase,
  });
  ui.Offset position;
  final ui.Offset velocity;
  final double born, life, radius, wobble, phase;
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
