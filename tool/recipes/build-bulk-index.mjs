import { createHash } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseRecipePage } from './collect-wikibooks.mjs';
import { parseIngredientQuantity } from './parse-ingredient-quantity.mjs';

const sourceId='wikibooks-cookbook-cc-by-sa';
const hash=value=>createHash('sha256').update(value,'utf8').digest('hex');
const need=(valid,message)=>{if(!valid)throw new Error(message);};
// Exact source-category labels only. Unlisted labels remain searchable raw tags.
const cuisineNames={
  Albanian:'ألباني',Algerian:'جزائري',American:'أمريكي',Argentine:'أرجنتيني',
  Australian:'أسترالي',Bangladeshi:'بنغلاديشي',Brazilian:'برازيلي',British:'بريطاني',
  Bulgarian:'بلغاري',Cameroonian:'كاميروني',Canadian:'كندي',Chinese:'صيني',
  Egyptian:'مصري',Ethiopian:'إثيوبي',French:'فرنسي',German:'ألماني',Ghanaian:'غاني',
  Greek:'يوناني',Indian:'هندي',Indonesian:'إندونيسي',Iranian:'إيراني',Iraqi:'عراقي',
  Irish:'أيرلندي',Italian:'إيطالي',Jamaican:'جامايكي',Japanese:'ياباني',Kenyan:'كيني',
  Korean:'كوري',Lebanese:'لبناني',Malaysian:'ماليزي',Mexican:'مكسيكي',Moroccan:'مغربي',
  Nigerian:'نيجيري',Pakistani:'باكستاني',Palestinian:'فلسطيني',Peruvian:'بيروفي',
  Portuguese:'برتغالي',Russian:'روسي',Saudi:'سعودي','Saudi Arabian':'سعودي',
  Senegalese:'سنغالي','South African':'جنوب إفريقي',Spanish:'إسباني',
  'Sri Lankan':'سريلانكي',Sudanese:'سوداني',Swedish:'سويدي',Syrian:'سوري',
  Taiwanese:'تايواني',Thai:'تايلاندي',Tunisian:'تونسي',Turkish:'تركي',
  Ukrainian:'أوكراني',Vietnamese:'فيتنامي',Welsh:'ويلزي',Caribbean:'كاريبي',
  Mediterranean:'متوسطي','Middle Eastern':'شرق أوسطي','West African':'غرب إفريقي',
};
const sourceCuisines=new Map(Object.entries(cuisineNames).map(([name,labelAr])=>[
  `Category:${name} recipes`,{id:name.toLowerCase().replaceAll(' ','-'),name,labelAr},
]));
function categories(value){
  need(Array.isArray(value)&&value.every(v=>typeof v==='string'&&v.startsWith('Category:')),'Invalid source categories');
  return value;
}
function literalCategories(raw){
  const text=raw.replace(/<!--[\s\S]*?-->/g,'').replace(/<(nowiki|pre|source|syntaxhighlight|code)\b[^>]*>[\s\S]*?<\/\1\s*>/gi,'');
  return [...new Set([...text.matchAll(/\[\[\s*Category:([^\]|\n]+)(?:\|[^\]]*)?\]\]/g)]
    .map(m=>`Category:${m[1].trim().replaceAll('_',' ')}`))].sort();
}

export function buildBulkIndex(records,{categoryObservations=[],parseSource}={}){
  need(Array.isArray(records),'Records must be a list');
  const revisions=new Map(),latest=new Map(),observed=new Map();
  for(const observation of categoryObservations){
    need(typeof observation.recordId==='string','Invalid category observation');
    const values=categories(observation.categories??observation.sourceCategories);
    observed.set(observation.recordId,new Set([...(observed.get(observation.recordId)??[]),...values]));
  }
  for(let i=0;i<records.length;i++){
    const r=records[i];
    need(r.sourceId===sourceId&&Number.isSafeInteger(r.sourcePageId)&&r.sourcePageId>0,'Invalid source page identity');
    need(typeof r.sourceRevision==='string'&&/^\d+$/.test(r.sourceRevision)&&Number.isSafeInteger(Number(r.sourceRevision))&&Number(r.sourceRevision)>0,'Invalid source revision');
    need(typeof r.sourceTitle==='string'&&r.sourceTitle.startsWith('Cookbook:'),'Invalid source namespace');
    need(r.recordId===`wikibooks-${r.sourcePageId}-r${r.sourceRevision}`,'Invalid source record key');
    need(typeof r.sourceWikitext==='string'&&r.sourceWikitext.length>0&&hash(r.sourceWikitext)===r.sourceSha256,'Corrupt source text/hash');
    const url=new URL(r.sourceUrl);
    need(url.protocol==='https:'&&url.hostname==='en.wikibooks.org'&&url.pathname==='/w/index.php'&&
      url.searchParams.get('oldid')===r.sourceRevision&&url.searchParams.get('title')===r.sourceTitle,'Invalid source permalink');
    need(Number.isFinite(Date.parse(r.retrievedAt)),'Invalid retrieval date');
    need(r.license?.id==='wikibooks-cookbook-cc-by-sa-4.0','Missing source licence');
    categories(r.sourceCategories);
    need(r.recipe?.nutrition===null&&Array.isArray(r.recipe.ingredients)&&Array.isArray(r.recipe.steps),'Unreviewed recipe structure/nutrition');
    need(r.recipe.ingredients.every(v=>v.foodBinding===null),'Unreviewed ingredient bindings');
    need(r.isRecipe===(r.recipe.ingredients.length>0&&r.recipe.steps.length>0),'Recipe parsing status mismatch');
    const previous=revisions.get(r.recordId);
    if(previous){
      need(previous.record.sourceSha256===r.sourceSha256,'Conflicting revision hash');
      observed.set(r.recordId,new Set([...(observed.get(r.recordId)??[]),...r.sourceCategories]));
      continue;
    }
    const entry={record:r,line:i+1};revisions.set(r.recordId,entry);
    if(!latest.has(r.sourcePageId)||Number(latest.get(r.sourcePageId).record.sourceRevision)<Number(r.sourceRevision))latest.set(r.sourcePageId,entry);
  }
  for(const id of observed.keys())need(revisions.has(id),'Category observation references absent revision');
  const cuisineCounts=new Map(),entries=[],parsedRecipes=[];
  for(const {record:r,line} of [...latest.values()].sort((a,b)=>a.record.sourcePageId-b.record.sourcePageId)){
    const parsed=parseSource?.(r.sourceWikitext);
    const ingredientTexts=parsed?.ingredients??r.recipe.ingredients.map(v=>v.sourceText);
    const stepTexts=parsed?.steps??r.recipe.steps.map(v=>v.text);
    const isRecipe=ingredientTexts.length>0&&stepTexts.length>0;
    if(isRecipe)parsedRecipes.push({
      schemaVersion:1,id:`wikibooks:${r.sourcePageId}`,recordId:r.recordId,sourceId,
      sourceRevision:r.sourceRevision,sourceUrl:r.sourceUrl,sourceSha256:r.sourceSha256,
      parserVersion:parsed?'wikibooks-sections-v2':'original-record-extraction',quantityParserVersion:'source-prefix-v1',license:r.license,
      reviewStatus:'source-extracted-unreviewed',changeNotice:'Source-language section extraction; markup removed. Not culinarily reviewed, translated or runtime-approved.',
      recipe:{name:r.recipe.name,nameAr:r.recipe.nameAr??null,servings:null,
        servingsSourceText:parsed?.servingsText??r.recipe.servingsSourceText??null,
        ingredients:ingredientTexts.map((sourceText,i)=>({id:`source-line-${i+1}`,name:sourceText,sourceText,amount:null,unit:null,foodBinding:null,quantityCandidate:parseIngredientQuantity(sourceText)})),
        steps:stepTexts.map((text,i)=>({n:i+1,text,durationMinutes:null})),nutrition:null},
    });
    const api=[...new Set([...r.sourceCategories,...(observed.get(r.recordId)??[])])].sort();
    const literal=literalCategories(r.sourceWikitext),all=[...new Set([...api,...literal])].sort();
    const tagged=all.filter(c=>sourceCuisines.has(c));
    for(const category of tagged){
      const cuisine=sourceCuisines.get(category);
      const count=cuisineCounts.get(category)??{...cuisine,sourceCategory:category,pageCount:0,parseableRecipePages:0};
      count.pageCount++;if(isRecipe)count.parseableRecipePages++;cuisineCounts.set(category,count);
    }
    entries.push({id:`wikibooks:${r.sourcePageId}`,recordId:r.recordId,sourcePageId:r.sourcePageId,
      sourceRevision:r.sourceRevision,sourceUrl:r.sourceUrl,sourceSha256:r.sourceSha256,sourceRecordLine:line,
      name:r.recipe.name,nameAr:r.recipe.nameAr??null,isParseableRecipe:isRecipe,
      ingredientRows:ingredientTexts.length,stepRows:stepTexts.length,
      cuisineTags:tagged.map(c=>sourceCuisines.get(c).id).sort(),sourceCategories:all,
      categoryEvidence:{api,literalWikitext:literal},reviewStatus:'source-extracted-unreviewed'});
  }
  const ingredientRows=parsedRecipes.flatMap(r=>r.recipe.ingredients);
  const candidateCount=ingredientRows.filter(i=>i.quantityCandidate.status==='parsed-source-candidate').length;
  return {quantityCandidates:{parserVersion:'source-prefix-v1',parsed:candidateCount,unresolved:ingredientRows.length-candidateCount,total:ingredientRows.length},schemaVersion:1,sourceId,status:'research-only',sourceRevisionRecords:revisions.size,
    distinctSourcePages:entries.length,parseableRecipePages:entries.filter(e=>e.isParseableRecipe).length,
    runtimeReadyCount:0,entries,parsedRecipes,cuisines:[...cuisineCounts.values()].sort((a,b)=>a.id.localeCompare(b.id)),
    classificationNote:'Exact recognised category labels reported by source/API or literal source wikitext; not a verified origin or suitability claim. Untagged pages remain unclassified. Source licences/unknown quantities and nutrition remain unchanged.'};
}

if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  try{
    const folder='data/recipes/bulk/wikibooks-cookbook';
    const raw=await readFile(`${folder}/source-pages.jsonl`,'utf8');
    let observations='',categoryObservations=[];
    try{observations=await readFile(`${folder}/category-observations.jsonl`,'utf8');}catch(e){if(e.code!=='ENOENT')throw e;}
    if(observations)categoryObservations=observations.split(/\r?\n/).filter(Boolean).map(JSON.parse);
    const built=buildBulkIndex(raw.split(/\r?\n/).filter(Boolean).map(JSON.parse),{categoryObservations,parseSource:parseRecipePage});
    const {parsedRecipes,...index}=built;
    const parsedText=parsedRecipes.map(r=>JSON.stringify(r)).join('\n')+(parsedRecipes.length?'\n':'');
    await writeFile(`${folder}/parsed-recipes.jsonl`,parsedText,'utf8');
    const result={...index,generatedAt:new Date().toISOString(),records:'source-pages.jsonl',
      parsedRecipes:'parsed-recipes.jsonl',parserVersion:'wikibooks-sections-v2',parsedRecipesSha256:hash(parsedText),
      sourceFileSha256:hash(raw),categoryObservationsSha256:observations?hash(observations):null};
    await writeFile(`${folder}/index.json`,JSON.stringify(result,null,2)+'\n','utf8');
    console.log(JSON.stringify({sourceRevisionRecords:index.sourceRevisionRecords,distinctSourcePages:index.distinctSourcePages,
      parseableRecipePages:index.parseableRecipePages,cuisineCount:index.cuisines.length,
      cuisines:index.cuisines.map(c=>({name:c.name,pages:c.pageCount})),runtimeReadyCount:0},null,2));
  }catch(error){console.error(error.message);process.exitCode=1;}
}
