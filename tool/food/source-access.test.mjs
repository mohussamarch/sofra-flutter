import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,readFile,writeFile,rm} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {runBatch} from './collect-incremental.mjs';
import {sourceAccessUntil} from './source-access.mjs';
import {auditWork} from '../work/watchdog.mjs';
const now=Date.parse('2026-10-14T08:46:00Z');
const until='2026-10-14T09:49:45.471Z';
async function fixture(fn){
 const out=await mkdtemp(path.join(os.tmpdir(),'sofra-auth-gate-'));
 try{return await fn(out);}
 finally{
  assert.equal(path.dirname(path.resolve(out)),path.resolve(os.tmpdir()));
  assert.ok(path.basename(out).startsWith('sofra-auth-gate-'));
  await rm(out,{recursive:true,force:true});
 }
}
test('source access gate spans markets, takes latest pending gate and rejects malformed access dates',()=>{
 assert.equal(sourceAccessUntil({failures:[{error:'Error: OFF 401 Unauthorized',nextAttemptAt:until}]},now),until);
 assert.equal(sourceAccessUntil({failures:[{error:'OFF 403 Forbidden',nextAttemptAt:until},{error:'OFF 401',nextAttemptAt:'2026-10-14T10:00:00Z'}]},now),'2026-10-14T10:00:00Z');
 assert.equal(sourceAccessUntil({failures:[{error:'OFF 503',nextAttemptAt:until}]},now),null);
 assert.equal(sourceAccessUntil({failures:[{error:'OFF 401',nextAttemptAt:until}]},Date.parse(until)),null);
 assert.throws(()=>sourceAccessUntil({failures:[{error:'OFF 401',nextAttemptAt:'bad'}]},now));
});
test('new401or403stops a multi-request batch before another job and saved gate blocks restart',async()=>{
 for(const status of [401,403])await fixture(async out=>{
  let calls=0;
  const args={out,maxRequests:6,nowMs:()=>now,sleep:async()=>{},rebuild:false,fetchImpl:async()=>{calls++;return new Response('denied',{status});}};
  const first=await runBatch(args);
  assert.equal(calls,1);assert.equal(first.results.length,1);assert.equal(first.fetched,false);
  const checkpoint=await readFile(path.join(out,'collection-state.json'),'utf8');
  const second=await runBatch(args);
  assert.equal(calls,1);assert.equal(second.results.length,0);assert.equal(second.blockedReason,'source_access_backoff');
  assert.equal(await readFile(path.join(out,'collection-state.json'),'utf8'),checkpoint);
 });
});
test('legacy saved Saudi401 prevents dueEgypt request and malformed date fails beforefetch',async()=>{
 await fixture(async out=>{
  let calls=0;
  const state={schemaVersion:1,cursors:{'egypt/global':{done:false,page:11}},failures:[{key:'saudi-arabia/global',error:'Error: OFF 401 Unauthorized',nextAttemptAt:until}]};
  const file=path.join(out,'collection-state.json');
  await writeFile(file,JSON.stringify(state));
  const args={out,maxRequests:1,nowMs:()=>now,rebuild:false,fetchImpl:async()=>{calls++;throw Error('unexpectedrequest');}};
  const result=await runBatch(args);assert.equal(calls,0);assert.equal(result.blockedUntil,until);
  state.failures[0].nextAttemptAt='bad';await writeFile(file,JSON.stringify(state));
  await assert.rejects(runBatch(args));assert.equal(calls,0);
 });
});
test('watchdog defers wholeproducts source while independentprices remain ready',()=>{
 const tasks=[{id:'product-bank',priority:1,status:'ready',dependsOn:[],nextAction:'Collect'},{id:'prices',priority:2,status:'ready',dependsOn:[],nextAction:'Review prices'}];
 const queue={schemaVersion:1,stallMinutes:60,tasks};
 const sourceState={cursors:{'egypt/global':{done:false,page:11}},failures:[{error:'OFF 401',nextAttemptAt:until}]};
 const result=auditWork(queue,{now:new Date(now).toISOString(),usage:{ordinaryUsageAllowed:true,primaryUsedPercent:77,weeklyUsedPercent:87},sourceState});
 assert.equal(result.nextTask.id,'prices');
 assert.equal(result.deferredTasks[0].reason,'source_access_backoff');
 assert.equal(result.deferredTasks[0].until,until);
 sourceState.failures[0].nextAttemptAt='bad';
 assert.equal(auditWork(queue,{now:new Date(now).toISOString(),usage:{ordinaryUsageAllowed:true,primaryUsedPercent:77,weeklyUsedPercent:87},sourceState}).deferredTasks[0].reason,'source_state_unavailable');
});
