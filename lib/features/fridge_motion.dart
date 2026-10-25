import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../app/scope.dart';
import '../domain/models.dart';
import '../scene/frame_player.dart';
import '../ui/design.dart';
import 'kitchen_screen.dart';

/// Codex's r18 review sidecar: the camera turns to face the fridge in
/// one-point perspective, then the door opens (`cameraMoves` from contract 1.1).
const fridgeMotionSidecar = 'assets/scenes/kitchen/fridge-motion-spike.json';

class FridgeMotion {
  FridgeMotion._(this.frames, this.approach);

  /// Approach frames then door frames, still compressed.
  final List<Uint8List> frames;
  final int approach;

  /// Frames for [mode], or null when that lighting has not been rendered yet.
  static Future<FridgeMotion?> load(String mode) async {
    try {
      final json =
          jsonDecode(await rootBundle.loadString(fridgeMotionSidecar))
              as Map<String, dynamic>;
      final move = (json['cameraMoves'] as List).cast<Map<String, dynamic>>()
          .firstWhere((m) => m['hotspot'] == 'fridge');
      final approach = (move['approachByMode'] as Map)[mode] as List?;
      final door = (move['doorByMode'] as Map)[mode] as List?;
      if (approach == null || door == null) return null;
      const dir = 'assets/scenes/kitchen/';
      final frames = <Uint8List>[];
      for (final path in [...approach, ...door].cast<String>()) {
        final data = await rootBundle.load('$dir$path');
        frames.add(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      }
      return FridgeMotion._(frames, approach.length);
    } catch (_) {
      return null; // Missing or partial pack: the scene's own zoom is used.
    }
  }

  /// Full-screen journey: approach and open, show the fridge's contents, then
  /// play back to the kitchen when the sheet closes.
  Future<void> play(BuildContext context, {required Color top, required Color bottom}) {
    final scope = SofraScope.of(context);
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: Sofra.motion(context, true),
        reverseTransitionDuration: Sofra.motion(context, true),
        pageBuilder: (_, _, _) => SofraScope(
          controller: scope.notifier!,
          nav: scope.nav,
          child: _FridgeJourney(motion: this, top: top, bottom: bottom),
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

class _FridgeJourney extends StatefulWidget {
  const _FridgeJourney({required this.motion, required this.top, required this.bottom});
  final FridgeMotion motion;
  final Color top, bottom;
  @override
  State<_FridgeJourney> createState() => _FridgeJourneyState();
}

class _FridgeJourneyState extends State<_FridgeJourney> {
  late int target = widget.motion.frames.length - 1;
  int frame = 0;
  bool closing = false;

  Future<void> _arrived(int index) async {
    if (index == 0 && closing) {
      if (mounted) Navigator.pop(context);
      return;
    }
    if (index != widget.motion.frames.length - 1) return;
    await ZoneStockSheet.show(context, StorageZone.fridge);
    if (!mounted) return;
    setState(() {
      closing = true;
      target = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // The first frames still show the render's backdrop; the page tone fades
    // over it exactly like on the home screen, then lifts as the camera turns.
    final edge = (1 - frame / 8).clamp(0.0, 1.0);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !closing) setState(() => closing = true);
        if (!didPop) setState(() => target = 0);
      },
      child: ColoredBox(
        color: widget.bottom,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FramePlayer(
              frames: widget.motion.frames,
              target: target,
              decodeWidth: (media.size.width * media.devicePixelRatio)
                  .clamp(360, 1080)
                  .round(),
              onFrame: (i) => setState(() => frame = i),
              onArrived: _arrived,
            ),
            if (edge > 0)
              IgnorePointer(
                child: Opacity(
                  opacity: edge,
                  child: CustomPaint(
                    painter: _FrameEdgeFade(top: widget.top, bottom: widget.bottom),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Feathered cut-out around the room in the move's first frame (1080×2340),
/// mapped with the same cover fit as the frames.
class _FrameEdgeFade extends CustomPainter {
  _FrameEdgeFade({required this.top, required this.bottom});
  final Color top, bottom;

  static const _frame = Size(1080, 2340);
  static const _room = [
    Offset(538, 800),
    Offset(945, 1020),
    Offset(945, 1295),
    Offset(538, 1515),
    Offset(131, 1295),
    Offset(131, 1020),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / _frame.width > size.height / _frame.height
        ? size.width / _frame.width
        : size.height / _frame.height;
    final origin = Offset(
      (size.width - _frame.width * k) / 2,
      (size.height - _frame.height * k) / 2,
    );
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(bounds),
    );
    canvas.drawPath(
      Path()..addPolygon([for (final p in _room) origin + p * k], true),
      Paint()
        ..blendMode = BlendMode.dstOut
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 36 * k),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FrameEdgeFade old) => old.top != top || old.bottom != bottom;
}
