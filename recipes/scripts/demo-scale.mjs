#!/usr/bin/env node
/**
 * عرض تجريبي: بيوضّح إزاي المقادير والأوقات بتتغيّر مع عدد الأشخاص.
 *
 * الاستخدام:
 *   node scripts/demo-scale.mjs                       # أول وصفة في كل مطبخ
 *   node scripts/demo-scale.mjs eg-koshari 8          # وصفة معيّنة لعدد أشخاص
 *   node scripts/demo-scale.mjs it-carbonara 2 8      # مقارنة بين عددين
 */

import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { scaleRecipe, formatDuration, toArabicDigits } from '../src/scale.ts';
import { stepSchedule } from '../src/steps.ts';

const HERE = dirname(fileURLToPath(import.meta.url));
const DATA = join(HERE, '..', 'data');

const index = JSON.parse(readFileSync(join(DATA, 'index.json'), 'utf8'));
const cache = new Map();

function loadRecipe(id) {
  const entry = index.recipes.find((r) => r.id === id);
  if (!entry) {
    console.error(`مفيش وصفة بالمعرّف: ${id}`);
    console.error('المتاح:', index.recipes.map((r) => r.id).join(', '));
    process.exit(1);
  }
  if (!cache.has(entry.file)) {
    cache.set(entry.file, JSON.parse(readFileSync(join(DATA, entry.file), 'utf8')));
  }
  return cache.get(entry.file).recipes.find((r) => r.id === id);
}

function printRecipe(recipe, servings) {
  const scaled = scaleRecipe(recipe, servings);

  console.log('');
  console.log('═'.repeat(64));
  console.log(`  ${recipe.name}  (${recipe.nameEn ?? ''})`);
  console.log(`  ${recipe.cuisine} · ${recipe.category} · ${recipe.difficulty}`);
  console.log(`  الأساس: ${toArabicDigits(recipe.servings)} أفراد → المطلوب: ${toArabicDigits(scaled.servings)} أفراد  (المعامل ×${scaled.factor})`);
  console.log(`  الوقت: ${formatDuration(scaled.totalTime)}  |  شغل فعلي: ${formatDuration(scaled.activeTime)}  |  انتظار: ${formatDuration(scaled.passiveTime)}`);
  console.log('─'.repeat(64));
  console.log('  المقادير:');
  for (const ing of scaled.ingredients) {
    const star = ing.scale === false ? ' (ثابت)' : '';
    const opt = ing.optional ? ' [اختياري]' : '';
    console.log(`    • ${ing.name.padEnd(34)} ${ing.display}${star}${opt}`);
  }
  console.log('─'.repeat(64));
  console.log('  الخطوات وأوقاتها:');
  for (const item of stepSchedule(scaled)) {
    const label = item.outsideSession
      ? 'خارج الوقت'
      : `${item.durationText} ${item.passive ? 'انتظار' : 'شغل'}`;
    console.log(`    ${item.label}. (${label}) ${item.text.slice(0, 52)}…`);
  }
  if (recipe.notes) console.log(`  ملاحظة: ${recipe.notes}`);
  console.log('═'.repeat(64));
}

const [id, ...servingsArgs] = process.argv.slice(2);

if (!id) {
  // أول وصفة في كل مطبخ كعيّنة
  for (const c of index.cuisines) {
    const entry = index.recipes.find((r) => r.file === c.file);
    if (entry) printRecipe(loadRecipe(entry.id), entry.servings);
  }
} else {
  const recipe = loadRecipe(id);
  const targets = servingsArgs.length ? servingsArgs.map(Number) : [recipe.servings];
  for (const t of targets) printRecipe(recipe, t);
}
