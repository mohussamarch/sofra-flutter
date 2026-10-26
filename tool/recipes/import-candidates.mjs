// Registers source-backed recipe candidates (data/recipes/candidates-*/*.json)
// in the operational catalog, in the shape CatalogRecipe.fromJson accepts:
//
// - difficulty is text: "غير محدد" when the source gives none;
// - any unknown prep/cook/step time needs metadataPolicy source-unknowns-v1
//   and notes naming the source (the URL goes in notes either way);
// - totalTime equals prep + cook, or is null when either is unknown (a
//   different stated total is kept in notes);
// - every measured line has a unit; ranges keep the lower bound, the range
//   stays in the line note (no extra fields);
// - the cuisine is concrete and belongs to one display group;
// - no pork or alcohol (content policy, 26 October 2026).
//
// Candidates already in the catalog (same id, or same name) are skipped, so
// the script can run again as new candidate files arrive.
//
// Usage: node tool/recipes/import-candidates.mjs data/recipes/candidates-20261026
import {readFileSync, writeFileSync, readdirSync, existsSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {review} from './hold-content.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url));
const indexFile = `${root}recipes/data/index.json`;
const unknownPolicy = 'source-unknowns-v1';

/** Spellings the catalog already uses. */
const cuisineSpelling = {'عماني': 'عُماني'};

/** Display group for cuisines the catalog did not have yet. */
const newCuisineGroup = {
  'سوري': 'levantine',
  'فلسطيني': 'levantine',
  'أردني': 'levantine',
};

/** File slugs for new cuisines. */
const slugs = {
  'سوري': 'syrian',
  'فلسطيني': 'palestinian',
  'أردني': 'jordanian',
  'إماراتي': 'emirati',
  'كويتي': 'kuwaiti',
  'جزائري': 'algerian',
  'ليبي': 'libyan',
  'سوداني': 'sudanese',
};

function need(ok, message) {
  if (!ok) throw new Error(message);
}

const number = (v) => typeof v === 'number' && Number.isFinite(v);

/** One candidate in catalog shape, or an error saying what is missing. */
export function normalize(c) {
  need(typeof c.id === 'string' && /^[a-z0-9-]+$/.test(c.id), 'bad id');
  for (const k of ['name', 'cuisine', 'category', 'description']) {
    need(typeof c[k] === 'string' && c[k].trim(), `missing ${k}`);
  }
  need(Number.isInteger(c.servings) && c.servings > 0, 'servings must be stated');
  need(c.source && /^https?:\/\//.test(c.source.url ?? ''), 'source url required');
  const reasons = review(c);
  need(!reasons.length, `pork/alcohol: ${reasons.map((r) => r.hit).join(',')}`);

  const ingredients = (c.ingredients ?? []).map((i, n) => {
    need(typeof i.id === 'string' && i.id && typeof i.name === 'string' && i.name.trim(),
      `ingredient ${n} needs id and name`);
    const measured = number(i.amount) && i.amount > 0;
    need(!measured || (typeof i.unit === 'string' && i.unit.trim()), `ingredient ${n} needs a unit`);
    const line = {id: i.id, name: i.name.trim(), amount: measured ? i.amount : null, unit: measured ? i.unit : null};
    if (!measured) {
      line.label = i.label ?? 'حسب الرغبة';
      line.scale = false;
    } else if (i.scale === false) {
      line.scale = false;
    }
    if (i.optional) line.optional = true;
    const notes = [i.note, number(i.amountMax) ? `من ${i.amount} لـ ${i.amountMax}` : null]
      .filter((v) => typeof v === 'string' && v.trim());
    if (notes.length) line.note = [...new Set(notes)].join('، ');
    return line;
  });
  need(ingredients.length, 'no ingredients');

  const steps = (c.steps ?? []).map((s, n) => {
    need(typeof s.text === 'string' && s.text.trim(), `step ${n + 1} needs text`);
    const step = {n: n + 1, text: s.text.trim(), duration: number(s.duration) && s.duration >= 0 ? s.duration : null};
    if (s.passive) step.passive = true;
    if (typeof s.tip === 'string' && s.tip.trim()) step.tip = s.tip.trim();
    return step;
  });
  need(steps.length, 'no steps');

  const prep = number(c.prepTime) ? c.prepTime : null;
  const cook = number(c.cookTime) ? c.cookTime : null;
  const total = prep != null && cook != null ? prep + cook : null;
  const notes = [`المصدر: ${c.source.url}`];
  if (c.source.site) notes.push(`الموقع: ${c.source.site}`);
  if (number(c.totalTime) && c.totalTime !== total) {
    notes.push(`الوقت الإجمالي في المصدر ${c.totalTime} دقيقة`);
  }
  notes.push('المقادير والأوقات من المصدر؛ الخطوات مكتوبة بصياغتنا، ولم يُستنتج مقدار أو زمن غير مذكور.');
  const unknown = prep == null || cook == null || steps.some((s) => s.duration == null);

  const cuisine = cuisineSpelling[c.cuisine.trim()] ?? c.cuisine.trim();
  const recipe = {
    id: c.id,
    name: c.name.trim(),
    nameEn: c.nameEn ?? null,
    cuisine,
    category: c.category.trim(),
    description: c.description.trim(),
    servings: c.servings,
    prepTime: prep,
    cookTime: cook,
    totalTime: total,
    difficulty: typeof c.difficulty === 'string' && c.difficulty.trim() ? c.difficulty.trim() : 'غير محدد',
    ingredients,
    steps,
    tags: [],
    notes: notes.join(' | '),
  };
  if (unknown) recipe.metadataPolicy = unknownPolicy;
  return recipe;
}

function main(dir) {
  const index = JSON.parse(readFileSync(indexFile, 'utf8'));
  const ids = new Set(index.recipes.map((r) => r.id));
  const names = new Set(index.recipes.map((r) => r.name.trim()));
  const fileOf = new Map(index.cuisines.map((c) => [c.name, c.file]));
  const groupOf = new Map();
  for (const g of index.cuisineGroups) for (const m of g.members) groupOf.set(m, g.id);
  const files = {};
  const report = {importedAt: '2026-10-26', added: [], skipped: []};

  for (const name of readdirSync(dir).filter((f) => f.endsWith('.json') && !f.startsWith('import-'))) {
    const batch = JSON.parse(readFileSync(`${dir}/${name}`, 'utf8'));
    for (const c of batch.recipes ?? []) {
      let recipe;
      try {
        recipe = normalize(c);
      } catch (e) {
        report.skipped.push({file: name, id: c.id, name: c.name, why: e.message});
        continue;
      }
      if (ids.has(recipe.id) || names.has(recipe.name)) {
        report.skipped.push({file: name, id: c.id, name: c.name, why: 'already in catalog'});
        continue;
      }
      const cuisine = recipe.cuisine;
      if (!fileOf.has(cuisine)) {
        const slug = slugs[cuisine];
        need(slug, `no file slug for new cuisine ${cuisine}`);
        const file = `${slug}.json`;
        index.cuisines.push({name: cuisine, slug, file, count: 0});
        fileOf.set(cuisine, file);
        if (!existsSync(`${root}recipes/data/${file}`)) {
          files[file] = {cuisine, cuisineSlug: slug, version: index.version, recipes: []};
        }
      }
      if (!groupOf.has(cuisine)) {
        const group = newCuisineGroup[cuisine] ?? 'other';
        index.cuisineGroups.find((g) => g.id === group).members.push(cuisine);
        groupOf.set(cuisine, group);
      }
      const file = fileOf.get(cuisine);
      files[file] ??= JSON.parse(readFileSync(`${root}recipes/data/${file}`, 'utf8'));
      files[file].recipes.push(recipe);
      index.recipes.push({
        id: recipe.id,
        name: recipe.name,
        nameEn: recipe.nameEn,
        cuisine,
        category: recipe.category,
        servings: recipe.servings,
        totalTime: recipe.totalTime,
        difficulty: recipe.difficulty,
        tags: [],
        ingredientCount: recipe.ingredients.length,
        stepCount: recipe.steps.length,
        file,
        catalogStatus: 'active',
        cuisineGroup: groupOf.get(cuisine),
      });
      ids.add(recipe.id);
      names.add(recipe.name);
      report.added.push({file: name, id: recipe.id, name: recipe.name, cuisine, unknownTimes: !!recipe.metadataPolicy});
    }
  }
  for (const c of index.cuisines) {
    c.count = index.recipes.filter((r) => r.file === c.file && r.catalogStatus === 'active').length;
  }
  for (const g of index.cuisineGroups) {
    g.count = index.recipes.filter((r) => r.catalogStatus === 'active' && r.cuisineGroup === g.id).length;
  }
  for (const [file, data] of Object.entries(files)) {
    writeFileSync(`${root}recipes/data/${file}`, `${JSON.stringify(data, null, 2)}\n`);
  }
  writeFileSync(indexFile, `${JSON.stringify(index, null, 2)}\n`);
  writeFileSync(`${dir}/import-report.json`, `${JSON.stringify(report, null, 2)}\n`);
  console.log(`added ${report.added.length}, skipped ${report.skipped.length}`);
  for (const s of report.skipped) console.log(`  skip ${s.id}: ${s.why}`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main(process.argv[2] ?? `${root}data/recipes/candidates-20261026`);
}
