// Copies the three.js files the kitchen viewer needs into
// assets/scene3d/vendor, flat, with the bare `three` import rewritten to a
// relative path so the page needs no import map (older WebViews).
//
//   npm pack three@0.180.0 && tar -xzf three-0.180.0.tgz
//   node tool/scene3d/vendor_three.mjs <path-to>/package
import fs from 'node:fs';
import path from 'node:path';

const src = process.argv[2];
if (!src) throw new Error('usage: vendor_three.mjs <three package folder>');
const out = 'assets/scene3d/vendor';
fs.mkdirSync(path.join(out, 'draco'), { recursive: true });
const copy = (from, to) => fs.copyFileSync(path.join(src, from), path.join(out, to));
copy('build/three.module.min.js', 'three.module.min.js');
copy('build/three.core.min.js', 'three.core.min.js');
copy('LICENSE', 'LICENSE-three.txt');
for (const f of ['loaders/GLTFLoader.js', 'loaders/DRACOLoader.js', 'loaders/HDRLoader.js', 'utils/BufferGeometryUtils.js']) {
  const text = fs.readFileSync(path.join(src, 'examples/jsm', f), 'utf8')
    .replace(/from 'three';/g, "from './three.module.min.js';")
    .replace("'../utils/BufferGeometryUtils.js'", "'./BufferGeometryUtils.js'");
  // Doc comments still mention the bare specifier; real imports must not.
  const live = text.split('\n').filter((line) => !line.trim().startsWith('*'));
  if (live.some((line) => line.includes("from 'three"))) throw new Error('unresolved three import in ' + f);
  fs.writeFileSync(path.join(out, path.basename(f)), text);
}
// The glTF build of the Draco decoder (Apache-2.0), loaded by DRACOLoader.
for (const f of ['draco_wasm_wrapper.js', 'draco_decoder.wasm']) {
  copy('examples/jsm/libs/draco/gltf/' + f, 'draco/' + f);
}
console.log('vendored three', JSON.parse(fs.readFileSync(path.join(src, 'package.json'), 'utf8')).version);
