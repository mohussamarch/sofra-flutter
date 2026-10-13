import { createHash } from 'node:crypto';
const need=(ok,message)=>{if(!ok)throw new Error(message);};
const text=v=>typeof v==='string'&&v.trim().length>0;
const sha=v=>typeof v==='string'&&/^[a-f0-9]{64}$/.test(v);
function canonical(v){
  if(v===null||typeof v==='string'||typeof v==='boolean')return v;
  if(typeof v==='number'){need(Number.isFinite(v),'Nonfinite snapshot number');return v;}
  if(Array.isArray(v))return v.map(canonical);
  need(v&&typeof v==='object'&&[Object.prototype,null].includes(Object.getPrototypeOf(v)),'Snapshot must contain JSON values');
  return Object.fromEntries(Object.keys(v).sort().map(k=>[k,canonical(v[k])]));
}
export const snapshotFingerprint=v=>createHash('sha256').update(JSON.stringify(canonical(v))).digest('hex');
function exactKeys(v,keys){need(v&&typeof v==='object'&&!Array.isArray(v),'Invalid proposal object');need(Object.keys(v).length===keys.length&&keys.every(k=>Object.hasOwn(v,k)),'Unexpected or missing proposal fields');}

/** Source guard only. The caller supplies the current authoritative parsed recipe. */
export function reviewTarget(recipe,lineIndex){
  need(recipe&&Number.isInteger(lineIndex)&&lineIndex>=0&&Array.isArray(recipe.recipe?.ingredients)&&lineIndex<recipe.recipe.ingredients.length,'Invalid source line index');
  for(const k of ['id','recordId','sourceId','sourceRevision','parserVersion','quantityParserVersion'])need(text(recipe[k]),`Missing recipe ${k}`);
  need(sha(recipe.sourceSha256),'Invalid source SHA');
  const line=recipe.recipe.ingredients[lineIndex];need(text(line.id)&&text(line.sourceText),'Invalid source ingredient');
  return {schemaVersion:1,recipeId:recipe.id,recordId:recipe.recordId,sourceId:recipe.sourceId,
    sourceRevision:recipe.sourceRevision,sourceSha256:recipe.sourceSha256,parserVersion:recipe.parserVersion,
    quantityParserVersion:recipe.quantityParserVersion,lineIndex,lineId:line.id,sourceText:line.sourceText,
    derivedRecipeSha256:snapshotFingerprint(recipe)};
}

/** Validates research proposals; does not approve identity, select food, convert or calculate. */
export function validateIdentityProposal(proposal,recipe,foodSnapshots){
  exactKeys(proposal,['schemaVersion','status','target','candidates','issues']);
  need(proposal.schemaVersion===1&&proposal.status==='identity-proposal-unreviewed','Proposal cannot claim approval');
  need(proposal.target&&snapshotFingerprint(proposal.target)===snapshotFingerprint(reviewTarget(recipe,proposal.target.lineIndex)),'Stale recipe or line review target');
  need(foodSnapshots instanceof Map,'Current authoritative food snapshot map required');
  need(Array.isArray(proposal.candidates)&&Array.isArray(proposal.issues)&&proposal.issues.every(text),'Invalid proposal lists');
  need(proposal.candidates.length>0||proposal.issues.length>0,'Unresolved proposal requires issues');
  const seen=new Set();
  for(const c of proposal.candidates){
    exactKeys(c,['foodId','foodVersion','foodSnapshotSha256','rationale']);
    need(text(c.foodId)&&text(c.foodVersion)&&sha(c.foodSnapshotSha256)&&text(c.rationale)&&!seen.has(c.foodId),'Invalid or duplicate food candidate');
    seen.add(c.foodId);
    const current=foodSnapshots.get(c.foodId);
    need(current&&current.id===c.foodId&&current.version===c.foodVersion&&snapshotFingerprint(current)===c.foodSnapshotSha256,'Food snapshot missing or changed; re-review required');
  }
  return true;
}
