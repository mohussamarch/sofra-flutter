import {readFile,access} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {snapshotFingerprint} from './review-target.mjs';
import {auditRecipeImportDraft} from './import-preflight.mjs';
import {loadRecipeReviewSnapshots} from './recipe-review-reader.mjs';
import {loadUsdaReviewSnapshots} from './usda-review-reader.mjs';
const need=(ok,message)=>{if(!ok)throw Error(message);};
const text=v=>typeof v==='string'&&v.trim().length>0;
const keys=(v,k)=>need(v&&typeof v==='object'&&!Array.isArray(v)&&Object.keys(v).length===k.length&&k.every(x=>Object.hasOwn(v,x)),'Unexpected or missing registry fields');
const hash=v=>createHash('sha256').update(v).digest('hex');
const slug=v=>typeof v==='string'&&/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(v);
const defaultRead=file=>readFile(new URL(`../../data/recipes/import-review/drafts/${file}`,import.meta.url));

/** Explicit registry of persisted draft bytes. No automatic discovery, approval or runtime write. */
export async function validateImportDraftRegistry(registry,{recipes,readDraft=defaultRead,loadFoods=loadUsdaReviewSnapshots}={}){
 keys(registry,['schemaVersion','status','entries','limitations']);
 need(registry.schemaVersion===1&&registry.status==='import-draft-registry-unreviewed','Registry cannot claim approval');
 need(recipes instanceof Map&&Array.isArray(registry.entries),'Current authoritative recipes and entries required');
 need(Array.isArray(registry.limitations)&&registry.limitations.length>0&&registry.limitations.every(text),'Registry limitations required');
 const ids=new Set(),files=new Set();
 // Validate every path and identity before the first file read.
 for(const entry of registry.entries){
  keys(entry,['id','file','sha256','source']);
  need(slug(entry.id)&&typeof entry.file==='string'&&entry.file.endsWith('.json')&&slug(entry.file.slice(0,-5)),'Unsafe registry identity or file');
  need(!ids.has(entry.id)&&!files.has(entry.file),'Duplicate registry identity or file');ids.add(entry.id);files.add(entry.file);
  need(typeof entry.sha256==='string'&&/^[a-f0-9]{64}$/.test(entry.sha256),'Invalid draft hash');
  keys(entry.source,['recipeId','recordId','sourceUrl','sourceSha256','license','changeNotice']);
  const s=entry.source,r=recipes.get(s.recipeId);
  need(r&&r.id===s.recipeId&&text(s.recordId)&&text(s.sourceUrl)&&text(s.changeNotice)&&s.license&&typeof s.license==='object','Missing current recipe attribution');
  need(s.recordId===r.recordId&&s.sourceUrl===r.sourceUrl&&s.sourceSha256===r.sourceSha256&&s.changeNotice===r.changeNotice&&snapshotFingerprint(s.license)===snapshotFingerprint(r.license),'Stale recipe attribution or licence');
 }
 const drafts=[],foodIds=new Set();
 for(const entry of registry.entries){
  const bytes=await readDraft(entry.file);need(Buffer.isBuffer(bytes),'Draft reader must return raw bytes');
  need(hash(bytes)===entry.sha256,'Registered draft hash mismatch; explicit re-registration/review required');
  const draft=JSON.parse(bytes.toString('utf8'));
  const recipe=recipes.get(entry.source.recipeId);
  auditRecipeImportDraft(recipe,draft); // All shape/source anchors before a food load.
  for(const line of draft.lines)for(const c of line.components??[])if(c.food)foodIds.add(c.food.foodId);
  drafts.push({entry,draft,recipe});
 }
 const foods=foodIds.size?await loadFoods([...foodIds].sort()):{snapshots:new Map(),evidence:new Map()};
 need(foods.snapshots instanceof Map&&foods.evidence instanceof Map&&[...foodIds].every(id=>foods.snapshots.has(id)&&foods.evidence.has(id)),'Incomplete authoritative food snapshots/evidence');
 const results=drafts.map(({entry,draft,recipe})=>{
  const report=auditRecipeImportDraft(recipe,draft,{foods:foods.snapshots});
  return {id:entry.id,file:entry.file,sha256:entry.sha256,recipeId:recipe.id,draftComplete:report.draftComplete,runtimeReady:false,lineCount:report.lines.length,issueCount:report.issues.length,issues:report.issues};
 });
 return {schemaVersion:1,status:registry.status,draftCount:results.length,completeDraftCount:results.filter(r=>r.draftComplete).length,
  runtimeReadyCount:0,foodReferenceCount:foodIds.size,foodEvidenceCount:foods.evidence.size,drafts:results};
}

async function stopped(){
 try{await access(new URL('../../data/recipes/bulk/wikibooks-cookbook/collector.lock',import.meta.url));}
 catch(e){if(e.code==='ENOENT')return;throw e;}
 throw Error('English collector active; wait for stable source snapshots');
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 try{
  need(process.argv.length<=3,'Usage: import-draft-registry.mjs [registry.json]');await stopped();
  const registry=JSON.parse(await readFile(resolve(process.argv[2]??'data/recipes/import-review/registry.json'),'utf8'));
  const {recipes}=await loadRecipeReviewSnapshots();
  const result=await validateImportDraftRegistry(registry,{recipes});await stopped();
  console.log(JSON.stringify(result,null,2));
 }catch(e){console.error(e.message);process.exitCode=1;}
}
