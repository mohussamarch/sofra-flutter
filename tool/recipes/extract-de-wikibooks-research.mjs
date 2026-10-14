import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const root = process.cwd();
const lane = path.join(root, 'data/recipes/source-discovery/de-wikibooks');
const hash = (bytes) => crypto.createHash('sha256').update(bytes).digest('hex');
const readArchive = (name) => {
  const wrapper = JSON.parse(fs.readFileSync(path.join(lane, name), 'utf8'));
  const raw = Buffer.from(wrapper.bodyBase64, 'base64');
  if (hash(raw) !== wrapper.bodySha256) throw new Error(`${name}: raw body digest mismatch`);
  if (raw.toString('utf8') !== wrapper.responseBody) throw new Error(`${name}: body text differs from archived bytes`);
  const bodyPath = path.join(lane, name.replace(/\.json$/u, '.body'));
  if (fs.existsSync(bodyPath) && !fs.readFileSync(bodyPath).equals(raw)) throw new Error(`${name}: body sidecar differs from archived bytes`);
  if (wrapper.httpStatus !== 200) throw new Error(`${name}: unexpected HTTP status ${wrapper.httpStatus}`);
  return { wrapper, data: JSON.parse(wrapper.responseBody), raw };
};
const policyArchive = readArchive('01-siteinfo.json');
const general = policyArchive.data.query?.general;
const rights = policyArchive.data.query?.rightsinfo;
const mainNamespace = policyArchive.data.query?.namespaces?.['0'];
if (general?.lang !== 'de' || general?.servername !== 'de.wikibooks.org') throw new Error('unexpected Wikibooks site identity');
if (!rights?.url?.includes('creativecommons.org/licenses/by-sa/4.0') || !rights?.text?.includes('Attribution-Share Alike 4.0')) throw new Error('sitewide CC BY-SA 4.0 policy not verified');
if (mainNamespace?.id !== 0 || mainNamespace?.content !== true) throw new Error('main namespace not verified');
const pageArchiveNames = fs.readdirSync(lane)
  .filter((name) => /^\d{2}-(?:pages|prefix-recovery-new)\.json$/u.test(name))
  .sort((a, b) => Number(a.slice(0, 2)) - Number(b.slice(0, 2)));
const archives = pageArchiveNames.map(readArchive);
if (archives.length < 2) throw new Error('expected the initial listing and at least one continuation archive');
const continuationArchives = pageArchiveNames.filter((name) => /^\d{2}-pages\.json$/u.test(name)).map(readArchive);
const lastRecovery = archives.filter(({ wrapper }) => wrapper.retrievalKind === 'new-prefix-recovery').at(-1);
const firstSavedContinuation = continuationArchives[0]?.wrapper.continuationIn;
if (archives.some(({ wrapper }) => wrapper.retrievalKind === 'new-prefix-recovery' && !wrapper.retrievedAt)) {
  throw new Error('new prefix recovery is missing its retrieval timestamp');
}
if (lastRecovery && (firstSavedContinuation?.gapcontinue !== lastRecovery.data.continue?.gapcontinue || firstSavedContinuation?.continue !== lastRecovery.data.continue?.continue)) {
  throw new Error('new prefix recovery does not join the preserved continuation boundary');
}
const pageMap = new Map();
const pageIds = new Set();
for (const { data } of archives) {
  for (const page of Object.values(data.query?.pages ?? {})) {
    if (!page.title?.startsWith('Kochbuch/')) continue;
    const revision = page.revisions?.[0];
    const wikitext = revision?.slots?.main?.content;
    if (page.ns !== 0 || !revision?.revid || typeof wikitext !== 'string') throw new Error(`incomplete source revision: ${page.title}`);
    const key = `${page.pageid}:${revision.revid}`;
    if (pageMap.has(key)) throw new Error(`duplicate source revision ${key}`);
    if (pageIds.has(page.pageid)) throw new Error(`page ID repeated across retrieval archives: ${page.pageid}`);
    pageIds.add(page.pageid);
    pageMap.set(key, { page, revision, wikitext });
  }
}
const headingPattern = /^(={2,6})\s*(.*?)\s*\1\s*$/u;
const ingredientHeading = (s) => /^zutaten\b/iu.test(s.trim());
const methodHeading = (s) => /^(?:zubereitung\b|zubereitungs(?:art|schritte|weise)\b|herstellung\b|anleitung\b|die\s+zubereitung\b|zubereiten\b)/iu.test(s.trim());
const listItem = /^\s*(?:\*+|#+\*+|#+|-|•)\s+(.+?)\s*$/u;
const ignoredMethodLine = (line) => {
  const text = line.trim();
  return !text || /^<!--.*-->$/u.test(text) || /^\{\{\s*(?:Abschnittswechsel|TOC|DEFAULTSORT)\b/iu.test(text) || /^\[\[(?:Kategorie|Category|Datei|File):/iu.test(text) || /^<(?:gallery|ref|references)\b/iu.test(text) || /^\|/u.test(text);
};
const getHeadings = (lines) => lines.map((line, index) => {
  const match = line.trim().match(headingPattern);
  return match ? { index, level: match[1].length, title: match[2].trim() } : null;
}).filter(Boolean);
const sectionsFor = (lines, headings, test) => headings.filter((heading) => test(heading.title)).map((heading) => {
  const end = headings.find((next) => next.index > heading.index && next.level <= heading.level)?.index ?? lines.length;
  return { heading, lines: lines.slice(heading.index + 1, end) };
});
const parseIngredients = (sections) => {
  const rows = [];
  for (const section of sections) {
    for (const line of section.lines) {
      const match = line.match(listItem);
      if (!match) continue;
      const sourceText = match[1].trim();
      if (!sourceText || sourceText.startsWith('{{')) continue;
      rows.push({ lineIndex: rows.length, sourceHeading: section.heading.title, sourceText, amount: null, unit: null, foodBinding: null });
    }
  }
  return rows;
};
const parseSteps = (sections) => {
  const rows = [];
  for (const section of sections) {
    let paragraph = [];
    const flushParagraph = () => {
      const text = paragraph.join('\n').trim();
      if (text) rows.push({ n: rows.length + 1, text, durationMinutes: null });
      paragraph = [];
    };
    for (const line of section.lines) {
      if (ignoredMethodLine(line)) { flushParagraph(); continue; }
      const match = line.match(listItem);
      if (match) {
        flushParagraph();
        const text = match[1].trim();
        if (text && !text.startsWith('{{')) rows.push({ n: rows.length + 1, text, durationMinutes: null });
      } else if (/^\s*\{\{/u.test(line.trim()) || /^\s*<\/?.+>\s*$/u.test(line.trim())) {
        flushParagraph();
      } else {
        paragraph.push(line);
      }
    }
    flushParagraph();
  }
  return rows;
};
const sourcePages = [];
const candidates = [];
for (const { page, revision, wikitext } of [...pageMap.values()].sort((a, b) => a.page.pageid - b.page.pageid)) {
  const lines = wikitext.split(/\r?\n/u);
  const headings = getHeadings(lines);
  const ingredientSections = sectionsFor(lines, headings, ingredientHeading);
  const methodSections = sectionsFor(lines, headings, methodHeading);
  const ingredients = parseIngredients(ingredientSections);
  const steps = parseSteps(methodSections);
  const parseStatus = ingredients.length && steps.length ? 'candidate' : 'source-page-unparsed';
  const sourceSha256 = hash(Buffer.from(wikitext, 'utf8'));
  const titlePart = page.title.slice('Kochbuch/'.length).trim();
  const sourceUrl = `https://de.wikibooks.org/w/index.php?title=${encodeURIComponent(page.title)}&oldid=${revision.revid}`;
  const sourceArchiveEntry = archives.find(({ data }) => {
    const archivedPages = data.query?.pages ?? [];
    return (Array.isArray(archivedPages) ? archivedPages : Object.values(archivedPages)).some((candidate) => candidate.pageid === page.pageid);
  });
  if (!sourceArchiveEntry) throw new Error(`missing request archive for page ${page.pageid}`);
  const archivePosition = archives.indexOf(sourceArchiveEntry);
  const sourceRequestArchive = pageArchiveNames[archivePosition];
  const sourceRecord = {
    id: `de-wikibooks:${page.pageid}`,
    sourceLanguage: 'de',
    sourcePageId: page.pageid,
    sourceRevision: String(revision.revid),
    sourceRevisionTimestamp: revision.timestamp,
    sourceRevisionUser: revision.user,
    sourceTitle: page.title,
    sourceUrl,
    retrievedAt: sourceArchiveEntry.wrapper.retrievedAt,
    sourceRequestArchive: `data/recipes/source-discovery/de-wikibooks/${sourceRequestArchive}`,
    sourceSha256,
    parserVersion: 'de-wikibooks-ingredient-method-sections-v1',
    parseStatus,
    ingredientLineCount: ingredients.length,
    stepCount: steps.length,
    sourceWikitext: wikitext,
  };
  sourcePages.push(sourceRecord);
  if (parseStatus !== 'candidate') continue;
  const categories = [...wikitext.matchAll(/\[\[Kategorie:([^\]|]+)(?:\|[^\]]*)?\]\]/giu)].map((match) => match[1].trim());
  candidates.push({
    schemaVersion: 1,
    status: 'research-only-source-candidate',
    id: sourceRecord.id,
    sourceId: 'de-wikibooks-research-cc-by-sa',
    sourceLanguage: 'de',
    sourcePageId: sourceRecord.sourcePageId,
    sourceRevision: sourceRecord.sourceRevision,
    sourceRevisionTimestamp: sourceRecord.sourceRevisionTimestamp,
    sourceRevisionUser: sourceRecord.sourceRevisionUser,
    sourceTitle: sourceRecord.sourceTitle,
    sourceUrl,
    retrievedAt: sourceRecord.retrievedAt,
    sourceSha256,
    sourceArchive: sourceRecord.sourceRequestArchive,
    license: {
      id: 'de-wikibooks-cc-by-sa-4.0',
      name: 'Creative Commons Attribution-Share Alike 4.0',
      url: rights.url,
      evidenceUrl: policyArchive.wrapper.requestUrl,
      evidenceArchive: 'data/recipes/source-discovery/de-wikibooks/01-siteinfo.json',
      policyStatus: 'verified-site-policy',
      licenseStatus: 'unverified-primary-source',
      pageExceptionStatus: 'not-reviewed-per-page',
      attribution: 'Attribute the source revision and contributor, link to the permanent revision, identify extraction or adaptation, retain the CC BY-SA 4.0 notice, and share adaptations under applicable terms.',
      changeNoticeRequired: true,
      shareAlikeRequired: true,
    },
    changeNotice: 'Extracted literal German ingredient and preparation sections from source wikitext for research only; no translation, nutrition review, or runtime import.',
    parserVersion: 'de-wikibooks-ingredient-method-sections-v1',
    isRecipe: true,
    sourceCategories: categories,
    recipe: {
      name: titlePart,
      servings: null,
      cuisine: null,
      nutrition: null,
      prepTime: null,
      cookTime: null,
      totalTime: null,
      ingredients,
      steps,
    },
    gaps: [
      'all quantities and units remain null; literal source ingredient rows are retained',
      'ingredient identities, food bindings, servings, timing, nutrition, and cuisine remain unreviewed or unknown',
      'source categories are copied as unreviewed source labels and are not treated as cuisine',
      'sitewide CC BY-SA policy is verified; page-specific exceptions and third-party attributions remain unreviewed',
    ],
    sourceWikitext: wikitext,
  });
}
const jsonl = (items) => items.map((item) => JSON.stringify(item)).join('\n') + (items.length ? '\n' : '');
fs.writeFileSync(path.join(lane, 'source-pages.jsonl'), jsonl(sourcePages), 'utf8');
fs.writeFileSync(path.join(lane, 'parsed-candidates.jsonl'), jsonl(candidates), 'utf8');
const index = {
  schemaVersion: 1,
  source: 'German Wikibooks Kochbuch namespace-0 prefix',
  sourceLanguage: 'de',
  sourcePolicy: { license: rights.text, licenseUrl: rights.url, policyStatus: 'verified-site-policy', pageExceptions: 'not-reviewed-per-page' },
  parserVersion: 'de-wikibooks-ingredient-method-sections-v1',
  requestArchives: ['01-siteinfo.json', ...pageArchiveNames],
  sourcePageCount: sourcePages.length,
  candidateCount: candidates.length,
  parsedIngredientLines: candidates.reduce((sum, item) => sum + item.recipe.ingredients.length, 0),
  parsedSteps: candidates.reduce((sum, item) => sum + item.recipe.steps.length, 0),
  unknownCanonicalAmounts: candidates.reduce((sum, item) => sum + item.recipe.ingredients.length, 0),
  unknownStepDurations: candidates.reduce((sum, item) => sum + item.recipe.steps.filter((step) => step.durationMinutes === null).length, 0),
  runtimeImports: 0,
  nutritionBindings: 0,
  cuisineApproved: 0,
  continuationAfterBatch: continuationArchives.at(-1).data.continue ?? null,
  sourcePageFileSha256: hash(fs.readFileSync(path.join(lane, 'source-pages.jsonl'))),
  candidateFileSha256: hash(fs.readFileSync(path.join(lane, 'parsed-candidates.jsonl'))),
};
fs.writeFileSync(path.join(lane, 'index.json'), `${JSON.stringify(index, null, 2)}\n`, 'utf8');
console.log(JSON.stringify(index, null, 2));
