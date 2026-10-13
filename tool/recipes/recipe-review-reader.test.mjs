import test from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pageRecord,parseRecipePage} from './collect-wikibooks.mjs';
import {buildBulkIndex} from './build-bulk-index.mjs';
import {loadRecipeReviewSnapshots} from './recipe-review-reader.mjs';
const hash=v=>createHash('sha256').update(v).digest('hex');
function fixture(){
 const record=pageRecord({pageid:1,ns:102,title:'Cookbook:Synthetic fixture',categories:[{title:'Category:Recipes'}],revisions:[{revid:11,slots:{main:{content:'== Ingredients ==\n* 1 cup synthetic flour\n== Procedure ==\n# Mix.'}}}]},'2026-10-13T16:00:00Z');
 const source=JSON.stringify(record)+'\n',observations='';
 const {parsedRecipes,...core}=buildBulkIndex([record],{parseSource:parseRecipePage});
 const parsed=parsedRecipes.map(r=>JSON.stringify(r)).join('\n')+'\n';
 const index={...core,records:'source-pages.jsonl',parsedRecipes:'parsed-recipes.jsonl',sourceFileSha256:hash(source),parsedRecipesSha256:hash(parsed),categoryObservationsSha256:null};
 const files=new Map([['source-pages.jsonl',source],['category-observations.jsonl',observations],['parsed-recipes.jsonl',parsed],['index.json',JSON.stringify(index)]]);
 return {record,index,files,read:async p=>{assert.ok(files.has(p),p);return files.get(p);}};
}
test('reproduces current recipe snapshots from hashed original source and observations',async()=>{
 const f=fixture();const result=await loadRecipeReviewSnapshots({read:f.read});assert.equal(result.recipes.size,1);assert.equal(result.evidence.sourceFileSha256,f.index.sourceFileSha256);
});
test('source/parsed/category file byte drift fails before review',async()=>{
 for(const file of ['source-pages.jsonl','parsed-recipes.jsonl','category-observations.jsonl']){const f=fixture();f.files.set(file,f.files.get(file)+' ');await assert.rejects(loadRecipeReviewSnapshots({read:f.read}),/hash/i);}
});
test('rewriting derived ingredients and its file hash still fails source re-extraction',async()=>{
 const f=fixture(),r=JSON.parse(f.files.get('parsed-recipes.jsonl'));r.recipe.ingredients[0].sourceText='Changed source';const parsed=JSON.stringify(r)+'\n';f.files.set('parsed-recipes.jsonl',parsed);f.index.parsedRecipesSha256=hash(parsed);f.files.set('index.json',JSON.stringify(f.index));await assert.rejects(loadRecipeReviewSnapshots({read:f.read}),/extraction/i);
});
test('corrupt original wikitext with updated outer file hash still fails internal source hash',async()=>{
 const f=fixture();f.record.sourceWikitext+='\nChanged';const raw=JSON.stringify(f.record)+'\n';f.files.set('source-pages.jsonl',raw);f.index.sourceFileSha256=hash(raw);f.files.set('index.json',JSON.stringify(f.index));await assert.rejects(loadRecipeReviewSnapshots({read:f.read}),/source text\/hash/i);
});
test('false index counts/entries and unsafe source paths are rejected',async()=>{
 for(const edit of [i=>i.parseableRecipePages=99,i=>i.entries[0].sourceRevision='99',i=>i.records='../outside.json']){const f=fixture();edit(f.index);f.files.set('index.json',JSON.stringify(f.index));await assert.rejects(loadRecipeReviewSnapshots({read:f.read}));}
});
