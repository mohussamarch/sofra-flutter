#!/usr/bin/env node
/**
 * مدقّق دفتر وصفات «سفرة».
 *
 * بيشتغل بأمر واحد:  node scripts/validate.mjs
 * وبيفحص:
 *   - إن كل ملفات المطابخ موجودة والـ JSON سليم
 *   - إن كل وصفة فيها كل الحقول المطلوبة بنوع صح
 *   - إن الإجمالي = وقت التحضير + وقت الطهي
 *   - إن كل كمية رقم (مش نص) إلا لو `amount: null` ومعاها `scale: false`
 *   - إن أرقام الخطوات متسلسلة من 1
 *   - إن معرّفات الوصفات والمكونات فريدة
 *   - إن فهرس index.json مطابق لملفات المطابخ فعلًا
 *
 * الخروج بكود 1 لو فيه أي خطأ، عشان يشتغل في CI أو pre-commit hook.
 */

import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, '..');
const DATA = join(ROOT, 'data');

const CUISINES = [
  { slug: 'egyptian', name: 'مصري', file: 'egyptian.json', minRecipes: 10 },
  { slug: 'levantine', name: 'شامي', file: 'levantine.json', minRecipes: 10 },
  { slug: 'saudi', name: 'سعودي', file: 'saudi.json', minRecipes: 10 },
  { slug: 'italian', name: 'إيطالي', file: 'italian.json', minRecipes: 10 },
];

const CATEGORIES = [
  'طبق رئيسي',
  'مقبلات',
  'شوربة',
  'فطار',
  'سلطة',
  'مخبوزات',
  'حلويات',
  'مشروبات',
];

const DIFFICULTIES = ['سهل', 'متوسط', 'متقدم'];

const errors = [];
const warnings = [];
const stats = { recipes: 0, ingredients: 0, steps: 0, minutes: 0 };

const err = (where, message) => errors.push(`${where}: ${message}`);
const warn = (where, message) => warnings.push(`${where}: ${message}`);

const readJson = (path) => {
  try {
    return JSON.parse(readFileSync(path, 'utf8'));
  } catch (e) {
    err(path.replace(ROOT, '.'), `JSON غير سليم أو غير مقروء (${e.message})`);
    return null;
  }
};

const isNonEmptyString = (v) => typeof v === 'string' && v.trim().length > 0;
const isPositiveNumber = (v) => typeof v === 'number' && Number.isFinite(v) && v > 0;
const isNonNegativeNumber = (v) => typeof v === 'number' && Number.isFinite(v) && v >= 0;

/** فحص وصفة واحدة */
function checkRecipe(recipe, where, seenIds) {
  const id = isNonEmptyString(recipe.id) ? recipe.id : where;

  if (!isNonEmptyString(recipe.id)) err(where, 'مفيش id');
  if (seenIds.has(recipe.id)) err(where, `id مكرر: ${recipe.id}`);
  seenIds.add(recipe.id);

  if (!isNonEmptyString(recipe.name)) err(id, 'مفيش اسم');
  if (!isNonEmptyString(recipe.nameEn)) warn(id, 'مفيش nameEn');
  if (!isNonEmptyString(recipe.description)) warn(id, 'مفيش وصف مختصر');
  if (!isNonEmptyString(recipe.cuisine)) err(id, 'مفيش مطبخ');
  if (!CATEGORIES.includes(recipe.category)) err(id, `قسم غير معروف: ${recipe.category}`);
  if (!DIFFICULTIES.includes(recipe.difficulty)) err(id, `صعوبة غير معروفة: ${recipe.difficulty}`);

  if (!isPositiveNumber(recipe.servings)) err(id, 'عدد الأشخاص لازم يكون رقم أكبر من صفر');

  const { prepTime, cookTime, totalTime } = recipe;
  if (!isNonNegativeNumber(prepTime)) err(id, 'وقت التحضير لازم يكون رقم');
  if (!isNonNegativeNumber(cookTime)) err(id, 'وقت الطهي لازم يكون رقم');
  if (!isNonNegativeNumber(totalTime)) err(id, 'الوقت الإجمالي لازم يكون رقم');
  else if (prepTime + cookTime !== totalTime) {
    err(id, `الوقت الإجمالي ${totalTime} ≠ ${prepTime} + ${cookTime}`);
  }

  // المكونات
  if (!Array.isArray(recipe.ingredients) || recipe.ingredients.length === 0) {
    err(id, 'مفيش مكونات');
  } else {
    const ingIds = new Set();
    recipe.ingredients.forEach((ing, i) => {
      const w = `${id} → مكوّن ${i + 1}`;
      if (!isNonEmptyString(ing.id)) err(w, 'مفيش id');
      else if (ingIds.has(ing.id)) err(w, `id مكرر: ${ing.id}`);
      else ingIds.add(ing.id);

      if (!isNonEmptyString(ing.name)) err(w, 'مفيش اسم');

      const hasAmount = ing.amount !== null && ing.amount !== undefined;
      if (hasAmount) {
        if (typeof ing.amount !== 'number' || !Number.isFinite(ing.amount)) {
          err(w, `الكمية لازم تكون رقم مش «${ing.amount}» — استخدم 0.5 مش "1/2"`);
        } else if (ing.amount <= 0) {
          err(w, `الكمية لازم تكون أكبر من صفر (${ing.amount})`);
        }
        if (!isNonEmptyString(ing.unit)) err(w, 'فيه كمية من غير وحدة');
      } else {
        // كمية مش مقاسة: لازم تتحصّن من التعديل
        if (ing.scale !== false) err(w, 'كمية null لازم معاها scale: false');
        if (!isNonEmptyString(ing.label)) warn(w, 'كمية null من غير label (مثال: حسب الرغبة)');
      }

      if (ing.scale === false && !isNonEmptyString(ing.note) && !isNonEmptyString(ing.label)) {
        warn(w, 'scale: false من غير note توضح السبب');
      }

      stats.ingredients += 1;
    });
  }

  // الخطوات
  if (!Array.isArray(recipe.steps) || recipe.steps.length === 0) {
    err(id, 'مفيش خطوات');
  } else {
    recipe.steps.forEach((step, i) => {
      const w = `${id} → خطوة ${i + 1}`;
      if (step.n !== i + 1) err(w, `رقم الخطوة لازم يكون ${i + 1} مش ${step.n}`);
      if (!isNonEmptyString(step.text)) err(w, 'مفيش نص للخطوة');
      if (!isPositiveNumber(step.duration)) {
        // مدة صفر مسموحة لخطوة انتظار بره الجلسة (نقع ليلة كاملة) ووقتها مكتوب في نص الخطوة
        if (isNonNegativeNumber(step.duration) && step.duration === 0) {
          if (step.passive === true) {
            warn(w, 'خطوة passive بمدة صفر');
          }
        } else {
          err(w, 'مدة الخطوة لازم تكون رقم بالدقائق');
        }
      }
      if (step.passive !== undefined && typeof step.passive !== 'boolean') {
        err(w, 'passive لازم تكون true أو false');
      }
      stats.steps += 1;
    });
  }

  if (!Array.isArray(recipe.tags) || recipe.tags.length === 0) warn(id, 'مفيش تاجات');
  if (!isNonEmptyString(recipe.notes)) warn(id, 'مفيش ملاحظات');

  // نظافة النصوص: منع الشرطة الطويلة والحروف اللاتينية جوه النص العربي
  const texts = [
    recipe.name,
    recipe.description,
    recipe.notes,
    ...(Array.isArray(recipe.ingredients) ? recipe.ingredients.map((i) => i.name) : []),
    ...(Array.isArray(recipe.steps) ? recipe.steps.flatMap((s) => [s.text, s.tip]) : []),
  ].filter(isNonEmptyString);

  for (const t of texts) {
    if (t.includes('—') || t.includes('–')) {
      // بعض النصوص بتستخدم الشرطة كفاصل مقصود، فبنكتفي بتنبيه
      warn(id, `النص فيه شرطة طويلة: «${t.slice(0, 40)}…»`);
      break;
    }
  }
  for (const t of texts) {
    if (/[A-Za-z]{4,}/.test(t) && !/[()]/.test(t)) {
      warn(id, `النص فيه كلمة إنجليزية من غير أقواس: «${t.slice(0, 40)}…»`);
      break;
    }
  }

  // فحوص منطقية للوقت.
  // الموديل: الخطوات السلبية (فرن، تبريد، نقع) بتشتغل لوحدها في نفس الوقت اللي المستخدم فيه بيعمل خطوات تانية.
  // فبنحسب حد أدنى تقديري للوقت: شغل فعلي + أطول خطوة انتظار.
  const steps = Array.isArray(recipe.steps) ? recipe.steps : [];
  const sumOf = (list) =>
    list.reduce((s, x) => s + (isNonNegativeNumber(x.duration) ? x.duration : 0), 0);

  const activeTime = sumOf(steps.filter((s) => s.passive !== true));
  const passiveSteps = steps.filter((s) => s.passive === true);
  const passiveTotal = sumOf(passiveSteps);
  const passiveLongest = passiveSteps.reduce(
    (max, s) => Math.max(max, isNonNegativeNumber(s.duration) ? s.duration : 0),
    0
  );
  const lowerBound = activeTime + passiveLongest;

  if (lowerBound > 0 && totalTime > 0) {
    if (passiveLongest > totalTime) {
      err(id, `أطول خطوة انتظار (${passiveLongest}) أطول من الوقت الكلي (${totalTime})`);
    }
    // لو الوقت الكلي أقل بكتير من الحد الأدنى، يبقى الوقت مكتوب غلط مش إن الخطوات متداخلة
    if (lowerBound > totalTime * 1.6 || lowerBound - totalTime > 20) {
      warn(
        id,
        `الوقت الكلي (${totalTime}) أقل من الحد الأدنى المحسوب (${lowerBound}) — راجع الأوقات أو اعمل الخطوات المتوازية passive`
      );
    }
    if (activeTime === 0 && passiveSteps.length > 0) {
      warn(id, 'كل الخطوات سلبية — فيه خطوة تحضير ناقصة؟');
    }
    if (passiveTotal > totalTime * 2 && activeTime < 10) {
      warn(id, 'وقت الانتظار طويل جداً مقارنة بالوقت الكلي — راجع تصنيف الخطوات');
    }
  }

  stats.recipes += 1;
  stats.minutes += isNonNegativeNumber(totalTime) ? totalTime : 0;
}

/* ============================================================
   التشغيل
   ============================================================ */

const allIds = new Set();
const perCuisine = [];

for (const c of CUISINES) {
  const path = join(DATA, c.file);
  if (!existsSync(path)) {
    err(c.file, 'الملف مش موجود');
    continue;
  }
  const data = readJson(path);
  if (!data) continue;

  if (data.cuisine !== c.name) err(c.file, `المطبخ لازم يكون «${c.name}» مش «${data.cuisine}»`);
  if (data.cuisineSlug !== c.slug) err(c.file, `cuisineSlug لازم يكون «${c.slug}»`);
  if (!Array.isArray(data.recipes)) {
    err(c.file, 'مفيش مصفوفة recipes');
    continue;
  }
  if (data.recipes.length < c.minRecipes) {
    warn(c.file, `عدد الوصفات ${data.recipes.length} أقل من ${c.minRecipes}`);
  }

  data.recipes.forEach((recipe, i) => checkRecipe(recipe, `${c.file} → وصفة ${i + 1}`, allIds));

  perCuisine.push({ ...c, count: data.recipes.length });
}

// فحص الفهرس لو موجود
const indexPath = join(DATA, 'index.json');
if (existsSync(indexPath)) {
  const index = readJson(indexPath);
  if (index) {
    if (!Array.isArray(index.recipes)) {
      err('index.json', 'مفيش مصفوفة recipes');
    } else {
      const indexIds = new Set(index.recipes.map((r) => r.id));
      for (const id of allIds) {
        if (!indexIds.has(id)) err('index.json', `وصفة ناقصة من الفهرس: ${id}`);
      }
      for (const id of indexIds) {
        if (!allIds.has(id)) err('index.json', `وصفة في الفهرس مش موجودة في الملفات: ${id}`);
      }
      for (const c of index.cuisines ?? []) {
        const found = perCuisine.find((p) => p.slug === c.slug);
        if (!found) err('index.json', `مطبخ غير معروف في الفهرس: ${c.slug}`);
        else if (found.count !== c.count) {
          err('index.json', `عدد وصفات ${c.slug} في الفهرس ${c.count} وفي الملف ${found.count}`);
        }
      }
    }
  }
} else {
  warn('index.json', 'الفهرس مش موجود — شغّل: node scripts/build-index.mjs');
}

// الملفات الزيادة في مجلد data
for (const f of readdirSync(DATA)) {
  if (!f.endsWith('.json')) continue;
  if (f === 'index.json') continue;
  if (!CUISINES.some((c) => c.file === f)) warn('data', `ملف مش معروف: ${f}`);
}

/* ============================================================
   التقرير
   ============================================================ */

const line = '─'.repeat(60);
console.log(line);
console.log('مدقّق وصفات سفرة');
console.log(line);

for (const c of perCuisine) {
  console.log(`  ${c.name.padEnd(8)} ${String(c.count).padStart(3)} وصفة   (${c.file})`);
}
console.log(line);
console.log(
  `  الإجمالي: ${stats.recipes} وصفة · ${stats.ingredients} مكوّن · ${stats.steps} خطوة · ${Math.round(
    stats.minutes / 60
  )} ساعة طهي`
);

if (warnings.length) {
  console.log(line);
  console.log(`تنبيهات (${warnings.length}):`);
  warnings.slice(0, 40).forEach((w) => console.log(`  ! ${w}`));
  if (warnings.length > 40) console.log(`  ... و${warnings.length - 40} تنبيه كمان`);
}

if (errors.length) {
  console.log(line);
  console.log(`أخطاء (${errors.length}):`);
  errors.slice(0, 60).forEach((e) => console.log(`  ✗ ${e}`));
  if (errors.length > 60) console.log(`  ... و${errors.length - 60} خطأ كمان`);
  console.log(line);
  process.exit(1);
}

console.log(line);
console.log('كله تمام، مفيش أخطاء.');
process.exit(0);
