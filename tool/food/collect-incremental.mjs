import { mkdir, readFile, writeFile, readdir, open, stat, unlink } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { categories, fetchArchive, buildBank } from './import.mjs';

const markets = ['egypt', 'saudi-arabia'];
const baseState = () => ({ schemaVersion: 1, cursors: {}, failures: [], lastRequestAt: null, nextJobIndex: 0 });
const sleepReal = ms => new Promise(resolve => setTimeout(resolve, ms));
const archiveId = job => job.categoryId ? `${job.country}-${job.categoryId}-p${job.page}` : `${job.country}-p${job.page}`;

export function makeJobs() {
  return [...categories.flatMap(([categoryId, category]) => markets.map(country => ({ key: `${country}/${categoryId}`, country, categoryId, category }))),
    ...markets.map(country => ({ key: `${country}/global`, country, categoryId: null, category: null }))];
}

export function backoffMs(error, previousFailures = 0) {
  const text = String(error);
  return /OFF (429|503)/.test(text)
    ? Math.min(24 * 60 * 60_000, 15 * 60_000 * (2 ** previousFailures))
    : Math.min(6 * 60 * 60_000, 5 * 60_000 * (2 ** previousFailures));
}

export function isDue(cursor, nowMs) {
  return !cursor.done && (!cursor.nextAttemptAt || Date.parse(cursor.nextAttemptAt) <= nowMs);
}

export function cursorFromArchive(cursor, archive, page) {
  const next = { ...cursor, page, done: false };
  if (!archive) return next;
  const rawCount = archive.count;
  const count = typeof rawCount === 'number' ? rawCount : typeof rawCount === 'string' && /^\d+$/.test(rawCount) ? Number(rawCount) : null;
  const records = Array.isArray(archive.products) ? archive.products.length : 0;
  const more = count !== null ? count > page * 100 : records >= 100;
  if (more) next.page = page + 1;
  else next.done = true;
  return next;
}

async function readArchive(out, file) {
  try { return JSON.parse(await readFile(path.join(out, 'raw', file), 'utf8')); }
  catch (error) { if (error.code === 'ENOENT') return null; throw error; }
}

export async function inferCursor(out, job, saved = {}) {
  let cursor = { page: 1, done: false, failures: 0, nextAttemptAt: null, ...saved };
  if (saved.page) return cursor;
  for (let page = 1; ; page += 1) {
    const file = job.categoryId
      ? page === 1 ? `${job.country}-${job.categoryId}.json` : `${job.country}-${job.categoryId}-p${page}.json`
      : `${job.country}-p${page}.json`;
    const archive = await readArchive(out, file);
    if (!archive) { cursor.page = page; return cursor; }
    cursor = cursorFromArchive(cursor, archive, page);
    if (cursor.done) return cursor;
  }
}

export async function runBatch({ out, maxRequests = 6, fetchImpl = fetch, nowMs = () => Date.now(), sleep = sleepReal, rebuild = true, onProgress = () => {} }) {
  const statePath = path.join(out, 'collection-state.json');
  const state = await loadCheckpoint(statePath);
  Object.assign(state, { ...baseState(), ...state });
  state.cursors ??= {};
  state.failures ??= [];
  const jobs = makeJobs();
  const start = state.nextJobIndex % jobs.length;
  const results = [];
  let fetched = false;
  for (let offset = 0; offset < jobs.length && results.length < maxRequests; offset += 1) {
    const index = (start + offset) % jobs.length;
    const job = jobs[index];
    let cursor = await inferCursor(out, job, state.cursors[job.key]);
    state.cursors[job.key] = cursor;
    if (!isDue(cursor, nowMs())) continue;

    const id = archiveId({ ...job, page: cursor.page });
    const cached = await readArchive(out, `${id}.json`);
    if (cached) {
      cursor = cursorFromArchive(cursor, cached, cursor.page);
      state.cursors[job.key] = cursor;
      state.nextJobIndex = (index + 1) % jobs.length;
      await writeCheckpoint(statePath, state);
      continue;
    }

    const last = state.lastRequestAt ? Date.parse(state.lastRequestAt) : 0;
    const wait = Math.max(0, 8000 - (nowMs() - last));
    if (wait) await sleep(wait);
    try {
      const records = await fetchArchive(out, { country: job.country, category: job.category, page: cursor.page, id, fetchImpl, now: () => new Date(nowMs()).toISOString() });
      state.lastRequestAt = new Date(nowMs()).toISOString();
      const archive = await readArchive(out, `${id}.json`);
      const progressed = cursorFromArchive({ ...cursor, failures: 0, nextAttemptAt: null }, archive, cursor.page);
      state.cursors[job.key] = progressed;
      state.failures = state.failures.filter(f => f.key !== job.key);
      fetched = true;
      const result = { key: job.key, page: cursor.page, records, status: 'success', done: progressed.done };
      results.push(result);
      onProgress(result);
    } catch (error) {
      state.lastRequestAt = new Date(nowMs()).toISOString();
      const previous = cursor.failures ?? 0;
      const nextAttemptAt = new Date(nowMs() + backoffMs(error, previous)).toISOString();
      state.cursors[job.key] = { ...cursor, failures: previous + 1, nextAttemptAt };
      state.failures = [...state.failures.filter(f => f.key !== job.key), { key: job.key, page: cursor.page, error: String(error), at: new Date(nowMs()).toISOString(), nextAttemptAt }];
      const result = { key: job.key, page: cursor.page, status: 'failed', nextAttemptAt, error: error.message };
      results.push(result);
      onProgress(result);
    }
    state.nextJobIndex = (index + 1) % jobs.length;
    await writeCheckpoint(statePath, state);
  }
  if (results.length === 0) await writeCheckpoint(statePath, state);
  if (fetched && rebuild) await buildBank(out);
  return { state, results, fetched };
}

async function writeCheckpoint(file, state) {
  await mkdir(path.dirname(file), { recursive: true });
  const temp = `${file}.${process.pid}.tmp`;
  const serialized = JSON.stringify(state, null, 2) + '\n';
  await writeFile(temp, serialized);
  await writeFile(file, serialized);
  await unlink(temp).catch(() => {});
}

async function loadCheckpoint(file) {
  try { return JSON.parse(await readFile(file, 'utf8')); }
  catch (error) {
    if (error.code === 'ENOENT' || error instanceof SyntaxError) {
      const dir = path.dirname(file), prefix = `${path.basename(file)}.`, names = await readdir(dir).catch(() => []);
      const candidates = names.filter(name => name.startsWith(prefix) && name.endsWith('.tmp'));
      for (const name of candidates) {
        try { return JSON.parse(await readFile(path.join(dir, name), 'utf8')); } catch {}
      }
      if (error.code === 'ENOENT') return baseState();
    }
    throw error;
  }
}

export async function withCollectorLock(out, fn, { nowMs = () => Date.now() } = {}) {
  await mkdir(out, { recursive: true });
  const lockPath = path.join(out, 'collection.lock');
  let lock;
  try { lock = await open(lockPath, 'wx'); }
  catch (error) {
    if (error.code !== 'EEXIST') throw error;
    const info = await stat(lockPath).catch(() => null);
    if (!info || nowMs() - info.mtimeMs < 15 * 60_000) throw new Error('Collector lock is active; no request made.');
    await unlink(lockPath).catch(() => {});
    lock = await open(lockPath, 'wx');
  }
  try { return await fn(); }
  finally { await lock.close(); await unlink(lockPath).catch(() => {}); }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const out = path.resolve(process.argv[2] ?? path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../data/food/openfoodfacts'));
  await withCollectorLock(out, async () => {
    const result = await runBatch({ out, onProgress: item => console.log(JSON.stringify(item)) });
    console.log(JSON.stringify({ requests: result.results.length, fetched: result.fetched, nextJobIndex: result.state.nextJobIndex }));
  });
}
