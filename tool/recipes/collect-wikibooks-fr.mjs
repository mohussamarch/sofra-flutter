#!/usr/bin/env node
// Separate research lane: no English cursor, runtime recipe, quantity or food binding changes.
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile,appendFile,rename,open,unlink,readdir} from 'node:fs/promises';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const ROOT=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
export const FRENCH_SOURCE=Object.freeze({
  sourceId:'fr-wikibooks-cuisine-cc-by-sa',sourceLanguage:'fr',namespace:0,
  prefix:'Livre de cuisine/',api:'https://fr.wikibooks.org/w/api.php',
  license:Object.freeze({id:'fr-wikibooks-cc-by-sa-4.0',name:'Creative Commons Attribution-Share Alike 4.0',
    url:'https://creativecommons.org/licenses/by-sa/4.0/deed.fr',
    evidenceUrl:'https://fr.wikibooks.org/w/api.php?action=query&meta=siteinfo&siprop=rightsinfo&format=json&formatversion=2',
    evidenceArchive:'data/recipes/source-discovery/fr-wikibooks/01-siteinfo.json',
    policyStatus:'verified-site-policy',pageExceptionStatus:'not-reviewed-per-page',
    attribution:'Link each source revision and its contributor history; indicate extraction/modification. Keep CC BY-SA 4.0 notice and share adaptations under the applicable licence.',
    changeNoticeRequired:true,shareAlikeRequired:true}),
});
const HASH=s=>createHash('sha256').update(s,'utf8').digest('hex');
const need=(ok,message)=>{if(!ok)throw new Error(message);};
const MAX_REQUESTS=10, PAGE_BATCH=20, INTERVAL=2000, COOLDOWN=600000;
function validateContinuation(value){
  need(value===null||typeof value==='object'&&!Array.isArray(value)&&
    Object.keys(value).every(k=>['apcontinue','continue'].includes(k))&&
    typeof value.apcontinue==='string'&&value.apcontinue.replaceAll('_',' ').startsWith(FRENCH_SOURCE.prefix)&&
    typeof value.continue==='string','Invalid French listing continuation');
}
function acceptListing(data,cp){
  need(Array.isArray(data.query?.allpages),'French response omitted prefix listing');
  const pages=data.query.allpages;for(const p of pages){need(p.ns===0&&Number.isSafeInteger(p.pageid)&&p.pageid>0&&p.title?.startsWith(FRENCH_SOURCE.prefix),'Invalid French prefix listing');}
  need(pages.length||!data.continue,'Empty French listing with continuation');validateContinuation(data.continue??null);
  cp.pendingPageIds=[...new Set(pages.map(p=>String(p.pageid)))];cp.pendingTitles=Object.fromEntries(pages.map(p=>[String(p.pageid),p.title]));
  cp.listingContinuation=data.continue??null;cp.listingExhausted=!data.continue;
}
async function maybeRead(path,fallback=''){try{return await readFile(path,'utf8');}catch(e){if(e.code==='ENOENT')return fallback;throw e;}}
async function jsonWrite(path,value){const temp=`${path}.${process.pid}.tmp`;await writeFile(temp,JSON.stringify(value,null,2)+'\n','utf8');await rename(temp,path);}
async function readRecoverableRecords(out,cp){
  const path=resolve(out,'source-pages.jsonl');let bytes;try{bytes=await readFile(path);}catch(e){if(e.code!=='ENOENT')throw e;bytes=Buffer.alloc(0);}
  const raw=bytes.toString('utf8'),lines=raw.split('\n'),records=[];
  for(let i=0;i<lines.length;i++){
    if(!lines[i].trim())continue;
    try{records.push(JSON.parse(lines[i]));}catch(e){
      // Only an unterminated last append is recoverable, and only while its request remains pending.
      if(i!==lines.length-1||raw.endsWith('\n')||!cp.pendingPageIds.length)throw e;
      buildFrenchIndex(records);const offset=bytes.lastIndexOf(10)+1,tail=bytes.subarray(offset);await mkdir(resolve(out,'recovery'),{recursive:true});
      await jsonWrite(resolve(out,'recovery',`${HASH(tail)}.json`),{reason:'torn-final-append',tailBytesBase64:tail.toString('base64'),tailSha256:HASH(tail),pendingPageIds:cp.pendingPageIds});
      const temp=`${path}.${process.pid}.tmp`;
      await writeFile(temp,bytes.subarray(0,offset));await rename(temp,path);return records;
    }
  }
  buildFrenchIndex(records);
  if(raw&&!raw.endsWith('\n'))await appendFile(path,'\n','utf8');
  return records;
}
const clean=line=>line.trim().replace(/^\s*[*#;:]+\s*/,'').replace(/'''?/g,'')
  .replace(/\[\[([^\]|]+)\|([^\]]+)\]\]/g,'$2').replace(/\[\[([^\]]+)\]\]/g,'$1')
  .replace(/<[^>]*>/g,'').replace(/\{\{[^{}]*\}\}/g,'').replace(/&nbsp;/g,' ').trim();
const normalized=s=>clean(s).normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();

export function parseFrenchRecipe(wikitext){
  const text=wikitext.replace(/<!--[\s\S]*?-->/g,'').replace(/<nowiki\b[^>]*>[\s\S]*?<\/nowiki\s*>/gi,'').replace(/<nowiki\b[^>]*\/\s*>/gi,'');
  const ingredients=[],steps=[];let section=null,level=0,groups=[];
  for(const line of text.split(/\r?\n/)){
    const h=line.match(/^\s*(={2,6})\s*(.*?)\s*\1\s*$/);
    if(h){const l=h[1].length,title=normalized(h[2]);
      if(section&&l<=level){section=null;groups=[];}
      if(!section){
        if(/^ingredients(?:\s*\(.*\))?$/.test(title)){section='ingredients';level=l;}
        else if(['preparation','preparations','realisation','procedure','instructions','methode'].includes(title)){section='steps';level=l;}
      }else if(section==='ingredients'){
        groups=groups.filter(g=>g.level<l);groups.push({level:l,title:clean(h[2]),sourceHeading:line});
      }
      continue;
    }
    if(!section||!/^\s*[*#]+\s*/.test(line))continue;
    const sourceText=clean(line);if(!sourceText)continue;
    if(section==='ingredients')ingredients.push({lineIndex:ingredients.length,sourceText,sourceGroupPath:groups.map(g=>({...g}))});
    else steps.push(sourceText);
  }
  return {ingredients,steps};
}
const key=(id,revision)=>`fr-wikibooks-${id}-r${revision}`;
const sourceUrl=(title,revision)=>`https://fr.wikibooks.org/w/index.php?title=${encodeURIComponent(title)}&oldid=${revision}`;
export function recordFrenchPage(page,retrievedAt){
  need(page.ns===0,'Unexpected French namespace');
  need(typeof page.title==='string'&&page.title.startsWith(FRENCH_SOURCE.prefix),'Unexpected French prefix');
  need(Number.isSafeInteger(page.pageid)&&page.pageid>0,'Invalid French page identity');
  const rev=page.revisions?.[0],raw=rev?.slots?.main?.content??rev?.slots?.main?.['*'];
  need(Number.isSafeInteger(rev?.revid)&&rev.revid>0,'Missing French revision');
  need(typeof raw==='string'&&raw.length>0,'Missing French source content');
  need(Number.isFinite(Date.parse(retrievedAt))&&Number.isFinite(Date.parse(rev.timestamp)),'Invalid source date');
  const parsed=parseFrenchRecipe(raw);
  const categories=[...new Set([...raw.replace(/<!--[\s\S]*?-->/g,'').replace(/<nowiki\b[^>]*>[\s\S]*?<\/nowiki\s*>/gi,'')
    .matchAll(/\[\[\s*Cat[ée]gorie:([^\]|\n]+)(?:\|[^\]]*)?\]\]/gi)].map(m=>`Catégorie:${m[1].trim().replaceAll('_',' ')}`))].sort();
  return {schemaVersion:1,recordId:key(page.pageid,rev.revid),sourceId:FRENCH_SOURCE.sourceId,sourceLanguage:'fr',
    sourcePageId:page.pageid,sourceRevision:String(rev.revid),sourceRevisionTimestamp:rev.timestamp,sourceRevisionUser:rev.user??null,
    sourceTitle:page.title,sourceUrl:sourceUrl(page.title,rev.revid),retrievedAt,license:{...FRENCH_SOURCE.license},
    sourceSha256:HASH(raw),sourceWikitext:raw,sourceCategories:categories,
    isRecipe:parsed.ingredients.length>0&&parsed.steps.length>0,
    recipe:{name:page.title.slice(FRENCH_SOURCE.prefix.length),nameAr:null,servings:null,cuisine:null,
      ingredients:parsed.ingredients.map(r=>({...r,id:`source-line-${r.lineIndex+1}`,amountText:r.sourceText,amount:null,unit:null,foodBinding:null})),
      steps:parsed.steps.map((text,i)=>({n:i+1,text,sourceText:text,durationMinutes:null})),nutrition:null},
    reviewStatus:'unreviewed-source-extraction',parserVersion:'fr-sections-v1'};
}

export function buildFrenchIndex(records){
  const revisions=new Map(),latest=new Map();
  for(const r of records){
    need(r.sourceId===FRENCH_SOURCE.sourceId&&r.sourceLanguage==='fr','Invalid French source');
    need(Number.isSafeInteger(r.sourcePageId)&&r.sourcePageId>0&&/^\d+$/.test(r.sourceRevision)&&Number.isSafeInteger(Number(r.sourceRevision))&&Number(r.sourceRevision)>0,'Invalid French identity');
    need(r.recordId===key(r.sourcePageId,r.sourceRevision),'Invalid French record key');
    need(typeof r.sourceTitle==='string'&&r.sourceTitle.startsWith(FRENCH_SOURCE.prefix),'Invalid French title prefix');
    need(r.sourceUrl===sourceUrl(r.sourceTitle,r.sourceRevision),'Invalid French permalink');
    need(r.license?.id===FRENCH_SOURCE.license.id&&r.license?.url===FRENCH_SOURCE.license.url,'Invalid French licence');
    need(typeof r.sourceWikitext==='string'&&r.sourceWikitext.length>0&&HASH(r.sourceWikitext)===r.sourceSha256,'Corrupt French source hash');
    need(Number.isFinite(Date.parse(r.retrievedAt)),'Invalid French retrieval date');
    const prior=revisions.get(r.recordId);need(!prior||prior.sourceSha256===r.sourceSha256,'Conflicting French revision hash');
    revisions.set(r.recordId,r);
    if(!latest.has(r.sourcePageId)||Number(r.sourceRevision)>Number(latest.get(r.sourcePageId).sourceRevision))latest.set(r.sourcePageId,r);
  }
  const recipes=[],entries=[];
  for(const r of [...latest.values()].sort((a,b)=>a.sourcePageId-b.sourcePageId)){
    // Re-extract from validated raw text, never trust saved derived fields.
    const current=recordFrenchPage({pageid:r.sourcePageId,ns:0,title:r.sourceTitle,revisions:[{revid:Number(r.sourceRevision),timestamp:r.sourceRevisionTimestamp,user:r.sourceRevisionUser,slots:{main:{content:r.sourceWikitext}}}]},r.retrievedAt);
    entries.push({id:`fr-wikibooks:${r.sourcePageId}`,recordId:r.recordId,title:r.sourceTitle,sourceUrl:r.sourceUrl,isRecipe:current.isRecipe,sourceCategories:current.sourceCategories});
    if(current.isRecipe)recipes.push({...current,id:`fr-wikibooks:${r.sourcePageId}`});
  }
  return {index:{schemaVersion:1,sourceId:FRENCH_SOURCE.sourceId,sourceLanguage:'fr',parserVersion:'fr-sections-v1',
    revisionRecords:revisions.size,distinctSourcePages:latest.size,recipeCount:recipes.length,runtimeReadyCount:0,
    ingredientCount:recipes.reduce((n,r)=>n+r.recipe.ingredients.length,0),stepCount:recipes.reduce((n,r)=>n+r.recipe.steps.length,0),
    entries,warning:'Prefix includes ingredients, indexes and techniques. Only pages with both recognized ingredient and method lists are research recipes. Language is not cuisine; all quantities/bindings/nutrition remain unknown.'},recipes};
}
async function publish(out,cp){
  const raw=await maybeRead(resolve(out,'source-pages.jsonl'));const records=raw.split(/\r?\n/).filter(Boolean).map(JSON.parse);
  const {index,recipes}=buildFrenchIndex(records);index.sourceFileSha256=HASH(raw);
  const derived=recipes.map(r=>JSON.stringify(r)).join('\n')+(recipes.length?'\n':'');index.parsedFileSha256=HASH(derived);
  await writeFile(resolve(out,'parsed-recipes.jsonl'),derived,'utf8');await jsonWrite(resolve(out,'index.json'),index);
  const manifest={...FRENCH_SOURCE,license:{...FRENCH_SOURCE.license},...index,entries:undefined,
    collectionStartedAt:cp.collectionStartedAt,lastSuccessfulRetrievalAt:cp.lastSuccessfulRetrievalAt??null,
    sourceExhausted:cp.sourceExhausted,nextAttemptAt:cp.nextAttemptAt,lastRunApiRequests:cp.lastRunApiRequests,
    cumulativeApiRequests:cp.cumulativeApiRequests,pendingPageIds:cp.pendingPageIds,checkpoint:'checkpoint.json',
    records:'source-pages.jsonl',parsed:'parsed-recipes.jsonl',requestArchives:'requests/',noAllTimeCollectionCap:true};
  await jsonWrite(resolve(out,'manifest.json'),manifest);return manifest;
}

// Narrow offline repair for the initial, fully archived listing rejected by the old space-only guard.
// Never clears a failure gate or makes source requests.
export async function recoverFrenchListing(out){
  const lockPath=resolve(out,'collector.lock');let lock;
  try{lock=await open(lockPath,'wx');}catch(e){if(e.code==='EEXIST')throw new Error('French collector lock exists');throw e;}
  try{
    await lock.writeFile(JSON.stringify({pid:process.pid,mode:'offline-listing-recovery'}));
    const cp=JSON.parse(await readFile(resolve(out,'checkpoint.json'),'utf8'));
    need(cp.sourceId===FRENCH_SOURCE.sourceId&&cp.lastError?.message==='Invalid French listing continuation'&&
      cp.pendingPageIds?.length===0&&cp.listingContinuation===null&&!cp.listingExhausted&&!cp.sourceExhausted,'Unsupported French listing recovery state');
    const prefix=String(cp.cumulativeApiRequests).padStart(6,'0')+'-',files=(await readdir(resolve(out,'requests'))).filter(f=>f.startsWith(prefix)&&f.endsWith('.json'));
    need(files.length===1,'Missing or ambiguous French request archive');
    const archive=JSON.parse(await readFile(resolve(out,'requests',files[0]),'utf8')),url=new URL(archive.requestUrl);
    need(archive.httpStatus===200&&HASH(archive.responseBody)===archive.responseSha256,'Corrupt French response archive hash/status');
    need(url.origin==='https://fr.wikibooks.org'&&url.pathname==='/w/api.php'&&url.searchParams.get('action')==='query'&&
      url.searchParams.get('list')==='allpages'&&url.searchParams.get('apprefix')===FRENCH_SOURCE.prefix&&url.searchParams.get('apnamespace')==='0'&&url.searchParams.get('apfilterredir')==='nonredirects','Unexpected French listing archive');
    const data=JSON.parse(archive.responseBody);need(!data.error,'Archived French API failure cannot be replayed');acceptListing(data,cp);
    cp.sourceExhausted=cp.listingExhausted&&!cp.pendingPageIds.length;
    cp.offlineRecovery={archive:`requests/${files[0]}`,reason:'Validated original underscore listing continuation; original failure cooldown retained',at:new Date().toISOString()};
    await jsonWrite(resolve(out,'checkpoint.json'),cp);return await publish(out,cp);
  }finally{await lock.close();await unlink(lockPath);}
}

export async function collectFrench(options,dependencies={}){
  const out=options.out??resolve(ROOT,'data/recipes/bulk/fr-wikibooks-cuisine');await mkdir(out,{recursive:true});
  const lockPath=resolve(out,'collector.lock');let lock;
  try{lock=await open(lockPath,'wx');}catch(e){if(e.code==='EEXIST')throw new Error('French collector lock exists; inspect its owner before retrying.');throw e;}
  const now=dependencies.now??(()=>new Date()),wait=dependencies.wait??(ms=>new Promise(r=>setTimeout(r,ms))),fetchImpl=dependencies.fetch??fetch;
  const checkpointPath=resolve(out,'checkpoint.json'),recordsPath=resolve(out,'source-pages.jsonl');let cp;
  try{
    await lock.writeFile(JSON.stringify({pid:process.pid,startedAt:now().toISOString(),sourceId:FRENCH_SOURCE.sourceId}));
    const readDiscovery=dependencies.readDiscovery??(path=>maybeRead(path,'{}'));
    const discovery=JSON.parse(await readDiscovery(options.discoveryStatusPath??resolve(ROOT,'data/recipes/source-discovery/fr-wikibooks/status.json')));
    need(!discovery.nextAttemptAt||Number.isFinite(Date.parse(discovery.nextAttemptAt)),'Invalid discovery cooldown date');
    if(discovery.nextAttemptAt&&now()<new Date(discovery.nextAttemptAt))throw new Error(`French discovery cooldown active until ${discovery.nextAttemptAt}; no request sent.`);
    const saved=await maybeRead(checkpointPath);
    need(options.resume||!saved&&!await maybeRead(recordsPath),'French output exists; use --resume');
    need(saved||!await maybeRead(recordsPath),'French source records lack a checkpoint; review recovery before restarting listing');
    cp=saved?JSON.parse(saved):{schemaVersion:1,sourceId:FRENCH_SOURCE.sourceId,collectionStartedAt:now().toISOString(),
      listingContinuation:null,listingExhausted:false,pendingPageIds:[],pendingTitles:{},sourceExhausted:false,cumulativeApiRequests:0,nextAttemptAt:null};
    need(cp.sourceId===FRENCH_SOURCE.sourceId,'Checkpoint belongs to another source');
    need(cp.schemaVersion===1&&Number.isSafeInteger(cp.cumulativeApiRequests)&&cp.cumulativeApiRequests>=0,'Invalid French checkpoint counters');
    need(Array.isArray(cp.pendingPageIds)&&cp.pendingPageIds.every(id=>/^\d+$/.test(id)),'Invalid pending IDs');
    validateContinuation(cp.listingContinuation);
    need(cp.pendingTitles&&cp.pendingPageIds.every(id=>typeof cp.pendingTitles[id]==='string'&&cp.pendingTitles[id].startsWith(FRENCH_SOURCE.prefix)),'Invalid pending title evidence');
    need(typeof cp.listingExhausted==='boolean'&&cp.sourceExhausted===(cp.listingExhausted&&!cp.pendingPageIds.length),'Inconsistent French exhaustion checkpoint');
    need(!cp.nextAttemptAt||Number.isFinite(Date.parse(cp.nextAttemptAt)),'Invalid cooldown date');
    if(cp.nextAttemptAt&&now()<new Date(cp.nextAttemptAt))throw new Error(`French source cooldown active until ${cp.nextAttemptAt}; no request sent.`);
    const existing=await readRecoverableRecords(out,cp);
    const known=new Map(existing.map(r=>[r.recordId,r.sourceSha256]));cp.lastRunApiRequests=0;let failure;
    const cap=Math.min(MAX_REQUESTS,options.maxApiRequests??MAX_REQUESTS);
    need(Number.isInteger(cap)&&cap>0,'Invalid request cap');
    while(!cp.sourceExhausted&&cp.lastRunApiRequests<cap){
      try{
        if(cp.lastSuccessfulRetrievalAt){const delay=Math.max(0,new Date(cp.lastSuccessfulRetrievalAt).getTime()+INTERVAL-now().getTime());if(delay)await wait(delay);}
        const pending=cp.pendingPageIds.length>0,url=new URL(FRENCH_SOURCE.api);
        const params=pending?{action:'query',pageids:cp.pendingPageIds.slice(0,PAGE_BATCH).join('|'),prop:'revisions',rvprop:'ids|timestamp|user|content',rvslots:'main'}:
          {action:'query',list:'allpages',apprefix:FRENCH_SOURCE.prefix,apnamespace:'0',apfilterredir:'nonredirects',aplimit:'50',...(cp.listingContinuation??{})};
        for(const [k,v] of Object.entries({...params,format:'json',formatversion:'2',maxlag:'5'}))url.searchParams.set(k,v);
        cp.lastRunApiRequests++;cp.cumulativeApiRequests++;cp.lastRequestStartedAt=now().toISOString();await jsonWrite(checkpointPath,cp);
        const response=await fetchImpl(url,{headers:{'user-agent':'SofraResearchCollector/1.0 (bounded recipe research; no images)'},signal:AbortSignal.timeout(45000)});
        const body=await response.text(),retrievedAt=now().toISOString(),sha=HASH(body);await mkdir(resolve(out,'requests'),{recursive:true});
        await jsonWrite(resolve(out,'requests',`${String(cp.cumulativeApiRequests).padStart(6,'0')}-${sha}.json`),{requestUrl:url.href,retrievedAt,httpStatus:response.status,responseSha256:sha,responseBody:body});
        if(!response.ok){const e=new Error(`French MediaWiki HTTP ${response.status}`),retry=response.headers?.get?.('retry-after');
          if(retry){const seconds=Number(retry),time=Number.isFinite(seconds)?now().getTime()+seconds*1000:Date.parse(retry);if(Number.isFinite(time))e.retryAfterMs=Math.max(0,time-now().getTime());}throw e;}
        const data=JSON.parse(body);if(data.error)throw new Error(`French MediaWiki API ${data.error.code}: ${data.error.info}`);
        if(pending){
          need(!data.continue,'Unexpected revision continuation; preserve pending IDs for review');
          need(Array.isArray(data.query?.pages),'French response omitted revision pages');
          const ids=cp.pendingPageIds.slice(0,PAGE_BATCH),seen=new Set(),records=[];
          for(const p of data.query.pages){const id=String(p.pageid);need(ids.includes(id)&&!seen.has(id),'Unexpected/duplicate French page ID');seen.add(id);
            need(cp.pendingTitles[id]===p.title,'French page title changed; review before accepting');records.push(recordFrenchPage(p,retrievedAt));}
          need(ids.every(id=>seen.has(id)),'French response omitted requested page IDs');
          const fresh=[];for(const r of records){const old=known.get(r.recordId);need(!old||old===r.sourceSha256,'Conflicting French revision hash');if(!old){fresh.push(r);known.set(r.recordId,r.sourceSha256);}}
          if(fresh.length)await appendFile(recordsPath,fresh.map(r=>JSON.stringify(r)).join('\n')+'\n','utf8');
          if(dependencies.afterAppend)await dependencies.afterAppend();
          cp.pendingPageIds=cp.pendingPageIds.filter(id=>!seen.has(id));for(const id of seen)delete cp.pendingTitles[id];
        }else{
          acceptListing(data,cp);
        }
        cp.sourceExhausted=cp.listingExhausted&&!cp.pendingPageIds.length;cp.lastSuccessfulRetrievalAt=retrievedAt;
        cp.nextAttemptAt=null;cp.lastError=null;cp.updatedAt=now().toISOString();await jsonWrite(checkpointPath,cp);
      }catch(e){failure=e;cp.lastError={at:now().toISOString(),message:e.message};cp.nextAttemptAt=new Date(now().getTime()+Math.max(COOLDOWN,e.retryAfterMs??0)).toISOString();await jsonWrite(checkpointPath,cp);break;}
    }
    const result=await publish(out,cp);if(failure)throw failure;return result;
  }finally{await lock.close();await unlink(lockPath);}
}

if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  try{const args=process.argv.slice(2),options={};for(let i=0;i<args.length;i++){
    if(args[i]==='--resume')options.resume=true;
    else if(args[i]==='--out')options.out=resolve(args[++i]);
    else if(args[i]==='--requests')options.maxApiRequests=Number(args[++i]);
    else throw new Error(`Unknown option ${args[i]}`);
  }const m=await collectFrench(options);process.stdout.write(JSON.stringify(m,null,2)+'\n');
  }catch(e){process.stderr.write(e.message+'\n');process.exitCode=1;}
}
