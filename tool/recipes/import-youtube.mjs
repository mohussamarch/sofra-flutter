#!/usr/bin/env node
// Imports the YouTube creator candidates (data/recipes/candidates-youtube-*)
// into the ONLINE library only: recipes/library-only/, which
// tool/recipes/publish-library.mjs merges into sofra-library.web.app. Nothing
// here is bundled in the app: recipes/data (the app's offline seed) is not
// touched.
//
// Every candidate ends in exactly one of three places, decided by the audit
// of 21 November 2026 (recipes/library-only/youtube-plan.json) and by the
// checks below:
//   active  recipes/library-only/youtube.json       published
//   held    recipes/library-only/youtube-held.json  the review queue, as the
//           candidate was, with the reasons; not published
//   dropped listed with the reason in the import report only
//
// The fixes applied to active recipes never invent data:
//   - off-list categories map to the catalog's categories, or to a few new
//     ones (CATEGORY);
//   - unit spellings merge (UNIT); other units stay as the source wrote them
//     ("ملعقة" with no size stays "ملعقة");
//   - a counted line with no unit gets the unit its name says (بيض -> حبة);
//   - an empty amount becomes unmeasured ("حسب الرغبة", no scaling);
//   - videoStartSec that runs backwards or past the video becomes null;
//   - cuisine is the one the candidate states (catalog spelling); a missing
//     or vague one ("عالمي", "شرقي") holds the recipe for cuisine review:
//     cuisine is never inferred from the name, the creator or the language;
//   - an id used twice gets the video id as a suffix; a name that the
//     catalog or another creator already uses gets «على طريقة <creator>»;
//   - a missing source is the video itself;
//   - ingredient ids come from the ingredient vocabulary when the name
//     matches; otherwise a stable id derived from the name (unmatched-…).
// Servings stay null unless the source states people ("4 أفراد"): the
// servings engine computes them at publish time. A recipe it cannot compute
// with at least medium confidence is held (the import-candidates rule).
//
// Usage:
//   node tool/recipes/import-youtube.mjs [candidatesBase] [channels.tsv]
// candidatesBase defaults to data/recipes (folders candidates-youtube-*).
import {createHash} from 'node:crypto';
import {existsSync, readFileSync, readdirSync, statSync, writeFileSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {normalize} from './import-candidates.mjs';
import {defaultEngine} from './servings-engine.mjs';
import {review} from './hold-content.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url));
export const libraryDir = path.join(root, 'recipes', 'library-only');

/** Off-list source categories -> catalog category. */
export const CATEGORY = {
  'سلطات': 'سلطة', 'سلطات ومقبلات': 'سلطة',
  'مقبلات ومشهيات': 'مقبلات', 'سناكس': 'مقبلات', 'سناك': 'مقبلات', 'تسالي': 'مقبلات',
  'بسكويت': 'حلويات', 'بسكويت وكحك': 'حلويات',
  'معجنات': 'مخبوزات', 'عجائن': 'مخبوزات', 'خبز': 'مخبوزات',
  'فطور': 'فطار', 'سحور': 'فطار',
  'لحوم': 'طبق رئيسي', 'مشويات': 'طبق رئيسي', 'مكرونة': 'طبق رئيسي',
  'مشروب': 'مشروبات', 'مشروبات وإضافات': 'مشروبات',
  'صلصة': 'صوصات', 'صلصات': 'صوصات', 'صوص': 'صوصات',
  'مخللات وصلصات': 'مخللات', 'مؤونة': 'مخللات',
  'ساندويتش': 'ساندويتشات', 'ساندوتشات': 'ساندويتشات',
  'تحضيرات': 'أساسيات', 'توابل': 'أساسيات',
};
/** Categories the library adds to the catalog's seven. */
export const NEW_CATEGORIES = ['طبق جانبي', 'مشروبات', 'صوصات', 'مخللات', 'ساندويتشات', 'أساسيات'];

/** Spellings of one unit -> the catalog spelling. */
export const UNIT = {
  'مللي': 'مل', 'جم': 'جرام', 'غرام': 'جرام', 'حبات': 'حبة', 'فصوص': 'فص',
  'باكت': 'باكيت', 'باكو': 'باكيت', 'راس': 'رأس', 'قطع': 'قطعة', 'ملاعق': 'ملعقة',
};

/** The unit a counted line's own name gives, or null. */
export function unitFromName(name) {
  const n = name.trim();
  if (/^(بيض|بيضة|صفار|صفار بيض|بياض|بياض بيض)( |$)/.test(n)) return 'حبة';
  if (/^(ورق|ورقة) /.test(n)) return 'ورقة';
  if (/^عود /.test(n)) return 'عود';
  if (/^مكعب /.test(n)) return 'مكعب';
  if (/^(قرنفل|يانسون نجمي|ينسون نجمي)$/.test(n)) return 'حبة';
  return null;
}

/** Catalog cuisine spellings and words that name no single cuisine. */
const CUISINE_SPELLING = {'إنجليزي': 'بريطاني', 'عماني': 'عُماني'};
const VAGUE = new Set(['خليجي', 'شرقي', 'عالمي', 'شرق أوسطي', 'آسيوي', 'غير محدد', 'عالمي متنوع', 'أمريكي جنوبي']);

/** The cuisine the candidate states (catalog spelling), or null when it
 *  states none or a word that names no single cuisine. Never inferred from
 *  the dish name, the creator's country or the language. */
export function cuisineOf(c) {
  const stated = typeof c.cuisine === 'string' ? (CUISINE_SPELLING[c.cuisine.trim()] ?? c.cuisine.trim()) : '';
  return stated && !VAGUE.has(stated) ? stated : null;
}

/** People the source itself says the recipe serves ("4 أفراد", "يكفي
 *  شخصين"; a range keeps its lower bound), or null. Pieces, trays and
 *  sizes are not people and stay in sourceServings. */
export function servingsFromSource(text) {
  if (typeof text !== 'string') return null;
  const t = text.trim();
  if (/^(يكفي )?(فردين|شخصين|شخصان)$/.test(t)) return 2;
  const m = /^(?:يكفي |من )?(\d+)(?:\s*(?:-|إلى)\s*\d+)?\s*(أفراد|أشخاص|فرد|شخص)$/.exec(t);
  return m ? Number(m[1]) : null;
}

const normName = (s) =>
  s.normalize('NFKC').replace(/[ً-ْـ]/g, '').replace(/[أإآ]/g, 'ا').replace(/ة/g, 'ه').replace(/ى/g, 'ي')
    .replace(/[^\p{L}\p{N}\s]/gu, ' ').replace(/\s+/g, ' ').trim();

/** Ingredient ids from the vocabulary (name and aliases, then the longest
 *  leading words), then from other candidates, then a stable derived id. */
export function ingredientIds(vocabulary, candidates = []) {
  const exact = new Map();
  for (const v of vocabulary) {
    for (const n of [v.name, ...(v.aliases ?? [])]) if (!exact.has(normName(n))) exact.set(normName(n), v.id);
  }
  const seen = new Map();
  for (const c of candidates) {
    for (const i of c.ingredients ?? []) {
      if (typeof i.id === 'string' && i.id && typeof i.name === 'string') {
        const k = normName(i.name);
        const m = seen.get(k) ?? new Map();
        m.set(i.id, (m.get(i.id) ?? 0) + 1);
        seen.set(k, m);
      }
    }
  }
  return (name) => {
    const k = normName(name);
    if (exact.has(k)) return exact.get(k);
    const words = k.split(' ');
    for (let n = words.length - 1; n >= 1; n--) {
      const head = words.slice(0, n).join(' ');
      if (exact.has(head)) return exact.get(head);
    }
    const m = seen.get(k);
    if (m) return [...m.entries()].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))[0][0];
    return `unmatched-${createHash('sha1').update(k).digest('hex').slice(0, 10)}`;
  };
}

/** Steps' videoStartSec, nulling a time that runs backwards or past the end. */
export function orderedStarts(steps, durationSec) {
  let last = -1;
  return steps.map((s) => {
    const t = s.videoStartSec;
    if (!Number.isInteger(t) || t < 0 || t < last || (Number.isInteger(durationSec) && t > durationSec)) {
      return {...s, videoStartSec: null};
    }
    last = t;
    return s;
  });
}

/** Repairs one candidate before normalize(); returns the copy. */
export function prepare(c, {idOf, creatorName}) {
  const r = structuredClone(c);
  r.category = CATEGORY[r.category?.trim()] ?? r.category;
  if (!r.source?.url && r.video?.url) {
    r.source = {url: r.video.url, site: creatorName, author: creatorName};
  }
  r.ingredients = (r.ingredients ?? []).map((i) => {
    const line = {...i};
    if (line.amount === '') {
      line.amount = null;
      line.unit = null;
    }
    if (typeof line.unit === 'string') line.unit = UNIT[line.unit.trim()] ?? line.unit.trim();
    const measured = typeof line.amount === 'number' && line.amount > 0;
    if (measured && !(typeof line.unit === 'string' && line.unit)) line.unit = unitFromName(line.name ?? '');
    if (!measured) {
      line.amount = null;
      line.unit = null;
    }
    if (!(typeof line.id === 'string' && line.id.trim()) && typeof line.name === 'string') line.id = idOf(line.name);
    return line;
  });
  r.steps = orderedStarts(r.steps ?? [], r.video?.durationSec);
  return r;
}

/** Candidate-specific fixes from the audit. */
const FIXES = {
  // Pepperoni is optional in the source ("اختياري" in its own note).
  'it-omar-spontini-pizza-yt': (r) => {
    for (const i of r.ingredients) if (/ببروني|بيبروني/.test(i.name)) i.optional = true;
  },
};

/** Every candidate of every creator folder: {tag, folder, file, recipe}. */
export function loadCandidates(base) {
  const out = [];
  for (const d of readdirSync(base).filter((d) => d.startsWith('candidates-youtube-')).sort()) {
    const dir = path.join(base, d);
    if (!statSync(dir).isDirectory()) continue;
    for (const f of readdirSync(dir).filter((f) => f.endsWith('.json') && f !== 'creators.json').sort()) {
      const json = JSON.parse(readFileSync(path.join(dir, f), 'utf8'));
      const rows = Array.isArray(json) ? json : (json.recipes ?? []);
      const folder = d.replace('candidates-youtube-', '');
      for (const recipe of rows) out.push({tag: `${folder}/${f}:${recipe.id}`, folder, file: f, recipe});
    }
  }
  return out;
}

/** Creators: channels.tsv rows (+ creators.json files) of creators with candidates. */
export function buildCreators(channelsTsv, extra, candidates, asOf) {
  const rows = channelsTsv.trim().split(/\r?\n/).slice(1).map((l) => l.split('\t'));
  const byId = new Map();
  for (const [slug, channelId, name, country, followers] of rows) {
    byId.set(`yt:${channelId}`, {slug, channelId, name, country, followers: Number(followers)});
  }
  for (const c of extra) {
    const known = byId.get(c.creatorId) ?? {};
    byId.set(c.creatorId, {...known, channelId: c.channelId, name: known.name ?? c.name, country: known.country ?? c.country});
  }
  const enName = new Map();
  for (const {recipe} of candidates) {
    const m = /\(([A-Za-z][^)]*)\)\s*$/.exec(recipe.source?.site ?? '');
    if (m && recipe.creatorId && !enName.has(recipe.creatorId)) enName.set(recipe.creatorId, m[1].trim());
  }
  const used = [...new Set(candidates.map((c) => c.recipe.creatorId))].sort();
  return used.map((creatorId) => {
    const c = byId.get(creatorId);
    if (!c) throw new Error(`no channel row for ${creatorId}`);
    return {
      creatorId,
      slug: c.slug ?? null,
      name: {ar: c.name, en: enName.get(creatorId) ?? null},
      platform: 'youtube',
      channelId: c.channelId,
      channelUrl: `https://www.youtube.com/channel/${c.channelId}`,
      country: c.country ?? null,
      followers: Number.isFinite(c.followers) ? {count: c.followers, asOf} : null,
      avatarUrl: null,
      verifiedAt: null,
    };
  });
}

/**
 * Sorts candidates into active / held / dropped. Pure: returns
 * {active, held, dropped} (active are normalized library recipes).
 * [catalog] is recipes/data/index.json (ids and names already taken).
 */
export function sortCandidates(candidates, plan, {catalog, creators, vocabulary, engine = defaultEngine()}) {
  const idOf = ingredientIds(vocabulary, candidates.map((c) => c.recipe));
  const creatorName = new Map(creators.map((c) => [c.creatorId, c.name.ar]));
  const cuisines = new Map(catalog.cuisines.map((c) => [c.name, c.file]));
  const held = [];
  const dropped = [];
  const ready = [];
  const seenTags = new Set();
  const audited = new Set([...plan.active, ...Object.keys(plan.hold), ...Object.keys(plan.drop)]);
  const notAudited = [];
  for (const x of candidates) {
    if (seenTags.has(x.tag)) throw new Error(`candidate listed twice: ${x.tag}`);
    seenTags.add(x.tag);
    // Batches converted after the audit wait for the next audit.
    if (!audited.has(x.tag)) {
      notAudited.push(x.tag);
      continue;
    }
    if (plan.drop[x.tag]) {
      dropped.push({tag: x.tag, id: x.recipe.id, name: x.recipe.name, reasons: plan.drop[x.tag]});
      continue;
    }
    const reasons = [...(plan.hold[x.tag] ?? [])];
    const hold = (why) => reasons.push(why);
    if (!x.recipe.creatorId) hold('no creatorId');
    const fixed = prepare(x.recipe, {idOf, creatorName: creatorName.get(x.recipe.creatorId)});
    FIXES[fixed.id]?.(fixed);
    if (review(fixed).length) {
      dropped.push({tag: x.tag, id: x.recipe.id, name: x.recipe.name, reasons: ['pork or alcohol required']});
      continue;
    }
    const cuisine = cuisineOf(fixed);
    if (!cuisine) hold('cuisine not stated');
    else if (!cuisines.has(cuisine)) hold(`cuisine ${cuisine} has no catalog file`);
    else fixed.cuisine = cuisine;
    for (const i of fixed.ingredients) {
      if (typeof i.amount === 'number' && i.amount > 0 && !i.unit) hold(`no unit for ${i.name}`);
    }
    let recipe = null;
    if (!reasons.length) {
      try {
        const stated = Number.isInteger(fixed.servings) && fixed.servings > 0 ? fixed.servings : servingsFromSource(fixed.sourceServings);
        recipe = normalize({...fixed, servings: stated});
      } catch (e) {
        hold(/servings/.test(e.message) ? 'servings not computable' : e.message);
      }
    }
    if (reasons.length) {
      held.push({tag: x.tag, reasons: [...new Set(reasons)], candidate: x.recipe});
      continue;
    }
    ready.push({tag: x.tag, recipe, videoId: x.recipe.video.id});
  }
  // Ids: one id per recipe across the catalog and the library.
  const taken = new Set(catalog.recipes.map((r) => r.id));
  const count = new Map();
  for (const {recipe} of ready) count.set(recipe.id, (count.get(recipe.id) ?? 0) + 1);
  for (const r of ready) {
    if (count.get(r.recipe.id) > 1 || taken.has(r.recipe.id)) {
      r.recipe.id = `${r.recipe.id}-${r.videoId.toLowerCase().replace(/[^a-z0-9]/g, '')}`;
    }
    if (taken.has(r.recipe.id)) throw new Error(`id still taken: ${r.recipe.id}`);
    taken.add(r.recipe.id);
  }
  // Names: a name the catalog or another library recipe uses gets the creator.
  const catalogNames = new Set(catalog.recipes.map((r) => r.name.trim()));
  const nameCount = new Map();
  for (const {recipe} of ready) nameCount.set(recipe.name, (nameCount.get(recipe.name) ?? 0) + 1);
  for (const r of ready) {
    if (catalogNames.has(r.recipe.name) || nameCount.get(r.recipe.name) > 1) {
      r.recipe.originalName = r.recipe.name;
      r.recipe.name = `${r.recipe.name} على طريقة ${creatorName.get(r.recipe.creatorId)}`;
    }
  }
  const names = new Set(catalogNames);
  const active = [];
  for (const r of ready) {
    if (names.has(r.recipe.name)) {
      held.push({tag: r.tag, reasons: ['same name as another recipe of the same creator'], candidate: candidates.find((c) => c.tag === r.tag).recipe});
      continue;
    }
    names.add(r.recipe.name);
    const verdict = engine.compute(r.recipe);
    if (r.recipe.servings == null && verdict.servingsConfidence !== 'high' && verdict.servingsConfidence !== 'medium') {
      held.push({tag: r.tag, reasons: ['servings not computable'], candidate: candidates.find((c) => c.tag === r.tag).recipe});
      continue;
    }
    active.push({...r.recipe, importTag: r.tag});
  }
  return {active, held, dropped, notAudited};
}

function main() {
  const base = path.resolve(process.argv[2] ?? path.join(root, 'data', 'recipes'));
  const tsvPath = path.resolve(process.argv[3] ?? path.join(root, '..', 'research', 'youtube-raw', 'channels.tsv'));
  const plan = JSON.parse(readFileSync(path.join(libraryDir, 'youtube-plan.json'), 'utf8'));
  const catalog = JSON.parse(readFileSync(path.join(root, 'recipes', 'data', 'index.json'), 'utf8'));
  const vocabulary = JSON.parse(readFileSync(path.join(root, 'data', 'ingredients', 'vocabulary.json'), 'utf8'));
  const candidates = loadCandidates(base);
  const extra = [];
  for (const d of readdirSync(base).filter((d) => d.startsWith('candidates-youtube-'))) {
    const f = path.join(base, d, 'creators.json');
    if (existsSync(f)) extra.push(...JSON.parse(readFileSync(f, 'utf8')));
  }
  const asOf = statSync(tsvPath).mtime.toISOString().slice(0, 10);
  const creators = buildCreators(readFileSync(tsvPath, 'utf8'), extra, candidates, asOf);
  const {active, held, dropped, notAudited} = sortCandidates(candidates, plan, {catalog, creators, vocabulary});
  const write = (name, data) => writeFileSync(path.join(libraryDir, name), `${JSON.stringify(data, null, 1)}\n`);
  write('creators.json', {version: 1, creators});
  write('youtube.json', {version: 1, importedAt: '2026-11-21', recipes: active});
  // One held candidate per line: the review queue stays small and diffable.
  writeFileSync(
    path.join(libraryDir, 'youtube-held.json'),
    `{"version":1,"importedAt":"2026-11-21","recipes":[\n${held.map((h) => JSON.stringify(h)).join(',\n')}\n]}\n`,
  );
  write('youtube-report.json', {
    importedAt: '2026-11-21',
    candidates: candidates.length - notAudited.length,
    notAuditedYet: notAudited.length,
    active: active.length,
    held: held.length,
    dropped: dropped.length,
    droppedRecipes: dropped,
    heldReasons: Object.fromEntries(
      Object.entries(held.reduce((m, h) => {
        for (const r of h.reasons) m[r.replace(/ for .*/, ' for <line>')] = (m[r.replace(/ for .*/, ' for <line>')] ?? 0) + 1;
        return m;
      }, {})).sort((a, b) => b[1] - a[1]),
    ),
  });
  console.log(`audited ${candidates.length - notAudited.length} (+${notAudited.length} not audited yet): active ${active.length}, held ${held.length}, dropped ${dropped.length}`);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
