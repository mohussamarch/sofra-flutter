import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {sha,folder,frozen,validateThirdDecision,makePreflight,build} from './curated-third-build.mjs';
import {snapshotFingerprint,reviewTarget} from './review-target.mjs';
import {normalize} from './curated-local-build.mjs';
import {auditRecipeImportDraft} from './import-preflight.mjs';
const root=new URL('../../',import.meta.url),dir=new URL(folder+'/',root);
const read=p=>readFile(new URL(p,root));
const pack=JSON.parse(await readFile(new URL('normalized-recipes.json',dir),'utf8'));
const decisions=JSON.parse(await readFile(new URL('review-decisions.json',dir),'utf8'));
const report=JSON.parse(await readFile(new URL('gap-review-report.json',dir),'utf8'));
const snaps=new Map();for(const r of pack.recipes)snaps.set(r.id,JSON.parse(await read(r.provenance.sourceSnapshotFile)));
const fixture=id=>{const record=pack.recipes.find(r=>r.id==='curated-local:'+id);const s=snaps.get(record.id);return{record,source:structuredClone(s.authoritativeParsedRecipe),raw:structuredClone(s.sourceRecord),decision:structuredClone(decisions.recipes.find(d=>d.sourcePageId===id))};};
test('eight source snapshots preserve byte, revision, licence, line and record pins; previous20 remain frozen',async()=>{
 assert.equal(pack.sourceCount,8);assert.equal(new Set(pack.recipes.map(r=>r.id)).size,8);
 const old=[];for(const [path,expected]of frozen){const bytes=await read(path);assert.equal(sha(bytes),expected);old.push(...JSON.parse(bytes).recipes);}
 for(const r of pack.recipes){const {record,source,raw,decision}=fixture(Number(r.id.split(':')[1]));
  assert(!old.some(o=>o.id===r.id||o.familyId===r.familyId||o.name===r.name));
  assert.equal(sha(await read(r.provenance.sourceSnapshotFile)),r.provenance.sourceSnapshotSha256);
  assert.equal(sha(raw.sourceWikitext),r.provenance.sourceSha256);assert.equal(snapshotFingerprint(source),r.provenance.derivedRecipeSha256);
  assert.equal(snapshotFingerprint(source.license),r.provenance.licenseSha256);assert.deepEqual(source.license,raw.license);
  const {contentSha256,...body}=record;assert.equal(snapshotFingerprint(body),contentSha256);
  assert.equal(validateThirdDecision(decision,source,raw),true);
  for(const i of r.ingredients)assert.deepEqual(i.target,reviewTarget(source,i.sourceLineIndex));
 }
});
test('review refuses actual source text/revision/URL/licence drift and unsupported cuisine claims',()=>{
 for(const mutate of [f=>f.source.recipe.ingredients[0].sourceText+=' changed',f=>f.source.sourceRevision='different',f=>f.raw.sourceWikitext+=' changed',f=>f.raw.sourceRevision='different',f=>f.raw.sourceUrl+='&changed=1',f=>f.raw.license.pageExceptionStatus='approved']){
  const f=fixture(141020);mutate(f);assert.throws(()=>validateThirdDecision(f.decision,f.source,f.raw),/drift|mismatch/i);
 }
 const f=fixture(141020);f.decision.cuisines=[['korean','كوري','Category:Korean recipes']];assert.throws(()=>validateThirdDecision(f.decision,f.source,f.raw),/Cuisine evidence/);
});
test('cuisine diversity uses nine exact source labels for eight recipes, with socca one recipe',()=>{
 assert.deepEqual(new Set(pack.recipes.flatMap(r=>r.cuisines.map(c=>c.id))),new Set(['english','mexican','japanese','thai','polish','spanish','french','italian','turkish']));
 assert.equal(pack.recipes.filter(r=>r.familyId==='curated-local:socca-farinata').length,1);
 for(const r of pack.recipes){const raw=snaps.get(r.id).sourceRecord;for(const c of r.cuisines)assert(raw.sourceWikitext.includes(c.evidenceText)||raw.sourceCategories.some(x=>x.includes(c.evidenceText)));}
 assert.deepEqual(pack.duplicateReview.exactCatalogueNameMatches,[]);
});
test('source ranges and procedural quantities remain unresolved, never replaced by guessed amounts or zero',()=>{
 const japanese=fixture(123453).record;assert.equal(japanese.ingredients[1].amount,null);
 const thai=fixture(134187).record;assert.equal(thai.ingredients[5].amount,null);assert.equal(thai.ingredients[9].amount,null);assert.match(thai.ingredients[5].sourceText,/2–3/);assert.match(thai.ingredients[9].sourceText,/5–6/);
 const polish=fixture(98250).record;assert.equal(polish.yield.amount,null);assert.equal(polish.yield.min,3);assert.equal(polish.yield.max,4);assert.equal(polish.ingredients[1].unit,'ml');assert.equal(polish.ingredients[2].amount,null);
 assert.equal(fixture(107543).record.time.declaredTotalMinutes,null);assert.equal(fixture(107543).record.yield.amount,null);
 const ayran=fixture(99896).record;assert.equal(ayran.ingredients[3].included,false);assert.equal(ayran.ingredients[3].optional,true);assert.equal(ayran.ingredients[2].amount,null);assert(ayran.time.conflict);
 for(const r of pack.recipes)for(const i of r.supplementalIngredients)assert.equal(i.amount,null);
 const wrong=fixture(123453);wrong.decision.status='fully-specified';assert.throws(()=>validateThirdDecision(wrong.decision,wrong.source,wrong.raw),/cannot be unknown/);
});
test('exact phase timers enter draft copies; approximate/range/conditional timers retain precision and unknown totals',async()=>{
 for(const id of [123453,134187,98250,385022,107543,99896]){const {record,source}=fixture(id);const d=makePreflight(record,source,decisions.reviewedAt);assert.equal(d.prepMinutes,null);assert.equal(d.cookMinutes,null);
  if(id===134187)assert.deepEqual(d.stepMinutes,[null,10,5,null]);else assert(d.stepMinutes.every(x=>x===null));
 }
 assert.equal(fixture(123453).record.steps[2].duration.approximate,true);assert.equal(fixture(98250).record.steps[0].duration.approximate,true);
 assert.deepEqual(fixture(385022).record.steps[6].duration,{min:7,max:8,scope:'first-side-before-inversion'});
 assert.equal(fixture(141020).record.ingredients[3].amount,10);assert.equal(fixture(141020).record.ingredients[3].unit,'ml');
 assert.equal(fixture(245915).record.ingredients[3].amount,12);assert.equal(fixture(245915).record.ingredients[3].unit,'oz');
});
test('all source actions mapped once, unknowns and approval gates retained; native drafts remain incomplete',async()=>{
 let issues=0;for(const r of pack.recipes){const {source,raw,decision}=fixture(Number(r.id.split(':')[1]));const before=snapshotFingerprint({decision,source,raw});assert.deepEqual(normalize(decision,source,raw,r.provenance),(({contentSha256,...body})=>body)(r));assert.equal(snapshotFingerprint({decision,source,raw}),before);
  const mapped=r.steps.flatMap(s=>s.sourceStepIndices);assert.equal(mapped.length,source.recipe.steps.length);assert.equal(new Set(mapped).size,mapped.length);
  assert.equal(r.runtimeReady,false);assert.equal(r.nutrition,null);assert.equal(r.actuallyKitchenTested,false);assert.equal(r.gates.perPageLicenseApproved,false);assert.equal(r.gates.inventoryIdentityApproved,false);assert.equal(r.gates.nutritionApproved,false);
  assert(r.ingredients.every(i=>i.scales===null&&i.foodBinding===null));
  const saved=report.newDraftReports.find(x=>x.curatedRecipeId===r.id),bytes=await read(saved.draftFile);assert.equal(sha(bytes),saved.draftSha256);
  const audit=auditRecipeImportDraft(source,JSON.parse(bytes));assert.equal(audit.draftComplete,false);assert.equal(audit.runtimeReady,false);issues+=audit.issues.length;
 }
 assert.equal(issues,152);assert.equal(report.oldSourceRecordsInspected,20);assert.equal(report.newNativeGapResolutions,0);assert.equal(report.networkRequests,0);
 assert.equal(pack.counts.fullySpecified,2);assert.equal(pack.counts.needsReview,6);assert.equal(pack.counts.runtimeReady,0);
});
test('offline authoritative re-extraction reproduces immutable pack/report/cookbook and existing packs',async()=>{
 const paths=['normalized-recipes.json','COOKBOOK.ar.md','gap-review-report.json'];const before=await Promise.all(paths.map(p=>readFile(new URL(p,dir))));
 const rebuilt=await build();assert.equal(rebuilt.pack.recipes.length,8);
 for(let i=0;i<paths.length;i++)assert.deepEqual(await readFile(new URL(paths[i],dir)),before[i]);
 assert.equal(sha(before[0]),'bef4b419623fd9a981d131232d04b5aa52e1d9e2fab50a0f57b5a313fe821d21');
});
