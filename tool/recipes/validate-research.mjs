import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const fail = message => { throw new Error(message); };
const object = (v, label) => v && typeof v === 'object' && !Array.isArray(v) || fail(`Invalid ${label}`);
const text = (v, label) => typeof v === 'string' && v.trim() !== '' || fail(`Invalid ${label}`);
const list = (v, label, nonempty = false) => Array.isArray(v) && (!nonempty || v.length > 0) || fail(`Invalid ${label}`);
const nullableNumber = (v, label, zero = false) => v === null ||
  (typeof v === 'number' && Number.isFinite(v) && (zero ? v >= 0 : v > 0)) || fail(`Invalid ${label}`);
function url(v, label) {
  text(v, label);
  let parsed; try { parsed = new URL(v); } catch { fail(`Invalid ${label}`); }
  if (parsed.protocol !== 'https:' || parsed.username || parsed.password) fail(`Invalid ${label}`);
}
function timestamp(v) {
  if (typeof v !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$/.test(v) ||
      !Number.isFinite(Date.parse(v))) fail('Invalid retrievedAt');
  const date = v.slice(0, 10);
  if (new Date(`${date}T12:00:00Z`).toISOString().slice(0, 10) !== date) fail('Invalid retrievedAt calendar date');
}
function unique(ids, value, label) {
  text(value, label);
  if (value.trim() !== value) fail(`Invalid ${label} whitespace`);
  if (ids.has(value)) fail(`Duplicate ${label}: ${value}`);
  ids.add(value);
}

/** Offline research boundary only. Does not approve evidence or produce runtime recipes. */
export function validateResearchBank(bank, { shippingIds = new Set() } = {}) {
  object(bank, 'bank');
  if (bank.schemaVersion !== 1) fail('Unsupported recipe research schemaVersion');
  list(bank.sources, 'sources', true); list(bank.recipes, 'recipes', true);
  const sourceIds = new Set(), recipeIds = new Set(), variantIds = new Set();
  const result = { sourceCount: bank.sources.length, recipeCount: bank.recipes.length,
    ingredientCount: 0, stepCount: 0, unknownAmounts: 0, unknownStepDurations: 0,
    unknownServings: 0, unverifiedLicenseSources: 0, runtimeReadyCount: 0 };
  for (const source of bank.sources) {
    object(source, 'source'); unique(sourceIds, source.id, 'source id');
    url(source.url, 'source URL'); text(source.title, 'source title');
    text(source.publisher, 'publisher'); text(source.license, 'license'); timestamp(source.retrievedAt);
    if (!['unknown', 'unverified-primary-source', 'verified-license'].includes(source.licenseStatus)) fail('Invalid license review status');
    if (source.licenseStatus === 'verified-license') url(source.licenseEvidenceUrl, 'license evidence URL');
    else result.unverifiedLicenseSources++;
    if (source.archivePath != null) {
      if (typeof source.archivePath !== 'string' || !/^research\/recipes\/[a-zA-Z0-9_./-]+$/.test(source.archivePath) ||
          source.archivePath.split('/').includes('..')) fail('Invalid archive path');
      if (typeof source.sha256 !== 'string' || !/^[a-f0-9]{64}$/.test(source.sha256)) fail('Archived source requires a SHA256 hash');
    } else if (source.sha256 != null) fail('Unarchived source hash must remain null');
  }
  for (const recipe of bank.recipes) {
    object(recipe, 'recipe'); unique(recipeIds, recipe.id, 'recipe id'); text(recipe.name, 'recipe name');
    if (!Number.isInteger(recipe.recordVersion) || recipe.recordVersion < 1) fail('Invalid research recordVersion');
    if (recipe.sourceRevision !== null) text(recipe.sourceRevision, 'source revision');
    unique(variantIds, recipe.variantId, 'variant id'); text(recipe.familyId, 'family id');
    if (shippingIds.has(recipe.id) || shippingIds.has(recipe.variantId)) fail('Research ID collides with shipping catalogue');
    if (!sourceIds.has(recipe.sourceId)) fail('Unknown sourceId');
    text(recipe.sourceRecipeId, 'source recipe id'); url(recipe.sourceUrl, 'recipe source URL');
    if (recipe.reviewStatus !== 'research-only') fail('Research recipe cannot claim runtime approval');
    nullableNumber(recipe.servings, 'servings');
    if (recipe.servings === null) result.unknownServings++;
    else if (!Number.isInteger(recipe.servings)) fail('Fractional source yield requires review before serving conversion');
    if (recipe.nutrition !== null) fail('Unreviewed recipe nutrition must remain null');
    list(recipe.gaps, 'gaps'); recipe.gaps.forEach(v => text(v, 'gap'));
    list(recipe.ingredients, 'ingredients', true); list(recipe.steps, 'steps', true);
    const lineIds = new Set();
    for (const ingredient of recipe.ingredients) {
      object(ingredient, 'ingredient'); unique(lineIds, ingredient.id, 'ingredient line id');
      text(ingredient.name, 'ingredient name'); text(ingredient.sourceText, 'source ingredient text');
      nullableNumber(ingredient.amount, 'ingredient amount');
      if (ingredient.unit !== null) text(ingredient.unit, 'ingredient unit');
      if (ingredient.amount === null) result.unknownAmounts++;
      else if (ingredient.unit === null) fail('Measured ingredient needs original unit');
      if (ingredient.foodBinding !== null) fail('Unreviewed ingredient foodBinding must remain null');
      result.ingredientCount++;
    }
    for (let i = 0; i < recipe.steps.length; i++) {
      const step = recipe.steps[i]; object(step, 'step');
      if (step.n !== i + 1) fail('Invalid integer step sequence');
      text(step.text, 'step text'); nullableNumber(step.durationMinutes, 'step duration', true);
      if (step.durationMinutes === null) result.unknownStepDurations++;
      result.stepCount++;
    }
  }
  return result;
}

function canonical(v) {
  if (Array.isArray(v)) return v.map(canonical);
  if (v && typeof v === 'object') return Object.fromEntries(Object.keys(v).sort().map(k => [k, canonical(v[k])]));
  return v;
}
export const candidateFingerprint = recipe => createHash('sha256').update(JSON.stringify(canonical(recipe))).digest('hex');

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const args = process.argv.slice(2);
    if (args.includes('--help')) {
      console.log('node tool/recipes/validate-research.mjs [--file data/recipes/research-candidates.json]\nRead-only research validation; never imports into Flutter or approves source facts.');
    } else {
      if (args.length && (args.length !== 2 || args[0] !== '--file')) fail('Expected --file PATH or --help');
      const bank = JSON.parse(await readFile(args[1] ?? 'data/recipes/research-candidates.json', 'utf8'));
      const shipping = JSON.parse(await readFile('recipes/data/index.json', 'utf8'));
      const report = validateResearchBank(bank, {shippingIds: new Set(shipping.recipes.map(r => r.id))});
      for (const source of bank.sources) if (source.archivePath != null) {
        const actual = createHash('sha256').update(await readFile(source.archivePath)).digest('hex');
        if (actual !== source.sha256) fail(`Archived source hash mismatch: ${source.id}`);
      }
      console.log(JSON.stringify({...report, candidates: bank.recipes.map(r => ({id:r.id, contentSha256:candidateFingerprint(r)}))}, null, 2));
    }
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
