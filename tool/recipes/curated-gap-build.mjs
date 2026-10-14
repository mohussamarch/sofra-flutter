import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {loadRecipeReviewSnapshots} from './recipe-review-reader.mjs';
import {snapshotFingerprint} from './review-target.mjs';
import {normalize,cookbook} from './curated-local-build.mjs';
import {emptyImportDraft,auditRecipeImportDraft} from './import-preflight.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
export const folder='data/recipes/curated-local/gap-review-20261014';
const original='data/recipes/curated-local/first-reviewed-20261014';
const expectedPack='2e8b81cba110ea979f6199dd0a7e8e67c9626e3081c98491897b83664d032946';
export const sha=v=>createHash('sha256').update(v).digest('hex');
const need=(v,m)=>{if(!v)throw Error(m);};
const fmt=v=>JSON.stringify(v,null,2)+'\n';
const timing=[
 {id:17844,stepIndex:2,phrase:'After five minutes',minutes:5,approximate:false,scope:'monitoring-stirring-before-milk',draftSha:'9d0f275a0ae1f35823e8cf0ae20e9d8913fad8857ac9da8f00a11821bea5b015'},
 {id:264763,stepIndex:3,phrase:'freeze for about 6 hours until set',minutes:360,approximate:true,scope:'freezing-phase-until-set',draftSha:'6bacd4ab95cc5bc40363fe8be9b29d48cdde278bae8cf6f3a1597c35f741e563'}
];
export function createTimingProposal(decision,source,record,draftBytes,reviewedAt){
 need(sha(draftBytes)===decision.draftSha,'Original draft byte drift');
 const draft=JSON.parse(draftBytes),step=source.recipe.steps[decision.stepIndex];
 need(source.id==='wikibooks:'+decision.id&&source.recordId===record.provenance.recordId,'Timing source identity mismatch');
 need(source.sourceSha256===record.provenance.sourceSha256&&snapshotFingerprint(source)===record.provenance.derivedRecipeSha256,'Timing source snapshot drift');
 need(step?.text.includes(decision.phrase),'Exact published timing phrase missing');
 need(draft.recipeSha256===snapshotFingerprint(source)&&draft.stepMinutes[decision.stepIndex]===null,'Draft slot no longer unresolved');
 return {
  schemaVersion:1,id:'curated-gap:'+decision.id+':step-'+decision.stepIndex,reviewedAt,
  changeType:'source-supported-step-timer',runtimeReady:false,
  base:{curatedRecordId:record.id,curatedRecordContentSha256:record.contentSha256,recipeId:source.id,recordId:source.recordId,
   sourceRevision:source.sourceRevision,sourceSha256:source.sourceSha256,derivedRecipeSha256:snapshotFingerprint(source),
   sourceSnapshotFile:record.provenance.sourceSnapshotFile,sourceSnapshotSha256:record.provenance.sourceSnapshotSha256,
   draftFile:original+'/preflight-drafts/'+decision.id+'.json',draftSha256:decision.draftSha},
  target:{field:'stepMinutes',stepIndex:decision.stepIndex,sourceStepText:step.text,sourceStepTextSha256:sha(step.text)},
  evidence:{exactPhrase:decision.phrase,sourceUrl:source.sourceUrl,scope:decision.scope,
   approximate:decision.approximate,remainingActionsDuration:null,
   note:decision.approximate?'Published approximate freezing timer; loading/covering actions are not separately timed.':'Published five-minute stirring interval before adding milk.'},
  operation:{before:null,afterMinutes:decision.minutes},
  unchangedUnknowns:['prepMinutes','cookMinutes','unmentioned step timers','scaling','food identities','rights/retention/nutrition']
 };
}
export function applyTimingProposal(proposal,source,record,draftBytes){
 need(proposal?.schemaVersion===1&&proposal.changeType==='source-supported-step-timer'&&proposal.runtimeReady===false,'Invalid timing-only proposal');
 const approved=timing.find(t=>source.id==='wikibooks:'+t.id);
 need(approved,'Unreviewed timing decision');
 const expected=createTimingProposal(approved,source,record,draftBytes,proposal.reviewedAt);
 const {result,...core}=proposal;
 need(snapshotFingerprint(core)===snapshotFingerprint(expected),'Changed timing proposal or target');
 const draft=JSON.parse(draftBytes);
 draft.stepMinutes[proposal.target.stepIndex]=proposal.operation.afterMinutes;
 draft.reviewedAt=proposal.reviewedAt;
 draft.note+=' Timing review '+proposal.id+': '+proposal.evidence.exactPhrase+
  '; scope='+proposal.evidence.scope+'; approximate='+proposal.evidence.approximate+
  '. Other actions/unknown timing, scaling, food and rights remain unresolved.';
 if(result!==undefined)need(snapshotFingerprint(result)===snapshotFingerprint({draftFile:folder+'/revised-preflight-drafts/'+approved.id+'.json',draftSha256:sha(fmt(draft))}),'Changed timing proposal result');
 return draft;
}
const countIssues=r=>r.issues.reduce((a,v)=>(a[v.code]=(a[v.code]??0)+1,a),{});
async function immutable(path,bytes){
 try{need((await readFile(path,'utf8'))===bytes,'Existing immutable artifact differs: '+path);}
 catch(e){if(e.code!=='ENOENT')throw e;await writeFile(path,bytes,{flag:'wx'});}
}
export async function build(){
 const {recipes,evidence}=await loadRecipeReviewSnapshots();
 const baseBytes=await readFile(resolve(root,original,'normalized-recipes.json'));
 need(sha(baseBytes)===expectedPack,'Frozen original curated pack drift');
 const base=JSON.parse(baseBytes),dest=resolve(root,folder);
 const decisions=JSON.parse(await readFile(resolve(dest,'review-decisions.json'),'utf8'));
 await mkdir(resolve(dest,'source-snapshots'),{recursive:true});
 await mkdir(resolve(dest,'revised-preflight-drafts'),{recursive:true});
 await mkdir(resolve(dest,'new-preflight-drafts'),{recursive:true});
 const proposals=[],audits=[];
 for(const r of base.recipes.filter(r=>['141667','264763','303834','17844'].includes(r.id.split(':')[1]))){
  const id=Number(r.id.split(':')[1]),source=recipes.get('wikibooks:'+id);
  const snapshotBytes=await readFile(resolve(root,r.provenance.sourceSnapshotFile));
  need(sha(snapshotBytes)===r.provenance.sourceSnapshotSha256,'Frozen source snapshot drift');
  const draftBytes=await readFile(resolve(root,original,'preflight-drafts',id+'.json'));
  const before=auditRecipeImportDraft(source,JSON.parse(draftBytes));
  const action=timing.find(t=>t.id===id);
  let after=before,newFile=null;
  if(action){
   const proposal=createTimingProposal(action,source,r,draftBytes,decisions.reviewedAt);
   const revised=applyTimingProposal(proposal,source,r,draftBytes);
   after=auditRecipeImportDraft(source,revised);
   newFile=folder+'/revised-preflight-drafts/'+id+'.json';
   await immutable(resolve(root,newFile),fmt(revised));
   proposals.push({...proposal,result:{draftFile:newFile,draftSha256:sha(fmt(revised))}});
  }
  audits.push({recipeId:source.id,before:{issueCount:before.issues.length,byCode:countIssues(before)},after:{issueCount:after.issues.length,byCode:countIssues(after)},revisedDraftFile:newFile,draftComplete:after.draftComplete,runtimeReady:false});
 }
 await immutable(resolve(dest,'timing-patch-proposals.json'),fmt({schemaVersion:1,basePackFile:original+'/normalized-recipes.json',basePackSha256:expectedPack,proposals}));
 const rawBytes=await readFile(resolve(root,'data/recipes/bulk/wikibooks-cookbook/source-pages.jsonl'));
 const rawMap=new Map(rawBytes.toString('utf8').split(/\r?\n/).filter(Boolean).map(JSON.parse).map(x=>[x.sourcePageId,x]));
 const normalized=[],newDraftReports=[];
 for(const d of decisions.recipes){
  need(!base.recipes.some(r=>r.id==='curated-local:'+d.sourcePageId),'Addition duplicates frozen first pack');
  const source=recipes.get('wikibooks:'+d.sourcePageId),raw=rawMap.get(d.sourcePageId);
  need(source&&raw&&sha(raw.sourceWikitext)===raw.sourceSha256,'Missing or changed authoritative raw source');
  const snapshot={schemaVersion:1,sourceRecord:raw,authoritativeParsedRecipe:source,authoritativeEvidence:evidence};
  const snapshotBytes=fmt(snapshot),name=d.sourcePageId+'.json';
  await immutable(resolve(dest,'source-snapshots',name),snapshotBytes);
  const provenance={sourceId:source.sourceId,recordId:source.recordId,sourceRevision:source.sourceRevision,
   sourceRevisionTimestamp:raw.sourceRevisionTimestamp,retrievedAt:raw.retrievedAt,sourceUrl:source.sourceUrl,
   sourceSha256:source.sourceSha256,derivedRecipeSha256:snapshotFingerprint(source),
   sourceSnapshotFile:folder+'/source-snapshots/'+name,sourceSnapshotSha256:sha(snapshotBytes),
   license:source.license,licenseSha256:snapshotFingerprint(source.license),changeNotice:decisions.changeNotice};
  const r=normalize(d,source,raw,provenance);
  if(d.servingDirections)r.servingDirections=structuredClone(d.servingDirections);
  if(d.equipment)r.equipment=structuredClone(d.equipment);
  r.contentSha256=snapshotFingerprint(r);normalized.push(r);
  const draft=emptyImportDraft(source);
  Object.assign(draft,{note:'Manual source quantities/choices. Timing only where expressly stated. Unknown scaling/food/rights remain unresolved.',reviewedAt:decisions.reviewedAt,
   servings:r.yield.unit==='source-servings'?r.yield.amount:null});
  for(const i of r.ingredients){
   const excluded=!i.included;
   Object.assign(draft.lines[i.sourceLineIndex],{resolution:/selected|option|alternative/i.test(i.decisionNote)?'choice':'single',
    disposition:excluded?'excluded-optional':i.optional?'included-optional':'required',note:i.decisionNote,
    components:excluded?[]:[{name:i.name,amount:i.amount,unit:i.unit,form:i.name,optional:i.optional,scales:null,food:null}]});
  }
  for(const step of r.steps)if(step.sourceStepIndices.length===1&&step.duration?.min===step.duration?.max&&step.duration?.min>0)
   draft.stepMinutes[step.sourceStepIndices[0]]=step.duration.min;
  const report=auditRecipeImportDraft(source,draft);
  await immutable(resolve(dest,'new-preflight-drafts',name),fmt(draft));
  newDraftReports.push({curatedRecipeId:r.id,draftFile:folder+'/new-preflight-drafts/'+name,draftSha256:sha(fmt(draft)),...report});
 }
 const counts={recipes:normalized.length,ingredientLines:normalized.reduce((n,r)=>n+r.ingredients.length,0),steps:normalized.reduce((n,r)=>n+r.steps.length,0),
  fullySpecified:normalized.filter(r=>r.status==='fully-specified').length,runtimeReady:0};
 const pack={schemaVersion:1,reviewedAt:decisions.reviewedAt,reviewer:decisions.reviewer,changeNotice:decisions.changeNotice,
  sourceEvidence:evidence,sourceCount:normalized.length,recipes:normalized,relationships:[],counts,
  duplicateReview:{scope:'explicit selected source IDs against frozen16 and54catalogue names; notglobal6056dedup',duplicateFrozenSourceIds:0}};
 const titles=[];
 for(const slug of ['egyptian','levantine','saudi','italian']){
  const data=JSON.parse(await readFile(resolve(root,'recipes/data/'+slug+'.json'),'utf8'));titles.push(...data.recipes);
 }
 pack.duplicateReview.exactCatalogueNameMatches=normalized.flatMap(r=>titles.filter(t=>t.name===r.nameAr||t.name===r.name).map(t=>({curatedId:r.id,catalogueId:t.id})));
 const before=audits.reduce((n,r)=>n+r.before.issueCount,0),after=audits.reduce((n,r)=>n+r.after.issueCount,0);
 const summary={schemaVersion:1,reviewedAt:decisions.reviewedAt,networkRequests:0,frozenOriginalWritten:false,
  nativeDraftIssues:{before,after,resolved:before-after},sourceTimerSlotsResolved:proposals.length,originalDrafts:audits,
  additionalRecipes:counts,newDraftReports,remainingGates:['all unsourced times remain null','no inferred fixed servings from ranges/volume/approximate yield','scaling/food/rights/form/basis/retention/nutrition unresolved']};
 await immutable(resolve(dest,'normalized-recipes.json'),fmt(pack));
 await immutable(resolve(dest,'COOKBOOK.ar.md'),cookbook(pack).replace('# أول مجموعة وصفات من الأرشيف المحلي','# وصفات إضافية من الأرشيف المحلي — مراجعة فجوات'));
 await immutable(resolve(dest,'gap-review-report.json'),fmt(summary));
 need(sha(await readFile(resolve(root,original,'normalized-recipes.json')))===expectedPack,'Frozen pack changed during review');
 console.log(JSON.stringify({folder,...counts,nativeDraftIssues:summary.nativeDraftIssues,packSha256:sha(fmt(pack))}));
 return {pack,summary};
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url))build().catch(e=>{console.error(e);process.exitCode=1});
