import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {buildFrenchIndex} from './collect-wikibooks-fr.mjs';
import {sha,contentSignature,validateBaseline} from './bulk-normalize-1000.mjs';
import {snapshotFingerprint} from './review-target.mjs';

const root=fileURLToPath(new URL('../../',import.meta.url));
const archive='data/recipes/bulk/fr-wikibooks-cuisine';
export const folder='data/recipes/curated-local/bulk-4000-20261016';
export const packFile=`${folder}/normalized-recipes.json`;
export const baselineFile=`${folder}/baseline-manifest.json`;
export const baselineManifestSha256='0de3aacf29146b8ad61ec5598bc570c33bbb27ece5c676c675f1a25dfacb491f';
export const sourceArchiveSha256='e7b89f680f6f0fdd7f45dec11c71c9139ba65f4c070ea98dcda5a084f013b388';
export const parsedArchiveSha256='0f30edc119e83cbcf04a6616a5be1cc2441257a25ca73c2cfb768b982442b924';
const notice='Offline extraction of already archived French Wikibooks pages; no translation, culinary review, new acquisition or runtime approval. Attribute contributors at the pinned revision, retain CC BY-SA 4.0 and share-alike. Per-page exceptions remain unreviewed. Literal source template labels and parser-omitted list lines were restored from pinned wikitext; unsupported markup remains flagged for review.';
const need=(ok,message)=>{if(!ok)throw Error(message);};
const text=v=>typeof v==='string'&&v.trim().length>0;
const jsonl=raw=>raw.toString('utf8').split(/\r?\n/).filter(Boolean).map(JSON.parse);
const fmt=v=>JSON.stringify(v)+'\n';
const selectedContent=row=>contentSignature((row.ingredients??[]).map(i=>i.sourceText??i.sourceQuantityText??i.name??i.labelAr??i.label??''),(row.steps??[]).map(s=>s.text??s.textAr??''));
const sourceContent=row=>contentSignature(row.recipe.ingredients.map(i=>i.sourceText),row.recipe.steps.map(s=>s.text));
const cleanFrench=line=>line.trim().replace(/^\s*[*#;:]+\s*/,'').replace(/'''?/g,'')
 .replace(/\[\[([^\]|]+)\|([^\]]+)\]\]/g,'$2').replace(/\[\[([^\]]+)\]\]/g,'$1')
 .replace(/<[^>]*>/g,'').replace(/\{\{[^{}]*\}\}/g,'').replace(/&nbsp;/g,' ').trim();
const normalizedHeading=s=>cleanFrench(s).normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();

/** Revisit exactly the list lines the frozen French section parser inspected. */
export function extractFrenchSectionEvidence(wikitext){
 const source=wikitext.replace(/<!--[\s\S]*?-->/g,'').replace(/<nowiki\b[^>]*>[\s\S]*?<\/nowiki\s*>/gi,'').replace(/<nowiki\b[^>]*\/\s*>/gi,'');
 const ingredients=[],steps=[];let section=null,level=0,groups=[];
 for(const line of source.split(/\r?\n/)){
  const h=line.match(/^\s*(={2,6})\s*(.*?)\s*\1\s*$/);
  if(h){const l=h[1].length,title=normalizedHeading(h[2]);
   if(section&&l<=level){section=null;groups=[];}
   if(!section){if(/^ingredients(?:\s*\(.*\))?$/.test(title)){section='ingredients';level=l;}
    else if(['preparation','preparations','realisation','procedure','instructions','methode'].includes(title)){section='steps';level=l;}}
   else if(section==='ingredients'){groups=groups.filter(g=>g.level<l);groups.push({level:l,title:cleanFrench(h[2]),sourceHeading:line});}
   continue;
  }
  if(!section||!/^\s*[*#]+\s*/.test(line))continue;
  const evidence={rawLine:line,parserSourceText:cleanFrench(line),sourceGroupPath:groups.map(g=>({...g}))};
  if(section==='ingredients')ingredients.push(evidence);else steps.push(evidence);
 }
 return {ingredients,steps};
}
export const extractFrenchIngredientEvidence=wikitext=>extractFrenchSectionEvidence(wikitext).ingredients;

/** Only render literal source-supplied template parameters; preserve anything else verbatim. */
export function renderFrenchSourceLine(rawLine){
 let value=rawLine.trim().replace(/^\s*[*#;:]+\s*/,'').replace(/'''?/g,'')
  .replace(/\[\[([^\]|]+)\|([^\]]+)\]\]/g,'$2').replace(/\[\[([^\]]+)\]\]/g,'$1')
  .replace(/&nbsp;/g,' ');
 value=value.replace(/\{\{([^{}]*)\}\}/g,(whole,body)=>{
  const [rawName,...args]=body.split('|'),name=rawName.trim().toLowerCase();
  if(['i',"i'",'ingrédient','w','ustensile','techniquecuisine'].includes(name)){
   const labels=args.filter(a=>a.trim()&&!/^'=/.test(a.trim()));
   return labels.length?labels.at(-1).trim():whole;
  }
  if(name==='unité'&&args.length===2&&args.every(a=>a.trim()))return args.map(a=>a.trim()).join(' ');
  if(name==='rouge'&&args.length===1&&args[0].trim())return args[0].trim();
  return whole;
 });
 return {text:value.trim(),unresolvedMarkup:/\{\{/.test(value)};
}

export function recoverFrenchLines(recipe,source){
 const evidence=extractFrenchSectionEvidence(source.sourceWikitext),ingredients=[],steps=[];
 let parserIngredientIndex=0,parserStepIndex=0,omittedIngredientLines=0,ingredientTemplateLines=0,methodTemplateLines=0;
 for(const e of evidence.ingredients){
  const parsed=e.parserSourceText?recipe.recipe.ingredients[parserIngredientIndex++]:null;
  need(!parsed||parsed.sourceText===e.parserSourceText,'French ingredient evidence/parser mismatch: '+recipe.id);
  const display=renderFrenchSourceLine(e.rawLine);
  need(text(display.text),'Empty French recovered ingredient: '+recipe.id);
  if(!parsed)omittedIngredientLines++;
  if(/\{\{(?:i|i'|ingrédient)\|/i.test(e.rawLine))ingredientTemplateLines++;
  ingredients.push({...e,...display,parserLine:parsed,parserLineIndex:parsed?.lineIndex??null});
 }
 for(const e of evidence.steps){
  const parsed=e.parserSourceText?recipe.recipe.steps[parserStepIndex++]:null;
  need(!parsed||parsed.text===e.parserSourceText,'French method evidence/parser mismatch: '+recipe.id);
  need(parsed,'French method list line was omitted by parser: '+recipe.id);
  const display=renderFrenchSourceLine(e.rawLine);
  need(text(display.text),'Empty French recovered method: '+recipe.id);
  if(/\{\{(?:i|i'|ingrédient)\|/i.test(e.rawLine))methodTemplateLines++;
  steps.push({...e,...display,parserLine:parsed,parserLineIndex:parserStepIndex-1});
 }
 need(parserIngredientIndex===recipe.recipe.ingredients.length&&parserStepIndex===recipe.recipe.steps.length,'French list evidence count mismatch: '+recipe.id);
 return {ingredients,steps,omittedIngredientLines,ingredientTemplateLines,methodTemplateLines,
  unresolvedIngredientLines:ingredients.filter(i=>i.unresolvedMarkup).length,unresolvedMethodLines:steps.filter(s=>s.unresolvedMarkup).length};
}

export function selectedManifestBaseline(current,baseline){
 const frozen=new Set(baseline.packs.map(p=>p.file));
 return {...current,packs:current.packs.filter(p=>frozen.has(p.file))};
}

/** Validate the saved, pre-fourth-pack manifest and every archived source byte. */
export async function loadInputs(){
 const read=file=>readFile(resolve(root,file));
 const current=JSON.parse(await read('data/recipes/curated-local/flutter-manifest.json'));
 let baselineRaw;
 try{baselineRaw=await read(baselineFile);}catch(error){if(error.code!=='ENOENT')throw error;baselineRaw=Buffer.from(JSON.stringify(current,null,2)+'\n');}
 need(sha(baselineRaw)===baselineManifestSha256,'Fourth frozen 22-pack baseline drift');
 const baseline=validateBaseline(current,JSON.parse(baselineRaw));
 need(baseline.packs.length===22,'Fourth batch requires exactly 22 frozen prior packs');
 const previous=[];
 for(const p of baseline.packs){const bytes=await read(p.file);need(sha(bytes)===p.sha256,'Previous pack drift: '+p.file);previous.push(...JSON.parse(bytes).recipes);}
 need(previous.length===3530,'Fourth batch requires exactly 3530 previous source rows');
 const [sourceRaw,parsedRaw,indexRaw,manifestRaw]=await Promise.all(['source-pages.jsonl','parsed-recipes.jsonl','index.json','manifest.json'].map(f=>read(`${archive}/${f}`)));
 const index=JSON.parse(indexRaw),manifest=JSON.parse(manifestRaw);
 need(index.sourceId==='fr-wikibooks-cuisine-cc-by-sa'&&index.sourceLanguage==='fr'&&index.parserVersion==='fr-sections-v1','Unexpected French source index');
 need(sha(sourceRaw)===sourceArchiveSha256&&sha(parsedRaw)===parsedArchiveSha256&&index.sourceFileSha256===sourceArchiveSha256&&index.parsedFileSha256===parsedArchiveSha256,'Frozen French archive hash mismatch');
 need(manifest.sourceFileSha256===index.sourceFileSha256&&manifest.parsedFileSha256===index.parsedFileSha256,'French archive manifest mismatch');
 const sources=jsonl(sourceRaw),saved=jsonl(parsedRaw),rebuilt=buildFrenchIndex(sources);
 need(sources.length>0&&snapshotFingerprint(manifest.license)===snapshotFingerprint(sources[0].license),'French manifest licence mismatch');
 need(snapshotFingerprint(rebuilt.index)===snapshotFingerprint(Object.fromEntries(Object.entries(index).filter(([k])=>!['sourceFileSha256','parsedFileSha256'].includes(k)))),'French source index re-extraction mismatch');
 need(snapshotFingerprint(rebuilt.recipes)===snapshotFingerprint(saved),'French parsed extraction mismatch');
 const sourceMap=new Map(sources.map(s=>[s.recordId,s]));need(sourceMap.size===sources.length,'Duplicate French source records');
 const recipes=new Map(saved.map(r=>[r.id,r]));need(recipes.size===saved.length,'Duplicate French parsed identities');
 return {recipes,sources:sourceMap,index,manifest,previous,baselineManifestRaw:baselineRaw.toString('utf8')};
}

export function buildFourthBatch({recipes,sources,index,manifest,previous,baselineManifestRaw},count=1000){
 need(Number.isSafeInteger(count)&&count>0,'Invalid batch size');
 need(sha(baselineManifestRaw)===baselineManifestSha256,'Fourth frozen baseline drift');
 const previousRecords=new Set(),previousUrls=new Set(),signatures=new Set();
 for(const row of previous){const p=row.provenance??row;if(p.recordId)previousRecords.add(p.recordId);if(p.sourceUrl)previousUrls.add(p.sourceUrl);signatures.add(row.normalizedSourceContentSha256??selectedContent(row));}
 const rejected={previousSource:0,previousContent:0,withinArchiveExactContent:0,emptyIngredientOrMethod:0};
 const eligible=[],seen=new Set(),seenParser=new Set();
 for(const r of [...recipes.values()].sort((a,b)=>a.sourcePageId-b.sourcePageId)){
  if(previousRecords.has(r.recordId)||previousUrls.has(r.sourceUrl)){rejected.previousSource++;continue;}
  const ingredients=r.recipe?.ingredients,steps=r.recipe?.steps;
  if(!Array.isArray(ingredients)||!Array.isArray(steps)||!ingredients.length||!steps.length||!ingredients.every(i=>text(i.sourceText))||!steps.every(s=>text(s.text))){rejected.emptyIngredientOrMethod++;continue;}
  const source=sources.get(r.recordId);
  need(source&&source.sourceId===r.sourceId&&source.sourceRevision===r.sourceRevision&&source.sourceUrl===r.sourceUrl&&source.sourceSha256===r.sourceSha256&&sha(source.sourceWikitext)===r.sourceSha256,'French source integrity mismatch: '+r.id);
  need(snapshotFingerprint(source.license)===snapshotFingerprint(r.license),'French licence mismatch: '+r.id);
  const recovered=recoverFrenchLines(r,source),parserSignature=sourceContent(r);
  const signature=contentSignature(recovered.ingredients.map(i=>i.text),recovered.steps.map(s=>s.text));
  if(signatures.has(signature)||signatures.has(parserSignature)){rejected.previousContent++;continue;}
  if(seen.has(signature)||seenParser.has(parserSignature)){rejected.withinArchiveExactContent++;continue;}
  seen.add(signature);seenParser.add(parserSignature);eligible.push({r,source,signature,parserSignature,recovered});
 }
 need(eligible.length>=count,`Only ${eligible.length} eligible French source records for requested ${count}; goal not lowered`);
 const files=new Map(),rows=[];
 const evidence={sourceId:index.sourceId,sourceLanguage:index.sourceLanguage,parserVersion:index.parserVersion,sourceLineRecoveryVersion:'literal-source-template-v1',sourceFileSha256:index.sourceFileSha256,parsedFileSha256:index.parsedFileSha256,sourceManifestLicense:manifest.license};
 for(const {r,source,signature,parserSignature,recovered} of eligible.slice(0,count)){
  const path=`${folder}/source-snapshots/${source.sourcePageId}.json`;
  const snapshot=fmt({schemaVersion:1,sourceRecord:source,parsedRecipe:r,authoritativeEvidence:evidence});files.set(path,snapshot);
  const row={id:`curated-local:fr:${source.sourcePageId}`,recordVersion:1,name:r.recipe.name,nameAr:null,sourceLanguage:'fr',translationStatus:'not-translated',status:'needs-review',familyId:null,methodId:null,cuisines:[],
   yield:{amount:null,min:null,max:null,unit:null,sourceText:null},time:{declaredTotalMinutes:null,prepMinutes:null,cookMinutes:null,sourceText:null},
   ingredients:recovered.ingredients.map((i,n)=>({sourceLineIndex:n,sourceParserLineIndex:i.parserLineIndex,name:i.text,nameAr:null,sourceLanguage:'fr',amount:null,unit:null,optional:null,included:null,sourceText:i.text,parserSourceText:i.parserSourceText||null,rawSourceLine:i.rawLine,sourceQuantityText:i.parserLine?.amountText??null,sourceLine:i.parserLine,sourceMarkupReviewRequired:i.unresolvedMarkup,quantityCandidate:null,sourceStructure:{sourceGroupPath:i.sourceGroupPath},quantityPrecision:'unreviewed',scales:null,foodBinding:null})),supplementalIngredients:[],
   steps:recovered.steps.map((s,n)=>({n:n+1,text:s.text,textAr:null,sourceLanguage:'fr',sourceStepIndices:[n],parserSourceText:s.parserSourceText,rawSourceLine:s.rawLine,sourceStep:s.parserLine,sourceMarkupReviewRequired:s.unresolvedMarkup,durationMinutes:null})),
   sourceTextRecovery:{version:'literal-source-template-v1',ingredientReferenceTemplateLines:recovered.ingredientTemplateLines,methodReferenceTemplateLines:recovered.methodTemplateLines,parserOmittedIngredientLines:recovered.omittedIngredientLines,unresolvedIngredientLines:recovered.unresolvedIngredientLines,unresolvedMethodLines:recovered.unresolvedMethodLines,sourceTextWithoutUnresolvedMarkup:recovered.unresolvedIngredientLines===0&&recovered.unresolvedMethodLines===0},
   notes:['Original wikitext, original parser output and literal source-line recovery are pinned. Unsupported source markup is retained verbatim and flagged; check every ingredient and method before cooking or quantity review.'],
   blockers:['Untranslated source extraction; culinary, quantity, per-page rights, ingredient and method review pending.'],
   provenance:{...Object.fromEntries(['sourceId','recordId','sourceRevision','sourceRevisionTimestamp','retrievedAt','sourceUrl','sourceSha256','license'].map(k=>[k,source[k]])),derivedRecipeSha256:snapshotFingerprint(r),sourceSnapshotFile:path,sourceSnapshotSha256:sha(snapshot),licenseSha256:snapshotFingerprint(source.license),changeNotice:notice},
   normalizedSourceContentSha256:signature,normalizedParserContentSha256:parserSignature,nutrition:null,runtimeReady:false,actuallyKitchenTested:false,
   gates:{culinarySourceTranscription:false,independentCulinaryApproval:false,perPageLicenseApproved:false,inventoryIdentityApproved:false,nutritionApproved:false}};
  row.contentSha256=snapshotFingerprint(row);rows.push(row);
 }
 const counts={recipes:rows.length,ingredientLines:rows.reduce((n,r)=>n+r.ingredients.length,0),steps:rows.reduce((n,r)=>n+r.steps.length,0),alreadyParsedRecords:rows.length,newAcquisitions:0,newNativeLibraryRecords:rows.length,fullySpecified:0,needsReview:rows.length,runtimeReady:0,translatedRecords:0,missingAmountLines:rows.reduce((n,r)=>n+r.ingredients.length,0),missingUnitLines:rows.reduce((n,r)=>n+r.ingredients.length,0),unknownYieldRecords:rows.length,unknownTimeRecords:rows.length,
  ingredientReferenceTemplateRecords:rows.filter(r=>r.sourceTextRecovery.ingredientReferenceTemplateLines>0).length,parserOmittedIngredientRecords:rows.filter(r=>r.sourceTextRecovery.parserOmittedIngredientLines>0).length,parserOmittedIngredientLines:rows.reduce((n,r)=>n+r.sourceTextRecovery.parserOmittedIngredientLines,0),unresolvedSourceMarkupRecords:rows.filter(r=>!r.sourceTextRecovery.sourceTextWithoutUnresolvedMarkup).length,sourceTextWithoutUnresolvedMarkupRecords:rows.filter(r=>r.sourceTextRecovery.sourceTextWithoutUnresolvedMarkup).length};
 const pack={schemaVersion:1,adapterVersion:'native-library-source-v1',sourceLanguage:'fr',translationStatus:'not-translated',reviewStatus:'source-extracted-unreviewed',runtimeReady:false,changeNotice:notice,sourceEvidence:evidence,sourceCount:rows.length,counts,cuisineCounts:{},duplicateReview:{previousSelectedRecords:previous.length,inputManifestSha256:baselineManifestSha256,excluded:rejected,scope:'Exact source record/revision URL and normalized recovered plus archived-parser ingredient+method content against all 22 previous packs and within this French archive. No semantic or cross-language dish uniqueness claim.'},recipes:rows,relationships:[]};
 files.set(packFile,fmt(pack));
 const report={schemaVersion:1,packFile,packSha256:sha(files.get(packFile)),counts,cuisineCounts:{},untaggedRecords:rows.length,sourceSnapshotCount:rows.length,archiveParsedRecipes:recipes.size,eligibleCandidates:eligible.length,duplicateReview:pack.duplicateReview,integrityIsCulinaryApproval:false};
 files.set(`${folder}/conversion-report.json`,JSON.stringify(report,null,2)+'\n');files.set(baselineFile,baselineManifestRaw);
 return {pack,report,files};
}

export async function run({check=false}={}){
 const result=buildFourthBatch(await loadInputs());
 if(!check)await mkdir(resolve(root,folder,'source-snapshots'),{recursive:true});
 for(const [file,content] of result.files){
  if(check)need(await readFile(resolve(root,file),'utf8')===content,'Fourth converted output drift: '+file);
  else await writeFile(resolve(root,file),content,'utf8');
 }
 return result.report;
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url))console.log(JSON.stringify(await run({check:process.argv.includes('--check')})));
