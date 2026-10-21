import {readFile,writeFile,mkdir,readdir,unlink} from 'node:fs/promises';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {buildSpanishIndex} from './collect-wikibooks-es.mjs';
import {sha,contentSignature as libraryContentSignature,validateBaseline} from './bulk-normalize-1000.mjs';
import {snapshotFingerprint} from './review-target.mjs';

const root=fileURLToPath(new URL('../../',import.meta.url));
const targetCount=1000;
export const folder='data/recipes/curated-local/bulk-5000-20261021';
export const packFile=`${folder}/normalized-recipes.json`;
export const baselineFile=`${folder}/baseline-manifest.json`;
export const baselineManifestSha256='038a62a40cdd528855f5b0b97cbf0ee1e34aa78c0edb8019bd141a30a912435a';
export const spanishArchive='data/recipes/bulk/es-wikibooks-recipes';
export const germanArchive='data/recipes/source-discovery/de-wikibooks';
export const spanishSourceSha256='459fc5b1985bba90ce340c5e0cbb3f73ac68664fe6218b2cd8966a3fb0bb4842';
export const spanishParsedSha256='822b9613fda4cb9d0eac73fc83dd8f630220cad4d1ebd5150fdc35613dba485b';
export const germanSourceSha256='289fcde82d231300df6fc36eefe96bbc941d3fda3a086d468ff207957eb4e04a';
export const germanParsedSha256='6bbff318d7ba5af472cd7d129ffda7f68a8c1b844e6504821ff00137af1175ed';
const notice='Offline extraction of archived Spanish and German Wikibooks source revisions into the native library. Parser output is preserved with complete raw source snapshots; recognized source template parameters are rendered as literal text and unsupported markup remains flagged. No translation, cuisine inference, culinary/quantity/rights approval, nutrition calculation or runtime approval. Cite contributor, permalink, extraction/modification and retain CC BY-SA 4.0/share-alike; page exceptions remain unreviewed.';
const need=(ok,message)=>{if(!ok)throw Error(message);};
const text=v=>typeof v==='string'&&v.trim().length>0;
const jsonl=raw=>raw.toString('utf8').split(/\r?\n/).filter(Boolean).map(JSON.parse);
const fmt=v=>JSON.stringify(v)+'\n';
const norm=v=>String(v??'').normalize('NFKC').toLowerCase().replace(/\s+/gu,' ').trim();
const templateSchemas={
 ing:{min:1,max:2,field:n=>n-1}, coc:{min:1,max:2,field:n=>n-1}, ute:{min:1,max:1,field:0},
 ter:{min:2,max:2,field:0}, rec:{min:1,max:2,field:n=>n-1}, tbc:{min:1,max:2,field:n=>n-1},
 w:{min:1,max:2,field:n=>n-1},
};
const literalBareTemplates=new Set(['abierta','cerrada','sin tapa','mantequilla','queso azul','azúcar','remover']);
function renderLiteralTemplate(whole,body){
 const [rawName,...args]=body.split('|'),name=rawName.trim().toLowerCase(),schema=templateSchemas[name];
 if(!schema){return args.length===0&&literalBareTemplates.has(name)?rawName.trim():whole;}
 if(args.length<schema.min||args.length>schema.max)return whole;
 const field=typeof schema.field==='function'?schema.field(args.length):schema.field;
 const selected=args[field]?.trim();
 if(!selected||/[{}<>\[\]|]/u.test(selected))return whole;
 return selected;
}
function safeWikiLink(whole,body){
 const parts=body.split('|'),target=parts[0]?.trim()??'';
 if(/^(?:image|file|archivo):/iu.test(target)||parts.length>2||!target)return whole;
 const display=(parts.length===2?parts[1]:target).trim();
 return display&&!/[{}<>\[\]]/u.test(display)?display:whole;
}
export function visibleText(value){return String(value??'').replace(/<!--[\s\S]*?-->/gu,'').replace(/\{\{([^{}]*)\}\}/gu,(whole,body)=>renderLiteralTemplate(whole,body)).replace(/\[\[([^\]]*)\]\]/gu,(whole,body)=>safeWikiLink(whole,body)).replace(/'{2,5}/gu,'').replace(/[\t\u00a0 ]+/gu,' ').trim();}
const hasUnresolvedMarkup=value=>{
 const raw=String(value??'');let remainder=raw.replace(/<!--[\s\S]*?-->/gu,'');
 remainder=remainder.replace(/\{\{([^{}]*)\}\}/gu,(whole,body)=>renderLiteralTemplate(whole,body)===''+whole?whole:' ');
 remainder=remainder.replace(/\[\[([^\]]*)\]\]/gu,(whole,body)=>safeWikiLink(whole,body)===whole?whole:' ');
 return /\{\{|\}\}|\[\[|\]\]|<[^>]*>|\|\s*\d+\s*px\b|\|/iu.test(remainder)||/\b(?:help-agent|tooltip|thumbtime|thumb|class\s*=|style\s*=)\b/iu.test(raw);
};
const sourceContent=recipe=>contentSignature(recipe.ingredients.map(i=>i.sourceText),recipe.steps.map(s=>s.text));
const selectedContent=r=>contentSignature((r.ingredients??[]).map(i=>i.sourceText??i.sourceQuantityText??i.name??i.labelAr??i.label??''),(r.steps??[]).map(s=>s.text??s.textAr??''));

export function contentSignature(ingredients,steps){return libraryContentSignature(ingredients.map(norm),steps.map(norm));}
export function hasCompleteIngredientMethod(recipe){
 const ingredients=recipe?.ingredients,steps=recipe?.steps;
 return recipe?.rawIngredientCoverageReviewRequired!==true&&recipe?.rawMethodCoverageReviewRequired!==true&&Array.isArray(ingredients)&&ingredients.length>0&&Array.isArray(steps)&&steps.length>0&&ingredients.every(i=>text(visibleText(i?.sourceText))&&!hasUnresolvedMarkup(i?.sourceText))&&steps.every(s=>text(visibleText(typeof s==='string'?s:s?.text))&&!hasUnresolvedMarkup(typeof s==='string'?s:s?.text));
}
export function hasCompleteSourceRecord(item){return hasCompleteIngredientMethod({...item.source.recipe,rawIngredientCoverageReviewRequired:auditRawIngredientCoverage(item).rawIngredientCoverageReviewRequired,rawMethodCoverageReviewRequired:auditRawMethodCoverage(item).rawMethodCoverageReviewRequired});}
const hasCompleteCandidate=hasCompleteSourceRecord;

const headingPattern=/^(={2,6})\s*(.*?)\s*\1\s*$/u;
const ingredientHeading=s=>/^zutaten\b/iu.test(s.trim());
const methodHeading=s=>/^(?:zubereitung\b|zubereitungs(?:art|schritte|weise)\b|herstellung\b|anleitung\b|die\s+zubereitung\b|zubereiten\b)/iu.test(s.trim());
const listItem=/^\s*(?:\*+|#+\*+|#+|-|•)\s+(.+?)\s*$/u;
const ignoredMethodLine=line=>{const t=line.trim();return !t||/^<!--.*-->$/u.test(t)||/^\{\{\s*(?:Abschnittswechsel|TOC|DEFAULTSORT)\b/iu.test(t)||/^\[\[(?:Kategorie|Category|Datei|File):/iu.test(t)||/^<(?:gallery|ref|references)\b/iu.test(t)||/^\|/u.test(t);};
function headingsFor(lines){return lines.map((line,index)=>{const m=line.trim().match(headingPattern);return m?{index,level:m[1].length,title:m[2].trim()}:null;}).filter(Boolean);}
function sectionsFor(lines,headings,test){return headings.filter(h=>test(h.title)).map(heading=>{const end=headings.find(next=>next.index>heading.index&&next.level<=heading.level)?.index??lines.length;return {heading,lines:lines.slice(heading.index+1,end)};});}
function spanishRawIngredientCount(wikitext){
 const raw=String(wikitext).replace(/<!--[\s\S]*?-->/gu,'');
 const startMatch=/\{\{\s*Artes[ _]culinarias\/Datos[ _]de[ _]receta(?=\s*[|}])/iu.exec(raw);
 const itemLine=/^\s*[*#]+\s*\S/u;
 if(startMatch){
  const lines=raw.slice(startMatch.index).split(/\r?\n/u),start=lines.findIndex(line=>/^\s*\|\s*ingredientes\s*=/iu.test(line));
  if(start<0)return null;
  const end=lines.findIndex((line,index)=>index>start&&/^\s*\|\s*procedimiento\s*=/iu.test(line));
  if(end<0)return null;
  return lines.slice(start+1,end).filter(line=>itemLine.test(line)).length;
 }
 const lines=raw.split(/\r?\n/u),heads=headingsFor(lines),sections=sectionsFor(lines,heads,title=>/^ingredientes(?:\s*\(.*\))?$/iu.test(title.normalize('NFD').replace(/[\u0300-\u036f]/gu,'')));
 return sections.length?sections.reduce((n,section)=>n+section.lines.filter(line=>itemLine.test(line)).length,0):null;
}
function germanRawIngredientCount(wikitext){
 const lines=String(wikitext).split(/\r?\n/u),heads=headingsFor(lines),sections=sectionsFor(lines,heads,ingredientHeading),lineItem=/^\s*(?:\*+|#+\*+|#+|-|•)\s+(.+?)\s*$/u;
 return sections.length?sections.reduce((n,section)=>n+section.lines.filter(line=>{const match=line.match(lineItem);return Boolean(match?.[1].trim());}).length,0):null;
}
export function auditRawIngredientCoverage(item){
 const recipe=item.source.recipe,raw=item.language==='es'?item.snapshotSource?.sourceWikitext:item.snapshotSource?.sourceWikitext;
 const count=raw?(item.language==='es'?spanishRawIngredientCount(raw):germanRawIngredientCount(raw)):null;
 const allPresent=Array.isArray(recipe?.ingredients)&&recipe.ingredients.every(ingredient=>typeof ingredient.sourceText==='string'&&raw?.includes(ingredient.sourceText));
 return {rawIngredientListLineCount:count,parsedIngredientLineCount:recipe?.ingredients?.length??0,allParsedLinesFoundInRawSource:allPresent,rawIngredientCoverageReviewRequired:count===null||count!==(recipe?.ingredients?.length??0)||!allPresent};
}
function spanishRawMethodLines(wikitext){
 const raw=String(wikitext).replace(/<!--[\s\S]*?-->/gu,'');
 const startMatch=/\{\{\s*Artes[ _]culinarias\/Datos[ _]de[ _]receta(?=\s*[|}])/iu.exec(raw),itemLine=/^\s*[*#]+\s*(.+?)\s*$/u;
 if(startMatch){const lines=raw.slice(startMatch.index).split(/\r?\n/u),start=lines.findIndex(line=>/^\s*\|\s*procedimiento\s*=/iu.test(line));if(start<0)return null;const end=lines.findIndex((line,index)=>index>start&&(/^\s*\|\s*[^=\n]+\s*=/u.test(line)||/^\s*\}\}/u.test(line)));if(end<0)return null;const first=lines[start].replace(/^\s*\|\s*procedimiento\s*=\s*/iu,'');return [first,...lines.slice(start+1,end)].map(line=>{const match=line.match(itemLine);return match?match[1].trim():line.trim();}).filter(Boolean);}
 const lines=raw.split(/\r?\n/u),heads=headingsFor(lines),sections=sectionsFor(lines,heads,title=>['preparacion','preparaciones','elaboracion','procedimiento','instrucciones'].includes(title.normalize('NFD').replace(/[\u0300-\u036f]/gu,'').toLowerCase()));
 return sections.length?sections.flatMap(section=>section.lines.map(line=>{const match=line.match(itemLine);return match?match[1].trim():line.trim();}).filter(Boolean)):null;
}
function germanRawMethodLines(wikitext){
 const lines=String(wikitext).split(/\r?\n/u),heads=headingsFor(lines),sections=sectionsFor(lines,heads,methodHeading),itemLine=/^\s*(?:\*+|#+\*+|#+|-|•)\s+(.+?)\s*$/u;
 return sections.length?sections.flatMap(section=>section.lines.map(line=>{const match=line.match(itemLine);return match?.[1].trim()||line.trim();}).filter(Boolean)):null;
}
export function auditRawMethodCoverage(item){
 const recipe=item.source.recipe,raw=item.snapshotSource?.sourceWikitext,steps=recipe?.steps??[];
 const lines=raw?(item.language==='es'?spanishRawMethodLines(raw):germanRawMethodLines(raw)):null;
 const allParsedStepsFoundInRawSource=Array.isArray(steps)&&steps.every(step=>typeof step.text==='string'&&raw?.includes(step.text));
 const unmatchedRawMethodLineCount=lines===null?null:lines.filter(line=>!steps.some(step=>typeof step.text==='string'&&step.text.includes(line))).length;
 const repeatedRawMethodLines=lines===null?[]:[...new Set(lines.filter((line,index)=>lines.indexOf(line)!==index))];
 const unmatchedRepeatedRawMethodLineCount=repeatedRawMethodLines.reduce((count,line)=>count+Math.max(0,lines.filter(candidate=>candidate===line).length-steps.filter(step=>typeof step.text==='string'&&step.text.includes(line)).length),0);
 return {rawMethodSourceLineCount:lines?.length??null,parsedMethodStepCount:steps.length,allParsedStepsFoundInRawSource,unmatchedRawMethodLineCount,unmatchedRepeatedRawMethodLineCount,rawMethodCoverageReviewRequired:lines===null||!allParsedStepsFoundInRawSource||unmatchedRawMethodLineCount!==0||unmatchedRepeatedRawMethodLineCount!==0};
}
export function parseGermanSource(wikitext){
 const lines=String(wikitext).split(/\r?\n/u),headings=headingsFor(lines),ingredientSections=sectionsFor(lines,headings,ingredientHeading),methodSections=sectionsFor(lines,headings,methodHeading),ingredients=[],steps=[];
 for(const section of ingredientSections)for(const line of section.lines){const m=line.match(listItem);if(!m)continue;const sourceText=m[1].trim();if(!sourceText||sourceText.startsWith('{{'))continue;ingredients.push({lineIndex:ingredients.length,sourceHeading:section.heading.title,sourceText,amount:null,unit:null,foodBinding:null});}
 for(const section of methodSections){let paragraph=[];const flush=()=>{const value=paragraph.join('\n').trim();if(value)steps.push({n:steps.length+1,text:value,durationMinutes:null});paragraph=[];};for(const line of section.lines){if(ignoredMethodLine(line)){flush();continue;}const m=line.match(listItem);if(m){flush();const value=m[1].trim();if(value&&!value.startsWith('{{'))steps.push({n:steps.length+1,text:value,durationMinutes:null});}else if(/^\s*\{\{/u.test(line.trim())||/^\s*<\/? .+>\s*$/u.test(line.trim()))flush();else paragraph.push(line);}flush();}
 return {ingredients,steps};
}

function validateGermanCandidate(candidate,source){
 need(source&&candidate.id===source.id,'German source ID mismatch');
 need(candidate.sourceId==='de-wikibooks-research-cc-by-sa'&&candidate.sourceLanguage==='de'&&source.sourceLanguage==='de','Unexpected German source identity');
 for(const k of ['sourcePageId','sourceRevision','sourceRevisionTimestamp','sourceTitle','sourceUrl','sourceSha256','retrievedAt'])need(candidate[k]===source[k],`German ${k} mismatch: ${candidate.id}`);
 need(sha(source.sourceWikitext)===source.sourceSha256,'German raw source hash mismatch: '+candidate.id);
 need(candidate.license?.id==='de-wikibooks-cc-by-sa-4.0'&&candidate.license?.policyStatus==='verified-site-policy'&&candidate.license?.licenseStatus==='unverified-primary-source','German licence status drift: '+candidate.id);
 need(candidate.sourceWikitext===source.sourceWikitext,'German candidate raw snapshot differs: '+candidate.id);
 need(candidate.recipe.ingredients.every(i=>source.sourceWikitext.includes(i.sourceText))&&candidate.recipe.steps.every(s=>source.sourceWikitext.includes(s.text)),'German extracted line missing from pinned raw source: '+candidate.id);
 return {ingredients:candidate.recipe.ingredients,steps:candidate.recipe.steps};
}

export async function loadInputs(){
 const read=file=>readFile(resolve(root,file));
 const currentRaw=await read('data/recipes/curated-local/flutter-manifest.json');
 const current=JSON.parse(currentRaw);
 const baselineRaw=await read(baselineFile);
 need(sha(baselineRaw)===baselineManifestSha256,'Frozen baseline manifest SHA drift');
 const baseline=validateBaseline(current,JSON.parse(baselineRaw));
 need(baseline.packs.length===23,'Expected exactly 23 frozen prior packs');
 const prior=[];
 for(const p of baseline.packs){const bytes=await read(p.file);need(sha(bytes)===p.sha256,'Prior pack hash mismatch: '+p.file);const pack=JSON.parse(bytes);prior.push(...pack.recipes);
  for(const snap of p.sourceSnapshots??[]){const snapshotBytes=await read(snap.file);need(sha(snapshotBytes)===snap.sha256,'Prior snapshot pin mismatch: '+snap.file);}}
 need(prior.length===4530,'Frozen prior selection must contain 4530 records');
 const spanishFiles=['source-pages.jsonl','parsed-recipes.jsonl','index.json','manifest.json'];
 const spanishBytes=await Promise.all(spanishFiles.map(f=>read(`${spanishArchive}/${f}`)));
 const [esSourceRaw,esParsedRaw,esIndexRaw,esManifestRaw]=spanishBytes,esIndex=JSON.parse(esIndexRaw),esManifest=JSON.parse(esManifestRaw);
 need(sha(esSourceRaw)===spanishSourceSha256&&sha(esParsedRaw)===spanishParsedSha256,'Frozen Spanish archive digest mismatch');
 need(esIndex.sourceFileSha256===spanishSourceSha256&&esIndex.parsedFileSha256===spanishParsedSha256,'Spanish index digest mismatch');
 need(esIndex.sourceId==='es-wikibooks-recipes-cc-by-sa'&&esIndex.sourceLanguage==='es'&&esIndex.recipeCount===853,'Unexpected Spanish archive index');
 const esSources=jsonl(esSourceRaw),esSaved=jsonl(esParsedRaw),esRebuilt=buildSpanishIndex(esSources);
 const esRebuiltRaw=Buffer.from(esRebuilt.recipes.map(JSON.stringify).join('\n')+'\n');
 need(sha(esRebuiltRaw)===spanishParsedSha256,'Spanish raw-source re-extraction differs from saved parsed file');
 need(snapshotFingerprint(esSaved)===snapshotFingerprint(esRebuilt.recipes),'Spanish parsed snapshots differ after re-extraction');
 need(snapshotFingerprint(esManifest.license)===snapshotFingerprint(esSources[0]?.license),'Spanish manifest licence mismatch');
 const spanish=esRebuilt.recipes.map(r=>({language:'es',source:r,snapshotSource:esSources.find(s=>s.recordId===r.recordId)}));
 const germanDir=germanArchive;
 const [deSourceRaw,deParsedRaw,deIndexRaw]=await Promise.all(['source-pages.jsonl','parsed-candidates.jsonl','index.json'].map(f=>read(`${germanDir}/${f}`)));
 const deIndex=JSON.parse(deIndexRaw);
 need(sha(deSourceRaw)===germanSourceSha256&&sha(deParsedRaw)===germanParsedSha256,'Frozen German archive digest mismatch');
 need(deIndex.sourcePageFileSha256===germanSourceSha256&&deIndex.candidateFileSha256===germanParsedSha256&&deIndex.candidateCount===544,'German index digest/count mismatch');
 const deSources=jsonl(deSourceRaw),deCandidates=jsonl(deParsedRaw),deMap=new Map(deSources.map(r=>[r.id,r]));
 need(deMap.size===deSources.length,'Duplicate German raw source IDs');
 const german=deCandidates.map(candidate=>{const source=deMap.get(candidate.id);const parsed=validateGermanCandidate(candidate,source);return {language:'de',source:candidate,snapshotSource:source,parsed};});
 const all=[...spanish,...german];
 for(const row of spanish){need(row.snapshotSource&&row.snapshotSource.sourceSha256===row.source.sourceSha256&&sha(row.snapshotSource.sourceWikitext)===row.source.sourceSha256,'Spanish source/raw mismatch: '+row.source.recordId);}
 return {current,currentRaw:currentRaw.toString('utf8'),baselineManifestRaw:baselineRaw.toString('utf8'),prior,spanish,german,esIndex,esManifest,deIndex,deSources,deCandidates};
}

export function buildBatch(inputs,count=targetCount){
 need(Number.isSafeInteger(count)&&count>0,'Invalid target count');
 need(sha(inputs.baselineManifestRaw)===baselineManifestSha256&&JSON.parse(inputs.baselineManifestRaw).packs.length===23,'Frozen baseline manifest drift');
 const oldRecords=new Set(),oldUrls=new Set(),signatures=new Set();
 for(const row of inputs.prior){const p=row.provenance??row;if(p.recordId)oldRecords.add(p.recordId);if(p.sourceUrl)oldUrls.add(p.sourceUrl);signatures.add(row.normalizedSourceContentSha256??selectedContent(row));}
 const excluded={priorSource:0,priorContent:0,withinArchiveDuplicate:0,sourceIntegrity:0};
 const acceptedComplete=[],acceptedIncomplete=[],seenContent=new Set(),seenRecords=new Set(),seenUrls=new Set();
 const candidates=[...inputs.spanish,...inputs.german].sort((a,b)=>a.language.localeCompare(b.language)||a.source.sourcePageId-b.source.sourcePageId);
 // Prefer every fully verified source record before using incomplete archive records to reach the conversion target.
 candidates.sort((a,b)=>{const al=a.language==='es'?0:1,bl=b.language==='es'?0:1;return al-bl||a.source.sourcePageId-b.source.sourcePageId;});
 for(const candidate of candidates){
  let item=candidate;
  const source=item.source,recordId=source.recordId??source.id,sourceUrl=source.sourceUrl;
  if(oldRecords.has(recordId)||oldUrls.has(sourceUrl)){excluded.priorSource++;continue;}
  const recipe=source.recipe;
  const ingredients=recipe?.ingredients,steps=recipe?.steps;
   if(!Array.isArray(ingredients)||!ingredients.length||!Array.isArray(steps)||!steps.length||!ingredients.every(i=>text(visibleText(i.sourceText)))||!steps.every(s=>text(visibleText(s.text))))continue;
  item={...item,sourceCoverage:auditRawIngredientCoverage(item),methodCoverage:auditRawMethodCoverage(item)};
  const sourceComplete=hasCompleteIngredientMethod({...recipe,rawIngredientCoverageReviewRequired:item.sourceCoverage.rawIngredientCoverageReviewRequired,rawMethodCoverageReviewRequired:item.methodCoverage.rawMethodCoverageReviewRequired});
  if(item.language==='de')validateGermanCandidate(source,item.snapshotSource);
  const signature=sourceContent(recipe);
  if(signatures.has(signature)){excluded.priorContent++;continue;}
  if(seenRecords.has(recordId)||seenUrls.has(sourceUrl)||seenContent.has(signature)){excluded.withinArchiveDuplicate++;continue;}
  signatures.add(signature);seenRecords.add(recordId);seenUrls.add(sourceUrl);seenContent.add(signature);
  (sourceComplete?acceptedComplete:acceptedIncomplete).push({...item,signature,sourceComplete});
 }
 const accepted=[...acceptedComplete,...acceptedIncomplete].slice(0,count);
 need(accepted.length===count,`Only ${accepted.length} source records available for target ${count}; target is not reduced`);
 const files=new Map(),rows=[];
 const evidence={sources:[{sourceId:inputs.esManifest.sourceId,sourceLanguage:'es',sourceArchive:`${spanishArchive}/source-pages.jsonl`,parsedArchive:`${spanishArchive}/parsed-recipes.jsonl`,sourceFileSha256:spanishSourceSha256,parsedFileSha256:spanishParsedSha256,parserVersion:inputs.esIndex.parserVersion,license:inputs.esManifest.license},{sourceId:'de-wikibooks-research-cc-by-sa',sourceLanguage:'de',sourceArchive:`${germanArchive}/source-pages.jsonl`,parsedArchive:`${germanArchive}/parsed-candidates.jsonl`,sourceFileSha256:germanSourceSha256,parsedFileSha256:germanParsedSha256,parserVersion:inputs.deIndex.parserVersion,sitePolicy:inputs.deIndex.sourcePolicy}],baselineManifestSha256,sourceSnapshotFormat:'full raw source + parsed source record + exact parser result; source bytes are reproduced from the pinned offline archives'};
 for(const item of accepted){
  const s=item.source,raw=item.snapshotSource,recordId=s.recordId??s.id,id=`curated-local:${item.language}:${s.sourcePageId}`;
  const parsed=item.language==='es'?s:item.source;
  const sourceRecipe=parsed.recipe;
  const archivedSourceRecord=item.language==='es'?raw:{...raw,sourceWikitext:s.sourceWikitext};
  const sourceRecord=item.language==='es'?raw:{...archivedSourceRecord,recordId:s.recordId??s.id,sourceId:s.sourceId,sourceLanguage:s.sourceLanguage??item.language,sourceRevision:s.sourceRevision,sourceRevisionTimestamp:s.sourceRevisionTimestamp,sourceUrl:s.sourceUrl,sourceSha256:s.sourceSha256,license:s.license};
  const snapshotObject={schemaVersion:1,sourceRecord,archivedSourceRecord,parsedRecipe:parsed,authoritativeEvidence:{sourceId:s.sourceId,sourceLanguage:item.language,sourceRevision:s.sourceRevision,sourceUrl:s.sourceUrl,sourceSha256:s.sourceSha256,license:s.license,sourceCategories:s.sourceCategories??[],licenseReviewStatus:s.license?.pageExceptionStatus??null,sourceLanguageIsNotCuisine:true}};
  const snapshot=fmt(snapshotObject),snapshotPath=`${folder}/source-snapshots/${item.language}-${s.sourcePageId}.json`;
  files.set(snapshotPath,snapshot);
  const row={id,recordVersion:1,name:sourceRecipe.name,nameAr:null,sourceLanguage:item.language,translationStatus:'not-translated',status:'needs-review',familyId:null,methodId:null,cuisines:[],sourceCategories:s.sourceCategories??[],sourceTextCompletenessVerified:item.sourceComplete,rawIngredientCoverageReviewRequired:item.sourceCoverage.rawIngredientCoverageReviewRequired,rawIngredientListLineCount:item.sourceCoverage.rawIngredientListLineCount,parsedIngredientLineCount:item.sourceCoverage.parsedIngredientLineCount,allParsedLinesFoundInRawSource:item.sourceCoverage.allParsedLinesFoundInRawSource,rawMethodCoverageReviewRequired:item.methodCoverage.rawMethodCoverageReviewRequired,rawMethodSourceLineCount:item.methodCoverage.rawMethodSourceLineCount,parsedMethodStepCount:item.methodCoverage.parsedMethodStepCount,allParsedStepsFoundInRawSource:item.methodCoverage.allParsedStepsFoundInRawSource,unmatchedRawMethodLineCount:item.methodCoverage.unmatchedRawMethodLineCount,unmatchedRepeatedRawMethodLineCount:item.methodCoverage.unmatchedRepeatedRawMethodLineCount,yield:{amount:null,min:null,max:null,unit:null,sourceText:null},time:{declaredTotalMinutes:null,prepMinutes:null,cookMinutes:null,sourceText:null},
    ingredients:sourceRecipe.ingredients.map((ingredient,n)=>({sourceLineIndex:n,name:visibleText(ingredient.sourceText),nameAr:null,sourceLanguage:item.language,amount:null,unit:null,optional:null,included:null,sourceText:ingredient.sourceText,sourceHeading:ingredient.sourceHeading??null,sourceGroupPath:ingredient.sourceGroupPath??null,quantityPrecision:'unreviewed',scales:null,foodBinding:null,sourceMarkupReviewRequired:hasUnresolvedMarkup(ingredient.sourceText)})),supplementalIngredients:[],
   steps:sourceRecipe.steps.map((step,n)=>({n:n+1,text:visibleText(step.text),sourceText:step.text,textAr:null,sourceLanguage:item.language,sourceStepIndices:[n],durationMinutes:null,sourceMarkupReviewRequired:hasUnresolvedMarkup(step.text)})),notes:['Untranslated source extraction. Raw source revision and parser output are pinned; review visible source markup, ingredient quantities, method and page-level rights before use.'],blockers:['Untranslated source text; culinary, quantity, page-rights, ingredient and method review pending.'],provenance:{...Object.fromEntries(['sourceId','sourceRevision','sourceRevisionTimestamp','sourceRevisionUser','retrievedAt','sourceUrl','sourceSha256','license'].map(k=>[k,s[k]??null])),recordId,derivedRecipeSha256:snapshotFingerprint(parsed),sourceSnapshotFile:snapshotPath,sourceSnapshotSha256:sha(snapshot),licenseSha256:snapshotFingerprint(s.license),sourceArchive:s.sourceArchive??raw?.sourceRequestArchive??null,sourceLanguage:item.language,changeNotice:notice},normalizedSourceContentSha256:item.signature,nutrition:null,runtimeReady:false,actuallyKitchenTested:false,gates:{culinarySourceTranscription:false,independentCulinaryApproval:false,perPageLicenseApproved:false,inventoryIdentityApproved:false,nutritionApproved:false}};
  row.contentSha256=snapshotFingerprint(JSON.parse(JSON.stringify(row)));rows.push(row);
 }
 const incompleteRows=rows.filter(r=>!hasCompleteIngredientMethod(r));
 const counts={recipes:rows.length,convertedRecords:rows.length,ingredientLines:rows.reduce((n,r)=>n+r.ingredients.length,0),steps:rows.reduce((n,r)=>n+r.steps.length,0),alreadyArchivedRecords:rows.length,newAcquisitions:0,newNativeLibraryRecords:rows.length,completeIngredientAndMethodRecords:rows.length-incompleteRows.length,incompleteIngredientAndMethodRecords:incompleteRows.length,omittedIngredientNames:rows.reduce((n,r)=>n+r.ingredients.filter(i=>!text(i.name)).length,0),omittedMethodText:rows.reduce((n,r)=>n+r.steps.filter(s=>!text(s.text)).length,0),rawIngredientCoverageVerifiedRecords:rows.filter(r=>r.rawIngredientCoverageReviewRequired===false&&r.allParsedLinesFoundInRawSource&&r.rawIngredientListLineCount===r.parsedIngredientLineCount).length,rawIngredientCoverageReviewRequiredRecords:rows.filter(r=>r.rawIngredientCoverageReviewRequired).length,rawMethodCoverageVerifiedRecords:rows.filter(r=>r.rawMethodCoverageReviewRequired===false&&r.allParsedStepsFoundInRawSource&&r.unmatchedRawMethodLineCount===0).length,rawMethodCoverageReviewRequiredRecords:rows.filter(r=>r.rawMethodCoverageReviewRequired).length,fullyReviewed:0,needsReview:rows.length,runtimeReady:0,translatedRecords:0,missingAmountLines:rows.reduce((n,r)=>n+r.ingredients.length,0),missingUnitLines:rows.reduce((n,r)=>n+r.ingredients.length,0),unknownYieldRecords:rows.length,unknownTimeRecords:rows.length,unresolvedMarkupIngredientLines:rows.reduce((n,r)=>n+r.ingredients.filter(i=>i.sourceMarkupReviewRequired).length,0),unresolvedMarkupMethodSteps:rows.reduce((n,r)=>n+r.steps.filter(s=>s.sourceMarkupReviewRequired).length,0),pageLicenseExceptionsNotReviewed:rows.filter(r=>r.provenance.license?.pageExceptionStatus==='not-reviewed-per-page').length};
 const languageCounts=Object.fromEntries(['de','es'].map(lang=>[lang,rows.filter(r=>r.sourceLanguage===lang).length]));
 const pack={schemaVersion:1,adapterVersion:'native-library-source-v1',sourceLanguage:'multi',sourceLanguages:['es','de'],translationStatus:'not-translated',reviewStatus:'source-extracted-unreviewed',runtimeReady:false,changeNotice:notice,sourceEvidence:evidence,sourceCount:rows.length,counts,languageCounts,cuisineCounts:{},duplicateReview:{previousSelectedRecords:inputs.prior.length,inputManifestSha256:baselineManifestSha256,excluded,scope:'Source record/revision/permalink and normalized ingredient+method text checked against all 23 frozen packs and within the two archived language candidates. No semantic translated-dish uniqueness claim.'},recipes:rows,relationships:[]};
 files.set(packFile,fmt(pack));
 const report={schemaVersion:1,packFile,packSha256:sha(files.get(packFile)),counts,languageCounts,cuisineCounts:{},untaggedRecords:rows.length,sourceSnapshotCount:rows.length,archiveCandidateCounts:{es:inputs.spanish.length,de:inputs.german.length},completeCandidateCounts:{es:inputs.spanish.filter(hasCompleteCandidate).length,de:inputs.german.filter(hasCompleteCandidate).length},incompleteCandidateCounts:{es:inputs.spanish.filter(x=>!hasCompleteCandidate(x)).length,de:inputs.german.filter(x=>!hasCompleteCandidate(x)).length},rawIngredientCoverageReviewRequiredCandidates:{es:inputs.spanish.filter(x=>auditRawIngredientCoverage(x).rawIngredientCoverageReviewRequired).length,de:inputs.german.filter(x=>auditRawIngredientCoverage(x).rawIngredientCoverageReviewRequired).length},rawMethodCoverageReviewRequiredCandidates:{es:inputs.spanish.filter(x=>auditRawMethodCoverage(x).rawMethodCoverageReviewRequired).length,de:inputs.german.filter(x=>auditRawMethodCoverage(x).rawMethodCoverageReviewRequired).length},selectedCompleteRecords:counts.completeIngredientAndMethodRecords,selectedIncompleteRecords:counts.incompleteIngredientAndMethodRecords,duplicateReview:pack.duplicateReview,integrityIsCulinaryOrRightsApproval:false};
 files.set(`${folder}/conversion-report.json`,JSON.stringify(report,null,2)+'\n');files.set(baselineFile,inputs.baselineManifestRaw);
 return {pack,report,files};
}

export async function run({check=false}={}){
 const result=buildBatch(await loadInputs());
 const snapshotDir=resolve(root,folder,'source-snapshots');
 const expectedSnapshots=new Set([...result.files.keys()].filter(file=>file.startsWith(`${folder}/source-snapshots/`)).map(file=>file.slice(`${folder}/source-snapshots/`.length)));
 if(!check){
  await mkdir(snapshotDir,{recursive:true});
  for(const entry of await readdir(snapshotDir,{withFileTypes:true}))if(entry.isFile()&&/^(?:es|de)-\d+\.json$/u.test(entry.name)&&!expectedSnapshots.has(entry.name))await unlink(resolve(snapshotDir,entry.name));
 }
 const actualSnapshots=(await readdir(snapshotDir,{withFileTypes:true})).filter(entry=>entry.isFile()&&/^(?:es|de)-\d+\.json$/u.test(entry.name)).map(entry=>entry.name).sort();
 if(check)need(JSON.stringify(actualSnapshots)===JSON.stringify([...expectedSnapshots].sort()),'Source snapshot directory contains missing or stale generated snapshots');
 for(const [file,content]of result.files){if(check)need(await readFile(resolve(root,file),'utf8')===content,'Converted output drift: '+file);else await writeFile(resolve(root,file),content,'utf8');}
 if(!check){const writtenSnapshots=(await readdir(snapshotDir,{withFileTypes:true})).filter(entry=>entry.isFile()&&/^(?:es|de)-\d+\.json$/u.test(entry.name)).map(entry=>entry.name).sort();need(JSON.stringify(writtenSnapshots)===JSON.stringify([...expectedSnapshots].sort()),'Generated snapshot directory does not match selected records');}
 return result.report;
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url))console.log(JSON.stringify(await run({check:process.argv.includes('--check')})));
