import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {folder,sha,applyTimingProposal,build} from './curated-gap-build.mjs';
import {snapshotFingerprint,reviewTarget} from './review-target.mjs';
import {auditRecipeImportDraft} from './import-preflight.mjs';
const repo=new URL('../../',import.meta.url),dir=new URL(folder+'/',repo);
const read=path=>readFile(new URL(path,repo));
const pack=JSON.parse(await readFile(new URL('normalized-recipes.json',dir),'utf8'));
const changes=JSON.parse(await readFile(new URL('timing-patch-proposals.json',dir),'utf8'));
const summary=JSON.parse(await readFile(new URL('gap-review-report.json',dir),'utf8'));
const frozenFile='data/recipes/curated-local/first-reviewed-20261014/normalized-recipes.json';
const frozen=JSON.parse(await read(frozenFile));
const copy=v=>structuredClone(v);
async function context(proposal){
 const record=frozen.recipes.find(r=>r.id===proposal.base.curatedRecordId);
 const snapshot=JSON.parse(await read(record.provenance.sourceSnapshotFile));
 return {record,source:snapshot.authoritativeParsedRecipe,bytes:await read(proposal.base.draftFile)};
}
test('four new records preserve original source, full ingredient targets and byte/canonical pins',async()=>{
 assert.equal(pack.recipes.length,4);
 assert.deepEqual(pack.recipes.map(r=>r.id),['curated-local:11375','curated-local:205147','curated-local:108458','curated-local:130025']);
 for(const r of pack.recipes){
  assert(!frozen.recipes.some(x=>x.id===r.id));
  const bytes=await read(r.provenance.sourceSnapshotFile),snapshot=JSON.parse(bytes);
  assert.equal(sha(bytes),r.provenance.sourceSnapshotSha256);
  assert.equal(sha(snapshot.sourceRecord.sourceWikitext),r.provenance.sourceSha256);
  assert.equal(snapshotFingerprint(snapshot.authoritativeParsedRecipe),r.provenance.derivedRecipeSha256);
  assert.equal(snapshotFingerprint(r.provenance.license),r.provenance.licenseSha256);
  const {contentSha256,...body}=r;assert.equal(snapshotFingerprint(body),contentSha256);
  for(const ingredient of r.ingredients)assert.deepEqual(ingredient.target,reviewTarget(snapshot.authoritativeParsedRecipe,ingredient.sourceLineIndex));
  assert.equal(r.status,'fully-specified');assert.equal(r.runtimeReady,false);assert.equal(r.nutrition,null);
  assert(r.steps.every(s=>s.textAr.length>0));assert(r.ingredients.every(i=>i.nameAr.length>0&&i.amount>0));
 }
});
test('published approximate/volume yields and source ingredient forms are not inferred',async()=>{
 const cocoa=pack.recipes.find(r=>r.id==='curated-local:205147');
 assert.equal(cocoa.yield.amount,null);assert.equal(cocoa.yield.sourceText,'approximately 48');
 assert.equal(cocoa.yield.additionalYield.amount,6);assert.equal(cocoa.yield.additionalYield.unit,'cup');
 assert.equal(cocoa.servingDirections.mix.qualifier,'heaping');
 assert.deepEqual(cocoa.cuisines,[]);
 const report=summary.newDraftReports.find(r=>r.curatedRecipeId===cocoa.id);
 assert.equal(JSON.parse(await read(report.draftFile)).servings,null);
 const punch=pack.recipes.find(r=>r.id==='curated-local:130025');
 assert.equal(punch.ingredients[7].unit,'stick');assert.equal(punch.ingredients[7].amount,3);
 assert.equal(punch.equipment[0].required,true);assert.equal(punch.equipment[0].name,'percolator-style coffee pot');
 const grits=pack.recipes.find(r=>r.id==='curated-local:11375');
 assert.equal(grits.ingredients[3].included,false);assert.equal(grits.ingredients[3].optional,true);
 assert.equal(grits.ingredients[1].name,'hominy grits');
});
test('cuisine labels require exact archived evidence; no source-language or name inference',async()=>{
 for(const r of pack.recipes){
  const source=JSON.parse(await read(r.provenance.sourceSnapshotFile)).sourceRecord;
  for(const c of r.cuisines){
   assert(source.sourceWikitext.includes(c.evidenceText)||source.sourceCategories.some(s=>s.includes(c.evidenceText)));
   assert.equal(c.sourceRecordId,source.recordId);
  }
 }
 assert.deepEqual([...new Set(pack.recipes.flatMap(r=>r.cuisines.map(c=>c.id)))],['native-american','american']);
});
test('persisted source-timer proposals apply with exact source/draft guards and reduce only two audit issues',async()=>{
 assert.equal(changes.proposals.length,2);let before=0,after=0;
 for(const p of changes.proposals){
  const {record,source,bytes}=await context(p),original=JSON.parse(bytes),fingerprint=snapshotFingerprint({record,source});
  const revised=applyTimingProposal(p,source,record,bytes);
  assert.equal(sha(bytes),p.base.draftSha256);
  assert.equal(sha(await read(p.result.draftFile)),p.result.draftSha256);
  assert.deepEqual(revised,JSON.parse(await read(p.result.draftFile)));
  const a=auditRecipeImportDraft(source,original),b=auditRecipeImportDraft(source,revised);
  assert.equal(a.issues.length-b.issues.length,1);before+=a.issues.length;after+=b.issues.length;
  assert.deepEqual(revised.lines,original.lines);
  assert.equal(revised.prepMinutes,original.prepMinutes);assert.equal(revised.cookMinutes,original.cookMinutes);
  assert.equal(revised.servings,original.servings);
  assert.equal(snapshotFingerprint({record,source}),fingerprint);
  for(let i=0;i<revised.stepMinutes.length;i++)if(i!==p.target.stepIndex)assert.equal(revised.stepMinutes[i],original.stepMinutes[i]);
  assert.equal(b.runtimeReady,false);assert.equal(b.draftComplete,false);
 }
 assert.equal(before-after,2);assert.deepEqual(summary.nativeDraftIssues,{before:60,after:58,resolved:2});
 assert.equal(summary.networkRequests,0);assert.equal(summary.frozenOriginalWritten,false);
});
test('source approximation and ranges remain explicit rather than inventing exact total/prep/cook',async()=>{
 const kulfi=changes.proposals.find(p=>p.base.recipeId==='wikibooks:264763');
 assert.equal(kulfi.evidence.approximate,true);assert.equal(kulfi.evidence.scope,'freezing-phase-until-set');
 assert.equal(kulfi.operation.afterMinutes,360);assert.equal(kulfi.evidence.remainingActionsDuration,null);
 const revised=JSON.parse(await read(kulfi.result.draftFile));
 assert.equal(revised.stepMinutes[1],null);assert.equal(revised.servings,null);
 assert.equal(revised.prepMinutes,null);assert.equal(revised.cookMinutes,null);
 assert.match(revised.note,/approximate=true/);
 for(const report of summary.newDraftReports){
  const draft=JSON.parse(await read(report.draftFile));
  assert.equal(draft.prepMinutes,null);assert.equal(draft.cookMinutes,null);
  assert(draft.stepMinutes.every(t=>t===null||t>0));
  assert(draft.lines.every(l=>l.components.every(c=>c.scales===null&&c.food===null)));
  assert.equal(report.draftComplete,false);assert.equal(report.runtimeReady,false);
 }
});
test('tampered target, new zero timer, food/scaling changes, stale bytes or altered result are rejected',async()=>{
 const p=changes.proposals[0],{record,source,bytes}=await context(p);
 for(const mutate of [
  q=>q.operation.afterMinutes=0,
  q=>q.operation.afterMinutes=6,
  q=>q.target.stepIndex=0,
  q=>q.target.sourceStepText='new source',
  q=>q.unchangedUnknowns.push('silently approved foods'),
  q=>q.result.draftFile='data/recipes/curated-local/elsewhere.json',
  q=>q.result.draftSha256='0'.repeat(64),
  q=>q.scaling=true
 ]){
  const q=copy(p);mutate(q);assert.throws(()=>applyTimingProposal(q,source,record,bytes));
 }
 assert.throws(()=>applyTimingProposal(p,source,record,Buffer.concat([bytes,Buffer.from(' ')])),/byte drift/);
 const changedSource=copy(source);changedSource.recipe.steps[p.target.stepIndex].text+=' changed';
 assert.throws(()=>applyTimingProposal(p,changedSource,record,bytes),/snapshot drift/);
});
test('all source steps are mapped or explicitly excluded and old approval/unknown fields are retained',async()=>{
 for(const r of pack.recipes){
  const original=JSON.parse(await read(r.provenance.sourceSnapshotFile)).authoritativeParsedRecipe;
  const seen=new Set([...r.steps.flatMap(s=>s.sourceStepIndices),...r.excludedSourceSteps.map(s=>s.sourceStepIndex)]);
  assert.equal(seen.size,original.recipe.steps.length);
  assert.equal(r.actuallyKitchenTested,false);assert.equal(r.gates.perPageLicenseApproved,false);
  assert.equal(r.gates.nutritionApproved,false);assert.equal(r.gates.inventoryIdentityApproved,false);
  assert(r.ingredients.every(i=>i.scales===null&&i.foodBinding===null));
 }
 assert.equal(sha(await read(frozenFile)),changes.basePackSha256);
 assert.deepEqual(pack.duplicateReview.exactCatalogueNameMatches,[]);
});
test('offline rebuild revalidates current authoritative source and keeps immutable outputs identical',async()=>{
 const before=sha(await read(folder+'/normalized-recipes.json'));
 const result=await build();
 assert.equal(result.pack.recipes.length,4);assert.equal(result.summary.nativeDraftIssues.resolved,2);
 assert.equal(sha(await read(folder+'/normalized-recipes.json')),before);
 assert.equal(sha(await read(frozenFile)),changes.basePackSha256);
});
