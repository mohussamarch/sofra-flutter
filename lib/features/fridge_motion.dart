import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../app/scope.dart';
import '../domain/models.dart';
import '../scene/frame_player.dart';
import '../ui/design.dart';
import 'common.dart';
import 'shelf_wheel.dart';

/// Codex's r19 review sidecar: separate fridge and freezer tracks per
/// lighting, appliance-only RGBA frames (the kitchen is not in them), the
/// camera closing in and the one door opening.
const fridgeMotionSidecar = 'assets/scenes/kitchen/fridge-v2-review.json';

class FridgeMotion {
  FridgeMotion._(this.frames, this.zone);

  /// Approach frames then door frames, still compressed.
  final List<Uint8List> frames;

  /// Which compartment opens: [StorageZone.fridge] or [StorageZone.freezer].
  final StorageZone zone;

  /// Frames for [zone] in [mode] (cream model), or null when missing.
  static Future<FridgeMotion?> load(String mode, StorageZone zone) async {
    try {
      final json = jsonDecode(
        await rootBundle.loadString(fridgeMotionSidecar),
      ) as Map<String, dynamic>;
      final track = (json['tracks'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (t) => t['model'] == 'cream' && t['compartment'] == zone.name,
          );
      final clip = (track['modes'] as Map)[mode] as Map?;
      final approach = clip?['approach'] as List?;
      final door = clip?['door'] as List?;
      if (approach == null || door == null) return null;
      const dir = 'assets/scenes/kitchen/';
      final frames = <Uint8List>[];
      for (final path in [...approach, ...door].cast<String>()) {
        final data = await rootBundle.load('$dir$path');
        frames.add(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      }
      return FridgeMotion._(frames, zone);
    } catch (_) {
      return null; // Missing or partial pack: the scene's own zoom is used.
    }
  }

  /// Full-screen journey: approach and open over the page's dark tone, show
  /// the compartment's shelves, then play back to the kitchen.
  Future<void> play(BuildContext context, {required Color background}) {
    final scope = SofraScope.of(context);
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: Sofra.motion(context, true),
        reverseTransitionDuration: Sofra.motion(context, true),
        pageBuilder: (_, _, _) => SofraScope(
          controller: scope.notifier!,
          nav: scope.nav,
          child: _FridgeJourney(motion: this, background: background),
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

class _FridgeJourney extends StatefulWidget {
  const _FridgeJourney({required this.motion, required this.background});
  final FridgeMotion motion;
  final Color background;
  @override
  State<_FridgeJourney> createState() => _FridgeJourneyState();
}

class _FridgeJourneyState extends State<_FridgeJourney> {
  late int target = widget.motion.frames.length - 1;
  bool closing = false, shelves = false;

  Future<void> _arrived(int index) async {
    if (index == 0 && closing) {
      if (mounted) Navigator.pop(context);
      return;
    }
    if (index != widget.motion.frames.length - 1 || closing) return;
    setState(() => shelves = true);
  }

  void _close() => setState(() {
    shelves = false;
    closing = true;
    target = 0;
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final zone = widget.motion.zone;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: ColoredBox(
        color: widget.background,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FramePlayer(
              frames: widget.motion.frames,
              target: target,
              decodeWidth: (media.size.width * media.devicePixelRatio)
                  .clamp(360, 1080)
                  .round(),
              onArrived: _arrived,
            ),
            IgnorePointer(
              ignoring: !shelves,
              child: AnimatedOpacity(
                opacity: shelves ? 1 : 0,
                duration: Sofra.motion(context),
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: Color(0x40000000)),
                  child: ShelfWheel(
                    title: zoneName(zone),
                    width: .66,
                    items: zoneShelfItems(context, zone),
                    empty: 'فاضي. ضيف اللي عندك وهنقولك تطبخ إيه.',
                    onAdd: () {
                      final nav = SofraScope.navOf(context);
                      Navigator.pop(context);
                      nav.openAddStock();
                    },
                    onAll: () {
                      final nav = SofraScope.navOf(context);
                      Navigator.pop(context);
                      nav.goTab(AppTab.kitchen);
                    },
                    onClose: _close,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
