import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {loadInputs,buildSecondBatch,folder,packFile,baselineManifestSha256,selectedManifestBaseline} from './bulk-normalize-2000.mjs';
import {buildBatch,sha,contentSignature,validateBaseline} from './bulk-normalize-1000.mjs';
import {snapshotFingerprint,reviewTarget} from './review-target.mjs';

const root=new URL('../../',import.meta.url),input=await loadInputs(),built=buildSecondBatch(input);
const firstPackFile='data/recipes/curated-local/bulk-1000-20261015/normalized-recipes.json';
const firstPackRaw=await readFile(new URL(firstPackFile,root)),firstPack=JSON.parse(firstPackRaw);
const firstPackSha256='26d6ca3ebf32b88f46e3573fdaadf8d5f959e4b230203a9e4b90be783981be02';

test('exact1000 second native records reproduce stored pack/report and preserve first pack bytes',async()=>{
 assert.equal(built.pack.recipes.length,1000);assert.equal(built.report.counts.newAcquisitions,0);
 assert.equal(built.report.duplicateReview.previousSelectedRecords,1090);
 assert.equal(built.report.duplicateReview.excluded.previousSource,1064);
 assert.equal(built.report.eligibleCandidates,2575);
 assert.equal(await readFile(new URL(packFile,root),'utf8'),built.files.get(packFile));
 assert.deepEqual(JSON.parse(await readFile(new URL(`${folder}/conversion-report.json`,root))),built.report);
 assert.equal(sha(firstPackRaw),firstPackSha256);
 assert.equal(sha(built.files.get(packFile)),built.report.packSha256);
});

test('all1000 snapshots retain exact source/revision/license and every ingredient target',async()=>{
 const paths=new Set();
 for(const row of built.pack.recipes){
  const p=row.provenance;paths.add(p.sourceSnapshotFile);
  const bytes=await readFile(new URL(p.sourceSnapshotFile,root)),s=JSON.parse(bytes);
  assert.equal(sha(bytes),p.sourceSnapshotSha256);assert.deepEqual(s.sourceRecord,input.sources.get(p.recordId));
  for(const key of ['recordId','sourceId','sourceRevision','sourceRevisionTimestamp','sourceUrl','sourceSha256','license'])assert.deepEqual(p[key],s.sourceRecord[key]);
  assert.equal(sha(s.sourceRecord.sourceWikitext),p.sourceSha256);
  assert.equal(snapshotFingerprint(s.parsedRecipe),p.derivedRecipeSha256);
  assert.equal(snapshotFingerprint(s.sourceRecord.license),p.licenseSha256);
  for(const [n,i]of row.ingredients.entries())assert.deepEqual(i.target,reviewTarget(s.parsedRecipe,n));
 }
 assert.equal(paths.size,1000);
});

test('all1090 prior records and first1000 are excluded by identity and exact source content',()=>{
 const ids=new Set(built.pack.recipes.map(r=>r.id)),records=new Set(built.pack.recipes.map(r=>r.provenance.recordId));
 const signatures=new Set(built.pack.recipes.map(r=>r.normalizedSourceContentSha256));
 assert.equal(ids.size,1000);assert.equal(records.size,1000);assert.equal(signatures.size,1000);
 assert.equal(firstPack.recipes.length,1000);
 for(const r of input.previous){
  assert.ok(!ids.has(r.id));assert.ok(!records.has(r.provenance?.recordId));
  const page=/^curated-local:(\d+)$/.exec(r.id??'');
  if(page){const parsed=input.recipes.get(`wikibooks:${page[1]}`);assert.ok(!signatures.has(contentSignature(parsed.recipe.ingredients.map(i=>i.sourceText),parsed.recipe.steps.map(s=>s.text))));}
 }
 for(const r of firstPack.recipes){assert.ok(!ids.has(r.id));assert.ok(!signatures.has(r.normalizedSourceContentSha256));}
});

test('frozen19pack baseline allows own and later registrations without selecting another batch',()=>{
 const baseline=JSON.parse(input.baselineManifestRaw);
 assert.equal(baseline.packs.length,19);assert.equal(sha(input.baselineManifestRaw),baselineManifestSha256);
 const registered={...baseline,packs:[...baseline.packs,{kind:'curated-local',file:packFile,sha256:built.report.packSha256,sourceSnapshots:[]}]};
 assert.deepEqual(selectedManifestBaseline(registered),baseline);
 const later={...registered,packs:[...registered.packs,{kind:'curated-local',file:'data/recipes/curated-local/future/recipes.json',sha256:'future-pin',sourceSnapshots:[]}]};
 const stable=validateBaseline(later,baseline);
 assert.equal(sha(JSON.stringify(stable,null,2)+'\n'),input.inputManifestSha256);
 assert.equal(buildSecondBatch({...input,baselineManifestRaw:JSON.stringify(stable,null,2)+'\n'}).report.packSha256,built.report.packSha256);
 const drift=structuredClone(later);drift.packs[0].sha256='changed';
 assert.throws(()=>validateBaseline(drift,baseline),/Baseline manifest pin missing or changed/);
});

test('source text/cuisines stay evidenced and untranslated; quantity/food/time/yield remain unknown',()=>{
 const entries=new Map(input.index.entries.map(e=>[e.id,e]));
 for(const row of built.pack.recipes){
  assert.equal(row.sourceLanguage,'en');assert.equal(row.translationStatus,'not-translated');assert.equal(row.nameAr,null);assert.ok((row.nameAr??row.name).trim());
  assert.equal(row.runtimeReady,false);assert.equal(row.nutrition,null);assert.equal(row.yield.amount,null);assert.equal(row.time.declaredTotalMinutes,null);
  assert.ok(row.ingredients.length&&row.steps.length);
  for(const i of row.ingredients){for(const key of ['amount','unit','foodBinding','optional','included','scales','nameAr'])assert.equal(i[key],null);assert.equal(i.nameAr??i.name,i.sourceText);}
  for(const s of row.steps){assert.equal(s.textAr,null);assert.ok((s.textAr??s.text).trim());}
  const entry=entries.get(`wikibooks:${row.id.split(':')[1]}`);
  for(const c of row.cuisines){assert.ok(entry.sourceCategories.includes(c.evidenceText));assert.equal(c.sourceRecordId,row.provenance.recordId);}
 }
 assert.deepEqual(built.report.cuisineCounts,{indian:42,italian:11});assert.equal(built.report.untaggedRecords,947);
});

test('second source drift, baseline byte drift and unsafe output folders fail explicitly',()=>{
 const id=built.pack.recipes[0].provenance.recordId;
 for(const edit of [r=>r.sourceWikitext+=' changed',r=>r.sourceRevision='1',r=>r.license.id='changed']){
  const sources=new Map(input.sources),row=structuredClone(sources.get(id));edit(row);sources.set(id,row);
  assert.throws(()=>buildSecondBatch({...input,sources}),/Source integrity|Source revision/);
 }
 assert.throws(()=>buildSecondBatch({...input,baselineManifestRaw:input.baselineManifestRaw+' '}),/Frozen baseline manifest drift/);
 for(const outputFolder of ['../escape','data/recipes/curated-local/../escape','data/recipes/curated-local/a/b','E:/escape'])assert.throws(()=>buildBatch(input,1000,{outputFolder}),/Unsafe batch output folder/);
});
