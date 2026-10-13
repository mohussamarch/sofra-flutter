import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile, rm, mkdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve } from 'node:path';
import { collect, parseRecipePage, pageRecord } from './collect-wikibooks.mjs';

const page = {
  pageid: 17001,
  ns: 102,
  title: 'Cookbook:Example Soup',
  categories: [
    { title: 'Category:Recipes' },
    { title: 'Category:Egyptian recipes' },
    { title: 'Category:Recipes using lentil' },
  ],
  revisions: [{
    revid: 45123,
    timestamp: '2025-06-19T02:57:00Z',
    user: 'ExampleEditor',
    slots: { main: { content: `{{Recipe\n|servings=4\n}}\n== Ingredients ==\n* 1 cup lentils\n* Salt to taste\n== Procedure ==\n# Rinse lentils.\n# Simmer until tender.\n[[Category:Egyptian recipes]]` } },
  }],
};

test('parses only source-section ingredient and procedure lines', () => {
  const parsed = parseRecipePage(page.revisions[0].slots.main.content);
  assert.deepEqual(parsed.ingredients, ['1 cup lentils', 'Salt to taste']);
  assert.deepEqual(parsed.steps, ['Rinse lentils.', 'Simmer until tender.']);
  assert.equal(parsed.servingsText, '4');
});

test('preserves revision, actual categories, stable permalink and source hash', () => {
  const record = pageRecord(page, '2026-10-13T11:13:54Z');
  assert.equal(record.sourceRevision, '45123');
  assert.match(record.sourceUrl, /oldid=45123$/);
  assert.deepEqual(record.sourceCategories, ['Category:Egyptian recipes', 'Category:Recipes', 'Category:Recipes using lentil']);
  assert.match(record.sourceSha256, /^[a-f0-9]{64}$/);
  assert.equal(record.recipe.servings, null);
  assert.deepEqual(record.recipe.ingredients[0], { id: 'source-line-1', sourceText: '1 cup lentils', amountText: '1 cup lentils', name: '1 cup lentils', amount: null, unit: null, foodBinding: null });
  assert.equal(record.license.id, 'wikibooks-cookbook-cc-by-sa-4.0');
  assert.equal(record.license.changeNoticeRequired, true);
});

test('non-recipe pages are retained as source records but parser reports no recipe sections', () => {
  const parsed = parseRecipePage('== Overview ==\nA broad overview.');
  assert.deepEqual(parsed.ingredients, []);
  assert.deepEqual(parsed.steps, []);
});

test('includes nested ingredient and procedure subsections but ignores comments and nowiki examples', () => {
  const parsed = parseRecipePage(`== Ingredients ==
=== Dough ===
* flour
<!-- * fake comment ingredient -->
<nowiki>* fake nowiki ingredient</nowiki>
=== Filling ===
* dates
== Procedure ==
=== Preparation ===
# Mix the dough.
=== Assembly ===
# Fill and fold.
== Notes ==
# Not a recipe step.
<!-- == Ingredients ==\n* hidden -->`);
  assert.deepEqual(parsed.ingredients, ['flour', 'dates']);
  assert.deepEqual(parsed.steps, ['Mix the dough.', 'Fill and fold.']);
});

test('recognizes cooking as a source procedure section', () => {
  const parsed = parseRecipePage('== Cooking ==\n# Heat gently.\n# Serve warm.');
  assert.deepEqual(parsed.steps, ['Heat gently.', 'Serve warm.']);
});

function makePage(pageid, title, category, suffix = 'Soup') {
  return {
    pageid, ns: 102, title: `Cookbook:${title}`,
    categories: [{ title: 'Category:Recipes' }, { title: `Category:${category}` }],
    revisions: [{ revid: 45000 + pageid, timestamp: '2025-06-19T02:57:00Z', user: 'Editor', slots: { main: { content: `== Ingredients ==\n* 1 cup lentils\n== Procedure ==\n# Cook ${suffix}.` } } }],
  };
}

function response(pages, continuation) {
  return { query: { pages: Object.fromEntries(pages.map((p) => [p.pageid, p])) }, ...(continuation ? { continue: continuation } : {}) };
}

function fakeFetch(sequence) {
  let calls = 0;
  const fetch = async (url) => {
    const item = sequence[calls++];
    if (item instanceof Error) throw item;
    assert.ok(item, 'unexpected fake API request');
    return { ok: true, json: async () => item };
  };
  return { fetch, calls: () => calls };
}

async function tempOutput(t) {
  const root = await mkdtemp(resolve(tmpdir(), 'sofra-wikibooks-'));
  t.after(() => rm(root, { recursive: true, force: true }));
  return root;
}

test('collects sequential pages, preserves continuation/categories, and resets per-run request count', async (t) => {
  const out = await tempOutput(t);
  const api = fakeFetch([
    response([makePage(1, 'Alpha', 'Egyptian recipes'), makePage(2, 'Beta', 'Nigerian recipes')], { continue: '-||', gcmcontinue: 'page|x' }),
    response([makePage(3, 'Gamma', 'Saudi recipes')]),
  ]);
  const first = await collect({ out, limit: 2 }, { fetch: api.fetch, wait: async () => {} });
  assert.equal(first.collection.sourceRevisionRecords, 2);
  assert.equal(first.collection.distinctSourcePages, 2);
  assert.equal(first.collection.parseableRecipePages, 2);
  assert.equal(first.collection.apiRequestsThisRun, 1);
  assert.equal(first.sourceExhausted, false);
  const second = await collect({ out, limit: 3, resume: true }, { fetch: api.fetch, wait: async () => {} });
  assert.equal(second.collection.sourceRevisionRecords, 3);
  assert.equal(second.collection.distinctSourcePages, 3);
  assert.equal(second.collection.apiRequestsThisRun, 1);
  assert.equal(second.collection.apiRequestsCumulative, 2);
  const lines = (await readFile(resolve(out, 'source-pages.jsonl'), 'utf8')).trim().split(/\r?\n/).map(JSON.parse);
  assert.equal(lines.length, 3);
  assert.deepEqual(lines[0].sourceCategories, ['Category:Egyptian recipes', 'Category:Recipes']);
  assert.equal(lines[0].sourceWikitext.includes('Cook Soup.'), true);
});

test('counts distinct recipe pages separately from immutable revision records', async (t) => {
  const out = await tempOutput(t);
  const original = makePage(42, 'Versioned', 'Egyptian recipes');
  const revised = structuredClone(original);
  revised.revisions[0].revid += 1;
  revised.revisions[0].slots.main.content += '\n<!-- revised -->';
  const api = fakeFetch([
    response([original], { continue: '-||', gcmcontinue: 'next' }),
    response([revised]),
  ]);
  const result = await collect({ out, limit: 2 }, { fetch: api.fetch, wait: async () => {} });
  assert.equal(result.collection.sourceRevisionRecords, 2);
  assert.equal(result.collection.distinctSourcePages, 1);
  assert.equal(result.collection.parseableRecipePages, 1);
});

test('keeps split category observations for a revision and forwards full API continuation', async (t) => {
  const out = await tempOutput(t);
  const firstPage = makePage(77, 'Split categories', 'Egyptian recipes');
  firstPage.revisions[0].revid = 77777;
  const secondPage = structuredClone(firstPage);
  secondPage.categories = [{ title: 'Category:Recipes' }, { title: 'Category:Nigerian recipes' }];
  const urls = [];
  const sequence = [
    response([firstPage], { continue: '||revisions', clcontinue: '77|A' }),
    response([secondPage]),
  ];
  const result = await collect({ out, limit: 2 }, {
    fetch: async (url) => {
      urls.push(new URL(url));
      const payload = sequence.shift();
      return { ok: true, json: async () => payload };
    },
    wait: async () => {},
  });
  assert.equal(urls[0].searchParams.get('cllimit'), '500');
  assert.equal(urls[1].searchParams.get('continue'), '||revisions');
  assert.equal(urls[1].searchParams.get('clcontinue'), '77|A');
  const records = (await readFile(resolve(out, 'source-pages.jsonl'), 'utf8')).trim().split(/\r?\n/).map(JSON.parse);
  assert.equal(records.length, 1);
  assert.deepEqual(records[0].sourceCategories, ['Category:Egyptian recipes', 'Category:Recipes']);
  const observations = (await readFile(resolve(out, 'category-observations.jsonl'), 'utf8')).trim().split(/\r?\n/).map(JSON.parse);
  assert.equal(observations.length, 2);
  assert.deepEqual(observations.map((item) => item.categories).sort((a, b) => a.join().localeCompare(b.join())), [
    ['Category:Egyptian recipes', 'Category:Recipes'],
    ['Category:Nigerian recipes', 'Category:Recipes'],
  ]);
  assert.deepEqual(result.sourceCategoryCounts, {
    'Category:Egyptian recipes': 1,
    'Category:Nigerian recipes': 1,
    'Category:Recipes': 1,
  });
  assert.ok(result.firstSuccessfulRetrievalAt);
  assert.ok(result.lastSuccessfulRetrievalAt);
  assert.notEqual(result.collectionStartedAt, result.firstSuccessfulRetrievalAt);
});

test('persists errors and enforces a ten-minute cooldown without making another request', async (t) => {
  const out = await tempOutput(t);
  const base = new Date('2026-10-13T12:01:43Z');
  const api = fakeFetch([new Error('simulated source error')]);
  await assert.rejects(collect({ out, limit: 1 }, { fetch: api.fetch, now: () => new Date(base), wait: async () => {} }), /simulated source error/);
  const checkpoint = JSON.parse(await readFile(resolve(out, 'checkpoint.json'), 'utf8'));
  assert.equal(checkpoint.nextAttemptAt, '2026-10-13T12:11:43.000Z');
  assert.match(checkpoint.lastError.message, /simulated source error/);
  const early = new Date('2026-10-13T12:11:42Z');
  await assert.rejects(collect({ out, limit: 1, resume: true }, { fetch: api.fetch, now: () => new Date(early) }), /cooldown active/);
  assert.equal(api.calls(), 1);
});

test('honors Retry-After while retaining the ten-minute minimum and cancels the response body', async (t) => {
  const out = await tempOutput(t);
  const base = new Date('2026-10-13T12:20:00Z');
  let cancelled = false;
  const api = fakeFetch([]);
  const fetchImpl = async () => ({
    ok: false,
    status: 429,
    headers: { get: (name) => name.toLowerCase() === 'retry-after' ? '900' : null },
    body: { cancel: async () => { cancelled = true; } },
  });
  await assert.rejects(collect({ out, limit: 1 }, { fetch: fetchImpl, now: () => new Date(base) }), /HTTP 429/);
  const checkpoint = JSON.parse(await readFile(resolve(out, 'checkpoint.json'), 'utf8'));
  assert.equal(checkpoint.nextAttemptAt, '2026-10-13T12:35:00.000Z');
  assert.equal(checkpoint.retryAfterMs, 900000);
  assert.equal(cancelled, true);
});

test('paces successful source requests by at least two seconds', async (t) => {
  const out = await tempOutput(t);
  const api = fakeFetch([
    response([makePage(61, 'Paced one', 'Egyptian recipes')], { continue: '||revisions', gcmcontinue: 'next' }),
    response([makePage(62, 'Paced two', 'Nigerian recipes')]),
  ]);
  const waits = [];
  await collect({ out, limit: 2 }, {
    fetch: api.fetch,
    now: () => new Date('2026-10-13T12:00:00Z'),
    wait: async (ms) => { waits.push(ms); },
  });
  assert.ok(waits.some((ms) => ms >= 2000), `expected a >=2000ms source gate, got ${waits}`);
});

test('recovers append-before-checkpoint crash without duplicate revisions', async (t) => {
  const out = await tempOutput(t);
  const batch = response([makePage(11, 'Recovered', 'Egyptian recipes')], { continue: '-||', gcmcontinue: 'page|next' });
  const firstApi = fakeFetch([batch]);
  let interrupted = false;
  const initialTime = new Date('2026-10-13T12:00:00Z');
  await assert.rejects(collect({ out, limit: 1 }, {
    fetch: firstApi.fetch, now: () => new Date(initialTime), wait: async () => {},
    afterAppend: async () => { if (!interrupted) { interrupted = true; throw new Error('simulated crash after append'); } },
  }), /simulated crash/);
  const resumeTime = new Date('2026-10-13T12:11:00Z');
  const resumeApi = fakeFetch([batch, response([makePage(12, 'After recovery', 'Nigerian recipes')])]);
  const result = await collect({ out, limit: 1, resume: true }, { fetch: resumeApi.fetch, now: () => new Date(resumeTime), wait: async () => {} });
  assert.equal(result.collection.sourceRevisionRecords, 2);
  const lines = (await readFile(resolve(out, 'source-pages.jsonl'), 'utf8')).trim().split(/\r?\n/);
  assert.equal(lines.length, 2);
  assert.equal(lines.map(JSON.parse).filter((line) => line.sourcePageId === 11).length, 1);
  assert.equal(resumeApi.calls(), 2);
});

test('does not re-fetch an exhausted source on resume', async (t) => {
  const out = await tempOutput(t);
  const api = fakeFetch([response([makePage(20, 'Final', 'Egyptian recipes')])]);
  const first = await collect({ out, limit: 5 }, { fetch: api.fetch, wait: async () => {} });
  assert.equal(first.sourceExhausted, true);
  const second = await collect({ out, limit: 10, resume: true }, { fetch: api.fetch });
  assert.equal(second.sourceExhausted, true);
  assert.equal(api.calls(), 1);
});

test('exclusive lock prevents concurrent collection', async (t) => {
  const out = await tempOutput(t);
  await mkdir(out, { recursive: true });
  await writeFile(resolve(out, 'collector.lock'), '{"pid":7}');
  const api = fakeFetch([]);
  await assert.rejects(collect({ out, limit: 1 }, { fetch: api.fetch }), /Collector lock exists/);
  assert.equal(api.calls(), 0);
});

test('preserves partial category continuation while fetching missing page content by ID', async (t) => {
  const out = await tempOutput(t);
  const missing = makePage(32, 'Deferred', 'Saudi recipes');
  delete missing.revisions;
  const api = fakeFetch([
    response([makePage(31, 'First', 'Egyptian recipes'), missing], { continue: '-||', gcmcontinue: 'page|deferred' }),
    response([makePage(32, 'Deferred', 'Saudi recipes')]),
    response([makePage(33, 'Third', 'Japanese recipes')]),
  ]);
  const result = await collect({ out, limit: 3 }, { fetch: api.fetch, wait: async () => {} });
  assert.equal(result.collection.sourceRevisionRecords, 3);
  assert.equal(result.collection.apiRequestsThisRun, 3);
  const lines = (await readFile(resolve(out, 'source-pages.jsonl'), 'utf8')).trim().split(/\r?\n/).map(JSON.parse);
  assert.deepEqual(lines.map((line) => line.sourcePageId), [31, 32, 33]);
  assert.deepEqual(lines[1].sourceCategories, ['Category:Recipes', 'Category:Saudi recipes']);
});

test('rejects wrong namespace, missing revision and empty content', () => {
  const wrongNamespace = makePage(40, 'Wrong', 'Egyptian recipes');
  wrongNamespace.ns = 0;
  assert.throws(() => pageRecord(wrongNamespace, '2026-10-13T12:00:00Z'), /Unexpected source namespace/);
  const noRevision = makePage(41, 'No revision', 'Egyptian recipes');
  noRevision.revisions = [];
  assert.throws(() => pageRecord(noRevision, '2026-10-13T12:00:00Z'), /Missing source revision/);
  const noContent = makePage(42, 'No content', 'Egyptian recipes');
  noContent.revisions[0].slots.main.content = '';
  assert.throws(() => pageRecord(noContent, '2026-10-13T12:00:00Z'), /Missing source content/);
});

test('stores complete licensed source pages even when parser finds no recipe sections', async (t) => {
  const out = await tempOutput(t);
  const unparsed = makePage(50, 'Glossary', 'Ingredients');
  unparsed.revisions[0].slots.main.content = '== Overview ==\nA source page with no recipe sections.';
  const api = fakeFetch([response([unparsed])]);
  const result = await collect({ out, limit: 1 }, { fetch: api.fetch, wait: async () => {} });
  assert.equal(result.collection.sourceRevisionRecords, 1);
  assert.equal(result.collection.distinctSourcePages, 1);
  assert.equal(result.collection.parseableRecipePages, 0);
  assert.deepEqual(result.sourceCategoryCounts, { 'Category:Ingredients': 1, 'Category:Recipes': 1 });
  const record = JSON.parse((await readFile(resolve(out, 'source-pages.jsonl'), 'utf8')).trim());
  assert.equal(record.isRecipe, false);
  assert.equal(record.sourceWikitext, '== Overview ==\nA source page with no recipe sections.');
  assert.match(record.sourceSha256, /^[a-f0-9]{64}$/);
});
