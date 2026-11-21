// Drives a page (the Flutter web build or the kitchen viewer on its own) in
// headless Edge over CDP and screenshots steps. Uses the machine's GPU.
//
//   node tool/scene3d/drive.mjs <url> <outDir> <script.json> [width] [height] [android]
//
// `android` as the last word makes the page believe it is on an Android phone
// (the viewer then picks its phone quality tier, the app drops its desktop
// phone frame).
//
// script: [{"tap":"text"} | {"at":[x,y]} | {"type":"text"} | {"eval":"js"} |
//          {"until":"js expression","timeout":ms} | {"shot":"name"} |
//          {"cdp":["Domain.method",{params}]} |
//          {"wait":ms}]; every step takes an optional "after" (ms).
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const [url, outDir, scriptFile, w = '390', h = '844', device = ''] = process.argv.slice(2);
const width = +w, height = +h;
const steps = JSON.parse(fs.readFileSync(scriptFile, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const port = 9300 + Math.floor(Math.random() * 500);
// The profile grows to hundreds of MB with a 3D page: keep it off the system
// drive and delete it when done.
const scratch = process.env.SOFRA_SCRATCH || 'E:/tmp/kitchen3d';
fs.mkdirSync(scratch, { recursive: true });
const profile = fs.mkdtempSync(path.join(scratch, 'edge-'));
const edge = spawn('C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe', [
  '--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`,
  `--window-size=${width},${height}`, '--force-device-scale-factor=2', '--hide-scrollbars',
  '--force-color-profile=srgb', '--enable-gpu', '--ignore-gpu-blocklist',
  '--use-angle=d3d11', '--enable-unsafe-swiftshader',
  // A headless window counts as covered after a while and stops drawing.
  '--disable-backgrounding-occluded-windows', '--disable-renderer-backgrounding',
  '--disable-features=CalculateNativeWinOcclusion',
  // Edge opens its own tabs on a fresh profile, which hides ours.
  '--no-first-run', '--no-default-browser-check', '--disable-extensions',
  '--disable-component-extensions-with-background-pages', 'about:blank',
], { stdio: 'ignore' });
// Whatever happens (a step that throws, Edge not answering), the browser is
// closed and its profile removed when this process ends.
process.on('exit', () => {
  try { edge.kill(); } catch { /* already gone */ }
  for (let i = 0; i < 12; i++) {
    try { fs.rmSync(profile, { recursive: true, force: true }); return; } catch { /* still closing */ }
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 300);
  }
});
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let tabs;
for (let i = 0; i < 50; i++) {
  try { tabs = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); break; } catch { await sleep(200); }
}
if (!tabs) throw new Error('Edge did not start');
const page = tabs.find((t) => t.type === 'page');
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((r) => ws.addEventListener('open', r));
let id = 0; const pending = new Map();
const logs = [];
ws.addEventListener('message', (e) => {
  const m = JSON.parse(e.data);
  if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
  if (m.method === 'Runtime.consoleAPICalled' && (['error', 'warning'].includes(m.params.type) || String(m.params.args[0]?.value).startsWith('sofra'))) {
    logs.push(m.params.type + ': ' + m.params.args.map((a) => a.value ?? a.description ?? '').join(' '));
  }
  if (m.method === 'Runtime.exceptionThrown') {
    logs.push('exception: ' + (m.params.exceptionDetails.exception?.description || m.params.exceptionDetails.text));
  }
});
const send = (method, params = {}) => new Promise((r) => {
  const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params }));
});
const evaluate = async (expr) => {
  const r = await send('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true });
  if (r.result?.exceptionDetails) return 'EVAL ERROR: ' + (r.result.exceptionDetails.exception?.description || r.result.exceptionDetails.text);
  return r.result?.result?.value;
};
await send('Runtime.enable');
await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 2, mobile: true });
await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: 'light' }] });
if (device === 'android') {
  await send('Emulation.setUserAgentOverride', {
    userAgent: 'Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36',
    platform: 'Android',
  });
}
await send('Page.enable');
await send('Emulation.setFocusEmulationEnabled', { enabled: true });
await send('Page.navigate', { url });
if (steps[0]?.boot) await sleep(steps[0].boot);
else {
  // A Flutter page: wait for it to come up (a busy machine takes a while),
  // then turn on its semantics tree so labels can be found.
  for (let i = 0; i < 180 && !(await evaluate(`!!document.querySelector('flt-semantics-placeholder')`)); i++) await sleep(250);
  await sleep(1500);
  await evaluate(`(() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) p.click(); return !!p; })()`);
  await sleep(800);
}

const find = (text) => evaluate(`(() => {
  const want = ${JSON.stringify(text)};
  const host = document.querySelector('flt-semantics-host') || document;
  let best = null;
  for (const el of host.querySelectorAll('*')) {
    const label = (el.getAttribute('aria-label') || '').trim();
    const own = el.children.length === 0 ? (el.textContent || '').trim() : [...el.childNodes].filter(n => n.nodeType === 3).map(n => n.textContent).join('').trim();
    if (label === want || own === want || (label && (label.startsWith(want) || label.includes(want))) || (own && own.includes(want))) {
      const r = el.getBoundingClientRect();
      if (r.width && r.height && (!best || r.width * r.height < best.w * best.h)) best = { x: r.x + r.width / 2, y: r.y + r.height / 2, w: r.width, h: r.height };
    }
  }
  return best;
})()`);

const click = async (x, y) => {
  for (const type of ['mousePressed', 'mouseReleased']) {
    await send('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 });
  }
};

for (const s of steps) {
  await send('Page.bringToFront');
  if (s.tap) {
    // A busy machine draws the next screen late: keep looking for a while.
    let at = null;
    for (let i = 0; i < 40 && !(at = await find(s.tap)); i++) await sleep(300);
    if (!at) console.log('NOT FOUND', s.tap);
    else await click(at.x, at.y);
  } else if (s.at) {
    await click(s.at[0], s.at[1]);
  } else if (s.type) {
    await send('Input.insertText', { text: s.type });
  } else if (s.eval) {
    const v = await evaluate(s.eval);
    if (v !== undefined) console.log('eval', typeof v === 'string' ? v : JSON.stringify(v));
  } else if (s.until) {
    const end = Date.now() + (s.timeout ?? 60000);
    let ok = false;
    while (Date.now() < end && !(ok = await evaluate(`!!(${s.until})`) === true)) await sleep(250);
    if (!ok) console.log('TIMEOUT', s.until);
  } else if (s.cdp) {
    await send(s.cdp[0], s.cdp[1] || {});
  } else if (s.shot) {
    const r = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(outDir, s.shot + '.png'), Buffer.from(r.result.data, 'base64'));
    console.log('shot', s.shot);
  }
  await sleep(s.after ?? s.wait ?? (s.shot || s.eval || s.until || s.cdp ? 0 : 900));
}
if (logs.length) console.log('--- console ---\n' + [...new Set(logs)].slice(0, 40).join('\n'));
await Promise.race([send('Browser.close'), sleep(1500)]);
ws.close();
