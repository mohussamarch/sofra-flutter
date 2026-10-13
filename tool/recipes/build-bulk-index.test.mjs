import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { buildBulkIndex } from './build-bulk-index.mjs';
import { parseRecipePage } from './collect-wikibooks.mjs';

function row({page=1,revision=11,title='Cookbook:Example',categories=[],raw='== Ingredients ==\n* Lentils\n== Procedure ==\n# Cook.',isRecipe=true}={}) {
  return {recordId:`wikibooks-${page}-r${revision}`,sourceId:'wikibooks-cookbook-cc-by-sa',
    sourcePageId:page,sourceRevision:String(revision),sourceTitle:title,
    sourceUrl:`https://en.wikibooks.org/w/index.php?title=${encodeURIComponent(title)}&oldid=${revision}`,
    sourceSha256:createHash('sha256').update(raw).digest('hex'),sourceWikitext:raw,
    sourceCategories:categories,retrievedAt:'2026-10-13T12:20:00Z',isRecipe,
    recipe:{name:title.replace('Cookbook:',''),nameAr:null,servings:null,
      ingredients:isRecipe?[{sourceText:'Lentils',amount:null,unit:null,foodBinding:null}]:[],
      steps:isRecipe?[{n:1,text:'Cook.',durationMinutes:null}]:[],nutrition:null},
    license:{id:'wikibooks-cookbook-cc-by-sa-4.0',pageExceptionStatus:'not-reviewed-per-page'}};
}

test('indexes actual source cuisine categories, keeps unknowns and never infers from title', () => {
  const a=row({categories:['Category:Egyptian recipes','Category:Easy recipes']});
  const b=row({page:2,title:'Cookbook:Saudi-style name with no category'});
  const result=buildBulkIndex([a,b]);
  assert.equal(result.distinctSourcePages,2);
  assert.equal(result.parseableRecipePages,2);
  assert.deepEqual(result.entries[0].cuisineTags,['egyptian']);
  assert.deepEqual(result.entries[1].cuisineTags,[]);
  assert.equal(result.cuisines[0].pageCount,1);
  assert.equal(result.runtimeReadyCount,0);
  assert.equal(a.recipe.ingredients[0].amount,null);
});

test('uses latest source revision per page and counts duplicate revisions only once', () => {
  const a=row();
  const latest=row({revision:12,isRecipe:false,raw:'Overview only'});
  const result=buildBulkIndex([a,a,latest]);
  assert.equal(result.distinctSourcePages,1);
  assert.equal(result.sourceRevisionRecords,2);
  assert.equal(result.parseableRecipePages,0);
  assert.equal(result.entries[0].sourceRevision,'12');
});

test('rejects corrupt source hashes and false source/revision permalinks', () => {
  for(const mutate of [r=>r.sourceSha256='a'.repeat(64),r=>r.sourceUrl='https://example.org/source',
    r=>r.sourceRevision='99',r=>r.sourceTitle='Main namespace',r=>r.recipe.nutrition={protein:5}]) {
    const r=row();mutate(r);assert.throws(()=>buildBulkIndex([r]));
  }
});

test('literal source categories have separate evidence and are not extracted from comments', () => {
  const r=row({raw:'[[Category:Nigerian recipes]]\n<!-- [[Category:Saudi recipes]] -->\n==Ingredients==\n* Rice\n==Procedure==\n# Cook.'});
  const result=buildBulkIndex([r]);
  assert.deepEqual(result.entries[0].cuisineTags,['nigerian']);
  assert.deepEqual(result.entries[0].categoryEvidence.literalWikitext,['Category:Nigerian recipes']);
});

test('source category observations extend membership without changing source text hash', () => {
  const r=row();
  const result=buildBulkIndex([r],{categoryObservations:[{recordId:r.recordId,categories:['Category:Japanese recipes']}]});
  assert.deepEqual(result.entries[0].cuisineTags,['japanese']);
  assert.equal(result.entries[0].sourceSha256,r.sourceSha256);
});

test('reparses immutable source into separately versioned unknown-preserving recipe rows', () => {
  const r=row({isRecipe:false,raw:'Nested source sections'});
  const before=structuredClone(r);
  const result=buildBulkIndex([r],{parseSource:()=>({ingredients:['1 cup flour'],steps:['Mix.'],servingsText:'4'})});
  assert.equal(result.parseableRecipePages,1);
  assert.deepEqual(r,before);
  assert.equal(result.parsedRecipes[0].parserVersion,'wikibooks-sections-v3');
  assert.equal(result.parsedRecipes[0].recipe.ingredients[0].amount,null);
  assert.equal(result.parsedRecipes[0].recipe.servings,null);
  assert.equal(result.parsedRecipes[0].sourceSha256,r.sourceSha256);
});

test('quantity candidates remain separate from canonical calculation inputs', () => {
  const r=row();
  const result=buildBulkIndex([r],{parseSource:()=>({ingredients:['1 cup flour','salt to taste'],steps:['Mix.']})});
  const [flour,salt]=result.parsedRecipes[0].recipe.ingredients;
  assert.equal(flour.quantityCandidate.amount,1);
  assert.equal(flour.quantityCandidate.unit,'cup');
  assert.equal(flour.amount,null);
  assert.equal(flour.unit,null);
  assert.equal(flour.foodBinding,null);
  assert.equal(salt.quantityCandidate.status,'unresolved');
  assert.equal(result.quantityCandidates.parsed,1);
  assert.equal(result.quantityCandidates.unresolved,1);
  assert.equal(result.parsedRecipes[0].sourceSha256,r.sourceSha256);
});

test('retains source groups and review cues without splitting choices or marking absent cues false', () => {
  const r=row({raw:'== Ingredients ==\n=== Filling ===\n* 1 cup milk or cream (optional)\n* salt to taste\n* 1 tbsp oil\n== Procedure ==\n# Mix.'});
  const result=buildBulkIndex([r],{parseSource:parseRecipePage});
  const [choice,salt,oil]=result.parsedRecipes[0].recipe.ingredients;
  assert.equal(choice.sourceStructure.sourceGroupPath[0].title,'Filling');
  assert.equal(choice.sourceStructure.optionalityCue.text,'optional');
  assert.equal(choice.sourceStructure.alternativeCue.text,'or');
  assert.equal(choice.sourceStructure.alternatives,null);
  assert.equal(choice.amount,null);
  assert.equal(choice.foodBinding,null);
  assert.equal(salt.sourceStructure.quantityQualifier.text,'to taste');
  assert.equal(salt.sourceStructure.optionalityCue,null);
  assert.equal(oil.sourceStructure.optionalityCue,null);
  assert.equal(result.sourceStructure.rowsWithGroup,3);
  assert.equal(result.sourceStructure.rowsWithAlternativeCue,1);
});

test('or more is a review cue, never inferred substitute identities or a selected amount', () => {
  const r=row();
  const result=buildBulkIndex([r],{parseSource:()=>({ingredients:['1 cup water or more'],steps:['Mix.']})});
  const line=result.parsedRecipes[0].recipe.ingredients[0];
  assert.equal(line.sourceStructure.alternativeCue.text,'or');
  assert.equal(line.sourceStructure.alternatives,null);
  assert.equal(line.sourceStructure.reviewStatus,'source-cues-unreviewed');
  assert.equal(line.sourceStructure.sourceGroupPath,null);
  assert.equal(line.amount,null);
});

test('rejects mismatched group extraction instead of attaching evidence to wrong source lines', () => {
  const r=row();
  assert.throws(()=>buildBulkIndex([r],{parseSource:()=>({ingredients:['flour'],steps:['Mix.'],ingredientRows:[{lineIndex:0,sourceText:'milk',sourceGroupPath:[]}]})}),/Ingredient structure/);
});
