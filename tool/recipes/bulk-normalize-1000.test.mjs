import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {buildBatch,loadInputs,sha,packFile,contentSignature,selectedManifestBaseline,validateBaseline} from './bulk-normalize-1000.mjs';
import {reviewTarget,snapshotFingerprint} from './review-target.mjs';
const root=new URL('../../',import.meta.url);
const input=await loadInputs(),built=buildBatch(input);

test('exactly 1000 native records and stable stored pack bytes after own manifest registration',async()=>{
 assert.equal(built.pack.recipes.length,1000);assert.equal(built.report.counts.newAcquisitions,0);
 assert.equal(built.report.duplicateReview.previousSelectedRecords,90);
 assert.equal(await readFile(new URL(packFile,root),'utf8'),built.files.get(packFile));
 assert.equal(sha(built.files.get(packFile)),built.report.packSha256);
 const manifest=JSON.parse(await readFile(new URL('data/recipes/curated-local/flutter-manifest.json',root),'utf8'));
 const baseline=JSON.parse(input.baselineManifestRaw);
 const registered={...baseline,packs:[...baseline.packs,{kind:'curated-local',file:packFile,sha256:built.report.packSha256,sourceSnapshots:[]}]};
 const registeredBaseline=validateBaseline(registered,baseline);
 assert.deepEqual(registeredBaseline,baseline);assert.ok(!registeredBaseline.packs.some(p=>p.file===packFile));
 const baselineHash=sha(JSON.stringify(registeredBaseline,null,2)+'\n');
 assert.equal(baselineHash,input.inputManifestSha256);
 assert.equal(buildBatch({...input,inputManifestSha256:baselineHash}).report.packSha256,built.report.packSha256);
 const later={...registered,packs:[...registered.packs,{kind:'curated-local',file:'data/recipes/curated-local/later/recipes.json',sha256:'later-pin',sourceSnapshots:[]}]};
 assert.deepEqual(validateBaseline(later,baseline),baseline);
 assert.equal(sha(JSON.stringify(validateBaseline(later,baseline),null,2)+'\n'),input.inputManifestSha256);
 assert.deepEqual(selectedManifestBaseline(registered),baseline);
 const drift=structuredClone(later);drift.packs[0].sha256='changed';
 assert.throws(()=>validateBaseline(drift,baseline),/Baseline manifest pin missing or changed/);
});
test('1000 immutable source snapshots retain original record, parsed extraction, revision and licence',async()=>{
 const paths=new Set();
 for(const row of built.pack.recipes){
  const p=row.provenance;paths.add(p.sourceSnapshotFile);
  const bytes=await readFile(new URL(p.sourceSnapshotFile,root));assert.equal(sha(bytes),p.sourceSnapshotSha256);
  const s=JSON.parse(bytes);assert.deepEqual(s.sourceRecord,input.sources.get(p.recordId));
  for(const k of ['recordId','sourceId','sourceRevision','sourceRevisionTimestamp','sourceUrl','sourceSha256','license'])assert.deepEqual(p[k],s.sourceRecord[k]);
  assert.equal(snapshotFingerprint(s.parsedRecipe),p.derivedRecipeSha256);
  assert.equal(snapshotFingerprint(s.sourceRecord.license),p.licenseSha256);
 }
 assert.equal(paths.size,1000);
});
test('changed source text or revision fails before conversion',()=>{
 const first=built.pack.recipes[0].provenance.recordId;
 for(const edit of [r=>r.sourceWikitext+=' changed',r=>r.sourceRevision='1']){
  const sources=new Map(input.sources),changed=structuredClone(sources.get(first));edit(changed);sources.set(first,changed);
  assert.throws(()=>buildBatch({...input,sources}),/Source integrity|Source revision/);
 }
});
test('previous identities and normalized exact content are deduplicated; unmet size fails explicitly',()=>{
 const rows=built.pack.recipes,ids=new Set(rows.map(r=>r.id)),signatures=new Set(rows.map(r=>r.normalizedSourceContentSha256));
 assert.equal(ids.size,1000);assert.equal(signatures.size,1000);
 for(const p of input.previous)assert.ok(!ids.has(p.id));
 assert.equal(contentSignature(['  1 CUP Milk '],['Mix.']),contentSignature(['1 cup milk'],['mix.']));
 const r=input.recipes.get(`wikibooks:${rows[0].id.split(':')[1]}`),source=input.sources.get(r.recordId);
 const clone=structuredClone(r);clone.id='wikibooks:99999999';clone.recordId='wikibooks-99999999-r'+r.sourceRevision;clone.sourceUrl+='&copy=1';
 const originalEntry=input.index.entries.find(e=>e.id===r.id),cloneEntry={...originalEntry,id:clone.id,recordId:clone.recordId};
 const fixture={...input,previous:[],recipes:new Map([[r.id,r],[clone.id,clone]]),sources:new Map([[r.recordId,source],[clone.recordId,{...source,sourcePageId:99999999,recordId:clone.recordId,sourceUrl:clone.sourceUrl}]]),index:{...input.index,entries:[originalEntry,cloneEntry]}};
 assert.equal(buildBatch(fixture,1).pack.recipes.length,1);
 assert.throws(()=>buildBatch(fixture,2),/Only 1 eligible records.*goal not lowered/);
});
test('English source stays untranslated; unresolved food, quantity, optionality, time and yield stay unknown',()=>{
 for(const row of built.pack.recipes){
  assert.equal(row.nameAr,null);assert.equal(row.nameAr??row.name,row.name);assert.ok(row.name.trim());
  assert.equal(row.translationStatus,'not-translated');assert.equal(row.runtimeReady,false);assert.equal(row.nutrition,null);
  assert.equal(row.yield.amount,null);assert.equal(row.time.declaredTotalMinutes,null);
  assert.ok(row.ingredients.length&&row.steps.length);
  for(const i of row.ingredients){for(const k of ['nameAr','amount','unit','optional','included','foodBinding','scales'])assert.equal(i[k],null);assert.ok(i.sourceText.trim());assert.equal(i.nameAr??i.name,i.sourceText);}
  for(const s of row.steps){assert.equal(s.textAr,null);assert.ok(s.text.trim());assert.equal(s.textAr??s.text,s.text);}
 }
});
test('every source line target and cuisine category is anchored; Asian coverage is source derived',()=>{
 for(const row of built.pack.recipes){
  const r=input.recipes.get(`wikibooks:${row.id.split(':')[1]}`),e=input.index.entries.find(e=>e.id===r.id);
  for(const [n,i]of row.ingredients.entries())assert.deepEqual(i.target,reviewTarget(r,n));
  for(const c of row.cuisines){assert.ok(e.sourceCategories.includes(c.evidenceText));assert.equal(c.sourceRecordId,r.recordId);}
 }
 for(const c of ['chinese','indian','indonesian','japanese','korean','malaysian','thai','vietnamese'])assert.ok(built.report.cuisineCounts[c]>0);
});
