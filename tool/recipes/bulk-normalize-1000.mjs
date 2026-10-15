import {readFile, writeFile, mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {loadRecipeReviewSnapshots} from './recipe-review-reader.mjs';
import {reviewTarget, snapshotFingerprint} from './review-target.mjs';

const root=fileURLToPath(new URL('../../',import.meta.url));
export const folder='data/recipes/curated-local/bulk-1000-20261015';
export const packFile=`${folder}/normalized-recipes.json`;
export const baselineFile=`${folder}/baseline-manifest.json`;
export const baselineManifestSha256='85cb5e078705592ecafcdfb8b7440e17bc62a64dd477b08b6d0c818ce30aadde';
export const sha=v=>createHash('sha256').update(v).digest('hex');
const need=(ok,message)=>{if(!ok)throw Error(message);};
const fmt=v=>JSON.stringify(v)+'\n';
const norm=v=>v.normalize('NFKC').toLowerCase().replace(/\s+/gu,' ').trim();
const text=v=>typeof v==='string'&&v.trim().length>0;
const notice='Offline adapter of already parsed English source recipes into the native source-library schema. No translation, culinary review, new acquisition or runtime approval. Markup extraction is a modification; attribute Wikibooks contributors at each pinned revision, retain CC BY-SA 4.0 and share-alike. Per-page exceptions remain unreviewed.';

// Exact normalized source text, without names, so renamed copies also collide.
export function contentSignature(ingredients,steps){
 return snapshotFingerprint({ingredients:ingredients.map(norm),steps:steps.map(norm)});
}
function sourceContent(r){return contentSignature(r.recipe.ingredients.map(i=>i.sourceText),r.recipe.steps.map(s=>s.text));}
function selectedContent(r){
 return contentSignature((r.ingredients??[]).map(i=>i.sourceText??i.sourceQuantityText??i.name??i.labelAr??i.label??''),(r.steps??[]).map(s=>s.text??s.textAr??''));
}

/** Own registration never changes this adapter's selected-record baseline. */
export function selectedManifestBaseline(manifest){
 return {...manifest,packs:manifest.packs.filter(p=>p.file!==packFile)};
}

/** Later packs are allowed; every frozen baseline pin must remain unchanged. */
export function validateBaseline(current,baseline){
 const byFile=new Map(current.packs.map(p=>[p.file,p]));
 need(byFile.size===current.packs.length,'Duplicate current manifest pack');
 for(const p of baseline.packs)need(snapshotFingerprint(byFile.get(p.file)??null)===snapshotFingerprint(p),'Baseline manifest pin missing or changed: '+p.file);
 return baseline;
}

export async function loadInputs(){
 const read=file=>readFile(resolve(root,file));
 const loaded=await loadRecipeReviewSnapshots();
 const raw=await read('data/recipes/bulk/wikibooks-cookbook/source-pages.jsonl');
 need(sha(raw)===loaded.evidence.sourceFileSha256,'Archive changed after reader validation');
 const sources=new Map(raw.toString('utf8').split(/\r?\n/).filter(Boolean).map(JSON.parse).map(r=>[r.recordId,r]));
 const manifestRaw=await read('data/recipes/curated-local/flutter-manifest.json');
 const current=JSON.parse(manifestRaw);
 let baselineRaw;
 try{baselineRaw=await read(baselineFile);}catch(error){if(error.code!=='ENOENT')throw error;baselineRaw=Buffer.from(JSON.stringify(selectedManifestBaseline(current),null,2)+'\n');}
 need(sha(baselineRaw)===baselineManifestSha256,'Frozen baseline manifest drift');
 const manifest=validateBaseline(current,JSON.parse(baselineRaw)),previous=[];
 for(const p of manifest.packs){
  const bytes=await read(p.file);need(sha(bytes)===p.sha256,'Previous selected pack drift: '+p.file);
  previous.push(...JSON.parse(bytes).recipes);
 }
 return {...loaded,sources,previous,inputManifestSha256:sha(baselineRaw),baselineManifestRaw:baselineRaw.toString('utf8')};
}

export function buildBatch({recipes,index,evidence,sources,previous,inputManifestSha256,baselineManifestRaw},count=1000){
 need(Number.isSafeInteger(count)&&count>0,'Invalid batch size');
 const excludedPages=new Set(),excludedRecords=new Set(),excludedUrls=new Set(),signatures=new Set();
 for(const row of previous){
  const p=row.provenance??row;
  if(p.recordId)excludedRecords.add(p.recordId);
  if(p.sourceUrl)excludedUrls.add(p.sourceUrl);
  const match=/^curated-local:(\d+)$/.exec(row.id??'');
  if(match){excludedPages.add(`wikibooks:${match[1]}`);const original=recipes.get(`wikibooks:${match[1]}`);if(original)signatures.add(sourceContent(original));}
  signatures.add(selectedContent(row));
 }
 const entries=new Map(index.entries.map(e=>[e.id,e])),cuisineMap=new Map(index.cuisines.map(c=>[c.id,c]));
 const candidates=[],rejected={previousSource:0,exactContent:0,nonRecipeOrEmpty:0};
 for(const r of recipes.values()){
  if(excludedPages.has(r.id)||excludedRecords.has(r.recordId)||excludedUrls.has(r.sourceUrl)){rejected.previousSource++;continue;}
  // Policy/template demonstration pages are parseable but are not recipe records.
  if(/^(?:Policy|Template|Help|Contents|Table of contents|Recipes|Cuisine of\b|Cuisines\b|Ingredients\b)(?::|\/|$)/i.test(r.recipe.name)||
     !r.recipe.ingredients.length||!r.recipe.steps.length||!r.recipe.ingredients.every(i=>text(i.sourceText))||!r.recipe.steps.every(s=>text(s.text))){rejected.nonRecipeOrEmpty++;continue;}
  const source=sources.get(r.recordId),entry=entries.get(r.id);
  need(source&&entry&&source.sourceSha256===r.sourceSha256&&sha(source.sourceWikitext)===r.sourceSha256,'Source integrity mismatch: '+r.id);
  need(source.sourceRevision===r.sourceRevision&&source.sourceUrl===r.sourceUrl&&snapshotFingerprint(source.license)===snapshotFingerprint(r.license),'Source revision/license mismatch');
  candidates.push({r,source,entry,signature:sourceContent(r)});
 }
 candidates.sort((a,b)=>a.source.sourcePageId-b.source.sourcePageId);
 // One from each evidenced cuisine per round, then unclassified: broad source
 // coverage, including Asian categories, without guessing origin from a title.
 const buckets=[...cuisineMap.keys()].sort().map(tag=>candidates.filter(c=>c.entry.cuisineTags.includes(tag)));
 buckets.push(candidates.filter(c=>!c.entry.cuisineTags.length));
 const selected=[],seenPages=new Set(),seenRecords=new Set(),seenUrls=new Set();
 for(let round=0;selected.length<count;round++){
  let available=false;
  for(const bucket of buckets){
   const c=bucket[round];if(!c)continue;available=true;
   if(seenPages.has(c.r.id))continue;
   seenPages.add(c.r.id);
   if(seenRecords.has(c.r.recordId)||seenUrls.has(c.r.sourceUrl)||signatures.has(c.signature)){rejected.exactContent++;continue;}
   signatures.add(c.signature);seenRecords.add(c.r.recordId);seenUrls.add(c.r.sourceUrl);selected.push(c);
   if(selected.length===count)break;
  }
  if(!available)break;
 }
 need(selected.length===count,`Only ${selected.length} eligible records for requested ${count}; goal not lowered`);
 const files=new Map(),rows=[];
 for(const {r,source,entry,signature}of selected){
  const path=`${folder}/source-snapshots/${source.sourcePageId}.json`;
  const snapshot=fmt({schemaVersion:1,sourceRecord:source,parsedRecipe:r,authoritativeEvidence:evidence});files.set(path,snapshot);
  const cuisines=entry.cuisineTags.map(tag=>{
   const c=cuisineMap.get(tag);need(entry.sourceCategories.includes(c.sourceCategory),'Unanchored cuisine category');
   return {id:c.id,nameAr:c.labelAr,evidenceText:c.sourceCategory,sourceRecordId:r.recordId,reviewStatus:'source-supported-not-runtime-approved'};
  });
  const row={id:`curated-local:${source.sourcePageId}`,recordVersion:1,name:r.recipe.name,nameAr:null,sourceLanguage:'en',translationStatus:'not-translated',status:'needs-review',familyId:null,methodId:null,cuisines,
   yield:{amount:null,min:null,max:null,unit:null,sourceText:r.recipe.servingsSourceText??null},
   time:{declaredTotalMinutes:null,prepMinutes:null,cookMinutes:null,sourceText:null},
   ingredients:r.recipe.ingredients.map((i,n)=>({sourceLineIndex:n,name:i.sourceText,nameAr:null,sourceLanguage:'en',amount:null,unit:null,optional:null,included:null,sourceText:i.sourceText,target:reviewTarget(r,n),quantityCandidate:i.quantityCandidate,sourceStructure:i.sourceStructure,quantityPrecision:'unreviewed',scales:null,foodBinding:null})),
   supplementalIngredients:[],steps:r.recipe.steps.map((s,n)=>({n:n+1,text:s.text,textAr:null,sourceLanguage:'en',sourceStepIndices:[n],durationMinutes:null})),
   notes:['Source quantities remain candidates; optionality, grouping, alternatives, yield, time, identities and scaling need review. Source text can contain multiple method variants; these remain one source record.'],
   blockers:['Untranslated source extraction; culinary, quantity, page rights, ingredient and method review pending.'],
   provenance:{...Object.fromEntries(['sourceId','recordId','sourceRevision','sourceRevisionTimestamp','retrievedAt','sourceUrl','sourceSha256','license'].map(k=>[k,source[k]])),derivedRecipeSha256:snapshotFingerprint(r),sourceSnapshotFile:path,sourceSnapshotSha256:sha(snapshot),licenseSha256:snapshotFingerprint(source.license),changeNotice:notice},
   normalizedSourceContentSha256:signature,nutrition:null,runtimeReady:false,actuallyKitchenTested:false,
   gates:{culinarySourceTranscription:false,independentCulinaryApproval:false,perPageLicenseApproved:false,inventoryIdentityApproved:false,nutritionApproved:false}};
  row.contentSha256=snapshotFingerprint(row);rows.push(row);
 }
 const counts={recipes:rows.length,ingredientLines:rows.reduce((n,r)=>n+r.ingredients.length,0),steps:rows.reduce((n,r)=>n+r.steps.length,0),alreadyParsedRecords:rows.length,newAcquisitions:0,newNativeLibraryRecords:rows.length,fullySpecified:0,needsReview:rows.length,runtimeReady:0,translatedRecords:0,
  missingAmountLines:rows.reduce((n,r)=>n+r.ingredients.filter(i=>i.amount===null).length,0),missingUnitLines:rows.reduce((n,r)=>n+r.ingredients.filter(i=>i.unit===null).length,0),unknownYieldRecords:rows.length,unknownTimeRecords:rows.length};
 const cuisineCounts=Object.fromEntries([...cuisineMap.keys()].sort().map(id=>[id,rows.filter(r=>r.cuisines.some(c=>c.id===id)).length]).filter(([,n])=>n));
 const pack={schemaVersion:1,adapterVersion:'native-library-source-v1',sourceLanguage:'en',translationStatus:'not-translated',reviewStatus:'source-extracted-unreviewed',runtimeReady:false,changeNotice:notice,sourceEvidence:evidence,sourceCount:rows.length,counts,cuisineCounts,duplicateReview:{previousSelectedRecords:previous.length,inputManifestSha256,excluded:rejected,scope:'Exact source page/revision/permalink and normalized source ingredient+method content against all selected records and within batch. No semantic, translation or unique-dish claim.'},recipes:rows,relationships:[]};
 files.set(packFile,fmt(pack));
 const report={schemaVersion:1,packFile,packSha256:sha(files.get(packFile)),counts,cuisineCounts,untaggedRecords:rows.filter(r=>!r.cuisines.length).length,sourceSnapshotCount:rows.length,archiveParsedRecipes:recipes.size,eligibleCandidates:candidates.length,duplicateReview:pack.duplicateReview,integrityIsCulinaryApproval:false};
 files.set(`${folder}/conversion-report.json`,JSON.stringify(report,null,2)+'\n');
 if(baselineManifestRaw!==undefined){need(sha(baselineManifestRaw)===baselineManifestSha256,'Frozen baseline manifest drift');files.set(baselineFile,baselineManifestRaw);}
 return {pack,report,files};
}

export async function run({check=false}={}){
 const result=buildBatch(await loadInputs());
 if(!check)await mkdir(resolve(root,folder,'source-snapshots'),{recursive:true});
 for(const [file,content]of result.files){
  if(check)need(await readFile(resolve(root,file),'utf8')===content,'Converted output drift: '+file);
  else await writeFile(resolve(root,file),content,'utf8');
 }
 return result.report;
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url))console.log(JSON.stringify(await run({check:process.argv.includes('--check')})));
