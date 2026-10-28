import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'asset_server.dart';
import 'js_runner.dart';

/// Which kitchen the viewer loads. `r24` (the default) is Codex's R25
/// mobile export of the R24 kitchen (`kitchen-mobile.glb`: 7.2MB Draco,
/// ~148k triangles, 768px colour / 512px normal pages on UV0, the Cycles
/// bounce light as a lightmap on UV1, hinged doors and the fridge, freezer
/// and microwave clips). Not yet tested on a phone or visually approved.
/// `spike` is the older vertex-baked model.
/// Build with `--dart-define=SOFRA_KITCHEN=spike` to go back.
const kitchenModel = String.fromEnvironment(
  'SOFRA_KITCHEN',
  defaultValue: 'r24',
);
bool get _r24 => kitchenModel == 'r24';

/// Bounce lightmap scale per lighting mode, printed by
/// `tool/scene3d/bounce_to_png.py` when it wrote the PNGs.
const _bounceScale = {'morning': 1.5039, 'golden': .9639, 'night': .2241};

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
    this.zoom = false,
  });
  final Kitchen3DController controller;

  /// DOM id; two viewers on screen at once need different ids.
  final String id;

  /// A tap (not a drag) on the model, where it hit.
  final ValueChanged<KitchenPoint>? onTap;

  /// Fades the room's edges into the page.
  final bool vignette;
  final Color background;

  /// Kept for callers; the camera is fixed, so it has no effect.
  final bool zoom;

  @override
  State<Kitchen3D> createState() => _Kitchen3DState();
}

/// Drives the viewer: camera shots, door animations and cabinet colour.
/// The camera moves in three scenes only: the isometric overview, the zoom
/// to the table and the turn to the fridge or microwave.
class Kitchen3DController {
  WebViewController? _web;
  String _id = 'kitchen3d';

  static const cabinetMaterial = 'r15_classic_painted_timber';

  Future<void> _run(String body) => runViewerJs(
    "(function(){const mv=document.querySelector('#$_id');"
    "if(!mv||!mv.loaded)return;$body})();",
    _web,
  );

  // R24 carries the garden and sky outside the window, so 'auto' would frame
  // those too: the room's own centre and distance instead.
  static final _homeTarget = _r24 ? '1.76m 1.26m -1.65m' : 'auto auto auto';
  static final _homeOrbit = _r24 ? '45deg 58deg 34m' : '45deg 58deg auto';

  static final _home =
      "${_r24 ? 'mv.__shut&&mv.__shut();' : ''}"
      "mv.cameraTarget='$_homeTarget';"
      "mv.cameraOrbit='$_homeOrbit';mv.fieldOfView='11.5deg';"
      "if(mv.__mask)mv.style.maskImage=mv.style.webkitMaskImage=mv.__mask;";

  /// The isometric overview.
  Future<void> overview() => _run(_home);

  /// Turns to face the fridge (or freezer) and opens its door.
  Future<void> open({bool freezer = false}) => _run(
    "mv.cameraTarget='3.15m ${freezer ? '1.7m' : '0.95m'} -2.9m';"
    "mv.cameraOrbit='0deg ${freezer ? '78deg' : '84deg'} 4.4m';"
    "mv.fieldOfView='40deg';"
    "${_r24 ? "mv.__door&&mv.__door('r18_${freezer ? 'freezer' : 'fridge'}_hinge',-1.75);" : "mv.timeScale=1;"
              "mv.animationName='${freezer ? 'freezer_open' : 'fridge_open'}';"
              "mv.currentTime=0;mv.play({repetitions:1});"}",
  );

  /// Swings the open door shut while the camera goes back to the overview.
  Future<void> close() => _run(
    _r24
        ? "mv.__shut&&mv.__shut();$_home"
        : "if(mv.animationName){mv.timeScale=-1;mv.currentTime=mv.duration;"
              "mv.play({repetitions:1});}"
              // Reverse play is not reliable everywhere: make sure the door
              // ends shut.
              "setTimeout(()=>{mv.pause();mv.timeScale=1;mv.currentTime=0;},1200);"
              "$_home",
  );

  /// R24 only: swaps the probe and bounce lightmap to the time of day.
  /// Kept on the element even before the model loads, so the first light
  /// is the right one.
  Future<void> lighting(String mode) => _r24
      ? runViewerJs(
          "(function(){const mv=document.querySelector('#$_id');if(!mv)return;"
          "mv.__mode='$mode';if(mv.loaded&&mv.__light)mv.__light('$mode');})();",
          _web,
        )
      : Future.value();

  /// At the near corner of the dining table, eyes about 1.55 m up, looking
  /// across it into the kitchen: table and vase low in front, window left,
  /// stove right. Codex's R24c framing (position 3.65, 1.55, 1.05 looking at
  /// 1.6, 1.05, -2.15, fov 58), put as an orbit. The move from the isometric
  /// overview is the zoom.
  Future<void> table() => _run(
    "mv.cameraTarget='1.6m 1.05m -2.15m';"
    "mv.cameraOrbit='32.6deg 82.5deg 3.83m';mv.fieldOfView='58deg';"
    // Seated, the room fills the screen: no edge fade.
    "mv.style.maskImage=mv.style.webkitMaskImage='none';",
  );

  /// Turns to the microwave on the back counter; on R24 its door opens too
  /// (`microwave_open`). The overview shuts it again.
  Future<void> microwave() => _run(
    // R24 moved it onto the counter by the window (`microwave_root`).
    "${_r24 ? "mv.cameraTarget='0.48m 1.07m -3.1m';mv.cameraOrbit='10deg 82deg 1.7m';" : "mv.cameraTarget='1m 1.08m -3.3m';mv.cameraOrbit='15deg 80deg 2.1m';"}"
    "mv.fieldOfView='45deg';"
    "${_r24 ? "mv.timeScale=1;mv.animationName='microwave_open';"
              "mv.currentTime=0;mv.play({repetitions:1});" : ''}",
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

  /// Where the viewer fetches lighting files; null until known.
  String? _assetBase;

  String get _channel => 'SofraKitchen_${widget.id}';

  @override
  void initState() {
    super.initState();
    widget.controller._id = widget.id;
    registerViewerChannel(_channel, _message);
    // The element appears a little after the widget; hook it up once found.
    if (_r24) viewerAssetBase().then((b) => _assetBase = b);
    var tries = 0;
    _setup = Timer.periodic(const Duration(milliseconds: 400), (t) {
      if (++tries > 60) t.cancel();
      // R24 needs the lighting files' address before hooking up.
      if (_r24 && _assetBase == null) return;
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
  /// edge fade. Drags (scrolling past the view) are not taps.
  String get _hookJs {
    final fade = widget.vignette
        ? "mv.__mask=mv.style.webkitMaskImage=mv.style.maskImage="
              "'radial-gradient(ellipse 52% 40% at 50% 50%,#000 58%,transparent 100%)';"
        : '';
    return "(function(){const mv=document.querySelector('#${widget.id}');"
        "if(!mv||mv.__sofra)return;mv.__sofra=1;$fade${_r24 ? _r24Js : ''}"
        "let down=null;"
        "mv.addEventListener('pointerdown',e=>{down=[e.clientX,e.clientY];});"
        "mv.addEventListener('click',e=>{"
        "if(down&&Math.hypot(e.clientX-down[0],e.clientY-down[1])>8)return;"
        "const h=mv.positionAndNormalFromPoint(e.clientX,e.clientY);"
        "const c=window['$_channel'];if(!h||!c)return;"
        "const p=h.position;c.postMessage(JSON.stringify([p.x,-p.z,p.y]));});"
        "})();";
  }

  /// R24 setup, run once per viewer after load: hides the review-only
  /// shadow catchers and the outdoor trees, puts the bounce lightmap on UV1
  /// of the baked (non-metal, non-glass) materials like Codex's viewer, and
  /// adds the door helpers. model-viewer keeps three.js private, so this
  /// reaches its scene through the element's `scene` symbol (experiment).
  String get _r24Js {
    final base = '$_assetBase/assets/spike3d/r24';
    final scales = _bounceScale.entries
        .map((e) => "${e.key}:${e.value}")
        .join(',');
    return "mv.setAttribute('tone-mapping','agx');"
        "const go=()=>{const k=Object.getOwnPropertySymbols(mv)"
        ".find(x=>x.description==='scene');const sc=k&&mv[k];if(!sc)return;"
        "const baked=[],gone=[],lamps=[];let Tex=null;"
        "sc.traverse(o=>{if(!o.isMesh)return;const u=o.userData||{};"
        "if(u.reviewShadowOnly||u.r22_large_sky_backdrop||o.name.startsWith('r22_exterior_')||"
        "o.name.startsWith('exterior_')){gone.push(o);return;}"
        "for(const m of [].concat(o.material)){if(m.map&&!Tex)Tex=m.map.constructor;"
        "if(m.name==='r18_fridge_lamp_diffuser'&&!lamps.includes(m)){m.emissiveIntensity=0;lamps.push(m);}"
        "if(!u.reviewDynamic&&m.isMeshStandardMaterial&&m.metalness<.65&&"
        "!(m.transmission>.05)){"
        "if(o.geometry.attributes.uv&&!o.geometry.attributes.uv1)"
        "o.geometry.setAttribute('uv1',o.geometry.attributes.uv.clone());"
        "baked.push(m);}}});"
        // Removed, not hidden: the garden and sky would still size the
        // framing and push the near plane past the table.
        "gone.forEach(o=>o.parent.remove(o));mv.updateFraming();"
        "const S={$scales},maps={};"
        "mv.__light=mode=>{mv.environmentImage='$base/probe-'+mode+'.hdr';"
        "if(!Tex)return;const use=t=>{for(const m of baked){m.lightMap=t;"
        "m.lightMapIntensity=S[mode]*Math.PI;m.needsUpdate=true;}"
        "sc.queueRender&&sc.queueRender();};"
        "if(maps[mode])return use(maps[mode]);const img=new Image();"
        "img.crossOrigin='anonymous';img.onload=()=>{const t=new Tex(img);t.flipY=false;t.channel=1;"
        "t.colorSpace='srgb';t.needsUpdate=true;maps[mode]=t;use(t);};"
        "img.src='$base/bounce-'+mode+'.png';};"
        "const swing=(name,to)=>{const o=sc.getObjectByName(name);if(!o)return;"
        "const from=o.rotation.y,t0=performance.now();const step=t=>{"
        "const f=Math.min(1,(t-t0)/900),e=1-Math.pow(1-f,3);"
        "o.rotation.y=from+(to-from)*e;"
        // The fridge lamp follows the door angle (off shut, full by ~20°).
        "const a=Math.abs(o.rotation.y),l=Math.min(1,Math.max(0,(a-.035)/.315));"
        "for(const m of lamps)m.emissiveIntensity=1.5*l*l*(3-2*l);"
        "sc.queueRender&&sc.queueRender();"
        "if(f<1)requestAnimationFrame(step);};requestAnimationFrame(step);};"
        "mv.__door=swing;"
        "mv.__shut=()=>{swing('r18_fridge_hinge',0);swing('r18_freezer_hinge',0);"
        "if(mv.animationName==='microwave_open'&&mv.currentTime>0){"
        "mv.timeScale=-1;mv.play({repetitions:1});setTimeout(()=>{mv.pause();"
        "mv.timeScale=1;mv.currentTime=0;},1300);}};"
        // No mode from the app yet: the hour, on the app's lighting schedule.
        "const h=new Date().getHours()+new Date().getMinutes()/60;"
        "mv.__light(mv.__mode||(h>=18.5||h<5?'night':h<6.5||h>=16.5?'golden':'morning'));};"
        "if(mv.loaded)go();else mv.addEventListener('load',go,{once:true});";
  }

  @override
  Widget build(BuildContext context) => ModelViewer(
    id: widget.id,
    // The web serves Flutter assets one folder deeper.
    src: _r24
        ? (kIsWeb
              ? 'assets/assets/spike3d/r24/kitchen.glb'
              : 'assets/spike3d/r24/kitchen.glb')
        : kIsWeb
        ? 'assets/assets/spike3d/kitchen.glb'
        : 'assets/spike3d/kitchen.glb',
    alt: 'المطبخ ثلاثي الأبعاد',
    backgroundColor: widget.background,
    cameraTarget: Kitchen3DController._homeTarget,
    cameraOrbit: Kitchen3DController._homeOrbit,
    fieldOfView: '11.5deg',
    minFieldOfView: '10deg',
    maxFieldOfView: '70deg',
    minCameraOrbit: 'auto auto 0.3m',
    maxCameraOrbit: 'auto 100deg auto',
    // Fixed shots only: the room is not something to spin around like a
    // game. The app moves the camera (overview, fridge, table); taps still
    // reach the zones.
    cameraControls: false,
    disablePan: true,
    disableZoom: true,
    interactionPrompt: InteractionPrompt.none,
    // R24 swaps in its probe HDR once loaded (`lighting`); the phone's
    // WebView can only reach those files through the asset server.
    environmentImage: 'neutral',
    exposure: _r24 ? .8 : 2.1,
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
