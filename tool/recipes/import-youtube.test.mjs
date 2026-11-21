import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { normalize } from './import-candidates.mjs';
import { cuisineOf, orderedStarts, prepare, servingsFromSource, unitFromName } from './import-youtube.mjs';
import { buildLibrary } from './publish-library.mjs';
import { review } from './hold-content.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const data = path.join(root, 'recipes', 'data');
const library = path.join(root, 'recipes', 'library-only');
const read = (file) => JSON.parse(fs.readFileSync(file, 'utf8'));

const candidate = {
  id: 'eg-test-nadia',
  name: 'بسكوت تجربة',
  nameEn: 'Test biscuits',
  cuisine: 'مصري',
  category: 'بسكويت',
  description: 'وصف قصير.',
  servings: null,
  creatorId: 'yt:UCG327FZhOIhBZpF9NqFL3Rg',
  sourceServings: '4 أفراد',
  video: {
    platform: 'youtube',
    id: 'TAaay8h3qd8',
    url: 'https://www.youtube.com/watch?v=TAaay8h3qd8',
    publishedAt: '2023-12-18',
    views: 1826858,
    likes: 31784,
    thumbnailUrl: 'https://i.ytimg.com/vi/TAaay8h3qd8/hqdefault.jpg',
    durationSec: 332,
    recipeIndex: 1,
  },
  ingredients: [
    { id: 'flour', name: 'دقيق', amount: 2, unit: 'كوب', group: 'للعجين' },
    { name: 'بيض', amount: 2, unit: null },
    { id: 'milk', name: 'حليب', amount: 100, unit: 'مللي' },
    { id: 'butter', name: 'زبدة', amount: '', unit: 'جرام' },
  ],
  steps: [
    { n: 1, text: 'اخلط.', videoStartSec: 21 },
    { n: 2, text: 'افرد.', videoStartSec: 10 },
    { n: 3, text: 'اخبز.', duration: 15, videoStartSec: 400 },
    { n: 4, text: 'قدّم.', videoStartSec: 300 },
  ],
};

test('the importer keeps creatorId, video, the source and every step videoStartSec', () => {
  const fixed = prepare(candidate, { idOf: () => 'egg', creatorName: 'نادية السيد' });
  const r = normalize({ ...fixed, servings: servingsFromSource(fixed.sourceServings) });
  assert.equal(r.creatorId, 'yt:UCG327FZhOIhBZpF9NqFL3Rg');
  assert.deepEqual(r.video, candidate.video);
  assert.equal(r.source.url, candidate.video.url);
  assert.equal(r.source.site, 'نادية السيد');
  assert.equal(r.sourceServings, '4 أفراد');
  assert.equal(r.servings, 4);
  // Backwards (10 after 21) and past the end (400 > 332) become unknown.
  assert.deepEqual(r.steps.map((s) => s.videoStartSec), [21, null, null, 300]);
  assert.ok(r.steps.every((s) => 'videoStartSec' in s));
  assert.equal(r.ingredients[0].group, 'للعجين');
  // A count with no unit takes the one its name says; spellings merge; an
  // empty amount is unmeasured and never scales.
  assert.deepEqual([r.ingredients[1].id, r.ingredients[1].unit], ['egg', 'حبة']);
  assert.equal(r.ingredients[2].unit, 'مل');
  assert.deepEqual([r.ingredients[3].amount, r.ingredients[3].scale, r.ingredients[3].label], [null, false, 'حسب الرغبة']);
  assert.equal(fixed.category, 'حلويات');
});

test('a recipe without a video keeps the catalog shape', () => {
  const { creatorId, video, ...plain } = candidate;
  const r = normalize({ ...plain, source: { url: 'https://example.com/r' }, servings: 2,
    ingredients: [{ id: 'flour', name: 'دقيق', amount: 2, unit: 'كوب' }] });
  assert.equal(r.creatorId, undefined);
  assert.equal(r.video, undefined);
  assert.ok(r.steps.every((s) => !('videoStartSec' in s)));
});

test('cuisine, servings and units are taken from the source, never guessed', () => {
  assert.equal(cuisineOf({ cuisine: null, name: 'كشري' }), null);
  assert.equal(cuisineOf({ cuisine: 'عالمي' }), null);
  assert.equal(cuisineOf({ cuisine: 'إنجليزي' }), 'بريطاني');
  assert.equal(servingsFromSource('12 قطعة'), null);
  assert.equal(servingsFromSource('من 4 إلى 6 أفراد'), 4);
  assert.equal(unitFromName('دقيق'), null);
  assert.equal(unitFromName('ورقة لورا'), 'ورقة');
  assert.deepEqual(orderedStarts([{ videoStartSec: 'x' }], 10), [{ videoStartSec: null }]);
});

test('every candidate is active, held or dropped exactly once', () => {
  const report = read(path.join(library, 'youtube-report.json'));
  const active = read(path.join(library, 'youtube.json')).recipes;
  const held = read(path.join(library, 'youtube-held.json')).recipes;
  assert.equal(report.active, active.length);
  assert.equal(report.held, held.length);
  assert.equal(report.dropped, report.droppedRecipes.length);
  assert.equal(report.active + report.held + report.dropped, report.candidates);
  const tags = [...active.map((r) => r.importTag), ...held.map((h) => h.tag), ...report.droppedRecipes.map((d) => d.tag)];
  assert.equal(new Set(tags).size, tags.length);
  for (const h of held) assert.ok(h.reasons.length, h.tag);
  const plan = read(path.join(library, 'youtube-plan.json'));
  for (const tag of Object.keys(plan.drop)) assert.ok(report.droppedRecipes.some((d) => d.tag === tag), tag);
  for (const r of active) {
    assert.ok(!plan.hold[r.importTag] && !plan.drop[r.importTag], r.importTag);
    assert.deepEqual(review(r), [], r.id);
  }
});

test('no duplicate recipe ids or names across the bundled catalog and the library', () => {
  const catalog = read(path.join(data, 'index.json')).recipes;
  const active = read(path.join(library, 'youtube.json')).recipes;
  const ids = [...catalog.map((r) => r.id), ...active.map((r) => r.id)];
  assert.equal(new Set(ids).size, ids.length);
  const names = [...catalog.map((r) => r.name.trim()), ...active.map((r) => r.name.trim())];
  assert.equal(new Set(names).size, names.length);
});

test('library recipes carry a known creator, the video and step times', () => {
  const creators = read(path.join(library, 'creators.json')).creators;
  const known = new Set(creators.map((c) => c.creatorId));
  for (const c of creators) {
    assert.match(c.creatorId, /^yt:UC[\w-]{22}$/);
    assert.equal(c.channelUrl, `https://www.youtube.com/channel/${c.channelId}`);
    assert.ok(c.name.ar);
  }
  for (const r of read(path.join(library, 'youtube.json')).recipes) {
    assert.ok(known.has(r.creatorId), r.id);
    assert.equal(r.video.platform, 'youtube');
    assert.ok(r.source.url, r.id);
    let last = -1;
    for (const s of r.steps) {
      assert.ok('videoStartSec' in s, r.id);
      if (s.videoStartSec != null) {
        assert.ok(s.videoStartSec >= last, r.id);
        last = s.videoStartSec;
      }
    }
  }
});

test('the published library adds the library recipes, creators and fields; the bundled catalog is unchanged', () => {
  const catalog = read(path.join(data, 'index.json'));
  const active = read(path.join(library, 'youtube.json')).recipes;
  const seed = catalog.recipes.filter((r) => r.catalogStatus === 'active').length;
  // The app bundles recipes/data: it stays exactly the seed it was.
  assert.equal(catalog.recipes.length, 789);
  assert.equal(seed, 495);
  const { files, manifest } = buildLibrary(data, { generatedAt: 'x', libraryDir: library });
  assert.equal(manifest.recipeCount, seed + active.length);
  assert.ok(files['creators.json']);
  const index = JSON.parse(files['index.json']);
  assert.equal(index.recipes.length, catalog.recipes.length + active.length);
  const groups = index.cuisineGroups.reduce((n, g) => n + g.count, 0);
  assert.equal(groups, manifest.recipeCount);
  const one = index.recipes.find((r) => r.id === active[0].id);
  assert.equal(one.creatorId, active[0].creatorId);
  assert.equal(one.video.id, active[0].video.id);
  const body = JSON.parse(files[`r/${one.body}.json`]);
  assert.deepEqual(body.video, active[0].video);
  assert.equal(body.importTag, undefined);
  assert.deepEqual(body.steps.map((s) => s.videoStartSec), active[0].steps.map((s) => s.videoStartSec));
  const ids = new Set(index.recipes.filter((r) => r.catalogStatus === 'active').map((r) => r.id));
  for (const d of JSON.parse(files['dishes.json']).dishes) {
    assert.ok(d.recipes.length >= 2, d.id);
    for (const id of d.recipes) assert.ok(ids.has(id), id);
  }
  // Without the library folder the build is the bundled catalog alone.
  assert.equal(buildLibrary(data, { generatedAt: 'x' }).manifest.recipeCount, seed);
});
