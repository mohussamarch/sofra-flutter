// Builds data/ingredients/directory.json: a rawId -> canonicalId map from the
// active recipe catalog onto the hand-curated ingredient vocabulary.
//
// Matching is deliberately conservative: a raw ingredient id is mapped only when
// it is itself a vocabulary id, or when every line using it has a cleaned name
// that equals exactly one vocabulary name/alias. Anything ambiguous stays
// unmapped. This map is for kitchen stock only, never for nutrition.
//
// Usage: node tool/ingredients/build-directory.mjs [--check] [--unmapped=N]
import {readFile, writeFile, mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {resolve, dirname} from 'node:path';
import {fileURLToPath} from 'node:url';

const root = fileURLToPath(new URL('../../', import.meta.url));
export const vocabularyFile = 'data/ingredients/vocabulary.json';
export const directoryFile = 'data/ingredients/directory.json';
export const indexFile = 'recipes/data/index.json';
const zones = new Set(['fridge', 'freezer', 'pantry']);

function need(ok, message) {
  if (!ok) throw new Error(message);
}

export function sha256(text) {
  return createHash('sha256').update(text.replace(/\r\n/g, '\n'), 'utf8').digest('hex');
}

/** Arabic search key: alef variants, ta marbuta, alef maqsura, no tashkeel. */
export function normKey(value) {
  return value
    .normalize('NFKC')
    .replace(/[ً-ٰٟـ]/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

// Leading quantity words ("ملعقتان كبيرتان", "رشة", "فصوص", "عود"...).
const quantityLead = new RegExp(
  '^(?:' +
    [
      '(?:ملعقه|ملعقتان|ملعقتين|ملاعق)(?: (?:كبيره|صغيره|كبيرتان|صغيرتان|كبار|صغار))?',
      'كوب', 'كوبان', 'كوبين', 'اكواب', 'رشه', 'رشتان', 'حبه', 'حبات', 'حبتان', 'حبتين',
      'فص', 'فصوص', 'فصين', 'قطعه', 'قطع', 'علبه', 'علب', 'كيلو', 'جرام', 'غرام', 'مل',
      'لتر', 'عودا', 'فصا', 'فصان', 'راس', 'رؤوس', 'حفنه', 'باقه', 'حزمه', 'ربطه', 'عود', 'اعواد', 'عودان', 'رطل', 'اونصه',
      'شريحه', 'شرائح', 'نصف', 'ربع', 'قليل من', 'بعض', 'انصاف', 'ارباع', 'اوتاد',
      'اغصان', 'عرق', 'عروق', 'زهيرات', 'حبتا', 'حبتان', 'بضع', 'بضعه', 'من', 'رغيف', 'رغيفان',
    ].join('|') +
    ')(?: |$)',
);

// Purpose clauses are cut from their first word to the end of the name.
const purposeWords = new Set(
  [
    'لسلق', 'لدهن', 'لفرك', 'لخلطه', 'لتمويج', 'لرش', 'لعجينه', 'لماء', 'لخفق',
    'لتذويب', 'لحشو', 'لتزيين', 'لتقديم', 'لقلي', 'لطهي', 'لعمل', 'لتحمير', 'لنقع',
    'لتغطيه', 'لتتبيل', 'لصوص', 'لصلصه', 'لعجن', 'لشربات', 'حسب', 'عند', 'اختياري',
    'اختياريه', 'بالعظم', 'بدون', 'دون', 'المقدار', 'المصدر', 'يذكر', 'مكون', 'لكل',
    'بحجم', 'بدرجه', 'بطول', 'بعرض', 'العدد', 'مع', 'يفضل', 'ويفضل', 'مثل', 'بكميه',
    'في', 'الجزء', 'الاجزاء', 'بالجزاين', 'لا', 'ثم', 'منزوع', 'منزوعه', 'ومنزوع',
    'ومنزوعه', 'والجلد', 'بمكبس', 'بالابعاد', 'يقسم', 'منزوعا', 'سريعا',
  ].map(normKey),
);

const descriptorWords = new Set(
  [
    'مفروم', 'مفرومه', 'مقطع', 'مقطعه', 'مبشور', 'مبشوره', 'مهروس', 'مهروسه', 'طازج',
    'طازجه', 'ناعم', 'ناعمه', 'ناعما', 'خشن', 'خشنه', 'خشنا', 'مكعبات', 'شرائح', 'شريحه',
    'حلقات', 'رقيقه', 'رقيق', 'رفيعه', 'سميكه', 'صغيره', 'صغير', 'صغار', 'كبير', 'كبيره',
    'كبار', 'متوسط', 'متوسطه', 'وسط', 'ناضج', 'ناضجه', 'مغسول', 'مغسوله', 'مصفي',
    'مصفاه', 'مسلوق', 'مسلوقه', 'منقوع', 'منقوعه', 'مذاب', 'مذابه', 'بارد', 'بارده',
    'دافئ', 'دافيء', 'فاتر', 'ساخن', 'ساخنه', 'مقشر', 'مقشره', 'محمص', 'محمصه', 'جدا',
    'قطع', 'مربعات', 'كامل', 'كامله', 'نيء', 'ني', 'جامد', 'جامده', 'طري', 'طريه',
    'مجروش', 'مجروشه', 'مقلي', 'مقليه', 'مشوي', 'مشويه', 'ممزق', 'باليد', 'الي', 'او',
    'معصور', 'معصوره', 'منظف', 'منظفه', 'طازجا', 'مخفوق', 'مخفوقه', 'جيدا', 'قليلا',
    'مفرومان', 'مقطعتان', 'منخول', 'مفتت', 'مفتته', 'مقشور', 'مقشوره',
    'بوصه', 'بوصات', 'بوصتين', 'بوصتان', 'سم', 'ارباعا', 'نصفين', 'مقسوم', 'مقسومه',
    'شرائط', 'قطعا', 'دوائر', 'طوليه', 'طوليا', 'مائله', 'مائل', 'قطريا', 'مبروش',
    'مبروشه', 'عضوي', 'عضويه', 'مكعبه',
    'مجمد', 'مجمده', 'مذابه', 'مملح', 'مملحه', 'غير', 'ممتلئ', 'نحو',
    'حوالي', 'الطازج', 'الطازجه', 'بجلده', 'بجلدها', 'بالجلد', 'رفيع', 'رفيعه',
    'انصاف', 'مقطعه', 'مقطوع', 'مقطوعه',
    'مصفاه', 'مسلوقه', 'مشرح', 'مشرحه', 'مخلي', 'مخليه',
    'متساويه', 'متوسطتان', 'متوسطتين', 'كبيرتين', 'صغيرتين', 'صغيرات',
    'مكعبات', 'شرائح', 'جيده', 'جيد', 'النوعيه', 'عاليه', 'الجوده', 'مفرومتان',
    'مفرومتين', 'مبشورتان', 'مخفوقتان', 'مهروسان', 'متماسك', 'متماسكه', 'مضغوط',
    'خفيف', 'خفيفه', 'بخفه', 'زهيرات', 'عيدان', 'عيدانا', 'ساده', 'مفروك', 'مفروكه',
    'مقسمه', 'مقطعان', 'ورقي', 'عاديه', 'عادي', 'نيئ', 'نيئه', 'شمعيه', 'شمعي',
    'دافئه', 'مفضل', 'اطوال', 'مسخن', 'مبشوران',
  ].map(normKey),
);
const descriptorPhrases = [
  'كامل الدسم', 'كامله الدسم', 'قليل الدسم', 'قليله الدسم', 'منزوع العظم', 'منزوعه العظم',
  'منزوع الجلد', 'منزوعه الجلد', 'خالي الدسم', 'خاليه الدسم', 'منزوع البذور', 'منزوعه البذور', 'بدون جلد',
  'بدون عظم', 'درجه حراره الغرفه',
].map(normKey);
const groundWords = new Set(['مطحون', 'مطحونه'].map(normKey));
const stateWords = new Set(
  ['طازج', 'طازجه', 'طازجا', 'مطحون', 'مطحونه', 'مفروم', 'مفرومه'].map(normKey),
);
// A bunch or sprigs of something is the fresh herb ("حزمة كزبرة").
const freshLead = /^(?:حزمه|باقه|ربطه|اغصان|غصن|عرق|عروق|اوراق) /;

// Amount words that never change which product a line names, wherever they sit.
const amountWords = new Set(
  [
    'جم', 'جرام', 'غرام', 'كجم', 'مل', 'ملعقه', 'ملاعق', 'ملعقتان', 'ملعقتين', 'كبيرتان',
    'صغيرتان', 'كوب', 'اكواب', 'كوبان', 'واحد', 'واحده', 'نصف', 'ربع', 'ثلث', 'ونصف',
    'رشه', 'رطل', 'رطلان', 'ارطال', 'لتر', 'اونصه', 'اونصات', 'اضافي', 'اضافيه', '⁄',
    'ورقتان', 'تقريبا', 'فقط',
    'اثنان', 'اثنين', 'ثلاث', 'ثلاثه', 'اربع', 'اربعه', 'خمس', 'خمسه', 'ست', 'سته',
    'سبع', 'ثماني', 'عشر', 'حبتا', 'حبتان', 'حبتين', 'حبه', 'حبات', 'كميه', 'مقدار',
    'ثمن', 'اقل', 'اكثر', 'حزمه', 'ربطه', 'باقه', 'حفنه', 'اوتاد', 'اغصان', 'عرق',
    'عروق', 'قرون', 'كاس', 'ديسيلتر', 'سنتيلتر',
  ].map(normKey),
);

function stripPunctuation(name) {
  return normKey(name)
    .replace(/\([^)]*\)|\[[^\]]*\]/g, ' ')
    .replace(/[0-9٠-٩۰-۹¼½¾⅓⅔⅛.,،:;؛\/\-–—%"'!?؟*+⁄]/g, ' ')
    .replace(/[()[\]]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function cutPurpose(s) {
  const words = s.split(' ');
  const cut = words.findIndex(
    (w, i) => i > 0 && (purposeWords.has(w) || (w.startsWith('لل') && w.length > 3)),
  );
  return (cut > 0 ? words.slice(0, cut) : words).join(' ').trim();
}

function lightClean(name) {
  let s = stripPunctuation(name);
  for (let i = 0; i < 3; i++) s = s.replace(quantityLead, '').trim();
  return dropWords(cutPurpose(s), amountWords);
}

function dropWords(s, set) {
  return s
    .split(' ')
    .filter((w) => !(set.has(w) || (w.length > 2 && w.startsWith('و') && set.has(w.slice(1)))))
    .join(' ')
    .trim();
}

/**
 * Cleaning stages, most literal first. The last stage strips "مطحون" and is
 * only accepted for spice entries (see [matchName]).
 */
export function cleanStages(name) {
  const literal = cutPurpose(stripPunctuation(name));
  const light = lightClean(name);
  let desc = ` ${light} `;
  for (const p of descriptorPhrases) desc = desc.split(` ${p} `).join(' ');
  desc = desc.replace(/\s+/g, ' ').trim();
  // "X أو Y" only collapses when every word after "أو" is a descriptor;
  // otherwise the line offers two different products and stays unmatched.
  const words = desc.split(' ');
  const or = words.indexOf('او');
  const options = or >= 0 ? desc.split(' او ').map((o) => dropWords(o, descriptorWords)) : [];
  const alternative = or >= 0 && options.slice(1).some((o) => o !== '');
  desc = alternative ? '' : dropWords(desc, descriptorWords);
  // The product name plus one stated form at a time ("كزبره طازجه").
  const said = alternative ? [] : light.split(' ').filter((w) => stateWords.has(w));
  const forms = new Set(said.map((w) => w.replace(/(?:ا|ه)?$/, 'ه')));
  const states = desc ? [...forms].map((w) => `${desc} ${w}`) : [];
  if (or >= 0 && !alternative && !desc) desc = options[0];
  const ground = desc && dropWords(desc, groundWords);
  // A leading "علبة" marks a canned product ("علبة طماطم مقشرة").
  const canned = /^(?:علبه|علب|علبتا|علبتان) /.test(literal);
  const fresh = freshLead.test(literal);
  return {literal, light, states, desc, ground, canned, fresh, options: alternative ? options : []};
}

/**
 * Units a person keeps an ingredient in at home: canonical units plus the
 * Arabic container/piece words. Recipe measures (cup, spoon) never apply.
 */
export const stockUnitValues = Object.freeze([
  'g', 'kg', 'ml', 'l', 'count',
  'ربطة', 'علبة', 'كيس', 'زجاجة', 'برطمان', 'عبوة', 'رغيف', 'فص', 'رأس', 'قرن', 'عود',
  'ورقة', 'كرتونة', 'باكو',
]);
const stockUnitSet = new Set(stockUnitValues);

function validateStockUnits(e) {
  const units = e.stockUnits;
  need(Array.isArray(units) && units.length > 0, `${e.id}: stockUnits must be a non-empty list`);
  for (const u of units) need(stockUnitSet.has(u), `${e.id}: bad stock unit ${u}`);
  need(new Set(units).size === units.length, `${e.id}: duplicate stock unit`);
  need(e.defaultUnit === units[0], `${e.id}: defaultUnit must equal stockUnits[0]`);
  const counted = units.includes('count');
  for (const k of ['pieceName', 'piecePlural']) {
    if (counted) need(typeof e[k] === 'string' && e[k].trim(), `${e.id}: count needs ${k}`);
    else need(e[k] === undefined, `${e.id}: ${k} without count`);
  }
}

export function validateVocabulary(vocabulary) {
  need(Array.isArray(vocabulary) && vocabulary.length > 0, 'Vocabulary must be a non-empty array');
  const ids = new Set();
  const keys = new Map();
  for (const e of vocabulary) {
    need(typeof e.id === 'string' && /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(e.id), `Bad id ${e.id}`);
    need(!ids.has(e.id), `Duplicate id ${e.id}`);
    ids.add(e.id);
    for (const k of ['name', 'category', 'defaultUnit']) {
      need(typeof e[k] === 'string' && e[k].trim(), `${e.id}: missing ${k}`);
    }
    need(zones.has(e.zone), `${e.id}: bad zone ${e.zone}`);
    validateStockUnits(e);
    need(Array.isArray(e.aliases), `${e.id}: aliases must be a list`);
    need(e.matchAliases === undefined || Array.isArray(e.matchAliases), `${e.id}: bad matchAliases`);
    need(
      e.matchExcludeCuisines === undefined || (e.matchAliases && Array.isArray(e.matchExcludeCuisines)),
      `${e.id}: matchExcludeCuisines needs matchAliases`,
    );
    for (const term of [e.name, ...e.aliases, ...(e.matchAliases ?? [])]) {
      const key = normKey(term);
      need(key, `${e.id}: empty alias`);
      const owner = keys.get(key);
      need(!owner || owner === e.id, `Alias "${term}" shared by ${owner} and ${e.id}`);
      keys.set(key, e.id);
    }
  }
  return keys;
}

/** Category whose entries are the ground form, so "مطحون" may be dropped. */
export const groundCategory = 'توابل';

/** Leading "ال" on a one-word name ("السكر"). */
function withoutArticle(stage) {
  return stage && !stage.includes(' ') && stage.startsWith('ال') && stage.length > 4
    ? stage.slice(2)
    : '';
}

/**
 * [blocked] holds catalog-only alias keys that must not apply to this line
 * (a regional word whose meaning differs in the line's cuisine).
 */
export function matchName(name, keys, categories, blocked = new Set()) {
  const {literal, light, states, desc, ground, canned, fresh, options} = cleanStages(name);
  const get = (k) => (k && !blocked.has(k) ? keys.get(k) : undefined);
  for (const stage of [literal, light, ...states, desc, withoutArticle(desc)]) {
    const id =
      stage &&
      ((canned && get(`${stage} معلبه`)) || (fresh && get(`${stage} طازجه`)) || get(stage));
    if (id) return id;
  }
  if (options.length > 1) {
    // Every option must resolve, and all to one entry.
    const ids = new Set(options.map((o) => matchName(o, keys, categories, blocked)));
    return ids.size === 1 && !ids.has(null) ? [...ids][0] : null;
  }
  const id = ground && ground !== desc ? get(ground) : undefined;
  return id && categories.get(id) === groundCategory ? id : null;
}

/**
 * "A أو B" naming different products: every option's entry, in the line's
 * order, when each one resolves and there are at least two. The first is the
 * default stock identity; cooking may use any of them.
 */
export function alternativesFor(name, keys, categories, blocked = new Set()) {
  const {options} = cleanStages(name);
  if (options.length < 2) return null;
  const ids = options.map((o) => matchName(o, keys, categories, blocked));
  if (ids.includes(null)) return null;
  const unique = [...new Set(ids)];
  return unique.length > 1 ? unique : null;
}

/** Alias key → cuisines where that catalog-only alias must not match. */
export function cuisineBlocks(vocabulary) {
  const blocks = new Map();
  for (const e of vocabulary) {
    for (const term of e.matchAliases ?? []) {
      blocks.set(normKey(term), new Set(e.matchExcludeCuisines ?? []));
    }
  }
  return blocks;
}

export async function loadActiveLines(read) {
  const index = JSON.parse(await read(indexFile));
  const active = index.recipes.filter((r) => r.catalogStatus === 'active');
  const ids = new Set(active.map((r) => r.id));
  const files = [...new Set(active.map((r) => r.file))].sort();
  const lines = [];
  for (const file of files) {
    const data = JSON.parse(await read(`recipes/data/${file}`));
    for (const recipe of data.recipes) {
      if (!ids.has(recipe.id)) continue;
      for (const i of recipe.ingredients ?? []) {
        need(typeof i.id === 'string' && typeof i.name === 'string', `Bad line in ${recipe.id}`);
        lines.push({id: i.id, name: i.name, recipe: recipe.id, cuisine: recipe.cuisine ?? null});
      }
    }
  }
  return lines;
}

function sortKeys(value) {
  if (Array.isArray(value)) return value.map(sortKeys);
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.keys(value)
        .sort()
        .map((k) => [k, sortKeys(value[k])]),
    );
  }
  return value;
}

export function buildDirectory(vocabularyText, lines) {
  const vocabulary = JSON.parse(vocabularyText);
  const keys = validateVocabulary(vocabulary);
  const vocabIds = new Set(vocabulary.map((e) => e.id));
  const categories = new Map(vocabulary.map((e) => [e.id, e.category]));
  const blocks = cuisineBlocks(vocabulary);
  const blockedFor = (line) =>
    new Set([...blocks].filter(([, cuisines]) => cuisines.has(line.cuisine)).map(([k]) => k));
  const byRaw = new Map();
  for (const line of lines) {
    if (!byRaw.has(line.id)) byRaw.set(line.id, []);
    byRaw.get(line.id).push(line);
  }
  const idMap = {};
  const alternatives = {};
  const unmappedNames = new Map();
  for (const [rawId, rawLines] of byRaw) {
    if (vocabIds.has(rawId)) {
      idMap[rawId] = rawId;
      continue;
    }
    const targets = new Set(
      rawLines.map((l) => matchName(l.name, keys, categories, blockedFor(l))),
    );
    const choices = new Set(
      rawLines.map((l) =>
        JSON.stringify(alternativesFor(l.name, keys, categories, blockedFor(l))),
      ),
    );
    if (targets.size === 1 && !targets.has(null)) {
      idMap[rawId] = [...targets][0];
    } else if (choices.size === 1 && !choices.has('null')) {
      const ids = JSON.parse([...choices][0]);
      idMap[rawId] = ids[0];
      alternatives[rawId] = ids;
    } else {
      for (const l of rawLines) {
        const key = cleanStages(l.name).ground;
        unmappedNames.set(key, (unmappedNames.get(key) ?? 0) + 1);
      }
    }
  }
  const mappedLines = lines.filter((l) => l.id in idMap).length;
  const directory = sortKeys({
    version: 1,
    vocabularySha256: sha256(vocabularyText),
    idMap,
    alternatives,
    unmapped: byRaw.size - Object.keys(idMap).length,
    stats: {
      lines: lines.length,
      mappedLines,
      rawIds: byRaw.size,
      mappedRawIds: Object.keys(idMap).length,
      alternativeRawIds: Object.keys(alternatives).length,
    },
  });
  return {directory, unmappedNames, vocabularySize: vocabulary.length};
}

export async function run({check = false, base = root, showUnmapped = 0} = {}) {
  const read = (file) => readFile(resolve(base, file), 'utf8');
  const vocabularyText = await read(vocabularyFile);
  const lines = await loadActiveLines(read);
  const {directory, unmappedNames, vocabularySize} = buildDirectory(vocabularyText, lines);
  const text = JSON.stringify(directory, null, 2) + '\n';
  const path = resolve(base, directoryFile);
  if (check) {
    need((await read(directoryFile)).replace(/\r\n/g, '\n') === text, `Stale ${directoryFile}`);
  } else {
    await mkdir(dirname(path), {recursive: true});
    await writeFile(path, text, 'utf8');
  }
  const s = directory.stats;
  const pct = (a, b) => ((100 * a) / b).toFixed(1) + '%';
  console.log(`vocabulary: ${vocabularySize} entries`);
  console.log(`lines mapped: ${s.mappedLines}/${s.lines} (${pct(s.mappedLines, s.lines)})`);
  console.log(`raw ids mapped: ${s.mappedRawIds}/${s.rawIds} (${pct(s.mappedRawIds, s.rawIds)})`);
  if (showUnmapped > 0) {
    const top = [...unmappedNames].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
    for (const [name, n] of top.slice(0, showUnmapped)) console.log(`  ${n}\t${name}`);
  }
  return directory;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const arg = process.argv.find((a) => a.startsWith('--unmapped='));
  await run({
    check: process.argv.includes('--check'),
    showUnmapped: arg ? Number(arg.split('=')[1]) : 0,
  });
}
