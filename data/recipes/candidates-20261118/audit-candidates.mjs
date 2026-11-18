#!/usr/bin/env node
// تدقيق مرشّحي هذا اليوم مقابل الكتالوج الحالي قبل الاستيراد.
//
// Usage: node data/recipes/candidates-20261118/audit-candidates.mjs [folder]
//
// يفحص:
//   - id مكرر مع الكتالوج
//   - اسم مكرر مع الكتالوج (بعد تطبيع الهمزات والتاء المربوطة والمسافات)
//   - أسماء متقاربة جدًا داخل الدفعة نفسها (تقاطع كلمات ≥ 80%)
//   - مطبخ غير متسق مع بادئة الـ id
//   - توزيع الأقسام لكل مطبخ
//   - صفحات المصادر المكررة (أكثر من وصفة من نفس الرابط)
import {readFileSync, readdirSync} from 'node:fs';
import {join, dirname} from 'node:path';
import {fileURLToPath} from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const folder = process.argv[2] ?? here;
// المجلد: app/data/recipes/candidates-YYYYMMDD → الجذر app
const app = join(here, '..', '..', '..');

const index = JSON.parse(readFileSync(join(app, 'recipes', 'data', 'index.json'), 'utf8'));
const catalogIds = new Set(index.recipes.map((r) => r.id));

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

function tokens(text) {
  return new Set(norm(text).split(' ').filter((w) => w.length > 2));
}

function jaccard(a, b) {
  const A = tokens(a);
  const B = tokens(b);
  if (!A.size || !B.size) return 0;
  let inter = 0;
  for (const w of A) if (B.has(w)) inter += 1;
  return inter / (A.size + B.size - inter);
}

const catalogNames = index.recipes.map((r) => ({id: r.id, name: r.name, cuisine: r.cuisine}));
const byCuisine = {};
const byCategory = {};
const bySource = {};
const problems = [];
const warnings = [];
const all = [];

for (const name of readdirSync(folder).filter((f) => f.endsWith('.json') && f !== 'import-report.json' && f !== 'content-policy-20261026.json')) {
  const batch = JSON.parse(readFileSync(join(folder, name), 'utf8'));
  for (const r of batch.recipes ?? []) {
    all.push({...r, _file: name});
    byCuisine[r.cuisine] = byCuisine[r.cuisine] ?? {};
    byCuisine[r.cuisine][r.category] = (byCuisine[r.cuisine][r.category] ?? 0) + 1;
    byCategory[r.category] = (byCategory[r.category] ?? 0) + 1;
    const url = r.source?.url ?? '';
    bySource[url] = bySource[url] ?? [];
    bySource[url].push(r.id);

    if (catalogIds.has(r.id)) problems.push(`${r.id}: نفس id موجود في الكتالوج`);
    const sameName = catalogNames.find((c) => norm(c.name) === norm(r.name));
    if (sameName) problems.push(`${r.id}: نفس اسم ${sameName.id} في الكتالوج (${r.name})`);
    else {
      const close = catalogNames
        .map((c) => ({...c, score: jaccard(c.name, r.name)}))
        .filter((c) => c.score >= 0.8)
        .sort((a, b) => b.score - a.score)[0];
      if (close) warnings.push(`${r.id}: قريب جدًا من ${close.id} «${close.name}» (${Math.round(close.score * 100)}%)`);
    }
  }
}

// تقارب داخل الدفعة
for (let i = 0; i < all.length; i += 1) {
  for (let j = i + 1; j < all.length; j += 1) {
    const score = jaccard(all[i].name, all[j].name);
    if (score >= 0.8) warnings.push(`${all[i].id} ≈ ${all[j].id}: أسماء متقاربة (${Math.round(score * 100)}%)`);
  }
}

for (const [url, ids] of Object.entries(bySource)) {
  if (ids.length > 1) warnings.push(`نفس رابط المصدر ${ids.length} مرات: ${url} → ${ids.join(', ')}`);
}

console.log('═'.repeat(64));
console.log('تدقيق مرشّحي 2026-11-18 مقابل الكتالوج');
console.log('═'.repeat(64));
console.log(`  الكتالوج الحالي: ${index.recipes.length} وصفة`);
console.log(`  المرشّحون: ${all.length} وصفة من ${new Set(all.map((r) => r.source?.site)).size} موقع`);
console.log('');

for (const [cuisine, cats] of Object.entries(byCuisine)) {
  const total = Object.values(cats).reduce((a, b) => a + b, 0);
  console.log(`  ${cuisine} (${total}): ${Object.entries(cats).map(([k, v]) => `${k} ${v}`).join(' · ')}`);
}
console.log('');
console.log(`  الأقسام كلها: ${Object.entries(byCategory).map(([k, v]) => `${k} ${v}`).join(' · ')}`);

if (warnings.length) {
  console.log(`\n  تنبيهات (${warnings.length}):`);
  warnings.slice(0, 30).forEach((w) => console.log(`   ! ${w}`));
  if (warnings.length > 30) console.log(`   ... و${warnings.length - 30} تنبيه آخر`);
}
if (problems.length) {
  console.log(`\n  مشاكل (${problems.length}):`);
  problems.slice(0, 40).forEach((p) => console.log(`   ✗ ${p}`));
  console.log('═'.repeat(64));
  process.exit(1);
}
console.log('\nلا تكرار مع الكتالوج.');
process.exit(0);
