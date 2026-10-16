import {readFile,writeFile,mkdir,readdir,open,unlink,stat} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {resolve,join,relative} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../../',import.meta.url));
export const folder='data/recipes/curated-local/based-cooking-20261015';
const cache='E:/work/SOFRA/source-cache/based-cooking-data',repo='https://github.com/LukeSmithxyz/based.cooking';
const dest=resolve(root,folder),checkpoint=join(dest,'checkpoint.json');
export const sha=v=>createHash('sha256').update(v).digest('hex');
const fmt=v=>JSON.stringify(v,null,2)+'\n';
const need=(v,m)=>{if(!v)throw Error(m)};
const norm=s=>s.normalize('NFKC').toLowerCase().replace(/https?:\/\/\S+/g,'').replace(/[^\p{L}\p{N}]/gu,'');
export function quotaGuard(q,now=Date.now()){
 need(q?.ordinary===true&&[q.primary,q.weekly].every(v=>typeof v==='number'&&v>=0&&v<99),'Actual eligible quota required');
 const age=now-Date.parse(q.capturedAt);need(Number.isFinite(age)&&age>=0&&age<=30000,'Quota evidence must be <=30seconds old');
}
export function parseMarkdown(raw,path='recipe.md'){
 const lines=raw.replace(/^\uFEFF/,'').replace(/\r\n/g,'\n').split('\n');let title=null,tags=[],front='',start=0;
 if(lines[0]==='---'){const end=lines.indexOf('---',1);if(end<0)return null;front=lines.slice(1,end).join('\n');start=end+1;const t=front.match(/^title:\s*(.+)$/m);if(t)title=t[1].replace(/^["']|["']$/g,'');const ts=front.match(/^tags:\s*\[([^\]]*)\]/m);if(ts)tags=ts[1].split(',').map(v=>v.trim().replace(/^["']|["']$/g,'')).filter(Boolean);}
 let section=null,sectionLevel=0,group=null;const ingredients=[],steps=[],notes=[];let current=null;
 const flush=()=>{if(current){steps.push(current);current=null}};
 for(let i=start;i<lines.length;i++){
  const l=lines[i].trim(),h=l.match(/^(#{1,6})\s+(.+?)(?:\s*#+)?$/);
  if(h){flush();const name=h[2].trim();if(h[1].length===1&&!title)title=name;
   if(section&&h[1].length>sectionLevel){group=name;notes.push({text:name,sourceLineNumber:i+1,scope:section==='i'?'ingredient-group':'method-group'});continue}
   sectionLevel=h[1].length;group=null;section=/^ingredients?\s*:?\s*$/i.test(name)?'i':/^(?:(?:prep|cooking)\s+)?(?:directions?|instructions?|procedure|preparation|method)(?:\s*\([^)]*\))?\s*:?\s*$/i.test(name)?'s':'other';continue;}
  if(!l){if(section==='s')flush();continue}if(/^!\[/.test(l))continue;
  if(section==='i'){const m=l.match(/^[-*+]\s+(.+)/);if(m)ingredients.push({sourceText:m[1],sourceLineNumber:i+1,sourceGroup:group});}
  else if(section==='s'){
   const m=l.match(/^(?:\d+[.)]|[-*+])\s+(.+)/);
   if(m){flush();current={text:m[1],sourceLineNumbers:[i+1]};}
   else if(current){current.text+=' '+l;current.sourceLineNumbers.push(i+1);}
   else current={text:l,sourceLineNumbers:[i+1]};
  }
 }
 flush();
 if(!title||!ingredients.length||!steps.length||/(^|\/)(?:_index|index|example)\.md$/i.test(path))return null;
 return {title,tags,frontMatter:front,ingredients,steps,methodNotes:notes};
}
export function contentKey(r){return sha(norm(r.ingredients.map(g=>g.sourceText??g.name??g.labelAr??'').join('\n'))+'|'+norm(r.steps.map(s=>s.text??s.textAr??s).join('\n')))}
export function selectUnique(candidates,prior=[]){
 const keys=new Set(),urls=new Set(),ids=new Set();
 for(const r of prior){if(r.ingredients?.length&&r.steps?.length)keys.add(contentKey(r));const u=r.sourceUrl??r.provenance?.sourceUrl;if(u)urls.add(u.replace(/[?#].*$/,''));ids.add(r.id??r.recipeId);}
 const accepted=[],rejected=[];
 for(const r of candidates){const k=contentKey(r),canonical=r.canonicalUrl.replace(/[?#].*$/,'');const reason=ids.has(r.id)?'duplicate-id':urls.has(canonical)?'duplicate-canonical-url':keys.has(k)?'duplicate-normalized-ingredient-method-content':null;
  if(reason){rejected.push({path:r.path,reason});continue}keys.add(k);urls.add(canonical);ids.add(r.id);accepted.push(r)}
 return {accepted,rejected};
}
export function sourceProof(raw,path,commit,timestamp,collectedAt,license){
 need(/^[a-f0-9]{40}$/.test(commit)&&path.startsWith('content/')&&path.endsWith('.md')&&!path.includes('..'),'Invalid source pin');
 return {schemaVersion:1,recordId:'based-cooking:'+commit+':'+path,sourceId:'based-cooking',sourceRevision:commit,sourceRevisionTimestamp:timestamp,sourceUrl:'https://github.com/LukeSmithxyz/based.cooking/blob/'+commit+'/'+path,sourceSha256:sha(raw),retrievedAt:collectedAt,sourcePath:path,sourceText:raw,rawGitText:raw,license};
}
export function assertPinnedText(working,pinned){need(sha(working)===sha(pinned),'Source cache working text drift')}
export function assertPinnedCommit(checkpointCommit,head){need(/^[a-f0-9]{40}$/.test(checkpointCommit)&&head===checkpointCommit,'Source checkpoint/HEAD commit drift')}
function git(args,{offline=false,rawOutput=false}={}){
 const r=spawnSync('git',['-c','credential.helper=','-c','http.extraHeader=','-c','core.autocrlf=false','-c','core.hooksPath=NUL',...args],{cwd:root,encoding:'utf8',maxBuffer:4*1024*1024,env:{...process.env,GIT_TERMINAL_PROMPT:'0',...(offline?{GIT_NO_LAZY_FETCH:'1'}:{})}});
 if(r.status!==0)throw Error((r.stderr||r.stdout||'Git failure').replace(/https?:\/\/[^@\s]+@/g,'https://[redacted]@'));
 return rawOutput?r.stdout:r.stdout.trim();
}
async function locked(run){await mkdir(dest,{recursive:true});const lock=join(dest,'collector.lock');const h=await open(lock,'wx');try{await h.writeFile(fmt({pid:process.pid,startedAt:new Date().toISOString(),cache}));return await run()}finally{await h.close();await unlink(lock)}}
async function previous(){try{return JSON.parse(await readFile(checkpoint,'utf8'))}catch(e){if(e.code!=='ENOENT')throw e;return {schemaVersion:1,sourceId:'based-cooking',targetRecipes:1000,networkOperations:[]}}}
export async function acquire(phase,q){
 return locked(async()=>{
  const cp=await previous();need(!cp.refusal&&!cp.failedAt,'Previous source failure requires explicit review, no automatic retry');
  quotaGuard(q);cp.networkOperations.push({operation:phase,startedAt:new Date().toISOString(),quota:q,status:'attempting',httpRequestCount:null});await writeFile(checkpoint,fmt(cp));
  try{
   if(phase==='clone'){
    try{await stat(cache);throw Error('Source cache already exists; inspect before reuse')}catch(e){if(e.code!=='ENOENT')throw e}
    await mkdir(resolve(cache,'..'),{recursive:true});quotaGuard(q);
    git(['clone','--filter=blob:none','--no-checkout','--depth','1',repo,cache]);
   }else if(phase==='checkout'){
    need(git(['-C',cache,'remote','get-url','origin']).toLowerCase()===repo.toLowerCase(),'Unexpected source-cache origin');
    git(['-C',cache,'sparse-checkout','init','--no-cone']);
    await writeFile(join(cache,'.git/info/sparse-checkout'),'/content/*.md\n/README.md\n/LICENSE.md\n');
    quotaGuard(q);git(['-C',cache,'read-tree','-mu','HEAD']);
   }else throw Error('Unknown acquisition phase');
   cp.networkOperations.at(-1).status='completed';cp.lastCompletedAt=new Date().toISOString();cp.sourceCommit=git(['-C',cache,'rev-parse','HEAD']);await writeFile(checkpoint,fmt(cp));return cp;
  }catch(e){cp.networkOperations.at(-1).status='failed';cp.failedAt=new Date().toISOString();cp.failure=String(e.message);cp.retryPolicy='stop; no automatic retry/alternate source or host';await writeFile(checkpoint,fmt(cp));throw e}
 });
}
async function markdownFiles(dir){const out=[];for(const e of await readdir(dir,{withFileTypes:true})){const p=join(dir,e.name);if(e.isDirectory())out.push(...await markdownFiles(p));else if(e.isFile()&&e.name.endsWith('.md'))out.push(p)}return out.sort()}
export async function build(){
 return locked(async()=>{
 const cp=await previous();need(cp.networkOperations.some(o=>o.operation==='checkout'&&o.status==='completed'),'Sparse acquisition not completed');
 const commit=cp.sourceCommit;assertPinnedCommit(commit,git(['-C',cache,'rev-parse','HEAD'],{offline:true}));const timestamp=git(['-C',cache,'show','-s','--format=%cI',commit],{offline:true}),collectedAt=new Date().toISOString();
 const pinnedText=async path=>{const pinned=git(['-C',cache,'show',commit+':'+path],{offline:true,rawOutput:true});assertPinnedText(await readFile(join(cache,path),'utf8'),pinned);return pinned};
 const readme=await pinnedText('README.md'),licenseText=await pinnedText('LICENSE.md');
 need(/website and all its content is in the public domain/i.test(readme),'First-party all-content public-domain declaration missing');
 await writeFile(join(dest,'README.source.md'),readme);await writeFile(join(dest,'LICENSE.source.md'),licenseText);
 const license={id:'based-cooking-public-domain-declaration',name:'Publisher public-domain declaration; repository Unlicense',evidenceUrl:'https://github.com/LukeSmithxyz/based.cooking/blob/'+commit+'/README.md',policyStatus:'first-party-all-content-declaration',pageExceptionStatus:'not-reviewed-per-page',readmeSha256:sha(readme),licenseTextSha256:sha(licenseText),attribution:'Retain repository commit/path and contributor metadata; no endorsement or runtime approval'};
 const manifest=JSON.parse(await readFile(resolve(root,'data/recipes/curated-local/flutter-manifest.json'),'utf8'));const prior=[];
 for(const p of manifest.packs){if(p.file===folder+'/normalized-recipes.json')continue;const b=await readFile(resolve(root,p.file));need(sha(b)===p.sha256,'Prior pack hash drift');prior.push(...JSON.parse(b).recipes)}
 const files=git(['-C',cache,'ls-tree','-r','--name-only',commit,'--','content/'],{offline:true}).split('\n').filter(p=>p.startsWith('content/')&&p.endsWith('.md')).sort(),candidates=[],rejected=[];
 for(const rel of files){const raw=await pinnedText(rel),parsed=parseMarkdown(raw,rel);if(!parsed){rejected.push({path:rel,reason:'no-complete-ingredient-and-method-or-metadata-page'});continue}candidates.push({...parsed,path:rel,raw,id:'based-cooking:'+rel.replace(/^content\/|\.md$/g,''),canonicalUrl:'https://based.cooking/'+rel.replace(/^content\/|\.md$/g,'')+'/'})}
 const chosen=selectUnique(candidates,prior);rejected.push(...chosen.rejected);await mkdir(join(dest,'source-snapshots'),{recursive:true});const records=[];
 for(const r of chosen.accepted){
  const proof=sourceProof(r.raw,r.path,commit,timestamp,collectedAt,license),snapshot={schemaVersion:1,sourceRecord:proof,parsedSource:{title:r.title,ingredients:r.ingredients,steps:r.steps,methodNotes:r.methodNotes,sourceTags:r.tags,frontMatter:r.frontMatter}},bytes=fmt(snapshot),name=r.id.slice('based-cooking:'.length).replaceAll('/','--')+'.json',snapshotFile=folder+'/source-snapshots/'+name;
  await writeFile(resolve(root,snapshotFile),bytes);
  const provenance={...Object.fromEntries(['recordId','sourceId','sourceRevision','sourceRevisionTimestamp','sourceUrl','sourceSha256','retrievedAt','license'].map(k=>[k,proof[k]])),sourceSnapshotFile:snapshotFile,sourceSnapshotSha256:sha(bytes),changeNotice:'Source-English Markdown extraction; unknown quantities/times/yield and unreviewed tags retained. No Arabic translation, food matching or nutrition approval.'};
  const row={id:r.id,recordVersion:1,name:r.title,nameAr:null,sourceLanguage:'en',translationStatus:'not-translated',status:'needs-review',familyId:null,methodId:null,cuisines:[],yield:{amount:null,unit:null,sourceText:null},time:{declaredTotalMinutes:null,prepMinutes:null,cookMinutes:null,sourceText:null},ingredients:r.ingredients.map((g,i)=>({sourceLineIndex:i,name:g.sourceText,nameAr:null,sourceText:g.sourceText,sourceMarkdownLine:g.sourceLineNumber,sourceGroup:g.sourceGroup??null,amount:null,unit:null,optional:null,included:null,quantityPrecision:'unaccepted-source-text',foodBinding:null,scales:null})),supplementalIngredients:[],steps:r.steps.map((s,i)=>({n:i+1,text:s.text,textAr:null,sourceStepIndices:[i],sourceMarkdownLines:s.sourceLineNumbers,duration:null})),sourceMethodNotes:r.methodNotes,sourceTags:r.tags,notes:['Source English; every numeric quantity/time/yield requires explicit review. Tags not promoted to cuisine/clinical evidence. Optionality/alternatives remain in source text.'],blockers:['independent culinary/quantity/form/scaling/rights review'],provenance,nutrition:null,runtimeReady:false,actuallyKitchenTested:false,gates:{culinarySourceTranscription:true,independentCulinaryApproval:false,perPageLicenseApproved:false,inventoryIdentityApproved:false,nutritionApproved:false}};
  row.contentSha256=sha(JSON.stringify(row));records.push(row);
 }
 const counts={recipes:records.length,ingredientLines:records.reduce((n,r)=>n+r.ingredients.length,0),supplementalIngredients:0,steps:records.reduce((n,r)=>n+r.steps.length,0),fullySpecified:0,needsReview:records.length,notCookable:0,sourceSupportedCuisineLabels:0,runtimeReady:0};
 const pack={schemaVersion:1,translationStatus:'not-translated',reviewedAt:collectedAt,reviewer:'Actual modern public-domain repository acquisition; source-English unreviewed',changeNotice:'New based.cooking source acquisition, not existing Wikibooks reprocessing',sourceCount:records.length,recipes:records,relationships:[],counts,sourceEvidence:{sourceId:'based-cooking',commit,commitTimestamp:timestamp,readmeSha256:sha(readme),licenseSha256:sha(licenseText)},duplicateReview:{priorRecordsChecked:prior.length,selectedPackCount:manifest.packs.length,scope:'canonical URL/id plus normalized ingredient+method content; no unique dish guarantee'}};
 const report={schemaVersion:1,sourceId:'based-cooking',targetRecipes:1000,actualAcquiredMarkdownFiles:files.length,accepted:records.length,rejected:rejected.length,rejections:rejected,counts,sourceCommit:commit,sourceTimestamp:timestamp,collectedAt,sourceOnlyValidRecipes:records.length,targetMet:records.length>=1000,shortfall:Math.max(0,1000-records.length),reason:records.length>=1000?'target-met':'source-only-'+records.length+'-accepted-recipes-under-parser-and-dedup; minimum1000notmet',priorRecordsChecked:prior.length,networkOperations:cp.networkOperations,httpRequestCount:null,newAcquisition:true,existingArchivesRecounted:0,rightsRuntimeApproval:false};
 await writeFile(join(dest,'normalized-recipes.json'),fmt(pack));await writeFile(join(dest,'acquisition-report.json'),fmt(report));cp.completedAt=collectedAt;cp.accepted=records.length;cp.shortfall=report.shortfall;await writeFile(checkpoint,fmt(cp));return {...report,packSha256:sha(fmt(pack))};
 });
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 const [phase,p,w,o,t]=process.argv.slice(2);const out=phase==='build'?await build():await acquire(phase,{primary:Number(p),weekly:Number(w),ordinary:o==='true',capturedAt:t});console.log(JSON.stringify(out));
}
