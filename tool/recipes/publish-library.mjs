#!/usr/bin/env node
// Builds the online recipe library that the app downloads from Firebase
// Hosting (site target "library"), from the reviewed catalog in recipes/data
// (also the app's bundled offline seed) plus the library-only recipes in
// recipes/library-only (never bundled: creators' video recipes).
//
//   node tool/recipes/publish-library.mjs            # -> build/library/
//   node tool/recipes/publish-library.mjs --out DIR  # another folder
//   node tool/recipes/publish-library.mjs --library none  # recipes/data only
//   firebase deploy --only hosting:library --project sofra-c03a1
//
// Output (deterministic for the same recipes/data):
//   manifest.json   {schema, version, generatedAt, recipeCount, files, bodies}
//                   served no-cache; the app checks it at most every 6 hours.
//                   files: {"index.json"|"dishes.json"|"creators.json":
//                   {sha256, size}};
//                   bodies: {count, size}; each body is checked by its row.
//   index.json      the catalog: every row of recipes/data/index.json plus
//                   `body` (sha256 of its body file) and, for active rows,
//                   `ingredients` (id, name, amount, unit, scale, optional) so
//                   listing, search and stock matching need no body; and
//                   optional image references `thumbnail` and `photos[]`
//                   (URLs or img/ paths, never image bytes).
//                   Library-only rows also carry `creatorId` and `video`
//                   ({id, publishedAt, views}) so a creator's recipes list
//                   and sort without bodies.
//   dishes.json     dish groups: recipes/library-only/dishes.json when the
//                   library has one (the catalog's dishes plus the library's),
//                   else recipes/data/dishes.json.
//   creators.json   the creators (recipes/library-only/creators.json).
//   r/<sha256>.json one recipe body each, content addressed (cached forever).
//
// Every row and body also carries the servings engine's verdict
// (tool/recipes/servings-engine.mjs): servingsComputed, servingsRange,
// servingsBasis and servingsConfidence. `servings` stays the source value.
//
// generatedAt only changes when the content changes: an unchanged library
// keeps the timestamp of the previous build in the output folder. Pass
// --generated-at ISO or SOURCE_DATE_EPOCH to pin it.
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { defaultEngine, servingsFields } from './servings-engine.mjs';

export const SCHEMA = 1;
const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..', '..');

export const sha256 = (text) =>
  createHash('sha256').update(Buffer.from(text, 'utf8')).digest('hex');

const ID = /^[A-Za-z0-9_.-]{1,120}$/;
const FILE = /^[a-z]+\.json$/;

/// Only what listing, search and stock matching read.
export function compactIngredient(line) {
  const out = { id: line.id, name: line.name };
  out.amount = line.amount ?? null;
  out.unit = line.unit ?? null;
  if (line.scale === false) out.scale = false;
  if (line.optional === true) out.optional = true;
  return out;
}

/// An image reference: an https URL, or a path under img/ on the library
/// site (compressed WebP preferred; see docs/dev/RECIPE-LIBRARY-ONLINE.md).
export const IMAGE = /^(https:\/\/[^\s"]+|img\/[A-Za-z0-9_./-]+\.(webp|jpg|jpeg|png))$/;

/// The optional image fields of a catalog row: `thumbnail` (the card) and
/// `photos` (step photos, loaded only when the recipe is opened). Text only:
/// the index never embeds image bytes. A row's own fields win over the body's.
export function imageFields(row, recipe) {
  const out = {};
  const thumbnail = row.thumbnail ?? recipe.thumbnail;
  if (thumbnail != null) {
    if (typeof thumbnail !== 'string' || !IMAGE.test(thumbnail) || thumbnail.includes('..')) {
      throw new Error(`bad thumbnail for ${row.id}`);
    }
    out.thumbnail = thumbnail;
  }
  const photos = row.photos ?? recipe.photos;
  if (photos != null) {
    if (!Array.isArray(photos) || photos.some((p) => typeof p !== 'string' || !IMAGE.test(p) || p.includes('..'))) {
      throw new Error(`bad photos for ${row.id}`);
    }
    if (photos.length) out.photos = photos;
  }
  return out;
}

// The app's own catalog checks (lib/data/recipe_repository.dart _parseIndex
// and CatalogIngredient.fromJson). A library the app would reject is never
// published: phones would keep their old catalog without anyone noticing.
const VAGUE_CUISINES = new Set(['غير محدد', 'عالمي متنوع', 'آسيوي', 'أمريكي جنوبي']);
const concreteCuisine = (v) => typeof v === 'string' && v.trim() !== '' && !VAGUE_CUISINES.has(v);
const held = (r) =>
  r.catalogStatus === 'held-cuisine' || r.catalogStatus === 'held-content' || !concreteCuisine(r.cuisine);
const text = (v) => typeof v === 'string' && v.trim() !== '';

function checkIngredient(line, id) {
  const fail = (why) => {
    throw new Error(`app would reject ${id}: ingredient ${why}`);
  };
  if (!line || typeof line !== 'object') fail('is not an object');
  if (!text(line.id) || !text(line.name)) fail('needs id and name');
  const amount = line.amount;
  if (amount != null && !(typeof amount === 'number' && Number.isFinite(amount) && amount > 0)) {
    fail(`${line.id} has an invalid amount`);
  }
  if (amount != null && !text(line.unit)) fail(`${line.id} is measured without a unit`);
  if (line.unit != null && typeof line.unit !== 'string') fail(`${line.id} has an invalid unit`);
  if (amount == null && line.scale !== false) fail(`${line.id} is unmeasured but scales`);
}

/// Throws when the app would not use [index] (the published catalog).
export function validateCatalog(index) {
  const files = new Set(index.cuisines.map((c) => c.file));
  for (const row of index.recipes) {
    if (!files.has(row.file)) throw new Error(`app would reject ${row.id}: unknown file ${row.file}`);
    for (const line of row.ingredients ?? []) checkIngredient(line, row.id);
  }
  const groups = index.cuisineGroups;
  if (groups == null) return;
  if (!Array.isArray(groups) || groups.length !== 16 || groups.at(-1).id !== 'other' ||
      new Set(groups.map((g) => g.id)).size !== 16) {
    throw new Error('app would reject cuisineGroups: needs exactly 15 primary groups plus "other" last');
  }
  groups.slice(0, 15).forEach((g, i) => {
    if (g.kind !== 'primary' || g.order !== i + 1) {
      throw new Error(`app would reject cuisineGroups: ${g.id} must be primary with order ${i + 1}`);
    }
  });
  const members = new Set();
  for (const g of groups) {
    if (!text(g.id) || !text(g.name) || !Array.isArray(g.members)) {
      throw new Error(`app would reject cuisine group ${g.id}: id, name and members required`);
    }
    for (const m of g.members) {
      if (!concreteCuisine(m) || members.has(m)) {
        throw new Error(`app would reject cuisine group ${g.id}: member ${m} vague or in two groups`);
      }
      members.add(m);
    }
    const rows = index.recipes.filter((r) => !held(r) && r.cuisineGroup === g.id);
    if (g.count !== rows.length) {
      throw new Error(`app would reject cuisine group ${g.id}: count ${g.count} but ${rows.length} active recipes`);
    }
    const stray = rows.find((r) => !g.members.includes(r.cuisine));
    if (stray) throw new Error(`app would reject ${stray.id}: cuisine ${stray.cuisine} not in group ${g.id}`);
  }
  const ids = new Set(groups.map((g) => g.id));
  for (const r of index.recipes) {
    if (held(r) ? r.cuisineGroup != null : r.catalogStatus !== 'active' || !ids.has(r.cuisineGroup)) {
      throw new Error(
        `app would reject ${r.id}: ${held(r) ? 'held recipe has a cuisineGroup' : 'active recipe needs a known cuisineGroup'}`,
      );
    }
  }
}

/// The library-only recipe files in recipes/library-only (active recipes).
export const LIBRARY_FILES = ['youtube.json'];
export const defaultLibraryDir = path.join(root, 'recipes', 'library-only');

/// The catalog index row of a library-only recipe.
export function libraryRow(recipe, file, cuisineGroup) {
  const row = {
    id: recipe.id,
    name: recipe.name,
    nameEn: recipe.nameEn ?? null,
    cuisine: recipe.cuisine,
    category: recipe.category,
    servings: recipe.servings ?? null,
    totalTime: recipe.totalTime ?? null,
    difficulty: recipe.difficulty,
    tags: recipe.tags ?? [],
    ingredientCount: recipe.ingredients.length,
    stepCount: recipe.steps.length,
    file,
    catalogStatus: 'active',
    cuisineGroup,
  };
  if (recipe.creatorId) row.creatorId = recipe.creatorId;
  if (recipe.video) {
    row.video = { id: recipe.video.id, publishedAt: recipe.video.publishedAt ?? null, views: recipe.video.views ?? null };
  }
  return row;
}

/// recipes/data's index plus the library-only recipes: {index, bodies,
/// dishes, creators}. Every library recipe is active and needs a cuisine the
/// catalog's files and groups know and a known creator.
export function mergeLibrary(index, libraryDir) {
  const readLib = (name) => JSON.parse(fs.readFileSync(path.join(libraryDir, name), 'utf8'));
  const has = (name) => fs.existsSync(path.join(libraryDir, name));
  const creators = has('creators.json') ? readLib('creators.json') : null;
  const creatorIds = new Set((creators?.creators ?? []).map((c) => c.creatorId));
  const fileOf = new Map(index.cuisines.map((c) => [c.name, c.file]));
  const groupOf = new Map();
  for (const g of index.cuisineGroups ?? []) for (const m of g.members) groupOf.set(m, g.id);
  const rows = [];
  const bodies = [];
  const units = new Set(index.units ?? []);
  const categories = new Set(index.categories ?? []);
  for (const name of LIBRARY_FILES.filter(has)) {
    for (const { importTag, ...recipe } of readLib(name).recipes) {
      const file = fileOf.get(recipe.cuisine);
      const group = groupOf.get(recipe.cuisine);
      if (!file || !group) throw new Error(`library recipe ${recipe.id}: cuisine ${recipe.cuisine} has no file or group`);
      if (recipe.creatorId && !creatorIds.has(recipe.creatorId)) {
        throw new Error(`library recipe ${recipe.id}: unknown creator ${recipe.creatorId}`);
      }
      rows.push(libraryRow(recipe, file, group));
      bodies.push({ recipe, file });
      for (const line of recipe.ingredients) if (line.unit) units.add(line.unit);
      categories.add(recipe.category);
    }
  }
  const recipes = [...index.recipes, ...rows];
  const activeOf = (pick) => recipes.filter((r) => r.catalogStatus === 'active' && pick(r)).length;
  const merged = {
    ...index,
    categories: [...categories],
    units: [...units],
    cuisines: index.cuisines.map((c) => ({ ...c, count: activeOf((r) => r.file === c.file) })),
    recipes,
  };
  if (index.cuisineGroups) {
    merged.cuisineGroups = index.cuisineGroups.map((g) => ({ ...g, count: activeOf((r) => r.cuisineGroup === g.id) }));
  }
  return {
    index: merged,
    bodies,
    dishes: has('dishes.json') ? readLib('dishes.json') : null,
    creators,
  };
}

/// Builds every published file in memory: {relativePath: text}. With
/// [libraryDir], the library-only recipes join recipes/data's catalog.
export function buildLibrary(dataDir, { generatedAt, engine = defaultEngine(), libraryDir } = {}) {
  const read = (name) => JSON.parse(fs.readFileSync(path.join(dataDir, name), 'utf8'));
  let index = read('index.json');
  if (!Array.isArray(index.recipes) || !Array.isArray(index.cuisines)) {
    throw new Error('index.json needs recipes and cuisines');
  }
  const bodies = new Map();
  for (const cuisine of index.cuisines) {
    if (!FILE.test(cuisine.file)) throw new Error(`bad cuisine file ${cuisine.file}`);
    for (const recipe of read(cuisine.file).recipes) {
      if (bodies.has(recipe.id)) throw new Error(`duplicate recipe ${recipe.id}`);
      bodies.set(recipe.id, { recipe, file: cuisine.file });
    }
  }
  const library = libraryDir ? mergeLibrary(index, libraryDir) : null;
  if (library) {
    index = library.index;
    for (const body of library.bodies) {
      if (bodies.has(body.recipe.id)) throw new Error(`duplicate recipe ${body.recipe.id}`);
      bodies.set(body.recipe.id, body);
    }
  }
  const files = {};
  const seen = new Set();
  const rows = index.recipes.map((row) => {
    if (!ID.test(row.id) || seen.has(row.id)) throw new Error(`bad or duplicate id ${row.id}`);
    seen.add(row.id);
    const found = bodies.get(row.id);
    if (!found || found.file !== row.file) throw new Error(`no body for ${row.id} in ${row.file}`);
    const { recipe: source } = found;
    if (source.cuisine !== row.cuisine || (source.servings ?? null) !== (row.servings ?? null)) {
      throw new Error(`index/body mismatch for ${row.id}`);
    }
    const servings = servingsFields(engine.compute(source));
    const recipe = { ...source, ...servings };
    const text = JSON.stringify(recipe);
    const sha = sha256(text);
    files[`r/${sha}.json`] = text;
    const out = { ...row, ...imageFields(row, recipe), ...servings, body: sha };
    if (row.catalogStatus === 'active') {
      out.ingredients = recipe.ingredients.map(compactIngredient);
    }
    return out;
  });
  const published = { ...index, recipes: rows };
  validateCatalog(published);
  files['index.json'] = JSON.stringify(published);
  const dishes = path.join(dataDir, 'dishes.json');
  if (library?.dishes) {
    const ids = new Set(rows.filter((r) => r.catalogStatus === 'active').map((r) => r.id));
    for (const d of library.dishes.dishes) {
      const missing = d.recipes.find((id) => !ids.has(id));
      if (missing) throw new Error(`dish ${d.id}: ${missing} is not an active recipe`);
    }
    files['dishes.json'] = JSON.stringify(library.dishes);
  } else if (fs.existsSync(dishes)) {
    files['dishes.json'] = JSON.stringify(JSON.parse(fs.readFileSync(dishes, 'utf8')));
  }
  if (library?.creators) files['creators.json'] = JSON.stringify(library.creators);
  // Bodies are verified through their index row (`body` is their sha256),
  // so the manifest the app fetches every few hours stays small.
  const entries = {};
  let bodyBytes = 0;
  let bodyCount = 0;
  for (const name of Object.keys(files).sort()) {
    const size = Buffer.byteLength(files[name], 'utf8');
    if (name.startsWith('r/')) {
      bodyBytes += size;
      bodyCount++;
    } else {
      entries[name] = { sha256: sha256(files[name]), size };
    }
  }
  const version = sha256(JSON.stringify(entries));
  const manifest = {
    schema: SCHEMA,
    version,
    generatedAt: generatedAt ?? new Date().toISOString(),
    recipeCount: rows.filter((r) => r.catalogStatus === 'active').length,
    files: entries,
    bodies: { count: bodyCount, size: bodyBytes },
  };
  return { manifest, files };
}

function previousManifest(outDir) {
  try {
    return JSON.parse(fs.readFileSync(path.join(outDir, 'manifest.json'), 'utf8'));
  } catch {
    return null;
  }
}

/// Refuses an output folder whose cleanup could delete anything but an
/// earlier library: the repository root, a folder holding the recipe data,
/// or a non-empty folder that is not a library build.
function checkOutDir(dataDir, outDir) {
  const out = path.resolve(outDir);
  const data = path.resolve(dataDir);
  const inside = (child, parent) => {
    const rel = path.relative(parent, child);
    return rel === '' || (!rel.startsWith('..') && !path.isAbsolute(rel));
  };
  if (inside(root, out) || inside(data, out) || inside(out, data) || out === path.parse(out).root) {
    throw new Error(`refusing --out ${out}: it would overwrite the repository or the recipe data`);
  }
  if (fs.existsSync(out)) {
    const names = fs.readdirSync(out);
    if (names.length && !names.includes('manifest.json')) {
      throw new Error(`refusing --out ${out}: not empty and not an earlier library build`);
    }
  }
}

/// The body hashes the previous build's index points at, so phones still on
/// it can open recipes until they take the new catalog.
function previousBodies(outDir) {
  try {
    const index = JSON.parse(fs.readFileSync(path.join(outDir, 'index.json'), 'utf8'));
    return new Set(index.recipes.map((r) => r.body).filter((b) => /^[0-9a-f]{64}$/.test(b ?? '')));
  } catch {
    return new Set();
  }
}

/// Writes the library to [outDir], replacing an earlier build there. Body
/// files of the previous build stay one more version (a phone on the old
/// catalog may still ask for them); older ones are removed.
export function publish(dataDir, outDir, { generatedAt, libraryDir } = {}) {
  checkOutDir(dataDir, outDir);
  if (libraryDir) checkOutDir(libraryDir, outDir);
  const previous = previousManifest(outDir);
  const keep = previousBodies(outDir);
  let built = buildLibrary(dataDir, { generatedAt: generatedAt ?? 'pending', libraryDir });
  if (!generatedAt) {
    const kept = previous && previous.version === built.manifest.version && previous.generatedAt;
    built.manifest.generatedAt = kept || new Date().toISOString();
  }
  const bodyDir = path.join(outDir, 'r');
  fs.mkdirSync(bodyDir, { recursive: true });
  for (const name of fs.readdirSync(outDir)) {
    if (name !== 'r') fs.rmSync(path.join(outDir, name), { recursive: true, force: true });
  }
  for (const name of fs.readdirSync(bodyDir)) {
    const sha = name.replace(/\.json$/, '');
    if (!keep.has(sha) && !built.files[`r/${name}`]) fs.rmSync(path.join(bodyDir, name), { force: true });
  }
  for (const [name, text] of Object.entries(built.files)) {
    fs.writeFileSync(path.join(outDir, name), text);
  }
  fs.writeFileSync(path.join(outDir, 'manifest.json'), JSON.stringify(built.manifest));
  return built.manifest;
}

function argument(name) {
  const at = process.argv.indexOf(name);
  return at === -1 ? undefined : process.argv[at + 1];
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const outDir = path.resolve(argument('--out') ?? path.join(root, 'build', 'library'));
  const dataDir = path.resolve(argument('--data') ?? path.join(root, 'recipes', 'data'));
  const lib = argument('--library') ?? defaultLibraryDir;
  const libraryDir = lib === 'none' ? undefined : path.resolve(lib);
  const epoch = process.env.SOURCE_DATE_EPOCH;
  const generatedAt =
    argument('--generated-at') ?? (epoch ? new Date(Number(epoch) * 1000).toISOString() : undefined);
  const manifest = publish(dataDir, outDir, { generatedAt, libraryDir });
  const bytes = Object.values(manifest.files).reduce((a, f) => a + f.size, manifest.bodies.size);
  console.log(
    `library ${manifest.version.slice(0, 12)}: ${manifest.recipeCount} recipes, ` +
      `${manifest.bodies.count} bodies, ${(bytes / 1e6).toFixed(2)} MB -> ${outDir}`,
  );
}
