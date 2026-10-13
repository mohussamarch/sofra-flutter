import test from 'node:test';
import assert from 'node:assert/strict';
import {reviewTarget,snapshotFingerprint} from './review-target.mjs';
import {validateIdentityBank} from './validate-identity-bank.mjs';
function fixture(){
 const recipe={id:'fixture:recipe',recordId:'fixture-r1',sourceId:'fixture-source',sourceRevision:'1',sourceSha256:'a'.repeat(64),sourceUrl:'https://example.org/recipe',parserVersion:'v3',quantityParserVersion:'v2',license:{id:'fixture-license',pageExceptionStatus:'unreviewed'},recipe:{ingredients:[{id:'line-1',sourceText:'1 cup synthetic sugar',foodBinding:null}],nutrition:null}};
 const food={id:'usda:1',version:'fixture-v1',name:'Synthetic food only',nutrition:null};
 const evidence={sourceId:'usda',license:'CC0-1.0',shardSha256:'b'.repeat(64)};
 const bank={schemaVersion:1,status:'identity-proposals-unreviewed',createdAt:'2026-10-13T16:00:00.000Z',recipeSources:[{recipeId:recipe.id,recordId:recipe.recordId,sourceUrl:recipe.sourceUrl,sourceSha256:recipe.sourceSha256,license:structuredClone(recipe.license),changeNotice:'Synthetic fixture annotation only'}],foodEvidence:[{foodId:food.id,foodSnapshotSha256:snapshotFingerprint(food),sourceEvidence:structuredClone(evidence)}],proposals:[{schemaVersion:1,status:'identity-proposal-unreviewed',target:reviewTarget(recipe,0),candidates:[{foodId:food.id,foodVersion:food.version,foodSnapshotSha256:snapshotFingerprint(food),rationale:'Synthetic fixture only'}],issues:['Not an approved identity']}],limitations:['No runtime approvals']};
 return {bank,recipe,food,evidence,options:{recipes:new Map([[recipe.id,recipe]]),loadFoods:async()=>({snapshots:new Map([[food.id,food]]),evidence:new Map([[food.id,evidence]])})}};
}
test('validates source/food provenance independently and reports zero approvals',async()=>{
 const f=fixture(),before=structuredClone(f.bank);const result=await validateIdentityBank(f.bank,f.options);assert.equal(result.proposalCount,1);assert.equal(result.runtimeReadyCount,0);assert.deepEqual(f.bank,before);
});
test('missing or altered recipe attribution/source/licence fails',async()=>{
 for(const edit of [b=>b.recipeSources=[],b=>b.recipeSources[0].sourceUrl='https://example.org/other',b=>b.recipeSources[0].license.id='wrong',b=>b.recipeSources[0].changeNotice='']){const f=fixture();edit(f.bank);await assert.rejects(validateIdentityBank(f.bank,f.options));}
});
test('food provenance and snapshot hash must match freshly loaded authoritative data',async()=>{
 for(const edit of [b=>b.foodEvidence=[],b=>b.foodEvidence[0].sourceEvidence.license='wrong',b=>b.foodEvidence[0].foodSnapshotSha256='c'.repeat(64)]){const f=fixture();edit(f.bank);await assert.rejects(validateIdentityBank(f.bank,f.options));}
});
test('duplicate targets and extra approval/selection fields fail',async()=>{
 const f=fixture();f.bank.proposals.push(structuredClone(f.bank.proposals[0]));await assert.rejects(validateIdentityBank(f.bank,f.options));
 const g=fixture();g.bank.runtimeReadyCount=1;await assert.rejects(validateIdentityBank(g.bank,g.options));
});
test('stale recipe or food source versions fail instead of rewriting the proposal',async()=>{
 const f=fixture();f.recipe.recipe.ingredients[0].sourceText='Changed source';await assert.rejects(validateIdentityBank(f.bank,f.options));
 const g=fixture();g.food.version='changed';await assert.rejects(validateIdentityBank(g.bank,g.options));
});
test('unresolved proposals preserve issues without loading any food or creating nutrition',async()=>{
 const f=fixture();f.bank.proposals[0].candidates=[];f.bank.foodEvidence=[];f.options.loadFoods=async()=>{throw new Error('No food should be loaded');};const result=await validateIdentityBank(f.bank,f.options);assert.equal(result.unresolvedCount,1);assert.equal(result.foodCount,0);
});
