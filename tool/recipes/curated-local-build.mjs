import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {loadRecipeReviewSnapshots} from './recipe-review-reader.mjs';
import {reviewTarget,snapshotFingerprint} from './review-target.mjs';
import {emptyImportDraft,auditRecipeImportDraft} from './import-preflight.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
const folder='data/recipes/curated-local/first-reviewed-20261014';
const sha=v=>createHash('sha256').update(v).digest('hex');
const need=(v,m)=>{if(!v)throw Error(m)};
export function validateDecision(d,source,raw){
  need(d.sourcePageId===raw.sourcePageId&&source.recordId===raw.recordId,'Source identity mismatch');
  need(d.sourceRecordId===source.recordId&&d.sourceSha256===source.sourceSha256&&d.derivedRecipeSha256===snapshotFingerprint(source),'Reviewed source revision drift; explicit new review required');
  need(['fully-specified','needs-review','not-cookable'].includes(d.status),'Invalid culinary status');
  need(d.ingredients.length===source.recipe.ingredients.length,'Every source ingredient needs explicit decision');
  need(d.ingredients.every((x,i)=>x[0]===i&&x.length===7&&typeof x[1]==='string'&&typeof x[2]==='string'&&typeof x[5]==='boolean'),'Invalid ingredient decision/order');
  for(const x of d.ingredients)need(x[3]===null?x[4]===null:typeof x[3]==='number'&&x[3]>0&&typeof x[4]==='string','Unknown is null; quantity must be positive with unit');
  for(const c of d.cuisines)need(raw.sourceWikitext.includes(c[2])||raw.sourceCategories.some(s=>s.includes(c[2])),'Cuisine evidence absent from source');
  need(d.steps.length>0&&d.steps.every(s=>s[0].length>0&&s[0].every(i=>Number.isInteger(i)&&i>=0&&i<source.recipe.steps.length)&&s[1].length>0),'Invalid source step mapping');
  const mapped=new Set(d.steps.flatMap(s=>s[0]));
  for(const s of d.excludedSourceSteps??[])mapped.add(s.sourceStepIndex);
  need(mapped.size===source.recipe.steps.length,'Every source step must be mapped or explicitly excluded');
  if(d.status==='fully-specified'){
    need(d.ingredients.every(x=>x[3]!==null),'Fully specified ingredients cannot be unknown');
    need(!(d.supplementalIngredients??[]).some(x=>x.amount===null),'Fully specified supplemental amounts cannot be unknown');
    need(d.yield.sourceText&&d.time.declaredTotalMinutes!==null&&!d.time.conflict,'Fully specified yield/time missing/conflicted');
  }
  return true;
}
export function normalize(d,source,raw,provenance){
  validateDecision(d,source,raw);
  return {
    id:'curated-local:'+d.sourcePageId,recordVersion:1,name:source.recipe.name,nameAr:d.nameAr,status:d.status,
    familyId:'curated-local:'+d.family,methodId:d.method,
    cuisines:d.cuisines.map(([id,nameAr,evidenceText])=>({id,nameAr,evidenceText,sourceRecordId:source.recordId,reviewStatus:'source-supported-not-runtime-approved'})),
    yield:d.yield,time:d.time,
    ingredients:d.ingredients.map(([sourceLineIndex,nameAr,name,amount,unit,optional,decisionNote])=>({
      sourceLineIndex,name,nameAr,amount,unit,optional,included:!(d.excludedIngredients??[]).includes(sourceLineIndex),
      decisionNote,sourceText:source.recipe.ingredients[sourceLineIndex].sourceText,target:reviewTarget(source,sourceLineIndex),
      quantityPrecision:amount===null?'unknown':decisionNote.includes('approximate')?'source-approximate':'source-stated',
      scales:null,foodBinding:null
    })),
    supplementalIngredients:(d.supplementalIngredients??[]).map(x=>({...x,foodBinding:null})),
    steps:d.steps.map(([sourceStepIndices,textAr,duration],i)=>({n:i+1,textAr,sourceStepIndices,duration})),
    excludedSourceSteps:d.excludedSourceSteps??[],notes:d.notes,blockers:d.blockers,
    provenance,nutrition:null,runtimeReady:false,actuallyKitchenTested:false,
    gates:{culinarySourceTranscription:true,independentCulinaryApproval:false,perPageLicenseApproved:false,inventoryIdentityApproved:false,nutritionApproved:false}
  };
}
const fmt=v=>JSON.stringify(v,null,2)+'\n';
export function cookbook(pack){
  const out=['# أول مجموعة وصفات من الأرشيف المحلي','',
    'هذه وصفات مصاغة ومقاديرها مراجعة من نصوص مؤرشفة فعلية. الاكتمال هنا يعني وجود مقادير وطريقة وناتج وزمن منشور للطبخ؛ لا يعني اعتماد التغذية أو الاستيراد إلى الكتالوج. لم تجر تجربة مطبخ فعلية. المجهول محفوظ كما هو.','',
    'النصوص العربية تكييف جديد لنصوص مساهمي Wikibooks؛ [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). روابط الإصدارات ثابتة لكل وصفة. استثناءات حقوق الصفحات تحتاج مراجعة مستقلة.','',
    '| الوصفة | حالة الطبخ | المطبخ المدعوم بالنص | الناتج المنشور | الزمن المنشور |',
    '|---|---|---|---|---|'];
  const statuses={'fully-specified':'محددة المقادير والطريقة والناتج والزمن','needs-review':'صالحة كمسودة طبخ؛ مراجعة معلنة مطلوبة','not-cookable':'ناقصة؛ لا تقدم كوصفة مكتملة'};
  for(const r of pack.recipes)out.push('| '+[r.nameAr,statuses[r.status],r.cuisines.map(c=>c.nameAr).join('، ')||'غير مصنف',r.yield.sourceText,r.time.sourceText??'غير منشور'].join(' | ')+' |');
  for(const r of pack.recipes){
    out.push('','## '+r.nameAr,'',r.name+' — '+statuses[r.status], '',
      '**الناتج:** '+r.yield.sourceText+' ('+r.yield.unit+'). **الزمن:** '+(r.time.sourceText??'غير منشور')+'. التحضير والطهي منفصلين: '+(r.time.prepMinutes??'مجهول')+' / '+(r.time.cookMinutes??'مجهول')+' دقيقة.',
      '', '**المقادير:**','');
    for(const i of r.ingredients)out.push('- '+(i.amount??'كمية مجهولة')+' '+(i.unit??'')+' — '+i.nameAr+(i.included?'':' (مستبعد صراحة من هذه الطريقة)')+(i.optional?' (اختياري)':'')+'؛ '+i.decisionNote+'.');
    for(const i of r.supplementalIngredients)out.push('- '+(i.amount??'كمية مجهولة')+' '+(i.unit??'')+' — '+i.nameAr+'؛ مذكور في الإجراء: '+i.sourceText+'. '+i.reason+'.');
    out.push('','**الطريقة المختصرة بصياغة عربية:**','');
    for(const s of r.steps)out.push(s.n+'. '+s.textAr);
    out.push('','**مراجعات وحدود محددة:**','');
    for(const n of [...r.notes,...r.blockers])out.push('- '+n);
    out.push('','**إسناد ومراجعة ثابتة:** [Wikibooks contributors — revision '+r.provenance.sourceRevision+']('+r.provenance.sourceUrl+').',
      '- Source wikitext SHA256: '+r.provenance.sourceSha256,
      '- Full source snapshot SHA256: '+r.provenance.sourceSnapshotSha256,
      '- License snapshot SHA256: '+r.provenance.licenseSha256,
      '- Full normalized record SHA256: '+r.contentSha256,
      '- Source snapshot: '+r.provenance.sourceSnapshotFile,
      '- Cuisine evidence: '+(r.cuisines.map(c=>c.id+': '+c.evidenceText).join('; ')||'none; no regional inference')+'.');
  }
  return out.join('\n')+'\n';
}
export async function build(){
  const {recipes,evidence}=await loadRecipeReviewSnapshots();
  const sourceBytes=await readFile(resolve(root,'data/recipes/bulk/wikibooks-cookbook/source-pages.jsonl'));
  const rawMap=new Map(sourceBytes.toString('utf8').split(/\r?\n/).filter(Boolean).map(JSON.parse).map(x=>[x.sourcePageId,x]));
  const decisions=JSON.parse((await readFile(resolve(root,folder,'review-decisions.json'),'utf8')).replace(/^\uFEFF/,''));
  const dest=resolve(root,folder);await mkdir(resolve(dest,'source-snapshots'),{recursive:true});
  const seen=new Set(),normalized=[];
  for(const d of decisions.recipes){
    need(!seen.has(d.sourcePageId),'Duplicate source decision');seen.add(d.sourcePageId);
    const source=recipes.get('wikibooks:'+d.sourcePageId),raw=rawMap.get(d.sourcePageId);
    need(source&&raw,'Missing authoritative source');
    need(sha(raw.sourceWikitext)===raw.sourceSha256&&source.sourceSha256===raw.sourceSha256,'Source wikitext SHA mismatch');
    validateDecision(d,source,raw);
    const snapshot={schemaVersion:1,sourceRecord:raw,authoritativeParsedRecipe:source,authoritativeEvidence:evidence};
    const bytes=fmt(snapshot),filename='source-snapshots/'+d.sourcePageId+'.json';
    const provenance={sourceId:source.sourceId,recordId:source.recordId,sourceRevision:source.sourceRevision,
      sourceRevisionTimestamp:raw.sourceRevisionTimestamp,retrievedAt:raw.retrievedAt,sourceUrl:source.sourceUrl,
      sourceSha256:source.sourceSha256,derivedRecipeSha256:snapshotFingerprint(source),
      sourceSnapshotFile:folder+'/'+filename,sourceSnapshotSha256:sha(bytes),
      license:source.license,licenseSha256:snapshotFingerprint(source.license),changeNotice:decisions.changeNotice};
    const r=normalize(d,source,raw,provenance);r.contentSha256=snapshotFingerprint(r);normalized.push(r);
    try{const previous=await readFile(resolve(dest,filename),'utf8');need(previous===bytes,'Immutable source snapshot already exists with different bytes');}
    catch(e){if(e.code!=='ENOENT')throw e;await writeFile(resolve(dest,filename),bytes,{flag:'wx'});}
  }
  const related=[
    {familyId:'curated-local:naan',recipeIds:['curated-local:33064','curated-local:456620'],relationship:'same-dish-distinct-methods',reviewed:true,evidence:'33064 ingredient 3 baking soda, yogurt dough and hot oven; 456620 active yeast with proofing and 140 C baking. Independent complete recipes; not numbered titles alone.',runtimeApproved:false},
    {familyId:'curated-local:irish-soda-bread',recipeIds:['curated-local:96175','curated-local:164154'],relationship:'same-dish-ingredient-variants',reviewed:true,evidence:'Both bake buttermilk/baking-soda loaves; whole-wheat and egg/butter differences. Not counted as distinct techniques.',runtimeApproved:false}
  ].filter(g=>g.recipeIds.every(id=>normalized.some(r=>r.id===id)));
  const existingCatalogue=[];
  for(const name of ['egyptian','levantine','saudi','italian']){
    const data=JSON.parse(await readFile(resolve(root,'recipes/data/'+name+'.json'),'utf8'));
    for(const r of data.recipes)existingCatalogue.push({id:r.id,name:r.name});
  }
  const initial=JSON.parse(await readFile(resolve(root,'data/recipes/research-candidates.json'),'utf8')).recipes;
  const catalogueNameMatches=normalized.flatMap(r=>existingCatalogue.filter(x=>x.name===r.nameAr||x.name===r.name).map(x=>({curatedId:r.id,catalogueId:x.id})));
  const initialSourceMatches=normalized.flatMap(r=>initial.filter(x=>x.sourceUrl===r.provenance.sourceUrl).map(x=>({curatedId:r.id,researchId:x.id})));
  const pack={schemaVersion:1,reviewedAt:decisions.reviewedAt,reviewer:decisions.reviewer,changeNotice:decisions.changeNotice,
    sourceEvidence:evidence,sourceCount:normalized.length,recipes:normalized,relationships:related,
    counts:{fullySpecified:normalized.filter(r=>r.status==='fully-specified').length,needsReview:normalized.filter(r=>r.status==='needs-review').length,
    notCookable:normalized.filter(r=>r.status==='not-cookable').length,distinctMethodFamilies:related.filter(g=>g.relationship==='same-dish-distinct-methods').length,
    sourceSupportedCuisineLabels:new Set(normalized.flatMap(r=>r.cuisines.map(c=>c.id))).size,runtimeReady:0},
    duplicateReview:{scope:'selected source snapshots plus existing54 names and six initial research candidates; source IDs authoritative; no claim of global6056dedup',
      existingCatalogueCount:existingCatalogue.length,initialResearchCount:initial.length,exactCatalogueNameMatches:catalogueNameMatches,exactInitialSourceMatches:initialSourceMatches,
      crossLanguageDuplicateReview:'not performed; selected English variants grouped manually; no claim of globally unique dishes',
      exactDuplicateSelectedSourceIds:0,normalizedTitleCollisions:normalized.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i).length,
      decision:'Same-family variants retained explicitly; no total across banks claimed as distinct dishes.'}};
  await mkdir(resolve(dest,'preflight-drafts'),{recursive:true});
  const preflight=[];
  for(const r of normalized.filter(r=>r.status==='fully-specified')){
    const source=recipes.get('wikibooks:'+r.id.split(':')[1]),draft=emptyImportDraft(source);
    Object.assign(draft,{note:'Manual source quantities/choices only. Missing timing/scaling/food identity remain unresolved; not registered or imported.',reviewedAt:decisions.reviewedAt,
      servings:r.yield.unit==='source-servings'?r.yield.amount:null,prepMinutes:r.time.prepMinutes,cookMinutes:r.time.cookMinutes});
    for(const i of r.ingredients){
      const line=draft.lines[i.sourceLineIndex];
      Object.assign(line,{resolution:/selected|option|alternative/i.test(i.decisionNote)?'choice':'single',disposition:i.optional?'included-optional':'required',note:i.decisionNote,
        components:[{name:i.name,amount:i.amount,unit:i.unit,form:i.name,optional:i.optional,scales:null,food:null}]});
    }
    const report=auditRecipeImportDraft(source,draft);
    const name=r.id.split(':')[1]+'.json';
    await writeFile(resolve(dest,'preflight-drafts',name),fmt(draft));
    preflight.push({recipeId:r.id,draftFile:folder+'/preflight-drafts/'+name,draftSha256:sha(fmt(draft)),...report});
  }
  await writeFile(resolve(dest,'preflight-reports.json'),fmt({schemaVersion:1,registeredInSharedRegistry:false,reports:preflight}));
  await writeFile(resolve(dest,'normalized-recipes.json'),fmt(pack));
  await writeFile(resolve(dest,'COOKBOOK.ar.md'),cookbook(pack));
  console.log(JSON.stringify({folder,counts:pack.counts,records:normalized.map(r=>({id:r.id,status:r.status}))}));
  return pack;
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url))build().catch(e=>{console.error(e);process.exitCode=1});
