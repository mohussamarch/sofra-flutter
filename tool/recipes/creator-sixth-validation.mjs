import {readFile,readdir} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {resolve,join} from 'node:path';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../../',import.meta.url));
export const file='data/recipes/arabic-youtube/sixth-batch-20261014/recipes.json';
const priorFiles=['2026-10-first-batch.json','second-batch-20261014/recipes.json','third-batch-20261014/recipes.json','fourth-batch-20261014/recipes.json','fifth-batch-20261014/recipes.json'];
const sorted=v=>Array.isArray(v)?v.map(sorted):v&&typeof v==='object'?Object.fromEntries(Object.keys(v).sort().map(k=>[k,sorted(v[k])])):v;
export const fingerprint=v=>createHash('sha256').update(JSON.stringify(sorted(v))).digest('hex');
const need=(v,m)=>{if(!v)throw Error(m)};
const canonUrl=s=>{const u=new URL(s);return `${u.protocol}//${u.host}${decodeURIComponent(u.pathname).replace(/\/$/,'')}`.toLowerCase()};
const canonTitle=s=>s.normalize('NFC').replace(/[\sـ،؛:!؟.,()\[\]{}]/g,'').toLowerCase();
export function validate(batch,prior={ids:[],titles:[],urls:[]}){
 need(batch?.schemaVersion===1&&batch.batchId==='arabic-creator-sixth-batch-20261014'&&batch.recipes?.length===2,'Expected exactly two bounded records');
 const p=batch.sourcePolicy;
 need(p?.sourceKind==='creator-website'&&p.youtubeDerived===false&&p.sourceApproval===null&&p.reuseRights===null&&p.mediaDownloaded===false&&p.transcriptExtraction===false&&p.httpBodyHash===null,'Do not infer media, rights or source approval');
 need(batch.creator?.creatorId==='manal-alalem'&&batch.creator.channelUrl===null&&batch.creator.identityStatus==='official-website-established-channel-link-pending','Creator website does not establish a verified channel URL');
 need(batch.sourceIndex.length===7&&batch.sourceIndex.every((x,i)=>x.index===i&&x.request===i+1),'Source index and seven attempted requests must be explicit');
 const ids=new Set(prior.ids),titles=new Set(prior.titles.map(canonTitle)),urls=new Set(prior.urls.map(canonUrl));
 for(const row of batch.recipes){
  need(typeof row.recipeId==='string'&&!ids.has(row.recipeId),'Duplicate/missing recipe identity'); ids.add(row.recipeId);
  need(typeof row.title==='string'&&!titles.has(canonTitle(row.title)),'Duplicate/missing normalized title'); titles.add(canonTitle(row.title));
  need(row.sourceUrl.startsWith('https://www.manalonline.com/')&&!urls.has(canonUrl(row.sourceUrl)),'Duplicate or non-official source URL'); urls.add(canonUrl(row.sourceUrl));
  need(row.evidenceUrl===row.sourceUrl&&row.sourceKind==='creator-website'&&row.youtubeDerived===false&&row.sourceVideoId===null,'Website provenance required');
  need(row.creatorId===batch.creator.creatorId&&row.sourceApproval===null&&row.reuseRights===null&&row.httpBodyHash===null&&row.runtimeReady===false&&row.nutrition===null&&row.foodBindings===undefined,'No implicit runtime/food/rights approval');
  need(row.retrievedAt==='2026-10-14'&&row.publishedAt===null,'Retrieval and unknown publication required');
  need(row.cuisine.value===null&&row.cuisine.reviewStatus==='pending'&&row.cuisine.status==='source-cuisine-not-stated'&&row.cuisine.evidenceUrl===row.sourceUrl,'Site category cannot be promoted to cuisine');
  need(row.yield.amount===null&&row.yield.unit===null&&row.time.prepMinutes===null&&row.time.cookMinutes===null&&row.time.totalMinutes===null&&row.time.publishedTotalMinutes===null&&row.time.actualElapsedMinutes===null,'Unknown yield and times must remain null');
  need(row.methodRepresentation==='concise-Arabic-paraphrase-not-transcript'&&row.sourceStepIndexBase===0&&row.sourceStepCount===12,'Method source index contract required');
  need(row.sourceEvidence.acquisitionMethod==='worker-primary-search-extract'&&row.sourceEvidence.rawBodyArchived===false&&row.sourceEvidence.fullPageRetrievedByWorker===false&&batch.sourceIndex[row.sourceEvidence.sourceIndex]?.url===row.sourceUrl,'Search-extract provenance missing');
  need(row.ingredients?.length>0&&Array.isArray(row.supplementalIngredients)&&row.steps?.length>0&&row.unknowns?.length>0,'Incomplete source record');
  for(const [i,g] of [...row.ingredients,...row.supplementalIngredients].entries()){
   need(typeof g.labelAr==='string'&&g.labelAr.trim()&&g.evidenceUrl===row.sourceUrl&&g.optional===false,'Ingredient source evidence missing');
   need(g.amount===null||typeof g.amount==='number'&&Number.isFinite(g.amount)&&g.amount>0,'Bad quantity');
   need(g.unit===null||typeof g.unit==='string'&&g.unit.length>0,'Bad unit');
   if(g.choiceRequired)need(g.alternatives?.length===2,'Explicit alternatives required');
  }
  need(row.ingredients.every((g,i)=>g.sourceIngredientIndex===i),'Source ingredient indexes must preserve the complete list order');
  const mapped=row.steps.flatMap(s=>{need(s.textAr?.trim()&&s.evidenceUrl===row.sourceUrl&&s.sourceStepIndices?.length,'Step evidence missing');return s.sourceStepIndices});
  need(JSON.stringify(mapped)===JSON.stringify(Array.from({length:12},(_,i)=>i)),'Method must map every source step once in order');
  for(const t of row.time.sourceTimers)need((t.minutes===null||t.minutes>0)&&t.phase&&t.sourceStepIndices?.every(n=>mapped.includes(n)),'Timer/phase source mapping invalid');
  const {contentSha256,...content}=row;need(contentSha256===fingerprint(content),'Recipe content drift');
 }
 const rolls=batch.recipes.find(r=>r.recipeId==='manal-website-quick-musakhan-rolls');
 need(rolls?.time.sourceTimers.every(t=>t.minutes===null),'Approximate oven phrase is not a measured timer');
 need(rolls?.ingredients.some(g=>g.choiceRequired&&g.alternatives?.join('|')==='صنوبر|لوز')&&rolls.supplementalIngredients.length===3,'Nut choice and unlisted method additions must remain explicit');
 need(rolls.steps.some(s=>s.textAr.includes('خيار المقلاة'))&&rolls.steps.some(s=>s.textAr.includes('خيار الفرن')),'Both source preparation options must be preserved');
 const tray=batch.recipes.find(r=>r.recipeId==='manal-website-eggplant-chicken-cream-casserole');
 need(tray?.time.sourceTimers.map(t=>t.minutes).join('|')==='30|35'&&tray.supplementalIngredients.some(g=>g.amount===null),'Bake range and unquantified frying oil must remain explicit');
 return {recipes:2,ingredients:rolls.ingredients.length+rolls.supplementalIngredients.length+tray.ingredients.length+tray.supplementalIngredients.length,steps:batch.recipes.reduce((n,r)=>n+r.steps.length,0),sourceCuisineLabels:0,verifiedMultiMethodFamilies:0,youtubeExtractions:0,sourceRequests:7,completeVideoSources:0};
}
export async function actual(){
 const prior={ids:[],titles:[],urls:[]};let priorWebsiteRecords=0;
 for(const p of priorFiles){const b=JSON.parse(await readFile(resolve(root,'data/recipes/arabic-youtube',p),'utf8'));for(const r of b.recipes){prior.ids.push(r.recipeId);prior.titles.push(r.title);prior.urls.push(r.sourceUrl);if(r.sourceKind==='creator-website')priorWebsiteRecords++;}}
 const raw=await readFile(resolve(root,file));const batch=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(raw));
 return {batch,prior,priorWebsiteRecords,summary:validate(batch,prior),packSha256:createHash('sha256').update(raw).digest('hex')};
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){const a=await actual();console.log(JSON.stringify({...a.summary,priorWebsiteRecords:a.priorWebsiteRecords,packSha256:a.packSha256}));}
