import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {snapshotFingerprint} from './review-target.mjs';

const root=new URL('../../',import.meta.url),folder='data/recipes/curated-local/sixth-reviewed-20261015/';
const read=p=>readFile(new URL(p,root));
let api,pack,report;
async function init(){if(api)return;api=await import('./curated-sixth-build.mjs');pack=JSON.parse(await read(folder+'normalized-recipes.json'));report=JSON.parse(await read(folder+'review-report.json'));}

test('four reviewed archived revisions have exact source and full-byte snapshot pins',async()=>{
 await init();assert.equal(pack.recipes.length,4);assert.deepEqual(pack.recipes.map(r=>Number(r.id.split(':')[1])),[6493,32960,457155,456772]);
 const labels=new Set(pack.recipes.flatMap(r=>r.cuisines.map(c=>c.id)));assert.deepEqual(labels,new Set(['hungarian','lebanese','ghanaian','tanzanian']));
 assert.equal(report.networkRequests,0);assert.equal(report.newBooks,0);assert.equal(report.frozenPreviousRecords,44);
 for(const r of pack.recipes){
  const snapBytes=await read(r.provenance.sourceSnapshotFile),snap=JSON.parse(snapBytes),raw=snap.sourceRecord,source=snap.authoritativeParsedRecipe;
  assert.equal(api.sha(snapBytes),r.provenance.sourceSnapshotSha256);assert.equal(api.sha(raw.sourceWikitext),raw.sourceSha256);
  assert.equal(raw.sourceSha256,r.provenance.sourceSha256);assert.equal(String(raw.sourceRevision),String(r.provenance.sourceRevision));
  assert.equal(raw.sourceRevisionTimestamp,r.provenance.sourceRevisionTimestamp);assert.equal(raw.retrievedAt,r.provenance.retrievedAt);assert.equal(raw.sourceUrl,r.provenance.sourceUrl);
  assert.deepEqual(raw.license,source.license);assert.equal(snapshotFingerprint(source),r.provenance.derivedRecipeSha256);
  assert.equal(snapshotFingerprint(source.license),r.provenance.licenseSha256);assert(r.cuisines.every(c=>raw.sourceCategories.includes(c.evidenceText)));
  const {contentSha256,...body}=r;assert.equal(snapshotFingerprint(body),contentSha256);
 }
});

test('Arabic drafts preserve all ingredients and ordered source steps without runtime approval',async()=>{
 await init();assert.deepEqual(pack.counts,{recipes:4,ingredientLines:38,supplementalIngredients:3,steps:30,fullySpecified:0,needsReview:4,notCookable:0,sourceSupportedCuisineLabels:4,runtimeReady:0});
 assert.deepEqual(report.combinedLocal,{recipes:48,fullySpecified:10,needsReview:36,notCookable:2,ingredientLines:340,supplementalIngredients:23,steps:250,sourceSupportedCuisineLabels:42,runtimeReady:0});
 for(const r of pack.recipes){
  const snap=JSON.parse(await read(r.provenance.sourceSnapshotFile)),source=snap.authoritativeParsedRecipe;
  assert.equal(r.status,'needs-review');assert.equal(r.runtimeReady,false);assert.equal(r.actuallyKitchenTested,false);assert.equal(r.nutrition,null);
  assert(r.ingredients.every(i=>i.scales===null&&i.foodBinding===null));assert.equal(r.ingredients.length,source.recipe.ingredients.length);assert.equal(r.steps.length,source.recipe.steps.length);
  for(let i=0;i<r.steps.length;i++)assert.deepEqual(r.steps[i].sourceStepIndices,[i]);
  assert(r.cuisines.every(c=>c.reviewStatus==='source-supported-not-runtime-approved'));
  const row=report.newDraftReports.find(x=>x.curatedRecipeId===r.id);assert(row);assert.equal(row.draftComplete,false);assert.equal(row.runtimeReady,false);
  const draftBytes=await read(row.draftFile),draft=JSON.parse(draftBytes);assert.equal(api.sha(draftBytes),row.draftSha256);assert.equal(draft.lines.length,source.recipe.ingredients.length);
 }
 const dumpling=pack.recipes.find(r=>r.id.endsWith(':6493'));assert.equal(dumpling.ingredients[4].amount,null);assert.equal(dumpling.ingredients[5].sourceLineIndex,5);assert.equal(dumpling.time.declaredTotalMinutes,null);
 const sayyadieh=pack.recipes.find(r=>r.id.endsWith(':32960'));assert.equal(sayyadieh.ingredients[0].amount,null);assert.match(sayyadieh.ingredients[0].decisionNote,/تقديرين وزنيين مختلفين/);assert.equal(sayyadieh.supplementalIngredients[0].amount,4);assert.match(sayyadieh.steps[3].textAr,/1 إلى 4/);
 const nkatenkwan=pack.recipes.find(r=>r.id.endsWith(':457155'));assert.equal(nkatenkwan.ingredients[3].optional,true);assert(nkatenkwan.supplementalIngredients.every(i=>i.amount===null));assert.equal(nkatenkwan.yield.amount,null);
 const nyama=pack.recipes.find(r=>r.id.endsWith(':456772'));assert.equal(nyama.ingredients[0].amount,1);assert.match(nyama.ingredients[0].decisionNote,/أربعة أنواع بديلة/);assert.equal(nyama.time.declaredTotalMinutes,null);
});

test('offline builder reproduces pack, snapshots, drafts, report and Arabic cookbook byte-for-byte',async()=>{
 await init();const files=['review-decisions.json','normalized-recipes.json','COOKBOOK.ar.md','review-report.json'];const before=await Promise.all(files.map(p=>read(folder+p)));
 const snapshotBefore=await Promise.all(pack.recipes.map(r=>read(r.provenance.sourceSnapshotFile))),draftBefore=await Promise.all(report.newDraftReports.map(r=>read(r.draftFile)));
 const rebuilt=await api.build();assert.equal(rebuilt.pack.recipes.length,4);
 for(let i=0;i<files.length;i++)assert.deepEqual(await read(folder+files[i]),before[i]);
 for(let i=0;i<pack.recipes.length;i++)assert.deepEqual(await read(pack.recipes[i].provenance.sourceSnapshotFile),snapshotBefore[i]);
 for(let i=0;i<report.newDraftReports.length;i++)assert.deepEqual(await read(report.newDraftReports[i].draftFile),draftBefore[i]);
});
