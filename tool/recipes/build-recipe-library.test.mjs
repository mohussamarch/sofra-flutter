import test from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {buildManifest,safePath,run,outputMatches,pinsFile,manifestFile} from './build-recipe-library.mjs';
test('Git CRLF conversion is allowed only for generated Dart, never pinned JSON',()=>{
 assert.equal(outputMatches(pinsFile,'line\r\n','line\n'),true);
 assert.equal(outputMatches(manifestFile,'{}\r\n','{}\n'),false);
});
test('actual selected recipe assets and generated pins are current',async()=>{
 const result=await run({check:true});assert.equal(result.packs,2);assert.equal(result.snapshots,16);
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
