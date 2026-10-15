import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';
import {canonicalUrl as priorCanonicalUrl,fingerprint,sha} from './creator-ninth-validation.mjs';
export {fingerprint,sha};
const root=fileURLToPath(new URL('../../',import.meta.url));
const dir='data/recipes/arabic-youtube/tenth-batch-20261015';
export const file=dir+'/recipes.json';
const need=(v,m)=>{if(!v)throw Error(m)};
export function canonicalUrl(s){const u=new URL(s);u.hostname=u.hostname.toLowerCase().replace(/^www\./,'');return priorCanonicalUrl(u.href)}
const title=s=>s.normalize('NFC').replace(/[\sـ،؛:!؟.,()[\]{}\u064b-\u065f]/g,'').toLowerCase();
const quantities=[[[null,null],[1,'tbsp'],[0.5,'tsp'],[1,'tsp'],[3,'clove'],[null,null],[300,'g'],[500,null],[100,'g'],[1,'tbsp'],[600,'ml']],[[1,'cup'],[2,'cup'],[null,null],[2,'piece'],[null,null],[null,null],[null,null]]];
const sourceUrls=['https://chef-omar.com/blog/post/Chicken_with_cream/','https://chef-omar.com/blog/post/Mujaddara-and-Pasta-with-Vegetables/'];
export function validate(batch,prior={ids:[],titles:[],urls:[]},extracts={}){
 need(batch.schemaVersion===1&&batch.batchId==='arabic-creator-tenth-batch-20261015'&&batch.recipes?.length===2,'Expected two bounded recipes');
 need(batch.requestCap===8&&batch.sourceSearchLog.length===7,'Bounded request log required');
 let count=0;
 for(const log of batch.sourceSearchLog){
  const n=(log.queries?.length??0)+(log.targets?.length??0);
  need(n>0&&JSON.stringify(log.underlyingRequestIndices)===JSON.stringify(Array.from({length:n},(_,i)=>count+i+1)),'Underlying request order drift');
  count+=n;need(count<=8,'Underlying request cap exceeded');
 }
 need(count===8&&batch.underlyingRequestCount===count,'Actual underlying requests required');
 const q=batch.quotaAtStart;
 need(q.ordinaryUsageAllowed===true&&[q.primaryUsedPercent,q.weeklyUsedPercent].every(n=>typeof n==='number'&&n>=0&&n<90),'Fresh eligible quota required');
 const p=batch.sourcePolicy;
 need(p.sourceKind==='creator-website'&&p.youtubeDerived===false&&p.sourceApproval===null&&p.reuseRights===null&&p.clinicalApproval===null&&p.nutritionApproval===null&&p.httpBodyHash===null&&p.mediaDownloaded===false&&p.transcriptExtraction===false,'Website evidence and unknown approval required');
 need(batch.creator.creatorId==='chef-omar-official-website'&&batch.creator.channelUrl===null&&batch.creator.identityStatus==='site-attributed; ownership-link-to-verified-channel-not-established-in-this-unit','Unconfirmed site ownership scope required');
 need(batch.sourceIndex.length===2,'Two accepted source mappings required');
 const ids=new Set(prior.ids),titles=new Set(prior.titles.map(title)),urls=new Set(prior.urls.filter(Boolean).map(canonicalUrl));
 let ingredients=0,steps=0,knownAmountAndUnit=0,missingAmount=0,missingUnit=0;
 batch.recipes.forEach((r,i)=>{
  const url=sourceUrls[i],e=r.sourceEvidence,s=batch.sourceIndex[i];
  need(r.recipeId&&!ids.has(r.recipeId),'Duplicate/missing recipe identity');ids.add(r.recipeId);
  need(r.title&&!titles.has(title(r.title)),'Duplicate/missing normalized title');titles.add(title(r.title));
  need(r.sourceUrl===url&&!urls.has(canonicalUrl(url)),'Duplicate source URL');urls.add(canonicalUrl(url));
  need(r.creatorId===batch.creator.creatorId&&r.sourceKind==='creator-website'&&r.youtubeDerived===false&&r.sourceVideoId===null&&r.evidenceUrl===url,'Website identity drift');
  need(r.sourceApproval===null&&r.reuseRights===null&&r.clinicalApproval===null&&r.httpBodyHash===null&&r.runtimeReady===false&&r.nutrition===null&&r.foodBindings.length===0,'No inferred approval or bindings');
  need(r.publishedAt===null&&r.retrievedAt==='2026-10-15'&&r.cuisine.value===null&&r.cuisine.reviewStatus==='pending','Source unknowns drift');
  need(e.sourceIndex===i&&s.index===i&&s.url===url&&s.request===(i===0?6:5)&&s.extractFile===e.sourceExtractFile&&s.extractSha256===e.sourceExtractSha256&&/^[a-f0-9]{64}$/.test(s.extractSha256),'Source index/hash mapping drift');
  need(e.acquisitionMethod==='worker-primary-search-extract'&&e.rawBodyArchived===false&&e.fullPageRetrievedByWorker===false&&e.mediaAccessed===false&&e.transcriptAccessed===false&&e.ingredientListCompleteInExtract===true&&e.methodCompleteInExtract===true,'Indexed evidence drift');
  need(e.directFetchOutcome===(i===0?'failed-cache-miss':'not-attempted')&&e.directFetchRequest===(i===0?7:null),'Direct fetch evidence drift');
  const raw=extracts[e.sourceExtractFile];
  if(raw!==undefined){
   need(sha(raw)===e.sourceExtractSha256,'Source extract hash drift');
   const text=raw.toString('utf8');
   need(text.includes(url)&&text.includes(e.sourcePageTitle)&&text.includes('### Ingredients')&&text.includes('How to Make It'),'Specific recipe extract incomplete');
   for(const g of r.ingredients)need(text.includes(g.sourceQuantityText),'Ingredient missing from source extract');
  }
  need(e.sourcePageYield.amount===4&&e.sourcePageTotalTime.minutes===30,'Page metadata must be retained');
  need(r.yield.amount===(i===0?4:null)&&r.yield.unit===(i===0?'serving':null),'Yield scope drift');
  need(['prepMinutes','cookMinutes','totalMinutes','actualElapsedMinutes'].every(k=>r.time[k]===null)&&r.time.publishedTotalMinutes===(i===0?30:null),'Unstated/component times must remain unknown');
  need(i===0?JSON.stringify(r.time.sourceTimers.map(t=>t.minutes))==='[2,2,10]'&&r.time.sourceTimers.every(t=>t.approximate===true&&JSON.stringify(t.sourceStepIndices)==='[1]'):r.time.sourceTimers.length===0,'Phase timers drift');
  need(e.sourcePageYield.scope===(i===0?'whole-recipe':'combined-page-not-assigned-to-component')&&e.sourcePageTotalTime.scope===e.sourcePageYield.scope,'Component scope drift');
  need(r.ingredients.length===quantities[i].length&&r.supplementalIngredients.length===0,'Ingredient count drift');
  r.ingredients.forEach((g,j)=>{
   need(g.labelAr&&g.sourceQuantityText&&g.sourceIngredientIndex===j&&g.evidenceUrl===url&&g.optional===false,'Ingredient evidence drift');
   need(JSON.stringify([g.amount,g.unit])===JSON.stringify(quantities[i][j]),'Source quantity/unit drift');
   if(g.amount===null)missingAmount++;if(g.unit===null)missingUnit++;if(g.amount!==null&&g.unit!==null)knownAmountAndUnit++;
  });
  need(r.methodRepresentation==='concise-Arabic-paraphrase-not-transcript'&&r.sourceStepIndexBase===0&&r.sourceStepCount===(i===0?2:1)&&e.methodSourceStepCount===r.sourceStepCount&&r.steps.length===(i===0?5:4),'Method/part scope drift');
  need(JSON.stringify(r.steps.map(s=>{need(s.textAr&&s.evidenceUrl===url,'Step evidence missing');return s.sourceStepIndices}))===(i===0?'[[0],[0],[1],[1],[1]]':'[[0],[0],[0],[0]]'),'Step part mapping drift');
  const {contentSha256,...body}=r;need(contentSha256===fingerprint(body),'Recipe content drift');
  ingredients+=r.ingredients.length;steps+=r.steps.length;
 });
 return {recipes:2,creatorWebsiteRecords:2,youtubeExtractions:0,ingredients,steps,sourceMethodParts:3,knownAmountAndUnitLines:knownAmountAndUnit,missingAmountLines:missingAmount,missingUnitLines:missingUnit,quantityIncompleteLines:ingredients-knownAmountAndUnit,sourceCuisineLabels:0,verifiedMultiMethodFamilies:0,completeDirectBodySources:0,sourceToolCalls:7,searchQueries:6,directOpens:2,underlyingRequests:count,requestCap:8,requestCapExceeded:false,priorRecordsChecked:prior.ids.length,priorCreatorRecordsChecked:prior.creatorCount??null};
}
export async function actual(){
 const prior={ids:[],titles:[],urls:[],creatorCount:0};
 const manifest=JSON.parse(await readFile(resolve(root,'data/recipes/curated-local/flutter-manifest.json'),'utf8'));
 for(const entry of manifest.packs){
  if(entry.file===file)continue;
  const pack=JSON.parse(await readFile(resolve(root,entry.file),'utf8'));
  for(const r of pack.recipes??[]){prior.ids.push(r.recipeId??r.id);prior.titles.push(r.title??r.name);if(r.nameAr)prior.titles.push(r.nameAr);prior.urls.push(r.sourceUrl??r.provenance?.sourceUrl);if((r.sourceKind??'').startsWith('creator-'))prior.creatorCount++;}
 }
 need(prior.ids.length>0,'Prior manifest scope required');
 const raw=await readFile(resolve(root,file)),batch=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(raw)),extracts={};
 for(let n=1;n<=7;n++){const p=dir+'/source-extracts/request-0'+n+'.txt';extracts[p]=await readFile(resolve(root,p));}
 const evidence=JSON.parse(await readFile(resolve(root,dir+'/source-evidence.json'),'utf8'));
 need(evidence.requests.length===7&&evidence.requests.every((r,i)=>r.file===dir+'/source-extracts/request-0'+(i+1)+'.txt'&&sha(extracts[r.file])===r.sha256&&JSON.stringify(r.underlyingRequestIndices)===JSON.stringify(batch.sourceSearchLog[i].underlyingRequestIndices)),'Raw web receipt drift');
 return {batch,prior,extracts,summary:validate(batch,prior,extracts),packSha256:sha(raw)};
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){const a=await actual();console.log(JSON.stringify({...a.summary,packSha256:a.packSha256}));}
