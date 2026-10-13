import {readFile,access} from 'node:fs/promises';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {snapshotFingerprint,validateIdentityProposal} from './review-target.mjs';
import {loadUsdaReviewSnapshots} from './usda-review-reader.mjs';
import {loadRecipeReviewSnapshots} from './recipe-review-reader.mjs';
const need=(ok,message)=>{if(!ok)throw new Error(message);};
const text=v=>typeof v==='string'&&v.trim().length>0;
function keys(v,expected){need(v&&typeof v==='object'&&!Array.isArray(v)&&Object.keys(v).length===expected.length&&expected.every(k=>Object.hasOwn(v,k)),'Invalid or unexpected bank fields');}
const same=(a,b)=>snapshotFingerprint(a)===snapshotFingerprint(b);

export async function validateIdentityBank(bank,{recipes,loadFoods=loadUsdaReviewSnapshots}={}){
  keys(bank,['schemaVersion','status','createdAt','recipeSources','foodEvidence','proposals','limitations']);
  need(bank.schemaVersion===1&&bank.status==='identity-proposals-unreviewed','Bank cannot claim approval');
  need(text(bank.createdAt)&&Number.isFinite(Date.parse(bank.createdAt)),'Invalid creation date');
  need(recipes instanceof Map&&Array.isArray(bank.proposals)&&bank.proposals.length>0,'Recipe snapshots/proposals required');
  need(Array.isArray(bank.recipeSources)&&Array.isArray(bank.foodEvidence)&&Array.isArray(bank.limitations)&&bank.limitations.length>0&&bank.limitations.every(text),'Provenance and limitations required');
  const recipeIds=new Set(),foodIds=new Set(),targets=new Set();
  for(const p of bank.proposals){
    need(p?.target&&recipes.has(p.target.recipeId)&&Array.isArray(p.candidates),'Missing current recipe or candidates');
    const key=`${p.target.recipeId}:${p.target.lineIndex}`;need(!targets.has(key),'Duplicate review target');targets.add(key);recipeIds.add(p.target.recipeId);
    for(const c of p.candidates){need(text(c.foodId),'Invalid food identity');foodIds.add(c.foodId);}
  }
  const loaded=foodIds.size?await loadFoods([...foodIds]):{snapshots:new Map(),evidence:new Map()};
  need(loaded.snapshots instanceof Map&&loaded.evidence instanceof Map,'Authoritative food reader required');
  const sourceIds=new Set(),evidenceIds=new Set();
  for(const s of bank.recipeSources){
    keys(s,['recipeId','recordId','sourceUrl','sourceSha256','license','changeNotice']);
    need(recipeIds.has(s.recipeId)&&!sourceIds.has(s.recipeId)&&text(s.changeNotice),'Missing/duplicate recipe attribution');sourceIds.add(s.recipeId);
    const r=recipes.get(s.recipeId);
    need(s.recordId===r.recordId&&s.sourceUrl===r.sourceUrl&&s.sourceSha256===r.sourceSha256&&same(s.license,r.license),'Recipe source or licence mismatch');
  }
  need(sourceIds.size===recipeIds.size,'Incomplete recipe provenance');
  for(const e of bank.foodEvidence){
    keys(e,['foodId','foodSnapshotSha256','sourceEvidence']);
    need(foodIds.has(e.foodId)&&!evidenceIds.has(e.foodId)&&loaded.snapshots.has(e.foodId)&&loaded.evidence.has(e.foodId),'Missing/duplicate food evidence');evidenceIds.add(e.foodId);
    need(e.foodSnapshotSha256===snapshotFingerprint(loaded.snapshots.get(e.foodId))&&same(e.sourceEvidence,loaded.evidence.get(e.foodId)),'Food provenance or snapshot mismatch');
  }
  need(evidenceIds.size===foodIds.size,'Incomplete food provenance');
  for(const p of bank.proposals)validateIdentityProposal(p,recipes.get(p.target.recipeId),loaded.snapshots);
  return {proposalCount:bank.proposals.length,recipeCount:recipeIds.size,foodCount:foodIds.size,candidateCount:bank.proposals.reduce((n,p)=>n+p.candidates.length,0),unresolvedCount:bank.proposals.filter(p=>p.candidates.length===0).length,runtimeReadyCount:0};
}

if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  try{
    const bank=JSON.parse(await readFile(resolve(process.argv[2]??'data/recipes/identity-proposals/first-review.json'),'utf8'));
    let collecting=false;try{await access(new URL('../../data/recipes/bulk/wikibooks-cookbook/collector.lock',import.meta.url));collecting=true;}catch(e){if(e.code!=='ENOENT')throw e;}need(!collecting,'Collector active; wait for source snapshot');
    const {recipes}=await loadRecipeReviewSnapshots();
    console.log(JSON.stringify(await validateIdentityBank(bank,{recipes})));
  }catch(e){console.error(e.message);process.exitCode=1;}
}
