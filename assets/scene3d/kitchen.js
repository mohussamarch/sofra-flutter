// The Sofra kitchen viewer: the room as a real-time scene with the hybrid
// lighting the owner chose (Cycles bounce light baked into lightmaps, plus a
// live sun, window light, ceiling lamp, under-cabinet LEDs and fridge lamps
// with real shadows). It runs inside the app (a WebView on the phone, an
// iframe on the web) and draws only when something changes.
//
// The host sends state as JSON through `window.sofraKitchen(msg)` or a
// `message` event, any subset of:
//   {shot: 'home'|'fridge'|'freezer'|'microwave'|'table',
//    weights: {morning, golden, night}, look: {...}, vignette: bool,
//    calm: bool, hud: bool, pick: [x, y]}  // pick: 0..1 across the view
// and gets back {t: 'hello'|'ready'|'tap'|'error'|'warn'|'perf', ...}.
// Protocol and design notes: docs/dev/KITCHEN-3D.md.
//
// Lighting follows Codex's R24 review viewer (design-assets, not in git):
// light powers, colours and directions are the Blender masters' own.
import * as THREE from './vendor/three.module.min.js';
import { GLTFLoader } from './vendor/GLTFLoader.js';
import { DRACOLoader } from './vendor/DRACOLoader.js';
import { HDRLoader } from './vendor/HDRLoader.js';

const params = new URLSearchParams(location.search);
const view = document.getElementById('view');
const hud = document.getElementById('hud');
const assets = params.get('assets') || '../spike3d/r24/';
if (params.get('bg')) document.body.style.background = '#' + params.get('bg'); // standalone trials

function post(message) {
  const text = JSON.stringify(message);
  if (window.SofraKitchen) window.SofraKitchen.postMessage(text);
  else if (parent !== window) parent.postMessage({ sofraKitchen: params.get('id') || '', data: text }, '*');
  if (params.has('log')) console.log('sofra', text);
}
// A stray script error once the room is up is reported but is not the end
// of it. Before that, any error means the room will not appear.
let lastWarning = '', started = false;
function warn(message) {
  lastWarning = String(message && message.message || message).slice(0, 200);
  post({ t: started ? 'warn' : 'error', message: lastWarning });
  if (!started) hud.textContent = '! ' + lastWarning;
}
window.addEventListener('error', (e) => warn(e.message));
window.addEventListener('unhandledrejection', (e) => warn(e.reason));

// The shader patches below edit three's own shader text. If a three update
// changes that text, fail loudly instead of drawing wrong light.
if (THREE.REVISION !== '180') throw new Error('kitchen.js patches three r180, found r' + THREE.REVISION);
function patch(text, find, replacement) {
  if (!text.includes(find)) throw new Error('three shader text changed: ' + find.slice(0, 48));
  return text.replace(find, replacement);
}

// ---------------------------------------------------------------- quality
const phone = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent) || matchMedia('(pointer: coarse)').matches;
const tier = params.get('q') || (phone ? 'phone' : 'desk');
// Shadow maps keep the sizes their biases were tuned for (Codex R24). The
// phone draws glass without refraction, which would draw the room twice.
const Q = { dpr: 2, minDpr: 1.5, taps: 16, sun: 2048, window: 1024, lamp: 2048, inside: 512, refract: tier === 'desk' };
let pixelRatio = Math.min(devicePixelRatio || 1, Q.dpr);

// A disk of taps instead of three's square grid: an even, round penumbra.
// The disk turns per pixel, so 16 taps read as a soft edge, not steps (32
// unrolled taps for five lights made the shaders take seconds to build).
// Each tap is compared against the receiving surface's own depth at that
// tap (receiver-plane bias), so a wide disk on a wall lit at a low angle
// does not shadow itself into stripes. SLOPE caps how far a tap's depth may
// follow the surface: enough to stop stripes, little enough that stickers
// and handles close to a door stay lit.
const SLOPE = '0.00100';
function softShadowChunk(chunk) {
  const start = chunk.indexOf('#if defined( SHADOWMAP_TYPE_PCF )', chunk.indexOf('float getShadow('));
  const end = chunk.indexOf('#elif defined( SHADOWMAP_TYPE_PCF_SOFT )', start);
  const test = 'bool frustumTest = inFrustum && shadowCoord.z <= 1.0;';
  if (start < 0 || end < 0 || !chunk.includes(test)) throw new Error('three shadow shader text changed');
  const lines = [
    '#if defined( SHADOWMAP_TYPE_PCF )',
    'vec2 texelSize = vec2( 1.0 ) / shadowMapSize;',
    'shadow = 0.0;',
    'float ign = 6.2831853 * fract( 52.9829189 * fract( dot( gl_FragCoord.xy, vec2( 0.06711056, 0.00583715 ) ) ) );',
    'mat2 turn = mat2( cos( ign ), sin( ign ), - sin( ign ), cos( ign ) );',
    'vec2 tap;',
  ];
  for (let i = 0; i < Q.taps; i++) {
    const r = Math.sqrt((i + .5) / Q.taps), a = i * 2.399963229728653;
    lines.push(
      `tap = turn * vec2( ${(r * Math.cos(a)).toFixed(6)}, ${(r * Math.sin(a)).toFixed(6)} ) * texelSize * shadowRadius;`,
      'shadow += texture2DCompare( shadowMap, shadowCoord.xy + tap, shadowCoord.z + clamp( dot( tap, sofraSlope ), - ' + SLOPE + ', ' + SLOPE + ' ) );');
  }
  lines.push(`shadow *= ${(1 / Q.taps).toFixed(8)};`, '');
  const slope = [
    test,
    'vec3 sofraDx = dFdx( shadowCoord.xyz ), sofraDy = dFdy( shadowCoord.xyz );',
    'float sofraDet = sofraDx.x * sofraDy.y - sofraDx.y * sofraDy.x;',
    'vec2 sofraSlope = abs( sofraDet ) > 1e-12 ? vec2( sofraDy.y * sofraDx.z - sofraDx.y * sofraDy.z, sofraDx.x * sofraDy.z - sofraDy.x * sofraDx.z ) / sofraDet : vec2( 0.0 );',
  ];
  const nl = String.fromCharCode(10);
  return (chunk.slice(0, start) + lines.join(nl) + chunk.slice(end)).replace(test, slope.join(nl));
}
THREE.ShaderChunk.shadowmap_pars_fragment = softShadowChunk(THREE.ShaderChunk.shadowmap_pars_fragment);
// The sun is always in the scene (see lights below). With no power it should
// not cost its shadow taps either: three already does this for spot lights.
THREE.ShaderChunk.lights_pars_begin = patch(THREE.ShaderChunk.lights_pars_begin,
  'light.direction = directionalLight.direction;\n\t\tlight.visible = true;',
  'light.direction = directionalLight.direction;\n\t\tlight.visible = ( directionalLight.color != vec3( 0.0 ) );');

// ---------------------------------------------------------------- renderer
const renderer = new THREE.WebGLRenderer({
  antialias: true, alpha: true, powerPreference: 'high-performance',
  preserveDrawingBuffer: params.has('keep'),
});
renderer.setPixelRatio(pixelRatio);
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.AgXToneMapping; // the Blender masters render through AgX
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFShadowMap;
renderer.shadowMap.autoUpdate = false;
renderer.setClearColor(0x000000, 0);
renderer.info.autoReset = false;
view.prepend(renderer.domElement);
const canvas = renderer.domElement;

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(40, 1, .05, 190);

// ---------------------------------------------------------------- lighting data
const MODES = ['morning', 'golden', 'night'];
// 8-bit lightmaps hold value / scale (tool/scene3d/bounce_to_png.py).
const BOUNCE_SCALE = { morning: 1.5039, golden: .9639, night: .2241 };
// The least bounce light any baked surface gets, per mode. The 2048 lightmap
// is too coarse for grooves, joints and the corners against the hidden walls:
// they bake pure black and read as ink outlines. No surface of a lit room is
// black; this keeps them dark but not drawn on.
const BOUNCE_FLOOR = { morning: .11, golden: .075, night: .03 };
// Shade in this room is warm, not grey.
const FLOOR_TINT = new THREE.Vector3(1, .9, .78);
// From the masters (Codex export-report.json), Blender z-up turned to y-up.
const SUN = {
  morning: { power: 15.36, color: [1, .78, .48], toward: new THREE.Vector3(-.8609, .4649, .2066) },
  golden: { power: 23.04, color: [1, .48, .12], toward: new THREE.Vector3(-.9053, .3621, .2218) },
};
const WINDOW_COLOR = { morning: [.88, .92, 1], golden: [1, .75, .5] };
const LAMP_COLOR = [1, .87, .68];
const ROOM_CENTRE = new THREE.Vector3(1.8, 1.1, -1.8);

// Cycles bakes outgoing radiance of a white surface; three wants irradiance:
// times PI (Codex's unit calibration). Two maps are mixed while the hour turns.
const bounce = {
  sofraBounceB: { value: null }, sofraBlend: { value: 0 },
  sofraScaleA: { value: 1 }, sofraScaleB: { value: 1 }, sofraFloor: { value: new THREE.Vector3() },
};
let bakedChunk = patch(THREE.ShaderChunk.lights_fragment_maps,
  'vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );',
  'vec4 lightMapTexel = mix( texture2D( lightMap, vLightMapUv ) * sofraScaleA, texture2D( sofraBounceB, vLightMapUv ) * sofraScaleB, sofraBlend );\n'
  + '\t\tlightMapTexel.rgb = max( lightMapTexel.rgb, sofraFloor );');
// The lightmap already holds the room's diffuse bounce: no probe diffuse on top.
bakedChunk = patch(bakedChunk, 'iblIrradiance += getIBLIrradiance( geometryNormal );', '');
function bakeInto(material) {
  material.onBeforeCompile = (shader) => {
    Object.assign(shader.uniforms, bounce);
    shader.fragmentShader = 'uniform sampler2D sofraBounceB;\nuniform float sofraBlend, sofraScaleA, sofraScaleB;\nuniform vec3 sofraFloor;\n'
      + patch(shader.fragmentShader, '#include <lights_fragment_maps>', bakedChunk);
  };
  material.customProgramCacheKey = () => 'sofra-baked';
  material.lightMapIntensity = Math.PI;
}

// ---------------------------------------------------------------- lights
// One fixed set, always on the scene: turning a light on or off only changes
// its power, so shaders never rebuild. A shadow map is drawn only for a
// light that has power, and only when what it sees has changed.
const sun = new THREE.DirectionalLight(0xffffff, 0);
sun.castShadow = true;
sun.shadow.mapSize.set(Q.sun, Q.sun);
Object.assign(sun.shadow.camera, { left: -4.5, right: 4.5, top: 4.5, bottom: -4.5, near: .1, far: 25 });
sun.shadow.bias = -.0001; sun.shadow.normalBias = .008; sun.shadow.radius = 6;
sun.target.position.copy(ROOM_CENTRE);

// The window's sky light (an area light in Blender, a wide soft spot here).
const windowLight = new THREE.SpotLight(0xffffff, 0, 12, 1.03, .85, 2);
windowLight.position.set(-.15, 1.75, -2.1);
windowLight.target.position.set(2, 1.2, -2.1);
windowLight.castShadow = true;
windowLight.shadow.mapSize.set(Q.window, Q.window);
// The window wall is centimetres from this light: a near plane further out
// skips it and the light leaks through the wall (Codex R23 finding).
windowLight.shadow.camera.near = .02;
windowLight.shadow.bias = -.00015; windowLight.shadow.normalBias = .009; windowLight.shadow.radius = 7;

const lamp = new THREE.SpotLight(0xffffff, 0, 12, 1.32, .9, 2);
lamp.position.set(1.95, 2.63, -1.65);
lamp.target.position.set(1.95, 0, -1.65);
lamp.castShadow = true;
lamp.shadow.mapSize.set(Q.lamp, Q.lamp);
lamp.shadow.bias = -.00015; lamp.shadow.normalBias = .007; lamp.shadow.radius = 7;
lamp.color.setRGB(...LAMP_COLOR);

// Fridge and freezer lamps: two lights, moved to the chosen fridge's lamps.
const insideLights = ['fridge', 'freezer'].map((part) => {
  const light = new THREE.SpotLight(0xffe9c7, 0, 1.8, 1.05, .8, 2);
  light.name = 'inside_' + part;
  light.castShadow = true;
  light.shadow.mapSize.set(Q.inside, Q.inside);
  light.shadow.camera.near = .01;
  light.shadow.bias = -.001; light.shadow.normalBias = .001;
  return light;
});
const roomLights = [sun, windowLight, lamp];
const shadowLights = [...roomLights, ...insideLights];
for (const light of shadowLights) {
  light.shadow.autoUpdate = false;
  light.userData.stale = true;
  scene.add(light, light.target);
}
const stale = (lights) => { for (const l of lights) l.userData.stale = true; };
// Under-cabinet LEDs: short warm spots that stop above the floor, so no
// shadow map is needed to keep them from passing through the worktop.
const leds = [];

// ---------------------------------------------------------------- sky
// Seen only through the window opening, so the page shows around the room.
const skyUniforms = {
  uNight: { value: 0 }, uGold: { value: 0 }, uSun: { value: new THREE.Vector3(-.8, .4, 0) },
  uWindow: { value: new THREE.Vector4(0, 3, -4, 0) },
};
const sky = new THREE.Mesh(new THREE.SphereGeometry(90, 32, 16), new THREE.ShaderMaterial({
  side: THREE.BackSide, depthWrite: false, toneMapped: false, uniforms: skyUniforms,
  vertexShader: 'varying vec3 vWorld;void main(){vec4 w=modelMatrix*vec4(position,1.);vWorld=w.xyz;gl_Position=projectionMatrix*viewMatrix*w;}',
  fragmentShader: `varying vec3 vWorld;uniform float uNight,uGold;uniform vec3 uSun;uniform vec4 uWindow;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void main(){vec3 ray=normalize(vWorld-cameraPosition);
if(cameraPosition.x>.05){if(ray.x>=-.0001)discard;vec3 hit=cameraPosition+ray*(-cameraPosition.x/ray.x);
if(hit.y<uWindow.x||hit.y>uWindow.y||hit.z<uWindow.z||hit.z>uWindow.w)discard;}else discard;
float h=clamp(ray.y*.5+.5,0.,1.);
vec3 day=mix(vec3(.63,.79,.91),vec3(.16,.40,.68),pow(h,.7));
vec3 gold=mix(vec3(1.,.58,.28),vec3(.24,.36,.55),smoothstep(.22,.84,h));
vec3 night=mix(vec3(.018,.036,.072),vec3(.004,.008,.022),h);
vec3 col=mix(mix(day,gold,uGold),night,uNight);
float glow=pow(max(0.,dot(ray,normalize(uSun))),48.);col+=vec3(1.,.61,.29)*glow*uGold*(1.-uNight)*.62;
vec2 uv=vec2(atan(ray.z,ray.x)/6.2831853+.5,asin(ray.y)/3.14159265+.5);vec2 grid=uv*vec2(520.,260.);
vec2 cell=floor(grid);vec2 f=fract(grid)-.5;vec2 offset=vec2(hash(cell+2.),hash(cell+7.))*.6-.3;
float star=(1.-smoothstep(.025,.095,length(f-offset)))*step(.96,hash(cell))*smoothstep(-.65,-.05,ray.y)*uNight;
col+=vec3(.72,.81,1.)*star*.9;gl_FragColor=vec4(col,1.);
#include <colorspace_fragment>
}`,
}));
sky.frustumCulled = false;
sky.renderOrder = -20;
scene.add(sky);

// ---------------------------------------------------------------- state
const DEFAULT_LOOK = { style: 'classic', fridge: 'default', range: 'default', rug: 'none', curtain: 'gingham' };
const state = {
  shot: 'home',
  look: { ...DEFAULT_LOOK },
  weights: null, // null: the clock decides
  vignette: params.get('vignette') === '1',
  calm: matchMedia('(prefers-reduced-motion: reduce)').matches,
};
let root = null, ready = false;
const light = { now: [1, 0, 0], from: [1, 0, 0], to: [1, 0, 0], t0: 0, moving: false };

// The hour's weights when the host has not sent any: the page on its own.
// In the app the host sends its lighting schedule.
function clockWeights() {
  const d = new Date(), t = d.getHours() + d.getMinutes() / 60;
  if (t < 5) return [0, 0, 1];
  if (t < 6.5) { const k = (t - 5) / 1.5; return [0, k, 1 - k]; }
  if (t < 8) { const k = (t - 6.5) / 1.5; return [k, 1 - k, 0]; }
  if (t < 15) return [1, 0, 0];
  if (t < 17.5) { const k = (t - 15) / 2.5; return [1 - k, k, 0]; }
  if (t < 20.5) { const k = (t - 17.5) / 3; return [0, 1 - k, k]; }
  return [0, 0, 1];
}
function weightsOf(map) {
  if (!map) return clockWeights();
  const w = MODES.map((m) => Math.max(0, +map[m] || 0)), total = w[0] + w[1] + w[2];
  return total > 0 ? w.map((x) => x / total) : clockWeights();
}

// ---------------------------------------------------------------- textures
// Loaded once each; a failed load may be asked for again.
const lightmaps = {}, probes = {}, loading = {};
const textureLoader = new THREE.TextureLoader();
let pmrem = null;
function once(key, load) {
  return loading[key] ||= load().catch((e) => { delete loading[key]; throw e; });
}
function loadLightmap(mode) {
  return once('b' + mode, () => textureLoader.loadAsync(assets + 'bounce-' + mode + '.png').then((t) => {
    t.flipY = false; t.channel = 1; t.colorSpace = THREE.SRGBColorSpace;
    t.generateMipmaps = false; t.minFilter = THREE.LinearFilter;
    lightmaps[mode] = t;
  }));
}
function loadProbe(mode) {
  return once('p' + mode, () => new HDRLoader().loadAsync(assets + 'probe-' + mode + '.hdr').then((hdr) => {
    hdr.mapping = THREE.EquirectangularReflectionMapping;
    pmrem ||= new THREE.PMREMGenerator(renderer);
    probes[mode] = pmrem.fromEquirectangular(hdr).texture;
    hdr.dispose();
  }));
}
// Asks for a file the light needs and applies the light again when it lands;
// asking many times while it loads adds nothing.
const wanted = new Set();
function want(key, load) {
  if (wanted.has(key)) return;
  wanted.add(key);
  load().then(() => { wanted.delete(key); applyLight(); }, (e) => { wanted.delete(key); warn(e); });
}

// ---------------------------------------------------------------- scene parts
const baked = [], lampMaterials = [], doorParts = {}, pickable = [];
const insideSpots = []; // {model, part, position, target}
const variants = new Map();
const hiddenMaterial = new THREE.MeshBasicMaterial({ colorWrite: false, depthWrite: false, side: THREE.DoubleSide });
const paintMaterials = [];
let fitBox = new THREE.Box3();

function materialFor(source, mesh, isBaked) {
  const key = source.uuid + (isBaked ? 'b' : 'd') + (mesh.geometry.attributes.uv1 ? '1' : '0');
  let m = variants.get(key);
  if (m) return m;
  m = source.clone();
  if (isBaked) { bakeInto(m); baked.push(m); }
  // The options library's shared atlas carries coarser normals. Scaled, not
  // set: the loader has already flipped y for these tangent-less meshes.
  if (m.normalMap && !mesh.geometry.attributes.uv1) m.normalScale.multiplyScalar(.35);
  if (m.transmission > .05) {
    m.depthWrite = false;
    if (Q.refract) { m.opacity = 1; m.thickness = .006; m.ior = 1.46; }
    // Refraction draws the whole room a second time: on the phone glass is
    // plain see-through with the room's reflections, as clear as it was.
    else { m.opacity = 1 - .62 * m.transmission; m.transmission = 0; m.transparent = true; m.roughness = Math.min(m.roughness, .12); }
  }
  if (m.name === 'r18_fridge_lamp_diffuser' || m.name === 'r19_double_diffuser') { m.emissiveIntensity = 0; lampMaterials.push(m); }
  if (m.name === 'r15_classic_painted_timber') { m.userData.base = m.color.clone(); paintMaterials.push(m); }
  variants.set(key, m);
  return m;
}

function setUp(gltf) {
  root = gltf.scene;
  scene.add(root);
  root.updateMatrixWorld(true);
  const gone = [], windowBox = new THREE.Box3(), tileBox = new THREE.Box3(), walls = [], hiddenWalls = [];
  root.traverse((o) => {
    if (!o.isMesh) return;
    const u = o.userData || {};
    // The garden and sky backdrop of the review file: the sky here is a shader.
    if (u.r22_large_sky_backdrop || o.name.startsWith('r22_exterior_') || o.name.startsWith('exterior_') || o.name === 'window_view_no_illumination') { gone.push(o); return; }
    if (/^window_(side|sill|mullion|horizontal|crossbar)/.test(o.name)) windowBox.expandByObject(o);
    o.castShadow = u.reviewCastShadow !== false;
    o.receiveShadow = true;
    const source = o.material;
    const glass = source.transmission > .05;
    const floorTile = /^(tile_|border_)/.test(o.name);
    // Glass passes light. Tiles are flat: their only shadow would be acne in
    // their own joints. Rug fringe is hair-thin: its shadow is a barcode.
    if (glass || floorTile || source.name.includes('fringe')) o.castShadow = false;
    if (floorTile) tileBox.expandByObject(o);
    if (source.name === 'r13_soft_cream_plaster' && !u.reviewShadowOnly) walls.push(o);
    // Ceiling and the two near walls: never drawn, they only block light
    // (the owner's closed room, cut away for the camera).
    if (u.reviewShadowOnly) { o.material = hiddenMaterial; hiddenWalls.push(new THREE.Box3().setFromObject(o)); return; }
    // The rim around the floor sits outside the closed room, so its baked
    // light is black: it takes the probe's light instead. So does the slab
    // under the tiles, whose joints are finer than the lightmap.
    const outside = o.name.startsWith('border_') || source.name === 'floor';
    const isBaked = !u.reviewDynamic && !outside && !!o.geometry.attributes.uv1
      && source.isMeshStandardMaterial && source.metalness < .65 && !glass;
    o.material = materialFor(source, o, isBaked);
  });
  for (const o of gone) o.parent.remove(o);
  skyUniforms.uWindow.value.set(windowBox.min.y - .04, windowBox.max.y + .04, windowBox.min.z - .04, windowBox.max.z + .04);
  dressCuts(tileBox, walls, hiddenWalls);

  // Doors: the clips' first and last poses, turned by hand so the lamps follow.
  for (const clip of gltf.animations) {
    const track = clip.tracks.find((t) => t.name.endsWith('.quaternion'));
    const node = track && root.getObjectByName(track.name.slice(0, -'.quaternion'.length));
    if (!node) continue;
    const v = track.values, n = v.length;
    doorParts[clip.name.replace('_open', '')] = [{
      node, shut: new THREE.Quaternion(v[0], v[1], v[2], v[3]),
      open: new THREE.Quaternion(v[n - 4], v[n - 3], v[n - 2], v[n - 1]),
    }];
  }
  // The double fridge has no clips: its doors open outwards, short of the chairs.
  const left = root.getObjectByName('r19_double_left_hinge'), right = root.getObjectByName('r19_double_right_hinge');
  const swing = (node, y) => ({ node, shut: node.quaternion.clone(), open: new THREE.Quaternion().setFromEuler(new THREE.Euler(0, y, 0)).premultiply(node.quaternion) });
  if (left && right) doorParts.double = [swing(left, -1.45), swing(right, 1.45)];

  // Where the fridge lamps sit, for both fridges.
  root.traverse((o) => {
    if (!o.isMesh || !/r18_fridge_inner_light_strip|r19_(fridge|freezer)_light_diffuser/.test(o.name)) return;
    const centre = new THREE.Box3().setFromObject(o).getCenter(new THREE.Vector3());
    const model = o.name.startsWith('r19') ? 'double' : 'default';
    const part = model === 'double' ? (o.name.includes('freezer') ? 'freezer' : 'fridge') : (centre.y > 1.5 ? 'freezer' : 'fridge');
    insideSpots.push({
      model, part,
      position: centre.clone().add(new THREE.Vector3(0, -.025, 0)),
      target: centre.clone().add(new THREE.Vector3(0, -.65, .18)),
    });
  });

  // LED strips under the two wall cabinets, placed from the cabinets themselves.
  for (const name of ['upper_prep_600_body', 'upper_buffer_600_body']) {
    const cabinet = root.getObjectByName(name);
    if (!cabinet) continue;
    const box = new THREE.Box3().setFromObject(cabinet), size = box.getSize(new THREE.Vector3()), centre = box.getCenter(new THREE.Vector3());
    const strip = new THREE.Mesh(
      new THREE.BoxGeometry(Math.max(.32, size.x - .08), .012, .026),
      new THREE.MeshBasicMaterial({ color: 0xffd19a, toneMapped: false, transparent: true, opacity: .82 }));
    strip.position.set(centre.x, box.min.y + .008, box.max.z + .012);
    strip.visible = false;
    const led = new THREE.SpotLight(0xffce96, 0, 1.15, 1.2, .9, 2);
    led.position.set(centre.x, box.min.y - .02, box.max.z - .08);
    led.target.position.set(centre.x, box.min.y - 1, box.max.z - .08);
    scene.add(strip, led, led.target);
    leds.push({ strip, light: led });
  }
}

// The room is a closed box in Blender (ceiling and near walls block the
// light), so what the cut-away shows from outside baked black: the joints
// between tiles (finer than the lightmap) and the cut faces of the two far
// walls. Thin planes lit by the room's own light cover them.
function dressCuts(tileBox, walls, hiddenWalls) {
  const add = (width, height, colour, shadowed, place) => {
    const mesh = new THREE.Mesh(new THREE.PlaneGeometry(width, height),
      new THREE.MeshStandardMaterial({ color: colour, roughness: .92, metalness: 0 }));
    place(mesh);
    mesh.receiveShadow = shadowed;
    mesh.userData.dressing = true;
    root.add(mesh);
  };
  if (!tileBox.isEmpty()) {
    // Grout, just under the tiles' faces; furniture shadows fall across it.
    const size = tileBox.getSize(new THREE.Vector3()), centre = tileBox.getCenter(new THREE.Vector3());
    add(size.x, size.z, 0xb3a089, true, (m) => { m.rotation.x = -Math.PI / 2; m.position.set(centre.x, tileBox.max.y - .0025, centre.z); });
  }
  for (const wall of walls) {
    // The cut faces touch the hidden ceiling and walls: a shadow map there
    // is all acne, so they take light without shadows.
    const box = new THREE.Box3().setFromObject(wall), size = box.getSize(new THREE.Vector3()), centre = box.getCenter(new THREE.Vector3());
    const alongX = size.x > size.z;
    add(size.x, size.z, 0xd9cbb6, false, (m) => { m.rotation.x = -Math.PI / 2; m.position.set(centre.x, box.max.y + .002, centre.z); });
    // The end that the cut-away exposes: towards the viewer.
    if (alongX) add(size.z, size.y, 0xd9cbb6, false, (m) => { m.rotation.y = Math.PI / 2; m.position.set(box.max.x + .002, centre.y, centre.z); });
    else add(size.x, size.y, 0xd9cbb6, false, (m) => { m.position.set(centre.x, centre.y, box.max.z + .002); });
    // And the strip of its inner face that a hidden wall butts against.
    for (const hidden of hiddenWalls) {
      const thin = hidden.getSize(new THREE.Vector3());
      if (alongX && thin.x < thin.z && thin.x < thin.y && hidden.min.x < box.max.x && hidden.min.x > centre.x) {
        const width = box.max.x - hidden.min.x;
        add(width, size.y, 0xd9cbb6, false, (m) => { m.position.set(hidden.min.x + width / 2, centre.y, box.max.z + .002); });
      }
      if (!alongX && thin.z < thin.x && thin.z < thin.y && hidden.min.z < box.max.z && hidden.min.z > centre.z) {
        const width = box.max.z - hidden.min.z;
        add(width, size.y, 0xd9cbb6, false, (m) => { m.rotation.y = Math.PI / 2; m.position.set(box.max.x + .002, centre.y, hidden.min.z + width / 2); });
      }
    }
  }
}

// ---------------------------------------------------------------- look
function applyLook() {
  const s = state.look;
  const on = {
    builtin: s.range === 'builtin', default_range: s.range !== 'builtin', default_counter: s.range !== 'builtin',
    default_fridge: s.fridge !== 'double', double_fridge: s.fridge === 'double',
    rug_persian: s.rug === 'rug_persian', rug_teal: s.rug === 'rug_teal', rug_ochre: s.rug === 'rug_ochre',
    white_blind: s.curtain === 'white_blind', default_curtain: s.curtain === 'gingham',
    hanging_plants: s.plants === '1', japandi_cane: s.cane === '1',
  };
  // Codex's rule (r23-options.mjs): a tagged part shows when its group is
  // chosen and its cabinet style matches. Meshes only.
  root.traverse((o) => {
    if (!o.isMesh) return;
    const u = o.userData || {}, style = u.cabinet_style, group = u.option_group;
    const tagged = Object.hasOwn(on, group || '');
    if (!style && !tagged) return;
    o.visible = (!tagged || on[group]) && (!style || style === s.style);
  });
  for (const m of paintMaterials) {
    if (Array.isArray(s.cabinet) && s.cabinet.length >= 3) m.color.setRGB(s.cabinet[0], s.cabinet[1], s.cabinet[2]);
    else m.color.copy(m.userData.base);
  }
  // The two fridge lamps move to the fridge that is showing.
  const model = s.fridge === 'double' ? 'double' : 'default';
  insideLights.forEach((spot, i) => {
    const place = insideSpots.find((p) => p.model === model && p.part === (i === 0 ? 'fridge' : 'freezer'));
    spot.userData.placed = !!place;
    if (!place) return;
    spot.position.copy(place.position);
    spot.target.position.copy(place.target);
  });
  pickable.length = 0;
  fitBox = new THREE.Box3();
  root.traverseVisible((o) => {
    if (!o.isMesh || o.userData.reviewShadowOnly) return;
    if (!o.userData.dressing) pickable.push(o);
    fitBox.expandByObject(o);
  });
  stale(shadowLights);
  invalidate();
}

// ---------------------------------------------------------------- time of day
const sunWas = new THREE.Vector3();
function applyLight() {
  const [day, gold, night] = light.now, daylight = day + gold;
  // The two heaviest modes share the lightmap.
  const order = [0, 1, 2].sort((a, b) => light.now[b] - light.now[a]);
  const a = MODES[order[0]];
  let b = light.now[order[1]] > .001 ? MODES[order[1]] : a;
  if (!lightmaps[a]) { want('b' + a, () => loadLightmap(a)); return; }
  if (!lightmaps[b]) { want('b' + b, () => loadLightmap(b)); b = a; }
  const total = light.now[order[0]] + light.now[order[1]];
  const mix = a === b || total <= 0 ? 0 : light.now[order[1]] / total;
  for (const m of baked) if (m.lightMap !== lightmaps[a]) { const had = !!m.lightMap; m.lightMap = lightmaps[a]; if (!had) m.needsUpdate = true; }
  bounce.sofraBounceB.value = lightmaps[b];
  bounce.sofraBlend.value = mix;
  bounce.sofraScaleA.value = BOUNCE_SCALE[a];
  bounce.sofraScaleB.value = BOUNCE_SCALE[b];
  bounce.sofraFloor.value.copy(FLOOR_TINT).multiplyScalar(BOUNCE_FLOOR.morning * day + BOUNCE_FLOOR.golden * gold + BOUNCE_FLOOR.night * night);
  if (probes[a]) scene.environment = probes[a]; else want('p' + a, () => loadProbe(a));

  const w = Math.max(daylight, 1e-6);
  const toward = SUN.morning.toward.clone().multiplyScalar(day).addScaledVector(SUN.golden.toward, gold);
  if (toward.lengthSq() < 1e-6) toward.copy(SUN.morning.toward);
  toward.normalize();
  sun.position.copy(ROOM_CENTRE).addScaledVector(toward, 9);
  // Only the sun moves with the hour; the other lights' shadows stand.
  if (sun.position.distanceToSquared(sunWas) > 1e-6) { sunWas.copy(sun.position); sun.userData.stale = true; }
  sun.intensity = SUN.morning.power * day + SUN.golden.power * gold;
  sun.color.setRGB(...SUN.morning.color.map((v, i) => (v * day + SUN.golden.color[i] * gold) / w));
  windowLight.intensity = 35 * day + 22 * gold;
  windowLight.color.setRGB(...WINDOW_COLOR.morning.map((v, i) => (v * day + WINDOW_COLOR.golden[i] * gold) / w));
  lamp.intensity = 44 * night; // the master's 53 burns the floor white under AgX here
  const led = state.look.led === '0' ? 0 : Math.pow(night, 1.15);
  for (const f of leds) { f.light.intensity = 2.4 * led; f.strip.visible = led > .015; }
  scene.environmentIntensity = .7;
  scene.environmentRotation.y = -Math.PI / 2;
  renderer.toneMappingExposure = Math.pow(2, .08 * daylight - .1 * night);
  skyUniforms.uNight.value = night;
  skyUniforms.uGold.value = gold;
  skyUniforms.uSun.value.copy(toward);
  invalidate();
}
function setWeights(target, jump) {
  // The host resends its whole state often: the same hour again is no news.
  if (target.every((v, i) => Math.abs(v - light.to[i]) < .002) && !jump) return;
  light.to = target;
  if (jump || state.calm) { light.now = target.slice(); light.moving = false; if (ready) applyLight(); return; }
  light.from = light.now.slice();
  light.t0 = performance.now();
  light.moving = true;
  wake();
}

// ---------------------------------------------------------------- doors
// Each door part eases between its shut and open pose; a new order starts
// from wherever the door is.
const doors = {}; // name -> {value, from, to, t0, delay}
function doorTo(name, to, delay = 0) {
  const d = doors[name] ||= { value: 0, from: 0, to: 0, t0: 0, delay: 0 };
  if (d.to === to) return;
  d.from = d.value; d.to = to; d.t0 = performance.now(); d.delay = delay;
  wake();
}
function applyDoors(now) {
  let moving = false, swung = false, settled = false;
  for (const [name, d] of Object.entries(doors)) {
    if (d.value === d.to) continue;
    const span = state.calm ? 1 : 900;
    const f = Math.min(1, Math.max(0, (now - d.t0 - d.delay) / span));
    if (f < 1) moving = true;
    if (f <= 0) continue; // still waiting for the camera: nothing has moved
    d.value = f >= 1 ? d.to : d.from + (d.to - d.from) * (1 - Math.pow(1 - f, 3));
    for (const part of doorParts[name] || []) part.node.quaternion.slerpQuaternions(part.shut, part.open, d.value);
    swung = true;
    if (f >= 1) settled = true;
  }
  if (swung) {
    // A swinging door changes every shadow. The fridge lamps follow each
    // frame; the big room maps every second frame, and once more at rest.
    doorFrame++;
    stale(insideLights);
    if (settled || doorFrame % 2 === 0) stale(roomLights);
  }
  // Lamps come on as the door leaves the frame: off shut, full by about 20°.
  const level = (v) => THREE.MathUtils.smoothstep(v * 1.75, .035, .35);
  const twin = state.look.fridge === 'double';
  const fridge = level(twin ? (doors.double?.value || 0) : (doors.fridge?.value || 0));
  const freezer = level(twin ? (doors.double?.value || 0) : (doors.freezer?.value || 0));
  insideLights[0].intensity = insideLights[0].userData.placed ? 4 * fridge : 0;
  insideLights[1].intensity = insideLights[1].userData.placed ? 4 * freezer : 0;
  for (const m of lampMaterials) m.emissiveIntensity = 1.5 * Math.max(fridge, freezer);
  return moving;
}
let doorFrame = 0;
function doorsFor(shot, delay) {
  const twin = state.look.fridge === 'double';
  const cold = shot === 'fridge' || shot === 'freezer';
  doorTo('fridge', !twin && shot === 'fridge' ? 1 : 0, delay);
  doorTo('freezer', !twin && shot === 'freezer' ? 1 : 0, delay);
  doorTo('double', twin && cold ? 1 : 0, delay);
  doorTo('microwave', shot === 'microwave' ? 1 : 0, delay);
}

// ---------------------------------------------------------------- camera
// Fixed shots only; the app moves the camera. `fov` is vertical, in degrees.
// The overview keeps the app's near-isometric angle and frames the room to
// whatever shape the view has.
const HOME_DIR = new THREE.Vector3(Math.sin(1.0123) * Math.sin(Math.PI / 4), Math.cos(1.0123), Math.sin(1.0123) * Math.cos(Math.PI / 4));
const SHOTS = {
  fridge: { position: [3.15, 1.41, 1.476], target: [3.15, .95, -2.9], fov: 40, ms: 1000 },
  // Level with the freezer door: from higher up the view runs over the wall tops.
  freezer: { position: [3.15, 1.62, .9], target: [3.15, 1.68, -2.9], fov: 32, ms: 1000 },
  microwave: { position: [.772, 1.307, -1.442], target: [.48, 1.07, -3.1], fov: 45, ms: 1000 },
  // Codex C2C-014: from the table's near corner, 45° across the room.
  table: { position: [4.35, 1.4, .75], target: [0, .9, -3.6], fov: 50, ms: 1800 },
};
const cam = { position: new THREE.Vector3(), target: new THREE.Vector3(), fov: 40 };
const tween = { on: false, t0: 0, ms: 0, from: null, to: null, name: 'home' };

function homeShot() {
  const target = fitBox.isEmpty() ? new THREE.Vector3(1.76, 1.26, -1.65) : fitBox.getCenter(new THREE.Vector3());
  const position = target.clone().addScaledVector(HOME_DIR, 34);
  // The narrowest field that still holds every corner of the room.
  const probe = new THREE.PerspectiveCamera(10, 1, 1, 100);
  probe.position.copy(position); probe.lookAt(target); probe.updateMatrixWorld(true);
  const aspect = Math.max(.2, view.clientWidth / Math.max(1, view.clientHeight));
  let tan = Math.tan(THREE.MathUtils.degToRad(5.75));
  if (!fitBox.isEmpty()) {
    tan = 0;
    const p = new THREE.Vector3();
    for (let i = 0; i < 8; i++) {
      p.set(i & 1 ? fitBox.max.x : fitBox.min.x, i & 2 ? fitBox.max.y : fitBox.min.y, i & 4 ? fitBox.max.z : fitBox.min.z)
        .applyMatrix4(probe.matrixWorldInverse);
      tan = Math.max(tan, Math.abs(p.y) / -p.z, Math.abs(p.x) / -p.z / aspect);
    }
    tan *= 1.08; // a margin, so the edge fade has room before the room starts
  }
  return { position, target, fov: THREE.MathUtils.radToDeg(Math.atan(tan)) * 2, ms: 1000 };
}
function shotOf(name) {
  if (name === 'home' || !SHOTS[name]) return homeShot();
  const s = SHOTS[name];
  return { position: new THREE.Vector3(...s.position), target: new THREE.Vector3(...s.target), fov: s.fov, ms: s.ms };
}
function placeCamera() {
  camera.position.copy(cam.position);
  camera.fov = cam.fov;
  camera.near = Math.max(.05, cam.position.distanceTo(cam.target) - 9);
  camera.updateProjectionMatrix();
  camera.lookAt(cam.target);
}
function jumpTo(to) {
  cam.position.copy(to.position); cam.target.copy(to.target); cam.fov = to.fov;
  tween.on = false;
  placeCamera();
  invalidate();
}
function goTo(name, jump) {
  const to = shotOf(name);
  tween.name = name;
  if (jump || !ready) { jumpTo(to); return; }
  if (state.calm) {
    // No travel: the view fades out, changes and fades back.
    canvas.classList.remove('ready');
    clearTimeout(calmTimer);
    calmTimer = setTimeout(() => { jumpTo(shotOf(tween.name)); applyMask(); canvas.classList.add('ready'); }, 330);
    return;
  }
  tween.from = { position: cam.position.clone(), target: cam.target.clone(), fov: cam.fov };
  tween.to = to; tween.t0 = performance.now(); tween.ms = to.ms; tween.on = true;
  wake();
}
let calmTimer = 0;
const half = (fov) => Math.tan(THREE.MathUtils.degToRad(fov) / 2);
function stepCamera(now) {
  if (!tween.on) return false;
  const f = Math.min(1, (now - tween.t0) / tween.ms);
  const e = f < .5 ? 4 * f * f * f : 1 - Math.pow(-2 * f + 2, 3) / 2;
  const a = tween.from, b = tween.to;
  // Turn, move the target and change the framed size together, so the room
  // grows steadily instead of lurching as the lens widens.
  const da = a.position.clone().sub(a.target), db = b.position.clone().sub(b.target);
  const sizeA = da.length() * half(a.fov), sizeB = db.length() * half(b.fov);
  const dir = da.normalize().lerp(db.normalize(), e).normalize();
  cam.fov = a.fov + (b.fov - a.fov) * e;
  cam.target.lerpVectors(a.target, b.target, e);
  const size = sizeA * Math.pow(sizeB / sizeA, e);
  cam.position.copy(cam.target).addScaledVector(dir, size / half(cam.fov));
  if (maskDue && f >= .5) applyMask();
  if (f >= 1) tween.on = false;
  placeCamera();
  return tween.on;
}
// The view never ends on a hard line against the page: the overview fades
// around the room, a close shot fades at its edges.
// The table fills the view, so it fades at the frame; an appliance sits in
// the middle of a cut-away room, so the fade is an oval around it.
function applyMask() {
  const shot = state.shot, home = shot === 'home', frameFade = shot === 'table';
  const style = canvas.style;
  maskDue = false;
  if (home && !state.vignette) { style.maskImage = style.webkitMaskImage = 'none'; return; }
  const mask = home ? 'radial-gradient(ellipse 56% 44% at 50% 50%, #000 64%, transparent 100%)'
    : frameFade ? 'linear-gradient(to bottom, transparent, #000 9%, #000 93%, transparent), linear-gradient(to right, transparent, #000 5%, #000 95%, transparent)'
      : 'radial-gradient(ellipse 66% 58% at 50% 50%, #000 60%, transparent 100%)';
  style.maskImage = style.webkitMaskImage = mask;
  style.maskComposite = frameFade ? 'intersect' : 'add';
  style.webkitMaskComposite = frameFade ? 'source-in' : 'source-over';
}
// Masks cannot ease from one shape to another: the change is made halfway
// through the camera's move, when the view is travelling fastest.
let maskDue = false;

// ---------------------------------------------------------------- drawing
let frame = null, settle = 0, lastFrame = 0, lastShadows = false, slowMoves = 0, fastMoves = 0, firstFrame = 0;
let mainDraws = 0, mainTriangles = 0; // one pass of the room, without shadow maps
const pace = [];
// The browser holds animation frames back while the page is out of sight,
// so a hidden viewer costs nothing and picks up where it was.
function wake() { if (firstFrame && frame === null) frame = requestAnimationFrame(tick); }
function invalidate() { settle = 2; wake(); }
function draw() {
  let shadows = false;
  for (const l of shadowLights) {
    // A light without power keeps its old map; it is redrawn when lit.
    if (l.userData.stale && l.intensity > 0) { l.shadow.needsUpdate = true; l.userData.stale = false; shadows = true; }
  }
  if (shadows) renderer.shadowMap.needsUpdate = true;
  renderer.info.reset();
  renderer.render(scene, camera);
  return shadows;
}
function tick(now) {
  frame = null;
  let moving = stepCamera(now);
  if (applyDoors(now)) moving = true;
  if (light.moving) {
    const f = Math.min(1, (now - light.t0) / 1400), e = f * f * (3 - 2 * f);
    light.now = light.from.map((v, i) => v + (light.to[i] - v) * e);
    if (f >= 1) light.moving = false; else moving = true;
    applyLight();
  }
  if (moving) settle = 2;
  if (settle <= 0) { lastFrame = 0; return; }
  settle--;
  // Pacing counts camera-only frames. The gap to this frame is the cost of
  // the frame before it: skip it when that one redrew shadow maps, which is
  // slow because of draw calls that fewer pixels would not help.
  const gap = now - lastFrame;
  if (moving && lastFrame && !lastShadows && gap < 100) { pace.push(gap); if (pace.length > 90) pace.shift(); }
  lastShadows = draw();
  if (!lastShadows) { mainDraws = renderer.info.render.calls; mainTriangles = renderer.info.render.triangles; }
  lastFrame = moving ? now : 0;
  if (!moving && pace.length >= 20) adapt();
  if (hud.style.display === 'block') showHud();
  if (settle > 0 || moving) wake();
}
// After a move: if frames ran long twice running, draw fewer pixels.
function adapt() {
  const sorted = pace.slice().sort((a, b) => a - b), median = sorted[sorted.length >> 1], p95 = sorted[Math.floor(sorted.length * .95)];
  lastPerf = `frame ${median.toFixed(1)} ms (p95 ${p95.toFixed(1)})`;
  post({ t: 'perf', median: +median.toFixed(1), p95: +p95.toFixed(1), frames: sorted.length, draws: mainDraws, triangles: mainTriangles, pixelRatio, tier });
  pace.length = 0;
  slowMoves = median > 24 ? slowMoves + 1 : 0;
  fastMoves = median < 14 ? fastMoves + 1 : 0;
  const top = Math.min(devicePixelRatio || 1, Q.dpr);
  let next = pixelRatio;
  if (slowMoves >= 2) next = Math.max(Q.minDpr, pixelRatio - .25);
  // A bad spell (a hot phone, another app) should not cost sharpness for good.
  else if (fastMoves >= 3) next = Math.min(top, pixelRatio + .25);
  if (next !== pixelRatio) {
    slowMoves = fastMoves = 0;
    pixelRatio = next;
    renderer.setPixelRatio(pixelRatio);
    resize();
  }
}
// The numbers to read on a real phone (long-press the kitchen in the app).
let lastPerf = '', startInfo = '';
function showHud() {
  hud.textContent = `${mainDraws} draws · ${Math.round(mainTriangles / 1000)}k tris · x${pixelRatio} · ${tier}\n`
    + `${lastPerf || 'no move measured yet'}\n${startInfo}\nview ${view.clientWidth}x${view.clientHeight}${lastWarning ? '\n! ' + lastWarning : ''}`;
}
function resize() {
  const w = view.clientWidth, h = view.clientHeight;
  if (!w || !h) return;
  renderer.setSize(w, h, false);
  camera.aspect = w / h;
  if (tween.name === 'home') {
    // The overview is framed to the view's shape: frame it again.
    if (tween.on) tween.to = homeShot(); else jumpTo(homeShot());
  }
  camera.updateProjectionMatrix();
  // Resizing clears the canvas: draw now, not a frame later (once the
  // first frame exists; before it the light is not set up yet).
  if (firstFrame) { draw(); invalidate(); }
}
new ResizeObserver(resize).observe(view);
document.addEventListener('visibilitychange', () => { if (!document.hidden) invalidate(); });
// A lost context (a long spell in the background, memory pressure) takes
// the baked reflections with it: start the page again; the host sends its
// state when the page says hello.
canvas.addEventListener('webglcontextlost', (e) => { e.preventDefault(); warn('context lost'); });
canvas.addEventListener('webglcontextrestored', () => location.reload());

// ---------------------------------------------------------------- commands
const raycaster = new THREE.Raycaster();
function pick(point) {
  if (!firstFrame || !Array.isArray(point) || point.length < 2) return;
  raycaster.setFromCamera(new THREE.Vector2(point[0] * 2 - 1, 1 - point[1] * 2), camera);
  const hit = raycaster.intersectObjects(pickable, false)[0];
  // Blender's axes (z up), the space the app measures its zones in.
  if (hit) post({ t: 'tap', p: [hit.point.x, -hit.point.z, hit.point.y].map((v) => +v.toFixed(3)) });
}
function command(message) {
  let m = message;
  try { if (typeof m === 'string') m = JSON.parse(m); } catch { return; }
  if (!m || typeof m !== 'object') return;
  if (typeof m.calm === 'boolean') state.calm = m.calm;
  if (typeof m.vignette === 'boolean' && m.vignette !== state.vignette) {
    state.vignette = m.vignette;
    if (ready) applyMask();
  }
  if (m.look) {
    const next = { ...DEFAULT_LOOK, ...m.look };
    if (JSON.stringify(next) !== JSON.stringify(state.look)) {
      state.look = next;
      if (ready) {
        applyLook(); applyLight(); doorsFor(state.shot, 0);
        // A different fridge or rug changes the room's outline.
        if (tween.name === 'home') { if (tween.on) tween.to = homeShot(); else if (state.calm) jumpTo(homeShot()); else goTo('home'); }
      }
    }
  }
  if (m.weights !== undefined) {
    state.weights = m.weights;
    setWeights(weightsOf(m.weights), !ready);
  }
  if (m.shot && m.shot !== state.shot) {
    const fromHome = state.shot === 'home';
    state.shot = m.shot;
    if (ready) {
      goTo(m.shot);
      if (tween.on) maskDue = true; else if (!state.calm) applyMask();
      // The camera turns to the door first, then the door swings (with
      // motion reduced it is simply open when the view comes back).
      doorsFor(m.shot, state.calm ? 330 : fromHome && m.shot !== 'home' ? 480 : 0);
    }
  }
  if (m.pick) pick(m.pick);
  if (typeof m.hud === 'boolean') { hud.style.display = m.hud ? 'block' : 'none'; if (m.hud && ready) showHud(); }
}
if (params.get('hud') === '1') hud.style.display = 'block';
// For the screenshot driver and bug hunts: what the viewer thinks is going on.
window.sofraDebug = () => ({ ready, shot: state.shot, light: light.now, lightMoving: light.moving, tween: tween.on, frame, settle, pixelRatio, hidden: document.hidden, size: [view.clientWidth, view.clientHeight], programs: renderer.info.programs.length, materials: variants.size });

// ---------------------------------------------------------------- start
function graphics() {
  const gl = renderer.getContext(), ext = gl.getExtension('WEBGL_debug_renderer_info');
  return `${ext ? gl.getParameter(ext.UNMASKED_RENDERER_WEBGL) : 'gpu ?'} · ${gl.getParameter(gl.MAX_TEXTURE_IMAGE_UNITS)} units`;
}
async function start() {
  const t0 = performance.now();
  post({ t: 'hello' });
  // Whatever the host sent while the page was loading sets the first frame.
  const early = window.__sofraQueue || [];
  window.sofraKitchen = command;
  for (const m of early) command(m);
  light.now = weightsOf(state.weights);
  light.to = light.now.slice();
  const order = [0, 1, 2].sort((a, b) => light.now[b] - light.now[a]);
  const first = MODES[order[0]];
  const draco = new DRACOLoader().setDecoderPath(new URL('./vendor/draco/', import.meta.url).href);
  const loader = new GLTFLoader().setDRACOLoader(draco);
  const [gltf] = await Promise.all([
    loader.loadAsync(assets + (params.get('model') || 'kitchen.glb')),
    loadLightmap(first), loadProbe(first),
    light.now[order[1]] > .001 ? loadLightmap(MODES[order[1]]) : null,
  ]);
  draco.dispose(); // its decoder workers are not needed again
  // The host may have named another hour while the files were coming.
  const now = [0, 1, 2].sort((a, b) => light.now[b] - light.now[a]);
  await Promise.all([loadLightmap(MODES[now[0]]), loadProbe(MODES[now[0]])]);
  const loaded = performance.now();
  setUp(gltf);
  applyLook();
  ready = true;
  resize();
  applyLight();
  applyMask();
  goTo(state.shot, true);
  doorsFor(state.shot, 0);
  // Build the shaders without freezing the page, then draw the first frame.
  await renderer.compileAsync(scene, camera);
  const compiled = performance.now();
  draw();
  firstFrame = performance.now();
  started = true;
  invalidate();
  canvas.classList.add('ready');
  startInfo = `start ${Math.round(firstFrame - t0)} ms = load ${Math.round(loaded - t0)} + shaders ${Math.round(compiled - loaded)} + first frame ${Math.round(firstFrame - compiled)}\n${graphics()}`;
  post({ t: 'ready', ms: Math.round(firstFrame - t0), load: Math.round(loaded - t0), shaders: Math.round(compiled - loaded), frame: Math.round(firstFrame - compiled), draws: renderer.info.render.calls, triangles: renderer.info.render.triangles, tier, pixelRatio, gpu: graphics() });
  // The other hours load one at a time while nothing moves, so the light can
  // turn later without a pause and a first tap is not slowed.
  const rest = MODES.flatMap((mode) => [() => loadLightmap(mode), () => loadProbe(mode)]);
  const idle = () => {
    if (tween.on || light.moving || settle > 0) return setTimeout(idle, 1500);
    const next = rest.shift();
    if (next) next().catch(warn).then(() => setTimeout(idle, 600));
    else if (!state.weights) setInterval(() => { if (!state.weights && !document.hidden) setWeights(clockWeights()); }, 60000);
  };
  setTimeout(idle, 2500);
}
start().catch(warn);
