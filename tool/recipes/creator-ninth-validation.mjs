import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../../',import.meta.url));
export const file='data/recipes/arabic-youtube/ninth-batch-20261015/recipes.json';
const dir='data/recipes/arabic-youtube/ninth-batch-20261015';
const need=(v,m)=>{if(!v)throw Error(m)};
export const sha=v=>createHash('sha256').update(v).digest('hex');
const sorted=v=>Array.isArray(v)?v.map(sorted):v&&typeof v==='object'?Object.fromEntries(Object.keys(v).sort().map(k=>[k,sorted(v[k])])):v;
export const fingerprint=v=>sha(JSON.stringify(sorted(v)));
export function canonicalUrl(s){
 const u=new URL(s),host=u.hostname.toLowerCase().replace(/^www\./,'');
 if(['youtube.com','m.youtube.com','youtu.be'].includes(host)){
  const id=host==='youtu.be'?u.pathname.slice(1):u.pathname==='/watch'?u.searchParams.get('v'):u.pathname.match(/^\/(?:shorts|embed)\/([^/]+)/)?.[1];
  need(typeof id==='string'&&/^[A-Za-z0-9_-]{11}$/.test(id),'Invalid YouTube identity');
  return 'youtube:'+id;
 }
 return u.protocol+'//'+u.hostname.toLowerCase()+decodeURIComponent(u.pathname).replace(/\/$/,'');
}
const title=s=>s.normalize('NFC').replace(/[\sـ،؛:!؟.,()[\]{}\u064b-\u065f]/g,'').toLowerCase();
export function validate(batch,prior={ids:[],titles:[],urls:[]},extracts={}){
 need(batch.schemaVersion===1&&batch.batchId==='arabic-creator-ninth-batch-20261015'&&batch.recipes?.length===2,'Expected two bounded recipes');
 need(batch.requestCap===8&&batch.sourceSearchLog.length===3,'Bounded request log required');
 let count=0;
 for(const log of batch.sourceSearchLog){
  const n=(log.queries?.length??0)+(log.targets?.length??0);
  need(n>0&&JSON.stringify(log.underlyingRequestIndices)===JSON.stringify(Array.from({length:n},(_,i)=>count+i+1)),'Underlying request order drift');
  count+=n;need(count<=batch.requestCap,'Underlying request cap exceeded');
 }
 need(count===4&&count===batch.underlyingRequestCount,'Actual underlying requests required');
 need(batch.quotaAtStart.ordinaryUsageAllowed===true&&[batch.quotaAtStart.primaryUsedPercent,batch.quotaAtStart.weeklyUsedPercent].every(n=>typeof n==='number'&&n>=0&&n<90),'Fresh eligible quota required');
 const p=batch.sourcePolicy;
 need(p.sourceKind==='creator-youtube'&&p.youtubeDerived===true&&p.sourceApproval===null&&p.reuseRights===null&&p.clinicalApproval===null&&p.nutritionApproval===null&&p.httpBodyHash===null&&p.mediaDownloaded===false&&p.transcriptExtraction===false,'Indexed evidence and unknown approval policy required');
 need(batch.creator.creatorId==='naglaa-el-sherbiny'&&batch.creator.publisher==='cbc Sofra'&&batch.creator.channelUrl===null,'Specific publisher attribution without invented channel URL required');
 const ids=new Set(prior.ids),titles=new Set(prior.titles.map(title)),urls=new Set(prior.urls.filter(Boolean).map(canonicalUrl));
 const expected=[{id:'_DmSJzc2Ksc',date:'2022-10-31',ingredients:9,supplemental:1},{id:'aExAOsnzqSI',date:'2022-08-10',ingredients:7,supplemental:0}];
 let ingredients=0,steps=0;
 batch.recipes.forEach((r,i)=>{
  const e=expected[i],url='https://www.youtube.com/watch?v='+e.id;
  need(r.recipeId&&!ids.has(r.recipeId),'Duplicate/missing recipe identity');ids.add(r.recipeId);
  need(r.title&&!titles.has(title(r.title)),'Duplicate/missing normalized title');titles.add(title(r.title));
  need(r.sourceUrl===url&&!urls.has(canonicalUrl(url)),'Duplicate source URL');urls.add(canonicalUrl(url));
  need(r.sourceKind==='creator-youtube'&&r.youtubeDerived===true&&r.sourceVideoId===e.id&&r.evidenceUrl===url,'Video identity drift');
  need(r.publishedAt===e.date&&r.retrievedAt==='2026-10-15'&&r.sourceLanguage==='ar','Source dates/language drift');
  need(r.sourceApproval===null&&r.reuseRights===null&&r.clinicalApproval===null&&r.httpBodyHash===null&&r.runtimeReady===false&&r.nutrition===null&&r.foodBindings.length===0,'No inferred approvals or bindings');
  const x=r.sourceEvidence,s=batch.sourceIndex[i];
  need(s.index===i&&s.request===i+1&&s.url===url&&x.sourceIndex===i&&x.sourceExtractFile===s.extractFile&&x.sourceExtractSha256===s.extractSha256,'Source index/extract mapping drift');
  need(x.acquisitionMethod==='worker-primary-search-extract'&&x.rawBodyArchived===false&&x.fullPageRetrievedByWorker===false&&x.mediaAccessed===false&&x.transcriptAccessed===false&&x.directFetchOutcome==='failed'&&x.directFetchRequest===i+3,'Indexed/direct evidence drift');
  need(x.ingredientListCompleteInExtract===true&&x.methodCompleteInExtract===true&&x.methodSourceStepCount===5&&x.titleExact===true&&x.displayedByline==='cbc Sofra (Verified)','Complete specific-video evidence required');
  need(/^[a-f0-9]{64}$/.test(s.extractSha256),'Extract hash missing');
  if(extracts[s.extractFile]!==undefined){
   const raw=extracts[s.extractFile];
   need(sha(raw)===s.extractSha256,'Source extract hash drift');
   const text=raw.toString('utf8');
   need(text.includes(url)&&text.includes('نجلاء الشرشابي')&&text.includes('By: cbc Sofra')&&text.includes('Verified')&&text.includes(e.date)&&text.includes('المقادير:')&&text.includes('طريقة التحضير:'),'Specific video attribution/content missing');
  }
  need(r.cuisine.value===null&&r.cuisine.reviewStatus==='pending'&&r.yield.amount===null&&r.yield.unit===null,'Cuisine/yield unknowns required');
  need(['prepMinutes','cookMinutes','totalMinutes','publishedTotalMinutes','actualElapsedMinutes'].every(k=>r.time[k]===null)&&r.time.sourceTimers.length===0,'Unstated times must remain null');
  need(r.ingredients.length===e.ingredients&&r.supplementalIngredients.length===e.supplemental,'Ingredient count drift');
  r.ingredients.forEach((g,j)=>need(g.labelAr&&g.sourceIngredientIndex===j&&g.amount===null&&g.unit===null&&g.sourceQuantityText===null&&g.evidenceUrl===url&&g.optional===false,'Unknown quantity/list mapping drift'));
  r.supplementalIngredients.forEach(g=>need(g.sourceIngredientIndex===null&&g.amount===null&&g.unit===null&&g.evidenceUrl===url&&g.optional===false,'Procedural unknown drift'));
  need(r.methodRepresentation==='concise-Arabic-paraphrase-not-transcript'&&r.sourceStepIndexBase===0&&r.sourceStepCount===5&&r.steps.length===5,'Method scope drift');
  need(JSON.stringify(r.steps.flatMap(s=>{need(s.textAr&&s.evidenceUrl===url,'Step evidence missing');return s.sourceStepIndices}))==='[0,1,2,3,4]','Step mapping drift');
  const {contentSha256,...body}=r;need(contentSha256===fingerprint(body),'Recipe content drift');
  ingredients+=r.ingredients.length+r.supplementalIngredients.length;steps+=r.steps.length;
 });
 return {recipes:2,listedIngredients:16,supplementalIngredients:1,ingredients,unknownQuantityLines:ingredients,steps,sourceCuisineLabels:0,verifiedMultiMethodFamilies:0,youtubeExtractions:2,indexedDescriptionRecords:2,completeDirectVideoSources:0,sourceToolCalls:3,searchQueries:2,directOpens:2,underlyingRequests:count,requestCap:8,requestCapExceeded:false,priorRecordsChecked:prior.ids.length};
}
export async function actual(){
 const prior={ids:[],titles:[],urls:[]};
 const manifest=JSON.parse(await readFile(resolve(root,'data/recipes/curated-local/flutter-manifest.json'),'utf8'));
 for(const entry of manifest.packs){
  if(entry.file===file)continue;
  const pack=JSON.parse(await readFile(resolve(root,entry.file),'utf8'));
  for(const r of pack.recipes??[]){prior.ids.push(r.recipeId??r.id);prior.titles.push(r.title??r.name);if(r.nameAr)prior.titles.push(r.nameAr);prior.urls.push(r.sourceUrl??r.provenance?.sourceUrl);}
 }
 need(prior.ids.length>0,'Prior current manifest scope required');
 const raw=await readFile(resolve(root,file)),batch=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(raw));
 const extracts={};
 for(let n=1;n<=3;n++){const p=dir+'/source-extracts/request-0'+n+'.txt';extracts[p]=await readFile(resolve(root,p));}
 const evidence=JSON.parse(await readFile(resolve(root,dir+'/source-evidence.json'),'utf8'));
 need(evidence.requests.length===3&&evidence.requests.every((r,i)=>r.file===dir+'/source-extracts/request-0'+(i+1)+'.txt'&&sha(extracts[r.file])===r.sha256),'Raw web receipt drift');
 need(extracts[dir+'/source-extracts/request-03.txt'].toString('utf8').includes('Failed to fetch https://www.youtube.com/watch?v=_DmSJzc2Ksc')&&extracts[dir+'/source-extracts/request-03.txt'].toString('utf8').includes('Failed to fetch https://www.youtube.com/watch?v=aExAOsnzqSI'),'Direct fetch failures required');
 return {batch,prior,extracts,summary:validate(batch,prior,extracts),packSha256:sha(raw)};
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){const a=await actual();console.log(JSON.stringify({...a.summary,packSha256:a.packSha256}));}
