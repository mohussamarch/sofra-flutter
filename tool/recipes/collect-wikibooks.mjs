#!/usr/bin/env node
import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile, appendFile, access, open, unlink } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(HERE, '../..');
const API = 'https://en.wikibooks.org/w/api.php';
const CATEGORY = 'Category:Recipes';
const PAGE_NAMESPACE = 102;
const MAX_API_REQUESTS = 10;
const MAX_PAGES_PER_REQUEST = 50;
const COOLDOWN_MS = 10 * 60 * 1000;
const MIN_REQUEST_INTERVAL_MS = 2 * 1000;

const LICENSE = Object.freeze({
  id: 'wikibooks-cookbook-cc-by-sa-4.0',
  name: 'Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0); Wikibooks text is generally dual-licensed with GFDL unless otherwise noted',
  evidenceUrl: 'https://en.wikibooks.org/wiki/Wikibooks:Copyrights',
  policyStatus: 'verified-license',
  pageExceptionStatus: 'not-reviewed-per-page',
  attribution: 'Attribute Wikibooks contributors by linking each version-specific source page. Indicate that structured fields are extracted and any translated or edited text is modified. Include CC BY-SA 4.0 notice/link and share adaptations under CC BY-SA 4.0 or later.',
  changeNoticeRequired: true,
  shareAlikeRequired: true,
});

function sha256(value) {
  return createHash('sha256').update(value, 'utf8').digest('hex');
}

function sourceCounts(records) {
  return {
    revisionRecords: records.length,
    distinctSourcePages: new Set(records.map((record) => String(record.sourcePageId))).size,
    parseableRecipePages: new Set(records.filter((record) => record.isRecipe).map((record) => String(record.sourcePageId))).size,
  };
}

function stripMarkup(line) {
  return line.trim()
    .replace(/^\s*[*#;:]+\s*/, '')
    .replace(/'''?([^']+)'''?/g, '$1')
    .replace(/\[\[([^\]|]+)\|([^\]]+)\]\]/g, '$2')
    .replace(/\[\[([^\]]+)\]\]/g, '$1')
    .replace(/\[https?:\/\/\S+\s+([^\]]+)\]/g, '$1')
    .replace(/<[^>]*>/g, '')
    .replace(/\{\{[^{}]*\}\}/g, '')
    .replace(/&nbsp;/g, ' ')
    .trim();
}

function sectionLines(wikitext, headingNames) {
  const names = new Set(headingNames.map((name) => name.toLowerCase()));
  const collected = [];
  let rootLevel = null;
  for (const line of wikitext.split(/\r?\n/)) {
    const heading = line.match(/^\s*(={2,6})\s*(.*?)\s*\1\s*$/);
    if (heading) {
      const title = stripMarkup(heading[2]).toLowerCase();
      const level = heading[1].length;
      if (rootLevel !== null && level <= rootLevel) rootLevel = null;
      if (rootLevel === null && names.has(title)) rootLevel = level;
      continue;
    }
    if (rootLevel === null || !/^\s*[*#]+\s*/.test(line)) continue;
    const clean = stripMarkup(line);
    if (clean) collected.push(clean);
  }
  return collected;
}

export function parseRecipePage(wikitext) {
  const parseableWikitext = wikitext
    .replace(/<!--([\s\S]*?)-->/g, '')
    .replace(/<nowiki\b[^>]*>[\s\S]*?<\/nowiki\s*>/gi, '')
    .replace(/<nowiki\b[^>]*\/\s*>/gi, '');
  const ingredients = sectionLines(parseableWikitext, ['ingredients', 'what you need']);
  const steps = sectionLines(parseableWikitext, ['procedure', 'directions', 'method', 'instructions', 'preparation', 'cooking']);
  const servingsText = parseableWikitext.match(/^\s*\|\s*servings\s*=\s*([^\n|]+)/im)?.[1]?.trim() ?? null;
  return { ingredients, steps, servingsText };
}

function sourceWikitext(page) {
  return page.revisions?.[0]?.slots?.main?.content
    ?? page.revisions?.[0]?.slots?.main?.['*']
    ?? '';
}

function pageUrl(title, revisionId) {
  return `https://en.wikibooks.org/w/index.php?title=${encodeURIComponent(title).replaceAll('%3A', ':')}&oldid=${revisionId}`;
}

function recipeFields(title, parsed) {
  return {
    name: title.replace(/^Cookbook:/, ''),
    nameAr: null,
    servings: null,
    servingsSourceText: parsed.servingsText,
    ingredients: parsed.ingredients.map((sourceText, index) => ({
      id: `source-line-${index + 1}`,
      name: sourceText,
      sourceText,
      amountText: sourceText,
      amount: null,
      unit: null,
      foodBinding: null,
    })),
    steps: parsed.steps.map((sourceText, index) => ({
      n: index + 1,
      text: sourceText,
      sourceText,
      durationMinutes: null,
    })),
    nutrition: null,
    gaps: [
      'Research extraction only; no culinary/editorial review.',
      'Ingredient quantities, units, alternatives, food identities, aggregate duration, and nutrition remain unknown until individually parsed/reviewed.',
      'Source-level CC BY-SA policy applies generally; page-specific exceptions have not been checked.',
    ],
  };
}

export function pageRecord(page, retrievedAt) {
  const revision = page.revisions?.[0];
  if (page.ns !== PAGE_NAMESPACE) throw new Error(`Unexpected source namespace for ${page.title}`);
  if (!revision?.revid) throw new Error(`Missing source revision for ${page.title}`);
  const raw = sourceWikitext(page);
  if (typeof raw !== 'string' || raw.length === 0) throw new Error(`Missing source content for ${page.title}`);
  const parsed = parseRecipePage(raw);
  const sourcePageUrl = pageUrl(page.title, revision.revid);
  const categories = (page.categories ?? []).map((entry) => entry.title).sort();
  return {
    schemaVersion: 1,
    recordId: `wikibooks-${page.pageid}-r${revision.revid}`,
    sourceId: 'wikibooks-cookbook-cc-by-sa',
    sourceTitle: page.title,
    sourcePageId: page.pageid,
    sourceRevision: String(revision.revid),
    sourceRevisionTimestamp: revision.timestamp,
    sourceRevisionUser: revision.user ?? null,
    sourceUrl: sourcePageUrl,
    retrievedAt,
    sourceCategories: categories,
    license: { ...LICENSE },
    sourceSha256: sha256(raw),
    sourceWikitext: raw,
    isRecipe: parsed.ingredients.length > 0 && parsed.steps.length > 0,
    recipe: recipeFields(page.title, parsed),
  };
}

async function fetchApiPage({ continuation, limit, pendingPageIds }, fetchImpl = fetch) {
  const url = new URL(API);
  const params = pendingPageIds?.length
    ? {
      action: 'query', pageids: pendingPageIds.slice(0, MAX_PAGES_PER_REQUEST).join('|'),
      prop: 'categories|revisions', cllimit: '500', rvprop: 'ids|timestamp|user|content',
      rvslots: 'main', maxlag: '5', format: 'json', formatversion: '2',
    }
    : {
      action: 'query', generator: 'categorymembers', gcmtitle: CATEGORY,
      gcmnamespace: String(PAGE_NAMESPACE), gcmtype: 'page',
      gcmlimit: String(Math.min(MAX_PAGES_PER_REQUEST, limit)),
      prop: 'categories|revisions', cllimit: '500', rvprop: 'ids|timestamp|user|content',
      rvslots: 'main', maxlag: '5', format: 'json', formatversion: '2',
    };
  for (const [key, value] of Object.entries(params)) url.searchParams.set(key, value);
  if (continuation) {
    for (const [key, value] of Object.entries(continuation)) {
      url.searchParams.set(key, value);
    }
  }
  const response = await fetchImpl(url, {
    headers: { 'user-agent': 'SofraResearchCollector/1.0 (research-only; contact via repository handoff)' },
  });
  if (!response.ok) {
    const error = new Error(`MediaWiki API HTTP ${response.status}; stop and respect source backoff.`);
    const retryAfter = response.headers?.get?.('retry-after');
    if (retryAfter) {
      const seconds = Number(retryAfter);
      const retryTime = Number.isFinite(seconds)
        ? Date.now() + Math.max(0, seconds) * 1000
        : Date.parse(retryAfter);
      if (Number.isFinite(retryTime)) error.retryAfterMs = Math.max(0, retryTime - Date.now());
    }
    try { await response.body?.cancel?.(); } catch { /* response body cancellation is best-effort */ }
    throw error;
  }
  const json = await response.json();
  if (json.error) throw new Error(`MediaWiki API ${json.error.code}: ${json.error.info}; stop and respect source backoff.`);
  return json;
}

function parseArgs(argv) {
  const options = { limit: 500, out: resolve(ROOT, 'data/recipes/bulk/wikibooks-cookbook'), resume: false };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--limit') options.limit = Number(argv[++i]);
    else if (argv[i] === '--out') options.out = resolve(argv[++i]);
    else if (argv[i] === '--resume') options.resume = true;
    else if (argv[i] === '--help') options.help = true;
    else throw new Error(`Unknown argument: ${argv[i]}`);
  }
  if (!Number.isInteger(options.limit) || options.limit < 1) {
    throw new Error('--limit must be a positive integer (new source pages to process this run).');
  }
  return options;
}

async function exists(path) {
  try { await access(path); return true; } catch { return false; }
}

async function atomicJson(path, value) {
  // A single writer holds collector.lock. Keep checkpoint writes small and portable
  // across Windows; JSONL records are append-only and hash-verified on recovery.
  await writeFile(path, JSON.stringify(value, null, 2) + '\n', 'utf8');
}

async function readRecords(recordsPath) {
  if (!await exists(recordsPath)) return [];
  const raw = await readFile(recordsPath, 'utf8');
  const records = [];
  const known = new Map();
  for (const [index, line] of raw.split(/\r?\n/).entries()) {
    if (!line.trim()) continue;
    const record = JSON.parse(line);
    if (typeof record.recordId !== 'string' || sha256(record.sourceWikitext) !== record.sourceSha256) {
      throw new Error(`Stored source revision/hash invalid at JSONL line ${index + 1}.`);
    }
    const previous = known.get(record.recordId);
    if (previous && previous !== record.sourceSha256) throw new Error(`Conflicting source hash for ${record.recordId}.`);
    if (!previous) {
      known.set(record.recordId, record.sourceSha256);
      records.push(record);
    }
  }
  if (records.length !== raw.split(/\r?\n/).filter((line) => line.trim()).length) {
    await writeFile(recordsPath, records.map((record) => JSON.stringify(record)).join('\n') + '\n', 'utf8');
  }
  return records;
}

async function appendUnique(recordsPath, existing, newRecords) {
  const known = new Map(existing.map((record) => [record.recordId, record.sourceSha256]));
  const pending = [];
  for (const record of newRecords) {
    const prior = known.get(record.recordId);
    if (prior && prior !== record.sourceSha256) throw new Error(`Conflicting revision hash for ${record.recordId}.`);
    if (!prior) {
      known.set(record.recordId, record.sourceSha256);
      pending.push(record);
    }
  }
  if (pending.length) await appendFile(recordsPath, pending.map((record) => JSON.stringify(record)).join('\n') + '\n', 'utf8');
  return pending.length;
}

function categoryObservation(page, retrievedAt) {
  const revision = page.revisions?.[0];
  return {
    observationId: `wikibooks-${page.pageid}-r${revision.revid}:${sha256((page.categories ?? []).map((entry) => entry.title).sort().join('\n'))}`,
    recordId: `wikibooks-${page.pageid}-r${revision.revid}`,
    sourcePageId: String(page.pageid),
    sourceRevision: String(revision.revid),
    observedAt: retrievedAt,
    categories: [...new Set((page.categories ?? []).map((entry) => entry.title))].sort(),
  };
}

async function readCategoryObservations(path) {
  if (!await exists(path)) return [];
  const raw = await readFile(path, 'utf8');
  const byId = new Map();
  for (const [index, line] of raw.split(/\r?\n/).entries()) {
    if (!line.trim()) continue;
    const observation = JSON.parse(line);
    if (typeof observation.observationId !== 'string' || !Array.isArray(observation.categories)) {
      throw new Error(`Invalid category observation at JSONL line ${index + 1}.`);
    }
    byId.set(observation.observationId, observation);
  }
  if (byId.size !== raw.split(/\r?\n/).filter((line) => line.trim()).length) {
    await writeFile(path, [...byId.values()].map((record) => JSON.stringify(record)).join('\n') + '\n', 'utf8');
  }
  return [...byId.values()];
}

async function appendCategoryObservations(path, existing, observations) {
  const known = new Set(existing.map((entry) => entry.observationId));
  const pending = observations.filter((entry) => !known.has(entry.observationId));
  if (pending.length) await appendFile(path, pending.map((record) => JSON.stringify(record)).join('\n') + '\n', 'utf8');
  return pending.length;
}

async function saveFailure(checkpointPath, checkpoint, error, now) {
  const failedAt = now();
  checkpoint.lastError = { at: failedAt.toISOString(), message: error.message };
  checkpoint.errors = [...(checkpoint.errors ?? []), checkpoint.lastError];
  checkpoint.retryAfterMs = error.retryAfterMs ?? null;
  checkpoint.nextAttemptAt = new Date(failedAt.getTime() + Math.max(COOLDOWN_MS, error.retryAfterMs ?? 0)).toISOString();
  checkpoint.updatedAt = now().toISOString();
  await atomicJson(checkpointPath, checkpoint);
}

export async function collect(options, dependencies = {}) {
  const out = options.out;
  await mkdir(out, { recursive: true });
  const checkpointPath = resolve(out, 'checkpoint.json');
  const recordsPath = resolve(out, 'source-pages.jsonl');
  const categoryObservationsPath = resolve(out, 'category-observations.jsonl');
  const manifestPath = resolve(out, 'manifest.json');
  const lockPath = resolve(out, 'collector.lock');
  let lock;
  try {
    lock = await open(lockPath, 'wx');
  } catch (error) {
    if (error.code === 'EEXIST') throw new Error('Collector lock exists; another run may be active. Do not remove it without checking the owning process.');
    throw error;
  }
  const now = dependencies.now ?? (() => new Date());
  const fetchImpl = dependencies.fetch ?? fetch;
  const wait = dependencies.wait ?? ((ms) => new Promise((resolveDelay) => setTimeout(resolveDelay, ms)));
  const afterAppend = dependencies.afterAppend;
  const perRunLimit = Math.min(MAX_API_REQUESTS, options.maxApiRequests ?? MAX_API_REQUESTS);
  let checkpoint;
  let categoryObservations;
  let runRequests = 0;
  try {
    await lock.writeFile(JSON.stringify({ pid: process.pid, startedAt: now().toISOString() }));
    const hasCheckpoint = await exists(checkpointPath);
    if (!options.resume && (hasCheckpoint || await exists(recordsPath))) {
      throw new Error('Output already exists; use --resume to continue from its checkpoint.');
    }
    checkpoint = options.resume && hasCheckpoint
      ? JSON.parse(await readFile(checkpointPath, 'utf8'))
      : {
        collectionStartedAt: now().toISOString(), continuation: null, sourceExhausted: false,
        pendingPageIds: [], sourcePagesProcessed: 0, recipeRecordCount: 0,
        distinctSourcePages: 0, parseableRecipePages: 0,
        processedPageRevisions: [], cumulativeApiRequests: 0, errors: [], nextAttemptAt: null,
      };
    checkpoint.collectionStartedAt ??= checkpoint.retrievedAt ?? checkpoint.runStartedAt ?? now().toISOString();
    delete checkpoint.retrievedAt;
    if (checkpoint.nextAttemptAt && now() < new Date(checkpoint.nextAttemptAt)) {
      throw new Error(`Source cooldown active until ${checkpoint.nextAttemptAt}; no request sent.`);
    }
    if (checkpoint.sourceExhausted) {
      const records = await readRecords(recordsPath);
      checkpoint.sourcePagesProcessed = Math.max(checkpoint.sourcePagesProcessed, records.length);
      checkpoint.recipeRecordCount = records.filter((record) => record.isRecipe).length;
      Object.assign(checkpoint, sourceCounts(records));
      await atomicJson(checkpointPath, checkpoint);
    }
    let records = await readRecords(recordsPath);
    categoryObservations = await readCategoryObservations(categoryObservationsPath);
    const legacyCategoryObservations = records
      .map((record) => ({
        ...categoryObservation({ pageid: record.sourcePageId, revisions: [{ revid: record.sourceRevision }], categories: record.sourceCategories.map((title) => ({ title })) }, null),
        timestampStatus: 'legacy record timestamp is unverified; observation time unknown',
      }));
    await appendCategoryObservations(categoryObservationsPath, categoryObservations, legacyCategoryObservations);
    categoryObservations = [...categoryObservations, ...legacyCategoryObservations];
    const byId = new Map(records.map((record) => [record.recordId, record]));
    checkpoint.processedPageRevisions = [...new Set([...(checkpoint.processedPageRevisions ?? []), ...byId.keys()])];
    checkpoint.sourcePagesProcessed = Math.max(checkpoint.sourcePagesProcessed ?? 0, checkpoint.processedPageRevisions.length);
    checkpoint.recipeRecordCount = records.filter((record) => record.isRecipe).length;
    Object.assign(checkpoint, sourceCounts(records));
    checkpoint.sourcePagesAtRunStart = checkpoint.sourcePagesProcessed;
    checkpoint.lastRunApiRequests = 0;
    checkpoint.runStartedAt = now().toISOString();

    const runStartPageCount = checkpoint.sourcePagesProcessed;
    while (!checkpoint.sourceExhausted && checkpoint.sourcePagesProcessed - runStartPageCount < options.limit && runRequests < perRunLimit) {
      const newPagesThisRun = checkpoint.sourcePagesProcessed - runStartPageCount;
      const remaining = options.limit - newPagesThisRun;
      try {
        if (checkpoint.lastSuccessfulRetrievalAt) {
          const gateAt = new Date(checkpoint.lastSuccessfulRetrievalAt).getTime() + MIN_REQUEST_INTERVAL_MS;
          const delay = Math.max(0, gateAt - now().getTime());
          if (delay) await wait(delay);
        }
        runRequests++;
        checkpoint.cumulativeApiRequests++;
        checkpoint.lastRequestStartedAt = now().toISOString();
        await atomicJson(checkpointPath, checkpoint);
        const batch = await fetchApiPage({
          continuation: checkpoint.continuation,
          limit: Math.min(MAX_PAGES_PER_REQUEST, remaining),
          pendingPageIds: checkpoint.pendingPageIds,
        }, fetchImpl);
        const pages = Object.values(batch.query?.pages ?? {}).sort((a, b) => a.pageid - b.pageid);
        if (!batch.query || !Array.isArray(batch.query.pages) && typeof batch.query.pages !== 'object') {
          throw new Error('MediaWiki response omitted generated pages; stopping without advancing checkpoint.');
        }
        const successfulRetrievalAt = now().toISOString();
        checkpoint.firstSuccessfulRetrievalAt ??= successfulRetrievalAt;
        checkpoint.lastSuccessfulRetrievalAt = successfulRetrievalAt;
        const fetchedRecords = [];
        const fetchedCategoryObservations = [];
        const missingPageIds = [];
        const wasPendingRequest = (checkpoint.pendingPageIds?.length ?? 0) > 0;
        for (const page of pages) {
          if (page.ns !== PAGE_NAMESPACE) throw new Error(`Unexpected page namespace for ${page.title}; stopping.`);
          const raw = sourceWikitext(page);
          if (!page.revisions?.[0]?.revid || typeof raw !== 'string' || raw.length === 0) {
            missingPageIds.push(String(page.pageid));
            continue;
          }
          fetchedRecords.push(pageRecord(page, successfulRetrievalAt));
          fetchedCategoryObservations.push(categoryObservation(page, successfulRetrievalAt));
        }
        const appended = await appendUnique(recordsPath, records, fetchedRecords);
        await appendCategoryObservations(categoryObservationsPath, categoryObservations, fetchedCategoryObservations);
        const categoryObservationIds = new Set(categoryObservations.map((entry) => entry.observationId));
        categoryObservations.push(...fetchedCategoryObservations.filter((entry) => !categoryObservationIds.has(entry.observationId)));
        if (afterAppend) await afterAppend();
        records = await readRecords(recordsPath);
        const recordIds = new Set(records.map((record) => record.recordId));
        checkpoint.processedPageRevisions = [...recordIds];
        checkpoint.sourcePagesProcessed = recordIds.size;
        checkpoint.recipeRecordCount = records.filter((record) => record.isRecipe).length;
        Object.assign(checkpoint, sourceCounts(records));
        if (missingPageIds.length) {
          checkpoint.pendingPageIds = [...new Set([...(checkpoint.pendingPageIds ?? []), ...missingPageIds])];
          checkpoint.continuation = batch.continue ?? checkpoint.continuation;
          if (wasPendingRequest) throw new Error(`Source revisions/content still missing for page IDs ${missingPageIds.join(',')}; preserving checkpoint and stopping.`);
        } else if (checkpoint.pendingPageIds?.length) {
          const returnedIds = new Set(pages.map((page) => String(page.pageid)));
          checkpoint.pendingPageIds = checkpoint.pendingPageIds.filter((id) => !returnedIds.has(id));
          if (!checkpoint.pendingPageIds.length && batch.continue) checkpoint.continuation = batch.continue;
        } else {
          checkpoint.continuation = batch.continue ?? null;
        }
        checkpoint.sourceExhausted = !checkpoint.pendingPageIds.length && !checkpoint.continuation;
        checkpoint.nextAttemptAt = null;
        checkpoint.lastError = null;
        checkpoint.updatedAt = now().toISOString();
        await atomicJson(checkpointPath, checkpoint);
        if (missingPageIds.length && !pages.length) throw new Error('Incomplete page payload; no pages could be verified.');
        if (checkpoint.pendingPageIds.length && runRequests < perRunLimit) {
          await wait(250);
          continue;
        }
        if (checkpoint.continuation && !checkpoint.sourceExhausted && runRequests < perRunLimit && checkpoint.sourcePagesProcessed - runStartPageCount < options.limit) {
          await wait(250);
          continue;
        }
        if (appended === 0 && !checkpoint.pendingPageIds.length && !checkpoint.continuation) break;
      } catch (error) {
        await saveFailure(checkpointPath, checkpoint, error, now);
        throw error;
      }
    }
  } finally {
    try { await lock.close(); } finally { await unlink(lockPath).catch(() => {}); }
  }

  const records = await readRecords(recordsPath);
  categoryObservations = await readCategoryObservations(categoryObservationsPath);
  checkpoint.sourcePagesProcessed = records.length;
  checkpoint.recipeRecordCount = records.filter((record) => record.isRecipe).length;
  Object.assign(checkpoint, sourceCounts(records));
  checkpoint.lastRunApiRequests = runRequests;
  await atomicJson(checkpointPath, checkpoint);
  const categoryPageIds = {};
  for (const observation of categoryObservations) {
    for (const category of observation.categories) {
      (categoryPageIds[category] ??= new Set()).add(observation.sourcePageId);
    }
  }
  const categoryCounts = Object.fromEntries(Object.entries(categoryPageIds).map(([category, pageIds]) => [category, pageIds.size]));
  const manifest = {
    schemaVersion: 1,
    status: 'research-only',
    sourceId: 'wikibooks-cookbook-cc-by-sa',
    sourceCategory: CATEGORY,
    sourceNamespace: PAGE_NAMESPACE,
    sourceApi: API,
    collectionStartedAt: checkpoint.collectionStartedAt,
    firstSuccessfulRetrievalAt: checkpoint.firstSuccessfulRetrievalAt ?? null,
    lastSuccessfulRetrievalAt: checkpoint.lastSuccessfulRetrievalAt ?? null,
    legacyRecordTimestampStatus: 'Records collected before this collector revision may carry the collection creation time instead of the exact retrieval time; use per-record retrievedAt only for records fetched after the timestamp fix.',
    license: { ...LICENSE },
    limits: { requestedNewPagesThisRun: options.limit, maxApiRequestsPerRun: MAX_API_REQUESTS, maxPagesPerRequest: MAX_PAGES_PER_REQUEST, maxPagesPerInvocation: MAX_API_REQUESTS * MAX_PAGES_PER_REQUEST, noAllTimeCollectionCap: true },
    collection: { sourceRevisionRecords: checkpoint.sourcePagesProcessed, revisionRecordsThisRun: checkpoint.sourcePagesProcessed - (checkpoint.sourcePagesAtRunStart ?? checkpoint.sourcePagesProcessed), distinctSourcePages: checkpoint.distinctSourcePages, parseableRecipePages: checkpoint.parseableRecipePages, recipeRevisionRecords: checkpoint.recipeRecordCount, apiRequestsThisRun: runRequests, apiRequestsCumulative: checkpoint.cumulativeApiRequests },
    sourceCategoryCounts: categoryCounts,
    categoryObservations: 'category-observations.jsonl',
    sourceExhausted: checkpoint.sourceExhausted,
    pendingPageIds: checkpoint.pendingPageIds,
    checkpoint: 'checkpoint.json',
    records: 'source-pages.jsonl',
    recordFormat: 'One raw source page revision plus conservative section extraction per JSONL line; source content hashes are SHA256 of API-returned revision wikitext UTF-8.',
    warning: 'Category membership does not establish a cuisine. Any cuisine/category label is copied only from the page’s returned source categories. Page-specific license exceptions and recipe quality remain unreviewed; no runtime, nutrition, amount, or unit readiness is asserted.',
  };
  await writeFile(manifestPath, JSON.stringify(manifest, null, 2) + '\n', 'utf8');
  return manifest;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const options = parseArgs(process.argv.slice(2));
    if (options.help) {
      process.stdout.write('Usage: node tool/recipes/collect-wikibooks.mjs [--limit 1..1000] [--out path] [--resume]\n');
    } else {
      process.stdout.write(`${JSON.stringify(await collect(options), null, 2)}\n`);
    }
  } catch (error) {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  }
}
