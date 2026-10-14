import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile,access} from 'node:fs/promises';
import {snapshotFingerprint} from './review-target.mjs';
const root=new URL('../../',import.meta.url);
const folder='data/recipes/curated-local/fourth-reviewed-20261014/';
const read=p=>readFile(new URL(p,root));
let api,pack,decisions,report;
async function init(){if(api)return;api=await import('./curated-fourth-build.mjs');pack=JSON.parse(await read(folder+'normalized-recipes.json'));decisions=JSON.parse(await read(folder+'review-decisions.json'));report=JSON.parse(await read(folder+'review-report.json'));}
async function fixture(id){await init();const record=pack.recipes.find(r=>r.id==='curated-local:'+id);const snap=JSON.parse(await read(record.provenance.sourceSnapshotFile));return{record,source:structuredClone(snap.authoritativeParsedRecipe),raw:structuredClone(snap.sourceRecord),decision:structuredClone(decisions.recipes.find(d=>d.sourcePageId===id))};}
test('new bounded archived-source builder exists',async()=>{let present=true;try{await access(new URL('./curated-fourth-build.mjs',import.meta.url));}catch{present=false;}assert.equal(present,true,'Fourth archived-source builder is not implemented');});
test('every new recipe retains exact source, licence and record pins without old ID, title or family overlap',async()=>{
 await init();assert.equal(pack.recipes.length,8);let old=[];
 for(const [p,expected]of api.frozen){const bytes=await read(p);assert.equal(api.sha(bytes),expected);old.push(...JSON.parse(bytes).recipes);}
 for(const record of pack.recipes){const {source,raw,decision}=await fixture(Number(record.id.split(':')[1]));assert(!old.some(o=>o.id===record.id||o.familyId===record.familyId||o.name===record.name));assert.equal(api.validateFourthDecision(decision,source,raw),true);assert.equal(api.sha(await read(record.provenance.sourceSnapshotFile)),record.provenance.sourceSnapshotSha256);assert.equal(api.sha(raw.sourceWikitext),record.provenance.sourceSha256);assert.equal(snapshotFingerprint(source),record.provenance.derivedRecipeSha256);assert.equal(snapshotFingerprint(raw.license),record.provenance.licenseSha256);const {contentSha256,...body}=record;assert.equal(snapshotFingerprint(body),contentSha256);}
});
test('source drift and fabricated cuisine evidence are rejected',async()=>{
 for(const mutate of [f=>f.raw.sourceWikitext+=' changed',f=>f.source.recipe.ingredients[0].sourceText+=' changed',f=>f.raw.sourceRevision='changed',f=>f.raw.sourceUrl+='changed',f=>f.raw.license.pageExceptionStatus='approved',f=>f.decision.cuisines=[['german','ألماني','Category:German recipes']],f=>f.decision.cuisines=[['korean','كوري','Category:Chinese recipes']]]){const f=await fixture(123460);mutate(f);assert.throws(()=>api.validateFourthDecision(f.decision,f.source,f.raw),/drift|mismatch|evidence/i);}
});
test('step indices must preserve original order exactly once and ingredient decisions preserve order',async()=>{
 for(const mutate of [f=>f.decision.steps.reverse(),f=>f.decision.steps[0][0]=[1],f=>f.decision.ingredients.reverse()]){const f=await fixture(123460);mutate(f);assert.throws(()=>api.validateFourthDecision(f.decision,f.source,f.raw),/order|once|mapped|mapping/i);}
});
test('eight exact archived categories create eight new local labels, with no source language inference',async()=>{
 await init();const labels=pack.recipes.flatMap(r=>r.cuisines.map(c=>c.id));assert.deepEqual(new Set(labels),new Set(['chinese','korean','indonesian','greek','caribbean','ethiopian','brazilian','swedish']));assert.equal(report.combinedLocal.sourceSupportedCuisineLabels,30);assert.equal(report.combinedLocal.recipes,36);
 for(const r of pack.recipes){const {raw}=await fixture(Number(r.id.split(':')[1]));for(const c of r.cuisines)assert(raw.sourceWikitext.includes(c.evidenceText));}assert.deepEqual(pack.duplicateReview.exactCatalogueNameMatches,[]);
});
test('unknown total/yield, ranges and procedural amounts stay unknown; sourced alternative remains explicit',async()=>{
 const chinese=(await fixture(123460)).record;assert.equal(chinese.ingredients[8].amount,null);assert.equal(chinese.supplementalIngredients[0].amount,null);
 const brazil=(await fixture(23358)).record;assert.equal(brazil.yield.amount,null);assert.deepEqual([brazil.yield.min,brazil.yield.max],[25,30]);assert.equal(brazil.time.declaredTotalMinutes,null);assert.equal(brazil.steps[2].duration.min,10);assert.equal(brazil.steps[2].duration.max,12);assert.match(brazil.steps[4].textAr,/ملعقتين معدنيتين/);assert.equal(brazil.supplementalIngredients.length,0);
 const korean=(await fixture(206996)).record;assert.equal(korean.yield.amount,null);assert.equal(korean.time.declaredTotalMinutes,null);assert.equal(korean.steps[2].duration.min,300);
 const ayib=(await fixture(457203)).record;assert.match(ayib.ingredients[1].decisionNote,/lemon.*selected/i);assert.equal(ayib.ingredients[0].unit,'L');assert.equal(ayib.steps[6].duration.approximate,true);assert.equal(ayib.steps[9].duration.minimumOnly,true);
 const awug=(await fixture(471850)).record;assert.equal(awug.supplementalIngredients.length,2);assert(awug.supplementalIngredients.every(i=>i.amount===null));
 const greek=(await fixture(204774)).record;assert.equal(greek.ingredients[5].amount,null);assert.equal(greek.ingredients[6].amount,null);
 const wrong=await fixture(90012);wrong.decision.status='fully-specified';assert.throws(()=>api.validateFourthDecision(wrong.decision,wrong.source,wrong.raw),/yield|time/i);
});
test('preflight scalar timers exclude approximate, range, minimum and endpoint-qualified durations; no approval gates cleared',async()=>{
 await init();let issues=0;for(const r of pack.recipes){const {source}=await fixture(Number(r.id.split(':')[1]));const d=api.makePreflight(r,source,decisions.reviewedAt);if(r.id==='curated-local:471850')assert.deepEqual(d.stepMinutes,[20,null,null,null,null,25,null]);else assert(d.stepMinutes.every(t=>t===null));assert.equal(r.runtimeReady,false);assert.equal(r.nutrition,null);assert.equal(r.actuallyKitchenTested,false);assert(r.ingredients.every(i=>i.foodBinding===null&&i.scales===null));assert.equal(r.gates.perPageLicenseApproved,false);const a=report.newDraftReports.find(a=>a.curatedRecipeId===r.id);assert.equal(a.draftComplete,false);issues+=a.issues.length;}assert.equal(issues,report.draftIssues);assert.equal(pack.counts.fullySpecified,0);assert.equal(pack.counts.needsReview,8);assert.equal(report.networkRequests,0);
});
test('offline authoritative rebuild preserves all immutable bytes and frozen previous28',async()=>{
 await init();const paths=['normalized-recipes.json','COOKBOOK.ar.md','review-report.json'];const before=await Promise.all(paths.map(p=>read(folder+p)));const rebuilt=await api.build();assert.equal(rebuilt.pack.recipes.length,8);for(let i=0;i<paths.length;i++)assert.deepEqual(await read(folder+paths[i]),before[i]);
});
