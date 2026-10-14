import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {validateOfficialRangeBank,selectHistoricalRanges} from './official-price-ranges.mjs';
const bank=JSON.parse(await readFile('data/prices/research/official/msit-2025-06-ranges.json','utf8'));
test('36 visually transcribed monthly intervals preserve bounds and remain separate from point prices',()=>{
 const result=validateOfficialRangeBank(bank);
 assert.equal(result.observations.length,36);
 assert.equal(result.runtimeReady,false);
 assert.deepEqual(result.observations.find(r=>r.label==='تين برشومي').range,{minimum:35,maximum:45});
 assert.equal(result.observations.find(r=>r.id.endsWith('-26')).label,'ف. رومى');
 assert.equal(result.observations.find(r=>r.id.endsWith('-26')).canonicalFoodId,null);
 assert.equal(result.pricePeriod,'2025-06');
 assert.ok(result.observations.every(r=>r.mean===null&&r.priceAsOf===null&&r.runtimeApproved===false));
 assert.equal(selectHistoricalRanges(result,{country:'EG',currency:'EGP',period:'2025-06',category:'fish'}).length,4);
 assert.deepEqual(result.observations.find(r=>r.label==='ماكريل').range,{minimum:160,maximum:200});
 result.observations[0].range.minimum=999;
 assert.equal(bank.observations[0].range.minimum,47);
});
test('no automatic current-price lookup or country/currency mixing',()=>{
 assert.throws(()=>selectHistoricalRanges(bank,{country:'EG',currency:'EGP'}));
 assert.throws(()=>selectHistoricalRanges(bank,{country:'SA',currency:'SAR',period:'2025-06'}));
 assert.deepEqual(selectHistoricalRanges(bank,{country:'EG',currency:'EGP',period:'2026-06'}),[]);
});
test('invalid bounds, dates, units, source and invented midpoint/runtime flags reject',()=>{
 const changed=(fn)=>{const b=structuredClone(bank);fn(b);return b;};
 for(const fn of [
 b=>b.observations[0].range.minimum=99,
 b=>b.observations[0].range.maximum=-1,
 b=>b.observations[0].range.minimum=null,
 b=>b.observations[0].mean=48.5,
 b=>b.observations[0].priceAsOf='2025-06-01',
 b=>b.observations[0].runtimeApproved=true,
 b=>b.observations[0].quantity.unit='count',
 b=>b.observations[0].quantity.value=0,
 b=>b.observations[0].page=0,
 b=>b.pricePeriod='2025-13',
 b=>b.pricePeriod='2027-06',
 b=>b.currency='SAR',
 b=>b.source.url='https://example.com/x.pdf',
 b=>b.source.sha256='bad',
 b=>b.observations.push(structuredClone(b.observations[0])),
 b=>b.reuseApproved=true]) assert.throws(()=>validateOfficialRangeBank(changed(fn)));
});
