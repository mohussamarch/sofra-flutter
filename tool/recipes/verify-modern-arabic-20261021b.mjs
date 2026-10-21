import fs from 'node:fs';import {createHash} from 'node:crypto';
const batch=JSON.parse(fs.readFileSync('data/recipes/modern-scale-20261021b-arabic/recipes.json','utf8'));
const sha=s=>createHash('sha256').update(s,'utf8').digest('hex');
const sorted=v=>Array.isArray(v)?v.map(sorted):v&&typeof v==='object'?Object.fromEntries(Object.keys(v).sort().map(k=>[k,sorted(v[k])])):v;
const urls=new Set(),ids=new Set();const errors=[];
for(const [i,r] of batch.recipes.entries()){
 if(urls.has(r.sourceUrl))errors.push(`duplicate URL ${i}`);urls.add(r.sourceUrl);
 if(ids.has(r.recipeId))errors.push(`duplicate id ${i}`);ids.add(r.recipeId);
 const note=fs.readFileSync(r.sourceEvidence.sourceExtractFile,'utf8');if(sha(note)!==r.sourceEvidence.sourceExtractSha256)errors.push(`extract hash ${i}`);
 const copy={...r};delete copy.contentSha256;if(sha(JSON.stringify(sorted(copy)))!==r.contentSha256)errors.push(`recipe hash ${i}`);
 if(!r.sourceEvidence.ingredientListCompleteInExtract||!r.sourceEvidence.methodCompleteInExtract||r.steps.length!==r.sourceStepCount)errors.push(`incomplete ${i}`);
 if(r.steps.some((s,j)=>s.sourceStepIndices.length!==1||s.sourceStepIndices[0]!==j))errors.push(`method indices ${i}`);
}
if(batch.requestLog.length!==batch.underlyingHttpRequestCount)errors.push('request log length');
if(batch.sourceIndex.length!==batch.recipes.length)errors.push('source index length');
console.log(JSON.stringify({records:batch.recipes.length,ingredients:batch.counts.sourceIngredients,steps:batch.counts.sourceMethodSteps,requests:batch.underlyingHttpRequestCount,log:batch.requestLog.length,complete:batch.counts.completeIngredientsAndMethods,failedHttpRequests:batch.requestLog.filter(x=>x.status!==200).map(x=>({request:x.request,status:x.status,target:x.target})),errors:errors.slice(0,20),errorCount:errors.length}));
