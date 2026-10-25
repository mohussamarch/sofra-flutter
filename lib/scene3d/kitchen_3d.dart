import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'js_runner.dart';

/// 3D-engine spike: the Blender kitchen as a real-time model
/// (`assets/spike3d/kitchen.glb`, exported by `tool/scene3d/export_glb.py`).
/// Cabinet colours change live and the fridge opens in place, with no render
/// per option. Lighting is the viewer's neutral environment, not the baked
/// Cycles light of the 2.5D scene yet.
class Kitchen3D extends StatefulWidget {
  const Kitchen3D({super.key, required this.controller});
  final Kitchen3DController controller;

  @override
  State<Kitchen3D> createState() => _Kitchen3DState();
}

/// Drives the viewer: camera shots, door animations and cabinet colour.
class Kitchen3DController {
  WebViewController? _web;

  static const _id = 'kitchen3d';
  static const cabinetMaterial = 'r15_classic_painted_timber';

  Future<void> _run(String body) => runViewerJs(
    "(function(){const mv=document.querySelector('#$_id');"
    "if(!mv||!mv.loaded)return;$body})();",
    _web,
  );

  /// The isometric overview, doors closed.
  Future<void> overview() => _run(
    "mv.pause();mv.currentTime=0;"
    "mv.cameraTarget='auto auto auto';"
    "mv.cameraOrbit='45deg 58deg 105%';mv.fieldOfView='14deg';",
  );

  /// Turns to face the fridge (or freezer) and opens its door.
  Future<void> open({bool freezer = false}) => _run(
    "mv.cameraTarget='3.15m ${freezer ? '1.7m' : '0.95m'} -2.9m';"
    "mv.cameraOrbit='0deg ${freezer ? '78deg' : '84deg'} 3.6m';"
    "mv.fieldOfView='40deg';"
    "mv.animationName='${freezer ? 'freezer_open' : 'fridge_open'}';"
    "mv.currentTime=0;mv.play({repetitions:1});",
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
  @override
  Widget build(BuildContext context) => ModelViewer(
    id: Kitchen3DController._id,
    // The web serves Flutter assets one folder deeper.
    src: kIsWeb
        ? 'assets/assets/spike3d/kitchen.glb'
        : 'assets/spike3d/kitchen.glb',
    alt: 'المطبخ ثلاثي الأبعاد',
    backgroundColor: const Color(0xFF15100C),
    cameraOrbit: '45deg 58deg 105%',
    fieldOfView: '14deg',
    minFieldOfView: '10deg',
    minCameraOrbit: 'auto 20deg 1m',
    maxCameraOrbit: 'auto 88deg auto',
    cameraControls: true,
    disablePan: true,
    interactionPrompt: InteractionPrompt.none,
    environmentImage: 'neutral',
    exposure: 1.05,
    shadowIntensity: .6,
    debugLogging: false,
    onWebViewCreated: (c) => widget.controller._web = c,
  );
}
