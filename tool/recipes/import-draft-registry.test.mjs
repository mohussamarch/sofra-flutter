import test from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {validateImportDraftRegistry} from './import-draft-registry.mjs';
import {emptyImportDraft} from './import-preflight.mjs';
import {snapshotFingerprint} from './review-target.mjs';
const hash=b=>createHash('sha256').update(b).digest('hex');
function fixture(){
 const recipe={id:'wikibooks:1',recordId:'r12',sourceId:'fixture',sourceRevision:'12',sourceSha256:'a'.repeat(64),parserVersion:'v3',quantityParserVersion:'v2',sourceUrl:'https://example.test/rev12',license:{id:'fixture-license'},changeNotice:'Unreviewed extraction',recipe:{ingredients:[{id:'line1',sourceText:'Flour'}],steps:[{n:1,text:'Mix'}],nutrition:null}};
 const draft=emptyImportDraft(recipe),bytes=Buffer.from(JSON.stringify(draft)+'\n');
 const registry={schemaVersion:1,status:'import-draft-registry-unreviewed',entries:[{id:'sample',file:'sample.json',sha256:hash(bytes),source:{recipeId:recipe.id,recordId:recipe.recordId,sourceUrl:recipe.sourceUrl,sourceSha256:recipe.sourceSha256,license:recipe.license,changeNotice:recipe.changeNotice}}],limitations:['Synthetic only; no runtime approval']};
 const options={recipes:new Map([[recipe.id,recipe]]),readDraft:async()=>bytes,loadFoods:async()=>{throw Error('No food load expected');}};
 return {recipe,draft,bytes,registry,options};
}
test('registered unresolved draft remains unresolved, source/draft/registry are not mutated',async()=>{
 const {registry,options}=fixture(),before=structuredClone(registry);
 const result=await validateImportDraftRegistry(registry,options);
 assert.equal(result.draftCount,1);assert.equal(result.completeDraftCount,0);assert.equal(result.runtimeReadyCount,0);assert.ok(result.drafts[0].issueCount>0);assert.deepEqual(registry,before);
});
test('raw draft byte changes fail even equivalent JSON whitespace',async()=>{
 const {registry,options,bytes}=fixture();
 await assert.rejects(validateImportDraftRegistry(registry,{...options,readDraft:async()=>Buffer.concat([bytes,Buffer.from(' ')])}),/hash/i);
 await assert.rejects(validateImportDraftRegistry(registry,{...options,readDraft:async()=>bytes.toString()}),/raw bytes/i);
});
test('unsafe files and duplicate registry IDs/files fail before any reads',async()=>{
 const {registry,options}=fixture();
 for(const file of ['../sample.json','C:/sample.json','sample.JSON','nested/sample.json']){const r=structuredClone(registry);r.entries[0].file=file;await assert.rejects(validateImportDraftRegistry(r,{...options,readDraft:async()=>{assert.fail('Unsafe read');}}),/file/i);}
 for(const edit of [r=>r.entries.push({...r.entries[0],file:'other.json'}),r=>r.entries.push({...r.entries[0],id:'other'})]){const r=structuredClone(registry);edit(r);await assert.rejects(validateImportDraftRegistry(r,options),/duplicate/i);}
});
test('source URL/record/licence/change notice and recipe identity must match current authoritative source',async()=>{
 const {registry,options}=fixture();
 for(const [field,value] of [['recipeId','unknown'],['recordId','r13'],['sourceUrl','https://other.test'],['sourceSha256','b'.repeat(64)],['license',{id:'other'}],['changeNotice','Other notice']]){const r=structuredClone(registry);r.entries[0].source[field]=value;await assert.rejects(validateImportDraftRegistry(r,options));}
});
test('rewritten file hash cannot certify stale recipe anchors',async()=>{
 const {registry,options,draft}=fixture();draft.recipeSha256='b'.repeat(64);const bytes=Buffer.from(JSON.stringify(draft));registry.entries[0].sha256=hash(bytes);
 await assert.rejects(validateImportDraftRegistry(registry,{...options,readDraft:async()=>bytes}),/stale/i);
});
test('approval fields/status cannot be smuggled; empty registry is valid and not bank completion',async()=>{
 const {registry,options}=fixture();
 await assert.rejects(validateImportDraftRegistry({...registry,approved:true},options));
 await assert.rejects(validateImportDraftRegistry({...registry,status:'approved'},options));
 const empty=await validateImportDraftRegistry({...registry,entries:[]},options);assert.equal(empty.draftCount,0);assert.equal(empty.runtimeReadyCount,0);
});
test('current food snapshots/evidence load once; stale references remain unresolved and absent evidence fails',async()=>{
 const {registry,options,draft}=fixture(),food={id:'fixture:1',version:'v1',nutrition:null};
 Object.assign(draft,{note:'Explicit synthetic review',reviewedAt:'2026-10-13T23:00:00Z',servings:2,prepMinutes:0,cookMinutes:0,stepMinutes:[0]});
 Object.assign(draft.lines[0],{note:'Measured synthetic fixture',resolution:'single',disposition:'required',components:[{name:'Flour',amount:100,unit:'g',form:'raw',optional:false,scales:true,food:{foodId:food.id,foodVersion:food.version,foodSnapshotSha256:snapshotFingerprint(food)}}]});
 const bytes=Buffer.from(JSON.stringify(draft));registry.entries[0].sha256=hash(bytes);let calls=0;
 const loadFoods=async ids=>{calls++;assert.deepEqual(ids,[food.id]);return {snapshots:new Map([[food.id,food]]),evidence:new Map([[food.id,{sourceId:'synthetic'}]])};};
 const opts={...options,readDraft:async()=>bytes,loadFoods};
 const result=await validateImportDraftRegistry(registry,opts);assert.equal(calls,1);assert.equal(result.completeDraftCount,1);assert.equal(result.runtimeReadyCount,0);assert.equal(result.foodEvidenceCount,1);
 const stale=await validateImportDraftRegistry(registry,{...opts,loadFoods:async()=>({snapshots:new Map([[food.id,{...food,version:'v2'}]]),evidence:new Map([[food.id,{}]])})});
 assert.equal(stale.completeDraftCount,0);assert.ok(stale.drafts[0].issues.some(i=>i.code==='food-reference'));
 await assert.rejects(validateImportDraftRegistry(registry,{...opts,loadFoods:async()=>({snapshots:new Map([[food.id,food]]),evidence:new Map()})}),/evidence/i);
});
