import test from 'node:test';
import assert from 'node:assert/strict';
import {normalizePriceQuote,estimateComparablePrices} from './price-observations.mjs';
const quote=(patch={})=>({
 schemaVersion:1,id:'test-only',country:'EG',currency:'EGP',kind:'retail',
 label:'Synthetic test food',amount:20,pack:{value:500,unit:'g'},
 sourceUrl:'https://example.org/test-only',observedAt:'2026-10-14T08:00:00.000Z',
 priceAsOf:'2026-10-13',availability:true,
 offer:{discounted:false,validFrom:null,validUntil:null},reuseApproved:true,evidenceChecked:true,
 itemKey:'test-reviewed-identity',city:'test-city',storeKey:'test-store',...patch
});
test('normalizes only declared mass/volume and preserves original quote',()=>{
 const q=quote();const n=normalizePriceQuote(q);
 assert.deepEqual(n.normalized,{quantity:.5,unit:'kg',unitPrice:40});
 assert.equal(q.pack.unit,'g');assert.equal(n.runtimeReady,false);
 assert.deepEqual(normalizePriceQuote(quote({pack:{value:1,unit:'l'}})).normalized,
 {quantity:1,unit:'l',unitPrice:20});
});
test('unknown pack has unknown unit price; count cannot become kilos',()=>{
 assert.equal(normalizePriceQuote(quote({pack:null})).normalized,null);
 assert.deepEqual(normalizePriceQuote(quote({pack:{value:4,unit:'count'}})).normalized,
 {quantity:4,unit:'count',unitPrice:5});
 assert.throws(()=>normalizePriceQuote(quote({pack:{value:2,unit:'bag'}})));
});
test('invalid currency, negative/zero price and dates never silently enter estimates',()=>{
 for(const p of [{currency:'SAR'},{amount:-1},{amount:0},
 {priceAsOf:'2026-02-30'},{pack:{value:0,unit:'g'}},
 {observedAt:'2026-13-01T00:00:00Z'}])
 assert.throws(()=>normalizePriceQuote(quote(p)));
});
test('eligibility separates retail from wholesale/statistical and enforces country city identity and age',()=>{
 const rows=[quote(),quote({id:'wholesale',kind:'wholesale'}),
 quote({id:'stat',kind:'statistical'}),quote({id:'other-city',city:'other'}),
 quote({id:'stale',priceAsOf:'2024-01-01'}),quote({id:'unknown-date',priceAsOf:null}),
 quote({id:'not-reviewed',itemKey:null}),quote({id:'unavailable',availability:false}),
 quote({id:'no-rights',reuseApproved:false}),quote({id:'unverified',evidenceChecked:false})].map((q,i)=>({...q,storeKey:'independent-store-'+i}));
 const r=estimateComparablePrices(rows,{country:'EG',city:'test-city',
 itemKey:'test-reviewed-identity',now:'2026-10-14',maxAgeDays:7});
 assert.equal(r.eligibleQuotes,1);assert.equal(r.meanUnitPrice,40);
 assert.equal(r.excluded.length,9);assert.equal(r.estimated,true);
});
test('one latest eligible quote per store prevents duplicate weighting; range and count remain visible',()=>{
 const rows=[quote(),quote({id:'same-store-old',amount:100,priceAsOf:'2026-10-12'}),
 quote({id:'other-store',amount:30,storeKey:'store-2'})];
 const r=estimateComparablePrices(rows,{country:'EG',city:'test-city',
 itemKey:'test-reviewed-identity',now:'2026-10-14',maxAgeDays:7});
 assert.equal(r.eligibleQuotes,2);assert.equal(r.meanUnitPrice,50);
 assert.deepEqual(r.range,[40,60]);assert.equal(r.storeCount,2);
 assert.equal(r.effectiveDate,'2026-10-13');
});
test('discounts, unknown expiry, missing stores and mixed mass/volume never become automatic averages',()=>{
 const rows=[quote({offer:{discounted:true,validFrom:null,validUntil:null}}),
 quote({id:'missing-store',storeKey:null}),
 quote({id:'future-offer',offer:{discounted:true,validFrom:'2026-10-20',validUntil:'2026-10-30'}}),
 quote({id:'unknown-offer',offer:{discounted:null,validFrom:null,validUntil:null}})].map((q,i)=>({...q,storeKey:q.storeKey===null?null:'offer-store-'+i}));
 const context={country:'EG',city:'test-city',itemKey:'test-reviewed-identity',
 now:'2026-10-14',maxAgeDays:7,includeOffers:true};
 assert.equal(estimateComparablePrices(rows,context).meanUnitPrice,null);
 assert.throws(()=>estimateComparablePrices([quote(),quote({id:'volume',
 storeKey:'store-2',pack:{value:1,unit:'l'}})],context));
});


test('newer unavailable or expired store evidence cannot resurrect an older eligible price',()=>{
 const context={country:'EG',city:'test-city',itemKey:'test-reviewed-identity',
 now:'2026-10-14',maxAgeDays:7,includeOffers:true};
 for(const patch of [
 {availability:false},
 {offer:{discounted:true,validFrom:'2026-10-10',validUntil:'2026-10-13'}},
 {offer:{discounted:null,validFrom:null,validUntil:null}}]){
 const rows=[quote({id:'old',priceAsOf:'2026-10-12'}),
 quote({id:'latest',priceAsOf:'2026-10-13',amount:30,...patch})];
 const result=estimateComparablePrices(rows,context);
 assert.equal(result.meanUnitPrice,null);assert.equal(result.storeCount,0);
 }
 assert.throws(()=>estimateComparablePrices([
 quote({id:'conflict-1'}),quote({id:'conflict-2',amount:30})],context),
 /Conflicting latest/);
 const unknown=quote({id:'unknown-asof',priceAsOf:null});
 const known=quote({id:'known-asof',priceAsOf:'2026-10-14'});
 for(const pair of [[unknown,known],[known,unknown]])
 assert.throws(()=>estimateComparablePrices(pair,context),/Conflicting latest/);
});
