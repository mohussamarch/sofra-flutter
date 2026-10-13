import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,readFile,writeFile,rm,readdir} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {parseSpanishRecipe,recordSpanishPage,buildSpanishIndex,collectSpanish as collect} from './collect-wikibooks-es.mjs';
import {loadSpanishBootstrap} from './collect-wikibooks-es.mjs';
import {createHash} from 'node:crypto';
const collectSpanish=(options,deps={})=>collect(options,{readBootstrap:async()=>null,...(!options.discoveryStatusPath?{readDiscovery:async()=> '{}'}:{}),...deps});

const raw='== Ingredientes ==\n* 200 g de arroz\n=== Salsa ===\n* Sal, opcional\n== Preparación ==\n# Laver le riz.\n# Cuire.\n== Notes ==\n* Hors recette';
const page=(id=1,text=raw)=>({pageid:id,ns:0,title:`Artes culinarias/Recetas/Recette ${id}`,revisions:[{revid:100+id,timestamp:'2026-01-01T00:00:00Z',user:'Auteur',slots:{main:{content:text}}}]});
const at='2026-10-13T17:00:00.000Z';
const response=(data,status=200,headers={})=>({ok:status===200,status,headers:{get:k=>headers[k]??null},text:async()=>JSON.stringify(data)});
async function temporary(fn){const out=await mkdtemp(join(tmpdir(),'sofra-fr-'));try{return await fn(out);}finally{await rm(out,{recursive:true,force:true});}}

test('Spanish sections preserve groups and only source text; hidden examples are excluded',()=>{
  const parsed=parseSpanishRecipe(`<!-- == Ingredientes ==\n* Faux -->\n${raw}\n<nowiki>== Ingredientes ==\n* Faux</nowiki>`);
  assert.deepEqual(parsed.ingredients.map(r=>r.sourceText),['200 g de arroz','Sal, opcional']);
  assert.equal(parsed.ingredients[1].sourceGroupPath[0].title,'Salsa');
  assert.deepEqual(parsed.steps,['Laver le riz.','Cuire.']);
});
test('headings with accents, plurals and bullet methods; no invented servings/weights',()=>{
  const r=recordSpanishPage(page(1,'== Ingredientes ==\n* Une pomme\n== Elaboración ==\n* Couper.'),at);
  assert.equal(r.isRecipe,true); assert.equal(r.sourceLanguage,'es');
  assert.match(r.sourceUrl,/es.wikibooks.org.*oldid=101/);
  assert.equal(r.recipe.ingredients[0].amount,null); assert.equal(r.recipe.ingredients[0].foodBinding,null);
  assert.equal(r.recipe.servings,null); assert.equal(r.recipe.nutrition,null);
  assert.equal(r.license.pageExceptionStatus,'not-reviewed-per-page');
});
test('prefix pages without both sections remain source pages, never recipes',()=>{
  assert.equal(recordSpanishPage(page(1,'== Ingredientes ==\n* riz'),at).isRecipe,false);
  assert.equal(recordSpanishPage(page(2,'#REDIRECT [[Autre]]'),at).isRecipe,false);
  assert.throws(()=>recordSpanishPage({...page(),ns:102},at),/namespace/i);
  assert.throws(()=>recordSpanishPage({...page(),title:'Autre'},at),/prefix/i);
  assert.throws(()=>recordSpanishPage(page(3,''),at),/content/i);
});
test('derived index rejects corrupt source and conflicting same revisions',()=>{
  const r=recordSpanishPage(page(),at);
  assert.throws(()=>buildSpanishIndex([{...r,sourceWikitext:'altered'}]),/hash/i);
  assert.throws(()=>buildSpanishIndex([{...r,sourceUrl:'https://example.org/'}]),/permalink/i);
  assert.throws(()=>buildSpanishIndex([{...r,license:{id:'unknown'}}]),/licen/i);
  const newer=recordSpanishPage({...page(),revisions:[{...page().revisions[0],revid:102}]},at);
  const result=buildSpanishIndex([r,r,newer,recordSpanishPage(page(2,'Sommaire'),at)]);
  assert.equal(result.index.distinctSourcePages,2);assert.equal(result.index.recipeCount,1);
  assert.equal(result.recipes[0].sourceRevision,'102');assert.equal(result.index.runtimeReadyCount,0);
});
test('listing cursor is separate from revision requests and resumes pending work first',()=>temporary(async out=>{
  const urls=[];
  const fetch=async url=>{const u=new URL(url);urls.push(u);return response(u.searchParams.has('list')?{query:{allpages:[{pageid:1,ns:0,title:page().title}]},continue:{apcontinue:'Artes culinarias/Recetas/B',continue:'-||'}}:{query:{pages:[page()]}});};
  await collectSpanish({out,maxApiRequests:1},{fetch,now:()=>new Date(at),wait:async()=>{}});
  let cp=JSON.parse(await readFile(join(out,'checkpoint.json')));
  assert.deepEqual(cp.pendingPageIds,['1']); assert.equal(cp.listingContinuation.apcontinue,'Artes culinarias/Recetas/B');
  const result=await collectSpanish({out,resume:true,maxApiRequests:1},{fetch,now:()=>new Date(at),wait:async()=>{}});
  assert.equal(urls[1].searchParams.get('pageids'),'1');assert.equal(urls[1].searchParams.has('apcontinue'),false);
  assert.equal(result.recipeCount,1);cp=JSON.parse(await readFile(join(out,'checkpoint.json')));
  assert.deepEqual(cp.pendingPageIds,[]);assert.equal(cp.listingContinuation.apcontinue,'Artes culinarias/Recetas/B');
}));
test('source errors create backoff and never advance pending work or bypass active gate',()=>temporary(async out=>{
  let calls=0;const deps={fetch:async()=>{calls++;return response({},503,{'retry-after':'1800'});},now:()=>new Date(at),wait:async()=>{}};
  await assert.rejects(collectSpanish({out,maxApiRequests:1},deps),/503/);
  const cp=JSON.parse(await readFile(join(out,'checkpoint.json')));assert.equal(cp.nextAttemptAt,'2026-10-13T17:30:00.000Z');
  await assert.rejects(collectSpanish({out,resume:true},deps),/cooldown/i);assert.equal(calls,1);
  await assert.rejects(readFile(join(out,'collector.lock')),/ENOENT/);
}));
test('missing content stops with preserved pending IDs; no false source exhaustion',()=>temporary(async out=>{
  let calls=0;const deps={fetch:async()=>response(++calls===1?{query:{allpages:[{pageid:1,ns:0,title:page().title}]}}:{query:{pages:[{...page(),revisions:[{revid:101,timestamp:at}]}]}}),now:()=>new Date(at),wait:async()=>{}};
  await assert.rejects(collectSpanish({out,maxApiRequests:2},deps),/content/i);
  const cp=JSON.parse(await readFile(join(out,'checkpoint.json')));assert.deepEqual(cp.pendingPageIds,['1']);assert.equal(cp.sourceExhausted,false);
}));
test('append-before-checkpoint recovery deduplicates immutable revisions',()=>temporary(async out=>{
  const deps={fetch:async url=>response(new URL(url).searchParams.has('list')?{query:{allpages:[{pageid:1,ns:0,title:page().title}]}}:{query:{pages:[page()]}}),now:()=>new Date(at),wait:async()=>{},afterAppend:async()=>{throw new Error('interrupted');}};
  await assert.rejects(collectSpanish({out,maxApiRequests:2},deps),/interrupted/);
  const result=await collectSpanish({out,resume:true,maxApiRequests:1},{...deps,afterAppend:undefined,now:()=>new Date('2026-10-13T18:00:00Z')});
  assert.equal(result.distinctSourcePages,1);assert.equal(result.recipeCount,1);
  const lines=(await readFile(join(out,'source-pages.jsonl'),'utf8')).trim().split('\n');assert.equal(lines.length,1);
  const cp=JSON.parse(await readFile(join(out,'checkpoint.json')));assert.equal(cp.sourceExhausted,true);
}));
test('lock refuses a second owner and wrong-source checkpoint cannot resume',()=>temporary(async out=>{
  await writeFile(join(out,'collector.lock'),'owner');await assert.rejects(collectSpanish({out}),/lock/i);
  await rm(join(out,'collector.lock'));await writeFile(join(out,'checkpoint.json'),JSON.stringify({sourceId:'english'}));
  await assert.rejects(collectSpanish({out,resume:true}),/source/i);
}));
test('request count is bounded and successful requests are paced',()=>temporary(async out=>{
  const waits=[];let n=0;
  await collectSpanish({out,maxApiRequests:100},{now:()=>new Date(at),wait:async ms=>waits.push(ms),fetch:async url=>{
    const u=new URL(url);return response(u.searchParams.has('list')?{query:{allpages:[{pageid:++n,ns:0,title:page(n).title}]},continue:{apcontinue:page(n+1).title,continue:'-||'}}:{query:{pages:[page(n)]}});
  }});
  const cp=JSON.parse(await readFile(join(out,'checkpoint.json')));assert.equal(cp.lastRunApiRequests,10);assert.equal(waits.length,9);assert.ok(waits.every(ms=>ms>=2000));
}));
test('unexpected continuation cannot alter query; revision pagination never advances listing cursor',()=>temporary(async out=>{
  let calls=0;const deps={fetch:async()=>response(++calls===1?{query:{allpages:[{pageid:1,ns:0,title:page().title}]},continue:{apcontinue:page(2).title,continue:'-||'}}:{query:{pages:[page()]},continue:{rvcontinue:'unexpected',continue:'||'}}),now:()=>new Date(at),wait:async()=>{}};
  await assert.rejects(collectSpanish({out,maxApiRequests:2},deps),/continuation/);
  const cp=JSON.parse(await readFile(join(out,'checkpoint.json')));assert.deepEqual(cp.pendingPageIds,['1']);assert.equal(cp.listingContinuation.apcontinue,page(2).title);
  cp.nextAttemptAt=null;cp.listingContinuation={action:'delete'};await writeFile(join(out,'checkpoint.json'),JSON.stringify(cp));
  await assert.rejects(collectSpanish({out,resume:true},deps),/continuation/);assert.equal(calls,2);
}));
test('discovery backoff applies before the first new checkpoint or network call',()=>temporary(async out=>{
  const gate=join(out,'discovery.json');await writeFile(gate,JSON.stringify({nextAttemptAt:'2026-10-13T17:13:55.179Z'}));
  let calls=0;await assert.rejects(collectSpanish({out,discoveryStatusPath:gate},{now:()=>new Date(at),fetch:async()=>{calls++;throw new Error('unexpected');}}),/discovery cooldown/i);
  assert.equal(calls,0);await assert.rejects(readFile(join(out,'checkpoint.json')),/ENOENT/);
}));
test('default discovery gate is app-root based even with a custom output directory',()=>temporary(async out=>{
  let calls=0;
  await assert.rejects(collect({out},{now:()=>new Date(at),readDiscovery:async path=>{
    assert.match(path.replaceAll('\\','/'),/\/data\/recipes\/source-discovery\/es-wikibooks\/status.json$/);
    assert.equal(path.startsWith(out),false);return JSON.stringify({nextAttemptAt:'2026-10-13T17:13:55.179Z'});
  },fetch:async()=>{calls++;throw new Error('unexpected');}}),/discovery cooldown/i);assert.equal(calls,0);
}));
test('torn final JSONL record is archived and refetched without losing complete revisions',()=>temporary(async out=>{
  const deps={fetch:async url=>response(new URL(url).searchParams.has('list')?{query:{allpages:[1,2].map(id=>({pageid:id,ns:0,title:page(id).title}))}}:{query:{pages:[page(1),page(2)]}}),now:()=>new Date(at),wait:async()=>{},afterAppend:async()=>{throw new Error('interrupted');}};
  await assert.rejects(collectSpanish({out,maxApiRequests:2},deps),/interrupted/);
  const path=join(out,'source-pages.jsonl'),lines=(await readFile(path,'utf8')).trim().split('\n');
  const unfinished=Buffer.from('{"recordId":"fr-é'),tail=unfinished.subarray(0,unfinished.length-1);
  await writeFile(path,Buffer.concat([Buffer.from(lines[0]+'\n'),tail]));
  const result=await collectSpanish({out,resume:true,maxApiRequests:1},{...deps,afterAppend:undefined,now:()=>new Date('2026-10-13T18:00:00Z')});
  assert.equal(result.distinctSourcePages,2);assert.equal((await readFile(path,'utf8')).trim().split('\n').length,2);
  const files=await readdir(join(out,'recovery'));assert.equal(files.length,1);
  const recovered=JSON.parse(await readFile(join(out,'recovery',files[0])));assert.equal(recovered.tailBytesBase64,tail.toString('base64'));
}));
test('API underscore continuation is retained verbatim and is not sent to revision query',()=>temporary(async out=>{
  let n=0;const cursor="Artes_culinarias/Recetas/Beurre_d'escargot",urls=[];
  await collectSpanish({out,maxApiRequests:2},{now:()=>new Date(at),wait:async()=>{},fetch:async url=>{urls.push(new URL(url));return response(++n===1?{query:{allpages:[{pageid:1,ns:0,title:page().title}]},continue:{apcontinue:cursor,continue:'-||'}}:{query:{pages:[page()]}});}});
  const cp=JSON.parse(await readFile(join(out,'checkpoint.json')));assert.equal(cp.listingContinuation.apcontinue,cursor);assert.equal(urls[1].searchParams.has('apcontinue'),false);
}));

function bootstrapFixture(){
 const hash=s=>createHash('sha256').update(s).digest('hex');
 const listing={query:{allpages:[1,2].map(id=>({pageid:id,ns:0,title:page(id).title}))},continue:{apcontinue:'Artes_culinarias/Recetas/B',continue:'-||'}};
 const archived=(data,params)=>{const url=new URL('https://es.wikibooks.org/w/api.php');for(const [k,v]of Object.entries(params))url.searchParams.set(k,v);const responseBody=JSON.stringify(data);return {requestUrl:url.href,httpStatus:200,responseBody,responseSha256:hash(responseBody)};};
 const files={'status.json':{completed:true,sourceLanguage:'es',firstListingCount:2,listingContinuation:listing.continue,listingExhausted:false,nextAttemptAt:null},'01-siteinfo.json':archived({query:{general:{lang:'es'},namespaces:{0:{id:0}},rightsinfo:{url:'https://creativecommons.org/licenses/by-sa/4.0/deed.es'}}},{action:'query',meta:'siteinfo'}),'02-first-prefix.json':archived(listing,{action:'query',list:'allpages',apprefix:'Artes culinarias/Recetas/',apnamespace:'0',apfilterredir:'nonredirects'})};
 const read=async p=>JSON.stringify(files[p.replaceAll('\\','/').split('/').at(-1)]);
 return {files,read};
}
test('archived discovery entries become pending before advancing their saved continuation',()=>temporary(async out=>{
 const f=bootstrapFixture(),urls=[];
 const result=await collectSpanish({out,maxApiRequests:1},{readBootstrap:()=>loadSpanishBootstrap({read:f.read}),fetch:async url=>{urls.push(new URL(url));return response({query:{pages:[page(1),page(2)]}});},now:()=>new Date(at),wait:async()=>{}});
 assert.equal(result.recipeCount,2);assert.equal(urls.length,1);assert.equal(urls[0].searchParams.get('pageids'),'1|2');assert.equal(urls[0].searchParams.has('apcontinue'),false);
 const cp=JSON.parse(await readFile(join(out,'checkpoint.json')));assert.equal(cp.listingContinuation.apcontinue,'Artes_culinarias/Recetas/B');assert.equal(cp.bootstrap.listingResponseSha256,f.files['02-first-prefix.json'].responseSha256);
}));
test('bootstrap verifies archive SHA, official endpoint, policy and exact listing status',async()=>{
 for(const edit of [f=>f['02-first-prefix.json'].responseSha256='0'.repeat(64),f=>f['01-siteinfo.json'].requestUrl='https://example.org/api',f=>f['status.json'].completed=false,f=>f['status.json'].firstListingCount=99,f=>f['status.json'].listingContinuation=null]){const f=bootstrapFixture();edit(f.files);await assert.rejects(loadSpanishBootstrap({read:f.read}));}
});
test('Spanish recipe template parameters preserve nested templates and ignore unrelated fields',()=>{
 const r=parseSpanishRecipe('{{Artes culinarias/Datos de receta\n|comensales=4\n|ingredientes=\n* [[Arroz|arroz]] 200 g\n* {{ing|Sal}} al gusto\n|procedimiento=\n# Cocer {{ute|olla}}.\n|extra=\n* not a method\n}}');
 assert.deepEqual(r.ingredients.map(x=>x.sourceText),['arroz 200 g','{{ing|Sal}} al gusto']);assert.deepEqual(r.steps,['Cocer {{ute|olla}}.']);
});
test('hidden or unbalanced templates are not recipes; other template names do not qualify',()=>{
 for(const text of ['<!-- {{Artes culinarias/Datos de receta|ingredientes=\n* riz\n|procedimiento=\n# cuire\n}} -->','{{Artes culinarias/Datos de receta|ingredientes=\n* riz\n|procedimiento=\n# cuire','{{Other|ingredientes=\n* riz\n|procedimiento=\n# cuire\n}}']){const r=parseSpanishRecipe(text);assert.equal(r.ingredients.length*r.steps.length,0);}
});
test('source grammar refuses ambiguous mixed heading/template recipes instead of double counting',()=>{
 const r=parseSpanishRecipe(raw+'\n{{Artes culinarias/Datos de receta|ingredientes=\n* otra\n|procedimiento=\n# Otra\n}}');assert.equal(r.ingredients.length,0);assert.equal(r.steps.length,0);
});
test('multiline unresolved nested templates are conservatively unparsed, never truncated into rows',()=>{
 for(const text of ['{{Artes culinarias/Datos de receta|ingredientes=\n* {{ing\n|food=arroz\n* falsa}}\n|procedimiento=\n# Cocer\n}}','== Ingredientes ==\n* {{ing\n|food=arroz\n* falsa}}\n== Preparación ==\n# Cocer']){const r=parseSpanishRecipe(text);assert.deepEqual(r,{ingredients:[],steps:[]});}
});
test('literal code regions and unterminated hidden blocks cannot supply recipe sections',()=>{
 for(const text of ['<syntaxhighlight lang="wikitext">\n'+raw+'\n</syntaxhighlight>','<pre>\n'+raw+'\n</pre>','<source>\n'+raw+'\n</source>','<!--\n'+raw,'<nowiki>\n'+raw])assert.deepEqual(parseSpanishRecipe(text),{ingredients:[],steps:[]});
 assert.equal(parseSpanishRecipe('<nowiki/>\n'+raw).ingredients.length,2);
});
test('nonbullet multiline templates inside or before heading sections cannot leak internal bullets',()=>{
 for(const text of ['== Ingredientes ==\n{{ing\n|food=arroz\n* falsa\n}}\n== Preparación ==\n# Cocer','== Ingredientes ==\n* arroz\n== Preparación ==\n{{ute\n# falsa\n}}','{{wrapper\n'+raw+'\n}}'])assert.deepEqual(parseSpanishRecipe(text),{ingredients:[],steps:[]});
});
