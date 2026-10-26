// Holds active catalog recipes that need pork or alcohol, by the owner's
// decision of 26 October 2026: their index rows become `held-content` and
// the reasons are written to data/recipes/content-policy-20261026.json.
//
// A recipe is held when a required line names pork or an alcoholic drink as
// its only choice. Wine/cider vinegar is vinegar. A line that offers another
// option ("خنزير أو دجاج"), is optional, or says "بدون/غير" keeps the recipe.
//
// Usage: node tool/recipes/hold-content.mjs [--check]
import {readFileSync, writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';

const root = fileURLToPath(new URL('../../', import.meta.url));
const indexFile = `${root}recipes/data/index.json`;
const policyFile = `${root}data/recipes/content-policy-20261026.json`;

export function norm(text) {
  return text
    .normalize('NFKC')
    .replace(/[ً-ٰٟـ]/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي')
    .replace(/[^\p{L}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

const words = new Set(
  [
    'خنزير', 'الخنزير', 'بيره', 'البيره', 'ساكي', 'تكيلا', 'التكيلا', 'فودكا',
    'ويسكي', 'براندي', 'كونياك', 'روم', 'الروم', 'ميرين', 'بانسيتا', 'بروشوتو',
    'برشوتو', 'بيبروني', 'كوريزو', 'تشوريزو', 'التشوريزو', 'كيلباسا', 'اندوي',
    'ستاوت', 'بورتر', 'غلوفاين', 'شاوشينغ', 'شمبانيا', 'هام', 'المقدد',
  ].map(norm),
);
const phrases = ['لحم مقدد', 'شيري جاف', 'نبيذ', 'سيدر جاف'].map(norm);
const vinegar = /(^| )خل (ال)?(نبيذ|سيدر)( (ال)?(احمر|ابيض))?/g;
const choice = /(^| )(او|بدون|غير|اختياري|اختياريه)( |$)/;

/** What in [text] is pork or alcohol, after vinegar is set aside. */
export function forbidden(text) {
  const n = ` ${norm(text).replace(vinegar, ' ')} `;
  const found = [...new Set(n.trim().split(' '))].filter((w) => words.has(w));
  for (const p of phrases) if (n.includes(` ${p} `)) found.push(p);
  return found;
}

export function review(recipe) {
  const reasons = [];
  for (const hit of forbidden(recipe.name)) reasons.push({where: 'name', hit});
  for (const line of recipe.ingredients ?? []) {
    const hits = forbidden(line.name);
    if (!hits.length || line.optional || choice.test(norm(line.name))) continue;
    for (const hit of hits) reasons.push({where: line.name, hit});
  }
  return reasons;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const index = JSON.parse(readFileSync(indexFile, 'utf8'));
  let previous = [];
  try {
    previous = JSON.parse(readFileSync(policyFile, 'utf8')).held;
  } catch {
    // First run.
  }
  const groupOf = new Map(previous.map((h) => [h.id, h.cuisineGroup]));
  const files = {};
  const held = [];
  for (const row of index.recipes) {
    if (row.catalogStatus !== 'active' && row.catalogStatus !== 'held-content') continue;
    files[row.file] ??= JSON.parse(readFileSync(`${root}recipes/data/${row.file}`, 'utf8'));
    const recipe = files[row.file].recipes.find((r) => r.id === row.id);
    const reasons = review(recipe);
    if (reasons.length) {
      const cuisineGroup = row.cuisineGroup ?? groupOf.get(row.id) ?? null;
      held.push({id: row.id, name: recipe.name, cuisineGroup, reasons});
      row.catalogStatus = 'held-content';
      row.cuisineGroup = null;
    } else if (row.catalogStatus === 'held-content') {
      row.catalogStatus = 'active';
      row.cuisineGroup = groupOf.get(row.id) ?? null;
    }
  }
  // Held rows leave their display group, which counts active rows only.
  for (const group of index.cuisineGroups) {
    group.count = index.recipes.filter(
      (r) => r.catalogStatus === 'active' && r.cuisineGroup === group.id,
    ).length;
  }
  const policy = {
    decidedAt: '2026-10-26',
    decision: 'Recipes that need pork or alcohol are removed from the catalog.',
    held,
  };
  const indexText = `${JSON.stringify(index, null, 2)}\n`;
  const policyText = `${JSON.stringify(policy, null, 2)}\n`;
  if (process.argv.includes('--check')) {
    const same =
      readFileSync(indexFile, 'utf8').replace(/\r\n/g, '\n') === indexText &&
      readFileSync(policyFile, 'utf8').replace(/\r\n/g, '\n') === policyText;
    if (!same) throw new Error('Content policy is stale; run hold-content.mjs');
  } else {
    writeFileSync(indexFile, indexText);
    writeFileSync(policyFile, policyText);
  }
  const active = index.recipes.filter((r) => r.catalogStatus === 'active').length;
  console.log(`held ${held.length}, active ${active}`);
}
