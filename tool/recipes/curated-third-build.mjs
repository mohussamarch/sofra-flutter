import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {loadRecipeReviewSnapshots} from './recipe-review-reader.mjs';
import {snapshotFingerprint} from './review-target.mjs';
import {normalize,cookbook,validateDecision} from './curated-local-build.mjs';
import {emptyImportDraft,auditRecipeImportDraft} from './import-preflight.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
export const folder='data/recipes/curated-local/third-reviewed-20261014';
export const frozen=[
 ['data/recipes/curated-local/first-reviewed-20261014/normalized-recipes.json','2e8b81cba110ea979f6199dd0a7e8e67c9626e3081c98491897b83664d032946'],
 ['data/recipes/curated-local/gap-review-20261014/normalized-recipes.json','9b4e2d203b80dd25c9c1392ef7b35d3dab097e0fc5e67cbee5a43908851aa4e5']
];
export const sha=v=>createHash('sha256').update(v).digest('hex');
const fmt=v=>JSON.stringify(v,null,2)+'\n';
const need=(v,m)=>{if(!v)throw Error(m);};
export function validateThirdDecision(d,source,raw){
 need(source&&raw,'Missing authoritative source');
 need(sha(raw.sourceWikitext)===raw.sourceSha256&&source.sourceSha256===raw.sourceSha256,'Source wikitext SHA mismatch');
 validateDecision(d,source,raw);
 need(String(raw.sourceRevision)===String(source.sourceRevision)&&raw.sourceUrl===source.sourceUrl,'Raw revision or URL drift');
 need(snapshotFingerprint(raw.license)===snapshotFingerprint(source.license),'Raw source license mismatch');
 need(d.steps.flatMap(s=>s[0]).length===source.recipe.steps.length,'All source steps must appear exactly once');
 need(new Set(d.steps.flatMap(s=>s[0])).size===source.recipe.steps.length,'Repeated source step');
 need(d.cuisines.length>0,'This batch requires explicit source cuisine evidence');
 return true;
}
export function makePreflight(record,source,reviewedAt){
 const draft=emptyImportDraft(source);
 Object.assign(draft,{reviewedAt,note:'Manual archived-source transcription only. Unknown/ranged amounts, untimed actions, scaling, food, rights and retention remain unresolved. Approximate phase durations are not exact scalar timers.',servings:record.yield.unit==='source-servings'?record.yield.amount:null,prepMinutes:record.time.prepMinutes,cookMinutes:record.time.cookMinutes});
 for(const i of record.ingredients){
  Object.assign(draft.lines[i.sourceLineIndex],{resolution:/selected|option|alternative/i.test(i.decisionNote)?'choice':'single',disposition:!i.included?'excluded-optional':i.optional?'included-optional':'required',note:i.decisionNote,
   components:!i.included?[]:[{name:i.name,amount:i.amount,unit:i.unit,form:i.name,optional:i.optional,scales:null,food:null}]});
 }
 for(const s of record.steps)if(s.sourceStepIndices.length===1&&s.duration?.min>0&&s.duration.min===s.duration.max&&s.duration.approximate!==true)
  draft.stepMinutes[s.sourceStepIndices[0]]=s.duration.min;
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
  const source=recipes.get('wikibooks:'+d.sourcePageId),raw=rawMap.get(d.sourcePageId);validateThirdDecision(d,source,raw);
  const snapshotBytes=fmt({schemaVersion:1,sourceRecord:raw,authoritativeParsedRecipe:source,authoritativeEvidence:evidence});
  const name=d.sourcePageId+'.json';await immutable(resolve(dest,'source-snapshots',name),snapshotBytes);
  const provenance={sourceId:source.sourceId,recordId:source.recordId,sourceRevision:source.sourceRevision,sourceRevisionTimestamp:raw.sourceRevisionTimestamp,retrievedAt:raw.retrievedAt,sourceUrl:source.sourceUrl,sourceSha256:source.sourceSha256,derivedRecipeSha256:snapshotFingerprint(source),sourceSnapshotFile:folder+'/source-snapshots/'+name,sourceSnapshotSha256:sha(snapshotBytes),license:source.license,licenseSha256:snapshotFingerprint(source.license),changeNotice:decisions.changeNotice};
  const r=normalize(d,source,raw,provenance);r.contentSha256=snapshotFingerprint(r);normalized.push(r);
  const draft=makePreflight(r,source,decisions.reviewedAt),bytes=fmt(draft);await immutable(resolve(dest,'preflight-drafts',name),bytes);
  draftReports.push({curatedRecipeId:r.id,draftFile:folder+'/preflight-drafts/'+name,draftSha256:sha(bytes),...auditRecipeImportDraft(source,draft)});
 }
 const catalogue=[];for(const slug of ['egyptian','levantine','saudi','italian'])catalogue.push(...JSON.parse(await readFile(resolve(root,'recipes/data/'+slug+'.json'),'utf8')).recipes);
 const counts={recipes:normalized.length,ingredientLines:normalized.reduce((n,r)=>n+r.ingredients.length,0),supplementalIngredients:normalized.reduce((n,r)=>n+r.supplementalIngredients.length,0),steps:normalized.reduce((n,r)=>n+r.steps.length,0),fullySpecified:normalized.filter(r=>r.status==='fully-specified').length,needsReview:normalized.filter(r=>r.status==='needs-review').length,notCookable:normalized.filter(r=>r.status==='not-cookable').length,sourceSupportedCuisineLabels:new Set(normalized.flatMap(r=>r.cuisines.map(c=>c.id))).size,runtimeReady:0};
 const pack={schemaVersion:1,reviewedAt:decisions.reviewedAt,reviewer:decisions.reviewer,changeNotice:decisions.changeNotice,sourceEvidence:evidence,sourceCount:normalized.length,recipes:normalized,relationships:[],counts,duplicateReview:{scope:'Selected source IDs and full families/titles compared to frozen20;54catalogue exact names. No global6056or cross-language unique-dish claim.',duplicateExistingSourceIds:0,duplicateSelectedSourceIds:0,existingCatalogueCount:catalogue.length,exactCatalogueNameMatches:normalized.flatMap(r=>catalogue.filter(t=>t.name===r.nameAr||t.name===r.name).map(t=>({curatedId:r.id,catalogueId:t.id}))),crossLanguageDuplicateReview:'not performed; Spanish tortilla explicitly derives from a Spanish source translation; socca/farinata is one recipe with two geographic labels'}};
 const gapAudit=[];
 for(const r of previous){
  const bytes=await readFile(resolve(root,r.provenance.sourceSnapshotFile));need(sha(bytes)===r.provenance.sourceSnapshotSha256,'Frozen old source snapshot drift');
  const snap=JSON.parse(bytes),source=recipes.get('wikibooks:'+r.id.split(':')[1]);need(snapshotFingerprint(source)===r.provenance.derivedRecipeSha256,'Frozen old authoritative recipe drift');
  gapAudit.push({curatedRecipeId:r.id,recordContentSha256:r.contentSha256,sourceSnapshotFile:r.provenance.sourceSnapshotFile,sourceSnapshotSha256:r.provenance.sourceSnapshotSha256,sourceTime:r.time,unresolvedBlockers:r.blockers,timingEvidence:source.recipe.steps.filter(s=>/minutes?|hours?|seconds?|days?/i.test(s.text)).map(s=>({sourceStepIndex:s.n-1,sourceStepText:s.text})),decision:'No new native gap resolved. Existing published phase timers/ranges are already retained in source records or prior timing proposals. Do not infer total/prep/cook, fixed range choice, missing amounts, scaling, food, retention or rights.'});
 }
 const report={schemaVersion:1,reviewedAt:decisions.reviewedAt,networkRequests:0,frozenPacks:frozen.map(([file,sha256])=>({file,sha256})),oldSourceRecordsInspected:previous.length,newNativeGapResolutions:0,existingGapAudit:gapAudit,counts,draftComplete:0,runtimeReady:0,newDraftReports:draftReports,remainingGates:['unquantified ingredients and procedural media remain null','ranges not silently fixed','approximate/conditional step timers not exact scalars','source yield ambiguity and timing conflict remain visible','no automatic scaling/food/rights/nutrition/retention approval']};
 await immutable(resolve(dest,'normalized-recipes.json'),fmt(pack));
 await immutable(resolve(dest,'COOKBOOK.ar.md'),cookbook(pack).replace('# أول مجموعة وصفات من الأرشيف المحلي','# الدفعة الثالثة من وصفات الأرشيف المحلي'));
 await immutable(resolve(dest,'gap-review-report.json'),fmt(report));
 for(const [path,expected]of frozen)need(sha(await readFile(resolve(root,path)))===expected,'Frozen pack changed during build');
 console.log(JSON.stringify({folder,...counts,packSha256:sha(fmt(pack)),draftIssues:draftReports.reduce((n,r)=>n+r.issues.length,0)}));
 return {pack,report};
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url))build().catch(e=>{console.error(e);process.exitCode=1});
