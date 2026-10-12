#!/usr/bin/env node
/**
 * اختبار تكامل شامل: بيقرأ كل الوصفات فعلًا وبيعدّي عليها دورة كاملة
 * (فهرس → وصفة → تعديل مقادير → جدول أوقات) وبيتأكد إن مفيش تعارض.
 *
 * الاستخدام: node scripts/verify-all.mjs
 */

import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  scaleRecipe,
  formatAmount,
  formatDuration,
  formatNumber,
  isScalable,
  roundAmountForUnit,
} from '../src/scale.ts';
import { stepSchedule, totalActiveMinutes, createTimer, tickTimer, timerText } from '../src/steps.ts';

const HERE = dirname(fileURLToPath(import.meta.url));
const DATA = join(HERE, '..', 'data');

const problems = [];
const notes = [];
const fail = (where, msg) => problems.push(`${where}: ${msg}`);

/** أصغر خطوة تقريب ممكنة للوحدة دي (نفس منطق src/scale.ts) */
function roundingStep(unit, expected) {
  if (unit === 'ملعقة صغيرة' || unit === 'ملعقة كبيرة' || unit === 'رشة') return 0.25;
  if (unit === 'كوب' || unit === 'جرام' || unit === 'مل' || unit === 'لتر') {
    return expected < 5 ? 0.5 : 2.5;
  }
  if (['حبة', 'فص', 'عود', 'رغيف', 'قرص', 'ورقة', 'حزمة'].includes(unit)) return 0.5;
  return 0.05 * Math.max(1, expected);
}

const index = JSON.parse(readFileSync(join(DATA, 'index.json'), 'utf8'));
const files = new Map();
for (const c of index.cuisines) {
  files.set(c.file, JSON.parse(readFileSync(join(DATA, c.file), 'utf8')));
}

let checked = 0;
let scaledCount = 0;
let timersRun = 0;

for (const entry of index.recipes) {
  const file = files.get(entry.file);
  const recipe = file?.recipes.find((r) => r.id === entry.id);
  if (!recipe) {
    fail(entry.id, `مش موجود في ${entry.file}`);
    continue;
  }
  const where = recipe.id;
  checked += 1;

  // 1) التعديل لأربعة أحجام مختلفة
  for (const target of [1, recipe.servings, recipe.servings * 2, Math.max(1, Math.round(recipe.servings / 2))]) {
    const scaled = scaleRecipe(recipe, target);
    scaledCount += 1;

    if (scaled.servings !== target) fail(where, `العدد المطلوب ${target} رجع ${scaled.servings}`);
    if (Math.abs(scaled.factor - target / recipe.servings) > 0.001) {
      fail(where, `المعامل غلط عند ${target}`);
    }
    if (scaled.ingredients.length !== recipe.ingredients.length) {
      fail(where, 'عدد المكونات اتغير بعد التعديل');
    }

    for (const ing of scaled.ingredients) {
      const base = recipe.ingredients.find((x) => x.id === ing.id);
      if (!base) {
        fail(where, `مكوّن مختفي: ${ing.id}`);
        continue;
      }

      // المكوّنات non-scalable لازم تفضل زي ما هي
      if (!isScalable(base) && ing.amount !== base.amount) {
        fail(where, `${ing.id} كان المفروض يفضل ثابت (${base.amount}) ورجع ${ing.amount}`);
      }

      // الكمية المعدّلة لازم تكون قريبة من الكمية المنطقية مع مراعاة التقريب العملي للمطبخ
      if (isScalable(base) && base.amount) {
        const expected = base.amount * scaled.factor;
        const step = roundingStep(base.unit, expected);
        const tolerance = Math.max(step, expected * 0.05) + 1e-6;
        if (Math.abs((ing.amount ?? 0) - expected) > tolerance) {
          fail(
            where,
            `${ing.id}: المتوقع ≈${expected.toFixed(2)} والنتيجة ${ing.amount} (وحدة: ${base.unit})`
          );
        }
      }

      // نص العرض لازم يكون موجود ومفيهوش NaN أو undefined أو رقم فاصلة غريبة
      if (typeof ing.display !== 'string' || !ing.display.trim()) {
        fail(where, `${ing.id}: نص العرض فاضي`);
      }
      if (/NaN|undefined|null|Infinity/.test(ing.display)) {
        fail(where, `${ing.id}: نص العرض فيه قيمة غلط: ${ing.display}`);
      }
      if (/\d\.\d/.test(ing.display) && !/\.\d\d/.test(ing.display)) {
        notes.push(`${where} → ${ing.name}: كسر عشري في العرض «${ing.display}»`);
      }
    }

    // الأوقات
    if (scaled.totalTime !== scaled.prepTime + scaled.cookTime) {
      fail(where, `الإجمالي مش متساوي مع ${target} أفراد`);
    }
    if (target > recipe.servings && scaled.totalTime < recipe.totalTime) {
      fail(where, 'الوقت قلّ مع زيادة عدد الأشخاص');
    }

    // جدول الخطوات
    const schedule = stepSchedule(scaled);
    if (schedule.length !== recipe.steps.length) fail(where, 'عدد الخطوات اتغير');
    schedule.forEach((item, i) => {
      if (item.n !== i + 1) fail(where, `ترقيم الخطوات غلط في الجدول عند ${i + 1}`);
      if (item.duration < 0) fail(where, `مدة سالبة في الخطوة ${item.n}`);
      if (!/^(\d+:)?\d\d:\d\d$/.test(item.startClock)) fail(where, `تنسيق وقت البداية غلط: ${item.startClock}`);
      if (!/^(\d+:)?\d\d:\d\d$/.test(item.endClock)) fail(where, `تنسيق وقت النهاية غلط: ${item.endClock}`);
      if (item.duration > 0 && item.end !== item.start + item.duration) {
        fail(where, `حساب بداية/نهاية الخطوة ${item.n} غلط`);
      }
    });
    if (totalActiveMinutes(scaled) < 0) fail(where, 'الوقت الفعلي سالب');
  }

  // 2) مؤقّت حقيقي: نعدّي على كل ثواني الوصفة ونتأكد إنه بيخلص عند آخر خطوة
  const scaled = scaleRecipe(recipe, recipe.servings);
  let timer = createTimer(scaled);
  const totalSeconds = scaled.steps.reduce((s, x) => s + x.duration * 60, 0);
  let ticks = 0;
  while (!timer.finished && ticks <= totalSeconds + 5) {
    timer = tickTimer(scaled, timer, 1);
    ticks += 1;
    timerText(timer);
  }
  timersRun += 1;
  if (!timer.finished) fail(where, `المؤقّت مش خلص بعد ${ticks} ثانية (المفروض ${totalSeconds})`);
  else if (ticks < totalSeconds) fail(where, `المؤقّت خلص بدري: ${ticks} من ${totalSeconds}`);

  // 3) تكرار التعديل مايغيّرش النتيجة (idempotence)
  const a = scaleRecipe(recipe, recipe.servings * 2);
  const b = scaleRecipe(recipe, recipe.servings * 2);
  if (JSON.stringify(a.ingredients) !== JSON.stringify(b.ingredients)) {
    fail(where, 'نفس المدخلات بتدي نتايج مختلفة');
  }
}

// 4) اختبارات وحدات صغيرة
const unitCases = [
  [0.4, 'ملعقة كبيرة', 0.5],
  [11.25, 'كوب', 11.25],
  [250, 'جرام', 250],
  [2.6, 'حبة', 2.5],
  [0.2, 'ملعقة صغيرة', 0.25],
];
for (const [input, unit, expected] of unitCases) {
  const got = roundAmountForUnit(input, unit);
  if (got !== expected) fail('roundAmountForUnit', `${input} ${unit} → ${got} والمتوقع ${expected}`);
}
if (formatNumber(1.5) !== '1½') fail('formatNumber', formatNumber(1.5));
if (formatDuration(90) !== 'ساعة و٣٠ دقيقة') fail('formatDuration', formatDuration(90));
if (formatAmount({ amount: null, unit: null, label: 'حسب الرغبة' }) !== 'حسب الرغبة') {
  fail('formatAmount', 'حالة amount: null');
}

/* ============================================================
   التقرير
   ============================================================ */

console.log('═'.repeat(64));
console.log('اختبار تكامل دفتر وصفات سفرة');
console.log('═'.repeat(64));
console.log(`  وصفات مفحوصة: ${checked}`);
console.log(`  عمليات تعديل مقادير: ${scaledCount}`);
console.log(`  مؤقّتات اشتغلت: ${timersRun}`);

if (notes.length) {
  console.log(`  ملاحظات عرض (${notes.length}):`);
  notes.slice(0, 10).forEach((n) => console.log(`    · ${n}`));
}

if (problems.length) {
  console.log('─'.repeat(64));
  console.log(`مشاكل (${problems.length}):`);
  problems.slice(0, 30).forEach((p) => console.log(`  ✗ ${p}`));
  console.log('═'.repeat(64));
  process.exit(1);
}

console.log('─'.repeat(64));
console.log('كل الوصفات عدّت الاختبار بنجاح ✓');
console.log('═'.repeat(64));

