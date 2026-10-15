import test from 'node:test';
import assert from 'node:assert/strict';
import {actual,validate,fingerprint,canonicalUrl} from './creator-ninth-validation.mjs';
const {batch,prior,extracts,summary}=await actual();
const repin=b=>{for(const r of b.recipes){delete r.contentSha256;r.contentSha256=fingerprint(r)}return b};
test('two indexed descriptions preserve quantities, attribution and request cap',()=>{
 assert.equal(summary.recipes,2);assert.equal(summary.ingredients,17);assert.equal(summary.unknownQuantityLines,17);assert.equal(summary.steps,10);
 assert.equal(summary.underlyingRequests,4);assert.equal(summary.completeDirectVideoSources,0);assert.ok(prior.ids.length>0);
});
test('dedup rejects identities, titles, canonical tracking and short URLs',()=>{
 const r=batch.recipes[0];
 for(const p of [{ids:[r.recipeId],titles:[],urls:[]},{ids:[],titles:[r.title],urls:[]},{ids:[],titles:[],urls:[r.sourceUrl+'&t=30']},{ids:[],titles:[],urls:['https://youtu.be/'+r.sourceVideoId+'?si=tracking']}]){
  assert.throws(()=>validate(batch,p,extracts),/Duplicate/);
 }
 assert.notEqual(canonicalUrl(batch.recipes[0].sourceUrl),canonicalUrl(batch.recipes[0].sourceUrl.replace('_DmSJzc2Ksc','_dmSJzc2Ksc')));
});
test('fail closed on excess underlying requests, unknown quota or unavailable ordinary usage',()=>{
 for(const edit of [b=>b.sourceSearchLog[2].targets.push('https://example.com'),b=>b.quotaAtStart.primaryUsedPercent=90,b=>b.quotaAtStart.weeklyUsedPercent=null,b=>b.quotaAtStart.ordinaryUsageAllowed=false]){
  const b=structuredClone(batch);edit(b);assert.throws(()=>validate(b,prior,extracts));
 }
});
test('direct-body, approval, unknown quantity and step changes are rejected after repinning',()=>{
 for(const edit of [b=>b.recipes[0].sourceEvidence.fullPageRetrievedByWorker=true,b=>b.recipes[0].sourceApproval=true,b=>b.recipes[0].ingredients[0].amount=1,b=>b.recipes[0].time.totalMinutes=30,b=>b.recipes[0].sourceVideoId='wrong',b=>b.recipes[0].steps.reverse(),b=>b.recipes[0].cuisine.value='مصري']){
  const b=structuredClone(batch);edit(b);assert.throws(()=>validate(repin(b),prior,extracts));
 }
});
test('recipe bytes and raw extract hashes are checked',()=>{
 const b=structuredClone(batch);b.recipes[0].title+=' جديد';assert.throws(()=>validate(b,prior,extracts),/content drift/);
 const bad={...extracts,[batch.sourceIndex[0].extractFile]:Buffer.from('changed')};
 assert.throws(()=>validate(batch,prior,bad),/extract hash drift/);
});
