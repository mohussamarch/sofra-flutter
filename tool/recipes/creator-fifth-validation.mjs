import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../../',import.meta.url));
export const file='data/recipes/arabic-youtube/fifth-batch-20261014/recipes.json';
const sorted=v=>Array.isArray(v)?v.map(sorted):v&&typeof v==='object'?Object.fromEntries(Object.keys(v).sort().map(k=>[k,sorted(v[k])])):v;
export const fingerprint=v=>createHash('sha256').update(JSON.stringify(sorted(v))).digest('hex');
const need=(v,m)=>{if(!v)throw Error(m)};
const sourceNames=['Turkish-Shish-Tawook-with-Bulgur','Meat-Shawarma','Syrian_meat_shawarma'];
export function validate(batch,priorIds=[]){
 need(batch?.schemaVersion===1&&batch.recipes?.length===3,'Expected bounded three-record batch');
 const p=batch.sourcePolicy;
 need(p?.sourceApproval===null&&p.reuseRights===null&&p.httpBodyHash===null&&p.youtubeDerived===false&&p.mediaDownloaded===false,'No invented source rights/hash/YouTube evidence');
 need(batch.creator?.creatorId==='chef-omar-official-website'&&batch.creator.channelUrl===null&&batch.creator.identityStatus==='website-name-established-channel-link-pending','Channel identity remains unverified');
 const ids=new Set(priorIds),urls=new Set();
 for(const row of batch.recipes){
  need(typeof row.recipeId==='string'&&!ids.has(row.recipeId),'Duplicate/missing recipe identity');ids.add(row.recipeId);
  need(sourceNames.some(n=>row.sourceUrl==='https://www.chef-omar.com/blog/post/'+n+'/')&&!urls.has(row.sourceUrl),'Official unique selected source required');urls.add(row.sourceUrl);
  need(row.evidenceUrl===row.sourceUrl&&row.sourceKind==='creator-website'&&row.youtubeDerived===false&&row.sourceVideoId===null,'Website provenance required');
  need(row.creatorId===batch.creator.creatorId&&row.sourceApproval===null&&row.reuseRights===null&&row.httpBodyHash===null&&row.runtimeReady===false&&row.nutrition===null&&row.foodBindings?.length===0,'No implicit runtime/food/rights approval');
  need(row.retrievedAt==='2026-10-14'&&row.publishedAt===null,'Retrieval and unknown publication required');
  need(row.cuisine?.reviewStatus==='pending'&&row.cuisine.status==='source-declared-pending-human-review'&&row.cuisine.evidenceUrl===row.sourceUrl&&row.cuisine.evidence,'Cuisine source claim only');
  need(row.yield?.amount>0&&row.yield.unit==='serving','Published yield required');
  need(row.methodRepresentation==='concise-Arabic-paraphrase-not-transcript'&&row.sourceStepIndexBase===0&&row.sourceStepCount===2,'Method mapping required');
  need(row.ingredients?.length>0&&row.steps?.length>0&&row.unknowns?.length>0,'Missing readable record');
  for(const i of [...row.ingredients,...row.supplementalIngredients]){
   need(typeof i.labelAr==='string'&&i.labelAr.trim()&&i.evidenceUrl===row.sourceUrl&&i.optional===false,'Ingredient evidence missing');
   need(i.amount===null||typeof i.amount==='number'&&Number.isFinite(i.amount)&&i.amount>0,'Bad quantity');
   need(i.unit===null||typeof i.unit==='string'&&i.unit.length>0,'Bad unit');
   if(i.choiceRequired)need(i.alternatives?.length===2,'Explicit alternative required');
  }
  const mapped=row.steps.flatMap(s=>{need(s.textAr?.trim()&&s.evidenceUrl===row.sourceUrl&&s.sourceStepIndices?.length,'Step evidence missing');return s.sourceStepIndices});
  need(JSON.stringify(mapped)==='[0,1]','Method covers each source part once in order');
  need(row.time?.prepMinutes===null&&row.time.cookMinutes===null&&row.time.totalMinutes===null&&row.time.actualElapsedMinutes===null&&row.time.publishedTotalMinutes>0&&row.time.conflicts?.length,'Published timers are not actual elapsed time');
  for(const t of row.time.sourceTimers)need(t.minutes>0&&t.phase&&t.sourceStepIndices?.every(n=>mapped.includes(n)),'Timer phase evidence missing');
  if(row.acquisitionMethod==='root-primary-search-extract')need(row.sourceEvidence?.rawBodyArchived===false&&row.sourceEvidence.fullPageRetrievedByWorker===false&&row.familyProposal?.reviewStatus==='pending','Cached provenance and unreviewed family required');
  else need(row.acquisitionMethod==='directly-parsed-primary-page','Acquisition method required');
  const {contentSha256,...content}=row;need(contentSha256===fingerprint(content),'Recipe content drift');
 }
 const shish=batch.recipes.find(r=>r.sourceUrl.endsWith('/Turkish-Shish-Tawook-with-Bulgur/'));
 need(shish?.ingredients.filter(i=>i.sourceQuantityText==='Half a spoon').every(i=>i.amount===.5&&i.unit===null)&&shish.time.optionalWaits?.[0]?.minutes===null&&shish.time.optionalWaits[0].optional===true,'Ambiguous spoons and optional overnight remain explicit');
 const meat=batch.recipes.find(r=>r.sourceUrl.endsWith('/Meat-Shawarma/'));
 need(meat?.time.sourceTimers.some(t=>t.minutes===240&&t.bound==='maximum')&&meat.time.sourceTimers.some(t=>t.minutes===1440&&t.bound==='minimum'&&t.conditional===true),'Conflicting four-hour/day limits preserved');
 const syrian=batch.recipes.find(r=>r.sourceUrl.endsWith('/Syrian_meat_shawarma/'));
 need(syrian?.ingredients.some(i=>i.sourceQuantityText==='A cup of olive oil tea'&&i.amount===null&&i.unit===null)&&syrian.ingredients.filter(i=>i.choiceRequired).length===2,'Cup ambiguity and source alternatives preserved');
 return {recipes:3,ingredients:batch.recipes.reduce((n,r)=>n+r.ingredients.length+r.supplementalIngredients.length,0),steps:batch.recipes.reduce((n,r)=>n+r.steps.length,0),sourceCuisineLabels:3,verifiedMultiMethodFamilies:0,youtubeExtractions:0};
}
export async function actual(){
 const previous=['2026-10-first-batch.json','second-batch-20261014/recipes.json','third-batch-20261014/recipes.json','fourth-batch-20261014/recipes.json'];const prior=[];
 for(const p of previous)prior.push(...JSON.parse(await readFile(resolve(root,'data/recipes/arabic-youtube',p),'utf8')).recipes.map(r=>r.recipeId));
 const raw=await readFile(resolve(root,file));const batch=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(raw));
 return {batch,prior,summary:validate(batch,prior),packSha256:createHash('sha256').update(raw).digest('hex')};
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){const a=await actual();console.log(JSON.stringify({...a.summary,packSha256:a.packSha256}));}
