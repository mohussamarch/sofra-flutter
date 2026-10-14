import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile,access} from 'node:fs/promises';
import {snapshotFingerprint} from './review-target.mjs';

const root=new URL('../../',import.meta.url);
const folder='data/recipes/curated-local/fifth-reviewed-20261014/';
const read=p=>readFile(new URL(p,root));
let api,pack,report,decisions;
async function init(){if(api)return;api=await import('./curated-fifth-build.mjs');pack=JSON.parse(await read(folder+'normalized-recipes.json'));report=JSON.parse(await read(folder+'review-report.json'));decisions=JSON.parse(await read(folder+'review-decisions.json'));}
async function sourceFor(id){await init();const r=pack.recipes.find(x=>x.id==='curated-local:'+id);assert(r);const snap=JSON.parse(await read(r.provenance.sourceSnapshotFile));return {r,snap};}

test('fifth archived-source builder exists',async()=>{await access(new URL('./curated-fifth-build.mjs',import.meta.url));});
test('eight fixed revisions retain source, rights and content fingerprints with no old ID/title/family overlap',async()=>{
 await init();assert.equal(pack.recipes.length,8);assert.equal(report.frozenPreviousRecords,36);assert.equal(report.creatorWebsiteRecords,19);
 const old=[];for(const [p,h] of api.frozen){const bytes=await read(p);assert.equal(api.sha(bytes),h);old.push(...JSON.parse(bytes).recipes);}
 const ids=new Set(old.map(x=>x.id)),families=new Set(old.map(x=>x.familyId)),titles=new Set(old.flatMap(x=>[x.name,x.nameAr]));
 for(const r of pack.recipes){
  assert(!ids.has(r.id));assert(!families.has(r.familyId));assert(!titles.has(r.name));assert(!titles.has(r.nameAr));
  const {snap}=await sourceFor(Number(r.id.split(':')[1])),raw=snap.sourceRecord,source=snap.authoritativeParsedRecipe;
  assert.equal(api.sha(raw.sourceWikitext),raw.sourceSha256);assert.equal(raw.sourceSha256,r.provenance.sourceSha256);
  assert.equal(raw.sourceRevisionTimestamp,r.provenance.sourceRevisionTimestamp);assert.equal(raw.retrievedAt,r.provenance.retrievedAt);
  assert.equal(raw.sourceUrl,r.provenance.sourceUrl);assert.deepEqual(raw.license,source.license);assert.equal(snapshotFingerprint(source),r.provenance.derivedRecipeSha256);
  assert.equal(snapshotFingerprint(raw.license),r.provenance.licenseSha256);
  const snapBytes=await read(r.provenance.sourceSnapshotFile);assert.equal(api.sha(snapBytes),r.provenance.sourceSnapshotSha256);
  const {contentSha256,...body}=r;assert.equal(snapshotFingerprint(body),contentSha256);
 }
});

test('eight genuinely new geographic source categories are exact and language does not supply cuisine',async()=>{
 await init();assert.deepEqual(new Set(pack.recipes.flatMap(r=>r.cuisines.map(c=>c.id))),new Set(['albanian','argentine','austrian','bulgarian','colombian','cuban','palestinian','malaysian']));
 assert.equal(report.combinedLocal.recipes,44);assert.equal(report.combinedLocal.sourceSupportedCuisineLabels,38);
 for(const r of pack.recipes){const {snap}=await sourceFor(Number(r.id.split(':')[1]));for(const c of r.cuisines)assert(snap.sourceRecord.sourceCategories.includes(c.evidenceText));}
 assert.deepEqual(pack.duplicateReview.exactCatalogueNameMatches,[]);
});

test('all methods remain ordered, unknowns and conflicts stay explicit, and no runtime approvals are implied',async()=>{
 await init();assert.equal(pack.counts.needsReview,8);assert.equal(pack.counts.fullySpecified,0);assert.equal(pack.counts.runtimeReady,0);
 for(const r of pack.recipes){const {snap}=await sourceFor(Number(r.id.split(':')[1]));assert.equal(r.status,'needs-review');assert.equal(r.runtimeReady,false);assert.equal(r.nutrition,null);assert.equal(r.actuallyKitchenTested,false);assert(r.ingredients.every(i=>i.foodBinding===null&&i.scales===null));assert.equal(r.steps.length,snap.authoritativeParsedRecipe.recipe.steps.length);for(let i=0;i<r.steps.length;i++)assert.deepEqual(r.steps[i].sourceStepIndices,[i]);assert(r.cuisines.every(c=>c.reviewStatus==='source-supported-not-runtime-approved'));}
 const albanian=(await sourceFor(18875)).r;assert.equal(albanian.yield.amount,4);assert.equal(albanian.time.declaredTotalMinutes,null);assert.equal(albanian.ingredients[2].amount,0.5);assert.match(albanian.ingredients[2].decisionNote,/بديلان/);
 const chanterelle=(await sourceFor(179962)).r;assert.equal(chanterelle.time.declaredTotalMinutes,null);assert.equal(chanterelle.ingredients[5].amount,null);assert.equal(chanterelle.ingredients[5].sourceText,'3–4 tbsp white wine vinegar');
 const beans=(await sourceFor(127705)).r;assert.equal(beans.time.declaredTotalMinutes,null);assert.deepEqual([beans.yield.amount,beans.yield.min,beans.yield.max],[6,null,null]);assert.equal(beans.ingredients[9].optional,true);
 const mejadra=(await sourceFor(8658)).r;assert.equal(mejadra.time.declaredTotalMinutes,null);assert.deepEqual([mejadra.yield.min,mejadra.yield.max],[3,4]);assert.equal(mejadra.ingredients[7].amount,1);assert.match(mejadra.ingredients[7].decisionNote,/بديلان/);
 const arisa=(await sourceFor(38143)).r;assert.equal(arisa.ingredients[0].amount,2);assert.equal(arisa.ingredients[0].unit,'chicken');assert.equal(arisa.supplementalIngredients[0].amount,null);assert.equal(arisa.time.declaredTotalMinutes,null);
 assert.deepEqual([chanterelle.steps[5].duration.min,chanterelle.steps[5].duration.max,chanterelle.steps[5].duration.endpointQualified],[10,12,true]);
 assert.equal((await sourceFor(179898)).r.steps[4].duration.min,15);assert.equal((await sourceFor(127705)).r.steps[4].duration.min,30);
 assert.deepEqual([(await sourceFor(8658)).r.steps[0].duration.min,(await sourceFor(8658)).r.steps[0].duration.max],[3,4]);
 assert.equal(report.networkRequests,0);assert.equal(report.newBooks,0);assert.equal(report.runtimeReady,0);assert.equal(report.draftComplete,0);
});

test('preflight drafts retain every source line and remain incomplete',async()=>{
 await init();let issues=0;for(const r of pack.recipes){const {snap}=await sourceFor(Number(r.id.split(':')[1]));const reportRow=report.newDraftReports.find(x=>x.curatedRecipeId===r.id);assert(reportRow);assert.equal(reportRow.draftComplete,false);assert.equal(reportRow.runtimeReady,false);const bytes=await read(reportRow.draftFile);assert.equal(api.sha(bytes),reportRow.draftSha256);const draft=JSON.parse(bytes);assert.equal(draft.lines.length,snap.authoritativeParsedRecipe.recipe.ingredients.length);issues+=reportRow.issues.length;}assert.equal(issues,report.draftIssues);assert.equal(report.draftIssues,report.newDraftReports.reduce((n,r)=>n+r.issues.length,0));
});

test('offline rebuild reproduces immutable pack, cookbook, source snapshots and preflight drafts',async()=>{
 await init();const files=['review-decisions.json','normalized-recipes.json','COOKBOOK.ar.md','review-report.json'];const before=await Promise.all(files.map(p=>read(folder+p)));const rebuilt=await api.build();assert.equal(rebuilt.pack.recipes.length,8);for(let i=0;i<files.length;i++)assert.deepEqual(await read(folder+files[i]),before[i]);
});
