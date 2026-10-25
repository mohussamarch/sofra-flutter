import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'scene_ambience.dart';
import 'scene_assets.dart';
import 'scene_lighting.dart';
import 'scene_manifest.dart';

enum DoorPhase { closed, zoomingIn, opening, open, closing, zoomingOut }

/// Drives the door journey from outside (e.g. a back button or the contents
/// sheet). Repeated calls during a transition are ignored.
class KitchenSceneController extends ChangeNotifier {
  DoorPhase _phase = DoorPhase.closed;
  String? _door;
  DoorPhase get phase => _phase;
  String? get activeDoor => _door;
  bool get isBusy => _phase != DoorPhase.closed && _phase != DoorPhase.open;

  _KitchenSceneState? _state;

  /// Zooms to [doorId]'s hotspot and opens it. Returns false when busy.
  bool open(String doorId) => _state?._open(doorId) ?? false;

  /// Closes the open door and zooms back out. Returns false when not open.
  bool close() => _state?._close() ?? false;

  void _set(DoorPhase phase, String? door) {
    _phase = phase;
    _door = door;
    notifyListeners();
  }
}

/// Interactive 2.5D kitchen built from a `sofra.scene/1` pack: time-of-day
/// cross-fades, pixel-exact hotspots, zoom-and-open doors, ambient life.
class KitchenScene extends StatefulWidget {
  const KitchenScene({
    super.key,
    required this.scene,
    this.controller,
    this.schedule,
    this.minuteOfDay,
    this.now = DateTime.now,
    this.onHotspotTap,
    this.onDoorOpened,
    this.onDoorClosed,
    this.ambience = true,
    this.shouldOpenDoor,
  });

  final LoadedScene scene;
  final KitchenSceneController? controller;

  /// Defaults to [LightingSchedule.provisional] restricted to the pack.
  final LightingSchedule? schedule;

  /// Fixed minute for previews/tests; null follows [now].
  final double? minuteOfDay;
  final DateTime Function() now;

  /// Any hotspot tap, including ones that also open a door.
  final ValueChanged<String>? onHotspotTap;
  final ValueChanged<String>? onDoorOpened;

  /// Lets the host take over a door (e.g. a pre-rendered camera move).
  final bool Function(String doorId)? shouldOpenDoor;
  final ValueChanged<String>? onDoorClosed;
  final bool ambience;

  @override
  State<KitchenScene> createState() => _KitchenSceneState();
}

class _KitchenSceneState extends State<KitchenScene>
    with TickerProviderStateMixin {
  late final _ownController = KitchenSceneController();
  KitchenSceneController get _controller => widget.controller ?? _ownController;

  late LightingSchedule _schedule;
  late Map<String, double> _weights;
  Timer? _clockTimer;

  late final AnimationController _zoom = AnimationController(vsync: this);
  late final AnimationController _door = AnimationController(vsync: this);
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Ticker _ticker;
  final _elapsed = ValueNotifier<double>(0);
  SceneAmbience? _ambience;

  SceneDoor? _activeDoor;
  String? _pulseId;
  final _silhouettes = <String, ui.Image>{};
  Size _viewport = Size.zero;

  SceneManifest get _manifest => widget.scene.manifest;
  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  Duration _ms(int ms) => Duration(milliseconds: _reduceMotion ? ms ~/ 5 : ms);

  @override
  void initState() {
    super.initState();
    _controller._state = this;
    _configureSchedule();
    _ticker = createTicker((d) {
      final seconds = d.inMicroseconds / 1e6;
      _ambience?.tick(seconds, _weights);
      _elapsed.value = seconds;
    });
    _syncAmbience();
    _clockTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (widget.minuteOfDay == null) setState(_updateWeights);
    });
  }

  @override
  void didUpdateWidget(KitchenScene old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._state = null;
      _controller._state = this;
    }
    if (old.schedule != widget.schedule || old.scene != widget.scene) {
      _configureSchedule();
    } else if (old.minuteOfDay != widget.minuteOfDay) {
      _updateWeights();
    }
    if (old.scene != widget.scene || old.ambience != widget.ambience) {
      _syncAmbience();
    }
  }

  void _configureSchedule() {
    _schedule = (widget.schedule ?? LightingSchedule.provisional()).restrictTo(
      _manifest.modeIds,
    );
    _updateWeights();
  }

  void _updateWeights() {
    final minute = widget.minuteOfDay;
    _weights = minute == null
        ? _schedule.weightsAtTime(widget.now())
        : _schedule.weightsAt(minute);
  }

  void _syncAmbience() {
    _ambience = widget.ambience ? SceneAmbience(widget.scene) : null;
    if (_ambience != null && !_ticker.isActive) _ticker.start();
    if (_ambience == null && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _ticker.dispose();
    _zoom.dispose();
    _door.dispose();
    _pulse.dispose();
    _elapsed.dispose();
    for (final s in _silhouettes.values) {
      s.dispose();
    }
    if (_controller._state == this) _controller._state = null;
    _ownController.dispose();
    super.dispose();
  }

  // Camera: scale and canvas-space centre, interpolated in log-scale space.
  ({double scale, Offset center}) _camera() {
    final canvas = _manifest.canvas;
    final fit = math.min(
      _viewport.width / canvas.width,
      _viewport.height / canvas.height,
    );
    final home = (scale: fit, center: canvas.center(Offset.zero));
    final door = _activeDoor;
    if (door == null || _zoom.value == 0) return home;
    final target = _manifest
        .hotspot(door.hotspot)!
        .bounds
        .inflate(door.rect.longestSide * .12);
    final targetScale = math.min(
      _viewport.width / target.width,
      _viewport.height / target.height,
    );
    final t = Curves.easeInOutCubic.transform(_zoom.value);
    return (
      scale: math.exp(ui.lerpDouble(math.log(fit), math.log(targetScale), t)!),
      center: Offset.lerp(home.center, target.center, t)!,
    );
  }

  Offset _toCanvas(Offset local) {
    final c = _camera();
    return (local - _viewport.center(Offset.zero)) / c.scale + c.center;
  }

  void _onTapUp(TapUpDetails details) {
    final phase = _controller.phase;
    if (phase == DoorPhase.open) {
      _close();
      return;
    }
    if (_controller.isBusy) return;
    final c = _camera();
    final id = widget.scene.idMask.hitTest(
      _toCanvas(details.localPosition),
      slop: 12 / c.scale,
    );
    if (id == null) return;
    widget.onHotspotTap?.call(id);
    _flash(id);
    final door = _manifest.doorFor(id);
    if (door != null && (widget.shouldOpenDoor?.call(door.id) ?? true)) {
      _open(door.id);
    }
  }

  Future<void> _flash(String id) async {
    _pulseId = id;
    unawaited(_pulse.forward(from: 0).orCancel.catchError((_) {}));
    if (_silhouettes.containsKey(id)) return;
    final b = _manifest.hotspot(id)!.bounds;
    final w = b.width.ceil(), h = b.height.ceil();
    final pixels = widget.scene.idMask.silhouette(
      id,
      b.left.floor(),
      b.top.floor(),
      w,
      h,
    );
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      w,
      h,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final image = await completer.future;
    if (!mounted) {
      image.dispose();
      return;
    }
    _silhouettes[id] = image;
    setState(() {});
  }

  bool _open(String doorId) {
    if (_controller.phase != DoorPhase.closed) return false;
    final door = _manifest.doors.where((d) => d.id == doorId).firstOrNull;
    if (door == null) return false;
    _activeDoor = door;
    _run(door);
    return true;
  }

  Future<void> _run(SceneDoor door) async {
    try {
      _controller._set(DoorPhase.zoomingIn, door.id);
      _zoom.duration = _ms(750);
      await _zoom.forward(from: _zoom.value).orCancel;
      _controller._set(DoorPhase.opening, door.id);
      _door.duration = _ms(650);
      await _door.animateTo(1, curve: Curves.easeOutCubic).orCancel;
      _controller._set(DoorPhase.open, door.id);
      widget.onDoorOpened?.call(door.id);
    } on TickerCanceled {
      // Disposed mid-journey.
    }
  }

  bool _close() {
    final door = _activeDoor;
    if (_controller.phase != DoorPhase.open || door == null) return false;
    () async {
      try {
        _controller._set(DoorPhase.closing, door.id);
        _door.duration = _ms(500);
        await _door.animateBack(0, curve: Curves.easeInCubic).orCancel;
        _controller._set(DoorPhase.zoomingOut, door.id);
        _zoom.duration = _ms(650);
        await _zoom.reverse(from: _zoom.value).orCancel;
        _activeDoor = null;
        _controller._set(DoorPhase.closed, null);
        widget.onDoorClosed?.call(door.id);
      } on TickerCanceled {
        // Disposed mid-journey.
      }
    }();
    return true;
  }

  Color _background() {
    var r = 0.0, g = 0.0, b = 0.0, a = 0.0;
    _weights.forEach((mode, w) {
      final c = widget.scene.backgrounds[mode]!;
      r += c.r * w;
      g += c.g * w;
      b += c.b * w;
      a += c.a * w;
    });
    return Color.from(alpha: a, red: r, green: g, blue: b);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = constraints.biggest;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _onTapUp,
          child: ColoredBox(
            color: _background(),
            child: AnimatedBuilder(
              animation: Listenable.merge([_zoom, _door, _pulse]),
              builder: (context, _) {
                final camera = _camera();
                // Canvas space is direction-agnostic; never mirror in RTL.
                return Stack(
                  textDirection: TextDirection.ltr,
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: _ScenePainter(
                          scene: widget.scene,
                          camera: camera,
                          weights: _weights,
                          door: _activeDoor,
                          doorT: _door.value,
                          pulseId: _pulseId,
                          pulse: _pulse.value,
                          silhouettes: _silhouettes,
                        ),
                      ),
                    ),
                    if (_ambience != null)
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: _AmbiencePainter(
                            ambience: _ambience!,
                            camera: camera,
                            weights: _weights,
                            elapsed: _elapsed,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

void _applyCamera(Canvas canvas, Size size, ({double scale, Offset center}) c) {
  canvas.translate(size.width / 2, size.height / 2);
  canvas.scale(c.scale);
  canvas.translate(-c.center.dx, -c.center.dy);
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.scene,
    required this.camera,
    required this.weights,
    required this.door,
    required this.doorT,
    required this.pulseId,
    required this.pulse,
    required this.silhouettes,
  });

  final LoadedScene scene;
  final ({double scale, Offset center}) camera;
  final Map<String, double> weights;
  final SceneDoor? door;
  final double doorT, pulse;
  final String? pulseId;
  final Map<String, ui.Image> silhouettes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _applyCamera(canvas, size, camera);
    final full = Offset.zero & scene.manifest.canvas;
    final paint = Paint()..filterQuality = FilterQuality.medium;
    // Heaviest mode first at full opacity, the other on top with its weight.
    final ordered = weights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (var i = 0; i < ordered.length; i++) {
      final mode = ordered[i].key;
      paint.color = Color.fromRGBO(0, 0, 0, i == 0 ? 1 : ordered[i].value);
      final image = scene.bases[mode]!;
      canvas.drawImageRect(image, _src(image), full, paint);
      final d = door;
      if (d != null && doorT > 0) {
        final frames = scene.framesFor(d, mode);
        final index = (doorT * (frames.length - 1)).round();
        canvas.drawImageRect(frames[index], _src(frames[index]), d.rect, paint);
      }
    }
    final id = pulseId, silhouette = id == null ? null : silhouettes[id];
    if (silhouette != null && pulse > 0 && pulse < 1) {
      final glow = math.sin(pulse * math.pi) * .35;
      final b = scene.manifest.hotspot(id!)!.bounds;
      canvas.drawImageRect(
        silhouette,
        _src(silhouette),
        Rect.fromLTWH(
          b.left.floorToDouble(),
          b.top.floorToDouble(),
          silhouette.width.toDouble(),
          silhouette.height.toDouble(),
        ),
        Paint()
          ..blendMode = BlendMode.plus
          ..colorFilter = ColorFilter.mode(
            Color.fromRGBO(255, 244, 214, glow),
            BlendMode.srcIn,
          ),
      );
    }
    canvas.restore();
  }

  static Rect _src(ui.Image i) =>
      Rect.fromLTWH(0, 0, i.width.toDouble(), i.height.toDouble());

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.camera != camera ||
      !mapEquals(old.weights, weights) ||
      old.door != door ||
      old.doorT != doorT ||
      old.pulse != pulse ||
      old.pulseId != pulseId ||
      old.silhouettes.length != silhouettes.length ||
      old.scene != scene;
}

class _AmbiencePainter extends CustomPainter {
  _AmbiencePainter({
    required this.ambience,
    required this.camera,
    required this.weights,
    required this.elapsed,
  }) : super(repaint: elapsed);

  final SceneAmbience ambience;
  final ({double scale, Offset center}) camera;
  final Map<String, double> weights;
  final ValueListenable<double> elapsed;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _applyCamera(canvas, size, camera);
    ambience.paint(canvas, elapsed.value, weights);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AmbiencePainter old) =>
      old.ambience != ambience ||
      old.camera != camera ||
      !mapEquals(old.weights, weights);
}
