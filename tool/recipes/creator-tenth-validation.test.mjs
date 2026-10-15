import test from 'node:test';
import assert from 'node:assert/strict';
import {actual,validate,fingerprint,canonicalUrl} from './creator-tenth-validation.mjs';
const {batch,prior,extracts,summary}=await actual();
const repin=b=>{for(const r of b.recipes){delete r.contentSha256;r.contentSha256=fingerprint(r)}return b};
test('website-only pack improves quantity evidence without inferring chicken unit or component yield',()=>{
 assert.equal(summary.recipes,2);assert.equal(summary.ingredients,18);assert.equal(summary.steps,9);assert.equal(summary.knownAmountAndUnitLines,11);assert.equal(summary.quantityIncompleteLines,7);
 assert.equal(batch.recipes[0].ingredients[7].amount,500);assert.equal(batch.recipes[0].ingredients[7].unit,null);
 assert.equal(batch.recipes[1].yield.amount,null);assert.equal(batch.recipes[1].time.publishedTotalMinutes,null);assert.equal(batch.recipes[1].sourceEvidence.sourcePageYield.amount,4);
 assert.equal(summary.underlyingRequests,8);assert.equal(summary.youtubeExtractions,0);assert.ok(prior.ids.length>0);
});
test('dedup rejects identity/title and www tracking URL variants, preserving YouTube case',()=>{
 const r=batch.recipes[0];
 for(const p of [{ids:[r.recipeId],titles:[],urls:[]},{ids:[],titles:[r.title],urls:[]},{ids:[],titles:[],urls:[r.sourceUrl.replace('://','://www.')+'?utm_source=x']}]){
  assert.throws(()=>validate(batch,p,extracts),/Duplicate/);
 }
 assert.notEqual(canonicalUrl('https://youtu.be/_DmSJzc2Ksc'),canonicalUrl('https://youtube.com/watch?v=_dmSJzc2Ksc'));
});
test('fail closed at request cap,90 percent, unavailable quota and ordinary false',()=>{
 const b=structuredClone(batch);b.sourceSearchLog[6].targets.push('https://example.com');b.sourceSearchLog[6].underlyingRequestIndices.push(9);b.underlyingRequestCount=9;assert.throws(()=>validate(b,prior,extracts),/cap exceeded/);
 for(const edit of [b=>b.quotaAtStart.primaryUsedPercent=90,b=>b.quotaAtStart.weeklyUsedPercent=null,b=>b.quotaAtStart.ordinaryUsageAllowed=false]){
  const b=structuredClone(batch);edit(b);assert.throws(()=>validate(b,prior,extracts));
 }
});
test('repinning cannot legitimize numeric guesses, component totals, video derivation or approvals',()=>{
 for(const edit of [b=>b.recipes[0].ingredients[7].unit='g',b=>b.recipes[1].yield.amount=4,b=>b.recipes[1].time.publishedTotalMinutes=30,b=>b.recipes[0].youtubeDerived=true,b=>b.recipes[0].sourceApproval=true,b=>b.recipes[0].sourceEvidence.fullPageRetrievedByWorker=true,b=>b.creator.identityStatus='official-verified']){
  const b=structuredClone(batch);edit(b);assert.throws(()=>validate(repin(b),prior,extracts));
 }
});
test('raw source hashes and normalized recipe pins reject drift',()=>{
 const b=structuredClone(batch);b.recipes[0].title+=' جديد';assert.throws(()=>validate(b,prior,extracts),/content drift/);
 const bad={...extracts,[batch.sourceIndex[0].extractFile]:Buffer.from('changed')};assert.throws(()=>validate(batch,prior,bad),/extract hash drift/);
});
