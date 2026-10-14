import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const root = process.cwd();
const lane = path.join(root, 'data/recipes/source-discovery/ar-wikibooks');
const archivePath = path.join(lane, '05-search.json');
const archive = JSON.parse(fs.readFileSync(archivePath, 'utf8'));
const responseBytes = Buffer.from(archive.responseBody, 'utf8');
const responseSha = crypto.createHash('sha256').update(responseBytes).digest('hex');
if (responseSha !== archive.bodySha256) throw new Error('search archive body digest mismatch');
if (archive.httpStatus !== 200) throw new Error(`search archive HTTP ${archive.httpStatus}`);
const response = JSON.parse(archive.responseBody);
const page = response.query?.pages?.find((item) => item.pageid === 12128);
if (!page || page.title !== 'كتاب الطبخ/كعكة-1-2-3-4') throw new Error('expected source page not found');
const revision = page.revisions?.[0];
if (!revision?.slots?.main?.content || String(revision.revid) !== '227030') throw new Error('unexpected source revision');
const wikitext = revision.slots.main.content;
const sourceSha = crypto.createHash('sha256').update(Buffer.from(wikitext, 'utf8')).digest('hex');
const headingBlock = (heading, nextHeading, source) => {
  const start = source.indexOf(heading);
  if (start < 0) return null;
  const from = start + heading.length;
  const end = nextHeading ? source.indexOf(nextHeading, from) : -1;
  return source.slice(from, end < 0 ? source.length : end);
};
const ingredientBlock = headingBlock('== المكونات ==', '== الطريقة (مختصرة) ==', wikitext);
const methodBlock = headingBlock('== الطريقة (مختصرة) ==', '== الطريقة (مفصلة) ==', wikitext);
if (!ingredientBlock || !methodBlock) throw new Error('source headings changed; review parser before regeneration');
const unitTerms = ['ملاعق صغيرة', 'ملعقة صغيرة', 'أكواب', 'كوب', 'قرصات', 'قرصة', 'بيضات', 'بيضة', 'غرام', 'جرام'];
const ingredients = ingredientBlock.split(/\r?\n/).filter((line) => /^\*\s+/.test(line)).map((line, index) => {
  const sourceText = line.replace(/^\*\s+/, '').trim();
  const match = sourceText.match(/^(\d+(?:\.\d+)?)\s+(.+)$/u);
  let unitText = null;
  let remainder = null;
  if (match) {
    remainder = match[2];
    unitText = unitTerms.find((term) => remainder.startsWith(term)) ?? null;
  }
  return {
    lineIndex: index,
    sourceText,
    sourceQuantityCandidate: match ? { amount: Number(match[1]), unitText, followingText: remainder, status: 'unreviewed-source-transcription' } : null,
    amount: null,
    unit: null,
    foodBinding: null,
  };
});
const steps = methodBlock.split(/\r?\n/).filter((line) => /^#\s+/.test(line)).map((line, index) => ({
  n: index + 1,
  text: line.replace(/^#\s+/, '').trim(),
  durationMinutes: null,
}));
if (!ingredients.length || !steps.length) throw new Error('parser found no ingredient or method lines');
const candidate = {
  schemaVersion: 1,
  status: 'research-only-source-candidate',
  id: 'ar-wikibooks:12128',
  sourceId: 'ar-wikibooks-research-cc-by-sa',
  sourceLanguage: 'ar',
  sourcePageId: page.pageid,
  sourceRevision: String(revision.revid),
  sourceRevisionTimestamp: revision.timestamp,
  sourceRevisionUser: revision.user,
  sourceTitle: page.title,
  sourceUrl: `https://ar.wikibooks.org/w/index.php?title=${encodeURIComponent(page.title).replaceAll('%2F', '%2F')}&oldid=${revision.revid}`,
  retrievalRequestUrl: archive.requestUrl,
  retrievedAt: archive.retrievedAt,
  retrievalHttpStatus: archive.httpStatus,
  retrievalResponseSha256: archive.bodySha256,
  retrievalArchive: 'data/recipes/source-discovery/ar-wikibooks/05-search.json',
  sourceWikitext: wikitext,
  sourceSha256: sourceSha,
  sourceArchive: 'data/recipes/source-discovery/ar-wikibooks/05-search.json',
  license: {
    id: 'ar-wikibooks-cc-by-sa-4.0',
    name: 'Creative Commons Attribution-Share Alike 4.0',
    url: 'https://creativecommons.org/licenses/by-sa/4.0/deed.ar',
    evidenceUrl: 'https://ar.wikibooks.org/w/api.php?action=query&meta=siteinfo&siprop=general%7Crightsinfo%7Cnamespaces&format=json&formatversion=2',
    evidenceArchive: 'data/recipes/source-discovery/ar-wikibooks/01-siteinfo.json',
    policyStatus: 'verified-site-policy',
    licenseStatus: 'unverified-primary-source',
    pageExceptionStatus: 'not-reviewed-per-page',
    attribution: 'Attribute the page revision and contributor, link to the permanent revision, identify extraction or adaptation, retain CC BY-SA 4.0 notice, and share adaptations under applicable terms.',
    changeNoticeRequired: true,
    shareAlikeRequired: true,
  },
  changeNotice: 'Arabic Wikibooks wikitext retained verbatim. Concise method and ingredient lists extracted for research only; no translation, nutrition review, or runtime import.',
  parserVersion: 'ar-wikibooks-literal-heading-v1',
  isRecipe: true,
  sourceObservations: {
    sourceCategories: ['كتاب الطبخ'],
    explicitCuisineText: 'هي وصفة أمريكية تقليدية.',
    cuisineReviewStatus: 'unreviewed-source-observation',
    alternateDetailedMethodPreservedInSourceWikitext: true,
    mediaReferencesPresent: true,
    mediaCollected: false,
  },
  recipe: {
    name: 'كعكة 1-2-3-4',
    nameAr: 'كعكة 1-2-3-4',
    servings: null,
    cuisine: null,
    nutrition: null,
    ingredients,
    steps,
  },
  gaps: [
    'servings not stated',
    'ingredient source quantities are explicit transcriptions but remain unreviewed; canonical amount and unit are null',
    'ingredient food identity and form are unreviewed',
    'no numeric prep, cooking, or total duration is stated; all step durations remain null',
    'source has concise and detailed method sections; concise method extracted, detailed method remains in source wikitext',
    'sitewide CC BY-SA policy verified; page-level exceptions and third-party attributions remain unreviewed',
    'source explicitly describes the recipe as traditional American; this cuisine observation is unreviewed',
    'no nutrition values or food bindings are included',
  ],
};
fs.writeFileSync(path.join(lane, 'candidate.json'), `${JSON.stringify(candidate, null, 2)}\n`, 'utf8');
const summary = {
  candidateId: candidate.id,
  sourceRevision: candidate.sourceRevision,
  sourceSha256: candidate.sourceSha256,
  ingredientLines: ingredients.length,
  explicitQuantityTranscriptions: ingredients.filter((item) => item.sourceQuantityCandidate).length,
  canonicalQuantities: ingredients.filter((item) => item.amount !== null || item.unit !== null).length,
  conciseSteps: steps.length,
  unknownStepDurations: steps.filter((step) => step.durationMinutes === null).length,
  servings: candidate.recipe.servings,
  cuisine: candidate.recipe.cuisine,
  nutrition: candidate.recipe.nutrition,
  status: candidate.status,
};
fs.writeFileSync(path.join(lane, 'extract-summary.json'), `${JSON.stringify(summary, null, 2)}\n`, 'utf8');
console.log(JSON.stringify(summary, null, 2));
