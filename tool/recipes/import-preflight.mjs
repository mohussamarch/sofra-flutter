import {readFile, access} from 'node:fs/promises';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {reviewTarget, snapshotFingerprint} from './review-target.mjs';
import {loadRecipeReviewSnapshots} from './recipe-review-reader.mjs';
import {loadUsdaReviewSnapshots} from './usda-review-reader.mjs';

const need=(ok,message)=>{if(!ok)throw new Error(message);};
const text=v=>typeof v==='string'&&v.trim().length>0;
const keys=(v,expected)=>need(v&&typeof v==='object'&&!Array.isArray(v)&&Object.keys(v).length===expected.length&&expected.every(k=>Object.hasOwn(v,k)),'Unexpected or missing draft fields');
const duration=v=>typeof v==='number'&&Number.isFinite(v)&&v>=0;
const stamp=v=>typeof v==='string'&&/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$/.test(v)&&Number.isFinite(Date.parse(v))&&new Date(v).toISOString().slice(0,19)===v.slice(0,19);
const topKeys=['schemaVersion','recipeSha256','note','reviewedAt','servings','prepMinutes','cookMinutes','stepMinutes','lines'];
const lineKeys=['target','resolution','disposition','note','components'];
const componentKeys=['name','amount','unit','form','optional','scales','food'];
const foodKeys=['foodId','foodVersion','foodSnapshotSha256'];
export const remainingRuntimeGates=Object.freeze([
  'runtime-adapter-and-required-catalog-metadata',
  'per-page-license-attribution-and-instruction-review',
  'runtime-food-form-basis-and-measurement-binding',
  'retention-and-nutrition-review',
]);

function source(recipe){
  need(Array.isArray(recipe?.recipe?.ingredients)&&recipe.recipe.ingredients.length>0,'Source ingredients required');
  need(Array.isArray(recipe.recipe.steps)&&recipe.recipe.steps.length>0,'Source steps required');
  for(const [i,s] of recipe.recipe.steps.entries())need(s&&s.n===i+1&&text(s.text),'Source steps required in order');
  for(const [i] of recipe.recipe.ingredients.entries())reviewTarget(recipe,i);
}

/** A blank review template, never a guessed conversion of source quantities or timing. */
export function emptyImportDraft(recipe){
  source(recipe);
  return {schemaVersion:1,recipeSha256:snapshotFingerprint(recipe),note:null,reviewedAt:null,
    servings:null,prepMinutes:null,cookMinutes:null,stepMinutes:recipe.recipe.steps.map(()=>null),
    lines:recipe.recipe.ingredients.map((_,i)=>({target:reviewTarget(recipe,i),resolution:null,disposition:null,note:null,components:null}))};
}

/** Offline draft audit only. Current authoritative source/food snapshots are caller requirements.
 * A complete draft is still NOT a runtime recipe, nutrition binding, retention or medical approval.
 */
export function auditRecipeImportDraft(recipe,draft,{foods=new Map()}={}){
  source(recipe);keys(draft,topKeys);
  need(draft.schemaVersion===1,'Unsupported draft schema');
  need(draft.recipeSha256===snapshotFingerprint(recipe),'Stale full recipe review snapshot');
  need(foods instanceof Map,'Current food snapshot map required');
  need(Array.isArray(draft.lines)&&draft.lines.length===recipe.recipe.ingredients.length,'Exactly one draft decision per source line required');
  need(Array.isArray(draft.stepMinutes)&&draft.stepMinutes.length===recipe.recipe.steps.length,'Exactly one duration per source step required');
  const issues=[],lines=[];
  const issue=(code,lineIndex=null,componentIndex=null)=>issues.push({code,lineIndex,componentIndex});
  if(!text(draft.note)||!stamp(draft.reviewedAt))issue('review-evidence');
  if(!Number.isSafeInteger(draft.servings)||draft.servings<1)issue('servings');
  if(!duration(draft.prepMinutes))issue('prep-time');
  if(!duration(draft.cookMinutes))issue('cook-time');
  for(const [i,v] of draft.stepMinutes.entries())if(!duration(v))issues.push({code:'step-time',stepIndex:i});
  let includedComponents=0;
  for(const [i,line] of draft.lines.entries()){
    keys(line,lineKeys);
    need(snapshotFingerprint(line.target)===snapshotFingerprint(reviewTarget(recipe,i)),'Stale, duplicate or reordered source line target');
    const start=issues.length;
    if(!text(line.note))issue('line-review-evidence',i);
    const resolution=['single','choice','split'].includes(line.resolution);
    const disposition=['required','included-optional','excluded-optional'].includes(line.disposition);
    if(!resolution)issue('resolution',i);
    if(!disposition)issue('disposition',i);
    const excluded=line.disposition==='excluded-optional';
    const components=line.components;
    if(!excluded&&Array.isArray(components))includedComponents+=components.length;
    if(!Array.isArray(components)|| (excluded?components.length!==0:
      line.resolution==='split'?components.length<2:components.length!==1))issue('components',i);
    if(Array.isArray(components))for(const [j,c] of components.entries()){
      keys(c,componentKeys);
      if(!text(c.name))issue('name',i,j);
      if(typeof c.amount!=='number'||!Number.isFinite(c.amount)||c.amount<=0)issue('quantity',i,j);
      if(!text(c.unit))issue('unit',i,j);
      if(!text(c.form))issue('form',i,j);
      if(typeof c.optional!=='boolean'||c.optional!==(line.disposition==='included-optional'))issue('optional',i,j);
      if(typeof c.scales!=='boolean')issue('scaling',i,j);
      if(c.food===null)issue('food-reference',i,j);
      else{
        keys(c.food,foodKeys);const ref=c.food,current=foods.get(ref.foodId);
        if(!text(ref.foodId)||!text(ref.foodVersion)||!current||current.id!==ref.foodId||current.version!==ref.foodVersion||snapshotFingerprint(current)!==ref.foodSnapshotSha256)issue('food-reference',i,j);
      }
    }
    lines.push({lineIndex:i,lineId:line.target.lineId,complete:issues.length===start,issueCount:issues.length-start});
  }
  if(includedComponents===0)issue('recipe-components');
  return {schemaVersion:1,recipeId:recipe.id,recipeSha256:draft.recipeSha256,draftComplete:issues.length===0,
    runtimeReady:false,issues,lines,remainingRuntimeGates:[...remainingRuntimeGates]};
}

async function assertStopped(){
  try{await access(new URL('../../data/recipes/bulk/wikibooks-cookbook/collector.lock',import.meta.url));}
  catch(e){if(e.code==='ENOENT')return;throw e;}
  throw new Error('English collector active; wait for a stable source snapshot');
}

// CLI: node tool/recipes/import-preflight.mjs wikibooks:123 [review-draft.json]
// Reads and verifies archived English source plus only the explicitly referenced USDA snapshots.
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  try{
    need(process.argv.length>=3&&process.argv.length<=4,'Usage: import-preflight.mjs <recipe-id> [draft.json]');
    await assertStopped();const {recipes}=await loadRecipeReviewSnapshots();
    const recipe=recipes.get(process.argv[2]);need(recipe,'Unknown English source recipe ID');
    const draft=process.argv[3]?JSON.parse(await readFile(resolve(process.argv[3]),'utf8')):emptyImportDraft(recipe);
    // Verify all source anchors/shapes before loading any referenced food bank.
    auditRecipeImportDraft(recipe,draft);
    const ids=[...new Set(draft.lines.flatMap(l=>(l.components??[]).map(c=>c.food?.foodId).filter(Boolean)))];
    const foods=ids.length?(await loadUsdaReviewSnapshots(ids)).snapshots:new Map();
    await assertStopped();
    const report=auditRecipeImportDraft(recipe,draft,{foods});console.log(JSON.stringify(report,null,2));
    if(!report.draftComplete)process.exitCode=2;
  }catch(e){console.error(e.message);process.exitCode=1;}
}
