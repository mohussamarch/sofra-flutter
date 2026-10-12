#!/usr/bin/env node
/**
 * بناء فهرس الوصفات: data/index.json
 *
 * الفهرس بيحتوي نسخة مختصرة من كل وصفة (من غير المقادير والخطوات) عشان:
 *   - البحث والفلترة في الواجهة يبقى سريع
 *   - التطبيق يعرف يقرأ ملف المطبخ المناسب بس لما المستخدم يفتح الوصفة
 *
 * الاستخدام:  node scripts/build-index.mjs
 * شغّله بعد أي تعديل في ملفات الوصفات.
 */

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, '..');
const DATA = join(ROOT, 'data');

const CUISINES = [
  { name: 'مصري', slug: 'egyptian', file: 'egyptian.json' },
  { name: 'شامي', slug: 'levantine', file: 'levantine.json' },
  { name: 'سعودي', slug: 'saudi', file: 'saudi.json' },
  { name: 'إيطالي', slug: 'italian', file: 'italian.json' },
];

const UNITS = [
  'كوب',
  'ملعقة كبيرة',
  'ملعقة صغيرة',
  'جرام',
  'كيلو',
  'مل',
  'لتر',
  'حبة',
  'فص',
  'عود',
  'رغيف',
  'قرص',
  'ورقة',
  'حزمة',
  'رشة',
];

const categories = new Set();
const recipes = [];
const cuisines = [];

for (const c of CUISINES) {
  const path = join(DATA, c.file);
  if (!existsSync(path)) {
    console.warn(`تحذير: ${c.file} مش موجود، تم تخطيه`);
    continue;
  }
  const data = JSON.parse(readFileSync(path, 'utf8'));
  const list = data.recipes ?? [];

  for (const r of list) {
    categories.add(r.category);
    recipes.push({
      id: r.id,
      name: r.name,
      nameEn: r.nameEn,
      cuisine: r.cuisine,
      category: r.category,
      servings: r.servings,
      totalTime: r.totalTime,
      difficulty: r.difficulty,
      tags: r.tags ?? [],
      ingredientCount: (r.ingredients ?? []).length,
      stepCount: (r.steps ?? []).length,
      file: c.file,
    });
  }

  cuisines.push({ name: c.name, slug: c.slug, file: c.file, count: list.length });
}

const index = {
  version: '1.0.0',
  updatedAt: new Date().toISOString().slice(0, 10),
  cuisines,
  categories: [...categories],
  units: UNITS,
  recipes,
};

writeFileSync(join(DATA, 'index.json'), `${JSON.stringify(index, null, 2)}\n`, 'utf8');

console.log(`تم بناء الفهرس: ${recipes.length} وصفة من ${cuisines.length} مطابخ`);
for (const c of cuisines) console.log(`  ${c.name}: ${c.count}`);
console.log(`  الأقسام: ${[...categories].join(' · ')}`);
