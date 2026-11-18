// Builds assets/places/<cc>.json — the Arabic names and positions of cities,
// towns and districts, used by «أسعار منطقتي» to turn a tap on the map or the
// phone's location into an area name. Positions never leave the phone.
//
// Input: raw Overpass API answers (OpenStreetMap, ODbL 1.0) saved by hand:
//   [out:json];area["ISO3166-1"="EG"][admin_level=2]->.a;
//   (nwr[place~"^(city|town|suburb|quarter|neighbourhood)$"](area.a););
//   out tags center;
// Usage: node tool/community/build-places.mjs <EG.json> <SA.json> <fetched yyyy-mm-dd>
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';

const [eg, sa, fetched] = process.argv.slice(2);
if (!eg || !sa || !/^\d{4}-\d{2}-\d{2}$/.test(fetched ?? '')) {
  console.error('usage: build-places.mjs <EG.json> <SA.json> <yyyy-mm-dd>');
  process.exit(2);
}

const kinds = { city: 'c', town: 't', suburb: 's', quarter: 'q', neighbourhood: 'n' };
const arabic = /[؀-ۿ]/;
const round = (v) => Math.round(v * 1e4) / 1e4;
const km = (a, b) => {
  const r = Math.PI / 180;
  const x = (b[1] - a[1]) * r * Math.cos(((a[0] + b[0]) / 2) * r);
  const y = (b[0] - a[0]) * r;
  return 6371 * Math.hypot(x, y);
};

function build(file, code) {
  const raw = JSON.parse(readFileSync(file, 'utf8'));
  const seen = [];
  for (const e of raw.elements) {
    const t = e.tags ?? {};
    const name = (t['name:ar'] ?? (arabic.test(t.name ?? '') ? t.name : '') ?? '')
      .replace(/\s+/g, ' ')
      .trim();
    const kind = kinds[t.place];
    const lat = e.lat ?? e.center?.lat;
    const lon = e.lon ?? e.center?.lon;
    if (!name || !kind || lat == null || lon == null || name.length > 40) continue;
    const at = [round(lat), round(lon)];
    // The same place drawn as a point and an outline, or twice: keep one.
    if (seen.some((p) => p.name === name && km(p.at, at) < 2)) continue;
    const population = +String(t.population ?? 0).replace(/[^0-9]/g, '');
    seen.push({ name, kind, at, population });
  }
  // Parents are big cities only (250k people or more), so a district reads
  // «المعادي، القاهرة» and not the police district next to it.
  const cities = seen.filter((p) => p.kind === 'c' && p.population >= 250000);
  const order = { c: 0, t: 1, s: 2, q: 3, n: 4 };
  seen.sort((a, b) => order[a.kind] - order[b.kind] || a.name.localeCompare(b.name, 'ar'));
  const cityIndex = new Map(seen.filter((p) => p.kind === 'c').map((p, i) => [p, i]));
  const places = seen.map((p) => {
    const row = [p.name, p.at[0], p.at[1], p.kind];
    if (p.kind !== 'c' && p.kind !== 't') {
      // The city a district belongs to: the nearest big city within 35 km.
      let best = null;
      for (const c of cities) {
        const d = km(p.at, c.at);
        if (d < 35 && (!best || d < best.d)) best = { c, d };
      }
      if (best) row.push(cityIndex.get(best.c));
    }
    return row;
  });
  const out = {
    country: code,
    source: 'OpenStreetMap contributors, via the Overpass API',
    license: 'ODbL-1.0',
    attribution: '© OpenStreetMap contributors',
    fetched,
    columns: ['name', 'lat', 'lon', 'kind c=city t=town s=suburb q=quarter n=neighbourhood', 'city index (districts only)'],
    places,
  };
  mkdirSync('assets/places', { recursive: true });
  writeFileSync(`assets/places/${code.toLowerCase()}.json`, JSON.stringify(out));
  const counts = {};
  for (const p of places) counts[p[3]] = (counts[p[3]] ?? 0) + 1;
  console.log(code, places.length, JSON.stringify(counts));
}

build(eg, 'EG');
build(sa, 'SA');
