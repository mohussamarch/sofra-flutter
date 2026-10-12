import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { backoffMs, cursorFromArchive, inferCursor, isDue, makeJobs, runBatch } from './collect-incremental.mjs';

test('scheduler covers every category in both markets plus global pagination', () => {
  const jobs = makeJobs();
  assert.equal(jobs.length, 42);
  assert.equal(new Set(jobs.map(job => job.key)).size, 42);
  assert.deepEqual(jobs.slice(-2).map(job => job.key), ['egypt/global', 'saudi-arabia/global']);
});

test('archive source count advances pages and marks exhausted categories', () => {
  assert.deepEqual(cursorFromArchive({}, { count: 250 }, 1), { page: 2, done: false });
  assert.deepEqual(cursorFromArchive({}, { count: 250 }, 3), { page: 3, done: true });
  assert.deepEqual(cursorFromArchive({}, { count: '250', products: [] }, 2), { page: 3, done: false });
  assert.deepEqual(cursorFromArchive({}, { count: '100', products: [] }, 1), { page: 1, done: true });
  assert.deepEqual(cursorFromArchive({}, { products: Array(100).fill({}) }, 1), { page: 2, done: false });
  assert.deepEqual(cursorFromArchive({}, { products: Array(40).fill({}) }, 1), { page: 1, done: true });
  assert.equal(backoffMs('OFF 503', 0), 15 * 60_000);
  assert.equal(backoffMs('OFF 429', 1), 30 * 60_000);
  assert.equal(isDue({ nextAttemptAt: '2026-10-12T20:44:02.430Z' }, Date.parse('2026-10-12T20:44:02.429Z')), false);
  assert.equal(isDue({ nextAttemptAt: '2026-10-12T20:44:02.430Z' }, Date.parse('2026-10-12T20:44:02.430Z')), true);
});

test('inference resumes global page three from immutable page one and two archives', async () => {
  const out = await mkdtemp(path.join(os.tmpdir(), 'sofra-food-cursor-'));
  try {
    await mkdir(path.join(out, 'raw'));
    for (const page of [1, 2]) await writeFile(path.join(out, 'raw', `egypt-p${page}.json`), JSON.stringify({ count: 450, products: Array(100).fill({}) }));
    const cursor = await inferCursor(out, { key: 'egypt/global', country: 'egypt', categoryId: null });
    assert.equal(cursor.page, 3);
    assert.equal(cursor.done, false);
  } finally { await rm(out, { recursive: true, force: true }); }
});

test('cached full category page one advances, while a known exhausted source count stops', async () => {
  const out = await mkdtemp(path.join(os.tmpdir(), 'sofra-food-cache-pages-'));
  try {
    await mkdir(path.join(out, 'raw'));
    await writeFile(path.join(out, 'raw', 'egypt-sweets.json'), JSON.stringify({ products: Array(100).fill({}) }));
    const full = await inferCursor(out, { key: 'egypt/sweets', country: 'egypt', categoryId: 'sweets' });
    assert.equal(full.page, 2);
    assert.equal(full.done, false);
    await writeFile(path.join(out, 'raw', 'egypt-sweets.json'), JSON.stringify({ count: '72', products: Array(72).fill({}) }));
    const exhausted = await inferCursor(out, { key: 'egypt/sweets', country: 'egypt', categoryId: 'sweets' });
    assert.equal(exhausted.done, true);
  } finally { await rm(out, { recursive: true, force: true }); }
});

test('batch persists 503 backoff, rotates to a different job, and avoids rebuilds on failure', async () => {
  const out = await mkdtemp(path.join(os.tmpdir(), 'sofra-food-batch-'));
  let calls = 0;
  const now = Date.parse('2026-10-12T21:00:00.000Z');
  const fetchImpl = async url => {
    calls += 1;
    if (calls === 1) return new Response('busy', { status: 503 });
    const parsed = new URL(url);
    assert.notEqual(parsed.searchParams.get('tag_0'), 'egypt');
    return new Response(JSON.stringify({ count: 0, products: [] }), { status: 200, headers: { 'content-type': 'application/json' } });
  };
  try {
    const result = await runBatch({ out, maxRequests: 2, fetchImpl, nowMs: () => now, sleep: async () => {}, rebuild: false });
    assert.equal(calls, 2);
    assert.equal(result.results[0].status, 'failed');
    assert.equal(result.results[1].status, 'success');
    const state = JSON.parse(await readFile(path.join(out, 'collection-state.json'), 'utf8'));
    assert.equal(state.cursors['egypt/sweets'].nextAttemptAt, new Date(now + 15 * 60_000).toISOString());
    assert.equal(state.cursors['saudi-arabia/sweets'].done, true);
  } finally { await rm(out, { recursive: true, force: true }); }
});

test('all-failure batch uses production rebuild default and creates no manifest', async () => {
  const out = await mkdtemp(path.join(os.tmpdir(), 'sofra-food-failure-only-'));
  try {
    const result = await runBatch({ out, maxRequests: 1, nowMs: () => Date.parse('2026-10-12T21:00:00.000Z'), sleep: async () => {}, fetchImpl: async () => new Response('busy', { status: 503 }) });
    assert.equal(result.fetched, false);
    assert.equal(result.results[0].status, 'failed');
    await assert.rejects(readFile(path.join(out, 'manifest.json'), 'utf8'), { code: 'ENOENT' });
  } finally { await rm(out, { recursive: true, force: true }); }
});

test('cached category page one with fewer than 100 total products is exhausted without fetching page two', async () => {
  const out = await mkdtemp(path.join(os.tmpdir(), 'sofra-food-cache-'));
  try {
    await mkdir(path.join(out, 'raw'));
    await writeFile(path.join(out, 'raw', 'egypt-sweets.json'), JSON.stringify({ count: 40, products: Array(40).fill({}) }));
    const cursor = await inferCursor(out, { key: 'egypt/sweets', country: 'egypt', categoryId: 'sweets' });
    assert.equal(cursor.done, true);
    assert.equal(cursor.page, 1);
  } finally { await rm(out, { recursive: true, force: true }); }
});
