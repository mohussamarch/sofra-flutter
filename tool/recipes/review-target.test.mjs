import test from 'node:test';
import assert from 'node:assert/strict';
import { reviewTarget, snapshotFingerprint, validateIdentityProposal } from './review-target.mjs';
const recipe=()=>({id:'wikibooks:1',recordId:'wikibooks-1-r12',sourceId:'fixture-source',sourceRevision:'12',sourceSha256:'a'.repeat(64),parserVersion:'sections-v3',quantityParserVersion:'source-prefix-v2',recipe:{ingredients:[{id:'source-line-1',sourceText:'1 cup flour',amount:null,unit:null,foodBinding:null}],nutrition:null}});
const food=()=>({id:'fixture:flour',version:'v1',description:'Synthetic test food only',nutrition:null});
function fixture(){const r=recipe(),f=food();return {r,f,p:{schemaVersion:1,status:'identity-proposal-unreviewed',target:reviewTarget(r,0),candidates:[{foodId:f.id,foodVersion:f.version,foodSnapshotSha256:snapshotFingerprint(f),rationale:'Synthetic identity review fixture only'}],issues:['Mass and preparation remain unknown']}};}
test('target is deterministic and pins full derived snapshot plus exact source line',()=>{
 const r=recipe(),before=structuredClone(r);assert.deepEqual(reviewTarget(r,0),reviewTarget(r,0));assert.deepEqual(r,before);assert.equal(reviewTarget(r,0).lineId,'source-line-1');assert.throws(()=>reviewTarget(r,2));
});
test('validates proposals without creating bindings or nutrient results',()=>{
 const {r,f,p}=fixture(),before=structuredClone(p);assert.equal(validateIdentityProposal(p,r,new Map([[f.id,f]])),true);assert.deepEqual(p,before);assert.equal(r.recipe.ingredients[0].foodBinding,null);
});
test('changed source, parser, line or even other derived metadata invalidates target',()=>{
 const {r,f,p}=fixture();for(const edit of [r=>r.sourceRevision='13',r=>r.parserVersion='v4',r=>r.recipe.ingredients[0].sourceText='2 cups flour',r=>r.recipe.servings=2]){const changed=structuredClone(r);edit(changed);assert.throws(()=>validateIdentityProposal(p,changed,new Map([[f.id,f]])),/stale/i);}
});
test('food version or snapshot change and duplicate/unknown identities fail',()=>{
 const {r,f,p}=fixture();for(const changed of [{...f,version:'v2'},{...f,description:'Changed'},undefined])assert.throws(()=>validateIdentityProposal(p,r,new Map(changed?[[f.id,changed]]:[])));
 const duplicate=structuredClone(p);duplicate.candidates.push(duplicate.candidates[0]);assert.throws(()=>validateIdentityProposal(duplicate,r,new Map([[f.id,f]])));
});
test('cannot smuggle approval, selection, quantities or nutrition through proposal',()=>{
 const {r,f,p}=fixture();for(const [key,value] of [['approved',true],['selectedFoodId',f.id],['nutrition',{}],['amount',1]]){assert.throws(()=>validateIdentityProposal({...p,[key]:value},r,new Map([[f.id,f]])));}
 assert.throws(()=>validateIdentityProposal({...p,status:'approved'},r,new Map([[f.id,f]])));
});
test('unresolved targets require recorded issues and canonical fingerprints ignore key order',()=>{
 const {r,p}=fixture();assert.equal(validateIdentityProposal({...p,candidates:[]},r,new Map()),true);assert.throws(()=>validateIdentityProposal({...p,candidates:[],issues:[]},r,new Map()));assert.equal(snapshotFingerprint({a:1,b:2}),snapshotFingerprint({b:2,a:1}));
});
