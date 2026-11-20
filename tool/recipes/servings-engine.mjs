#!/usr/bin/env node
// Servings engine (node mirror of lib/domain/servings_engine.dart).
//
// The app decides how many people a recipe feeds from its own portion norms
// (data/ingredients/portion-norms.json): one person's dry pasta is about
// 200 g, and so on. A yield stated by the source is only checked against
// that; when it is missing the engine's number is used.
//
//   node tool/recipes/servings-engine.mjs --emit-dart   # lib/domain/servings_tables.g.dart
//   node tool/recipes/servings-engine.mjs --check       # fails when it is stale
//
// Both implementations read the same tables and must agree on every recipe;
// test/servings_engine_test.dart checks that against
// test/fixtures/servings-parity.json (written by servings-report.mjs).
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
export const root = path.resolve(here, '..', '..');
export const tablesDartFile = 'lib/domain/servings_tables.g.dart';

const readJson = (rel) => JSON.parse(fs.readFileSync(path.join(root, rel), 'utf8'));

/// The lookup tables both engines use, derived from the portion norms, the
/// portion categories, the vocabulary and the ingredient directory. Plain
/// JSON so the Dart side can embed exactly the same object.
export function buildTables({
  norms = readJson('data/ingredients/portion-norms.json'),
  categories = readJson('data/ingredients/portion-categories.json'),
  vocabulary = readJson('data/ingredients/vocabulary.json'),
  directory = readJson('data/ingredients/directory.json'),
} = {}) {
  const ids = categories.ids;
  for (const [id, cat] of Object.entries(ids)) {
    if (!norms.norms[cat]) throw new Error(`unknown norm ${cat} for ${id}`);
  }
  for (const [, cat] of categories.keywords) {
    if (!norms.norms[cat]) throw new Error(`unknown norm ${cat} in keywords`);
  }
  const idMap = directory.idMap;
  const vocabIds = new Set(vocabulary.map((v) => v.id));
  // rawId -> category, already resolved through idMap.
  const driving = {};
  const known = new Set();
  for (const raw of Object.keys(idMap).sort()) {
    const canon = idMap[raw];
    if (ids[canon]) driving[raw] = ids[canon];
    else if (vocabIds.has(canon)) known.add(raw);
  }
  for (const id of Object.keys(ids).sort()) {
    if (!(id in idMap)) driving[id] = ids[id];
  }
  for (const id of [...vocabIds].sort()) {
    if (!(id in idMap) && !driving[id]) known.add(id);
  }
  // Raw ids whose directory mapping is wrong for portions (idMap sends
  // "meat" to chicken); these win over idMap.
  for (const [raw, cat] of Object.entries(categories.rawOverrides ?? {})) {
    if (!norms.norms[cat]) throw new Error(`unknown norm ${cat} for ${raw}`);
    driving[raw] = cat;
    known.delete(raw);
  }
  // Exact vocabulary names and aliases: of ingredients that can drive
  // (-> category), and of every other vocabulary item (never drives).
  const aliases = {};
  const knownNames = new Set();
  for (const v of vocabulary) {
    const cat = ids[v.id];
    for (const term of [v.name, ...(v.aliases ?? [])]) {
      const key = term.trim();
      if (!key) continue;
      if (cat) {
        if (!(key in aliases)) aliases[key] = cat;
      } else {
        knownNames.add(key);
      }
    }
  }
  for (const [name, cat] of Object.entries(categories.nameOverrides ?? {})) {
    if (!norms.norms[cat]) throw new Error(`unknown norm ${cat} for ${name}`);
    aliases[name] = cat;
  }
  for (const key of Object.keys(aliases)) knownNames.delete(key);
  // Cup densities by raw id, resolved through idMap too.
  const cupG = {};
  for (const [id, g] of Object.entries(norms.cupGById)) cupG[id] = g;
  for (const raw of Object.keys(idMap).sort()) {
    const g = norms.cupGById[idMap[raw]];
    if (g != null && !(raw in cupG)) cupG[raw] = g;
  }
  return {
    version: 1,
    norms: norms.norms,
    units: norms.units,
    rules: norms.rules,
    cupG: sortKeys(cupG),
    driving: sortKeys(driving),
    known: [...known].sort(),
    aliases: sortKeys(aliases),
    knownNames: [...knownNames].sort(),
    deny: categories.deny,
    keywords: categories.keywords,
    kinds: categories.kinds,
    defaultKind: categories.defaultKind,
    priority: categories.priority,
  };
}

function sortKeys(o) {
  return Object.fromEntries(Object.keys(o).sort().map((k) => [k, o[k]]));
}

/// A compiled engine over [tables] (from [buildTables]).
export function createEngine(tables) {
  const re = (p) => new RegExp(p, 'i');
  const known = new Set(tables.known);
  const knownNames = new Set(tables.knownNames);
  const deny = re(tables.deny);
  const keywords = tables.keywords.map(([p, c]) => [re(p), c]);
  const kinds = tables.kinds.map(([p, k]) => [re(p), k]);
  const piece = re(tables.units.piecePattern);
  // Maps, not objects: an ingredient called "constructor" must not hit
  // Object.prototype.
  const asMap = (o) => new Map(Object.entries(o));
  const mass = asMap(tables.units.mass);
  const volume = asMap(tables.units.volume);
  const cup = asMap(tables.units.cup);
  const driving = asMap(tables.driving);
  const aliases = asMap(tables.aliases);
  const cupG = asMap(tables.cupG);
  const norms = asMap(tables.norms);
  const rules = tables.rules;
  const natural = new Set(rules.naturalPieceCategories);

  const kindOf = (category) => {
    const text = String(category ?? '').trim();
    for (const [r, k] of kinds) if (r.test(text)) return k;
    return tables.defaultKind;
  };

  const text = (v) => (typeof v === 'string' ? v.trim() : '');

  /// Category of one ingredient line, or null when it never drives.
  const categoryOf = (line) => {
    const id = text(line.id);
    const name = text(line.name);
    if (driving.has(id)) return driving.get(id);
    if (aliases.has(name)) return aliases.get(name);
    if (known.has(id) || knownNames.has(name)) return null;
    if (deny.test(name) || deny.test(id)) return null;
    for (const [r, c] of keywords) if (r.test(name) || r.test(id)) return c;
    return null;
  };

  /// Whether a line without a category is still understood (a known
  /// vocabulary item or something that never drives, like oil or spice).
  const understood = (line) => {
    const id = text(line.id);
    const name = text(line.name);
    return known.has(id) || knownNames.has(name) || deny.test(name) || deny.test(id);
  };

  const amountOf = (line) => {
    const a = typeof line.amount === 'number' ? line.amount : Number(line.amount);
    return Number.isFinite(a) && a > 0 ? a : null;
  };

  const unitKey = (u) => text(u).toLowerCase();

  /// Amount of [line] in the norm's unit (g, ml or count), or null.
  const convert = (line, cat) => {
    const a = amountOf(line);
    if (a == null) return null;
    const norm = norms.get(cat);
    const u = unitKey(line.unit);
    if (norm.unit === 'count') {
      return u === '' || piece.test(u) ? { value: a, via: 'count' } : null;
    }
    if (mass.has(u)) return { value: a * mass.get(u), via: 'mass' };
    if (volume.has(u)) return { value: a * volume.get(u), via: 'volume' };
    if (cup.has(u)) {
      const g = cupG.get(text(line.id)) ?? norm.cupG;
      return g == null ? null : { value: a * cup.get(u) * g, via: 'cup' };
    }
    if (u !== '' && piece.test(u) && norm.pieceG != null) {
      return { value: a * norm.pieceG, via: 'piece' };
    }
    return null;
  };

  /// Rough grams of any measured line, only to weigh how much of the
  /// recipe the engine understood.
  const roughGrams = (line, cat) => {
    const a = amountOf(line);
    if (a == null) return null;
    const u = unitKey(line.unit);
    const norm = cat ? norms.get(cat) : null;
    if (mass.has(u)) return a * mass.get(u);
    if (volume.has(u)) return a * volume.get(u);
    if (cup.has(u)) return a * cup.get(u) * (norm?.cupG ?? tables.units.genericCupG);
    if (u === '' || piece.test(u)) return a * (norm?.pieceG ?? tables.units.genericPieceG);
    return null;
  };

  const role = (cat) => norms.get(cat).role;

  /// The category [cat] counts as in a dish of [kind], or null to ignore it.
  const inContext = (kind, cat) => {
    if (kind === 'soup' || kind === 'drink') {
      if (role(cat) !== 'liquid') return null;
      return kind === 'drink' ? 'drink' : 'soupLiquid';
    }
    if (role(cat) === 'liquid') return kind === 'dessert' && cat === 'milkDessert' ? cat : null;
    if (cat === 'eggsMain' && kind !== 'main' && kind !== 'salad') return null;
    if (cat === 'saladVeg' && kind !== 'salad') return null;
    if (kind === 'salad' && role(cat) === 'veg') return 'saladVeg';
    if (kind === 'dip' && role(cat) === 'starch') return 'dipBase';
    if (kind === 'dessert' && cat === 'flourBread') return 'dessertBase';
    return cat;
  };

  const r2 = (v) => Math.round(v * 100) / 100;
  const r1 = (v) => Math.round(v * 10) / 10;

  /// The engine's verdict for one recipe ({category, servings, ingredients}).
  function compute(recipe) {
    const kind = kindOf(recipe.category);
    const stated = Number.isInteger(recipe.servings) && recipe.servings > 0 ? recipe.servings : null;
    const out = (fields) => ({ kind, servings: stated, ...fields });
    if (kind === 'base') {
      return out({
        servingsComputed: null, servingsRange: null, servingsConfidence: 'none',
        servingsBasis: { source: stated == null ? 'none' : 'source', drivers: [], reason: 'notApplicable' },
      });
    }
    const lines = Array.isArray(recipe.ingredients) ? recipe.ingredients : [];
    let total = 0;
    let unmapped = 0;
    let categorized = 0;
    const byCat = new Map();
    for (const line of lines) {
      if (!line || typeof line !== 'object' || line.optional === true) continue;
      const base = categoryOf(line);
      const g = roughGrams(line, base);
      if (g != null) {
        total += g;
        if (base == null && !understood(line)) unmapped += g;
      }
      if (base == null) continue;
      categorized++;
      const cat = inContext(kind, base);
      if (cat == null) continue;
      const amount = convert(line, cat);
      if (amount == null || !(amount.value > 0)) continue;
      const norm = norms.get(cat);
      const entry = byCat.get(cat) ?? { category: cat, role: norm.role, unit: norm.unit, amount: 0, people: 0, ids: [], vias: [] };
      entry.amount += amount.value;
      entry.people += amount.value / norm.per;
      entry.ids.push(text(line.id));
      entry.vias.push(amount.via);
      byCat.set(cat, entry);
    }
    let cats = [...byCat.values()];
    if (cats.some((c) => c.role === 'protein' && c.category !== 'eggsMain')) {
      cats = cats.filter((c) => c.category !== 'eggsMain');
    }
    const roles = new Map();
    for (const c of cats) {
      const r = roles.get(c.role) ?? { role: c.role, people: 0, cats: [] };
      r.people += c.people;
      r.cats.push(c);
      roles.set(c.role, r);
    }
    const drivers = (tables.priority[kind] ?? [])
      .map((r) => roles.get(r))
      .filter((r) => r && r.people >= rules.driverMinPeople);
    const mappedShare = total > 0 ? 1 - unmapped / total : 1;
    if (!drivers.length) {
      const reason = cats.length ? 'driverTooSmall' : categorized ? 'noMeasuredDriver' : 'noDriverIngredient';
      return out({
        servingsComputed: null, servingsRange: null, servingsConfidence: 'none',
        servingsBasis: { source: stated == null ? 'none' : 'source', drivers: [], reason },
        mappedShare: r2(mappedShare),
      });
    }
    const values = drivers.map((d) => d.people);
    const sum = values.reduce((s, v) => s + v, 0);
    const n = drivers.length;
    const p = n === 1 ? sum : sum * rules.combine[String(Math.min(n, 3))];
    const [lo, hi] = rules.clamp;
    const computed = Math.max(lo, Math.min(hi, Math.round(p)));
    const range = [
      Math.min(computed, Math.max(lo, Math.floor(p * rules.range[0]))),
      Math.max(computed, Math.min(hi, Math.ceil(p * rules.range[1]))),
    ];
    // Agreement is judged among roles that feed at least one person; a
    // supporting role (a little rice in a pudding) does not make it low.
    const firm = values.filter((v) => v >= 1);
    const spread = firm.length > 1 ? Math.max(...firm) / Math.min(...firm) : 1;
    const used = drivers.flatMap((d) => d.cats);
    const pieceOnly = used.every((c) => c.vias.every((v) => v === 'piece') && !natural.has(c.category));
    const conf = rules.confidence;
    let confidence;
    if (spread > conf.mediumAgree || 1 - mappedShare > conf.lowUnmappedShare || pieceOnly || (n === 1 && p < conf.smallSinglePeople)) {
      confidence = 'low';
    } else if (n >= 2 && spread <= conf.highAgree && mappedShare >= conf.highMappedShare) {
      confidence = 'high';
    } else {
      confidence = 'medium';
    }
    let dominant = used[0];
    for (const c of used) if (c.people > dominant.people) dominant = c;
    const basis = {
      source: 'computed',
      drivers: used.map((c) => ({
        ingredientId: c.ids[0], category: c.category, amount: r1(c.amount), unit: c.unit, people: r2(c.people),
      })),
    };
    if (stated != null) {
      const norm = norms.get(dominant.category);
      const implied = (norm.per * p) / stated;
      basis.impliedPerPerson = r1(implied);
      const plausible = implied >= norm.band[0] && implied <= norm.band[1];
      if (plausible) {
        basis.source = 'source';
      } else if (confidence === 'low') {
        basis.source = 'source';
        basis.reason = 'sourceKeptLowConfidence';
      } else {
        basis.reason = mismatchReason({ kind, stated, p, mappedShare, dominant, rules });
      }
    }
    return out({
      servingsComputed: computed, servingsRange: range, servingsConfidence: confidence,
      servingsBasis: basis, mappedShare: r2(mappedShare), people: r2(p),
    });
  }

  return { compute, kindOf, categoryOf, understood, convert, tables };
}

function mismatchReason({ kind, stated, p, mappedShare, dominant, rules }) {
  if (stated > p) {
    if ((kind === 'dessert' || kind === 'bread') && stated / p >= rules.sourceCountsPiecesRatio) {
      return 'sourceCountsPieces';
    }
    if (mappedShare < rules.mappingGapMappedShare) return 'mappingGap';
    return 'sourceInflated';
  }
  if (mappedShare < rules.mappingGapMappedShare) return 'mappingGap';
  return 'driverAmbiguous';
}

/// The yield the app uses: the source when the engine agrees (or cannot
/// tell), otherwise the engine's number. Null only when neither exists.
export function effectiveServings(result) {
  if (result.servings != null && result.servingsBasis.source !== 'computed') return result.servings;
  return result.servingsConfidence === 'none' ? result.servings : result.servingsComputed;
}

/// The four build-time fields written on every index row and recipe body.
export function servingsFields(result) {
  return {
    servingsComputed: result.servingsComputed,
    servingsRange: result.servingsRange,
    servingsBasis: result.servingsBasis,
    servingsConfidence: result.servingsConfidence,
  };
}

let shared;
/// The engine over the repository's current tables.
export function defaultEngine() {
  shared ??= createEngine(buildTables());
  return shared;
}

export function dartTables(tables = buildTables()) {
  const json = JSON.stringify(tables, null, 1);
  if (json.includes("'''")) throw new Error('tables cannot be embedded');
  return (
    '// Generated by tool/recipes/servings-engine.mjs --emit-dart; do not edit.\n' +
    '// Source: data/ingredients/portion-norms.json, portion-categories.json,\n' +
    '// vocabulary.json and directory.json.\n\n' +
    `const servingsTablesJson = r'''${json}''';\n`
  );
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const file = path.join(root, tablesDartFile);
  const text = dartTables();
  if (process.argv.includes('--check')) {
    const now = fs.existsSync(file) ? fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n') : '';
    if (now !== text) {
      console.error(`stale: ${tablesDartFile}; run node tool/recipes/servings-engine.mjs --emit-dart`);
      process.exit(1);
    }
    console.log(`${tablesDartFile} is current`);
  } else if (process.argv.includes('--emit-dart')) {
    fs.writeFileSync(file, text);
    console.log(`wrote ${tablesDartFile} (${text.length} bytes)`);
  }
}
