import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {actual,validateRecord,dedup,specs,sha} from './curated-twelfth-validation.mjs';
import {snapshotFingerprint} from './review-target.mjs';
const a=await actual(),root=new URL('../../',import.meta.url);
const snapshots=await Promise.all(a.pack.recipes.map(r=>readFile(new URL(r.provenance.sourceSnapshotFile,root),'utf8').then(JSON.parse)));
const repin=r=>{delete r.contentSha256;r.contentSha256=snapshotFingerprint(r);return r};
test('two archived recipes preserve exact revisions, source categories and zero network',()=>{
 assert.deepEqual(a.summary.newLabels,['egyptian','cypriot']);assert.equal(a.summary.ingredientLines,16);assert.equal(a.summary.supplementalIngredients,2);assert.equal(a.summary.steps,12);assert.equal(a.summary.needsReview,2);assert.equal(a.summary.runtimeReady,0);
 assert.equal(a.summary.networkRequests,0);assert.equal(a.summary.newBooks,0);assert.ok(a.summary.priorPacksChecked>0);assert.ok(a.summary.priorRecordsChecked>0);
 for(let i=0;i<2;i++){assert.equal(snapshots[i].sourceRecord.sourceRevision,specs[i].revision);assert(snapshots[i].sourceRecord.sourceCategories.includes(specs[i].cuisine[2]));assert.equal(sha(snapshots[i].sourceRecord.sourceWikitext),a.pack.recipes[i].provenance.sourceSha256)}
});
test('quantity ranges, unspecified spoons, alternatives, missing totals and optional extras remain explicit',()=>{
 const [stew,salad]=a.pack.recipes;
 assert.equal(stew.time.prepMinutes,20);assert.equal(stew.time.cookMinutes,60);assert.equal(stew.time.declaredTotalMinutes,null);assert.equal(stew.yield.amount,4);
 assert.equal(stew.ingredients[4].amount,null);assert.match(stew.ingredients[4].sourceText,/or.*4 tablespoons/);assert.equal(stew.supplementalIngredients.length,2);assert(stew.supplementalIngredients.every(g=>g.optional&&g.amount===null));
 assert.equal(salad.yield.amount,null);assert.equal(salad.time.cookMinutes,null);assert.equal(salad.ingredients[5].amount,null);assert.match(salad.ingredients[5].sourceText,/5–6/);assert.equal(salad.ingredients[4].unit,'spoon-unspecified');
});
test('source category, revision, quantity and unsupported readiness changes fail even after content repinning',()=>{
 for(const edit of [r=>r.cuisines[0].evidenceText='Category:Invented recipes',r=>r.provenance.sourceRevision='0',r=>r.ingredients[4].amount=4,r=>r.time.declaredTotalMinutes=80,r=>r.runtimeReady=true,r=>r.nutrition={},r=>r.steps.reverse()]){
  const r=structuredClone(a.pack.recipes[0]);edit(r);repin(r);assert.throws(()=>validateRecord(r,snapshots[0],specs[0],snapshots[0].authoritativeParsedRecipe));
 }
 const r=structuredClone(a.pack.recipes[1]);r.ingredients[4].unit='tbsp';repin(r);assert.throws(()=>validateRecord(r,snapshots[1],specs[1],snapshots[1].authoritativeParsedRecipe),/Quantity/);
});
test('dedup compares current selected identities, normalized titles, families and source URLs',()=>{
 const r=a.pack.recipes[0];
 for(const p of [{id:r.id},{nameAr:r.nameAr},{familyId:r.familyId},{sourceUrl:r.provenance.sourceUrl+'&utm_source=x'}])assert.throws(()=>dedup([r],[p]),/Duplicate/);
});
test('raw source and normalized record drift are detected',()=>{
 const r=structuredClone(a.pack.recipes[0]);r.notes.push('changed');assert.throws(()=>validateRecord(r,snapshots[0],specs[0],snapshots[0].authoritativeParsedRecipe),/content drift/);
 const bad=structuredClone(snapshots[0]);bad.sourceRecord.sourceWikitext+='changed';assert.throws(()=>validateRecord(a.pack.recipes[0],bad,specs[0],snapshots[0].authoritativeParsedRecipe),/hash drift/);
});
