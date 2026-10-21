import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';

const root=fileURLToPath(new URL('../../',import.meta.url));
const lanes=['asian','gulf','balkan-tibetan'];
const pathFor=lane=>`data/recipes/arabic-youtube/modern-expansion-20261021-${lane}/recipes.json`;
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const read=path=>readFile(resolve(root,path));
async function records(){
 const packs=await Promise.all(lanes.map(async lane=>({file:pathFor(lane),data:JSON.parse(await read(pathFor(lane)))})));
 return packs.flatMap(({file,data})=>data.recipes.map(row=>({file,row})));
}

test('15 modern source records cover seven explicitly evidenced new labels without runtime promotion',async()=>{
 const rows=await records();assert.equal(rows.length,15);
 const cuisines={};
 for(const {row:r} of rows){
   assert.equal(r.runtimeReady,false);assert.equal(r.nutrition,null);
   assert.equal(r.youtubeDerived,false);assert.equal(r.sourceKind,'creator-website');
   assert.equal(r.httpBodyHash,null);assert.equal(r.sourceApproval,null);
   assert.ok(r.reuseRights===null||r.reuseRights==='unknown');
   assert.ok(r.ingredients.length>0&&r.steps.length>0);
   assert.ok(r.cuisine.evidence&&r.cuisine.evidenceUrl===r.sourceUrl);
   assert.ok(r.ingredients.every((i,n)=>i.labelAr&&i.sourceQuantityText&&i.sourceIngredientIndex===n));
   assert.ok(r.steps.every(s=>s.textAr&&s.sourceStepIndices.length));
   cuisines[r.cuisine.value]=(cuisines[r.cuisine.value]??0)+1;
 }
 assert.deepEqual(cuisines,{Filipino:5,Singaporean:2,Nepalese:1,Omani:2,Yemeni:2,Bosnian:2,Tibetan:1});
});

test('compact evidence hashes pin saved facts without claiming archived HTTP bodies',async()=>{
 for(const {file,row:r} of await records()){
   const p=r.sourceEvidence.sourceExtractFile;
   const evidence=p.startsWith('data/')?p:dirname(file)+'/'+p;
   assert.match(evidence,/^data\/recipes\/arabic-youtube\/modern-expansion-20261021-[\w-]+\/source-extracts\/[\w.-]+$/);
   assert.equal(sha(await read(evidence)),r.sourceEvidence.sourceExtractSha256,r.recipeId);
   assert.equal(r.sourceEvidence.rawBodyArchived,false);
 }
});

test('stored method indices cover the declared evidence domain; grouped summaries are explicitly distinguished',async()=>{
 for(const {row:r} of await records()){
   const indices=[...new Set(r.steps.flatMap(s=>s.sourceStepIndices))].sort((a,b)=>a-b);
   assert.deepEqual(indices,Array.from({length:r.sourceStepCount},(_,n)=>n),r.recipeId);
   if(!r.recipeId.startsWith('dina-')&&!r.recipeId.startsWith('amjaad-')){
     assert.equal(r.sourceStepIndexSemantics,'saved-evidence-summary-segment,not-source-native-step',r.recipeId);
     assert.notEqual(r.sourceEvidence.nativeSourceStepCoverageVerified,true);
   }
 }
});

test('four grouped Asian methods remain partial; only11new records have complete ingredient-and-method evidence',async()=>{
 const rows=(await records()).map(({row})=>row);
 const partial=rows.filter(r=>r.sourceEvidence.methodCompleteInExtract===false);
 assert.deepEqual(partial.map(r=>r.recipeId),[
   'panlasang-pinoy-lechon-kawali-20261021',
   'delishar-singapore-chilli-crab-cream-pasta-20261021',
   'delishar-singapore-chilli-crab-cake-pasta-20261021',
   'nepali-food-recipes-aloo-bodi-tama-20261021',
 ]);
 assert.equal(rows.filter(r=>r.sourceEvidence.methodCompleteInExtract===true).length,11);
});

test('new source URLs are unique and baseline23 packs and snapshot pins remain exact',async()=>{
 const frozen=JSON.parse(await read('data/recipes/curated-local/bulk-5000-20261021/baseline-manifest.json'));
 const baselineUrls=new Set(),modernUrls=new Set();
 const canonical=url=>new URL(url).href.replace(/\/comment-page-\d+\/?$/,'/');
 for(const p of frozen.packs){
   const bytes=await read(p.file);assert.equal(sha(bytes),p.sha256);
   for(const r of JSON.parse(bytes).recipes){const url=r.sourceUrl??r.provenance?.sourceUrl;if(url)baselineUrls.add(canonical(url));}
   for(const s of p.sourceSnapshots)assert.equal(sha(await read(s.file)),s.sha256);
 }
 assert.equal(frozen.packs.length,23);
 for(const {row:r} of await records()){
   const url=canonical(r.sourceUrl);assert.ok(!modernUrls.has(url)&&!baselineUrls.has(url),r.recipeId);modernUrls.add(url);
 }
});

test('ranges and source units remain unresolved rather than invented scalar conversions',async()=>{
 const map=new Map((await records()).map(({row})=>[row.recipeId,row]));
 const bread=map.get('balkan-lunchbox-bosnian-tepsijas-20261021');
 assert.equal(bread.ingredients[5].amount,null);assert.equal(bread.ingredients[6].amount,null);
 assert.equal(bread.ingredients[6].optional,true);assert.equal(bread.time.totalMinutes,null);
 const thue=map.get('yowangdu-tibetan-thue-20261021');
 assert.equal(thue.yield.unit,'bricks');assert.equal(thue.yield.servings,null);
 assert.equal(thue.ingredients[2].unit,'stick');assert.equal(thue.time.cookMinutes,null);
});
