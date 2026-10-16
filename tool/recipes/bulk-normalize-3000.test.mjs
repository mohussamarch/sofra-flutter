import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {loadInputs,buildThirdBatch,folder,packFile,baselineManifestSha256,selectedManifestBaseline} from './bulk-normalize-3000.mjs';
import {sha,contentSignature,validateBaseline} from './bulk-normalize-1000.mjs';
import {snapshotFingerprint,reviewTarget} from './review-target.mjs';
const root=new URL('../../',import.meta.url),input=await loadInputs(),built=buildThirdBatch(input);

test('exact third1000 and all1003 files reproduce with source anchors, untranslated text and unknown metadata',async()=>{
 assert.equal(built.pack.recipes.length,1000);assert.equal(built.files.size,1003);
 assert.equal(built.report.eligibleCandidates,1575);assert.equal(built.report.sourceSnapshotCount,1000);
 assert.deepEqual(built.report.cuisineCounts,{});assert.equal(built.report.untaggedRecords,1000);
 assert.equal(built.report.counts.newAcquisitions,0);assert.equal(built.report.counts.ingredientLines,8250);assert.equal(built.report.counts.steps,6113);
 for(const [file,bytes]of built.files)assert.equal(await readFile(new URL(file,root),'utf8'),bytes);
 const seenPaths=new Set();
 for(const row of built.pack.recipes){
  const p=row.provenance,path=p.sourceSnapshotFile;seenPaths.add(path);
  const bytes=built.files.get(path),s=JSON.parse(bytes);assert.equal(sha(bytes),p.sourceSnapshotSha256);
  assert.deepEqual(s.sourceRecord,input.sources.get(p.recordId));assert.equal(sha(s.sourceRecord.sourceWikitext),p.sourceSha256);
  for(const k of ['recordId','sourceId','sourceRevision','sourceRevisionTimestamp','sourceUrl','sourceSha256','license'])assert.deepEqual(p[k],s.sourceRecord[k]);
  assert.equal(snapshotFingerprint(s.parsedRecipe),p.derivedRecipeSha256);assert.equal(snapshotFingerprint(p.license),p.licenseSha256);
  assert.equal(row.nameAr,null);assert.ok((row.nameAr??row.name).trim());assert.equal(row.sourceLanguage,'en');assert.equal(row.translationStatus,'not-translated');
  assert.equal(row.runtimeReady,false);assert.equal(row.nutrition,null);assert.equal(row.yield.amount,null);assert.equal(row.time.declaredTotalMinutes,null);assert.deepEqual(row.cuisines,[]);
  assert.ok(row.ingredients.length&&row.steps.length);
  for(const [n,i]of row.ingredients.entries()){
   for(const k of ['nameAr','amount','unit','optional','included','foodBinding','scales'])assert.equal(i[k],null);
   assert.equal(i.nameAr??i.name,i.sourceText);assert.deepEqual(i.target,reviewTarget(s.parsedRecipe,n));
   assert.deepEqual(i.quantityCandidate,s.parsedRecipe.recipe.ingredients[n].quantityCandidate);
  }
  for(const s of row.steps){assert.equal(s.textAr,null);assert.ok((s.textAr??s.text).trim());assert.equal(s.durationMinutes,null);}
 }
 assert.equal(seenPaths.size,1000);assert.equal(sha(built.files.get(packFile)),built.report.packSha256);
});

test('all2090 prior records including firsttwo1000 stay excluded and both previous pack hashes remain unchanged',async()=>{
 assert.equal(input.previous.length,2090);assert.equal(built.report.duplicateReview.excluded.previousSource,2064);
 const ids=new Set(built.pack.recipes.map(r=>r.id)),signatures=new Set(built.pack.recipes.map(r=>r.normalizedSourceContentSha256));
 assert.equal(ids.size,1000);assert.equal(signatures.size,1000);
 for(const p of input.previous){
  assert.ok(!ids.has(p.id??p.recipeId));const page=/^curated-local:(\d+)$/.exec(p.id??'');
  if(page){const r=input.recipes.get(`wikibooks:${page[1]}`);assert.ok(!signatures.has(contentSignature(r.recipe.ingredients.map(i=>i.sourceText),r.recipe.steps.map(s=>s.text))));}
 }
 for(const [part,expected]of [[1000,'26d6ca3ebf32b88f46e3573fdaadf8d5f959e4b230203a9e4b90be783981be02'],[2000,'1d65a70f09930fd5b6e375069a6869080d424d3868f43dc55c9e1ea0c82905c7']]){
  const bytes=await readFile(new URL(`data/recipes/curated-local/bulk-${part}-20261015/normalized-recipes.json`,root));assert.equal(sha(bytes),expected);
  for(const r of JSON.parse(bytes).recipes)assert.ok(!signatures.has(r.normalizedSourceContentSha256));
 }
});

test('frozen20pack baseline is stable after own/future registration; drift or undersized archive fails explicitly',()=>{
 const baseline=JSON.parse(input.baselineManifestRaw);assert.equal(baseline.packs.length,20);assert.equal(sha(input.baselineManifestRaw),baselineManifestSha256);
 const own={...baseline,packs:[...baseline.packs,{kind:'curated-local',file:packFile,sha256:built.report.packSha256,sourceSnapshots:[]}]};
 assert.deepEqual(selectedManifestBaseline(own),baseline);
 const later={...own,packs:[...own.packs,{kind:'curated-local',file:'data/recipes/curated-local/future/recipes.json',sha256:'future-pin',sourceSnapshots:[]}]};
 const stable=validateBaseline(later,baseline),stableBytes=JSON.stringify(stable,null,2)+'\n';
 assert.equal(sha(stableBytes),baselineManifestSha256);assert.equal(buildThirdBatch({...input,baselineManifestRaw:stableBytes}).report.packSha256,built.report.packSha256);
 const drift=structuredClone(later);drift.packs[0].sha256='changed';assert.throws(()=>validateBaseline(drift,baseline),/Baseline manifest pin missing or changed/);
 const id=built.pack.recipes[0].provenance.recordId,sources=new Map(input.sources),changed=structuredClone(sources.get(id));changed.sourceWikitext+=' changed';sources.set(id,changed);
 assert.throws(()=>buildThirdBatch({...input,sources}),/Source integrity mismatch/);
 const selectedIds=new Set(built.pack.recipes.slice(0,10).map(r=>`wikibooks:${r.id.split(':')[1]}`));
 const recipes=new Map([...input.recipes].filter(([id])=>selectedIds.has(id)));
 assert.throws(()=>buildThirdBatch({...input,recipes}),/Only 10 eligible records.*goal not lowered/);
});
