import test from 'node:test';
import assert from 'node:assert/strict';
import {readdir, readFile} from 'node:fs/promises';
import {snapshotFingerprint} from './review-target.mjs';

const root=new URL('../../',import.meta.url),folder='data/recipes/curated-local/eighth-reviewed-20261015/';
const read=p=>readFile(new URL(p,root));
let api,pack,report;
async function init(){if(api)return;api=await import('./curated-eighth-build.mjs');pack=JSON.parse(await read(folder+'normalized-recipes.json'));report=JSON.parse(await read(folder+'review-report.json'));}
async function filesBelow(path){
 const out=[];
 async function walk(dir,prefix='') {for(const entry of await readdir(new URL(dir,root),{withFileTypes:true})){const rel=prefix+entry.name;if(entry.isDirectory())await walk(dir+entry.name+'/',rel+'/');else out.push(rel);}}
 await walk(path);return out.sort();
}

test('six exact archived revisions retain provenance, conflicts, quantities and source labels',async()=>{
 await init();assert.deepEqual(pack.recipes.map(r=>Number(r.id.split(':')[1])),[13447,14459,219286,294156,234180,452631]);
 assert.deepEqual(report.newLabels,['norwegian']);
 assert.equal(report.networkRequests,0);assert.equal(report.newBooks,0);assert.equal(report.frozenPreviousRecords,56);assert.equal(report.frozenPacks.length,7);
 assert.deepEqual(pack.counts,{recipes:6,ingredientLines:44,supplementalIngredients:4,steps:32,fullySpecified:0,needsReview:6,notCookable:0,sourceSupportedCuisineLabels:5,runtimeReady:0});
 assert.deepEqual(report.combinedLocal,{recipes:62,fullySpecified:10,needsReview:50,notCookable:2,ingredientLines:457,supplementalIngredients:29,steps:339,sourceSupportedCuisineLabels:51,runtimeReady:0});
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
 const bulgogi=pack.recipes.find(r=>r.id.endsWith(':13447'));assert.equal(bulgogi.ingredients[0].amount,450);assert.equal(bulgogi.ingredients[0].unit,'g');assert.equal(bulgogi.ingredients[8].amount,null);assert.equal(bulgogi.ingredients[2].optional,true);assert.match(bulgogi.notes.join(' '),/التعارض/);assert.equal(bulgogi.yield.amount,6);
 const moqueca=pack.recipes.find(r=>r.id.endsWith(':14459'));assert.equal(moqueca.ingredients[5].optional,false);assert.equal(moqueca.ingredients[8].amount,200);assert.equal(moqueca.ingredients[8].unit,'ml');assert.equal(moqueca.ingredients[9].amount,null);assert.equal(moqueca.supplementalIngredients.length,1);
 const cheese=pack.recipes.find(r=>r.id.endsWith(':219286'));assert.equal(cheese.time.declaredTotalMinutes,5);assert.equal(cheese.ingredients[3].optional,true);assert.equal(cheese.ingredients[3].amount,null);assert.equal(cheese.steps[4].duration.min,1);assert.equal(cheese.steps[4].duration.max,2);
 const lefse=pack.recipes.find(r=>r.id.endsWith(':294156'));assert.equal(lefse.yield.amount,null);assert.equal(lefse.yield.sourceText,'About 40 lefse');assert.equal(lefse.time.prepMinutes,null);assert.equal(lefse.time.cookMinutes,60);assert.equal(lefse.supplementalIngredients.length,2);
 const klepon=pack.recipes.find(r=>r.id.endsWith(':234180'));assert.equal(klepon.ingredients[0].amount,null);assert.equal(klepon.ingredients[5].amount,null);assert.equal(klepon.steps[3].duration.approximate,true);
 const rice=pack.recipes.find(r=>r.id.endsWith(':452631'));assert.equal(rice.ingredients[0].amount,300);assert.equal(rice.ingredients[1].amount,400);assert.equal(rice.ingredients[4].amount,null);assert.match(rice.notes.join(' '),/التناقض/);assert.equal(rice.time.cookMinutes,null);
 assert.equal(report.draftIssues,151);assert.equal(report.creatorArchiveRecords,22);

});

test('offline builder reproduces every eighth-pack file byte for byte',async()=>{
 await init();const paths=await filesBelow(folder),before=await Promise.all(paths.map(p=>read(folder+p)));
 const rebuilt=await api.build();assert.equal(rebuilt.pack.recipes.length,6);
 assert.deepEqual(await filesBelow(folder),paths);
 for(let i=0;i<paths.length;i++)assert.deepEqual(await read(folder+paths[i]),before[i]);
});
