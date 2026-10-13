import test from 'node:test';
import assert from 'node:assert/strict';
import {auditWork} from './watchdog.mjs';
const now='2026-10-13T08:00:00Z';
const usage={ordinaryUsageAllowed:true,primaryUsedPercent:20,weeklyUsedPercent:10};
const task=(id,priority,status='ready',dependsOn=[])=>({id,priority,status,dependsOn,nextAction:'Implement '+id});
const queue=tasks=>({schemaVersion:1,stallMinutes:60,lastProgress:{at:'2026-10-13T07:55:00Z',taskId:tasks[0].id,summary:'Actual implementation',evidence:['source.dart']},tasks});
test('source backoff never blocks independent ready implementation',()=>{
 const q=queue([task('measure',1),{...task('product-bank',9,'waiting'),blockedUntil:'2026-10-13T09:00:00Z'}]);
 const a=auditWork(q,{now,usage,sourceState:{cursors:{'egypt/global':{done:false,page:7,nextAttemptAt:'2026-10-13T09:00:00Z'}}}});
 assert.equal(a.reason,'ready_work_available');assert.equal(a.nextTask.id,'measure');assert.equal(a.deferredTasks[0].id,'product-bank');
});
test('active owner continues and stale work asks why without spawning another writer',()=>{
 const q=queue([{...task('active',1,'active'),lastAttemptAt:'2026-10-13T07:50:00Z'},task('other',2)]);
 assert.equal(auditWork(q,{now,usage}).reason,'work_in_progress');
 q.lastProgress.at='2026-10-13T06:00:00Z';
 const a=auditWork(q,{now,usage});assert.equal(a.reason,'stalled_active_task');assert.equal(a.nextTask,null);assert.ok(a.action.includes('owner'));
});
test('usage unknown, prohibited and either90percent prevent expensive work',()=>{
 const q=queue([task('x',1)]);
 assert.equal(auditWork(q,{now}).reason,'usage_unknown');
 for(const u of [{...usage,ordinaryUsageAllowed:false},{...usage,primaryUsedPercent:90},{...usage,weeklyUsedPercent:90}]) assert.equal(auditWork(q,{now,usage:u}).reason,'quota_reserve');
});
test('dependencies gate work; cyclic/unknown references are invalid',()=>{
 const q=queue([task('a',1,'done'),task('b',2,'ready',['a'])]);assert.equal(auditWork(q,{now,usage}).nextTask.id,'b');
 q.tasks[0].dependsOn=['b'];assert.throws(()=>auditWork(q,{now,usage}),/cycle/i);
 q.tasks[0].dependsOn=['absent'];assert.throws(()=>auditWork(q,{now,usage}),/dependency/i);
});
test('all waiting reports actual source retry; all done is explicit',()=>{
 const q=queue([task('product-bank',1,'waiting')]);
 const a=auditWork(q,{now,usage,sourceState:{cursors:{x:{done:false,page:1,nextAttemptAt:'2026-10-13T09:00:00Z'}}}});
 assert.equal(a.reason,'waiting_for_external');assert.equal(a.nextRetryAt,'2026-10-13T09:00:00Z');
 q.tasks[0].status='done';assert.equal(auditWork(q,{now,usage}).reason,'all_tasks_done');
});
test('due source cursor becomes runnable without editing the saved queue',()=>{
 const q=queue([{...task('product-bank',1,'waiting'),blockedUntil:'2026-10-13T10:00:00Z'}]);
 const before=JSON.stringify(q);
 const a=auditWork(q,{now,usage,sourceState:{cursors:{x:{done:false,page:1,nextAttemptAt:'2026-10-13T07:59:00Z'}}}});
 assert.equal(a.nextTask.id,'product-bank');assert.equal(JSON.stringify(q),before);
});

test('exhausted current source pages become expansion work, never bank completion',()=>{
 const q=queue([task('product-bank',1,'waiting')]);
 const a=auditWork(q,{now,usage,sourceState:{cursors:{x:{done:true,page:2}}}});
 assert.equal(a.nextTask.id,'product-bank');assert.ok(a.nextTask.nextAction.includes('expansion'));
});

test('old progress from another task does not falsely stall a fresh owner',()=>{
 const q=queue([task('finished',0,'done'),{...task('active',1,'active'),lastAttemptAt:'2026-10-13T07:59:00Z'}]);
 q.lastProgress.at='2026-10-13T06:00:00Z';
 assert.equal(auditWork(q,{now,usage}).reason,'work_in_progress');
});
test('unrelated recent progress cannot hide a stalled owner',()=>{
 const q=queue([task('finished',0,'done'),{...task('active',1,'active'),lastAttemptAt:'2026-10-13T06:00:00Z'}]);
 const a=auditWork(q,{now,usage});assert.equal(a.reason,'stalled_active_task');
 assert.deepEqual(a.stalledTasks,['active']);
});
test('empty or malformed source cursors require diagnosis before collection',()=>{
 const q=queue([task('product-bank',1,'waiting')]);
 for(const cursors of [{},[],{x:null},{x:{done:'false'}}]){
  const a=auditWork(q,{now,usage,sourceState:{cursors}});
  assert.equal(a.reason,'waiting_for_external');assert.equal(a.nextTask,null);
  assert.equal(a.deferredTasks[0].reason,'source_state_unavailable');
 }
});
