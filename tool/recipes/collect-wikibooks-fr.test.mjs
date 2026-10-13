import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,readFile,writeFile,rm,readdir} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {parseFrenchRecipe,recordFrenchPage,buildFrenchIndex,recoverFrenchListing,collectFrench as collect} from './collect-wikibooks-fr.mjs';
const collectFrench=(options,deps={})=>collect(options,{...(!options.discoveryStatusPath?{readDiscovery:async()=> '{}'}:{}),...deps});

const raw='== Ingrédients ==\n* 200 g de riz\n=== Sauce ===\n* Sel, facultatif\n== Préparation ==\n# Laver le riz.\n# Cuire.\n== Notes ==\n* Hors recette';
const page=(id=1,text=raw)=>({pageid:id,ns:0,title:`Livre de cuisine/Recette ${id}`,revisions:[{revid:100+id,timestamp:'2026-01-01T00:00:00Z',user:'Auteur',slots:{main:{content:text}}}]});
const at='2026-10-13T17:00:00.000Z';
const response=(data,status=200,headers={})=>({ok:status===200,status,headers:{get:k=>headers[k]??null},text:async()=>JSON.stringify(data)});
async function temporary(fn){const out=await mkdtemp(join(tmpdir(),'sofra-fr-'));try{return await fn(out);}finally{await rm(out,{recursive:true,force:true});}}

test('French sections preserve groups and only source text; hidden examples are excluded',()=>{
  const parsed=parseFrenchRecipe(`<!-- == Ingrédients ==\n* Faux -->\n${raw}\n<nowiki>== Ingrédients ==\n* Faux</nowiki>`);
  assert.deepEqual(parsed.ingredients.map(r=>r.sourceText),['200 g de riz','Sel, facultatif']);
  assert.equal(parsed.ingredients[1].sourceGroupPath[0].title,'Sauce');
  assert.deepEqual(parsed.steps,['Laver le riz.','Cuire.']);
});
test('headings with accents, plurals and bullet methods; no invented servings/weights',()=>{
  const r=recordFrenchPage(page(1,'== Ingredients ==\n* Une pomme\n== Préparations ==\n* Couper.'),at);
  assert.equal(r.isRecipe,true); assert.equal(r.sourceLanguage,'fr');
  assert.match(r.sourceUrl,/fr.wikibooks.org.*oldid=101/);
  assert.equal(r.recipe.ingredients[0].amount,null); assert.equal(r.recipe.ingredients[0].foodBinding,null);
  assert.equal(r.recipe.servings,null); assert.equal(r.recipe.nutrition,null);
  assert.equal(r.license.pageExceptionStatus,'not-reviewed-per-page');
});
test('prefix pages without both sections remain source pages, never recipes',()=>{
  assert.equal(recordFrenchPage(page(1,'== Ingrédients ==\n* riz'),at).isRecipe,false);
  assert.equal(recordFrenchPage(page(2,'#REDIRECT [[Autre]]'),at).isRecipe,false);
  assert.throws(()=>recordFrenchPage({...page(),ns:102},at),/namespace/i);
  assert.throws(()=>recordFrenchPage({...page(),title:'Autre'},at),/prefix/i);
  assert.throws(()=>recordFrenchPage(page(3,''),at),/content/i);
});
test('derived index rejects corrupt source and conflicting same revisions',()=>{
  const r=recordFrenchPage(page(),at);
  assert.throws(()=>buildFrenchIndex([{...r,sourceWikitext:'altered'}]),/hash/i);
  assert.throws(()=>buildFrenchIndex([{...r,sourceUrl:'https://example.org/'}]),/permalink/i);
  assert.throws(()=>buildFrenchIndex([{...r,license:{id:'unknown'}}]),/licen/i);
  const newer=recordFrenchPage({...page(),revisions:[{...page().revisions[0],revid:102}]},at);
  const result=buildFrenchIndex([r,r,newer,recordFrenchPage(page(2,'Sommaire'),at)]);
  assert.equal(result.index.distinctSourcePages,2);assert.equal(result.index.recipeCount,1);
  assert.equal(result.recipes[0].sourceRevision,'102');assert.equal(result.index.runtimeReadyCount,0);
});
test('listing cursor is separate from revision requests and resumes pending work first',()=>temporary(async out=>{
  const urls=[];
  const fetch=async url=>{const u=new URL(url);urls.push(u);return response(u.searchParams.has('list')?{query:{allpages:[{pageid:1,ns:0,title:page().title}]},continue:{apcontinue:'Livre de cuisine/B',continue:'-||'}}:{query:{pages:[page()]}});};
  await collectFrench({out,maxApiRequests:1},{fetch,now:()=>new Date(at),wait:async()=>{}});
  let cp=JSON.parse(await readFile(join(out,'checkpoint.json')));
  assert.deepEqual(cp.pendingPageIds,['1']); assert.equal(cp.listingContinuation.apcontinue,'Livre de cuisine/B');
  const result=await collectFrench({out,resume:true,maxApiRequests:1},{fetch,now:()=>new Date(at),wait:async()=>{}});
  assert.equal(urls[1].searchParams.get('pageids'),'1');assert.equal(urls[1].searchParams.has('apcontinue'),false);
  assert.equal(result.recipeCount,1);cp=JSON.parse(await readFile(join(out,'checkpoint.json')));
  assert.deepEqual(cp.pendingPageIds,[]);assert.equal(cp.listingContinuation.apcontinue,'Livre de cuisine/B');
}));
test('source errors create backoff and never advance pending work or bypass active gate',()=>temporary(async out=>{
  let calls=0;const deps={fetch:async()=>{calls++;return response({},503,{'retry-after':'1800'});},now:()=>new Date(at),wait:async()=>{}};
  await assert.rejects(collectFrench({out,maxApiRequests:1},deps),/503/);
  const cp=JSON.parse(await readFile(join(out,'checkpoint.json')));assert.equal(cp.nextAttemptAt,'2026-10-13T17:30:00.000Z');
  await assert.rejects(collectFrench({out,resume:true},deps),/cooldown/i);assert.equal(calls,1);
  await assert.rejects(readFile(join(out,'collector.lock')),/ENOENT/);
}));
test('missing content stops with preserved pending IDs; no false source exhaustion',()=>temporary(async out=>{
  let calls=0;const deps={fetch:async()=>response(++calls===1?{query:{allpages:[{pageid:1,ns:0,title:page().title}]}}:{query:{pages:[{...page(),revisions:[{revid:101,timestamp:at}]}]}}),now:()=>new Date(at),wait:async()=>{}};
  await assert.rejects(collectFrench({out,maxApiRequests:2},deps),/content/i);
  const cp=JSON.parse(await readFile(join(out,'checkpoint.json')));assert.deepEqual(cp.pendingPageIds,['1']);assert.equal(cp.sourceExhausted,false);
}));
test('append-before-checkpoint recovery deduplicates immutable revisions',()=>temporary(async out=>{
  const deps={fetch:async url=>response(new URL(url).searchParams.has('list')?{query:{allpages:[{pageid:1,ns:0,title:page().title}]}}:{query:{pages:[page()]}}),now:()=>new Date(at),wait:async()=>{},afterAppend:async()=>{throw new Error('interrupted');}};
  await assert.rejects(collectFrench({out,maxApiRequests:2},deps),/interrupted/);
  const result=await collectFrench({out,resume:true,maxApiRequests:1},{...deps,afterAppend:undefined,now:()=>new Date('2026-10-13T18:00:00Z')});
  assert.equal(result.distinctSourcePages,1);assert.equal(result.recipeCount,1);
  const lines=(await readFile(join(out,'source-pages.jsonl'),'utf8')).trim().split('\n');assert.equal(lines.length,1);
  const cp=JSON.parse(await readFile(join(out,'checkpoint.json')));assert.equal(cp.sourceExhausted,true);
}));
test('lock refuses a second owner and wrong-source checkpoint cannot resume',()=>temporary(async out=>{
  await writeFile(join(out,'collector.lock'),'owner');await assert.rejects(collectFrench({out}),/lock/i);
  await rm(join(out,'collector.lock'));await writeFile(join(out,'checkpoint.json'),JSON.stringify({sourceId:'english'}));
  await assert.rejects(collectFrench({out,resume:true}),/source/i);
}));
test('request count is bounded and successful requests are paced',()=>temporary(async out=>{
  const waits=[];let n=0;
  await collectFrench({out,maxApiRequests:100},{now:()=>new Date(at),wait:async ms=>waits.push(ms),fetch:async url=>{
    const u=new URL(url);return response(u.searchParams.has('list')?{query:{allpages:[{pageid:++n,ns:0,title:page(n).title}]},continue:{apcontinue:page(n+1).title,continue:'-||'}}:{query:{pages:[page(n)]}});
  }});
  const cp=JSON.parse(await readFile(join(out,'checkpoint.json')));assert.equal(cp.lastRunApiRequests,10);assert.equal(waits.length,9);assert.ok(waits.every(ms=>ms>=2000));
}));
test('unexpected continuation cannot alter query; revision pagination never advances listing cursor',()=>temporary(async out=>{
  let calls=0;const deps={fetch:async()=>response(++calls===1?{query:{allpages:[{pageid:1,ns:0,title:page().title}]},continue:{apcontinue:page(2).title,continue:'-||'}}:{query:{pages:[page()]},continue:{rvcontinue:'unexpected',continue:'||'}}),now:()=>new Date(at),wait:async()=>{}};
  await assert.rejects(collectFrench({out,maxApiRequests:2},deps),/continuation/);
  const cp=JSON.parse(await readFile(join(out,'checkpoint.json')));assert.deepEqual(cp.pendingPageIds,['1']);assert.equal(cp.listingContinuation.apcontinue,page(2).title);
  cp.nextAttemptAt=null;cp.listingContinuation={action:'delete'};await writeFile(join(out,'checkpoint.json'),JSON.stringify(cp));
  await assert.rejects(collectFrench({out,resume:true},deps),/continuation/);assert.equal(calls,2);
}));
test('discovery backoff applies before the first new checkpoint or network call',()=>temporary(async out=>{
  const gate=join(out,'discovery.json');await writeFile(gate,JSON.stringify({nextAttemptAt:'2026-10-13T17:13:55.179Z'}));
  let calls=0;await assert.rejects(collectFrench({out,discoveryStatusPath:gate},{now:()=>new Date(at),fetch:async()=>{calls++;throw new Error('unexpected');}}),/discovery cooldown/i);
  assert.equal(calls,0);await assert.rejects(readFile(join(out,'checkpoint.json')),/ENOENT/);
}));
test('default discovery gate is app-root based even with a custom output directory',()=>temporary(async out=>{
  let calls=0;
  await assert.rejects(collect({out},{now:()=>new Date(at),readDiscovery:async path=>{
    assert.match(path.replaceAll('\\','/'),/\/data\/recipes\/source-discovery\/fr-wikibooks\/status.json$/);
    assert.equal(path.startsWith(out),false);return JSON.stringify({nextAttemptAt:'2026-10-13T17:13:55.179Z'});
  },fetch:async()=>{calls++;throw new Error('unexpected');}}),/discovery cooldown/i);assert.equal(calls,0);
}));
test('torn final JSONL record is archived and refetched without losing complete revisions',()=>temporary(async out=>{
  const deps={fetch:async url=>response(new URL(url).searchParams.has('list')?{query:{allpages:[1,2].map(id=>({pageid:id,ns:0,title:page(id).title}))}}:{query:{pages:[page(1),page(2)]}}),now:()=>new Date(at),wait:async()=>{},afterAppend:async()=>{throw new Error('interrupted');}};
  await assert.rejects(collectFrench({out,maxApiRequests:2},deps),/interrupted/);
  const path=join(out,'source-pages.jsonl'),lines=(await readFile(path,'utf8')).trim().split('\n');
  const unfinished=Buffer.from('{"recordId":"fr-é'),tail=unfinished.subarray(0,unfinished.length-1);
  await writeFile(path,Buffer.concat([Buffer.from(lines[0]+'\n'),tail]));
  const result=await collectFrench({out,resume:true,maxApiRequests:1},{...deps,afterAppend:undefined,now:()=>new Date('2026-10-13T18:00:00Z')});
  assert.equal(result.distinctSourcePages,2);assert.equal((await readFile(path,'utf8')).trim().split('\n').length,2);
  const files=await readdir(join(out,'recovery'));assert.equal(files.length,1);
  const recovered=JSON.parse(await readFile(join(out,'recovery',files[0])));assert.equal(recovered.tailBytesBase64,tail.toString('base64'));
}));
test('API underscore continuation is retained verbatim and is not sent to revision query',()=>temporary(async out=>{
  let n=0;const cursor="Livre_de_cuisine/Beurre_d'escargot",urls=[];
  await collectFrench({out,maxApiRequests:2},{now:()=>new Date(at),wait:async()=>{},fetch:async url=>{urls.push(new URL(url));return response(++n===1?{query:{allpages:[{pageid:1,ns:0,title:page().title}]},continue:{apcontinue:cursor,continue:'-||'}}:{query:{pages:[page()]}});}});
  const cp=JSON.parse(await readFile(join(out,'checkpoint.json')));assert.equal(cp.listingContinuation.apcontinue,cursor);assert.equal(urls[1].searchParams.has('apcontinue'),false);
}));
test('archived valid listing recovery preserves cooldown and makes no network requests',()=>temporary(async out=>{
  await collectFrench({out,maxApiRequests:1},{now:()=>new Date(at),wait:async()=>{},fetch:async()=>response({query:{allpages:[{pageid:1,ns:0,title:page().title}]},continue:{apcontinue:'Livre_de_cuisine/B',continue:'-||'}})});
  const path=join(out,'checkpoint.json'),cp=JSON.parse(await readFile(path));cp.pendingPageIds=[];cp.pendingTitles={};cp.listingContinuation=null;cp.listingExhausted=false;cp.sourceExhausted=false;cp.lastError={at,message:'Invalid French listing continuation'};cp.nextAttemptAt='2026-10-13T17:20:00Z';await writeFile(path,JSON.stringify(cp));
  const result=await recoverFrenchListing(out);assert.equal(result.pendingPageIds.length,1);
  const recovered=JSON.parse(await readFile(path));assert.equal(recovered.nextAttemptAt,cp.nextAttemptAt);assert.equal(recovered.listingContinuation.apcontinue,'Livre_de_cuisine/B');assert.equal(recovered.cumulativeApiRequests,1);
  await assert.rejects(recoverFrenchListing(out),/state/i);
}));
