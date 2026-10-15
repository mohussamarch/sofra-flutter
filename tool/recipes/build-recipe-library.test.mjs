import test from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {buildManifest,safePath,run,outputMatches,pinsFile,manifestFile} from './build-recipe-library.mjs';
test('Git CRLF conversion is allowed only for generated Dart, never pinned JSON',()=>{
 assert.equal(outputMatches(pinsFile,'line\r\n','line\n'),true);
 assert.equal(outputMatches(manifestFile,'{}\r\n','{}\n'),false);
});
test('actual selected recipe assets and generated pins are current',async()=>{
 const result=await run({check:true});assert.equal(result.packs,12);assert.equal(result.snapshots,44);
});
test('source snapshot corruption refuses to generate a trusted manifest',async()=>{
 const source=Buffer.from('{}\n'),hash=createHash('sha256').update(source).digest('hex');
 const pack={recipes:[{id:'a',provenance:{sourceSnapshotFile:'data/recipes/curated-local/snapshot.json',sourceSnapshotSha256:hash}}]};
 await assert.rejects(buildManifest(async file=>file.endsWith('normalized-recipes.json')?Buffer.from(JSON.stringify(pack)):Buffer.from('bad')),/snapshot drift/);
});
test('paths cannot escape selected source folders',()=>{
 for(const path of ['../x.json','data/recipes/curated-local/../x.json','data/recipes/arabic-youtube/x.json?x','C:/x.json','data/food/x.json'])assert.throws(()=>safePath(path));
 assert.equal(safePath('data/recipes/curated-local/a/123.json'),'data/recipes/curated-local/a/123.json');
});

function syntheticRead({duplicate=false,blankId,invalidUtf8=false,snapshot}={}){
 const source=snapshot??Buffer.from('{}\n'),hash=createHash('sha256').update(source).digest('hex');
 let n=0;
 return async file=>{
  if(file.endsWith('/snapshot.json'))return source;
  const position=n++,local=file.endsWith('/normalized-recipes.json');
  const id=position===0&&blankId!==undefined?blankId:duplicate&&position<2?'same-id':'row-'+position;
  const row=local?{id,provenance:{sourceSnapshotFile:'data/recipes/curated-local/snapshot.json',sourceSnapshotSha256:hash}}:{recipeId:id,sourceKind:'creator-website',youtubeDerived:false};
  if(file.includes('/seventh-batch-20261015/'))Object.assign(row,{sourceKind:'creator-youtube',youtubeDerived:true,sourceVideoId:'Abc_123-xyz',sourceUrl:'https://www.youtube.com/watch?v=Abc_123-xyz'});
  row.note='VALID';
  const text=JSON.stringify({recipes:[row]});
  if(invalidUtf8&&position===0){
   const at=text.indexOf('VALID');
   return Buffer.concat([Buffer.from(text.slice(0,at)),Buffer.from([255]),Buffer.from(text.slice(at+5))]);
  }
  return Buffer.from(text);
 };
}
test('duplicate identities across selected packs reject before generating trusted pins',async()=>{
 await assert.rejects(buildManifest(syntheticRead({duplicate:true})),/Duplicate recipe identity/);
});
test('empty and whitespace-only recipe identities cannot be pinned',async()=>{
 for(const blankId of ['', '   '])await assert.rejects(buildManifest(syntheticRead({blankId})),/recipe identity/);
});
test('malformed UTF8 cannot be silently replaced and pinned as readable JSON',async()=>{
 await assert.rejects(buildManifest(syntheticRead({invalidUtf8:true})),/encoded|UTF-8|encoding/i);
});

test('matching hash does not make malformed UTF8 source snapshots readable',async()=>{
 await assert.rejects(buildManifest(syntheticRead({snapshot:Buffer.from([255])})),/encoded|encoding/i);
});
test('matching hash does not permit invalid source snapshot JSON',async()=>{
 await assert.rejects(buildManifest(syntheticRead({snapshot:Buffer.from('{')})),SyntaxError);
});
test('source snapshots must be JSON objects rather than array/scalar/null',async()=>{
 for(const text of ['[]','null','3','"text"'])await assert.rejects(buildManifest(syntheticRead({snapshot:Buffer.from(text)})),/JSON object/);
});
