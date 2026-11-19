#!/usr/bin/env node
// فحص مرشّحي الوصفات (نسخة 19 نوفمبر 2026) قبل التسليم.
//
// Usage:
//   node data/recipes/candidates-20261120/check-candidates.mjs            # فحص كل الملفات في المجلد
//   node data/recipes/candidates-20261120/check-candidates.mjs --find ملوخية
//
// --find يبحث في كتالوج الوصفات (recipes/data/index.json) عن طبق بالاسم
//         عشان تتأكد إنه مش موجود قبل ما تجمعه.
//
// الفحص يطابق أعمدة الملف: data/recipes/candidates-YYYYMMDD/README أو القسم 3
// من docs/agents/RECIPES-AGENT-BRIEF-20261119.md.
import {readFileSync, readdirSync, statSync, existsSync} from 'node:fs';
import {join, dirname} from 'node:path';
import {fileURLToPath} from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const arg = process.argv[2];
const onlyFile = arg && arg.endsWith('.json') ? (arg.includes('/') || arg.includes('\\') ? arg : join(here, arg)) : null;
const folder = arg && !arg.startsWith('--') && !onlyFile ? arg : here;
const app = join(here, '..', '..', '..');

/* ============================ البحث السريع ============================ */
const findIndex = process.argv.indexOf('--find');
if (findIndex > -1) {
  const needle = (process.argv[findIndex + 1] ?? '').trim();
  if (!needle) {
    console.error('اكتب كلمة البحث: node check-candidates.mjs --find ملوخية');
    process.exit(2);
  }
  const index = JSON.parse(readFileSync(join(app, 'recipes', 'data', 'index.json'), 'utf8'));
  const hits = index.recipes.filter((r) => String(r.name).includes(needle));
  if (!hits.length) console.log(`مفيش وصفة في الكتالوج باسم فيه «${needle}» — يمكنك جمعها.`);
  else {
    console.log(`الكتالوج فيه ${hits.length} وصفة باسم فيه «${needle}»:`);
    for (const r of hits.slice(0, 40)) console.log(`  ${String(r.cuisine).padEnd(10)} ${String(r.category).padEnd(12)} ${r.name}  [${r.id}]`);
    if (hits.length > 40) console.log(`  ... و${hits.length - 40} أخرى`);
  }
  process.exit(0);
}

/* ============================ الثوابت ============================ */
const CATEGORIES = ['طبق رئيسي', 'فطار', 'شوربة', 'سلطة', 'مقبلات', 'طبق جانبي', 'حلويات', 'مخبوزات', 'صلصة', 'مشروب'];
const MEAL_TIMES = ['فطار', 'غداء', 'عشاء', 'سناك'];
const DIFFICULTIES = ['سهل', 'متوسط', 'صعب'];

const ARAB_EG = ['مصري'];
const ARAB_SA = ['سعودي'];
const ARAB_LV = ['شامي', 'لبناني', 'سوري', 'فلسطيني', 'أردني'];
const ARAB_MA = ['مغربي'];
const ARAB_OTHER = ['عراقي', 'يمني', 'إماراتي', 'كويتي', 'عُماني', 'عماني', 'بحريني', 'قطري', 'تونسي', 'جزائري', 'ليبي', 'سوداني'];
const WORLD = ['إيطالي', 'فرنسي', 'يوناني', 'إسباني', 'تركي', 'صيني', 'ياباني', 'هندي', 'تايلاندي', 'كوري', 'مكسيكي'];

function prefixFor(cuisine) {
  if (ARAB_EG.includes(cuisine)) return ['eg-'];
  if (ARAB_SA.includes(cuisine)) return ['sa-'];
  if (ARAB_LV.includes(cuisine)) return ['lv-'];
  if (ARAB_MA.includes(cuisine)) return ['ma-'];
  if (ARAB_OTHER.includes(cuisine)) return ['ar-'];
  if (WORLD.includes(cuisine)) return ['w-'];
  return null;
}

/* ============================ تحميل الكتالوج ============================ */
const catalog = JSON.parse(readFileSync(join(app, 'recipes', 'data', 'index.json'), 'utf8'));
const catalogIds = new Set(catalog.recipes.map((r) => r.id));

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
const catalogKey = new Map();
for (const r of catalog.recipes) catalogKey.set(`${norm(r.name)}|${r.cuisine.trim()}`, r.id);

/* ============================ فلتر المحتوى ============================ */
const STORE_LIST = ['خنزير', 'الخنزير', 'بيره', 'البيره', 'ساكي', 'تكيلا', 'التكيلا', 'فودكا', 'ويسكي', 'براندي', 'كونياك', 'روم', 'الروم', 'ميرين', 'بانسيتا', 'بروشوتو', 'برشوتو', 'بيبروني', 'كوريزو', 'تشوريزو', 'التشوريزو', 'كيلباسا', 'اندوي', 'ستاوت', 'بورتر', 'غلوفاين', 'شاوشينغ', 'شمبانيا', 'هام', 'المقدد'];
const STORE_PHRASES = ['لحم مقدد', 'شيري جاف', 'نبيذ', 'سيدر جاف'];
const FORBIDDEN_WORDS = new Set(STORE_LIST.map(norm));
const FORBIDDEN_PHRASES = STORE_PHRASES.map(norm);
const VINEGAR = /(^| )خل (ال)?(نبيذ|سيدر)( (ال)?(احمر|ابيض))?/g;
const CHOICE = /(^| )(او|بدون|غير|اختياري|اختياريه)( |$)/;
function forbidden(text) {
  const n = ` ${norm(text).replace(VINEGAR, ' ')} `;
  const found = [...new Set(n.trim().split(' '))].filter((w) => FORBIDDEN_WORDS.has(w));
  for (const p of FORBIDDEN_PHRASES) if (n.includes(` ${p} `)) found.push(p);
  return found;
}

/* ============================ معرّفات المكونات المعتمدة ============================ */
const canonicalIds = new Map();
for (const f of readdirSync(join(app, 'recipes', 'data'))) {
  if (!f.endsWith('.json') || f === 'index.json' || f === 'dishes.json') continue;
  const data = JSON.parse(readFileSync(join(app, 'recipes', 'data', f), 'utf8'));
  for (const r of data.recipes ?? []) for (const i of r.ingredients ?? []) if (i.id) canonicalIds.set(i.id, (canonicalIds.get(i.id) ?? 0) + 1);
}
const knownIds = new Set([...canonicalIds.entries()].filter(([, n]) => n >= 2).map(([id]) => id));

/* ============================ الفحص ============================ */
const errors = [];
const warnings = [];
const newIngredientIds = new Map();
const seenIds = new Map();
const stats = {recipes: 0, ingredients: 0, steps: 0, unknownStepTimes: 0, withDishName: 0, categories: {}, cuisines: {}, files: 0, dishNames: new Set(), sources: new Map()};
const add = (file, id, msg) => errors.push(`${file} :: ${id} :: ${msg}`);

const isText = (v) => typeof v === 'string' && v.trim().length > 0;
const isNum = (v) => typeof v === 'number' && Number.isFinite(v);
const isPosInt = (v) => Number.isInteger(v) && v > 0;

const targets = onlyFile
  ? [onlyFile]
  : readdirSync(folder).filter((f) => f.endsWith('.json') && f !== 'import-report.json').map((f) => join(folder, f));

for (const path of targets) {
  const name = path.split(/[\\/]/).pop();
  if (!existsSync(path) || !statSync(path).isFile()) continue;
  let batch;
  try {
    batch = JSON.parse(readFileSync(path, 'utf8'));
  } catch (e) {
    errors.push(`${name} :: ملف JSON غير صالح (${e.message})`);
    continue;
  }
  stats.files += 1;
  if (!isText(batch.collectedAt)) add(name, '-', 'مفيش collectedAt');
  if (!isText(batch.collector)) add(name, '-', 'مفيش collector');
  if (!Array.isArray(batch.recipes)) {
    add(name, '-', 'مفيش مصفوفة recipes');
    continue;
  }

  for (const r of batch.recipes) {
    const id = isText(r.id) ? r.id : '(بدون id)';
    const where = `${name}/${id}`;
    stats.recipes += 1;
    stats.cuisines[r.cuisine] = (stats.cuisines[r.cuisine] ?? 0) + 1;
    stats.categories[r.category] = (stats.categories[r.category] ?? 0) + 1;

    // ✅ الهوية
    if (!isText(r.id)) add(where, 'id', 'مفيش id');
    else if (!/^[a-z0-9-]+$/.test(r.id)) add(where, 'id', 'id فيه حروف غير مسموحة');
    else {
      const prefixes = prefixFor(r.cuisine);
      if (!prefixes) add(where, 'cuisine', `مطبخ غير مسموح في هذه المهمة: «${r.cuisine}»`);
      else if (!prefixes.some((p) => r.id.startsWith(p))) add(where, 'id', `البادئة لازم تكون ${prefixes.join(' أو ')} للمطبخ «${r.cuisine}»`);
    }
    if (seenIds.has(r.id)) add(where, 'id', `id مكرر مع ${seenIds.get(r.id)}`);
    else seenIds.set(r.id, name);
    if (catalogIds.has(r.id)) add(where, 'id', 'نفس id موجود في الكتالوج');

    // ✅ الأعمدة الإلزامية
    for (const k of ['name', 'cuisine', 'category', 'description']) if (!isText(r[k])) add(where, k, `مفيش ${k}`);
    if (!CATEGORIES.includes(r.category)) add(where, 'category', `قسم غير مسموح: ${r.category}`);
    if (!isPosInt(r.servings)) add(where, 'servings', 'servings لازم عدد صحيح موجب مذكور في المصدر');
    if (!isText(r.source?.site)) add(where, 'source.site', 'مفيش source.site');
    if (!isText(r.source?.retrievedAt) || !/^\d{4}-\d\d-\d\d$/.test(r.source.retrievedAt)) add(where, 'source.retrievedAt', 'source.retrievedAt لازم YYYY-MM-DD');
    const url = r.source?.url;
    if (!isText(url) || !/^https?:\/\//.test(url)) add(where, 'source.url', 'مفيش رابط مصدر صالح');
    else if (/^https?:\/\/[^/]+\/?$/.test(url)) add(where, 'source.url', 'الرابط صفحة رئيسية وليس صفحة وصفة');

    // التكرار مع الكتالوج: نفس الاسم ونفس المطبخ
    const key = `${norm(r.name)}|${String(r.cuisine).trim()}`;
    if (catalogKey.has(key)) add(where, 'name', `مكرر: نفس الاسم والمطبخ موجود في الكتالوج (${catalogKey.get(key)})`);

    // ⭐ الأعمدة المفضّلة
    if (r.dishName !== undefined && r.dishName !== null && !isText(r.dishName)) add(where, 'dishName', 'dishName لازم نص');
    if (r.dishName) {
      stats.withDishName += 1;
      stats.dishNames.add(r.dishName.trim());
    }
    if (r.wayNote !== undefined && r.wayNote !== null && !isText(r.wayNote)) add(where, 'wayNote', 'wayNote لازم نص');
    if (r.mealTimes !== undefined && r.mealTimes !== null) {
      if (!Array.isArray(r.mealTimes)) add(where, 'mealTimes', 'mealTimes لازم قائمة');
      else for (const m of r.mealTimes) if (!MEAL_TIMES.includes(m)) add(where, 'mealTimes', `قيمة غير مسموحة: ${m}`);
    }
    for (const k of ['prepTime', 'cookTime', 'totalTime']) {
      if (r[k] !== undefined && r[k] !== null && !(isNum(r[k]) && r[k] >= 0)) add(where, k, `${k} لازم رقم أو null`);
    }
    if (r.nameEn !== undefined && r.nameEn !== null && !isText(r.nameEn)) add(where, 'nameEn', 'nameEn لازم نص');
    for (const k of ['title', 'author']) {
      if (r.source?.[k] !== undefined && r.source[k] !== null && !isText(r.source[k])) add(where, `source.${k}`, `source.${k} لازم نص`);
    }
    if (r.region !== undefined && r.region !== null && !isText(r.region)) add(where, 'region', 'region لازم نص');
    if (r.difficulty !== undefined && r.difficulty !== null && !DIFFICULTIES.includes(r.difficulty)) add(where, 'difficulty', `صعوبة غير مسموحة: ${r.difficulty}`);
    if (r.equipment !== undefined && r.equipment !== null) {
      if (!Array.isArray(r.equipment)) add(where, 'equipment', 'equipment لازم قائمة');
      else for (const e of r.equipment) if (!isText(e)) add(where, 'equipment', 'عنصر equipment لازم نص');
    }
    if (r.occasion !== undefined && r.occasion !== null && !isText(r.occasion)) add(where, 'occasion', 'occasion لازم نص');
    if (r.spicy !== undefined && r.spicy !== null && r.spicy !== true) add(where, 'spicy', 'spicy لازم true أو null');

    // ✅ المكونات
    if (!Array.isArray(r.ingredients) || !r.ingredients.length) add(where, 'ingredients', 'مفيش مكونات');
    else {
      const ingIds = new Set();
      r.ingredients.forEach((i, n) => {
        const w = `${where} مكوّن#${n + 1}`;
        if (!isText(i.name)) add(w, 'name', 'مكوّن بدون اسم');
        if (!isText(i.id)) add(w, 'id', 'مكوّن بدون id');
        else {
          if (!/^[a-z0-9-]+$/.test(i.id)) add(w, 'id', `id غير صالح: ${i.id}`);
          if (ingIds.has(i.id)) add(w, 'id', `id مكوّن مكرر في نفس الوصفة: ${i.id}`);
          ingIds.add(i.id);
          if (!knownIds.has(i.id)) newIngredientIds.set(i.id, (newIngredientIds.get(i.id) ?? 0) + 1);
        }
        const hasAmount = i.amount !== null && i.amount !== undefined;
        if (hasAmount) {
          if (!isNum(i.amount)) add(w, 'amount', `الكمية لازم رقم مش «${i.amount}»`);
          else if (i.amount <= 0) add(w, 'amount', `الكمية لازم أكبر من صفر (${i.amount})`);
          if (!isText(i.unit)) add(w, 'unit', 'كمية بدون وحدة');
          if (i.amountMax !== undefined && i.amountMax !== null) {
            if (!isNum(i.amountMax)) add(w, 'amountMax', 'amountMax لازم رقم');
            else if (!(i.amountMax > i.amount)) add(w, 'amountMax', 'amountMax لازم أكبر من amount');
          }
        } else {
          if (i.scale !== false) add(w, 'scale', 'amount: null لازم معاه scale: false');
          if (!isText(i.label)) add(w, 'label', 'amount: null من غير label');
        }
        if (i.optional !== undefined && i.optional !== null && i.optional !== true) add(w, 'optional', 'optional لازم true أو يُحذف');
        for (const k of ['group', 'note']) if (i[k] !== undefined && i[k] !== null && !isText(i[k])) add(w, k, `${k} لازم نص`);
        for (const hit of forbidden(i.name)) {
          if (!i.optional && !CHOICE.test(norm(i.name))) add(w, 'content', `مكوّن ممنوع: ${hit}`);
        }
        stats.ingredients += 1;
      });
    }

    // ✅ الخطوات
    if (!Array.isArray(r.steps) || !r.steps.length) add(where, 'steps', 'مفيش خطوات');
    else {
      r.steps.forEach((s, n) => {
        const w = `${where} خطوة#${n + 1}`;
        if (s.n !== n + 1) add(w, 'n', `n لازم يكون ${n + 1} مش ${s.n}`);
        if (!isText(s.text)) add(w, 'text', 'خطوة بدون نص');
        if (s.duration !== undefined && s.duration !== null && !(isNum(s.duration) && s.duration >= 0)) add(w, 'duration', 'duration لازم رقم موجب أو null');
        if (s.duration === undefined || s.duration === null) stats.unknownStepTimes += 1;
        if (s.passive !== undefined && s.passive !== null && s.passive !== true) add(w, 'passive', 'passive لازم true أو يُحذف');
        if (s.tip !== undefined && s.tip !== null && !isText(s.tip)) add(w, 'tip', 'tip لازم نص');
        stats.steps += 1;
      });
    }

    const nameHits = forbidden(r.name);
    if (nameHits.length) add(where, 'content', `اسم الطبق ممنوع (${nameHits.join(', ')})`);

    const host = (() => { try { return new URL(url).host; } catch { return '?'; } })();
    stats.sources.set(host, (stats.sources.get(host) ?? 0) + 1);
  }
}

/* ============================ التقرير ============================ */
const line = '═'.repeat(68);
console.log(line);
console.log('فحص مرشّحي الوصفات — 2026-11-20');
console.log(line);
console.log(`  الملفات: ${stats.files} · الوصفات: ${stats.recipes} · المكونات: ${stats.ingredients} · الخطوات: ${stats.steps}`);
console.log(`  بوقت خطوة غير مذكور: ${stats.unknownStepTimes} · بدون dishName: ${stats.recipes - stats.withDishName}`);
console.log('');
console.log(`  المطابخ: ${Object.entries(stats.cuisines).map(([k, v]) => `${k} ${v}`).join(' · ')}`);
console.log(`  الأقسام: ${Object.entries(stats.categories).map(([k, v]) => `${k} ${v}`).join(' · ')}`);
console.log(`  المواقع: ${Object.entries([...stats.sources.entries()]).sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k} ${v}`).join(' · ')}`);
if (stats.dishNames.size) console.log(`  أسماء أطباق مشتركة (dishName): ${[...stats.dishNames].join(' · ')}`);

if (newIngredientIds.size) {
  const list = [...newIngredientIds.entries()].sort((a, b) => b[1] - a[1]);
  console.log('');
  console.log(`  معرّفات مكونات جديدة (${list.length}) — تُذكر في التقرير:`);
  console.log(`   ${list.map(([k, v]) => `${k}(${v})`).join(' ')}`);
}

if (warnings.length) {
  console.log(`\n  تنبيهات (${warnings.length}):`);
  warnings.slice(0, 30).forEach((w) => console.log(`   ! ${w}`));
}
if (errors.length) {
  console.log(`\n  أخطاء (${errors.length}):`);
  errors.slice(0, 50).forEach((e) => console.log(`   ✗ ${e}`));
  if (errors.length > 50) console.log(`   ... و${errors.length - 50} خطأ آخر`);
  console.log(line);
  process.exit(1);
}
console.log('\nكله تمام، مفيش أخطاء.');
process.exit(0);
