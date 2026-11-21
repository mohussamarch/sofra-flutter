import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../ui/design.dart';
import 'viewer_host.dart';

/// A point in the kitchen in Blender's coordinates (metres, z up), the same
/// space the zones are measured in.
typedef KitchenPoint = ({double x, double y, double z});

/// The Blender kitchen as a real-time room: the app's own three.js viewer
/// (`assets/scene3d/`) showing Codex's R25 mobile model with its options
/// (`assets/spike3d/r24/kitchen.glb`). The light is the hybrid the owner
/// chose: Cycles bounce light baked into lightmaps, plus a live sun, window
/// light, ceiling lamp, LEDs and fridge lamps casting real shadows. Cabinet
/// colour and every option change live, with no render per choice.
/// How the page works and what it is told: `docs/dev/KITCHEN-3D.md`.
class Kitchen3D extends StatefulWidget {
  const Kitchen3D({
    super.key,
    required this.controller,
    this.id = 'kitchen3d',
    this.onTap,
    this.vignette = false,
    this.background = const Color(0xFF15100C),
    this.foreground,
    this.look = const {},
  });
  final Kitchen3DController controller;

  /// Names this viewer's messages; two viewers alive at once need two ids.
  final String id;

  /// A tap on the room, where it hit.
  final ValueChanged<KitchenPoint>? onTap;

  /// Fades the room's edges into the page (overview only).
  final bool vignette;
  final Color background;

  /// Ink for the loading and error states, readable on what is behind the
  /// room. Without it, chosen from [background].
  final Color? foreground;

  /// The kitchen's chosen parts, [Profile.kitchenLook].
  final Map<String, String> look;

  @override
  State<Kitchen3D> createState() => _Kitchen3DState();
}

/// Drives the viewer: camera shots with their doors, and the time of day.
/// The camera moves in fixed shots only: the isometric overview, the table,
/// and the turn to the fridge, freezer or microwave, whose door then opens.
class Kitchen3DController {
  _Kitchen3DState? _view;
  String _shot = 'home';
  Map<String, double>? _weights;

  Future<void> _go(String shot) async {
    _shot = shot;
    _view?._push();
  }

  /// The isometric overview; any open door swings shut.
  Future<void> overview() => _go('home');

  /// Turns to face the fridge (or freezer) and opens its door.
  Future<void> open({bool freezer = false}) =>
      _go(freezer ? 'freezer' : 'fridge');

  /// Shuts the open door while the camera goes back to the overview.
  Future<void> close() => _go('home');

  /// From the near corner of the dining table, looking across it into the
  /// kitchen (Codex C2C-014: 45° across the room, field of view 50°).
  Future<void> table() => _go('table');

  /// Turns to the microwave on the counter and opens its door.
  Future<void> microwave() => _go('microwave');

  /// The time of day as weights of `morning`, `golden` and `night`; the room
  /// eases between them. Without any, the viewer follows the clock.
  Future<void> light(Map<String, double> weights) async {
    _weights = Map.of(weights);
    _view?._push();
  }

  /// One lighting mode at full weight.
  Future<void> lighting(String mode) => light({mode: 1});
}

class _Kitchen3DState extends State<Kitchen3D> {
  late ViewerHost _host;
  var _generation = 0;
  var _ready = false;
  var _failed = false;
  var _slow = false;
  var _hud = false;
  var _calm = false;

  /// Why the page failed, in its own words (shown small under the message:
  /// the first thing to read when a phone shows no kitchen).
  String? _cause;
  Timer? _lost;
  Timer? _slowTimer;
  Timer? _giveUp;

  @override
  void initState() {
    super.initState();
    widget.controller._view = this;
    _open();
  }

  void _open() {
    _cause = null;
    final generation = ++_generation;
    _host = openViewer(
      id: '${widget.id}-$generation',
      // A page that was replaced may still be talking.
      onMessage: (text) {
        if (generation == _generation) _message(text);
      },
    );
    _waitForPage();
  }

  /// A page is loading (the first time, a retry, or after its graphics
  /// context was lost): it fades in by itself; a spinner only if it is
  /// taking a while, and the error state if it never comes.
  void _waitForPage() {
    _ready = _failed = _slow = false;
    _lost?.cancel();
    _slowTimer?.cancel();
    _slowTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted && !_ready) setState(() => _slow = true);
    });
    _giveUp?.cancel();
    _giveUp = Timer(const Duration(seconds: 30), () {
      if (mounted && !_ready) setState(() => _failed = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion can change while the room is up.
    final calm = MediaQuery.disableAnimationsOf(context);
    if (calm != _calm) {
      _calm = calm;
      _push();
    }
  }

  @override
  void didUpdateWidget(Kitchen3D old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      if (old.controller._view == this) old.controller._view = null;
      widget.controller._view = this;
      _push();
    } else if (!mapEquals(old.look, widget.look) ||
        old.vignette != widget.vignette) {
      _push();
    }
  }

  @override
  void dispose() {
    if (widget.controller._view == this) widget.controller._view = null;
    _slowTimer?.cancel();
    _giveUp?.cancel();
    _lost?.cancel();
    _host.dispose();
    super.dispose();
  }

  /// The whole state every time: the page keeps what has not changed, and a
  /// page that was not up yet misses nothing.
  void _push() {
    if (!mounted) return;
    final c = widget.controller;
    _host.send(
      jsonEncode({
        'shot': c._shot,
        'weights': c._weights,
        'look': _lookJson(widget.look),
        'vignette': widget.vignette,
        'calm': _calm,
        'hud': _hud,
      }),
    );
  }

  void _message(String text) {
    if (!mounted) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      return;
    }
    if (decoded is! Map) return;
    switch (decoded['t']) {
      case 'hello':
        // A hello from a room that was up: its page started again.
        if (_ready) setState(_waitForPage);
        _push();
      case 'ready':
        _slowTimer?.cancel();
        _giveUp?.cancel();
        _lost?.cancel();
        _push();
        setState(() {
          _ready = true;
          _failed = false;
        });
      case 'tap':
        final p = decoded['p'];
        if (p is! List || p.length < 3 || p.any((v) => v is! num)) return;
        widget.onTap?.call((
          x: (p[0] as num).toDouble(),
          y: (p[1] as num).toDouble(),
          z: (p[2] as num).toDouble(),
        ));
      case 'error':
        // The page could not start (or could not load at all).
        final why = decoded['message'];
        if (!_ready) {
          setState(() {
            _failed = true;
            _cause = why is String ? why : null;
          });
        }
      case 'warn':
        // The page reloads itself when its graphics context comes back; if
        // it never does, say so instead of leaving a blank room.
        if (decoded['message'] == 'context lost') {
          _lost?.cancel();
          _lost = Timer(const Duration(seconds: 6), () {
            if (!mounted) return;
            setState(() {
              _ready = false;
              _failed = true;
              _cause = 'context lost';
            });
          });
        }
    }
  }

  void _retry() => setState(() {
    _host.dispose();
    _open();
  });

  /// A three-second hold: the page's own numbers (draw calls, frame time,
  /// start-up, graphics chip), for reading on a real phone. Long enough not
  /// to happen by accident, and an ordinary slow press still taps.
  void _toggleHud() {
    _hud = !_hud;
    _push();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final back = widget.background;
    final ink =
        widget.foreground ??
        (back.a > .5 && back.computeLuminance() < .25
            ? Sofra.onInverse
            : Sofra.ink);
    return ColoredBox(
      color: back,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              label: t.kitchen3dAlt,
              image: true,
              child: IgnorePointer(
                child: KeyedSubtree(
                  key: ValueKey(_generation),
                  child: _host.view,
                ),
              ),
            ),
            // Touches are the app's: a tap asks the page what it hit.
            RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: {
                LongPressGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      LongPressGestureRecognizer
                    >(
                      () => LongPressGestureRecognizer(
                        duration: const Duration(seconds: 3),
                      ),
                      (r) => r.onLongPress = _toggleHud,
                    ),
                if (widget.onTap != null)
                  TapGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        TapGestureRecognizer
                      >(
                        TapGestureRecognizer.new,
                        (r) => r.onTapUp = (d) => _host.send(
                          jsonEncode({
                            'pick': [
                              d.localPosition.dx / box.maxWidth,
                              d.localPosition.dy / box.maxHeight,
                            ],
                          }),
                        ),
                      ),
              },
            ),
            if (_failed)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.kitchen3dError,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ink, height: 1.6),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(t.recipeRetry),
                    ),
                    if (_cause != null) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _cause!,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink.withValues(alpha: .6),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else if (_slow && !_ready)
              Center(
                child: SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: ink,
                    semanticsLabel: t.kitchen3dLoading,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The viewer's look: [Profile.kitchenLook] with the cabinet colour (hex) as
/// a linear colour, the space the model's materials are in.
Map<String, Object?> _lookJson(Map<String, String> look) {
  final hex = look['cabinet'];
  final value = hex == null || hex.length != 6
      ? null
      : int.tryParse('FF$hex', radix: 16);
  final c = value == null ? null : Color(value);
  return {
    ...look,
    'cabinet': c == null ? null : [_linear(c.r), _linear(c.g), _linear(c.b)],
  };
}

/// Swatches are sRGB; material colours are linear.
double _linear(double c) =>
    c <= .04045 ? c / 12.92 : math.pow((c + .055) / 1.055, 2.4).toDouble();
