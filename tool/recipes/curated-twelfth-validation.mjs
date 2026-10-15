import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
import {loadRecipeReviewSnapshots} from './recipe-review-reader.mjs';
import {snapshotFingerprint} from './review-target.mjs';
import {normalize,cookbook,validateDecision} from './curated-local-build.mjs';
import {makePreflight} from './curated-third-build.mjs';
import {auditRecipeImportDraft} from './import-preflight.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
export const folder='data/recipes/curated-local/twelfth-reviewed-20261015';
export const file=folder+'/normalized-recipes.json';
export const sha=v=>createHash('sha256').update(v).digest('hex');
const fmt=v=>JSON.stringify(v,null,2)+'\n';
const need=(v,m)=>{if(!v)throw Error(m)};
const reviewedAt='2026-10-15';
const changeNotice='Two Arabic adaptations of exact Wikibooks revisions already in the local archive; zero network/new book acquisition. CC BY-SA 4.0 attribution and share-alike retained. Category evidence is source-supported only, not approved national cuisine. Unspecified spoon sizes, ingredient alternatives, ranges and unknowns are preserved. Page-specific exceptions and culinary/runtime approval remain unreviewed.';
export const specs=[
 {id:236563,revision:'4518607',nameAr:'يخنة العدس المصرية',family:'egyptian-red-lentil-stew',method:'saute-simmer-lemon',cuisine:['egyptian','مصري','Category:Egyptian recipes'],
 yield:{amount:4,min:4,max:4,unit:'servings',sourceText:'4'},time:{declaredTotalMinutes:null,prepMinutes:20,cookMinutes:60,sourceText:'20 minutes (prep); 1 hour (cook)'},
 ingredients:[
 ['بصل مقشر ومفروم',2,'onion',false,'بصلتان كما في المصدر؛ لا وزن مفترض.'],
 ['زيت زيتون',4,'tbsp',false,'4ملاعق كبيرة دون تحويل إلى حجم أو وزن.'],
 ['ماء',8,'cup',false,'8أكواب؛ نظام حجم الكوب غير محدد.'],
 ['عدس أحمر',0.5,'lb',false,'نصف رطل كما في المصدر؛ لا تحويل إلى جرام.'],
 ['ملح حسب الذوق أو خليط شوربة',null,null,true,'المصدر: ملح حسب الذوق أو4ملاعق كبيرة خليط شوربة ويمكن حذفه؛ لم يُختر بديل ولم يوحد السطر المركب كمكون غذائي.'],
 ['كمون مطحون',1,'tsp',false,'ملعقة صغيرة كما في المصدر.'],
 ['كزبرة مطحونة',1,'tsp',false,'ملعقة صغيرة كما في المصدر.'],
 ['ليمون',1,'lemon',false,'ليمونة كاملة لعصرها؛ مردود العصير مجهول.']
 ],
 steps:[
 'ضعي البصل المفروم في قدر كبير مع4ملاعق كبيرة زيت الزيتون.',
 'شوّحي البصل على نار منخفضة حتى يشفّ ويصبح ذهبيًا قليلًا.',
 'أضيفي8أكواب الماء والعدس والكمون والكزبرة؛ تذكر الخطوة الأصلية خليط الشوربة، بينما بديله مع الملح وحذفه ما زال يحتاج اختيارًا.',
 'قلّبي وارفعِي الحرارة إلى المتوسطة تقريبًا ليظهر غليان خفيف دون غليان شديد.',
 'اتركي الخليط على غليان هادئ ساعة مع التقليب كل بضع دقائق وضبط الحرارة؛ تذوقي وأضيفي الملح عند الحاجة بحسب اختيار المكوّن.',
 'أطفئي الموقد وانقلي القدر إلى موقد آخر حتى لا يستمر الطهي.',
 'اقطعي الليمونة نصفين واعصريها.',
 'أضيفي عصير الليمون إلى القدر وقلّبي.',
 'تذوقي وقدّمي؛ يذكر المصدر إمكانية إضافة كمون وليمون طازج إضافيين حسب التفضيل.'
 ],
 durations:{4:{min:60,max:60,scope:'simmer',approximate:false}},
 supplementalIngredients:[
 {name:'extra cumin to serve',nameAr:'كمون إضافي عند التقديم',amount:null,unit:null,optional:true,included:true,sourceText:'Cumin and more fresh lemon and can be added to the bowl according to preference.',reason:'إضافة اختيارية إجرائية بلا كمية؛ لا تخصم تلقائيًا من الملعقة الأساسية.'},
 {name:'extra fresh lemon to serve',nameAr:'ليمون طازج إضافي عند التقديم',amount:null,unit:null,optional:true,included:true,sourceText:'Cumin and more fresh lemon and can be added to the bowl according to preference.',reason:'إضافة اختيارية إجرائية بلا كمية؛ لا تفترض ليمونة ثانية.'}
 ],
 notes:['الناتج4حصص، والتحضير20دقيقة والطهي ساعة منشوران؛ لا يوجد مجموع منشور ولا زمن مقاس فعليًا، فلا ننتج80دقيقة كحقيقة مصدرية.','القائمة تسمح بملح أو4ملاعق خليط شوربة أوحذفه، لكن الخطوة3تذكر خليط الشوربة ثم تضيف الملح عند الحاجة؛ لم يُحسم الاختيار أو هوية الخليط.','المصدر يسميها يخنة عدس مصرية ويذكر اسم shorbat ads بمعنى حساء عدس؛ لا يثبت ذلك تطابقها مع وصفة كتالوج أخرى أو اختلاف طريقة معتمد.','تصنيف Category:Egyptian recipes دليل المصدر، وليس اعتماد مطبخ وطني أو وصفة سريرية.'],
 blockers:['اختيار الملح/خليط الشوربة وكميته وهوية الخليط والكوب والرطل والتزيين يحتاج مراجعة قبل التحجيم أو الحساب.']},
 {id:129995,revision:'4518126',nameAr:'سلطة قبرصية',family:'cypriot-vegetable-feta-salad',method:'raw-cut-dress',cuisine:['cypriot','قبرصي','Category:Cypriot recipes'],
 yield:{amount:null,min:null,max:null,unit:null,sourceText:null},time:{declaredTotalMinutes:null,prepMinutes:null,cookMinutes:null,sourceText:'غير منشور'},
 ingredients:[
 ['طماطم',1,'tomato',false,'ثمرة واحدة كما وردت؛ حجمها ووزنها غير منشورين.'],
 ['خيار',1,'cucumber',false,'ثمرة واحدة كما وردت؛ حجمها ووزنها غير منشورين.'],
 ['خس',3,'leaf',false,'3أوراق؛ لا وزن مفترض.'],
 ['بصل صغير',1,'onion',false,'بصلة صغيرة واحدة كما في المصدر.'],
 ['جبن فيتا مقطع صغيرًا',1,'spoon-unspecified',false,'المصدر1spoon؛ لا يفترض أنها ملعقة طعام أو صغيرة.'],
 ['زيتون أسود',null,null,false,'المدى5–6حبات محفوظ في النص؛ لم يُختر عدد واحد.'],
 ['زيت زيتون',3,'spoon-unspecified',false,'المصدر3spoons؛ نوع الملعقة وحجمها مجهولان.'],
 ['عصير ليمون',2,'spoon-unspecified',false,'المصدر2spoons؛ نوع الملعقة وحجمها مجهولان.']
 ],
 steps:[
 'قطّعي الخضروات إلى قطع.',
 'ضعيها في وعاء وزينيها بالبصل وجبن الفيتا والزيتون وفق ترتيبك.',
 'قبيل التقديم أضيفي زيت الزيتون والليمون وقلّبي؛ عبارة المصدر add salad في هذه الخطوة ملتبسة ومحفوظة للمراجعة.'
 ],durations:{},supplementalIngredients:[],
 notes:['الناتج والتحضير والطهي والمجموع غير منشورة؛ لا يُخترع زمن صفري لأنها سلطة نيئة.','المدى5–6للزيتون محفوظ؛ لم نحوله إلى5أو6أو5.5.','spoon في مقادير الفيتا والزيت والليمون لا يحدد حجمًا؛ الوحدةspoon-unspecified تبقي هذا الغموض ولا تعنيtbsp.','الخطوة الأخيرة تقول add salad and olive oil with lemon and shake؛ لم تُضف مكونات غير مذكورة لحل الصياغة.','رابط Cuisine of Cyprus وCategory:Cypriot recipes في النص يدعمان نسبة المصدر؛ لا تعتمد تسمية قومية أو مساواة مع سلطة يونانية.'],
 blockers:['مقاس الملعقة ومدى الزيتون والناتج والزمن وصياغة الخطوة الأخيرة تحتاج مراجعة قبل التحجيم أو الحساب.']}
];
const canonTitle=s=>s.normalize('NFC').replace(/[\sـ،؛:!؟.,()[\]{}\u064b-\u065f]/g,'').toLowerCase();
const canonUrl=s=>{const u=new URL(s);u.hostname=u.hostname.replace(/^www\./,'').toLowerCase();if(u.hostname==='youtube.com'&&u.pathname==='/watch')return 'youtube:'+u.searchParams.get('v');return u.origin+decodeURIComponent(u.pathname)+(u.searchParams.has('title')?'?title='+u.searchParams.get('title'):'')};
export async function prior(){
 const manifest=JSON.parse(await readFile(resolve(root,'data/recipes/curated-local/flutter-manifest.json'),'utf8'));
 const rows=[],packs=[];
 for(const p of manifest.packs){if(p.file===file)continue;const bytes=await readFile(resolve(root,p.file));need(sha(bytes)===p.sha256,'Prior manifest pin drift: '+p.file);const b=JSON.parse(bytes);rows.push(...b.recipes);packs.push({file:p.file,sha256:sha(bytes)});}
 return {rows,packs};
}
export function dedup(records,previous){
 const ids=new Set(previous.map(r=>r.id??r.recipeId)),families=new Set(previous.map(r=>r.familyId).filter(Boolean)),titles=new Set(previous.flatMap(r=>[r.name,r.nameAr,r.title].filter(Boolean).map(canonTitle))),urls=new Set(previous.map(r=>r.sourceUrl??r.provenance?.sourceUrl).filter(Boolean).map(canonUrl));
 for(const r of records){need(!ids.has(r.id),'Duplicate source identity');need(!families.has(r.familyId),'Duplicate family');need(!titles.has(canonTitle(r.name))&&!titles.has(canonTitle(r.nameAr)),'Duplicate title');need(!urls.has(canonUrl(r.provenance.sourceUrl)),'Duplicate source URL');ids.add(r.id);families.add(r.familyId);titles.add(canonTitle(r.name));titles.add(canonTitle(r.nameAr));urls.add(canonUrl(r.provenance.sourceUrl));}
}
function decision(spec,source){
 need(source.recipe.ingredients.length===spec.ingredients.length&&source.recipe.steps.length===spec.steps.length,'Source shape mismatch');
 return {sourcePageId:spec.id,sourceRecordId:source.recordId,sourceSha256:source.sourceSha256,derivedRecipeSha256:snapshotFingerprint(source),nameAr:spec.nameAr,status:'needs-review',family:spec.family,method:spec.method,cuisines:[spec.cuisine],yield:spec.yield,time:spec.time,ingredients:spec.ingredients.map((x,i)=>[i,x[0],source.recipe.ingredients[i].name,x[1],x[2],x[3],x[4]]),steps:spec.steps.map((s,i)=>[[i],s,spec.durations[i]??null]),supplementalIngredients:spec.supplementalIngredients,notes:spec.notes,blockers:spec.blockers};
}
export async function build(){
 const {recipes,evidence}=await loadRecipeReviewSnapshots();
 const rawBytes=await readFile(resolve(root,'data/recipes/bulk/wikibooks-cookbook/source-pages.jsonl'));
 const rawMap=new Map(rawBytes.toString('utf8').split(/\r?\n/).filter(Boolean).map(JSON.parse).map(r=>[r.sourcePageId,r]));
 const previous=await prior(),records=[],decisions=[],drafts=[];
 const dest=resolve(root,folder);await mkdir(resolve(dest,'source-snapshots'),{recursive:true});await mkdir(resolve(dest,'preflight-drafts'),{recursive:true});
 for(const spec of specs){
  const source=recipes.get('wikibooks:'+spec.id),raw=rawMap.get(spec.id);
  need(source&&raw&&String(raw.sourceRevision)===spec.revision&&raw.sourceSha256===sha(raw.sourceWikitext)&&source.sourceSha256===raw.sourceSha256,'Current archive source drift');
  need(raw.sourceCategories.includes(spec.cuisine[2]),'Source category evidence missing');
  const d=decision(spec,source);validateDecision(d,source,raw);decisions.push(d);
  const bytes=fmt({schemaVersion:1,sourceRecord:raw,authoritativeParsedRecipe:source,authoritativeEvidence:evidence}),snapshotFile=folder+'/source-snapshots/'+spec.id+'.json';
  try{need(await readFile(resolve(root,snapshotFile),'utf8')===bytes,'Immutable snapshot drift')}catch(e){if(e.code!=='ENOENT')throw e;await writeFile(resolve(root,snapshotFile),bytes,{flag:'wx'});}
  const provenance={sourceId:source.sourceId,recordId:source.recordId,sourceRevision:source.sourceRevision,sourceRevisionTimestamp:raw.sourceRevisionTimestamp,retrievedAt:raw.retrievedAt,sourceUrl:source.sourceUrl,sourceSha256:source.sourceSha256,derivedRecipeSha256:snapshotFingerprint(source),sourceSnapshotFile:snapshotFile,sourceSnapshotSha256:sha(bytes),license:source.license,licenseSha256:snapshotFingerprint(source.license),changeNotice};
  const r=normalize(d,source,raw,provenance);r.contentSha256=snapshotFingerprint(r);records.push(r);
  const draft=makePreflight(r,source,reviewedAt),draftBytes=fmt(draft),draftFile=folder+'/preflight-drafts/'+spec.id+'.json';
  await writeFile(resolve(root,draftFile),draftBytes);
  drafts.push({curatedRecipeId:r.id,draftFile,draftSha256:sha(draftBytes),...auditRecipeImportDraft(source,draft)});
 }
 dedup(records,previous.rows);
 const priorLabels=new Set(previous.rows.flatMap(r=>(r.cuisines??[]).map(c=>c.id)));
 const counts={recipes:2,ingredientLines:records.reduce((n,r)=>n+r.ingredients.length,0),supplementalIngredients:records.reduce((n,r)=>n+r.supplementalIngredients.length,0),steps:records.reduce((n,r)=>n+r.steps.length,0),fullySpecified:0,needsReview:2,notCookable:0,sourceSupportedCuisineLabels:new Set(records.flatMap(r=>r.cuisines.map(c=>c.id))).size,runtimeReady:0};
 const newLabels=[...new Set(records.flatMap(r=>r.cuisines.map(c=>c.id)))].filter(id=>!priorLabels.has(id));
 const pack={schemaVersion:1,reviewedAt,reviewer:'Bounded offline archived-source Arabic transcription; no kitchen testing',changeNotice,sourceEvidence:evidence,sourceCount:2,recipes:records,relationships:[],counts,duplicateReview:{scope:'All current selected manifest packs, exact source identity/URL, normalized English/Arabic title and family; no global6056unique-dishes claim',priorPacks:previous.packs.length,priorRecords:previous.rows.length,duplicateSourceIds:0,duplicateTitles:0,duplicateFamilies:0,crossLanguageDuplicateReview:'not exhaustive; source distinctness is not global dish uniqueness'}};
 const report={schemaVersion:1,reviewedAt,networkRequests:0,newBooks:0,quotaAtStart:{primaryUsedPercent:69,weeklyUsedPercent:11,ordinaryUsageAllowed:true},counts,newLabels,selectedSourcePageIds:specs.map(s=>s.id),frozenPacks:previous.packs,priorRecords:previous.rows.length,priorLocalRecords:previous.rows.filter(r=>r.id?.startsWith('curated-local:')).length,priorSourceLabels:priorLabels.size,draftComplete:0,runtimeReady:0,draftIssues:drafts.reduce((n,r)=>n+r.issues.length,0),newDraftReports:drafts,remainingGates:['independent culinary and page-specific license review','ingredient alternatives/spoon/range/quantity/time/yield review','food identity/form/scaling/nutrition and runtime approval']};
 await writeFile(resolve(dest,'review-decisions.json'),fmt({schemaVersion:1,reviewedAt,reviewer:pack.reviewer,changeNotice,recipes:decisions}));
 await writeFile(resolve(dest,'normalized-recipes.json'),fmt(pack));await writeFile(resolve(dest,'review-report.json'),fmt(report));
 const human={...pack,recipes:pack.recipes.map(r=>({...r,yield:{...r.yield,sourceText:r.yield.sourceText??'غير منشور',unit:r.yield.unit??'غير محدد'}}))};
 await writeFile(resolve(dest,'COOKBOOK.ar.md'),cookbook(human).replace('# أول مجموعة وصفات من الأرشيف المحلي','# الدفعة الثانية عشرة — تكييف وصفتين من الأرشيف الموجود'));
 return actual();
}
export function validateRecord(r,snapshot,expected,source){
 const raw=snapshot.sourceRecord,parsed=snapshot.authoritativeParsedRecipe,p=r.provenance;
 need(p.sourceId==='wikibooks-cookbook-cc-by-sa'&&p.recordId===raw.recordId&&String(p.sourceRevision)===expected.revision&&p.sourceSha256===sha(raw.sourceWikitext)&&p.sourceSha256===source.sourceSha256,'Source identity/revision/hash drift');
 need(snapshotFingerprint(parsed)===snapshotFingerprint(source)&&p.derivedRecipeSha256===snapshotFingerprint(source),'Current parsed source drift');
 need(snapshotFingerprint(p.license)===snapshotFingerprint(source.license)&&p.licenseSha256===snapshotFingerprint(source.license)&&p.license.pageExceptionStatus==='not-reviewed-per-page','License drift');
 need(r.status==='needs-review'&&r.runtimeReady===false&&r.nutrition===null&&r.actuallyKitchenTested===false&&r.gates.independentCulinaryApproval===false&&r.gates.perPageLicenseApproved===false&&r.gates.nutritionApproved===false,'No inferred readiness/approval');
 need(r.cuisines.length===1&&r.cuisines[0].evidenceText===expected.cuisine[2]&&raw.sourceCategories.includes(r.cuisines[0].evidenceText)&&r.cuisines[0].reviewStatus==='source-supported-not-runtime-approved','Exact source category required');
 need(r.ingredients.length===source.recipe.ingredients.length&&r.ingredients.length===expected.ingredients.length,'Ingredient mapping drift');
 r.ingredients.forEach((g,i)=>{need(g.sourceLineIndex===i&&g.sourceText===source.recipe.ingredients[i].sourceText&&g.target.sourceSha256===source.sourceSha256&&g.target.derivedRecipeSha256===snapshotFingerprint(source),'Source line target drift');need(JSON.stringify([g.amount,g.unit,g.optional])===JSON.stringify(expected.ingredients[i].slice(1,4)),'Quantity/range/choice drift');need(g.foodBinding===null&&g.scales===null,'No inferred food/scaling');});
 need(snapshotFingerprint(r.yield)===snapshotFingerprint(expected.yield)&&snapshotFingerprint(r.time)===snapshotFingerprint(expected.time),'Source yield/time unknown drift');
 need(r.steps.length===source.recipe.steps.length&&r.steps.every((s,i)=>s.textAr===expected.steps[i]&&JSON.stringify(s.sourceStepIndices)===JSON.stringify([i])),'Every source step mapped once');
 need(snapshotFingerprint(r.supplementalIngredients.map(({foodBinding,...g})=>g))===snapshotFingerprint(expected.supplementalIngredients)&&r.supplementalIngredients.every(g=>g.foodBinding===null),'Procedural optional unknown drift');
 const {contentSha256,...body}=r;need(snapshotFingerprint(body)===contentSha256,'Normalized content drift');
 return true;
}
export async function actual(){
 const bytes=await readFile(resolve(root,file)),pack=JSON.parse(bytes),report=JSON.parse(await readFile(resolve(root,folder+'/review-report.json'),'utf8'));
 need(pack.recipes.length===2&&report.networkRequests===0&&report.newBooks===0,'Exactly two offline records required');
 const {recipes,evidence}=await loadRecipeReviewSnapshots(),previous=await prior();
 const rawMap=new Map((await readFile(resolve(root,'data/recipes/bulk/wikibooks-cookbook/source-pages.jsonl'),'utf8')).split(/\r?\n/).filter(Boolean).map(JSON.parse).filter(r=>specs.some(s=>s.id===r.sourcePageId)).map(r=>[r.sourcePageId,r]));
 need(snapshotFingerprint(pack.sourceEvidence)===snapshotFingerprint(evidence),'Current archive bank evidence drift');
 for(let i=0;i<2;i++){
  const r=pack.recipes[i],snapBytes=await readFile(resolve(root,r.provenance.sourceSnapshotFile));
  need(sha(snapBytes)===r.provenance.sourceSnapshotSha256,'Raw snapshot bytes drift');
  need(snapshotFingerprint(JSON.parse(snapBytes).sourceRecord)===snapshotFingerprint(rawMap.get(specs[i].id)),'Current full raw archive record drift');
  validateRecord(r,JSON.parse(snapBytes),specs[i],recipes.get('wikibooks:'+specs[i].id));
  const d=report.newDraftReports[i],draftBytes=await readFile(resolve(root,d.draftFile));
  need(sha(draftBytes)===d.draftSha256&&d.runtimeReady===false,'Draft pin/approval drift');
 }
 dedup(pack.recipes,previous.rows);
 return {pack,report,summary:{...pack.counts,newLabels:report.newLabels,networkRequests:0,newBooks:0,priorPacksChecked:previous.packs.length,priorRecordsChecked:previous.rows.length,draftIssues:report.draftIssues,packSha256:sha(bytes)}};
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){const a=process.argv.includes('--build')?await build():await actual();console.log(JSON.stringify(a.summary));}
