import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildLibrary, imageFields, publish, sha256, validateCatalog } from './publish-library.mjs';

const data = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', 'recipes', 'data');

test('same recipes give the same library, bodies are content addressed', () => {
  const a = buildLibrary(data, { generatedAt: '2026-11-20T00:00:00.000Z' });
  const b = buildLibrary(data, { generatedAt: '2026-11-20T00:00:00.000Z' });
  assert.deepEqual(a.manifest, b.manifest);
  assert.deepEqual(Object.keys(a.files), Object.keys(b.files));
  for (const [name, text] of Object.entries(a.files)) {
    if (name.startsWith('r/')) assert.equal(name, `r/${sha256(text)}.json`);
  }
  for (const [name, entry] of Object.entries(a.manifest.files)) {
    assert.equal(entry.sha256, sha256(a.files[name]));
  }
});

test('index rows carry their body hash and, when active, listing ingredients', () => {
  const { files, manifest } = buildLibrary(data, { generatedAt: 'x' });
  const index = JSON.parse(files['index.json']);
  const active = index.recipes.filter((r) => r.catalogStatus === 'active');
  assert.equal(manifest.recipeCount, active.length);
  assert.equal(manifest.bodies.count, index.recipes.length);
  for (const row of index.recipes) {
    const body = JSON.parse(files[`r/${row.body}.json`]);
    assert.equal(body.id, row.id);
    if (row.catalogStatus === 'active') {
      assert.equal(row.ingredients.length, body.ingredients.length);
      for (const line of row.ingredients) {
        assert.ok(line.id && line.name);
        assert.ok(!('note' in line) && !('label' in line));
        // An unmeasured line never scales (the app rejects it otherwise).
        if (line.amount === null) assert.equal(line.scale, false);
      }
    } else {
      assert.equal(row.ingredients, undefined);
    }
  }
});

test('an unchanged library keeps its timestamp; a changed one gets a new one', () => {
  const out = fs.mkdtempSync(path.join(os.tmpdir(), 'sofra-lib-'));
  const first = publish(data, out, { generatedAt: '2026-01-01T00:00:00.000Z' });
  const again = publish(data, out);
  assert.equal(again.generatedAt, first.generatedAt);
  assert.equal(again.version, first.version);
  const written = JSON.parse(fs.readFileSync(path.join(out, 'manifest.json'), 'utf8'));
  assert.deepEqual(written, again);
  const copy = fs.mkdtempSync(path.join(os.tmpdir(), 'sofra-data-'));
  for (const f of fs.readdirSync(data)) fs.copyFileSync(path.join(data, f), path.join(copy, f));
  const dishes = JSON.parse(fs.readFileSync(path.join(copy, 'dishes.json'), 'utf8'));
  dishes.dishes.pop();
  fs.writeFileSync(path.join(copy, 'dishes.json'), JSON.stringify(dishes));
  const changed = publish(copy, out);
  assert.notEqual(changed.version, first.version);
  assert.notEqual(changed.generatedAt, first.generatedAt);
  fs.rmSync(out, { recursive: true, force: true });
  fs.rmSync(copy, { recursive: true, force: true });
});

test('image references are text only, checked, and carried by the index row', () => {
  const ok = imageFields(
    { id: 'x', thumbnail: 'img/x.webp' },
    { photos: ['img/x-1.webp', 'https://cdn.example/x-2.webp'] },
  );
  assert.deepEqual(ok, { thumbnail: 'img/x.webp', photos: ['img/x-1.webp', 'https://cdn.example/x-2.webp'] });
  assert.deepEqual(imageFields({ id: 'y' }, {}), {});
  for (const bad of ['http://insecure/x.jpg', 'img/../x.webp', 'javascript:alert(1)', 'img/x.gif']) {
    assert.throws(() => imageFields({ id: 'z', thumbnail: bad }, {}), /bad thumbnail/);
    assert.throws(() => imageFields({ id: 'z' }, { photos: [bad] }), /bad photos/);
  }
  // Today's catalog has no images, so no row carries image fields yet.
  const index = JSON.parse(buildLibrary(data, { generatedAt: 'x' }).files['index.json']);
  assert.ok(index.recipes.every((r) => !('thumbnail' in r) && !('photos' in r)));
});

const copyData = () => {
  const copy = fs.mkdtempSync(path.join(os.tmpdir(), 'sofra-data-'));
  for (const f of fs.readdirSync(data)) fs.copyFileSync(path.join(data, f), path.join(copy, f));
  return copy;
};

test('a catalog the app would reject is never published', () => {
  const copy = copyData();
  const file = path.join(copy, 'index.json');
  const original = fs.readFileSync(file, 'utf8');
  const index = JSON.parse(original);
  index.cuisineGroups[0].count += 1;
  fs.writeFileSync(file, JSON.stringify(index));
  assert.throws(() => buildLibrary(copy, { generatedAt: 'x' }), /count/);
  const fewer = JSON.parse(original);
  fewer.cuisineGroups.pop();
  fs.writeFileSync(file, JSON.stringify(fewer));
  assert.throws(() => buildLibrary(copy, { generatedAt: 'x' }), /15 primary/);
  const grouped = JSON.parse(original);
  grouped.recipes.find((r) => r.catalogStatus !== 'active').cuisineGroup = grouped.cuisineGroups[0].id;
  fs.writeFileSync(file, JSON.stringify(grouped));
  assert.throws(() => buildLibrary(copy, { generatedAt: 'x' }), /held recipe/);
  const published = JSON.parse(buildLibrary(data, { generatedAt: 'x' }).files['index.json']);
  published.recipes.find((r) => r.ingredients).ingredients[0].scale = undefined;
  published.recipes.find((r) => r.ingredients).ingredients[0].amount = null;
  assert.throws(() => validateCatalog(published), /unmeasured but scales/);
  fs.rmSync(copy, { recursive: true, force: true });
});

test('--out never wipes the repository, the data or an unrelated folder', () => {
  const root = path.resolve(data, '..', '..');
  assert.throws(() => publish(data, root), /refusing/);
  assert.throws(() => publish(data, data), /refusing/);
  assert.throws(() => publish(data, path.dirname(data)), /refusing/);
  const other = fs.mkdtempSync(path.join(os.tmpdir(), 'sofra-other-'));
  fs.writeFileSync(path.join(other, 'keep.txt'), 'mine');
  assert.throws(() => publish(data, other), /not empty/);
  assert.equal(fs.readFileSync(path.join(other, 'keep.txt'), 'utf8'), 'mine');
  fs.rmSync(other, { recursive: true, force: true });
});

test('the previous build bodies stay one more version for phones on the old catalog', () => {
  const out = fs.mkdtempSync(path.join(os.tmpdir(), 'sofra-lib-'));
  const copy = copyData();
  const first = JSON.parse(buildLibrary(copy, { generatedAt: 'x' }).files['index.json']);
  publish(copy, out, { generatedAt: '2026-01-01T00:00:00.000Z' });
  const row = first.recipes.find((r) => r.catalogStatus === 'active');
  const cuisine = path.join(copy, row.file);
  const change = (note) => {
    const body = JSON.parse(fs.readFileSync(cuisine, 'utf8'));
    body.recipes.find((r) => r.id === row.id).notes = note;
    fs.writeFileSync(cuisine, JSON.stringify(body));
  };
  change('second');
  publish(copy, out, { generatedAt: '2026-01-02T00:00:00.000Z' });
  const second = JSON.parse(fs.readFileSync(path.join(out, 'index.json'), 'utf8'));
  const secondSha = second.recipes.find((r) => r.id === row.id).body;
  assert.notEqual(secondSha, row.body);
  assert.ok(fs.existsSync(path.join(out, 'r', `${row.body}.json`)), 'old body kept');
  assert.ok(fs.existsSync(path.join(out, 'r', `${secondSha}.json`)));
  change('third');
  publish(copy, out, { generatedAt: '2026-01-03T00:00:00.000Z' });
  assert.ok(!fs.existsSync(path.join(out, 'r', `${row.body}.json`)), 'two versions back removed');
  assert.ok(fs.existsSync(path.join(out, 'r', `${secondSha}.json`)));
  fs.rmSync(out, { recursive: true, force: true });
  fs.rmSync(copy, { recursive: true, force: true });
});
