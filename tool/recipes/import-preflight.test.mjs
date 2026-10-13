import test from 'node:test';
import assert from 'node:assert/strict';
import {auditRecipeImportDraft, emptyImportDraft} from './import-preflight.mjs';
import {reviewTarget, snapshotFingerprint} from './review-target.mjs';

function fixture() {
  const recipe = {id:'wikibooks:1',recordId:'r12',sourceId:'fixture',sourceRevision:'12',sourceSha256:'a'.repeat(64),parserVersion:'v3',quantityParserVersion:'v2',recipe:{servings:null,ingredients:[{id:'line1',sourceText:'1 cup flour',amount:null},{id:'line2',sourceText:'butter or oil (optional)',amount:null}],steps:[{n:1,text:'Mix',durationMinutes:null},{n:2,text:'Bake',durationMinutes:null}],nutrition:null}};
  const food = {id:'fixture:1',version:'v1',name:'Synthetic only',nutrition:null};
  const foods = new Map([[food.id,food]]);
  const component = {name:'Flour',amount:100,unit:'g',form:'raw dry flour',optional:false,scales:true,food:{foodId:food.id,foodVersion:food.version,foodSnapshotSha256:snapshotFingerprint(food)}};
  const draft = {schemaVersion:1,recipeSha256:snapshotFingerprint(recipe),note:'Synthetic explicit review',reviewedAt:'2026-10-13T23:00:00Z',servings:2,prepMinutes:5,cookMinutes:10,stepMinutes:[2,10],lines:[{target:reviewTarget(recipe,0),resolution:'single',disposition:'required',note:'Explicit measured amount',components:[component]},{target:reviewTarget(recipe,1),resolution:'choice',disposition:'excluded-optional',note:'Omit optional alternative',components:[]}]};
  return {recipe,food,foods,draft,component};
}

test('empty draft preserves unknowns and independently reports all review gates',()=>{
  const {recipe}=fixture(),before=structuredClone(recipe),draft=emptyImportDraft(recipe);
  const report=auditRecipeImportDraft(recipe,draft);
  assert.equal(report.draftComplete,false);assert.equal(report.runtimeReady,false);
  assert.equal(draft.servings,null);assert.deepEqual(draft.stepMinutes,[null,null]);
  for(const code of ['review-evidence','servings','prep-time','cook-time','step-time','resolution','disposition','components'])assert.ok(report.issues.some(i=>i.code===code),code);
  assert.equal(report.lines.length,2);assert.deepEqual(recipe,before);
});
test('complete explicit draft is an audit only, never an import or nutrient approval',()=>{
  const {recipe,draft,foods}=fixture(),before=structuredClone(draft);
  const report=auditRecipeImportDraft(recipe,draft,{foods});
  assert.equal(report.draftComplete,true);assert.deepEqual(report.issues,[]);assert.equal(report.runtimeReady,false);
  assert.ok(report.remainingRuntimeGates.includes('retention-and-nutrition-review'));
  assert.deepEqual(draft,before);assert.equal(recipe.recipe.nutrition,null);
});
test('whole recipe, line and parser drift cannot refresh a stale review',()=>{
  const {recipe,draft,foods}=fixture();
  for(const edit of [r=>r.sourceRevision='13',r=>r.quantityParserVersion='v3',r=>r.recipe.steps[0].text='Drain',r=>r.recipe.ingredients[0].sourceText='2 cups flour']){
    const changed=structuredClone(recipe);edit(changed);
    assert.throws(()=>auditRecipeImportDraft(changed,draft,{foods}),/stale/i);
    const partiallyRefreshed={...draft,recipeSha256:snapshotFingerprint(changed)};
    assert.throws(()=>auditRecipeImportDraft(changed,partiallyRefreshed,{foods}),/stale/i);
  }
});
test('every line must occur exactly once in source order with no hidden fields',()=>{
  const {recipe,draft,foods}=fixture();
  for(const lines of [draft.lines.slice(1),[draft.lines[0],draft.lines[0]],[...draft.lines].reverse()])assert.throws(()=>auditRecipeImportDraft(recipe,{...draft,lines},{foods}));
  assert.throws(()=>auditRecipeImportDraft(recipe,{...draft,approved:true},{foods}));
  const changed=structuredClone(draft);changed.lines[0].components[0].nutrition={};assert.throws(()=>auditRecipeImportDraft(recipe,changed,{foods}));
});
test('missing and stale food references stay unresolved; repeated food across lines is allowed',()=>{
  const {recipe,draft,foods,food,component}=fixture();
  assert.ok(auditRecipeImportDraft(recipe,draft).issues.some(i=>i.code==='food-reference'));
  assert.ok(auditRecipeImportDraft(recipe,draft,{foods:new Map([[food.id,{...food,version:'v2'}]])}).issues.some(i=>i.code==='food-reference'));
  const changed=structuredClone(draft);changed.lines[1]={...changed.lines[1],resolution:'single',disposition:'required',components:[structuredClone(component)]};
  assert.equal(auditRecipeImportDraft(recipe,changed,{foods}).draftComplete,true);
});
test('amount, form, optional and scaling decisions are explicit and cannot default',()=>{
  const {recipe,draft,foods}=fixture();
  for(const [field,value,code] of [['amount',null,'quantity'],['amount',0,'quantity'],['amount',-1,'quantity'],['amount',Infinity,'quantity'],['unit',null,'unit'],['form',null,'form'],['optional',null,'optional'],['scales',null,'scaling'],['optional',true,'optional']]){
    const changed=structuredClone(draft);changed.lines[0].components[0][field]=value;
    assert.ok(auditRecipeImportDraft(recipe,changed,{foods}).issues.some(i=>i.code===code),field);
  }
});
test('single/choice/split and optional exclusions have strict cardinality',()=>{
  const {recipe,draft,foods,component}=fixture();
  for(const [resolution,components] of [['choice',[component,component]],['single',[]],['split',[component]]]){
    const changed=structuredClone(draft);Object.assign(changed.lines[0],{resolution,components});assert.ok(auditRecipeImportDraft(recipe,changed,{foods}).issues.some(i=>i.code==='components'));
  }
  const split=structuredClone(draft);split.lines[0].resolution='split';split.lines[0].components.push(structuredClone(component));assert.equal(auditRecipeImportDraft(recipe,split,{foods}).draftComplete,true);
  const invalid=structuredClone(draft);invalid.lines[1].components=[component];assert.ok(auditRecipeImportDraft(recipe,invalid,{foods}).issues.some(i=>i.code==='components'));
});
test('known zero time is permitted only when explicitly reviewed; missing time is not zero',()=>{
  const {recipe,draft,foods}=fixture();
  const known=structuredClone(draft);known.prepMinutes=0;known.cookMinutes=0;known.stepMinutes=[0,0];assert.equal(auditRecipeImportDraft(recipe,known,{foods}).draftComplete,true);
  for(const value of [null,-1,Infinity,'0']){const changed=structuredClone(draft);changed.stepMinutes[0]=value;assert.ok(auditRecipeImportDraft(recipe,changed,{foods}).issues.some(i=>i.code==='step-time'));}
  for(const value of [0,2.5,null]){const changed=structuredClone(draft);changed.servings=value;assert.ok(auditRecipeImportDraft(recipe,changed,{foods}).issues.some(i=>i.code==='servings'));}
  assert.throws(()=>auditRecipeImportDraft(recipe,{...draft,stepMinutes:[5]},{foods}));
});
test('a review requires a real calendar timestamp',()=>{
  const {recipe,draft,foods}=fixture();
  assert.ok(auditRecipeImportDraft(recipe,{...draft,reviewedAt:'2026-02-30T23:00:00Z'},{foods}).issues.some(i=>i.code==='review-evidence'));
});
test('all source components excluded does not make an importable ingredient list',()=>{
  const {recipe,draft,foods}=fixture();
  const allExcluded=structuredClone(draft);allExcluded.lines[0].disposition='excluded-optional';allExcluded.lines[0].components=[];
  assert.ok(auditRecipeImportDraft(recipe,allExcluded,{foods}).issues.some(i=>i.code==='recipe-components'));
});
test('sparse duration slots and missing source steps cannot pass as reviewed',()=>{
  const {recipe,draft,foods}=fixture();
  const changed=structuredClone(draft);changed.stepMinutes=new Array(2);
  assert.equal(auditRecipeImportDraft(recipe,changed,{foods}).issues.filter(i=>i.code==='step-time').length,2);
  const source=structuredClone(recipe);source.recipe.steps=new Array(2);
  const pinned=structuredClone(draft);pinned.recipeSha256=snapshotFingerprint(source);pinned.lines=pinned.lines.map((l,i)=>({...l,target:reviewTarget(source,i)}));
  assert.throws(()=>auditRecipeImportDraft(source,pinned,{foods}));
});
