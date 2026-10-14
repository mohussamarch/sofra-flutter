import {createHash} from 'node:crypto';
import {auditRecipeImportDraft} from './import-preflight.mjs';
import {snapshotFingerprint} from './review-target.mjs';
const need=(ok,message)=>{if(!ok)throw Error(message);};
const text=v=>typeof v==='string'&&v.trim().length>0;
const keys=(v,k)=>need(v&&typeof v==='object'&&!Array.isArray(v)&&Object.keys(v).length===k.length&&k.every(x=>Object.hasOwn(v,x)),'Unexpected or missing adapter fields');
const clone=v=>JSON.parse(JSON.stringify(v));
const stamp=v=>typeof v==='string'&&/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$/.test(v)&&Number.isFinite(Date.parse(v))&&new Date(v).toISOString().slice(0,19)===v.slice(0,19);

/** Structural candidate only. Caller snapshots must be authoritative; no persistence or food binding. */
export function buildRuntimeRecipeCandidate(source,draft,metadata,{foods=new Map()}={}){
 const audit=auditRecipeImportDraft(source,draft,{foods});
 need(audit.draftComplete,'Incomplete source draft; resolve explicit review decisions first');
 keys(metadata,['schemaVersion','draftSha256','id','name','cuisine','category','description','difficulty','tags','notes','ingredientIds','steps','reviewNote','reviewedAt','acknowledgeSourceAndInstructions','acknowledgeRemainingNutritionGates']);
 need(metadata.schemaVersion===1&&metadata.draftSha256===snapshotFingerprint(draft),'Stale or unsupported adapter draft review');
 need(typeof metadata.id==='string'&&/^import:[a-z0-9]+(?:-[a-z0-9]+)*$/.test(metadata.id),'Explicit import namespaced recipe identity required');
 for(const field of ['name','cuisine','category','description','difficulty','reviewNote'])need(text(metadata[field]),`Explicit ${field} required`);
 for(const field of ['name','cuisine','category','description','difficulty'])need(metadata[field]===metadata[field].trim(),`Catalog ${field} must be normalized`);
 need(stamp(metadata.reviewedAt)&&metadata.acknowledgeSourceAndInstructions===true&&metadata.acknowledgeRemainingNutritionGates===true,'Explicit source/instruction and remaining nutrition review acknowledgement required');
 need(Array.isArray(metadata.tags),'Explicit tags required');
 for(const tag of metadata.tags)need(text(tag),'Invalid tag');
 need(metadata.notes===null||text(metadata.notes),'Notes must be explicit text or null');
 need(Array.isArray(metadata.steps)&&metadata.steps.length===source.recipe.steps.length,'Exactly one reviewed instruction per source step required');
 need(Array.isArray(metadata.ingredientIds)&&metadata.ingredientIds.length===draft.lines.length,'Explicit runtime ingredient IDs per source line required');
 need(text(source.sourceUrl)&&source.license&&typeof source.license==='object'&&!Array.isArray(source.license)&&Object.keys(source.license).length>0&&text(source.changeNotice),'Source attribution/licence/change notice required');
 const ingredients=[],lines=[];
 for(const [i,line] of draft.lines.entries()){
  const ids=metadata.ingredientIds[i];need(Array.isArray(ids)&&ids.length===line.components.length,'Runtime ingredient IDs must cover only included components');
  const runtimeLineIndices=[];
  for(const [j,c] of line.components.entries()){
   need(text(ids[j])&&ids[j]===ids[j].trim(),'Explicit normalized runtime ingredient identity required');
   need(c.name===c.name.trim(),'Catalog ingredient name must be normalized');
   runtimeLineIndices.push(ingredients.length);
   ingredients.push({id:ids[j],name:c.name,amount:c.amount,unit:c.unit,scale:c.scales,optional:c.optional,label:null,display:null,note:c.form});
  }
  lines.push({target:clone(line.target),resolution:line.resolution,disposition:line.disposition,note:line.note,runtimeLineIndices,
   components:line.components.map((c,j)=>({runtimeIngredientId:ids[j],form:c.form,rawFoodReference:clone(c.food)}))});
 }
 const steps=[];
 for(const [i,step] of metadata.steps.entries()){
  keys(step,['text','passive','tip']);need(text(step.text)&&typeof step.passive==='boolean'&&(step.tip===null||text(step.tip)),'Explicit instruction/passive/tip decisions required');
  need(step.text===step.text.trim(),'Catalog instruction text must be normalized');
  steps.push({n:i+1,text:step.text,duration:draft.stepMinutes[i],passive:step.passive,tip:step.tip});
 }
 const totalTime=draft.prepMinutes+draft.cookMinutes;need(Number.isFinite(totalTime),'Total time overflow');
 const recipe={id:metadata.id,name:metadata.name,cuisine:metadata.cuisine,category:metadata.category,description:metadata.description,difficulty:metadata.difficulty,
  servings:draft.servings,prepTime:draft.prepMinutes,cookTime:draft.cookMinutes,totalTime,ingredients,steps,tags:[...metadata.tags],notes:metadata.notes};
 return {schemaVersion:1,status:'runtime-recipe-candidate-unapproved',runtimeReady:false,recipe,
  provenance:{source:{recipeId:source.id,recordId:source.recordId,sourceId:source.sourceId,sourceRevision:source.sourceRevision,sourceSha256:source.sourceSha256,sourceUrl:source.sourceUrl,license:clone(source.license),sourceChangeNotice:source.changeNotice},
   sourceRecipeSha256:snapshotFingerprint(source),draftSha256:snapshotFingerprint(draft),metadataSha256:snapshotFingerprint(metadata),recipeSha256:snapshotFingerprint(recipe),
   changeNotice:'Caller-reviewed structural adaptation; ingredient choices/splits/exclusions, labels and instructions may differ from the archived source. Nutrition is unreviewed.',
   sourceReview:{note:draft.note,reviewedAt:draft.reviewedAt},adapterReview:{note:metadata.reviewNote,reviewedAt:metadata.reviewedAt},lines},
  nutrition:{status:'unreviewed',runtimeBindings:[]},remainingGates:['runtime-persistence-and-provenance-validation','per-page-license-exception-review','runtime-food-form-basis-and-measurement-binding','retention-and-nutrition-review']};
}

/** Rebuild before accepting a transported/stored candidate; never trust embedded claims alone. */
export function validateRuntimeRecipeCandidate(candidate,source,draft,metadata,options={}){
 const expected=buildRuntimeRecipeCandidate(source,draft,metadata,options);
 need(snapshotFingerprint(candidate)===snapshotFingerprint(expected),'Runtime candidate differs from reviewed source/draft/metadata or remaining gates');
 return {recipeId:expected.recipe.id,candidateSha256:snapshotFingerprint(expected),runtimeReady:false,
  sourceRecipeSha256:expected.provenance.sourceRecipeSha256,draftSha256:expected.provenance.draftSha256,metadataSha256:expected.provenance.metadataSha256};
}

/** Exact UTF8 transport after authoritative rebuild; expected SHA must travel via a trusted registry. */
export function packRuntimeRecipeCandidate(candidate,source,draft,metadata,options={}){
 validateRuntimeRecipeCandidate(candidate,source,draft,metadata,options);
 const payload=JSON.stringify(candidate);
 return {schemaVersion:1,encoding:'utf8-json',payload,sha256:createHash('sha256').update(payload,'utf8').digest('hex')};
}
