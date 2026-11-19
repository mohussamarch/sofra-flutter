#!/usr/bin/env node
// تدقيق دفعة المرشّحين: التقارب الاسمي، تغطية ربط البلاد (dishName)، والتوزيع.
//
// Usage: node data/recipes/candidates-20261120/audit-candidates.mjs [folder]
import {readFileSync, readdirSync, existsSync} from 'node:fs';
import {join, dirname} from 'node:path';
import {fileURLToPath} from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const folder = process.argv[2] ?? here;
const app = join(here, '..', '..', '..');

const index = JSON.parse(readFileSync(join(app, 'recipes', 'data', 'index.json'), 'utf8'));
const dishes = JSON.parse(readFileSync(join(app, 'recipes', 'data', 'dishes.json'), 'utf8')).dishes;
const dishNames = new Set(dishes.map((d) => d.name.trim()));

function norm(text) {
  return String(text)
    .normalize('NFKC')
    .replace(/[ً-ٰٟـ]/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي')
    .replace(/[^\p{L}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}
const tokens = (t) => new Set(norm(t).split(' ').filter((w) => w.length > 2));
function jaccard(a, b) {
  const A = tokens(a);
  const B = tokens(b);
  if (!A.size || !B.size) return 0;
  let inter = 0;
  for (const w of A) if (B.has(w)) inter += 1;
  return inter / (A.size + B.size - inter);
}

const rows = [];
const byCuisine = {};
const byCategory = {};
const warnings = [];
const problems = [];

for (const name of readdirSync(folder).filter((f) => f.endsWith('.json') && f !== 'import-report.json')) {
  const batch = JSON.parse(readFileSync(join(folder, name), 'utf8'));
  for (const r of batch.recipes ?? []) {
    rows.push({...r, _file: name});
    byCuisine[r.cuisine] = byCuisine[r.cuisine] ?? {};
    byCuisine[r.cuisine][r.category] = (byCuisine[r.cuisine][r.category] ?? 0) + 1;
    byCategory[r.category] = (byCategory[r.category] ?? 0) + 1;

    const sameCuisine = index.recipes.filter((c) => norm(c.cuisine) === norm(r.cuisine));
    const exact = sameCuisine.find((c) => norm(c.name) === norm(r.name));
    if (exact) problems.push(`${r.id}: اسم ومطبخ مكرر (${exact.id})`);

    const close = sameCuisine
      .map((c) => ({...c, score: jaccard(c.name, r.name)}))
      .filter((c) => c.score >= 0.8)
      .sort((a, b) => b.score - a.score)[0];
    if (close && !exact) warnings.push(`${r.id} «${r.name}» ≈ ${close.id} «${close.name}» (${Math.round(close.score * 100)}%)`);

    if (r.dishName && !dishNames.has(r.dishName.trim())) {
      warnings.push(`${r.id}: dishName «${r.dishName}» مش في dishes.json (اسم جديد للربط)`);
    }
  }
}

for (let i = 0; i < rows.length; i += 1) {
  for (let j = i + 1; j < rows.length; j += 1) {
    if (norm(rows[i].cuisine) === norm(rows[j].cuisine)) {
      const score = jaccard(rows[i].name, rows[j].name);
      if (score >= 0.8) warnings.push(`${rows[i].id} ≈ ${rows[j].id}: أسماء متقاربة داخل نفس المطبخ (${Math.round(score * 100)}%)`);
    }
  }
}

const line = '═'.repeat(68);
console.log(line);
console.log('تدقيق دفعة 2026-11-20');
console.log(line);
console.log(`  الكتالوج: ${index.recipes.length} وصفة · أطباق مربوطة بين البلاد: ${dishes.length}`);
console.log(`  المرشّحون: ${rows.length} من ${new Set(rows.map((r) => r.source?.site)).size} موقع`);
console.log('');
for (const [cuisine, cats] of Object.entries(byCuisine)) {
  const total = Object.values(cats).reduce((a, b) => a + b, 0);
  console.log(`  ${cuisine} (${total}): ${Object.entries(cats).map(([k, v]) => `${k} ${v}`).join(' · ')}`);
}
console.log('');
console.log(`  الأقسام: ${Object.entries(byCategory).map(([k, v]) => `${k} ${v}`).join(' · ')}`);

const shared = rows.filter((r) => r.dishName && dishNames.has(r.dishName.trim()));
console.log(`  وصفات تربطها أسماء أطباق موجودة في dishes.json: ${shared.length}`);
if (shared.length) {
  const groups = {};
  for (const r of shared) (groups[r.dishName] = groups[r.dishName] ?? []).push(`${r.cuisine}:${r.id}`);
  for (const [d, list] of Object.entries(groups)) console.log(`    ${d} ← ${list.join(', ')}`);
}

if (warnings.length) {
  console.log(`\n  تنبيهات (${warnings.length}):`);
  warnings.slice(0, 25).forEach((w) => console.log(`   ! ${w}`));
}
if (problems.length) {
  console.log(`\n  مشاكل (${problems.length}):`);
  problems.slice(0, 25).forEach((p) => console.log(`   ✗ ${p}`));
  process.exit(1);
}
console.log('\nلا تكرار مؤكد مع الكتالوج.');
process.exit(0);
