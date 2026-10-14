import test from 'node:test';
import assert from 'node:assert/strict';
import {actual,validate,fingerprint} from './creator-fourth-validation.mjs';
const {batch,summary,prior}=await actual();
const copy=()=>structuredClone(batch);
const repin=r=>{delete r.contentSha256;r.contentSha256=fingerprint(r)};
test('actual five official creator recipes retain source facts and procedural extras',()=>{
 assert.deepEqual(summary,{recipes:5,ingredients:81,steps:15});
 const pasta=batch.recipes.find(r=>r.recipeId.endsWith('chicken-bechamel-pasta'));
 assert.equal(pasta.supplementalIngredients.length,3);
 assert.equal(pasta.ingredients.find(i=>i.labelAr==='دجاج مسلوق').amount,1000);
 assert.equal(pasta.ingredients[0].unit,'bag');
 assert.equal(batch.recipes.every(r=>r.cuisine===null&&r.yield.amount===null),true);
});
test('ambiguous RTL fractions and ranges stay unknown rather than guessed',()=>{
 const cake=batch.recipes.find(r=>r.recipeId.endsWith('apple-cake'));
 for(const raw of ['5-4','4/1','2 4/3','2/1','3-2'])assert.equal(cake.ingredients.find(i=>i.sourceQuantityText===raw).amount,null);
});
test('phase timings preserve published50-minute rice without manufacturing total',()=>{
 const kabsa=batch.recipes.find(r=>r.recipeId.endsWith('quick-chicken-kabsa'));
 assert.equal(kabsa.time.sourceTimers.at(-1).minutes,50);
 assert.equal(kabsa.time.cookMinutes,null);
});
test('edited recipe facts fail canonical content pin',()=>{
 const b=copy();b.recipes[0].ingredients[0].amount=4;
 assert.throws(()=>validate(b,prior),/content drift/);
});
test('source identity, implicit approvals and duplicate identity fail even if repinned',()=>{
 for(const edit of [r=>r.reuseRights=true,r=>r.cuisine={value:'invented'},r=>r.sourceUrl='https://example.com/a',r=>r.youtubeDerived=true,r=>r.foodBindings=[{foodId:'guessed'}]]){
  const b=copy();edit(b.recipes[0]);repin(b.recipes[0]);assert.throws(()=>validate(b,prior));
 }
 const b=copy();b.recipes[1].recipeId=b.recipes[0].recipeId;repin(b.recipes[1]);assert.throws(()=>validate(b,prior),/Duplicate/);
});
test('missing/reordered source steps and unsupported timer indices reject',()=>{
 for(const edit of [r=>r.steps[0].sourceStepIndices.shift(),r=>r.steps[1].sourceStepIndices.reverse(),r=>r.time.sourceTimers[0].sourceStepIndices=[999]]){
  const b=copy();edit(b.recipes[0]);repin(b.recipes[0]);assert.throws(()=>validate(b,prior));
 }
});
