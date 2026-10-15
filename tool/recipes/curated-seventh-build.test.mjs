import test from 'node:test';
import assert from 'node:assert/strict';
import {readdir, readFile} from 'node:fs/promises';
import {snapshotFingerprint} from './review-target.mjs';

const root=new URL('../../',import.meta.url),folder='data/recipes/curated-local/seventh-reviewed-20261015/';
const read=p=>readFile(new URL(p,root));
let api,pack,report;
async function init(){if(api)return;api=await import('./curated-seventh-build.mjs');pack=JSON.parse(await read(folder+'normalized-recipes.json'));report=JSON.parse(await read(folder+'review-report.json'));}
async function filesBelow(path){
 const out=[];
 async function walk(dir,prefix='') {for(const entry of await readdir(new URL(dir,root),{withFileTypes:true})){const rel=prefix+entry.name;if(entry.isDirectory())await walk(dir+entry.name+'/',rel+'/');else out.push(rel);}}
 await walk(path);return out.sort();
}

test('eight exact archived revisions retain provenance and eight new source labels',async()=>{
 await init();assert.deepEqual(pack.recipes.map(r=>Number(r.id.split(':')[1])),[4024,6472,456825,456953,456979,457075,457525,457553]);
 assert.deepEqual(report.newLabels,['jamaican','russian','gambian','ugandan','cameroonian','libyan','zambian','malawian']);
 assert.equal(report.networkRequests,0);assert.equal(report.newBooks,0);assert.equal(report.frozenPreviousRecords,48);assert.equal(report.frozenPacks.length,6);
 assert.deepEqual(pack.counts,{recipes:8,ingredientLines:73,supplementalIngredients:2,steps:57,fullySpecified:0,needsReview:8,notCookable:0,sourceSupportedCuisineLabels:8,runtimeReady:0});
 assert.deepEqual(report.combinedLocal,{recipes:56,fullySpecified:10,needsReview:44,notCookable:2,ingredientLines:413,supplementalIngredients:25,steps:307,sourceSupportedCuisineLabels:50,runtimeReady:0});
 for(const r of pack.recipes){
  const bytes=await read(r.provenance.sourceSnapshotFile),snap=JSON.parse(bytes),raw=snap.sourceRecord,source=snap.authoritativeParsedRecipe;
  assert.equal(api.sha(bytes),r.provenance.sourceSnapshotSha256);assert.equal(api.sha(raw.sourceWikitext),raw.sourceSha256);
  assert.equal(raw.sourceSha256,r.provenance.sourceSha256);assert.equal(String(raw.sourceRevision),String(r.provenance.sourceRevision));
  assert.equal(raw.sourceRevisionTimestamp,r.provenance.sourceRevisionTimestamp);assert.equal(raw.retrievedAt,r.provenance.retrievedAt);assert.equal(raw.sourceUrl,r.provenance.sourceUrl);
  assert.deepEqual(raw.license,source.license);assert.equal(snapshotFingerprint(source),r.provenance.derivedRecipeSha256);
  assert.equal(snapshotFingerprint(source.license),r.provenance.licenseSha256);assert(r.cuisines.every(c=>raw.sourceCategories.includes(c.evidenceText)));
  assert.equal(r.status,'needs-review');assert.equal(r.runtimeReady,false);assert.equal(r.actuallyKitchenTested,false);assert.equal(r.nutrition,null);
  assert(r.ingredients.every(i=>i.scales===null&&i.foodBinding===null));assert.equal(r.ingredients.length,source.recipe.ingredients.length);assert.equal(r.steps.length,source.recipe.steps.length);
  for(let i=0;i<r.steps.length;i++)assert.deepEqual(r.steps[i].sourceStepIndices,[i]);
  assert(r.cuisines.every(c=>c.reviewStatus==='source-supported-not-runtime-approved'));
  const {contentSha256,...body}=r;assert.equal(snapshotFingerprint(body),contentSha256);
  const draftRow=report.newDraftReports.find(x=>x.curatedRecipeId===r.id);assert(draftRow);assert.equal(draftRow.runtimeReady,false);
  const draftBytes=await read(draftRow.draftFile),draft=JSON.parse(draftBytes);assert.equal(api.sha(draftBytes),draftRow.draftSha256);assert.equal(draft.lines.length,source.recipe.ingredients.length);
 }
 const jamaican=pack.recipes.find(r=>r.id.endsWith(':4024'));assert.deepEqual([jamaican.yield.amount,jamaican.yield.unit,jamaican.yield.sourceText],[4,'servings','4']);
 const libyan=pack.recipes.find(r=>r.id.endsWith(':457075'));assert.deepEqual([libyan.yield.min,libyan.yield.max,libyan.yield.sourceText],[4,6,'4–6']);
 const yassa=pack.recipes.find(r=>r.id.endsWith(':456825'));assert.equal(yassa.ingredients[0].amount,null);assert.equal(yassa.ingredients[0].sourceLineIndex,0);assert.match(yassa.steps[1].textAr,/ساعتين على الأقل أو طوال الليل/);
 const kwacoco=pack.recipes.find(r=>r.id.endsWith(':456979'));assert.equal(kwacoco.supplementalIngredients.length,2);assert.equal(kwacoco.yield.amount,null);
 const beans=pack.recipes.find(r=>r.id.endsWith(':457525'));assert.equal(beans.ingredients[6].amount,1);assert.match(beans.ingredients[6].decisionNote,/البدائل محفوظة/);
});

test('offline builder reproduces every seventh-pack file byte for byte',async()=>{
 await init();const paths=await filesBelow(folder),before=await Promise.all(paths.map(p=>read(folder+p)));
 const rebuilt=await api.build();assert.equal(rebuilt.pack.recipes.length,8);
 assert.deepEqual(await filesBelow(folder),paths);
 for(let i=0;i<paths.length;i++)assert.deepEqual(await read(folder+paths[i]),before[i]);
});
