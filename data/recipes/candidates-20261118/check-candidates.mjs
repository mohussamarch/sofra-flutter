#!/usr/bin/env node
// فحص ملفات المرشّحين في هذا المجلد قبل التسليم.
//
// Usage: node data/recipes/candidates-20261118/check-candidates.mjs [folder]
//
// يفحص:
//   - صلاحية JSON لكل ملف
//   - {collectedAt, collector, recipes} والـ id فريد داخل الملف وبين الملفات
//   - id بصيغة مسموحة وبادئة تخص المطبخ
//   - servings عدد صحيح موجب مذكور في المصدر
//   - category من القائمة المسموحة
//   - لكل مكوّن id وname، وأي amount رقمي معه unit
//   - amount: null مصحوب بـ label و scale:false
//   - amountMax أكبر من amount
//   - الخطوات متسلسلة من 1 وفيها نص، والمدد أرقام أو null
//   - source.url رابط صفحة وصفة وليس الصفحة الرئيسية
//   - لا خنزير ولا كحول (نفس فلتر hold-content.mjs)
import {readFileSync, readdirSync, statSync} from 'node:fs';
import {join, dirname} from 'node:path';
import {fileURLToPath} from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const folder = process.argv[2] ?? here;

const CATEGORIES = ['طبق رئيسي', 'فطار', 'حلويات', 'شوربة', 'سلطة', 'مقبلات', 'مخبوزات'];
const CUISINE_PREFIX = {
  'مصري': ['eg-'],
  'سعودي': ['sa-'],
  'شامي': ['lv-'],
  'لبناني': ['lv-'],
  'فلسطيني': ['lv-'],
  'أردني': ['lv-'],
  'سوري': ['lv-'],
  'مغربي': ['ma-'],
};
const OTHER_PREFIX = ['ar-'];

const STORE_LIST = [
  'خنزير', 'الخنزير', 'بيره', 'البيره', 'ساكي', 'تكيلا', 'التكيلا', 'فودكا',
  'ويسكي', 'براندي', 'كونياك', 'روم', 'الروم', 'ميرين', 'بانسيتا', 'بروشوتو',
  'برشوتو', 'بيبروني', 'كوريزو', 'تشوريزو', 'التشوريزو', 'كيلباسا', 'اندوي',
  'ستاوت', 'بورتر', 'غلوفاين', 'شاوشينغ', 'شمبانيا', 'هام', 'المقدد',
];
const STORE_PHRASES = ['لحم مقدد', 'شيري جاف', 'نبيذ', 'سيدر جاف'];

// تطبيع وتقسيم لكلمات كاملة — نفس منطق hold-content.mjs:
// «مفروم» لا تحتوي «روم» بعد التقسيم، فلا تُرفض ظلمًا.
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
const FORBIDDEN_WORDS = new Set(STORE_LIST.map(norm));
const FORBIDDEN_PHRASES = STORE_PHRASES.map(norm);
const VINEGAR = /(^| )خل (ال)?(نبيذ|سيدر)( (ال)?(احمر|ابيض))?/g;
const CHOICE = /(^| )(او|بدون|غير|اختياري|اختياريه)( |$)/;

function forbidden(text) {
  const normalized = ` ${norm(text).replace(VINEGAR, ' ')} `;
  const found = [...new Set(normalized.trim().split(' '))].filter((w) => FORBIDDEN_WORDS.has(w));
  for (const phrase of FORBIDDEN_PHRASES) if (normalized.includes(` ${phrase} `)) found.push(phrase);
  return found;
}

const errors = [];
const warnings = [];
const seenIds = new Map();
const stats = {recipes: 0, ingredients: 0, steps: 0, unknownTimes: 0};
const add = (file, id, msg) => errors.push(`${file} :: ${id} :: ${msg}`);

const isText = (v) => typeof v === 'string' && v.trim().length > 0;
const isNum = (v) => typeof v === 'number' && Number.isFinite(v);
const isPosInt = (v) => Number.isInteger(v) && v > 0;

for (const name of readdirSync(folder).filter((f) => f.endsWith('.json') && !f.startsWith('import-') && f !== 'content-policy-20261026.json')) {
  const path = join(folder, name);
  if (!statSync(path).isFile()) continue;
  let batch;
  try {
    batch = JSON.parse(readFileSync(path, 'utf8'));
  } catch (e) {
    errors.push(`${name} :: ملف JSON غير صالح (${e.message})`);
    continue;
  }
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

    if (!isText(r.id)) add(where, 'id', 'مفيش id');
    else if (!/^[a-z0-9-]+$/.test(r.id)) add(where, 'id', 'id فيه حروف غير مسموحة');
    else {
      const prefixes = CUISINE_PREFIX[r.cuisine] ?? OTHER_PREFIX;
      if (!prefixes.some((p) => r.id.startsWith(p))) {
        add(where, 'id', `البادئة لازم تكون ${prefixes.join(' أو ')} للمطبخ «${r.cuisine}»`);
      }
    }
    if (seenIds.has(r.id)) add(where, 'id', `id مكرر مع ${seenIds.get(r.id)}`);
    else seenIds.set(r.id, name);

    for (const k of ['name', 'cuisine', 'category', 'description']) {
      if (!isText(r[k])) add(where, k, `مفيش ${k}`);
    }
    if (!CATEGORIES.includes(r.category)) add(where, 'category', `قسم غير مسموح: ${r.category}`);
    if (!isPosInt(r.servings)) add(where, 'servings', 'servings لازم يكون عدد صحيح موجب مذكور في المصدر');

    for (const k of ['prepTime', 'cookTime', 'totalTime']) {
      if (r[k] !== null && r[k] !== undefined && !isNum(r[k])) add(where, k, `${k} لازم رقم أو null`);
      if (r[k] === undefined) add(where, k, `${k} مطلوب (null لو المصدر مش ذاكره)`);
    }
    if (r.difficulty !== null && r.difficulty !== undefined && !isText(r.difficulty)) {
      add(where, 'difficulty', 'difficulty لازم نص أو null');
    }

    if (!Array.isArray(r.ingredients) || !r.ingredients.length) add(where, 'ingredients', 'مفيش مكونات');
    else {
      const ingIds = new Set();
      r.ingredients.forEach((i, n) => {
        const w = `${where} مكوّن#${n + 1}`;
        if (!isText(i.id)) add(w, 'id', 'مكوّن بدون id');
        else if (ingIds.has(i.id)) add(w, 'id', `id مكوّن مكرر: ${i.id}`);
        else ingIds.add(i.id);
        if (!isText(i.name)) add(w, 'name', 'مكوّن بدون اسم');
        const hasAmount = i.amount !== null && i.amount !== undefined;
        if (hasAmount) {
          if (!isNum(i.amount)) add(w, 'amount', `الكمية لازم رقم مش «${i.amount}»`);
          else if (i.amount <= 0) add(w, 'amount', `الكمية لازم أكبر من صفر (${i.amount})`);
          if (!isText(i.unit)) add(w, 'unit', 'كمية بدون وحدة');
          if (i.amountMax !== undefined) {
            if (!isNum(i.amountMax)) add(w, 'amountMax', 'amountMax لازم رقم');
            else if (i.amountMax <= i.amount) add(w, 'amountMax', 'amountMax لازم أكبر من amount');
          }
        } else {
          if (i.scale !== false) add(w, 'scale', 'amount: null لازم معاه scale: false');
          if (!isText(i.label)) add(w, 'label', 'amount: null من غير label');
        }
        for (const hit of forbidden(i.name)) {
          if (!i.optional && !CHOICE.test(norm(i.name))) add(w, 'content', `مكوّن ممنوع: ${hit}`);
        }
        stats.ingredients += 1;
      });
    }

    if (!Array.isArray(r.steps) || !r.steps.length) add(where, 'steps', 'مفيش خطوات');
    else {
      r.steps.forEach((s, n) => {
        const w = `${where} خطوة#${n + 1}`;
        if (s.n !== n + 1) add(w, 'n', `n لازم يكون ${n + 1} مش ${s.n}`);
        if (!isText(s.text)) add(w, 'text', 'خطوة بدون نص');
        if (s.duration !== null && s.duration !== undefined && !(isNum(s.duration) && s.duration >= 0)) {
          add(w, 'duration', 'duration لازم رقم موجب أو null');
        }
        if (s.duration === null || s.duration === undefined) stats.unknownTimes += 1;
        stats.steps += 1;
      });
    }

    const url = r.source?.url;
    if (!isText(url) || !/^https?:\/\//.test(url)) add(where, 'source.url', 'مفيش رابط مصدر صالح');
    else if (/^https?:\/\/[^/]+\/?$/.test(url)) warnings.push(`${where} :: source.url يبدو صفحة رئيسية: ${url}`);
    if (!isText(r.source?.site)) warnings.push(`${where} :: مفيش source.site`);
    if (!isText(r.source?.title)) warnings.push(`${where} :: مفيش source.title`);
    if (!isText(r.source?.retrievedAt)) warnings.push(`${where} :: مفيش source.retrievedAt`);

    const nameHits = forbidden(r.name);
    if (nameHits.length) add(where, 'content', `اسم الطبق ممنوع (${nameHits.join(', ')})`);
  }
}

console.log('═'.repeat(64));
console.log('فحص مرشّحي الوصفات');
console.log('═'.repeat(64));
console.log(`  الملفات: ${readdirSync(folder).filter((f) => f.endsWith('.json')).length}`);
console.log(`  الوصفات: ${stats.recipes} · المكونات: ${stats.ingredients} · الخطوات: ${stats.steps}`);
console.log(`  خطوات بوقت غير مذكور: ${stats.unknownTimes}`);

if (warnings.length) {
  console.log(`\n  تنبيهات (${warnings.length}):`);
  warnings.slice(0, 25).forEach((w) => console.log(`   ! ${w}`));
  if (warnings.length > 25) console.log(`   ... و${warnings.length - 25} تنبيه آخر`);
}
if (errors.length) {
  console.log(`\n  أخطاء (${errors.length}):`);
  errors.slice(0, 40).forEach((e) => console.log(`   ✗ ${e}`));
  if (errors.length > 40) console.log(`   ... و${errors.length - 40} خطأ آخر`);
  console.log('═'.repeat(64));
  process.exit(1);
}
console.log('\nكله تمام، مفيش أخطاء.');
process.exit(0);
