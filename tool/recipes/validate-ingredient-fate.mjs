import {readFile,access} from 'node:fs/promises';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {reviewTarget,snapshotFingerprint} from './review-target.mjs';
import {loadRecipeReviewSnapshots} from './recipe-review-reader.mjs';
const need=(ok,message)=>{if(!ok)throw new Error(message);};
const text=v=>typeof v==='string'&&v.trim().length>0;
const same=(a,b)=>snapshotFingerprint(a)===snapshotFingerprint(b);
function keys(v,expected){need(v&&typeof v==='object'&&!Array.isArray(v)&&Object.keys(v).length===expected.length&&expected.every(k=>Object.hasOwn(v,k)),'Unexpected or missing fate fields');}

/** Research source anchors only. Never chooses food, converts quantities or approves retention. */
export function validateIngredientFateBank(bank,{recipes}={}){
 keys(bank,['schemaVersion','status','createdAt','recipeSources','observations','limitations']);
 need(bank.schemaVersion===1&&bank.status==='ingredient-fate-research-unreviewed','Fate bank cannot claim approval');
 need(text(bank.createdAt)&&Number.isFinite(Date.parse(bank.createdAt)),'Invalid fate date');
 need(recipes instanceof Map,'Current authoritative recipes required');
 need(Array.isArray(bank.observations)&&bank.observations.length>0&&Array.isArray(bank.recipeSources),'Fate observations/provenance required');
 need(Array.isArray(bank.limitations)&&bank.limitations.length>0&&bank.limitations.every(text),'Fate limitations required');
 const recipeIds=new Set(),targets=new Set();let stepReferenceCount=0;
 for(const o of bank.observations){
  keys(o,['schemaVersion','status','target','methodSteps','interpretation','retainedIngredientFraction','nutrientRetention','requiresReview']);
  need(o.schemaVersion===1&&o.status==='ingredient-fate-unreviewed'&&o.requiresReview===true,'Fate observation cannot claim approval');
  need(o.retainedIngredientFraction===null&&o.nutrientRetention===null,'Retained amounts/nutrients must remain unknown');
  need(text(o.interpretation)&&o.target&&recipes.has(o.target.recipeId),'Current recipe and interpretation required');
  const r=recipes.get(o.target.recipeId);
  need(same(o.target,reviewTarget(r,o.target.lineIndex)),'Stale ingredient fate target');
  const key=JSON.stringify([o.target.recipeId,o.target.lineIndex]);need(!targets.has(key),'Duplicate fate target');targets.add(key);recipeIds.add(r.id);
  need(Array.isArray(r.recipe.steps)&&Array.isArray(o.methodSteps)&&o.methodSteps.length>0,'Method evidence required');
  let previous=-1;
  for(const s of o.methodSteps){
   keys(s,['stepIndex','stepNumber','text']);
   need(Number.isInteger(s.stepIndex)&&s.stepIndex>previous&&s.stepIndex<r.recipe.steps.length,'Invalid/duplicate/unordered method index');previous=s.stepIndex;
   const current=r.recipe.steps[s.stepIndex];
   need(Number.isInteger(s.stepNumber)&&s.stepNumber>0&&s.stepNumber===current.n&&text(s.text)&&s.text===current.text,'Changed method source text/number');
   stepReferenceCount++;
  }
 }
 const attributed=new Set();
 for(const s of bank.recipeSources){
  keys(s,['recipeId','recordId','sourceUrl','sourceSha256','license','changeNotice']);
  need(recipeIds.has(s.recipeId)&&!attributed.has(s.recipeId)&&text(s.changeNotice),'Invalid/duplicate fate attribution');attributed.add(s.recipeId);
  const r=recipes.get(s.recipeId);
  need(s.recordId===r.recordId&&s.sourceUrl===r.sourceUrl&&s.sourceSha256===r.sourceSha256&&same(s.license,r.license),'Fate source/licence mismatch');
 }
 need(attributed.size===recipeIds.size,'Incomplete fate provenance');
 return {observationCount:bank.observations.length,recipeCount:recipeIds.size,stepReferenceCount,unknownRetentionCount:bank.observations.length,runtimeReadyCount:0};
}

if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 try{
  let collecting=false;try{await access(new URL('../../data/recipes/bulk/wikibooks-cookbook/collector.lock',import.meta.url));collecting=true;}catch(e){if(e.code!=='ENOENT')throw e;}
  need(!collecting,'Collector active; wait for source snapshot');
  const file=process.argv[2]?resolve(process.argv[2]):fileURLToPath(new URL('../../data/recipes/ingredient-fate/soaking-review.json',import.meta.url));
  const bank=JSON.parse(await readFile(file,'utf8'));
  const {recipes}=await loadRecipeReviewSnapshots();
  console.log(JSON.stringify(validateIngredientFateBank(bank,{recipes})));
 }catch(e){console.error(e.message);process.exitCode=1;}
}
