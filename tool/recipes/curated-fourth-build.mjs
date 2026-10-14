import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {loadRecipeReviewSnapshots} from './recipe-review-reader.mjs';
import {snapshotFingerprint} from './review-target.mjs';
import {normalize,cookbook,validateDecision} from './curated-local-build.mjs';
import {auditRecipeImportDraft} from './import-preflight.mjs';
import {makePreflight as priorPreflight} from './curated-third-build.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
export const folder='data/recipes/curated-local/fourth-reviewed-20261014';
export const frozen=[
 ['data/recipes/curated-local/first-reviewed-20261014/normalized-recipes.json','2e8b81cba110ea979f6199dd0a7e8e67c9626e3081c98491897b83664d032946'],
 ['data/recipes/curated-local/gap-review-20261014/normalized-recipes.json','9b4e2d203b80dd25c9c1392ef7b35d3dab097e0fc5e67cbee5a43908851aa4e5'],
 ['data/recipes/curated-local/third-reviewed-20261014/normalized-recipes.json','bef4b419623fd9a981d131232d04b5aa52e1d9e2fab50a0f57b5a313fe821d21']
];
export const sha=v=>createHash('sha256').update(v).digest('hex');
const fmt=v=>JSON.stringify(v,null,2)+'\n';
const need=(v,m)=>{if(!v)throw Error(m);};
export function validateFourthDecision(d,source,raw){
 need(source&&raw,'Missing authoritative source');
 need(sha(raw.sourceWikitext)===raw.sourceSha256&&source.sourceSha256===raw.sourceSha256,'Source wikitext SHA mismatch');
 validateDecision(d,source,raw);
 need(String(raw.sourceRevision)===String(source.sourceRevision)&&raw.sourceUrl===source.sourceUrl,'Raw revision or URL drift');
 need(snapshotFingerprint(raw.license)===snapshotFingerprint(source.license),'Raw source license mismatch');
 need(d.steps.flatMap(s=>s[0]).length===source.recipe.steps.length,'All source steps must appear exactly once');
 need(new Set(d.steps.flatMap(s=>s[0])).size===source.recipe.steps.length,'Repeated source step');
 need(d.steps.flatMap(s=>s[0]).every((index,position)=>index===position),'Source step order must be retained exactly once');
 const labels={chinese:'Chinese',korean:'Korean',indonesian:'Indonesian',greek:'Greek',caribbean:'Caribbean',ethiopian:'Ethiopian',brazilian:'Brazilian',swedish:'Swedish'};
 need(d.cuisines.length>0,'This batch requires explicit source cuisine evidence');
 need(d.cuisines.every(c=>labels[c[0]]&&c[2]==='Category:'+labels[c[0]]+' recipes'),'Cuisine ID and exact category evidence mismatch');
 return true;
}
export function makePreflight(record,source,reviewedAt){
 const draft=priorPreflight(record,source,reviewedAt);
 // A minimum or endpoint-qualified phase is not a fixed scalar timer.
 for(const step of record.steps)if(step.duration?.minimumOnly||step.duration?.endpointQualified)
  for(const index of step.sourceStepIndices)draft.stepMinutes[index]=null;
 return draft;
}
async function immutable(path,bytes){
 try{need((await readFile(path,'utf8'))===bytes,'Immutable output differs: '+path);}
 catch(e){if(e.code!=='ENOENT')throw e;await writeFile(path,bytes,{flag:'wx'});}
}
export async function build(){
 const {recipes,evidence}=await loadRecipeReviewSnapshots();
 const previous=[];
 for(const [path,expected]of frozen){const bytes=await readFile(resolve(root,path));need(sha(bytes)===expected,'Frozen curated pack drift');previous.push(...JSON.parse(bytes).recipes);}
 const decisions=JSON.parse(await readFile(resolve(root,folder,'review-decisions.json'),'utf8'));
 need(decisions.recipes.length>0&&decisions.recipes.length<=8,'Bounded batch exceeded');
 const rawBytes=await readFile(resolve(root,'data/recipes/bulk/wikibooks-cookbook/source-pages.jsonl'));
 const rawMap=new Map(rawBytes.toString('utf8').split(/\r?\n/).filter(Boolean).map(JSON.parse).map(r=>[r.sourcePageId,r]));
 const dest=resolve(root,folder);await mkdir(resolve(dest,'source-snapshots'),{recursive:true});await mkdir(resolve(dest,'preflight-drafts'),{recursive:true});
 const normalized=[],draftReports=[],ids=new Set();
 for(const d of decisions.recipes){
  need(!ids.has(d.sourcePageId)&&!previous.some(r=>r.id==='curated-local:'+d.sourcePageId),'Duplicate existing or selected source ID');ids.add(d.sourcePageId);
  const source=recipes.get('wikibooks:'+d.sourcePageId),raw=rawMap.get(d.sourcePageId);validateFourthDecision(d,source,raw);
  const snapshotBytes=fmt({schemaVersion:1,sourceRecord:raw,authoritativeParsedRecipe:source,authoritativeEvidence:evidence});
  const name=d.sourcePageId+'.json';await immutable(resolve(dest,'source-snapshots',name),snapshotBytes);
  const provenance={sourceId:source.sourceId,recordId:source.recordId,sourceRevision:source.sourceRevision,sourceRevisionTimestamp:raw.sourceRevisionTimestamp,retrievedAt:raw.retrievedAt,sourceUrl:source.sourceUrl,sourceSha256:source.sourceSha256,derivedRecipeSha256:snapshotFingerprint(source),sourceSnapshotFile:folder+'/source-snapshots/'+name,sourceSnapshotSha256:sha(snapshotBytes),license:source.license,licenseSha256:snapshotFingerprint(source.license),changeNotice:decisions.changeNotice};
  const r=normalize(d,source,raw,provenance);
  need(![...previous,...normalized].some(o=>o.familyId===r.familyId||o.name===r.name||o.nameAr===r.nameAr),'Duplicate existing or selected title/family');
  r.contentSha256=snapshotFingerprint(r);normalized.push(r);
  const draft=makePreflight(r,source,decisions.reviewedAt),bytes=fmt(draft);await immutable(resolve(dest,'preflight-drafts',name),bytes);
  draftReports.push({curatedRecipeId:r.id,draftFile:folder+'/preflight-drafts/'+name,draftSha256:sha(bytes),...auditRecipeImportDraft(source,draft)});
 }
 const catalogue=[];for(const slug of ['egyptian','levantine','saudi','italian'])catalogue.push(...JSON.parse(await readFile(resolve(root,'recipes/data/'+slug+'.json'),'utf8')).recipes);
 const counts={recipes:normalized.length,ingredientLines:normalized.reduce((n,r)=>n+r.ingredients.length,0),supplementalIngredients:normalized.reduce((n,r)=>n+r.supplementalIngredients.length,0),steps:normalized.reduce((n,r)=>n+r.steps.length,0),fullySpecified:normalized.filter(r=>r.status==='fully-specified').length,needsReview:normalized.filter(r=>r.status==='needs-review').length,notCookable:normalized.filter(r=>r.status==='not-cookable').length,sourceSupportedCuisineLabels:new Set(normalized.flatMap(r=>r.cuisines.map(c=>c.id))).size,runtimeReady:0};
 const pack={schemaVersion:1,reviewedAt:decisions.reviewedAt,reviewer:decisions.reviewer,changeNotice:decisions.changeNotice,sourceEvidence:evidence,sourceCount:normalized.length,recipes:normalized,relationships:[],counts,duplicateReview:{scope:'Selected source IDs, exact titles and families compared to frozen28;54catalogue exact names. No global6056or cross-language unique-dish claim.',duplicateExistingSourceIds:0,duplicateSelectedSourceIds:0,existingCatalogueCount:catalogue.length,exactCatalogueNameMatches:normalized.flatMap(r=>catalogue.filter(t=>t.name===r.nameAr||t.name===r.name).map(t=>({curatedId:r.id,catalogueId:t.id}))),crossLanguageDuplicateReview:'not performed; no claim of global unique dishes or cross-language deduplication'}};
 const combined=[...previous,...normalized];
 const combinedLocal={recipes:combined.length,fullySpecified:combined.filter(r=>r.status==='fully-specified').length,needsReview:combined.filter(r=>r.status==='needs-review').length,notCookable:combined.filter(r=>r.status==='not-cookable').length,ingredientLines:combined.reduce((n,r)=>n+r.ingredients.length,0),supplementalIngredients:combined.reduce((n,r)=>n+r.supplementalIngredients.length,0),steps:combined.reduce((n,r)=>n+r.steps.length,0),sourceSupportedCuisineLabels:new Set(combined.flatMap(r=>r.cuisines.map(c=>c.id))).size,runtimeReady:0};
 const priorLabels=new Set(previous.flatMap(r=>r.cuisines.map(c=>c.id)));
 const newLabels=[...new Set(normalized.flatMap(r=>r.cuisines.map(c=>c.id)))].filter(id=>!priorLabels.has(id));
 need(newLabels.length===8,'Selected recipes must add eight exact new local source labels');
 const report={schemaVersion:1,reviewedAt:decisions.reviewedAt,networkRequests:0,frozenPacks:frozen.map(([file,sha256])=>({file,sha256})),frozenPreviousRecords:previous.length,counts,combinedLocal,newLabels,draftComplete:0,runtimeReady:0,draftIssues:draftReports.reduce((n,r)=>n+r.issues.length,0),newDraftReports:draftReports,remainingGates:['unquantified ingredients and procedural media remain null','source ranges and minimum/endpoint durations not converted to fixed scalar timers','missing source yield/total time retained as unknown','source-supported cuisine categories are not approved national cuisines','no scaling/food/rights/nutrition/retention or independent culinary approval']};
 await immutable(resolve(dest,'normalized-recipes.json'),fmt(pack));
 await immutable(resolve(dest,'COOKBOOK.ar.md'),cookbook(pack).replace('# أول مجموعة وصفات من الأرشيف المحلي','# الدفعة الرابعة من وصفات الأرشيف المحلي'));
 await immutable(resolve(dest,'review-report.json'),fmt(report));
 for(const [path,expected]of frozen)need(sha(await readFile(resolve(root,path)))===expected,'Frozen pack changed during build');
 console.log(JSON.stringify({folder,...counts,packSha256:sha(fmt(pack)),draftIssues:draftReports.reduce((n,r)=>n+r.issues.length,0)}));
 return {pack,report};
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url))build().catch(e=>{console.error(e);process.exitCode=1});
