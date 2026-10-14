import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {buildResearchPriceIndex} from './build-research-index.mjs';
test('actual price index rebuilds exactly and cannot publish unreviewed research',async()=>{
 const built=await buildResearchPriceIndex(),stored=JSON.parse(await readFile('data/prices/research/observations.json','utf8'));
 assert.deepEqual(stored,built);assert.equal(stored.observationCount,34);
 assert.equal(stored.excluded.length,1);assert.equal(stored.runtimePriceApprovals,0);
 assert.ok(stored.entries.every(e=>!e.runtimeReady&&!e.quote.reuseApproved&&!e.quote.evidenceChecked&&e.quote.itemKey===null));
 assert.deepEqual(stored.cohorts.map(c=>[c.country,c.retail,c.initiative]),[['EG',5,25],['SA',4,0]]);
});
test('actual extracted fragments and public API response archives match their scoped hashes',async()=>{
 const bank=JSON.parse(await readFile('data/prices/research/egypt-sources.json','utf8'));
 const fragments=bank.observations.filter(q=>q.evidence.literal!==null);
 assert.equal(fragments.length,5);
 for(const q of fragments)assert.equal(createHash('sha256').update(q.evidence.literal).digest('hex'),q.evidence.evidenceTextUtf8Sha256);
 const root='data/prices/research/open-prices/';
 const probe=JSON.parse(await readFile(root+'probe.json','utf8'));assert.equal(probe.requests.length,2);
 for(const r of probe.requests){
 assert.equal(r.httpStatus,200);assert.equal(r.countryCoverageVerified,false);
 const body=await readFile(root+r.responseFile);assert.equal(body.length,r.bytes);
 assert.equal(createHash('sha256').update(body).digest('hex'),r.sha256);
 const data=JSON.parse(body);assert.equal(data.total,r.totalCurrencyObservations);
 assert.equal(data.items.length,1);
 }
});
