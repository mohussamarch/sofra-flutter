import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildLibrary, imageFields, publish, sha256 } from './publish-library.mjs';

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
