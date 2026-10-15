import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,readFile,writeFile,readdir,rm,mkdir} from 'node:fs/promises';
import path from 'node:path';import os from 'node:os';
import {runBatch,withCollectorLock} from './collect-incremental.mjs';
import {offResearchUserAgent} from './off-contact.mjs';
import {collect} from './import.mjs';

async function temporary(fn){const parent=path.resolve(os.tmpdir()),out=await mkdtemp(path.join(parent,'sofra-off-contact-'));try{await fn(out);}finally{assert.equal(path.dirname(out),parent);assert.ok(path.basename(out).startsWith('sofra-off-contact-'));await rm(out,{recursive:true,force:true});}}
test('contact header has explicit runtime identity and rejects header injection without echoing contact',()=>{
 assert.equal(offResearchUserAgent('collector@example.invalid'),'SofraResearch/0.1 (collector@example.invalid)');
 for(const contact of [undefined,'','not-email','contact@example.invalid\r\nX-Test: yes','name(test)@example.invalid',' name@example.invalid ','a@b..com','a@-b.com','a@b-.com','.a@example.invalid','a.@example.invalid','a..b@example.invalid']){
  assert.throws(()=>offResearchUserAgent(contact),error=>{assert.match(error.message,/SOFRA_OFF_CONTACT_EMAIL/);if(contact)assert.ok(!error.message.includes(contact));return true;});
 }
});
test('collector sends corrected contact header but never archives private contact',()=>temporary(async out=>{
 let calls=0;
 const result=await runBatch({out,maxRequests:1,contactEmail:'collector@example.invalid',rebuild:false,sleep:async()=>{},fetchImpl:async(_url,options)=>{calls++;assert.equal(options.headers['User-Agent'],'SofraResearch/0.1 (collector@example.invalid)');return new Response(JSON.stringify({count:0,products:[]}),{status:200});}});
 assert.equal(calls,1);assert.equal(result.fetched,true);
 const raw=await readdir(path.join(out,'raw'));assert.equal(raw.length,1);
 assert.ok(!(await readFile(path.join(out,'raw',raw[0]),'utf8')).includes('collector@example.invalid'));
 assert.ok(!(await readFile(path.join(out,'collection-state.json'),'utf8')).includes('collector@example.invalid'));
}));
test('missing contact is local configuration failure: no HTTP, checkpoint mutation, backoff or retained lock',()=>temporary(async out=>{
 const file=path.join(out,'collection-state.json'),bytes=JSON.stringify({schemaVersion:1,cursors:{},failures:[],lastRequestAt:null,nextJobIndex:0})+'\n';await writeFile(file,bytes);
 let calls=0;
 await assert.rejects(withCollectorLock(out,()=>runBatch({out,maxRequests:1,contactEmail:'',fetchImpl:async()=>{calls++;throw Error('Must not fetch');},sleep:async()=>{},rebuild:false})),/SOFRA_OFF_CONTACT_EMAIL/);
 assert.equal(calls,0);assert.equal(await readFile(file,'utf8'),bytes);assert.deepEqual(await readdir(out),['collection-state.json']);
}));
test('active refusal gate needs no contact and does not request or mutate checkpoint',()=>temporary(async out=>{
 const now=Date.parse('2026-10-15T07:00:00Z'),file=path.join(out,'collection-state.json'),bytes=JSON.stringify({schemaVersion:1,cursors:{},failures:[{error:'OFF 401',nextAttemptAt:'2026-10-15T08:00:00Z'}]})+'\n';await writeFile(file,bytes);
 let calls=0;const result=await runBatch({out,contactEmail:'',nowMs:()=>now,fetchImpl:async()=>{calls++;throw Error('Must not fetch');}});
 assert.equal(calls,0);assert.equal(result.blockedReason,'source_access_backoff');assert.equal(await readFile(file,'utf8'),bytes);
}));

test('legacy failure receipts whitelist public plan fields instead of persisting private runtime contact',()=>temporary(async out=>{
 await mkdir(path.join(out,'raw'));
 await collect(out,[{country:'egypt',page:1,category:null,id:'failure',contactEmail:'collector@example.invalid',privateNote:'private-runtime-metadata',fetchImpl:async()=>new Response(null,{status:503})}]);
 const text=await readFile(path.join(out,'fetch-failures.json'),'utf8');
 assert.ok(!text.includes('collector@example.invalid'));assert.ok(!text.includes('private-runtime-metadata'));
 assert.deepEqual(JSON.parse(text)[0].plan,{country:'egypt',page:1,category:null,id:'failure'});
}));
