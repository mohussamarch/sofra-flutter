import assert from 'node:assert/strict';
const month=v=>typeof v==='string'&&/^\d{4}-(0[1-9]|1[0-2])$/.test(v);
const positive=v=>typeof v==='number'&&Number.isFinite(v)&&v>0;
export function validateOfficialRangeBank(bank){
 assert.equal(bank.schemaVersion,1);
 assert.equal(bank.kind,'official_monthly_retail_range');
 assert.equal(bank.researchOnly,true);assert.equal(bank.runtimeReady,false);assert.equal(bank.reuseApproved,false);
 assert.equal(bank.country,'EG');assert.equal(bank.currency,'EGP');
 assert.ok(month(bank.pricePeriod),'Explicit valid monthly period required');
 assert.ok(typeof bank.observedAt==='string'&&Number.isFinite(Date.parse(bank.observedAt)),'Observed timestamp required');
 assert.ok(bank.pricePeriod<=bank.observedAt.slice(0,7),'Price period cannot follow acquisition');
 const url=new URL(bank.source.url);
 assert.equal(url.protocol,'https:');assert.ok(['msit.gov.eg','www.msit.gov.eg'].includes(url.hostname));
 assert.ok(/^[a-f0-9]{64}$/.test(bank.source.sha256));assert.equal(bank.source.redistributedInGit,false);
 assert.equal(bank.source.license,null);assert.equal(bank.source.tablePage,15);
 assert.ok(Array.isArray(bank.observations)&&bank.observations.length>0);
 const ids=new Set();
 for(const row of bank.observations){
  assert.ok(typeof row.id==='string'&&row.id.trim()&&!ids.has(row.id));ids.add(row.id);
  assert.ok(typeof row.label==='string'&&row.label.trim());assert.ok(typeof row.category==='string'&&row.category.trim());
  assert.equal(row.page,bank.source.tablePage);assert.equal(row.column,'سعر سوق التجزئة');
  assert.equal(row.quantity.value,1);assert.equal(row.quantity.unit,'kg');assert.equal(row.quantity.sourceUnit,'ج/ك');
  assert.ok(positive(row.range.minimum)&&positive(row.range.maximum)&&row.range.minimum<=row.range.maximum,'Ordered known positive interval required');
  assert.equal(row.mean,null);assert.equal(row.priceAsOf,null);assert.equal(row.runtimeApproved,false);
  assert.equal(row.canonicalFoodId,null);assert.equal(row.transcriptionStatus,'visual-transcription-unreviewed');
 }
 return structuredClone(bank);
}
export function selectHistoricalRanges(bank,{country,currency,period,category}={}){
 const checked=validateOfficialRangeBank(bank);
 assert.ok(month(period),'Explicit historical month required; no current-price fallback');
 assert.equal(country,checked.country);assert.equal(currency,checked.currency);
 return period===checked.pricePeriod?checked.observations.filter(r=>category===undefined||r.category===category):[];
}
