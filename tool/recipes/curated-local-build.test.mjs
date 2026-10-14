import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {normalize,validateDecision} from './curated-local-build.mjs';
import {snapshotFingerprint} from './review-target.mjs';
const dir=new URL('../../data/recipes/curated-local/first-reviewed-20261014/',import.meta.url);
const pack=JSON.parse(await readFile(new URL('normalized-recipes.json',dir),'utf8'));
const decisions=JSON.parse(await readFile(new URL('review-decisions.json',dir),'utf8'));
const snapshots=new Map();
for(const r of pack.recipes)snapshots.set(r.id,JSON.parse(await readFile(new URL('../../'+r.provenance.sourceSnapshotFile,import.meta.url),'utf8')));
const copy=v=>structuredClone(v);
const fixture=id=>{
 const record=pack.recipes.find(r=>r.id===id);
 const snapshot=snapshots.get(id);
 return {record,decision:copy(decisions.recipes.find(d=>'curated-local:'+d.sourcePageId===id)),source:snapshot.authoritativeParsedRecipe,raw:snapshot.sourceRecord};
};
test('all16 curated recipes preserve exact archived source/license and full record pins',async()=>{
 assert.equal(pack.recipes.length,16);const ids=new Set();
 for(const r of pack.recipes){
   assert(!ids.has(r.id));ids.add(r.id);
   const bytes=await readFile(new URL('../../'+r.provenance.sourceSnapshotFile,import.meta.url));
   assert.equal(createHash('sha256').update(bytes).digest('hex'),r.provenance.sourceSnapshotSha256);
   const snap=snapshots.get(r.id),source=snap.authoritativeParsedRecipe,raw=snap.sourceRecord;
   assert.equal(createHash('sha256').update(raw.sourceWikitext).digest('hex'),r.provenance.sourceSha256);
   assert.equal(snapshotFingerprint(source),r.provenance.derivedRecipeSha256);
   assert.equal(snapshotFingerprint(r.provenance.license),r.provenance.licenseSha256);
   assert.equal(source.sourceRevision,r.provenance.sourceRevision);
   const {contentSha256,...withoutHash}=r;
   assert.equal(snapshotFingerprint(withoutHash),contentSha256);
   const d=decisions.recipes.find(d=>'curated-local:'+d.sourcePageId===r.id);
   assert.equal(validateDecision(d,source,raw),true);
 }
});
test('changed full source revision cannot reuse a manual curation decision',()=>{
 const {decision,source,raw}=fixture('curated-local:264763');
 const changed=copy(source);changed.recipe.ingredients[0].sourceText='changed milk';
 assert.throws(()=>validateDecision(decision,changed,raw),/revision drift/);
 const shifted=copy(source);shifted.sourceRevision='other-revision';
 assert.throws(()=>validateDecision(decision,shifted,raw),/revision drift/);
});
test('cuisine requires actual raw source evidence; language alone is rejected',()=>{
 const {decision,source,raw}=fixture('curated-local:141667');
 decision.cuisines=[['english','English cuisine','Category:English cuisine']];
 assert.throws(()=>validateDecision(decision,source,raw),/Cuisine evidence/);
 assert.equal(pack.recipes.find(r=>r.id==='curated-local:456620').cuisines.length,0);
 const swahili=pack.recipes.find(r=>r.id==='curated-local:483733');
 assert.equal(swahili.cuisines[0].id,'swahili');
 assert(!swahili.cuisines.some(c=>c.id==='senegalese'));
});
test('explicit source quantity choices retain units, ranges, pieces and unknowns',()=>{
 const mango=pack.recipes.find(r=>r.id==='curated-local:455788');
 assert.equal(mango.ingredients[3].amount,250);assert.equal(mango.ingredients[3].unit,'ml');
 const kulfi=pack.recipes.find(r=>r.id==='curated-local:264763');
 assert.equal(kulfi.yield.amount,null);assert.equal(kulfi.yield.min,4);assert.equal(kulfi.yield.max,6);
 const naan=pack.recipes.find(r=>r.id==='curated-local:456620');
 assert.equal(naan.yield.unit,'dough-balls');assert.equal(naan.supplementalIngredients[0].amount,1);
 assert.equal(naan.supplementalIngredients[1].amount,null);
 for(const r of pack.recipes){
  assert.equal(r.runtimeReady,false);assert.equal(r.nutrition,null);assert.equal(r.time.cookMinutes,null);
  assert(r.ingredients.every(i=>i.foodBinding===null&&i.scales===null));
 }
});
test('source omissions and unresolved procedural ingredients cannot be called fully specified',()=>{
 const {decision,source,raw}=fixture('curated-local:33064');
 decision.status='fully-specified';
 assert.throws(()=>validateDecision(decision,source,raw),/supplemental amounts/);
 const incomplete=fixture('curated-local:141667');
 incomplete.decision.ingredients.pop();
 assert.throws(()=>validateDecision(incomplete.decision,incomplete.source,incomplete.raw),/Every source ingredient/);
});
test('every source step is covered or explicitly excluded and optional choices never sum alternatives',()=>{
 for(const r of pack.recipes){
  const source=snapshots.get(r.id).authoritativeParsedRecipe;
  const covered=new Set([...r.steps.flatMap(s=>s.sourceStepIndices),...r.excludedSourceSteps.map(s=>s.sourceStepIndex)]);
  assert.equal(covered.size,source.recipe.steps.length);
 }
 const sauce=pack.recipes.find(r=>r.id==='curated-local:303834');
 assert.equal(sauce.excludedSourceSteps[0].sourceStepIndex,1);
 assert.equal(sauce.ingredients[4].unit,'tsp');assert.equal(sauce.ingredients[4].amount,1);
 const rice=pack.recipes.find(r=>r.id==='curated-local:483733');
 assert.equal(rice.ingredients[4].included,false);assert.equal(rice.ingredients[4].optional,true);
 const bad=fixture('curated-local:141667');bad.decision.steps=[];
 assert.throws(()=>validateDecision(bad.decision,bad.source,bad.raw),/Invalid source step/);
});
test('only genuine naan technique difference is counted; soda breads remain ingredient variants',()=>{
 assert.equal(pack.relationships.length,2);
 assert.equal(pack.relationships.filter(g=>g.relationship==='same-dish-distinct-methods').length,1);
 const naan=pack.relationships.find(g=>g.familyId==='curated-local:naan');
 assert.equal(naan.recipeIds.length,2);
 assert.equal(new Set(naan.recipeIds.map(id=>pack.recipes.find(r=>r.id===id).methodId)).size,2);
 assert.equal(pack.relationships.find(g=>g.familyId==='curated-local:irish-soda-bread').relationship,'same-dish-ingredient-variants');
 assert.deepEqual(pack.counts,{fullySpecified:4,needsReview:10,notCookable:2,distinctMethodFamilies:1,sourceSupportedCuisineLabels:11,runtimeReady:0});
 assert.equal(pack.duplicateReview.existingCatalogueCount,54);assert.equal(pack.duplicateReview.initialResearchCount,6);
 assert.deepEqual(pack.duplicateReview.exactCatalogueNameMatches,[]);assert.deepEqual(pack.duplicateReview.exactInitialSourceMatches,[]);
});
test('normalization never mutates original authoritative recipe or review choices',()=>{
 const {decision,source,raw,record}=fixture('curated-local:264763');
 const before=snapshotFingerprint({decision,source,raw});
 const normalized=normalize(decision,source,raw,record.provenance);
 assert.equal(snapshotFingerprint({decision,source,raw}),before);
 assert.equal(normalized.actuallyKitchenTested,false);
 assert.equal(normalized.gates.perPageLicenseApproved,false);
});


test('four populated existing preflight drafts retain explicit quantities and unresolved timing/scaling/food gates',async()=>{
 const artifact=JSON.parse(await readFile(new URL('preflight-reports.json',dir),'utf8'));
 assert.equal(artifact.registeredInSharedRegistry,false);assert.equal(artifact.reports.length,4);
 for(const report of artifact.reports){
   const bytes=await readFile(new URL('../../'+report.draftFile,import.meta.url));
   assert.equal(createHash('sha256').update(bytes).digest('hex'),report.draftSha256);
   const draft=JSON.parse(bytes),recipe=pack.recipes.find(r=>r.provenance.derivedRecipeSha256===draft.recipeSha256);
   assert(recipe);assert.equal(draft.lines.length,recipe.ingredients.length);
   assert(draft.lines.every(l=>l.components.length===1&&l.components[0].amount>0&&l.components[0].scales===null&&l.components[0].food===null));
   assert.equal(report.draftComplete,false);assert.equal(report.runtimeReady,false);
   assert(report.issues.some(i=>i.code==='prep-time'));assert(report.issues.some(i=>i.code==='cook-time'));
   assert(report.issues.some(i=>i.code==='step-time'));assert(report.issues.some(i=>i.code==='scaling'));
   assert(report.issues.some(i=>i.code==='food-reference'));
 }
});
