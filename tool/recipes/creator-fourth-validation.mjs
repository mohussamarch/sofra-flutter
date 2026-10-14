import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../../',import.meta.url));
export const file='data/recipes/arabic-youtube/fourth-batch-20261014/recipes.json';
const sorted=v=>Array.isArray(v)?v.map(sorted):v&&typeof v==='object'?Object.fromEntries(Object.keys(v).sort().map(k=>[k,sorted(v[k])])):v;
export const fingerprint=v=>createHash('sha256').update(JSON.stringify(sorted(v))).digest('hex');
const need=(v,m)=>{if(!v)throw Error(m)};
export function validate(batch,priorIds=[]){
 need(batch?.schemaVersion===1&&batch.recipes?.length===5,'Expected bounded five-record batch');
 const policy=batch.sourcePolicy;
 need(policy?.sourceApproval===null&&policy.reuseRights===null&&policy.httpBodyHash===null&&policy.youtubeDerived===false,'No invented source rights/hash/YouTube evidence');
 const ids=new Set(priorIds),urls=new Set();
 for(const row of batch.recipes){
  need(typeof row.recipeId==='string'&&!ids.has(row.recipeId),'Duplicate/missing recipe identity');ids.add(row.recipeId);
  need(typeof row.sourceUrl==='string'&&new URL(row.sourceUrl).origin==='https://www.manalonline.com'&&!urls.has(row.sourceUrl),'Official unique source required');urls.add(row.sourceUrl);
  need(row.sourceKind==='creator-website'&&row.youtubeDerived===false&&row.sourceVideoId===null,'Website provenance required');
  need(row.creatorId===batch.creator?.creatorId&&row.sourceApproval===null&&row.reuseRights===null&&row.runtimeReady===false&&row.nutrition===null&&Array.isArray(row.foodBindings)&&row.foodBindings.length===0,'No implicit runtime/food/rights approval');
  need(row.cuisine===null&&row.yield?.amount===null&&row.yield.unit===null,'Source lacks declared cuisine and servings');
  need(row.methodRepresentation==='concise-Arabic-paraphrase-not-transcript'&&row.sourceStepIndexBase===0,'Method representation required');
  need(row.ingredients?.length>0&&row.steps?.length>0&&row.unknowns?.length>0,'Missing readable method or unknowns');
  for(const i of [...row.ingredients,...(row.supplementalIngredients??[])]){
   need(typeof i.labelAr==='string'&&i.labelAr.trim()&&i.evidenceUrl===row.sourceUrl,'Ingredient evidence missing');
   need(i.amount===null||typeof i.amount==='number'&&Number.isFinite(i.amount)&&i.amount>0,'Bad quantity');
  }
  const stepIndices=[];
  for(const s of row.steps){
   need(typeof s.textAr==='string'&&s.textAr.trim()&&s.evidenceUrl===row.sourceUrl&&Array.isArray(s.sourceStepIndices)&&s.sourceStepIndices.length>0,'Step evidence missing');
   for(const n of s.sourceStepIndices){need(Number.isInteger(n)&&n>=0,'Bad source step index');stepIndices.push(n)}
  }
  need(stepIndices.every((n,i)=>n===i),'Method must cover each source step once in order');
  need(row.time?.prepMinutes===null&&row.time.cookMinutes===null&&row.time.totalMinutes===null,'Phase timers are not total duration');
  for(const timer of row.time.sourceTimers){
   need(Number.isInteger(timer.minutes)&&timer.minutes>0&&typeof timer.phase==='string'&&timer.sourceStepIndices?.every(n=>stepIndices.includes(n)),'Timer phase evidence missing');
  }
  const {contentSha256,...content}=row;
  need(contentSha256===fingerprint(content),'Recipe content drift');
 }
 return {recipes:batch.recipes.length,ingredients:batch.recipes.reduce((n,r)=>n+r.ingredients.length+(r.supplementalIngredients?.length??0),0),steps:batch.recipes.reduce((n,r)=>n+r.steps.length,0)};
}
export async function actual(){
 const previous=['2026-10-first-batch.json','second-batch-20261014/recipes.json','third-batch-20261014/recipes.json'];
 const prior=[];
 for(const p of previous)prior.push(...JSON.parse(await readFile(resolve(root,'data/recipes/arabic-youtube',p),'utf8')).recipes.map(r=>r.recipeId));
 const batch=JSON.parse(await readFile(resolve(root,file),'utf8'));
 return {batch,summary:validate(batch,prior),prior};
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url))console.log(JSON.stringify((await actual()).summary));
