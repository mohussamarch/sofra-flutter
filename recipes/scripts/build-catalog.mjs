#!/usr/bin/env node
/**
 * توليد كتالوج مختصر لكل الوصفات: data/CATALOG.md
 *
 * الاستخدام: node scripts/build-catalog.mjs
 * شغّله بعد أي إضافة وصفة، وهو بيتولّد من نفس الملفات (مفيش كتابة يدوية).
 */

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, '..');
const DATA = join(ROOT, 'data');
const OUT = join(DATA, 'CATALOG.md');

const AR = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
const ar = (v) => String(v).replace(/[0-9]/g, (d) => AR[Number(d)]);

const minutes = (m) => {
  const h = Math.floor(m / 60);
  const r = m % 60;
  if (!h) return `${ar(r)} د`;
  if (!r) return `${ar(h)} س`;
  return `${ar(h)} س ${ar(r)} د`;
};

const files = ['egyptian.json', 'levantine.json', 'saudi.json', 'italian.json'];
const lines = [];
let total = 0;

lines.push('# كتالوج وصفات سفرة');
lines.push('');
lines.push('> الملف ده بيتولّد أوتوماتيك: `node scripts/build-catalog.mjs` — متعدّلوش بإيدك.');
lines.push('');
lines.push('كل وصفة ليها مقادير مضبوطة على عدد أشخاص أساسي، و**المقادير وأوقات الخطوات بتتعدّل أوتوماتيك**');
lines.push('لما يتغيّر عدد الأشخاص من داخل البرنامج.');
lines.push('');

for (const file of files) {
  const path = join(DATA, file);
  if (!existsSync(path)) continue;
  const data = JSON.parse(readFileSync(path, 'utf8'));
  const byCategory = new Map();

  for (const r of data.recipes) {
    if (!byCategory.has(r.category)) byCategory.set(r.category, []);
    byCategory.get(r.category).push(r);
    total += 1;
  }

  lines.push(`## ${data.cuisine} — ${ar(data.recipes.length)} وصفة`);
  lines.push('');

  for (const [category, recipes] of byCategory) {
    lines.push(`### ${category}`);
    lines.push('');
    lines.push('| الوصفة | المعرّف | الأساس | الوقت | الخطوات | المكونات |');
    lines.push('|---|---|---|---|---|---|');
    for (const r of recipes) {
      lines.push(
        `| ${r.name} | \`${r.id}\` | ${ar(r.servings)} أفراد | ${minutes(r.totalTime)} | ${ar(
          r.steps.length
        )} | ${ar(r.ingredients.length)} |`
      );
    }
    lines.push('');
  }
}

lines.push('---');
lines.push('');
lines.push(`**الإجمالي: ${ar(total)} وصفة.**`);
lines.push('');
lines.push('## المطابخ');
lines.push('');
lines.push('| المطبخ | الملف | الوصفات |');
lines.push('|---|---|---|');
for (const file of files) {
  if (!existsSync(join(DATA, file))) continue;
  const d = JSON.parse(readFileSync(join(DATA, file), 'utf8'));
  lines.push(`| ${d.cuisine} | \`data/${file}\` | ${ar(d.recipes.length)} |`);
}
lines.push('');

writeFileSync(OUT, `${lines.join('\n')}`, 'utf8');
console.log(`تم توليد الكتالوج: ${OUT} (${total} وصفة)`);
