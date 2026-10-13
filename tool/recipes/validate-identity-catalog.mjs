import {readFile,access} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {validateIdentityBank} from './validate-identity-bank.mjs';
import {loadUsdaReviewSnapshots} from './usda-review-reader.mjs';
import {loadRecipeReviewSnapshots} from './recipe-review-reader.mjs';
const need=(ok,message)=>{if(!ok)throw new Error(message);};
const text=s=>typeof s==='string'&&s.trim().length>0;
const keys=(v,expected)=>need(v&&typeof v==='object'&&!Array.isArray(v)&&Object.keys(v).length===expected.length&&expected.every(k=>Object.hasOwn(v,k)),'Unexpected catalog fields');
const hash=bytes=>createHash('sha256').update(bytes).digest('hex');
const parse=bytes=>JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/,''));
const defaultRead=file=>readFile(new URL(`../../data/recipes/identity-proposals/${file}`,import.meta.url));
const countFields=['proposalCount','recipeCount','foodCount','candidateCount','unresolvedCount'];

/** Validated research inventory only. Does not select foods or apply runtime bindings. */
export async function validateIdentityCatalog(catalog,{recipes,readBank=defaultRead,loadFoods=loadUsdaReviewSnapshots}={}){
 keys(catalog,['schemaVersion','status','banks','expected','limitations']);
 need(catalog.schemaVersion===1&&catalog.status==='identity-catalog-unreviewed','Invalid catalog status; no approval allowed');
 need(recipes instanceof Map,'Current recipe snapshots required');
 need(Array.isArray(catalog.banks)&&catalog.banks.length>0,'Catalog banks required');
 need(Array.isArray(catalog.limitations)&&catalog.limitations.length>0&&catalog.limitations.every(text),'Catalog limitations required');
 keys(catalog.expected,countFields);need(countFields.every(k=>Number.isSafeInteger(catalog.expected[k])&&catalog.expected[k]>=0),'Invalid catalog expected counts');
 const bankIds=new Set(),fileIds=new Set();
 for(const entry of catalog.banks){
  keys(entry,['id','file','sha256']);
  need(typeof entry.id==='string'&&/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(entry.id)&&entry.id!=='catalog'&&entry.file===`${entry.id}.json`,'Unsafe catalog bank identity/file');
  need(!bankIds.has(entry.id)&&!fileIds.has(entry.file),'Duplicate catalog bank identity/file');bankIds.add(entry.id);fileIds.add(entry.file);
  need(typeof entry.sha256==='string'&&/^[a-f0-9]{64}$/.test(entry.sha256),'Invalid catalog bank hash');
 }
 const banks=[],foodIds=new Set();
 for(const entry of catalog.banks){
  const bytes=await readBank(entry.file);need(Buffer.isBuffer(bytes),'Catalog bank reader must return raw bytes');
  need(hash(bytes)===entry.sha256,`Catalog bank hash mismatch: ${entry.file}`);
  const bank=parse(bytes);
  need(Array.isArray(bank.proposals),'Catalog bank proposals required');
  for(const proposal of bank.proposals){need(Array.isArray(proposal?.candidates),'Catalog bank candidates required');for(const candidate of proposal.candidates){need(text(candidate.foodId),'Invalid catalog food identity');foodIds.add(candidate.foodId);}}
  banks.push(bank);
 }
 // One authoritative food snapshot set for the entire catalog; shared references are never blended.
 const foods=foodIds.size?await loadFoods([...foodIds].sort()):{snapshots:new Map(),evidence:new Map()};
 const targets=new Set(),recipeIds=new Set();let proposalCount=0,candidateCount=0,unresolvedCount=0;
 for(const bank of banks){
  const result=await validateIdentityBank(bank,{recipes,loadFoods:async()=>foods});
  proposalCount+=result.proposalCount;candidateCount+=result.candidateCount;unresolvedCount+=result.unresolvedCount;
  for(const proposal of bank.proposals){
   const target=`${proposal.target.recipeId}:${proposal.target.lineIndex}`;
   need(!targets.has(target),'Duplicate review target across catalog banks');targets.add(target);recipeIds.add(proposal.target.recipeId);
  }
 }
 const summary={bankCount:banks.length,proposalCount,recipeCount:recipeIds.size,foodCount:foodIds.size,candidateCount,unresolvedCount,runtimeReadyCount:0};
 need(countFields.every(k=>catalog.expected[k]===summary[k]),'Catalog expected count mismatch; explicit registry update required');
 return summary;
}

if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 try{
  let collecting=false;try{await access(new URL('../../data/recipes/bulk/wikibooks-cookbook/collector.lock',import.meta.url));collecting=true;}catch(e){if(e.code!=='ENOENT')throw e;}
  need(!collecting,'English collector active; wait for current recipe source snapshot');
  const catalog=parse(await readFile(resolve(process.argv[2]??'data/recipes/identity-proposals/catalog.json')));
  const {recipes}=await loadRecipeReviewSnapshots();
  console.log(JSON.stringify(await validateIdentityCatalog(catalog,{recipes})));
 }catch(e){console.error(e.message);process.exitCode=1;}
}
