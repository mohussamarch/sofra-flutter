import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { defaultEngine, effectiveServings, dartTables, root, tablesDartFile } from './servings-engine.mjs';
import { loadCorpus, buildReport } from './servings-report.mjs';
import { normalize } from './import-candidates.mjs';

const engine = defaultEngine();
const recipe = (category, lines, servings = null) => ({
  category, servings,
  ingredients: lines.map(([id, name, amount, unit, optional]) => ({ id, name, amount, unit, optional })),
});

test('anchor cases follow the home portion norms', () => {
  assert.equal(engine.compute(recipe('طبق رئيسي', [['pasta', 'مكرونة', 1, 'كيلو']])).servingsComputed, 5);
  const kabsa = engine.compute(recipe('طبق رئيسي', [['basmati-rice', 'أرز بسمتي', 1, 'كيلو'], ['lamb', 'لحم ضأن', 1, 'كيلو']]));
  assert.ok(Math.abs(kabsa.servingsComputed - 7) <= 1, `kabsa ${kabsa.servingsComputed}`);
  assert.equal(engine.compute(recipe('طبق رئيسي', [['chicken', 'فرخة', 1, 'حبة']])).servingsComputed, 4);
  assert.equal(engine.compute(recipe('طبق رئيسي', [['molokhia', 'ملوخية', 400, 'جرام']])).servingsComputed, 4);
  assert.equal(engine.compute(recipe('شوربة', [['red-lentils', 'عدس', 1.5, 'كوب'], ['water', 'ماء', 1.75, 'لتر']])).servingsComputed, 5);
});

test('kind rules: bases are not applicable, soups count liquid, mains ignore it', () => {
  const sauce = engine.compute(recipe('صلصة', [['pasta', 'مكرونة', 1, 'كيلو']]));
  assert.equal(sauce.servingsComputed, null);
  assert.equal(sauce.servingsBasis.reason, 'notApplicable');
  const main = engine.compute(recipe('طبق رئيسي', [['pasta', 'مكرونة', 400, 'جرام'], ['water', 'ماء', 3, 'لتر']]));
  assert.equal(main.servingsComputed, 2);
  const eggs = engine.compute(recipe('فطار', [['eggs', 'بيض', 6, 'حبة']]));
  assert.equal(eggs.servingsComputed, 3);
  const eggsWithMeat = engine.compute(recipe('طبق رئيسي', [['eggs', 'بيض', 2, 'حبة'], ['beef', 'لحم', 1, 'كيلو']]));
  assert.deepEqual(eggsWithMeat.servingsBasis.drivers.map((d) => d.category), ['meatBoneless']);
  const side = engine.compute(recipe('أطباق جانبية', [['x-i0', 'أرز', 300, 'جرام']]));
  assert.equal(side.kind, 'side');
  assert.equal(side.servingsComputed, 4);
  const bolognese = engine.compute(recipe('صلصة', [['x-i0', 'لحم بقري مفروم', 1, 'كيلو']]));
  assert.equal(bolognese.servingsComputed, 7);
});

test('a stated yield is kept when plausible and rejected only by a sure engine', () => {
  const ok = engine.compute(recipe('طبق رئيسي', [['pasta', 'مكرونة', 500, 'جرام']], 3));
  assert.equal(ok.servingsBasis.source, 'source');
  assert.equal(effectiveServings(ok), 3);
  const lines = [['pasta', 'مكرونة', 500, 'جرام'], ['beef', 'لحمة بقري', 500, 'جرام']];
  const inflated = engine.compute(recipe('طبق رئيسي', lines, 10));
  assert.equal(inflated.servingsConfidence, 'high');
  assert.equal(inflated.servingsBasis.source, 'computed');
  assert.equal(inflated.servingsBasis.reason, 'sourceInflated');
  assert.equal(effectiveServings(inflated), 4);
  const medium = engine.compute(recipe('طبق رئيسي', [['pasta', 'مكرونة', 500, 'جرام']], 10));
  assert.equal(medium.servingsBasis.reason, 'sourceKeptMediumConfidence');
  assert.equal(effectiveServings(medium), 10);
  const cookies = engine.compute(recipe('حلويات', [['flour', 'دقيق', 250, 'جرام'], ['milk', 'حليب', 1.2, 'لتر']], 36));
  assert.equal(cookies.servingsBasis.reason, 'sourceCountsPieces');
});

test('the name corrects a plain id; generated line ids never match', () => {
  assert.equal(engine.categoryOf({ id: 'beef', name: 'لحم بقري أو ضاني مفروم (أو خليط منهما)' }), 'mince');
  assert.equal(engine.categoryOf({ id: 'lamb', name: 'لحم غنم شقف' }), 'meatBoneIn');
  assert.equal(engine.categoryOf({ id: 'beef', name: 'لحم بقري بدون عظم' }), 'meatBoneless');
  assert.equal(engine.categoryOf({ id: 'ma650-manal-coconut-cake-20261021b-i6', name: 'زبدة، لينة' }), null);
});

test('unknown units, odd lines and prototype names never crash', () => {
  const r = engine.compute(recipe('طبق رئيسي', [['pasta', 'مكرونة', 2, 'حفنة'], ['constructor', 'toString', 3, 'constructor'], [null, null, 'x', null]]));
  assert.equal(r.servingsComputed, null);
  assert.equal(r.servingsConfidence, 'none');
  assert.ok(r.servingsBasis.reason);
  assert.doesNotThrow(() => engine.compute({ category: null, ingredients: [null, 3, 'x'] }));
});

test('candidates without servings import when the engine can compute them', () => {
  const c = {
    id: 'test-pasta', name: 'مكرونة', cuisine: 'مصري', category: 'طبق رئيسي', description: 'وصف',
    source: { url: 'https://example.com/r' },
    ingredients: [{ id: 'pasta', name: 'مكرونة', amount: 500, unit: 'جرام' }],
    steps: [{ text: 'اسلق المكرونة', duration: 10 }], prepTime: 5, cookTime: 10,
  };
  const r = normalize(c);
  assert.equal(r.servings, null);
  assert.equal(r.metadataPolicy, 'source-unknowns-v1');
  assert.throws(() => normalize({ ...c, ingredients: [{ id: 'salt', name: 'ملح', amount: 1, unit: 'ملعقة صغيرة' }] }), /servings/);
});

test('every corpus recipe gets a value or an explicit reason', () => {
  const corpus = loadCorpus();
  const { report } = buildReport(corpus, engine);
  assert.equal(report.summary.recipes, corpus.length);
  for (const { recipe: r } of corpus) {
    const out = engine.compute(r);
    if (out.servingsComputed == null) assert.ok(out.servingsBasis.reason, r.id);
    else assert.ok(out.servingsComputed >= 1 && out.servingsComputed <= 20, r.id);
  }
});

test('the Dart tables are current', () => {
  const now = fs.readFileSync(path.join(root, tablesDartFile), 'utf8').replace(/\r\n/g, '\n');
  assert.equal(now, dartTables(), 'run node tool/recipes/servings-engine.mjs --emit-dart');
});
