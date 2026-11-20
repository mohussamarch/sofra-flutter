#!/usr/bin/env node
// Builds the online recipe library that the app downloads from Firebase
// Hosting (site target "library"), from the reviewed catalog in recipes/data.
//
//   node tool/recipes/publish-library.mjs            # -> build/library/
//   node tool/recipes/publish-library.mjs --out DIR  # another folder
//   firebase deploy --only hosting:library --project sofra-c03a1
//
// Output (deterministic for the same recipes/data):
//   manifest.json   {schema, version, generatedAt, recipeCount, files, bodies}
//                   served no-cache; the app checks it at most every 6 hours.
//                   files: {"index.json"|"dishes.json": {sha256, size}};
//                   bodies: {count, size}; each body is checked by its row.
//   index.json      the catalog: every row of recipes/data/index.json plus
//                   `body` (sha256 of its body file) and, for active rows,
//                   `ingredients` (id, name, amount, unit, scale, optional) so
//                   listing, search and stock matching need no body; and
//                   optional image references `thumbnail` and `photos[]`
//                   (URLs or img/ paths, never image bytes).
//   dishes.json     dish groups, as in recipes/data.
//   r/<sha256>.json one recipe body each, content addressed (cached forever).
//
// generatedAt only changes when the content changes: an unchanged library
// keeps the timestamp of the previous build in the output folder. Pass
// --generated-at ISO or SOURCE_DATE_EPOCH to pin it.
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

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

/// Builds every published file in memory: {relativePath: text}.
export function buildLibrary(dataDir, { generatedAt } = {}) {
  const read = (name) => JSON.parse(fs.readFileSync(path.join(dataDir, name), 'utf8'));
  const index = read('index.json');
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
  const files = {};
  const seen = new Set();
  const rows = index.recipes.map((row) => {
    if (!ID.test(row.id) || seen.has(row.id)) throw new Error(`bad or duplicate id ${row.id}`);
    seen.add(row.id);
    const found = bodies.get(row.id);
    if (!found || found.file !== row.file) throw new Error(`no body for ${row.id} in ${row.file}`);
    const { recipe } = found;
    if (recipe.cuisine !== row.cuisine || (recipe.servings ?? null) !== (row.servings ?? null)) {
      throw new Error(`index/body mismatch for ${row.id}`);
    }
    const text = JSON.stringify(recipe);
    const sha = sha256(text);
    files[`r/${sha}.json`] = text;
    const out = { ...row, ...imageFields(row, recipe), body: sha };
    if (row.catalogStatus === 'active') {
      out.ingredients = recipe.ingredients.map(compactIngredient);
    }
    return out;
  });
  const published = { ...index, recipes: rows };
  files['index.json'] = JSON.stringify(published);
  const dishes = path.join(dataDir, 'dishes.json');
  if (fs.existsSync(dishes)) {
    files['dishes.json'] = JSON.stringify(JSON.parse(fs.readFileSync(dishes, 'utf8')));
  }
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

/// Writes the library to [outDir], replacing what was there.
export function publish(dataDir, outDir, { generatedAt } = {}) {
  const previous = previousManifest(outDir);
  let built = buildLibrary(dataDir, { generatedAt: generatedAt ?? 'pending' });
  if (!generatedAt) {
    const kept = previous && previous.version === built.manifest.version && previous.generatedAt;
    built.manifest.generatedAt = kept || new Date().toISOString();
  }
  fs.rmSync(outDir, { recursive: true, force: true });
  fs.mkdirSync(path.join(outDir, 'r'), { recursive: true });
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
  const epoch = process.env.SOURCE_DATE_EPOCH;
  const generatedAt =
    argument('--generated-at') ?? (epoch ? new Date(Number(epoch) * 1000).toISOString() : undefined);
  const manifest = publish(dataDir, outDir, { generatedAt });
  const bytes = Object.values(manifest.files).reduce((a, f) => a + f.size, manifest.bodies.size);
  console.log(
    `library ${manifest.version.slice(0, 12)}: ${manifest.recipeCount} recipes, ` +
      `${manifest.bodies.count} bodies, ${(bytes / 1e6).toFixed(2)} MB -> ${outDir}`,
  );
}
