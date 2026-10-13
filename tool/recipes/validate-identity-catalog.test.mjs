import test from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {reviewTarget,snapshotFingerprint} from './review-target.mjs';
import {validateIdentityCatalog} from './validate-identity-catalog.mjs';
const hash=bytes=>createHash('sha256').update(bytes).digest('hex');
function fixture(){
 const recipes=new Map(),files=new Map(),food={id:'usda:1',version:'synthetic-v1',name:'Synthetic food only',nutrition:null},evidence={sourceId:'usda',license:'CC0-1.0',shardSha256:'b'.repeat(64)};
 const banks=[];
 for(const id of ['one','two']){
  const r={id:`fixture:${id}`,recordId:`${id}-r1`,sourceId:'synthetic',sourceRevision:'1',sourceSha256:'a'.repeat(64),sourceUrl:`https://example.org/${id}`,parserVersion:'v3',quantityParserVersion:'v2',license:{id:'synthetic-license'},recipe:{ingredients:[{id:'line-1',sourceText:'Synthetic ingredient',foodBinding:null}],nutrition:null}};recipes.set(r.id,r);
  const bank={schemaVersion:1,status:'identity-proposals-unreviewed',createdAt:'2026-10-13T17:00:00Z',recipeSources:[{recipeId:r.id,recordId:r.recordId,sourceUrl:r.sourceUrl,sourceSha256:r.sourceSha256,license:structuredClone(r.license),changeNotice:'Synthetic test annotation only'}],foodEvidence:[{foodId:food.id,foodSnapshotSha256:snapshotFingerprint(food),sourceEvidence:structuredClone(evidence)}],proposals:[{schemaVersion:1,status:'identity-proposal-unreviewed',target:reviewTarget(r,0),candidates:[{foodId:food.id,foodVersion:food.version,foodSnapshotSha256:snapshotFingerprint(food),rationale:'Synthetic test candidate only'}],issues:['Unreviewed']}],limitations:['No approvals']};
  const bytes=Buffer.from(JSON.stringify(bank));files.set(`${id}.json`,bytes);banks.push({id,file:`${id}.json`,sha256:hash(bytes)});
 }
 let foodLoads=0;
 return {catalog:{schemaVersion:1,status:'identity-catalog-unreviewed',banks,expected:{proposalCount:2,recipeCount:2,foodCount:1,candidateCount:2,unresolvedCount:0},limitations:['Research only']},files,recipes,food,evidence,
  options:{recipes,readBank:async path=>{assert.ok(files.has(path));return files.get(path);},loadFoods:async ids=>{foodLoads++;assert.deepEqual(ids,['usda:1']);return {snapshots:new Map([[food.id,food]]),evidence:new Map([[food.id,evidence]])};}},foodLoads:()=>foodLoads};
}
function replace(f,file,bank){const bytes=Buffer.from(JSON.stringify(bank));f.files.set(file,bytes);f.catalog.banks.find(b=>b.file===file).sha256=hash(bytes);}
test('catalog verifies real banks, deduplicates food/recipe counts and loads shared foods once',async()=>{
 const f=fixture(),before=structuredClone(f.catalog);const result=await validateIdentityCatalog(f.catalog,f.options);
 assert.deepEqual(result,{bankCount:2,proposalCount:2,recipeCount:2,foodCount:1,candidateCount:2,unresolvedCount:0,runtimeReadyCount:0});assert.equal(f.foodLoads(),1);assert.deepEqual(f.catalog,before);
});
test('bank bytes and expected aggregate counts are guarded',async()=>{
 const f=fixture();f.files.set('one.json',Buffer.from('{}'));await assert.rejects(validateIdentityCatalog(f.catalog,f.options),/hash/i);assert.equal(f.foodLoads(),0);
 const g=fixture();g.catalog.expected.recipeCount=999;await assert.rejects(validateIdentityCatalog(g.catalog,g.options),/count/i);
});
test('rejects unsafe or duplicate bank identities and approval fields before reads',async()=>{
 for(const edit of [c=>c.banks[0].file='../one.json',c=>{c.banks[0].id=null;c.banks[0].file='null.json';},c=>c.banks.push({...c.banks[0]}),c=>c.banks[0].id='catalog',c=>c.status='approved',c=>c.runtimeReadyCount=1]){
  const f=fixture();edit(f.catalog);f.options.readBank=async()=>{throw Error('Must reject before read');};await assert.rejects(validateIdentityCatalog(f.catalog,f.options),/catalog|identity|field|file/i);
 }
});
test('duplicate target across independently valid banks fails instead of double counting',async()=>{
 const f=fixture(),a=JSON.parse(f.files.get('one.json'));replace(f,'two.json',a);await assert.rejects(validateIdentityCatalog(f.catalog,f.options),/duplicate.*target/i);
});
test('current source and food snapshot checks are not replaced by bank hashes',async()=>{
 const f=fixture();f.recipes.get('fixture:one').recipe.ingredients[0].sourceText='Changed';await assert.rejects(validateIdentityCatalog(f.catalog,f.options));
 const g=fixture();g.food.version='changed';await assert.rejects(validateIdentityCatalog(g.catalog,g.options));
 const h=fixture(),bank=JSON.parse(h.files.get('two.json'));bank.foodEvidence[0].sourceEvidence.license='wrong';replace(h,'two.json',bank);await assert.rejects(validateIdentityCatalog(h.catalog,h.options));
});
test('unresolved banks preserve unknowns and do not load nonexistent food data',async()=>{
 const f=fixture();for(const file of f.files.keys()){const bank=JSON.parse(f.files.get(file));bank.proposals[0].candidates=[];bank.foodEvidence=[];replace(f,file,bank);}
 f.catalog.expected={proposalCount:2,recipeCount:2,foodCount:0,candidateCount:0,unresolvedCount:2};f.options.loadFoods=async()=>{throw Error('No food needed');};const r=await validateIdentityCatalog(f.catalog,f.options);assert.equal(r.unresolvedCount,2);assert.equal(r.runtimeReadyCount,0);
});
