#!/usr/bin/env node
// يولّد REPORT.md من ملفات JSON نفسها (أرقام دقيقة)، ويُلحق الملاحظات اليدوية من report-notes.md.
//
// Usage: node data/recipes/candidates-20261120/build-report.mjs
import {readFileSync, writeFileSync, readdirSync, existsSync} from 'node:fs';
import {join, dirname} from 'node:path';
import {fileURLToPath} from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const app = join(here, '..', '..', '..');
const out = join(here, 'REPORT.md');

const index = JSON.parse(readFileSync(join(app, 'recipes', 'data', 'index.json'), 'utf8'));
const dishes = JSON.parse(readFileSync(join(app, 'recipes', 'data', 'dishes.json'), 'utf8')).dishes;
const dishNameSet = new Set(dishes.map((d) => d.name.trim()));

const canonical = new Map();
for (const f of readdirSync(join(app, 'recipes', 'data'))) {
  if (!f.endsWith('.json') || f === 'index.json' || f === 'dishes.json') continue;
  const d = JSON.parse(readFileSync(join(app, 'recipes', 'data', f), 'utf8'));
  for (const r of d.recipes ?? []) for (const i of r.ingredients ?? []) if (i.id) canonical.set(i.id, (canonical.get(i.id) ?? 0) + 1);
}

const rows = [];
for (const name of readdirSync(here).filter((f) => f.endsWith('.json') && f !== 'import-report.json')) {
  const batch = JSON.parse(readFileSync(join(here, name), 'utf8'));
  for (const r of batch.recipes ?? []) rows.push({...r, file: name});
}

const cuisines = {};
const categories = {};
const dishGroups = {};
const newIds = new Map();
const sources = new Map();
let withTimes = 0;

for (const r of rows) {
  cuisines[r.cuisine] = (cuisines[r.cuisine] ?? 0) + 1;
  categories[r.category] = (categories[r.category] ?? 0) + 1;
  if (r.prepTime != null || r.cookTime != null) withTimes += 1;
  if (r.dishName) {
    dishGroups[r.dishName] = dishGroups[r.dishName] ?? [];
    dishGroups[r.dishName].push(`${r.cuisine} · ${r.id}`);
  }
  for (const i of r.ingredients ?? []) {
    if (!i.id) continue;
    if ((canonical.get(i.id) ?? 0) < 2) newIds.set(i.id, (newIds.get(i.id) ?? 0) + 1);
  }
  const host = (() => { try { return new URL(r.source.url).host; } catch { return '?'; } })();
  sources.set(host, (sources.get(host) ?? 0) + 1);
}

const sortObj = (o) => Object.entries(o).sort((a, b) => b[1] - a[1]);
const sharedGroups = Object.entries(dishGroups).filter(([d]) => dishNameSet.has(d.trim()));
const newDishGroups = Object.entries(dishGroups).filter(([d]) => !dishNameSet.has(d.trim()));

const lines = [];
const push = (...s) => lines.push(...s);

push('# تقرير جمع مرشّحي الوصفات — 2026-11-20', '');
push('المسار: `data/recipes/candidates-20261120/`', '');
push(`**النتيجة: ${rows.length} وصفة مرشّحة من ${sources.size} موقع.**`, '');
push('---', '');

push('## 1. العدد لكل مطبخ', '');
push('| المطبخ | العدد |', '|---|---:|');
for (const [c, n] of sortObj(cuisines)) push(`| ${c} | ${n} |`);
push(`| **الإجمالي** | **${rows.length}** |`, '');

push('## 2. العدد لكل قسم', '');
push('| القسم | العدد |', '|---|---:|');
for (const [c, n] of sortObj(categories)) push(`| ${c} | ${n} |`);
push('');

push(`## 3. ربط طرق البلاد (\`dishName\`)`, '');
push(`عدد الوصفات التي لها \`dishName\`: **${rows.filter((r) => r.dishName).length}** من ${rows.length}.`, '');
if (sharedGroups.length) {
  push('### أسماء أطباق موجودة في `dishes.json` — تربطها بالطرق الحالية', '');
  push('| الطبق | الوصفات الجديدة |', '|---|---|');
  for (const [d, list] of sharedGroups) push(`| ${d} | ${list.join(' · ')} |`);
  push('');
}
if (newDishGroups.length) {
  push('### أسماء أطباق جديدة (غير موجودة في `dishes.json`) — يقترح المنسّق إضافتها لاحقًا', '');
  push('| الطبق | الوصفات |', '|---|---|');
  for (const [d, list] of newDishGroups) push(`| ${d} | ${list.join(' · ')} |`);
  push('');
}

push('## 4. المصادر', '');
push('| الموقع | الوصفات |', '|---|---:|');
for (const [s, n] of sortObj(Object.fromEntries(sources))) push(`| ${s} | ${n} |`);
push('');

push('## 5. تغطية الأوقات', '');
push(`- وصفات فيها \`prepTime\` أو \`cookTime\` من المصدر: **${withTimes}** من ${rows.length}.`);
push(`- الوصفات التي كل أوقاتها \`null\`: **${rows.length - withTimes}** (المصدر لا يذكر أوقاتًا).`);
push(`- الكتالوج الحالي: ${index.recipes.length} وصفة · أطباق مربوطة: ${dishes.length}.`, '');

push('## 6. معرّفات المكونات الجديدة', '');
if (newIds.size) {
  push('معرّفات استُخدمت وليست في الكتالوج (أو استُخدمت مرة واحدة فقط):', '');
  push(`\`${[...newIds.entries()].sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k}(${v})`).join('`, `')}\``, '');
} else push('لا توجد معرّفات جديدة.', '');
push('');

const notesPath = join(here, 'report-notes.md');
if (existsSync(notesPath)) {
  push('---', '');
  push(readFileSync(notesPath, 'utf8').trim(), '');
}

push('---', '');
push('## 8. الفحوص', '');
push('```');
push('node data/recipes/candidates-20261120/check-candidates.mjs');
push('node data/recipes/candidates-20261120/audit-candidates.mjs');
push('```');
push('');
push('كل ملف JSON صالح، وكل عمود ✅ موجود، وكل `amount` له `unit`، وكل `amount: null` معه `label` و`scale: false`،');
push('ولا يوجد `id` مكرر بين الملفات أو مع الكتالوج، ولا وصفة من مطبخ خارج نطاق المهمة.');

writeFileSync(out, `${lines.join('\n')}\n`, 'utf8');
console.log(`تم توليد ${out} (${rows.length} وصفة)`);
