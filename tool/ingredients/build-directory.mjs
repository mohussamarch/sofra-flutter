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
      'شريحه', 'شرائح', 'نصف', 'ربع', 'قليل من', 'بعض',
    ].join('|') +
    ')(?: |$)',
);

// Purpose clauses are cut from their first word to the end of the name.
const purposeWords = new Set(
  [
    'لسلق', 'لدهن', 'لفرك', 'لخلطه', 'لتمويج', 'لرش', 'لعجينه', 'لماء', 'لخفق',
    'لتذويب', 'لحشو', 'لتزيين', 'لتقديم', 'لقلي', 'لطهي', 'لعمل', 'لتحمير', 'لنقع',
    'لتغطيه', 'لتتبيل', 'لصوص', 'لصلصه', 'لعجن', 'لشربات', 'حسب', 'عند', 'اختياري',
    'اختياريه', 'بالعظم', 'بدون', 'دون', 'المقدار',
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
  ].map(normKey),
);
const descriptorPhrases = [
  'كامل الدسم', 'كامله الدسم', 'قليل الدسم', 'قليله الدسم', 'منزوع العظم', 'منزوعه العظم',
  'منزوع الجلد', 'منزوعه الجلد', 'منزوع البذور', 'منزوعه البذور', 'بدون جلد',
  'بدون عظم', 'درجه حراره الغرفه',
].map(normKey);
const groundWords = new Set(['مطحون', 'مطحونه'].map(normKey));

// Amount words that never change which product a line names, wherever they sit.
const amountWords = new Set(
  [
    'جم', 'جرام', 'غرام', 'كجم', 'مل', 'ملعقه', 'ملاعق', 'ملعقتان', 'ملعقتين', 'كبيرتان',
    'صغيرتان', 'كوب', 'اكواب', 'كوبان', 'واحد', 'واحده', 'نصف', 'ربع', 'ثلث', 'ونصف',
    'رشه', 'رطل', 'رطلان', 'ارطال', 'لتر', 'اونصه', 'اونصات', 'اضافي', 'اضافيه', '⁄',
    'ورقتان', 'تقريبا', 'فقط',
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
  const alternative = or >= 0 && dropWords(words.slice(or + 1).join(' '), descriptorWords) !== '';
  desc = alternative ? '' : dropWords(desc, descriptorWords);
  const ground = desc && dropWords(desc, groundWords);
  // A leading "علبة" marks a canned product ("علبة طماطم مقشرة").
  const canned = /^(?:علبه|علب|علبتا|علبتان) /.test(literal);
  return {literal, light, desc, ground, canned};
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
    need(Array.isArray(e.aliases), `${e.id}: aliases must be a list`);
    for (const term of [e.name, ...e.aliases]) {
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

export function matchName(name, keys, categories) {
  const {literal, light, desc, ground, canned} = cleanStages(name);
  for (const stage of [literal, light, desc]) {
    const id = stage && ((canned && keys.get(`${stage} معلبه`)) || keys.get(stage));
    if (id) return id;
  }
  const id = ground && ground !== desc ? keys.get(ground) : undefined;
  return id && categories.get(id) === groundCategory ? id : null;
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
        lines.push({id: i.id, name: i.name, recipe: recipe.id});
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
  const byRaw = new Map();
  for (const line of lines) {
    if (!byRaw.has(line.id)) byRaw.set(line.id, []);
    byRaw.get(line.id).push(line);
  }
  const idMap = {};
  const unmappedNames = new Map();
  for (const [rawId, rawLines] of byRaw) {
    if (vocabIds.has(rawId)) {
      idMap[rawId] = rawId;
      continue;
    }
    const targets = new Set(rawLines.map((l) => matchName(l.name, keys, categories)));
    if (targets.size === 1 && !targets.has(null)) {
      idMap[rawId] = [...targets][0];
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
    unmapped: byRaw.size - Object.keys(idMap).length,
    stats: {
      lines: lines.length,
      mappedLines,
      rawIds: byRaw.size,
      mappedRawIds: Object.keys(idMap).length,
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
