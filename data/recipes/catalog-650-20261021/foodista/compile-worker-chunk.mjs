import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const root = process.cwd();
const base = 'data/recipes/catalog-650-20261021/foodista';
const selection = JSON.parse(fs.readFileSync(path.join(base, 'selection.json'), 'utf8'));
const selected = new Map(selection.recipes.map(({recipe}, index) => [recipe.id, {recipe, index}]));
const existing = JSON.parse(fs.readFileSync(path.join(base, 'chunk-001.json'), 'utf8'));
const existingIds = new Set(existing.recipes.map(recipe => recipe.id));
const warehouseRoot = path.join(root, 'data/recipes/curated-local/foodista-scale-20261021b');
const normalizedFiles = [path.join(warehouseRoot, 'normalized-recipes.json'), ...fs.readdirSync(path.join(warehouseRoot, 'batches'), {withFileTypes:true}).filter(x=>x.isDirectory()).map(x=>path.join(warehouseRoot,'batches',x.name,'normalized-recipes.json'))];
const warehouse = new Map();
const warehousePacks = new Map();
for (const file of normalizedFiles) {
  if (!fs.existsSync(file)) continue;
  const data=JSON.parse(fs.readFileSync(file,'utf8'));
  for (const r of data.recipes) { warehouse.set(r.id, r); warehousePacks.set(r.id, path.relative(root,file).replaceAll('\\','/')); }
}
if (process.argv[2] === '--scan-pool') {
  const seen = new Set(selection.recipes.map(x=>x.recipe.id));
  for (const row of existing.recipes) seen.add(`modern-bulk:foodista:${row.id.slice('fi650-'.length)}`);
  const eligible = [];
  const cuisine = /moroccan|japanese|chinese|indian|thai|korean|vietnamese|indonesian|malaysian|filipino|pakistani|kimchi|sushi|pho|biryani|pad thai|lumpia|couscous|tagine|tagine|curry|teriyaki|sukiyaki|miso|ramen|tandoori|tikka|tempura|bibimbap|bulgogi|sichuan|szechuan/i;
  for (const file of normalizedFiles) {
    if (!fs.existsSync(file)) continue;
    const data=JSON.parse(fs.readFileSync(file,'utf8'));
    for (const r of data.recipes) {
      if (seen.has(r.id) || !cuisine.test(r.name) || !r.provenance?.license?.id?.startsWith('CC-BY') || !r.provenance?.sourceSnapshotFile || !r.steps?.length || !r.ingredients?.length) continue;
      eligible.push({id:r.id,name:r.name,ingredients:r.ingredients.length,steps:r.steps.length,sourceUrl:r.provenance.sourceUrl,sourceSnapshotFile:r.provenance.sourceSnapshotFile,pack:path.relative(root,file).replaceAll('\\','/')});
    }
  }
  process.stdout.write(JSON.stringify({scannedFiles:normalizedFiles.length,eligibleTitleMatches:eligible.length,candidates:eligible},null,2)+'\n');
  process.exit(0);
}
const inputPath = process.argv[2];
if (!inputPath) throw new Error('Usage: node compile-worker-chunk.mjs INPUT.json');
const input = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
if (!Number.isInteger(input.chunk) || input.chunk < 101 || !Array.isArray(input.recipes) || input.recipes.length < 20 || input.recipes.length > 30) {
  throw new Error('Chunk must be 101+ and contain 20–30 recipes');
}
const outRecipes = [], outReviews = [];
const ids = new Set();
for (const job of input.recipes) {
  const sourceId = `modern-bulk:foodista:${job.sourceId}`;
  const found = selected.get(sourceId);
  const src = found?.recipe ?? warehouse.get(sourceId);
  const sourcePack = found ? selection.recipes[found.index].sourcePack : warehousePacks.get(sourceId);
  if (!src || !sourcePack) throw new Error(`Source ${job.sourceId} is not in the frozen selection or warehouse`);
  if ((found && [4, 5, 12, 32].includes(found.index)) || existingIds.has(`fi650-${job.sourceId}`)) throw new Error(`Root-owned source index/recipe: ${job.sourceId}`);
  if (!src.provenance?.license?.id?.startsWith('CC-BY') || !src.provenance?.sourceSnapshotFile) throw new Error(`Missing per-record rights or provenance evidence ${job.sourceId}`);
  const id = `fi650-${job.sourceId}`;
  if (ids.has(id)) throw new Error(`Duplicate ${id}`);
  ids.add(id);
  if (!job.name || !job.cuisine || !job.review || !job.steps?.length || !job.ingredients?.length) throw new Error(`Incomplete translation ${id}`);
  const rawLines = new Map(src.ingredients.map(v => [v.sourceLineIndex, v.sourceText]));
  const used = new Set();
  const ingredients = job.ingredients.map((ingredient, i) => {
    const line = ingredient.sourceLineIndex;
    if (!Number.isInteger(line) || !rawLines.has(line) || used.has(line)) throw new Error(`Invalid source ingredient crosswalk ${id}:${line}`);
    used.add(line);
    if (ingredient.amount == null && ingredient.unit != null) throw new Error(`Unknown amount cannot have a unit ${id}:${line}`);
    if (ingredient.amount != null && (!Number.isFinite(ingredient.amount) || ingredient.amount <= 0 || !ingredient.unit)) throw new Error(`Invalid known amount ${id}:${line}`);
    return { id: `${id}-i${i}`, name: ingredient.name, amount: ingredient.amount ?? null, unit: ingredient.unit ?? null, scale: ingredient.amount != null, optional: ingredient.optional === true, label: ingredient.label ?? null, display: null, note: ingredient.note ?? null };
  });
  const omitted = src.ingredients.filter(v => !used.has(v.sourceLineIndex));
  if (omitted.some(v => !job.omittedLines?.[v.sourceLineIndex])) {
    throw new Error(`Every omitted source line needs a heading/footnote reason ${id}`);
  }
  if (src.yield != null || src.time != null) {
    throw new Error(`Source has structured yield/time; preserve it explicitly before compiling ${id}`);
  }
  const snapshotFile = src.provenance.sourceSnapshotFile;
  const snapshotPath = path.join(root, snapshotFile);
  const snapshotBytes = fs.readFileSync(snapshotPath);
  const sourceSnapshotSha256 = crypto.createHash('sha256').update(snapshotBytes).digest('hex');
  const snapshot = JSON.parse(snapshotBytes.toString('utf8'));
  const provenance = src.provenance;
  const steps = job.steps.map((text, n) => ({ n: n + 1, text, duration: null, passive: false, tip: null }));
  const sourceNotes = `المصدر: ${provenance.sourceUrl}؛ المؤلف: ${provenance.author?.join('، ') || 'غير مذكور'}؛ الرخصة المعلنة في السجل: ${provenance.license?.id || 'غير محددة'}. ترجمة عربية مع توضيح/تنظيم للمقادير دون إضافة مكونات أو أزمنة أو مردود. بصمة لقطة المصدر ${sourceSnapshotSha256}؛ أصل Common Pile ${provenance.sourceRevision}. الوصفة غير معتمدة غذائيًا أو للحساسية أو المخزون.`;
  outRecipes.push({
    id, name: job.name, nameEn: src.name, cuisine: job.cuisine,
    category: job.category || 'أطباق رئيسية',
    description: 'طريقة المصدر مترجمة إلى العربية مع حفظ المقادير والحقائق المنشورة.',
    difficulty: 'غير محدد بالمصدر', servings: job.servings ?? null,
    prepTime: job.prepTime ?? null, cookTime: job.cookTime ?? null,
    totalTime: job.prepTime != null && job.cookTime != null ? job.prepTime + job.cookTime : null,
    metadataPolicy: 'source-unknowns-v1', ingredients, steps, tags: [],
    notes: `${sourceNotes} ${job.review}`,
  });
  outReviews.push({
    id, sourceId: src.id, sourcePack,
    sourceSnapshotFile: snapshotFile, sourceSnapshotSha256,
    cuisineEvidence: src.name,
    sourceIngredientLines: src.ingredients.map(v => v.sourceText),
    ingredientCrosswalk: job.ingredients.map((ingredient, i) => ({ sourceLineIndex: ingredient.sourceLineIndex, sourceText: rawLines.get(ingredient.sourceLineIndex), targetIngredientId: `${id}-i${i}`, translatedName: ingredient.name })),
    omittedSourceLines: omitted.map(v => ({ sourceLineIndex: v.sourceLineIndex, sourceText: v.sourceText, reason: job.omittedLines[v.sourceLineIndex] })),
    sourceMethod: src.steps.map(v => v.text),
    translatedMethodCoverage: job.steps.map((text, i) => ({ sourceStepIndices: src.steps.map(v => v.sourceStepIndices).flat(), translatedStep: i + 1, text })),
    review: job.review, quantityDecision: job.quantityDecision || 'المجهول محفوظ كما ورد؛ لم تُستنتج كمية أو وحدة أو مردود.',
    sourceUrl: provenance.sourceUrl, sourceAuthor: provenance.author || [], sourceLicenseId: provenance.license?.id || null,
    sourceRecordId: provenance.recordId, sourceTextSha256: provenance.sourceTextSha256,
    sourceSnapshotContentSha256: snapshot.sourceRecord?.sourceSnapshotSha256 || provenance.sourceSnapshotSha256,
  });
}
fs.writeFileSync(path.join(base, `chunk-${String(input.chunk).padStart(3,'0')}.json`), JSON.stringify({recipes: outRecipes}, null, 2) + '\n');
fs.writeFileSync(path.join(base, `chunk-${String(input.chunk).padStart(3,'0')}.review.json`), JSON.stringify({recipes: outReviews}, null, 2) + '\n');
process.stdout.write(`Wrote chunk ${input.chunk}: ${outRecipes.length} recipes, ${outReviews.reduce((n,r)=>n+r.ingredientCrosswalk.length,0)} ingredient crosswalks\n`);
