import assert from 'node:assert/strict';
/** A pending HTTP access refusal applies to this upstream, across market jobs. */
export function sourceAccessUntil(state,nowMs){
 assert.ok(Number.isFinite(nowMs),'Valid current time required');
 const failures=state?.failures??[];
 assert.ok(Array.isArray(failures),'Invalid source failure state');
 let until=null;
 for(const failure of failures){
  if(!/\bOFF (401|403)\b/.test(String(failure?.error)))continue;
  assert.ok(typeof failure.nextAttemptAt==='string'&&Number.isFinite(Date.parse(failure.nextAttemptAt)),'Invalid source access backoff');
  const gate=Date.parse(failure.nextAttemptAt);
  if(gate>nowMs&&(!until||gate>Date.parse(until)))until=failure.nextAttemptAt;
 }
 return until;
}
