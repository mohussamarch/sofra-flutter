import test from 'node:test';
import assert from 'node:assert/strict';
import {reviewTarget} from './review-target.mjs';
import {validateIngredientFateBank} from './validate-ingredient-fate.mjs';

function fixture(){
 const recipe={id:'fixture:soaking',recordId:'fixture-r1',sourceId:'fixture-source',sourceRevision:'1',sourceSha256:'a'.repeat(64),sourceUrl:'https://example.org/revision/1',parserVersion:'v3',quantityParserVersion:'v2',license:{id:'fixture-license'},recipe:{ingredients:[{id:'line-1',sourceText:'1 tsp synthetic soaking ingredient'}],steps:[{n:1,text:'Add to soaking water.'},{n:2,text:'Drain.'}],nutrition:null}};
 const bank={schemaVersion:1,status:'ingredient-fate-research-unreviewed',createdAt:'2026-10-13T21:33:00Z',recipeSources:[{recipeId:recipe.id,recordId:recipe.recordId,sourceUrl:recipe.sourceUrl,sourceSha256:recipe.sourceSha256,license:structuredClone(recipe.license),changeNotice:'Synthetic fixture only'}],observations:[{schemaVersion:1,status:'ingredient-fate-unreviewed',target:reviewTarget(recipe,0),methodSteps:[{stepIndex:0,stepNumber:1,text:'Add to soaking water.'},{stepIndex:1,stepNumber:2,text:'Drain.'}],interpretation:'Soaking and draining require retained-amount review.',retainedIngredientFraction:null,nutrientRetention:null,requiresReview:true}],limitations:['No numerical retention or runtime approval']};
 return {bank,recipe,recipes:new Map([[recipe.id,recipe]])};
}
test('verified source anchors remain unknown, immutable and zero runtime-ready',()=>{
 const f=fixture(),before=structuredClone(f.bank);assert.deepEqual(validateIngredientFateBank(f.bank,{recipes:f.recipes}),{observationCount:1,recipeCount:1,stepReferenceCount:2,unknownRetentionCount:1,runtimeReadyCount:0});assert.deepEqual(f.bank,before);
});
test('stale ingredient, full recipe snapshot or parser cannot be silently refreshed',()=>{
 for(const edit of [r=>r.recipe.ingredients[0].sourceText='different',r=>r.recipe.steps[0].text='different',r=>r.parserVersion='new']){const f=fixture();edit(f.recipe);assert.throws(()=>validateIngredientFateBank(f.bank,{recipes:f.recipes}));}
});
test('method references require exact text, numbering and valid index',()=>{
 for(const edit of [o=>o.methodSteps[0].text='invented',o=>o.methodSteps[0].stepNumber=2,o=>o.methodSteps[0].stepIndex=99,o=>o.methodSteps[0].stepIndex=0.5,o=>o.methodSteps=[]]){const f=fixture();edit(f.bank.observations[0]);assert.throws(()=>validateIngredientFateBank(f.bank,{recipes:f.recipes}));}
});
test('zero, full or estimated retention and approval claims are rejected',()=>{
 for(const edit of [o=>o.retainedIngredientFraction=0,o=>o.retainedIngredientFraction=1,o=>o.nutrientRetention={sodium:0.5},o=>o.requiresReview=false,o=>o.status='approved',o=>o.runtimeReady=true]){const f=fixture();edit(f.bank.observations[0]);assert.throws(()=>validateIngredientFateBank(f.bank,{recipes:f.recipes}));}
});
test('source URL, licence, attribution and complete provenance must match',()=>{
 for(const edit of [b=>b.recipeSources=[],b=>b.recipeSources[0].sourceUrl='https://example.org/other',b=>b.recipeSources[0].license.id='wrong',b=>b.recipeSources[0].changeNotice='']){const f=fixture();edit(f.bank);assert.throws(()=>validateIngredientFateBank(f.bank,{recipes:f.recipes}));}
});
test('duplicate observations and duplicate or unordered method anchors fail',()=>{
 for(const edit of [b=>b.observations.push(structuredClone(b.observations[0])),b=>b.observations[0].methodSteps.push(structuredClone(b.observations[0].methodSteps[0])),b=>b.observations[0].methodSteps.reverse(),b=>b.recipeSources.push(structuredClone(b.recipeSources[0]))]){const f=fixture();edit(f.bank);assert.throws(()=>validateIngredientFateBank(f.bank,{recipes:f.recipes}));}
});
test('empty banks, extra fields and absent current source fail closed',()=>{
 for(const edit of [b=>b.observations=[],b=>b.approved=true,b=>b.limitations=[],b=>b.observations[0].interpretation='']){const f=fixture();edit(f.bank);assert.throws(()=>validateIngredientFateBank(f.bank,{recipes:f.recipes}));}
 const f=fixture();assert.throws(()=>validateIngredientFateBank(f.bank,{recipes:new Map()}));
});
