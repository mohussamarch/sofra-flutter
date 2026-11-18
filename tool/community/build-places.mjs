// Builds assets/places/<cc>.json — the Arabic names and positions of cities,
// towns and districts, used by «أسعار منطقتي» to turn a tap on the map or the
// phone's location into an area name. Positions never leave the phone.
//
// Input: raw Overpass API answers (OpenStreetMap, ODbL 1.0) saved by hand:
//   [out:json];area["ISO3166-1"="EG"][admin_level=2]->.a;
//   (nwr[place~"^(city|town|suburb|quarter|neighbourhood)$"](area.a););
//   out tags center;
// Usage: node tool/community/build-places.mjs <EG.json> <SA.json> <fetched yyyy-mm-dd>
//
// Every label («name» or «name، parent») is unique per country after the
// app's normalizePlace(), because the label is what is saved and shared as
// the area: two places with one label would pool their prices.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';

const [eg, sa, fetched] = process.argv.slice(2);
if (!eg || !sa || !/^\d{4}-\d{2}-\d{2}$/.test(fetched ?? '')) {
  console.error('usage: build-places.mjs <EG.json> <SA.json> <yyyy-mm-dd>');
  process.exit(2);
}

const kinds = { city: 'c', town: 't', suburb: 's', quarter: 'q', neighbourhood: 'n' };
const order = { c: 0, t: 1, s: 2, q: 3, n: 4 };
const arabic = /[؀-ۿ]/;
const round = (v) => Math.round(v * 1e4) / 1e4;
const km = (a, b) => {
  const r = Math.PI / 180;
  const x = (b[1] - a[1]) * r * Math.cos(((a[0] + b[0]) / 2) * r);
  const y = (b[0] - a[0]) * r;
  return 6371 * Math.hypot(x, y);
};

/// The same as normalizePlace() in lib/domain/places.dart.
const normalize = (v) =>
  v
    .trim()
    .toLowerCase()
    .replace(/[ًٌٍَُِّْـ]/g, '')
    .replace(/[أإآ]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي')
    .replace(/\s+/g, ' ');

const isTown = (p) => p.kind === 'c' || p.kind === 't';

/// City before town before district, then more people, then a fixed order.
const importance = (a, b) =>
  order[a.kind] - order[b.kind] ||
  b.population - a.population ||
  a.at[0] - b.at[0] ||
  a.at[1] - b.at[1];

const labelOf = (p) => (p.parent && p.parent.key !== p.key ? `${p.name}، ${p.parent.name}` : p.name);

function nearestTown(p, towns, maxKm, ok = () => true) {
  let best = null;
  for (const c of towns) {
    if (c === p || c.key === p.key || !ok(c)) continue;
    const d = km(p.at, c.at);
    if (d < maxKm && (!best || d < best.d)) best = { c, d };
  }
  return best?.c ?? null;
}

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
    const population = +String(t.population ?? 0).replace(/[^0-9]/g, '') || 0;
    seen.push({ name, key: normalize(name), kind, at, population });
  }
  seen.sort(importance);

  // A place named like a more important place within 15 km is that place
  // (or a part of it named after it): keep only the important one.
  let places = [];
  const byName = new Map();
  let near = 0;
  for (const p of seen) {
    const same = byName.get(p.key) ?? [];
    if (same.some((q) => km(q.at, p.at) < 15)) {
      near++;
      continue;
    }
    same.push(p);
    byName.set(p.key, same);
    places.push(p);
  }

  // Parents, then unique labels. Dropping a town can orphan a district, so
  // repeat until nothing more is dropped.
  let renamed = 0;
  let clashing = 0;
  for (;;) {
    const towns = places.filter(isTown);
    const big = towns.filter((c) => c.kind === 'c' && c.population >= 250000);
    for (const p of places) {
      p.parent = null;
      if (isTown(p)) continue;
      // The city a district belongs to: the nearest big city within 35 km
      // («المعادي، القاهرة», not the police district next to it), else the
      // nearest city or town within 25 km.
      p.parent = nearestTown(p, big, 35) ?? nearestTown(p, towns, 25);
    }
    const groups = new Map();
    for (const p of places) {
      const key = normalize(labelOf(p));
      const group = groups.get(key) ?? [];
      group.push(p);
      groups.set(key, group);
    }
    // The most important place of each group keeps its label.
    const used = new Set(groups.keys());
    const others = [...groups.values()].flatMap((g) => g.slice(1)).sort(importance);
    const dropped = new Set();
    renamed = 0;
    for (const p of others) {
      // «تربة، حائل»: named after the nearest city or town of another name.
      const candidates = towns
        .filter((c) => c.key !== p.key && km(p.at, c.at) < 80)
        .sort((a, b) => km(p.at, a.at) - km(p.at, b.at));
      const parent = candidates.find((c) => !used.has(normalize(`${p.name}، ${c.name}`)));
      if (parent) {
        p.parent = parent;
        used.add(normalize(labelOf(p)));
        renamed++;
      } else {
        dropped.add(p);
      }
    }
    if (!dropped.size) break;
    clashing += dropped.size;
    places = places.filter((p) => !dropped.has(p));
  }

  places.sort((a, b) => order[a.kind] - order[b.kind] || a.name.localeCompare(b.name, 'ar'));
  const index = new Map(places.map((p, i) => [p, i]));
  const labels = new Set();
  const rows = places.map((p) => {
    const label = normalize(labelOf(p));
    if (labels.has(label)) throw new Error(`${code}: label not unique: ${label}`);
    labels.add(label);
    const row = [p.name, p.at[0], p.at[1], p.kind];
    if (p.parent && p.parent.key !== p.key) {
      // Parents are cities and towns, which come first, so the index is
      // also the index among them.
      if (!index.has(p.parent)) throw new Error(`${code}: parent dropped: ${p.name}`);
      row.push(index.get(p.parent));
    }
    return row;
  });
  const out = {
    country: code,
    source: 'OpenStreetMap contributors, via the Overpass API',
    license: 'ODbL-1.0',
    attribution: '© OpenStreetMap contributors',
    fetched,
    columns: [
      'name',
      'lat',
      'lon',
      'kind c=city t=town s=suburb q=quarter n=neighbourhood',
      'parent: index of the city or town the label names, when there is one',
    ],
    places: rows,
  };
  mkdirSync('assets/places', { recursive: true });
  writeFileSync(`assets/places/${code.toLowerCase()}.json`, JSON.stringify(out));
  const counts = {};
  for (const r of rows) counts[r[3]] = (counts[r[3]] ?? 0) + 1;
  console.log(
    code,
    rows.length,
    JSON.stringify(counts),
    `dropped ${near} near a same-named place, ${clashing} with no unique label; renamed ${renamed}`,
  );
}

build(eg, 'EG');
build(sa, 'SA');
