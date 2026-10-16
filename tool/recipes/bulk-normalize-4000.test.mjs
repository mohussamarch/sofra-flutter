import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {loadInputs,buildFourthBatch,packFile,baselineManifestSha256,selectedManifestBaseline,extractFrenchSectionEvidence,renderFrenchSourceLine,recoverFrenchLines} from './bulk-normalize-4000.mjs';
import {sha,contentSignature,validateBaseline} from './bulk-normalize-1000.mjs';
import {snapshotFingerprint} from './review-target.mjs';

const root=new URL('../../',import.meta.url),input=await loadInputs(),built=buildFourthBatch(input);

test('exact fourth 1000 reproduces its 1003 files and preserves French source facts and unknowns',async()=>{
 assert.equal(built.pack.recipes.length,1000);assert.equal(built.files.size,1003);
 assert.equal(built.report.eligibleCandidates,1010);assert.equal(built.report.sourceSnapshotCount,1000);
 assert.equal(built.report.counts.ingredientLines,7167);assert.equal(built.report.counts.steps,6330);
 assert.equal(built.report.counts.ingredientReferenceTemplateRecords,946);
 assert.equal(built.report.counts.parserOmittedIngredientRecords,77);
 assert.equal(built.report.counts.parserOmittedIngredientLines,125);
 assert.equal(built.report.counts.unresolvedSourceMarkupRecords,12);
 assert.equal(built.report.counts.sourceTextWithoutUnresolvedMarkupRecords,988);
 assert.equal(built.report.counts.newAcquisitions,0);assert.equal(built.report.untaggedRecords,1000);
 assert.deepEqual(built.report.cuisineCounts,{});
 for(const [file,bytes]of built.files)assert.equal(await readFile(new URL(file,root),'utf8'),bytes);
 const paths=new Set(),ids=new Set(),signatures=new Set();
 for(const row of built.pack.recipes){
  const p=row.provenance,path=p.sourceSnapshotFile,s=JSON.parse(built.files.get(path));paths.add(path);ids.add(row.id);signatures.add(row.normalizedSourceContentSha256);
  assert.equal(sha(built.files.get(path)),p.sourceSnapshotSha256);assert.deepEqual(s.sourceRecord,input.sources.get(p.recordId));
  assert.deepEqual(s.parsedRecipe,input.recipes.get(`fr-wikibooks:${s.sourceRecord.sourcePageId}`));
  assert.equal(sha(s.sourceRecord.sourceWikitext),p.sourceSha256);assert.equal(snapshotFingerprint(s.parsedRecipe),p.derivedRecipeSha256);
  for(const k of ['recordId','sourceId','sourceRevision','sourceRevisionTimestamp','sourceUrl','sourceSha256','license'])assert.deepEqual(p[k],s.sourceRecord[k]);
  assert.equal(row.nameAr,null);assert.equal(row.sourceLanguage,'fr');assert.equal(row.translationStatus,'not-translated');
  assert.equal(row.runtimeReady,false);assert.equal(row.nutrition,null);assert.deepEqual(row.cuisines,[]);
  assert.equal(row.yield.amount,null);assert.equal(row.time.declaredTotalMinutes,null);
  assert.ok(row.ingredients.length&&row.steps.length);
  const recovered=recoverFrenchLines(s.parsedRecipe,s.sourceRecord);
  assert.equal(row.ingredients.length,recovered.ingredients.length);assert.equal(row.steps.length,recovered.steps.length);
  assert.equal(row.sourceTextRecovery.parserOmittedIngredientLines,recovered.omittedIngredientLines);
  for(const [n,i]of row.ingredients.entries()){
   for(const k of ['amount','unit','optional','included','foodBinding','scales','quantityCandidate'])assert.equal(i[k],null);
   assert.deepEqual(i.sourceLine,recovered.ingredients[n].parserLine);assert.equal(i.sourceText,recovered.ingredients[n].text);
   assert.equal(i.parserSourceText,recovered.ingredients[n].parserSourceText||null);
   assert.equal(i.rawSourceLine,recovered.ingredients[n].rawLine);assert.equal(i.sourceQuantityText,i.sourceLine?.amountText??null);
   assert.equal(i.sourceMarkupReviewRequired,recovered.ingredients[n].unresolvedMarkup);assert.equal(i.sourceLanguage,'fr');
  }
  for(const [n,step]of row.steps.entries()){
   assert.deepEqual(step.sourceStep,s.parsedRecipe.recipe.steps[n]);assert.equal(step.text,recovered.steps[n].text);
   assert.equal(step.rawSourceLine,recovered.steps[n].rawLine);assert.equal(step.parserSourceText,step.sourceStep.text);
   assert.equal(step.durationMinutes,null);assert.equal(step.sourceLanguage,'fr');
  }
 }
 assert.equal(paths.size,1000);assert.equal(ids.size,1000);assert.equal(signatures.size,1000);
 assert.equal(sha(built.files.get(packFile)),built.report.packSha256);
});

test('literal template recovery restores exact displayed names and all parser-omitted ingredient lines',()=>{
 assert.deepEqual(renderFrenchSourceLine("* 2 {{i|'=oui|aubergine}}s"),{text:'2 aubergines',unresolvedMarkup:false});
 assert.deepEqual(renderFrenchSourceLine('* {{i|grenouille|cuisses de grenouilles}}'),{text:'cuisses de grenouilles',unresolvedMarkup:false});
 assert.deepEqual(renderFrenchSourceLine('* 200 g de {{ingrédient|crevette}}s'),{text:'200 g de crevettes',unresolvedMarkup:false});
 assert.deepEqual(renderFrenchSourceLine('* {{càs|1}} de sel'),{text:'{{càs|1}} de sel',unresolvedMarkup:true});
 const omitted=built.pack.recipes.flatMap(r=>r.ingredients.filter(i=>i.sourceParserLineIndex===null));
 assert.equal(omitted.length,125);assert.ok(omitted.every(i=>i.sourceLine===null&&i.rawSourceLine&&i.sourceText));
 const sample=built.pack.recipes.find(r=>r.id==='curated-local:fr:10419');assert.ok(sample);
 const raw=extractFrenchSectionEvidence(input.sources.get(sample.provenance.recordId).sourceWikitext);
 assert.equal(raw.ingredients.length,sample.ingredients.length);
 assert.ok(sample.ingredients.some(i=>i.sourceText==='cuisses de grenouilles'&&i.parserSourceText===null));
});

test('22 pinned previous packs stay excluded by source identity and exact normalized ingredient plus method content',()=>{
 assert.equal(input.previous.length,3530);assert.equal(JSON.parse(input.baselineManifestRaw).packs.length,22);
 assert.equal(sha(input.baselineManifestRaw),baselineManifestSha256);
 const ids=new Set(built.pack.recipes.map(r=>r.id)),records=new Set(built.pack.recipes.map(r=>r.provenance.recordId)),urls=new Set(built.pack.recipes.map(r=>r.provenance.sourceUrl));
 const signatures=new Set(built.pack.recipes.map(r=>r.normalizedSourceContentSha256));
 for(const row of input.previous){
  assert.ok(!ids.has(row.id??row.recipeId));assert.ok(!records.has(row.provenance?.recordId));assert.ok(!urls.has(row.provenance?.sourceUrl));
  const sig=row.normalizedSourceContentSha256??contentSignature((row.ingredients??[]).map(i=>i.sourceText??i.sourceQuantityText??i.name??i.labelAr??i.label??''),(row.steps??[]).map(s=>s.text??s.textAr??''));
  assert.ok(!signatures.has(sig));
 }
 assert.deepEqual(built.report.duplicateReview.excluded,{previousSource:0,previousContent:0,withinArchiveExactContent:1,emptyIngredientOrMethod:0});
});

test('frozen baseline survives registration, rejects drift, and a short archive never lowers the goal',()=>{
 const baseline=JSON.parse(input.baselineManifestRaw),own={...baseline,packs:[...baseline.packs,{kind:'curated-local',file:packFile,sha256:built.report.packSha256,sourceSnapshots:[]}]};
 assert.deepEqual(selectedManifestBaseline(own,baseline),baseline);
 const later={...own,packs:[...own.packs,{kind:'curated-local',file:'data/recipes/curated-local/future/normalized-recipes.json',sha256:'future',sourceSnapshots:[]}]};
 assert.deepEqual(selectedManifestBaseline(later,baseline),baseline);
 assert.deepEqual(validateBaseline(later,baseline),baseline);
 const drift=structuredClone(later);drift.packs[0].sha256='changed';assert.throws(()=>validateBaseline(drift,baseline),/Baseline manifest pin missing or changed/);
 const id=built.pack.recipes[0].provenance.recordId,sources=new Map(input.sources),changed=structuredClone(sources.get(id));changed.sourceWikitext+='changed';sources.set(id,changed);
 assert.throws(()=>buildFourthBatch({...input,sources}),/French source integrity mismatch/);
 const selected=new Set(built.pack.recipes.slice(0,10).map(r=>`fr-wikibooks:${r.id.split(':')[2]}`));
 const recipes=new Map([...input.recipes].filter(([id])=>selected.has(id)));
 assert.throws(()=>buildFourthBatch({...input,recipes}),/Only 10 eligible French source records.*goal not lowered/);
});
