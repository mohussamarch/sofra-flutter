#!/usr/bin/env node
// Runs the servings engine over the whole corpus (recipes/data and the
// candidate batches) and writes:
//   data/recipes/servings-report.json    distribution, mismatch list, gaps
//   test/fixtures/servings-parity.json   what the Dart engine must reproduce
//   docs/dev/SERVINGS-ENGINE.md          the stats block between the markers
//
//   node tool/recipes/servings-report.mjs
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { defaultEngine, effectiveServings, root } from './servings-engine.mjs';

export const reportFile = 'data/recipes/servings-report.json';
export const parityFile = 'test/fixtures/servings-parity.json';
export const docFile = 'docs/dev/SERVINGS-ENGINE.md';

/// Every recipe of the corpus: {file, index, recipe}. Same order as the
/// Dart test reads them.
export function loadCorpus(base = root) {
  const out = [];
  const catalog = path.join(base, 'recipes/data');
  for (const f of fs.readdirSync(catalog).filter((f) => f.endsWith('.json')).sort()) {
    if (f === 'index.json' || f === 'dishes.json') continue;
    const data = JSON.parse(fs.readFileSync(path.join(catalog, f), 'utf8'));
    (data.recipes ?? []).forEach((recipe, index) => {
      if (recipe && Array.isArray(recipe.ingredients)) out.push({ file: `recipes/data/${f}`, index, recipe, catalog: true });
    });
  }
  const data = path.join(base, 'data/recipes');
  for (const d of fs.readdirSync(data).filter((d) => d.startsWith('candidates-')).sort()) {
    const dir = path.join(data, d);
    if (!fs.statSync(dir).isDirectory()) continue;
    for (const f of fs.readdirSync(dir).filter((f) => f.endsWith('.json')).sort()) {
      let json;
      try {
        json = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8'));
      } catch {
        continue;
      }
      const rows = Array.isArray(json) ? json : json?.recipes;
      if (!Array.isArray(rows)) continue;
      rows.forEach((recipe, index) => {
        if (recipe && Array.isArray(recipe.ingredients)) {
          out.push({ file: `data/recipes/${d}/${f}`, index, recipe, catalog: false });
        }
      });
    }
  }
  return out;
}

const count = (map, key) => map.set(key, (map.get(key) ?? 0) + 1);
const obj = (map) => Object.fromEntries([...map.entries()].sort((a, b) => String(a[0]).localeCompare(String(b[0]), 'en', { numeric: true })));

export function buildReport(corpus, engine = defaultEngine()) {
  const parity = [];
  const finalSource = new Map();
  const confidence = new Map();
  const distribution = new Map();
  const kinds = new Map();
  const reasons = new Map();
  const noneReasons = new Map();
  const mismatches = [];
  const gaps = new Map();
  let stated = 0;
  let computed = 0;
  let computedNoSource = 0;
  let missing = 0;
  const ratios = [];
  for (const { file, index, recipe, catalog } of corpus) {
    const r = engine.compute(recipe);
    parity.push({
      file, index, id: recipe.id,
      servingsComputed: r.servingsComputed, servingsRange: r.servingsRange,
      servingsConfidence: r.servingsConfidence, servingsBasis: r.servingsBasis,
    });
    count(kinds, r.kind);
    count(confidence, r.servingsConfidence);
    if (r.servings != null) stated++;
    else missing++;
    if (r.servingsComputed != null) {
      computed++;
      count(distribution, r.servingsComputed > 8 ? '9-20' : String(r.servingsComputed));
      if (r.servings == null) computedNoSource++;
    } else {
      count(noneReasons, r.servingsBasis.reason);
    }
    let how;
    if (r.servings != null && r.servingsComputed != null) {
      ratios.push(r.servings / r.people);
      how = r.servingsBasis.source === 'source'
        ? (r.servingsBasis.reason ? (r.servingsBasis.reason === 'sourceKeptLowConfidence' ? 'source kept (engine low confidence)' : 'source kept (engine medium confidence)') : 'plausible source value')
        : 'computed, source value rejected';
    } else if (r.servings != null) how = 'source only (engine found no driver)';
    else if (r.servingsComputed != null) how = 'computed, no source value';
    else how = 'nothing';
    count(finalSource, how);
    if (r.servingsBasis.source === 'computed' && r.servings != null) {
      count(reasons, r.servingsBasis.reason);
      mismatches.push({
        id: recipe.id, file, name: recipe.name, catalog, source: r.servings, computed: r.servingsComputed,
        confidence: r.servingsConfidence, reason: r.servingsBasis.reason,
        impliedPerPerson: r.servingsBasis.impliedPerPerson,
        drivers: r.servingsBasis.drivers.map((d) => `${d.category}:${d.ingredientId}=${d.amount}${d.unit}`),
      });
    }
    // Measured lines the engine could not place, weighted by how often.
    for (const line of recipe.ingredients ?? []) {
      if (!line || line.optional || line.amount == null) continue;
      if (engine.categoryOf(line) != null) continue;
      if (engine.understood(line)) continue;
      count(gaps, `${line.id} | ${line.name}`);
    }
  }
  ratios.sort((a, b) => a - b);
  const median = ratios.length ? Math.round(ratios[Math.floor(ratios.length / 2)] * 100) / 100 : null;
  mismatches.sort((a, b) => Math.abs(Math.log(b.source / b.computed)) - Math.abs(Math.log(a.source / a.computed)));
  const effective = corpus.filter(({ recipe }) => effectiveServings(engine.compute(recipe)) != null).length;
  const summary = {
    recipes: corpus.length,
    catalog: corpus.filter((c) => c.catalog).length,
    candidates: corpus.filter((c) => !c.catalog).length,
    sourceStates: stated,
    sourceMissing: missing,
    computed,
    computedWithoutSource: computedNoSource,
    withEffectiveServings: effective,
    withoutServings: corpus.length - effective,
    medianSourceToComputed: median,
  };
  const report = {
    version: 1,
    summary,
    finalSource: obj(finalSource),
    confidence: obj(confidence),
    distribution: obj(distribution),
    kinds: obj(kinds),
    mismatchReasons: obj(reasons),
    noValueReasons: obj(noneReasons),
    mismatches,
    unmappedMeasured: [...gaps.entries()].sort((a, b) => b[1] - a[1]).slice(0, 60).map(([k, n]) => ({ ingredient: k, recipes: n })),
  };
  return { report, parity };
}

export function statsMarkdown(report) {
  const s = report.summary;
  const table = (title, o) => [
    `| ${title} | recipes |`, '|---|---|',
    ...Object.entries(o).map(([k, v]) => `| ${k} | ${v} |`),
  ].join('\n');
  const top = report.mismatches.slice(0, 12).map((m) => `| ${m.id} | ${m.source} | ${m.computed} | ${m.reason} | ${m.drivers.join(', ')} |`);
  return [
    '<!-- servings-report:start (generated by tool/recipes/servings-report.mjs) -->',
    `Corpus: **${s.recipes}** recipes (${s.catalog} catalog, ${s.candidates} candidates). ` +
      `The source states servings for ${s.sourceStates}; ${s.sourceMissing} have none.`,
    '',
    `The engine computes a value for **${s.computed}** recipes, ${s.computedWithoutSource} of them without a source value. ` +
      `**${s.withEffectiveServings}** recipes end up with a yield the app can scale; ` +
      `${s.withoutServings} have none, each with an explicit reason below. ` +
      `Median source / computed ratio: ${s.medianSourceToComputed}.`,
    '',
    table('final source of the number', report.finalSource),
    '',
    table('confidence', report.confidence),
    '',
    table('computed people', report.distribution),
    '',
    table('reason a source value was rejected', report.mismatchReasons),
    '',
    table('reason there is no computed value', report.noValueReasons),
    '',
    '| largest mismatches | source | computed | reason | drivers |', '|---|---|---|---|---|',
    ...top,
    '<!-- servings-report:end -->',
  ].join('\n');
}

export function writeDoc(markdown, base = root) {
  const file = path.join(base, docFile);
  const now = fs.readFileSync(file, 'utf8');
  const start = now.indexOf('<!-- servings-report:start');
  const end = now.indexOf('<!-- servings-report:end -->');
  if (start < 0 || end < 0) throw new Error(`${docFile} needs the servings-report markers`);
  const next = now.slice(0, start) + markdown + now.slice(end + '<!-- servings-report:end -->'.length);
  fs.writeFileSync(file, next);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const corpus = loadCorpus();
  const { report, parity } = buildReport(corpus);
  fs.writeFileSync(path.join(root, reportFile), `${JSON.stringify(report, null, 1)}\n`);
  fs.mkdirSync(path.join(root, 'test/fixtures'), { recursive: true });
  fs.writeFileSync(path.join(root, parityFile), `${JSON.stringify(parity)}\n`);
  writeDoc(statsMarkdown(report));
  console.log(JSON.stringify({ ...report.summary, finalSource: report.finalSource, confidence: report.confidence }, null, 1));
}
