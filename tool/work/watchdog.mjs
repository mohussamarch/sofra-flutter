import {sourceAccessUntil} from '../food/source-access.mjs';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

function time(v){const n=Date.parse(v);assert.ok(typeof v==='string'&&Number.isFinite(n),'Invalid work timestamp');return n;}
function validate(q){
 assert.equal(q.schemaVersion,1);assert.ok(Array.isArray(q.tasks));
 assert.ok(Number.isFinite(q.stallMinutes)&&q.stallMinutes>0);
 const byId=new Map();
 for(const t of q.tasks){
  assert.ok(typeof t.id==='string'&&t.id.trim()&&!byId.has(t.id),'Invalid/duplicate task');
  assert.ok(Number.isInteger(t.priority)&&t.priority>=0);
  assert.ok(['ready','active','waiting','done','needs_user'].includes(t.status));
  assert.ok(typeof t.nextAction==='string'&&t.nextAction.trim());
  assert.ok(Array.isArray(t.dependsOn)&&new Set(t.dependsOn).size===t.dependsOn.length);byId.set(t.id,t);
  if(t.blockedUntil)time(t.blockedUntil);if(t.lastAttemptAt)time(t.lastAttemptAt);if(Object.hasOwn(t,'lastProgressAt'))time(t.lastProgressAt);
 }
 const visiting=new Set(),visited=new Set();
 function visit(id){assert.ok(byId.has(id),'Unknown dependency');assert.ok(!visiting.has(id),'Dependency cycle');if(visited.has(id))return;
  visiting.add(id);for(const dep of byId.get(id).dependsOn)visit(dep);visiting.delete(id);visited.add(id);
 }
 for(const id of byId.keys())visit(id);
 const p=q.lastProgress;
 if(p){time(p.at);assert.ok(byId.has(p.taskId));assert.ok(typeof p.summary==='string'&&p.summary.trim());assert.ok(Array.isArray(p.evidence)&&p.evidence.length>0&&p.evidence.every(v=>typeof v==='string'&&v.trim()));}
 return byId;
}

/** Read-only audit. Chooses work, never starts/kills a process or changes a queue. */
export function auditWork(queue,{now=new Date().toISOString(),usage,sourceState,quotaLimit=90}={}){
 assert.ok(Number.isInteger(quotaLimit)&&quotaLimit>=90&&quotaLimit<=99,'Invalid quota limit');
 const byId=validate(queue),nowMs=time(now),deferredTasks=[];
 const answer=(reason,nextTask=null,action='',extra={})=>({reason,nextTask:nextTask?{id:nextTask.id,nextAction:nextTask.nextAction}:null,action,deferredTasks,...extra});
 if(!usage||typeof usage.ordinaryUsageAllowed!=='boolean'||
   ![usage.primaryUsedPercent,usage.weeklyUsedPercent].every(v=>Number.isFinite(v)&&v>=0&&v<=100))return answer('usage_unknown',null,'Read current account limits before costly work');
 if(!usage.ordinaryUsageAllowed||usage.primaryUsedPercent>=quotaLimit||usage.weeklyUsedPercent>=quotaLimit)return answer('quota_reserve',null,'Save continuation and recheck later; do not buy/reset credits');
 const active=queue.tasks.filter(t=>t.status==='active');
 if(active.length){
  const stalled=active.filter(t=>{
   const recorded=[];
   if(Object.hasOwn(t,'lastProgressAt'))recorded.push(time(t.lastProgressAt));
   if(queue.lastProgress?.taskId===t.id)recorded.push(time(queue.lastProgress.at));
   const progress=recorded.length?Math.max(...recorded):(t.lastAttemptAt?time(t.lastAttemptAt):0);
   return nowMs-progress>=queue.stallMinutes*60000;
  });
  if(stalled.length)return answer('stalled_active_task',null,'Inspect existing owner/process and evidence; resume it or release ownership before another writer',{activeTasks:active.map(t=>t.id),stalledTasks:stalled.map(t=>t.id)});
  const first=active.sort((a,b)=>a.priority-b.priority)[0];
  return answer('work_in_progress',first,'Continue existing owner; do not start another writer');
 }
 let nextRetryAt=null;
 const candidates=[];
 for(const task of queue.tasks){
  if(task.status==='done')continue;
  if(task.status==='needs_user'){deferredTasks.push({id:task.id,reason:'needs_user'});continue;}
  if(task.dependsOn.some(id=>byId.get(id).status!=='done')){deferredTasks.push({id:task.id,reason:'dependency'});continue;}
  let until=task.blockedUntil??null;
  if(task.id==='product-bank'){
   let accessUntil;
   try{accessUntil=sourceAccessUntil(sourceState,nowMs);}catch{deferredTasks.push({id:task.id,reason:'source_state_unavailable'});continue;}
   if(accessUntil){deferredTasks.push({id:task.id,reason:'source_access_backoff',until:accessUntil});if(!nextRetryAt||time(accessUntil)<time(nextRetryAt))nextRetryAt=accessUntil;continue;}
   const cursors=sourceState?.cursors;
   if(!cursors||typeof cursors!=='object'||Array.isArray(cursors)||!Object.keys(cursors).length||
     Object.values(cursors).some(c=>!c||typeof c!=='object'||typeof c.done!=='boolean')){deferredTasks.push({id:task.id,reason:'source_state_unavailable'});continue;}
   const unfinished=Object.values(sourceState.cursors).filter(c=>!c.done);
   if(!unfinished.length){candidates.push({...task,nextAction:'Review source expansion and category gaps; ongoing bank is not complete'});continue;}
   const due=unfinished.some(c=>!c.nextAttemptAt||time(c.nextAttemptAt)<=nowMs);
   until=due?null:unfinished.map(c=>c.nextAttemptAt).sort()[0];
  }
  if(until&&time(until)>nowMs){
   deferredTasks.push({id:task.id,reason:task.blockedReason??'source_backoff',until});
   if(!nextRetryAt||time(until)<time(nextRetryAt))nextRetryAt=until;continue;
  }
  if(task.status==='waiting'&&!until&&task.id!=='product-bank'){deferredTasks.push({id:task.id,reason:task.blockedReason??'waiting_without_retry'});continue;}
  candidates.push(task);
 }
 if(candidates.length){candidates.sort((a,b)=>a.priority-b.priority);return answer('ready_work_available',candidates[0],'Execute the highest-priority available unit and record actual evidence');}
 if(queue.tasks.every(t=>t.status==='done'))return answer('all_tasks_done',null,'Review roadmap with user before closing ongoing research');
 return answer('waiting_for_external',null,'Record each reason and next retry; diagnose any unsatisfied dependencies',{nextRetryAt});
}

if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 const args=new Map();for(let i=2;i<process.argv.length;i+=2)args.set(process.argv[i],process.argv[i+1]);
 const q=JSON.parse(await readFile(args.get('--queue')??'docs/WORK-QUEUE.json','utf8'));
 let sourceState;try{sourceState=JSON.parse(await readFile('data/food/openfoodfacts/collection-state.json','utf8'));}catch{}
 const ordinary=args.get('--ordinary');
 const usage={ordinaryUsageAllowed:ordinary==='true'?true:ordinary==='false'?false:undefined,primaryUsedPercent:args.has('--primary')?Number(args.get('--primary')):NaN,weeklyUsedPercent:args.has('--weekly')?Number(args.get('--weekly')):NaN};
 console.log(JSON.stringify(auditWork(q,{now:args.get('--now')??new Date().toISOString(),usage,sourceState,quotaLimit:args.has('--quota-limit')?Number(args.get('--quota-limit')):90}),null,2));
}
