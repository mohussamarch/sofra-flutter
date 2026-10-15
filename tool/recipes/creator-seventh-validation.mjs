import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';

const root=fileURLToPath(new URL('../../',import.meta.url));
export const file='data/recipes/arabic-youtube/seventh-batch-20261015/recipes.json';
const manifestFile='data/recipes/curated-local/flutter-manifest.json';
const sorted=v=>Array.isArray(v)?v.map(sorted):v&&typeof v==='object'?Object.fromEntries(Object.keys(v).sort().map(k=>[k,sorted(v[k])])):v;
export const fingerprint=v=>createHash('sha256').update(JSON.stringify(sorted(v))).digest('hex');
const need=(v,m)=>{if(!v)throw Error(m)};
const canonUrl=s=>{const u=new URL(s),base=`${u.protocol}//${u.host}${decodeURIComponent(u.pathname).replace(/\/$/,'')}`.toLowerCase();return u.hostname.toLowerCase()==='www.youtube.com'&&u.pathname==='/watch'?base+'?v='+u.searchParams.get('v'):base};
const canonTitle=s=>s.normalize('NFC').replace(/[\sـ،؛:!؟.,()\[\]{}]/g,'').toLowerCase();

export function validate(batch,prior={ids:[],titles:[],urls:[]}){
 need(batch?.schemaVersion===1&&batch.batchId==='arabic-creator-seventh-batch-20261015'&&batch.recipes?.length===1,'Expected one bounded recipe');
 need(batch.sourcePolicy?.sourceKind==='creator-youtube'&&batch.sourcePolicy.youtubeDerived===true&&batch.sourcePolicy.sourceApproval===null&&batch.sourcePolicy.reuseRights===null&&batch.sourcePolicy.mediaDownloaded===false&&batch.sourcePolicy.transcriptExtraction===false&&batch.sourcePolicy.httpBodyHash===null,'YouTube description provenance and unknown rights required');
 need(batch.creator?.creatorId==='manal-alalem'&&batch.creator.channelUrl==='https://www.youtube.com/@manalalalem','Official creator identity required');
 need(batch.sourceIndex.length===1&&batch.sourceIndex[0].index===0&&batch.sourceIndex[0].url==='https://www.youtube.com/watch?v=pRhIh2o2x00'&&batch.sourceIndex[0].request===2,'Accepted source index required');
 need(batch.sourceSearchLog.length===6&&batch.sourceSearchLog.every((x,i)=>x.request===i+1),'All six web tool request outcomes must be recorded');
 need(batch.recipes[0].sourceEvidence.sourceIndex===0,'Recipe source evidence index required');
 const ids=new Set(prior.ids),titles=new Set(prior.titles.map(canonTitle)),urls=new Set(prior.urls.map(canonUrl));
 const r=batch.recipes[0];
 need(typeof r.recipeId==='string'&&!ids.has(r.recipeId),'Duplicate/missing recipe identity');
 need(typeof r.title==='string'&&!titles.has(canonTitle(r.title)),'Duplicate/missing normalized title');
 need(r.sourceUrl==='https://www.youtube.com/watch?v=pRhIh2o2x00'&&!urls.has(canonUrl(r.sourceUrl)),'Duplicate source URL');
 need(r.evidenceUrl===r.sourceUrl&&r.sourceKind==='creator-youtube'&&r.youtubeDerived===true&&r.sourceVideoId==='pRhIh2o2x00','YouTube source identity required');
 need(r.sourceApproval===null&&r.reuseRights===null&&r.httpBodyHash===null&&r.runtimeReady===false&&r.nutrition===null&&r.foodBindings.length===0,'No inferred approval or food bindings');
 need(r.publishedAt==='2020-03-16'&&r.retrievedAt==='2026-10-15'&&r.sourceEvidence.titleExact===false&&r.titleBasis,'Date and descriptive title limitations required');
 need(r.cuisine.value===null&&r.cuisine.reviewStatus==='pending'&&r.yield.amount===null&&r.yield.unit===null,'Cuisine and yield unknowns must remain null');
 need(r.time.prepMinutes===null&&r.time.totalMinutes===null&&r.time.publishedTotalMinutes===null&&r.time.actualElapsedMinutes===null,'Unstated times must remain null');
 need(r.methodRepresentation==='concise-Arabic-paraphrase-not-transcript'&&r.sourceStepIndexBase===0&&r.sourceStepCount===5,'Concise paraphrase and source index contract required');
 need(r.ingredients.length===11&&r.ingredients.every((g,i)=>g.sourceIngredientIndex===i&&g.evidenceUrl===r.sourceUrl&&g.optional===false),'All eleven indexed description ingredients required');
 need(r.supplementalIngredients.length===1&&r.supplementalIngredients[0].amount===null&&r.supplementalIngredients[0].sourceIngredientIndex===null,'Unquantified garnish omitted from source list must stay explicit');
 const mapped=r.steps.flatMap(s=>{need(s.textAr?.trim()&&s.evidenceUrl===r.sourceUrl&&s.sourceStepIndices?.length,'Step evidence missing');return s.sourceStepIndices});
 need(JSON.stringify(mapped)===JSON.stringify([0,1,2,3,4]),'All five description steps must map once in order');
 need(r.time.sourceTimers.map(x=>x.minutes).join('|')==='10|15'&&r.time.sourceTimers.every(x=>JSON.stringify(x.sourceStepIndices)==='[2]'),'Only the explicitly timed simmer interval is retained');
 const {contentSha256,...content}=r;need(contentSha256===fingerprint(content),'Recipe content drift');
 const searchQueries=batch.sourceSearchLog.reduce((n,x)=>n+(x.queries?.length??0),0),directOpens=batch.sourceSearchLog.reduce((n,x)=>n+(x.targets?.length??0),0),underlyingRequests=searchQueries+directOpens;
 return {recipes:1,ingredients:12,steps:5,sourceCuisineLabels:0,verifiedMultiMethodFamilies:0,youtubeExtractions:1,sourceToolCalls:batch.sourceSearchLog.length,searchQueries,directOpens,underlyingRequests,requestCap:8,requestCapExceeded:underlyingRequests>8,completeVideoSources:0};
}

export async function actual(){
 const prior={ids:[],titles:[],urls:[]};
 const manifest=JSON.parse(await readFile(resolve(root,manifestFile),'utf8'));
 for(const entry of manifest.packs){if(entry.file===file)continue;const pack=JSON.parse(await readFile(resolve(root,entry.file),'utf8'));for(const r of pack.recipes??[]){prior.ids.push(r.recipeId??r.id);prior.titles.push(r.title??r.name);if(r.nameAr)prior.titles.push(r.nameAr);prior.urls.push(r.sourceUrl??r.provenance?.sourceUrl);}}
 need(prior.ids.length>0,'Dedup scope must include current selected library entries excluding this own pack');
 const raw=await readFile(resolve(root,file));const batch=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(raw));
 return {batch,prior,summary:validate(batch,prior),packSha256:createHash('sha256').update(raw).digest('hex')};
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){const a=await actual();console.log(JSON.stringify({...a.summary,packSha256:a.packSha256}));}
