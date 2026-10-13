import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {validateReview} from './validate-reference-review.mjs';
const review=JSON.parse(await readFile('data/nutrition/recipe-reference-review.json','utf8'));
test('shipped review preserves exact source hashes, line identity and USDA provenance',async()=>{
  const result=await validateReview(review);
  assert.deepEqual(result,{entries:197,recipes:53,foodReferences:36});
});
test('stale recipe source evidence and changed quantities cannot be restamped',async()=>{
  const stale=structuredClone(review); stale.entries[0].recipeSourceSha256='a'.repeat(64);
  await assert.rejects(validateReview(stale),/Recipe source hash/);
  const quantity=structuredClone(review); quantity.entries[0].originalQuantity=499;
  await assert.rejects(validateReview(quantity),/Recipe quantity/);
});
test('source revision changes and compound deblocking are rejected',async()=>{
  const stale=structuredClone(review); stale.entries[0].candidates[0].sourceVersion='wrong';
  await assert.rejects(validateReview(stale),/Food source identity/);
  const compound=structuredClone(review); compound.entries.find(e=>e.blocked).blocked=false;
  await assert.rejects(validateReview(compound),/Compound/);
});
