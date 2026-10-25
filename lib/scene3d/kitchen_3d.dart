import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'js_runner.dart';

/// A point in the kitchen in Blender's coordinates (metres, z up), the same
/// space the zones are measured in.
typedef KitchenPoint = ({double x, double y, double z});

/// The Blender kitchen as a real-time model (`assets/spike3d/kitchen.glb`,
/// made by `tool/scene3d/bake_light.py`): the Cycles light of the render is
/// baked into vertex colours, each material keeps its own colour, so cabinet
/// colours still change live and the fridge opens in place, with no render per
/// option. The baked light already holds the shading, hence no extra shadow.
class Kitchen3D extends StatefulWidget {
  const Kitchen3D({
    super.key,
    required this.controller,
    this.id = 'kitchen3d',
    this.onTap,
    this.vignette = false,
    this.background = const Color(0xFF15100C),
    this.zoom = true,
  });
  final Kitchen3DController controller;

  /// DOM id; two viewers on screen at once need different ids.
  final String id;

  /// A tap (not a drag) on the model, where it hit.
  final ValueChanged<KitchenPoint>? onTap;

  /// Fades the room's edges into the page.
  final bool vignette;
  final Color background;
  final bool zoom;

  @override
  State<Kitchen3D> createState() => _Kitchen3DState();
}

/// Drives the viewer: camera shots, door animations and cabinet colour.
class Kitchen3DController {
  WebViewController? _web;
  String _id = 'kitchen3d';

  static const cabinetMaterial = 'r15_classic_painted_timber';

  Future<void> _run(String body) => runViewerJs(
    "(function(){const mv=document.querySelector('#$_id');"
    "if(!mv||!mv.loaded)return;$body})();",
    _web,
  );

  static const _home =
      "mv.cameraTarget='auto auto auto';"
      "mv.cameraOrbit='45deg 58deg auto';mv.fieldOfView='11.5deg';";

  /// The isometric overview.
  Future<void> overview() => _run(_home);

  /// Turns to face the fridge (or freezer) and opens its door.
  Future<void> open({bool freezer = false}) => _run(
    "mv.cameraTarget='3.15m ${freezer ? '1.7m' : '0.95m'} -2.9m';"
    "mv.cameraOrbit='0deg ${freezer ? '78deg' : '84deg'} 4.4m';"
    "mv.fieldOfView='40deg';"
    "mv.timeScale=1;"
    "mv.animationName='${freezer ? 'freezer_open' : 'fridge_open'}';"
    "mv.currentTime=0;mv.play({repetitions:1});",
  );

  /// Swings the open door shut while the camera goes back to the overview.
  Future<void> close() => _run(
    "if(mv.animationName){mv.timeScale=-1;mv.currentTime=mv.duration;"
    "mv.play({repetitions:1});}"
    // Reverse play is not reliable everywhere: make sure the door ends shut.
    "setTimeout(()=>{mv.pause();mv.timeScale=1;mv.currentTime=0;},1200);"
    "$_home",
  );

  /// Closer and lower, over the middle of the floor where the dining table
  /// stands (Codex is adding it to the scene).
  Future<void> table() => _run(
    "mv.cameraTarget='1.95m 0.5m -1.65m';"
    "mv.cameraOrbit='45deg 66deg 3.4m';mv.fieldOfView='30deg';",
  );

  /// Repaints every cabinet in [color]; null restores the rendered colour.
  Future<void> cabinets(Color? color) {
    final value = color == null
        ? 'window.__sofraCabinet'
        : '[${_linear(color.r)},${_linear(color.g)},${_linear(color.b)},1]';
    return _run(
      "const m=mv.model.materials.find(x=>x.name==='$cabinetMaterial');"
      "if(!m)return;"
      "window.__sofraCabinet=window.__sofraCabinet||"
      "m.pbrMetallicRoughness.baseColorFactor.slice();"
      "m.pbrMetallicRoughness.setBaseColorFactor($value);",
    );
  }
}

/// glTF colour factors are linear; swatches are sRGB.
double _linear(double c) =>
    c <= .04045 ? c / 12.92 : math.pow((c + .055) / 1.055, 2.4).toDouble();

class _Kitchen3DState extends State<Kitchen3D> {
  Timer? _setup;

  String get _channel => 'SofraKitchen_${widget.id}';

  @override
  void initState() {
    super.initState();
    widget.controller._id = widget.id;
    registerViewerChannel(_channel, _message);
    // The element appears a little after the widget; hook it up once found.
    var tries = 0;
    _setup = Timer.periodic(const Duration(milliseconds: 400), (t) {
      if (++tries > 40) t.cancel();
      runViewerJs(_hookJs, widget.controller._web);
    });
  }

  @override
  void dispose() {
    _setup?.cancel();
    super.dispose();
  }

  void _message(String text) {
    final p = (jsonDecode(text) as List).cast<num>();
    widget.onTap?.call((
      x: p[0].toDouble(),
      y: p[1].toDouble(),
      z: p[2].toDouble(),
    ));
  }

  /// Idempotent: forwards taps (glTF y-up to Blender z-up) and applies the
  /// edge fade. Drags that orbit the camera are not taps.
  String get _hookJs {
    final fade = widget.vignette
        ? "mv.style.webkitMaskImage=mv.style.maskImage="
              "'radial-gradient(ellipse 52% 40% at 50% 50%,#000 58%,transparent 100%)';"
        : '';
    return "(function(){const mv=document.querySelector('#${widget.id}');"
        "if(!mv||mv.__sofra)return;mv.__sofra=1;$fade"
        "let down=null;"
        "mv.addEventListener('pointerdown',e=>{down=[e.clientX,e.clientY];});"
        "mv.addEventListener('click',e=>{"
        "if(down&&Math.hypot(e.clientX-down[0],e.clientY-down[1])>8)return;"
        "const h=mv.positionAndNormalFromPoint(e.clientX,e.clientY);"
        "const c=window['$_channel'];if(!h||!c)return;"
        "const p=h.position;c.postMessage(JSON.stringify([p.x,-p.z,p.y]));});"
        "})();";
  }

  @override
  Widget build(BuildContext context) => ModelViewer(
    id: widget.id,
    // The web serves Flutter assets one folder deeper.
    src: kIsWeb
        ? 'assets/assets/spike3d/kitchen.glb'
        : 'assets/spike3d/kitchen.glb',
    alt: 'المطبخ ثلاثي الأبعاد',
    backgroundColor: widget.background,
    cameraOrbit: '45deg 58deg auto',
    fieldOfView: '11.5deg',
    minFieldOfView: '10deg',
    minCameraOrbit: '-10deg 20deg 1m',
    maxCameraOrbit: '100deg 88deg auto',
    cameraControls: true,
    disablePan: true,
    disableZoom: !widget.zoom,
    interactionPrompt: InteractionPrompt.none,
    environmentImage: 'neutral',
    exposure: 2.1,
    shadowIntensity: 0,
    debugLogging: false,
    javascriptChannels: {
      JavascriptChannel(
        _channel,
        onMessageReceived: (m) => _message(m.message),
      ),
    },
    onWebViewCreated: (c) => widget.controller._web = c,
  );
}
