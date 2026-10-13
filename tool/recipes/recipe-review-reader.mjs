import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {buildBulkIndex} from './build-bulk-index.mjs';
import {parseRecipePage} from './collect-wikibooks.mjs';
import {snapshotFingerprint} from './review-target.mjs';
const need=(v,m)=>{if(!v)throw new Error(m);};
const hash=v=>createHash('sha256').update(v).digest('hex');
const parseLines=v=>v.toString('utf8').split(/\r?\n/).filter(Boolean).map(JSON.parse);
const defaultRead=path=>readFile(new URL(`../../data/recipes/bulk/wikibooks-cookbook/${path}`,import.meta.url));

/** Offline consistency against original local source; run only after collector/indexer exit. */
export async function loadRecipeReviewSnapshots({read=defaultRead}={}){
  const index=JSON.parse((await read('index.json')).toString('utf8'));
  need(index.records==='source-pages.jsonl'&&index.parsedRecipes==='parsed-recipes.jsonl','Unexpected recipe source paths');
  const source=await read('source-pages.jsonl'),parsed=await read('parsed-recipes.jsonl'),observations=await read('category-observations.jsonl');
  need(hash(source)===index.sourceFileSha256,'Recipe source file hash mismatch');
  need(hash(parsed)===index.parsedRecipesSha256,'Parsed recipe file hash mismatch');
  need((observations.length?hash(observations):null)===index.categoryObservationsSha256,'Category observation hash mismatch');
  const built=buildBulkIndex(parseLines(source),{categoryObservations:parseLines(observations),parseSource:parseRecipePage});
  const {parsedRecipes,...core}=built;
  for(const [key,value]of Object.entries(core))need(snapshotFingerprint(value)===snapshotFingerprint(index[key]),`Recipe index mismatch: ${key}`);
  const rows=parseLines(parsed);
  need(snapshotFingerprint(rows)===snapshotFingerprint(parsedRecipes),'Derived recipe extraction mismatch; rebuild/review required');
  const recipes=new Map(rows.map(r=>[r.id,r]));need(recipes.size===rows.length,'Duplicate parsed recipe identities');
  return {recipes,index,evidence:{sourceFileSha256:index.sourceFileSha256,parsedRecipesSha256:index.parsedRecipesSha256,categoryObservationsSha256:index.categoryObservationsSha256}};
}
