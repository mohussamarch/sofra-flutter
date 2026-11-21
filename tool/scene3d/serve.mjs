// Serves a folder over HTTP for trying the kitchen viewer on its own, with
// the same paths the phone's asset server uses:
//
//   node tool/scene3d/serve.mjs assets 8912
//   http://localhost:8912/scene3d/index.html?hud=1
//
// or a whole web build: node tool/scene3d/serve.mjs build/web 8913
// Missing files are a plain 404 (no single-page fallback).
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(process.argv[2] || 'assets');
const port = +process.argv[3] || 8912;
const types = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png',
  '.webp': 'image/webp', '.glb': 'model/gltf-binary', '.hdr': 'image/vnd.radiance',
  '.ktx2': 'image/ktx2', '.css': 'text/css', '.txt': 'text/plain',
};
http.createServer((req, res) => {
  let file;
  try { file = path.join(root, decodeURIComponent(req.url.split('?')[0])); } catch { file = ''; }
  // A folder serves its index.html (the Flutter web build's root).
  const inside = file === root || file.startsWith(root + path.sep);
  if (inside && fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
  if (!inside || !fs.existsSync(file) || !fs.statSync(file).isFile()) {
    res.writeHead(404);
    return res.end();
  }
  res.writeHead(200, {
    'Content-Type': types[path.extname(file)] || 'application/octet-stream',
    'Content-Length': fs.statSync(file).size,
    'Access-Control-Allow-Origin': '*',
    'Cache-Control': 'no-cache',
  });
  fs.createReadStream(file).on('error', () => res.destroy()).pipe(res);
}).listen(port, '127.0.0.1', () => console.log('serving ' + root + ' on http://localhost:' + port));
