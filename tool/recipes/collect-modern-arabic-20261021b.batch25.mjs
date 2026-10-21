import {createHash} from 'node:crypto';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {resolve} from 'node:path';
const root=process.cwd(), dir='data/recipes/modern-scale-20261021b-arabic';
const utf8=async p=>{let s=await readFile(resolve(root,p),'utf8');return s.charCodeAt(0)===0xfeff?s.slice(1):s};
const sorted=v=>Array.isArray(v)?v.map(sorted):v&&typeof v==='object'?Object.fromEntries(Object.keys(v).sort().map(k=>[k,sorted(v[k])])):v;
const sha=s=>createHash('sha256').update(s,'utf8').digest('hex');
const batch=JSON.parse(await utf8(`${dir}/recipes.json`));
const extras=JSON.parse(await utf8(process.argv[2] ?? `${dir}/batch25-facts.json`));`nconst args=process.argv.slice(3).map(Number); const [sitemapRequest,startPrimary,startWeekly,endPrimary,endWeekly]=args;
const sitemapNo=Number.isFinite(sitemapRequest)?sitemapRequest:6; const startP=Number.isFinite(startPrimary)?startPrimary:10, startW=Number.isFinite(startWeekly)?startWeekly:14, endP=Number.isFinite(endPrimary)?endPrimary:14, endW=Number.isFinite(endWeekly)?endWeekly:14;
const exactPrior=[
 'https://www.manalonline.com/مقلوبة-الدجاج-الباذنجان/','https://www.manalonline.com/المقلوبـة/','https://www.manalonline.com/سلمون-مشوي/','https://www.manalonline.com/كيك-بالتفاح/','https://www.manalonline.com/مكرونة-بالدجاج-والبشاميل/','https://www.manalonline.com/كبسة-الدجاج-السريعة/','https://www.manalonline.com/كفتة-بالطحينة/','https://www.manalonline.com/رولات-المسخن-السريعة/','https://www.manalonline.com/صينية-الباذنجان-والدجاج-بالكريمة/'
];
const canonUrl=s=>{const u=new URL(s);return `${u.protocol}//${u.host}${decodeURIComponent(u.pathname).replace(/\/$/,'')}`.toLowerCase()};
const usedUrls=new Set([...exactPrior,...batch.recipes.map(r=>r.sourceUrl)].map(canonUrl));
const seenTitles=new Set(batch.recipes.map(r=>r.title.normalize('NFC').replace(/[\sـ،؛:!؟.,()\[\]{}]/g,'').toLowerCase()));
for(let i=0;i<extras.length;i++){
 const s=extras[i], u=canonUrl(s.url), title=s.title.normalize('NFC').replace(/[\sـ،؛:!؟.,()\[\]{}]/g,'').toLowerCase();
 if(usedUrls.has(u))throw Error(`Duplicate exact URL ${s.url}`);
 if(seenTitles.has(title))throw Error(`Duplicate exact normalized title ${s.title}`);
 usedUrls.add(u);seenTitles.add(title);
 const index=batch.recipes.length, extractPath=`${dir}/source-extracts/${String(index+1).padStart(3,'0')}-${s.id}.json`;
 const note={schemaVersion:1,sourceUrl:s.url,retrievedAt:'2026-10-21',evidenceKind:'direct-http-jsonld',creator:'منال العالم',sourcePageTitle:s.title,sourceCategory:s.category,sourceCuisine:null,ingredientFactCoverage:{complete:true,lines:s.ingredients.map((sourceText,index)=>({index,sourceText}))},methodFactCoverage:{complete:true,sourceStepIndexBase:0,sourceStepCount:s.steps.length,segments:s.steps.map((summaryAr,index)=>({sourceStepIndices:[index],summaryAr}))},yield:null,time:null,rawBodyArchived:false,sourceBodySha256:null,limitations:'حقائق مكونات/كميات ونقاط طريقة مختصرة بالعربية؛ لا نص HTML أو صورة أو نص تعليمات أصلي محفوظ. الفئة ليست تصنيف مطبخ.'};
 const noteText=JSON.stringify(note,null,2)+'\n'; await writeFile(resolve(root,extractPath),noteText,{encoding:'utf8'});
 const specificNotes=[];
 if(s.id==='manal-macaroni-bechamel-20261021b')specificNotes.push('تضيف الطريقة 12 كوب ماء وملعقة ملح وملعقة زيت للسلق وكوب ماء لصلصة الطماطم؛ هذه الإضافات غير مدرجة كسطور مكونات.');
 if(s.id==='manal-chicken-shakriyeh-20261021b')specificNotes.push('خطوة المصدر تكرر ذكر البصل وتقول إن الشاكرية تطهى مع الدجاج؛ حُفظ الالتباس ولم تُستنتج كمية أخرى.');
 if(s.id==='manal-daily-orange-cake-20261021b')specificNotes.push('ترتيب الخطوتين الأخيرتين في المصدر يشرح توزيع الصلصة قبل شرح خلطها؛ محفوظ الترتيب كما ظهر مع التنبيه.');
 if(s.id==='manal-kudu-chicken-20261021b')specificNotes.push('تذكر الطريقة إضافة ثوم طازج مع البصل في المقلاة الثانية دون ظهوره كسطر مستقل في قائمة المكونات.');
 if(s.id==='manal-lasagna-mushroom-20261021b')specificNotes.push('ورق الغار وارد في قائمة المكونات ولم يظهر استعماله في خطوات الطريقة.');
 if(s.id==='manal-chicken-shawarma-20261021b')specificNotes.push('سطر الخبز/المخلل في قائمة المصدر مشوش كما ظهر: `. .. خبز عربي /مخلل`.');
 const recipe={recipeId:s.id,title:s.title,titleBasis:'exact-source-Arabic-title',creatorId:'manal-alalem-official-website',sourceUrl:s.url,evidenceUrl:s.url,sourceKind:'creator-website',sourceVideoId:null,youtubeDerived:false,retrievedAt:'2026-10-21',publishedAt:null,sourceLanguage:'ar',sourceApproval:null,reuseRights:null,clinicalApproval:null,httpBodyHash:null,sourceEvidence:{acquisitionMethod:'direct-http-jsonld-fact-extract',sourceIndex:index,sourceExtractFile:extractPath,sourceExtractSha256:sha(noteText),rawBodyArchived:false,fullPageRetrievedByWorker:true,mediaAccessed:false,transcriptAccessed:false,ingredientListCompleteInExtract:true,methodCompleteInExtract:true,methodSourceStepCount:s.steps.length,sourcePageTitle:s.title,sourceCategory:s.category,sourceCuisine:null,directFetchOutcome:'http-200-jsonld',directFetchRequest:s.request,sourcePageYield:{amount:null,unit:null,sourceText:null,scope:'whole-recipe'},sourcePageTotalTime:{minutes:null,sourceText:null,scope:'whole-recipe'}},methodRepresentation:'concise-Arabic-factual-paraphrase-not-source-text',sourceStepIndexBase:0,sourceStepCount:s.steps.length,cuisine:{value:null,evidence:null,evidenceUrl:s.url,reviewStatus:'pending',status:'source-cuisine-not-stated'},sourceCategory:{value:s.category,evidenceUrl:s.url,status:'source-category-only'},yield:{amount:null,unit:null,sourceText:null},time:{prepMinutes:null,cookMinutes:null,totalMinutes:null,publishedTotalMinutes:null,publishedTotalText:null,publishedTotalEvidence:null,actualElapsedMinutes:null,sourceTimers:[],optionalWaits:[],conflicts:[]},runtimeReady:false,nutrition:null,ingredients:s.ingredients.map((sourceQuantityText,sourceIngredientIndex)=>({labelAr:sourceQuantityText,amount:null,unit:null,sourceQuantityText,group:null,evidenceUrl:s.url,sourceIngredientIndex,optional:null})),supplementalIngredients:[],steps:s.steps.map((textAr,stepIndex)=>({textAr,evidenceUrl:s.url,sourceStepIndices:[stepIndex],sourceStepSegmentIndex:0})),sourceNotes:['مقادير النص الأصلي محفوظة كنص لأن الاستخراج العددي/الوحدات لم يُراجع؛ الحقول الرقمية تظل null.','تصنيف الصفحة محفوظ كفئة مصدر ولا يثبت مطبخاً أو جنسية طبق.',...specificNotes],unknowns:['yield','prep time','cook time','reuse rights','source approval','nutrition','food bindings'],foodBindings:[]};
 recipe.contentSha256=sha(JSON.stringify(sorted(recipe)));
 batch.recipes.push(recipe);
 batch.sourceIndex.push({index,request:s.request,url:s.url,extractFile:extractPath,extractSha256:recipe.sourceEvidence.sourceExtractSha256,outcome:'HTTP 200; complete ingredient list and every numbered method step summarized'});
 batch.requestLog.push({request:s.request,target:s.url,status:200,outcome:`Recipe JSON-LD; complete ingredients (${s.ingredients.length}) and method (${s.steps.length} steps) observed; only factual summaries persisted.`});
}
for(const [request,target,outcome] of [[sitemapNo,'https://www.manalonline.com/sitemap.xml','HTTP 200; sitemap has 2,090 URLs including 2,021 recipe detail URLs; sitemap body not saved']])batch.requestLog.push({request,target,status:200,outcome});
batch.requestLog.sort((a,b)=>a.request-b.request);
batch.underlyingHttpRequestCount=sitemapNo+25;
batch.quotaAtStart={primaryUsedPercent:4,weeklyUsedPercent:13,ordinaryUsageAllowed:true,stopThresholdPercent:98};
batch.quotaChecks.push({phase:25-page retrieval start #,primaryUsedPercent:startP,weeklyUsedPercent:startW,ordinaryUsageAllowed:true},{phase:fter 25-page retrieval #,primaryUsedPercent:endP,weeklyUsedPercent:endW,ordinaryUsageAllowed:true});
batch.sourceAssessmentTargets={webSearchQueries:5,webPageOpens:4,webClicks:2,underlyingWebTargets:11};
batch.counts={records:batch.recipes.length,completeIngredientsAndMethods:batch.recipes.filter(r=>r.sourceEvidence.ingredientListCompleteInExtract&&r.sourceEvidence.methodCompleteInExtract).length,partial:0,duplicates:0,rejected:0,failed:0,sourceIngredients:batch.recipes.reduce((n,r)=>n+r.ingredients.length,0),sourceMethodSteps:batch.recipes.reduce((n,r)=>n+r.steps.length,0),bodySnapshotsArchived:0,runtimeReady:0,nutritionApprovals:0,rightsApprovals:0,exactPriorSourceUrlsSkipped:9};
batch.nextAction='Continue serial 25-recipe checkpoints from remaining sitemap URLs; check quota and access status between batches and preserve complete ingredient/method fact coverage.';
await writeFile(resolve(root,`${dir}/recipes.json`),JSON.stringify(batch,null,2)+'\n',{encoding:'utf8'});
console.log(JSON.stringify({...batch.counts,underlyingHttpRequestCount:batch.underlyingHttpRequestCount,sourceIndex:batch.sourceIndex.length}));
