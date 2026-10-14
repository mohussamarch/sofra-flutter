import test from 'node:test';
import assert from 'node:assert/strict';
import {buildRuntimeRecipeCandidate,validateRuntimeRecipeCandidate,packRuntimeRecipeCandidate} from './runtime-adapter.mjs';
import {createHash} from 'node:crypto';
import {fixture} from './runtime-adapter.fixture.mjs';
import {snapshotFingerprint} from './review-target.mjs';
test('builds explicit catalog shape with split/order/exclusions and source/raw-reference mapping',()=>{
 const f=fixture(),before=structuredClone(f),result=buildRuntimeRecipeCandidate(f.source,f.draft,f.metadata,{foods:f.foods});
 assert.equal(result.recipe.id,'import:fixture');assert.deepEqual(result.recipe.ingredients.map(c=>c.id),['flour','water']);
 assert.deepEqual(result.recipe.ingredients.map(c=>c.amount),[100,200]);assert.equal(result.recipe.totalTime,15);
 assert.deepEqual(result.recipe.steps.map(s=>s.duration),[2,10]);assert.equal(result.recipe.steps[1].passive,true);
 assert.equal(result.provenance.lines[1].disposition,'excluded-optional');assert.deepEqual(result.provenance.lines[1].runtimeLineIndices,[]);
 assert.deepEqual(result.provenance.lines[0].runtimeLineIndices,[0,1]);assert.equal(result.provenance.lines[0].components[0].form,'raw dry');
 assert.deepEqual(result.provenance.source.license,f.source.license);assert.equal(result.provenance.source.recordId,f.source.recordId);
 assert.equal(result.runtimeReady,false);assert.equal(result.nutrition.status,'unreviewed');assert.deepEqual(result.nutrition.runtimeBindings,[]);
 assert.deepEqual(f,before);
});
test('unknown servings, timing, choices, quantity or current raw food reference prevents adaptation',()=>{
 for(const edit of [f=>f.draft.servings=null,f=>f.draft.stepMinutes[0]=null,f=>f.draft.lines[0].resolution=null,f=>f.draft.lines[0].components[0].amount=null,f=>f.foods.clear()]){
  const f=fixture();edit(f);f.metadata.draftSha256=snapshotFingerprint(f.draft);assert.throws(()=>buildRuntimeRecipeCandidate(f.source,f.draft,f.metadata,{foods:f.foods}),/incomplete/i);
 }
});
test('source/draft changes invalidate exact review; catalog metadata/instructions never default',()=>{
 const f=fixture();f.source.recipe.steps[0].text='Drain';assert.throws(()=>buildRuntimeRecipeCandidate(f.source,f.draft,f.metadata,{foods:f.foods}),/stale/i);
 const changed=fixture();changed.draft.note='New review';assert.throws(()=>buildRuntimeRecipeCandidate(changed.source,changed.draft,changed.metadata,{foods:changed.foods}),/draft/i);
 for(const field of ['name','cuisine','category','description','difficulty','reviewNote']){const c=fixture();c.metadata[field]='';assert.throws(()=>buildRuntimeRecipeCandidate(c.source,c.draft,c.metadata,{foods:c.foods}));}
});
test('explicit namespaced identity, ingredient labels, source acknowledgement and exact step coverage required',()=>{
 for(const edit of [m=>m.id='existing-recipe',m=>m.ingredientIds=[['flour'],[]],m=>m.ingredientIds=[['flour','water'],['oil']],m=>m.steps.pop(),m=>m.steps[0].passive=null,m=>m.acknowledgeSourceAndInstructions=false,m=>m.acknowledgeRemainingNutritionGates=false,m=>m.reviewedAt='2026-02-30T00:00:00Z']){
  const f=fixture();edit(f.metadata);assert.throws(()=>buildRuntimeRecipeCandidate(f.source,f.draft,f.metadata,{foods:f.foods}));
 }
});
test('sparse steps/ingredient IDs, overflow and approval smuggling fail closed',()=>{
 for(const edit of [f=>f.metadata.steps=new Array(2),f=>f.metadata.ingredientIds[0]=new Array(2),f=>{f.draft.prepMinutes=Number.MAX_VALUE;f.draft.cookMinutes=Number.MAX_VALUE;f.metadata.draftSha256=snapshotFingerprint(f.draft);},f=>f.metadata.nutrition={},f=>f.metadata.steps[0].duration=5]){
  const f=fixture();edit(f);assert.throws(()=>buildRuntimeRecipeCandidate(f.source,f.draft,f.metadata,{foods:f.foods}));
 }
});
test('candidate owns JSON copies and flags unresolved licence/form/retention; never drops attribution',()=>{
 const f=fixture(),candidate=buildRuntimeRecipeCandidate(f.source,f.draft,f.metadata,{foods:f.foods});
 candidate.provenance.source.license.id='changed';candidate.recipe.ingredients[0].amount=9;
 assert.equal(f.source.license.id,'fixture-license');assert.equal(f.draft.lines[0].components[0].amount,100);
 assert.ok(candidate.remainingGates.includes('per-page-license-exception-review'));assert.ok(candidate.remainingGates.includes('runtime-persistence-and-provenance-validation'));
 for(const key of ['sourceUrl','license','changeNotice']){const c=fixture();delete c.source[key];c.draft.recipeSha256=snapshotFingerprint(c.source);assert.throws(()=>buildRuntimeRecipeCandidate(c.source,c.draft,c.metadata,{foods:c.foods}));}
});
test('stored candidate must reproduce full recipe/provenance/gates from exact authoritative inputs',()=>{
 const f=fixture(),candidate=buildRuntimeRecipeCandidate(f.source,f.draft,f.metadata,{foods:f.foods});
 const result=validateRuntimeRecipeCandidate(candidate,f.source,f.draft,f.metadata,{foods:f.foods});
 assert.equal(result.recipeId,'import:fixture');assert.equal(result.runtimeReady,false);assert.equal(result.candidateSha256,snapshotFingerprint(candidate));
 for(const edit of [c=>c.recipe.ingredients[0].amount=99,c=>delete c.provenance.source.license,c=>c.provenance.lines[0].runtimeLineIndices.reverse(),c=>c.runtimeReady=true,c=>c.nutrition.runtimeBindings.push({}),c=>c.remainingGates.pop(),c=>c.approved=true]){
  const changed=structuredClone(candidate);edit(changed);assert.throws(()=>validateRuntimeRecipeCandidate(changed,f.source,f.draft,f.metadata,{foods:f.foods}),/candidate/i);
 }
});
test('candidate validator uses current source/draft/metadata/food snapshots, never its self-reported hash alone',()=>{
 for(const edit of [f=>f.source.sourceRevision='13',f=>f.draft.stepMinutes[0]=3,f=>f.metadata.name='Changed',f=>f.foods.clear()]){
  const f=fixture(),candidate=buildRuntimeRecipeCandidate(f.source,f.draft,f.metadata,{foods:f.foods});edit(f);
  assert.throws(()=>validateRuntimeRecipeCandidate(candidate,f.source,f.draft,f.metadata,{foods:f.foods}));
 }
});
test('transport packs exact UTF8 JSON bytes only after current source validation',()=>{
 const f=fixture(),candidate=buildRuntimeRecipeCandidate(f.source,f.draft,f.metadata,{foods:f.foods});
 const transport=packRuntimeRecipeCandidate(candidate,f.source,f.draft,f.metadata,{foods:f.foods});
 assert.equal(transport.encoding,'utf8-json');assert.equal(transport.sha256,createHash('sha256').update(transport.payload,'utf8').digest('hex'));assert.deepEqual(JSON.parse(transport.payload),candidate);
 const changed=structuredClone(candidate);changed.provenance.source.license.id='other';assert.throws(()=>packRuntimeRecipeCandidate(changed,f.source,f.draft,f.metadata,{foods:f.foods}));
 f.source.sourceRevision='13';assert.throws(()=>packRuntimeRecipeCandidate(candidate,f.source,f.draft,f.metadata,{foods:f.foods}));
});
test('catalog text is already normalized so native parsing cannot change reviewed identities',()=>{
 for(const edit of [f=>f.metadata.ingredientIds[0][0]=' flour ',f=>f.metadata.name=' Recipe ',f=>f.metadata.steps[0].text=' Mix ',f=>{f.draft.lines[0].components[0].name=' Flour ';f.metadata.draftSha256=snapshotFingerprint(f.draft);}]){
  const f=fixture();edit(f);assert.throws(()=>buildRuntimeRecipeCandidate(f.source,f.draft,f.metadata,{foods:f.foods}),/normalized/i);
 }
});
