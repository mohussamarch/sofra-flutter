import test from 'node:test';
import assert from 'node:assert/strict';
import {talabatCatalogCandidates as read,assertCurrencyPriceMetric} from './partner-catalog-candidates.mjs';
const context=()=>({metric:'currency-amount',country:'EG',currency:'EGP',city:'synthetic-city',storeKey:'synthetic-store',chainId:'test-chain',vendorId:'test-vendor',evidenceId:'synthetic-response',catalogSha256:'a'.repeat(64),accessScope:'authorized-partner-vendor',observedAt:'2026-10-14T10:20:00Z'});
test('official inflation APIs and percent/index values cannot masquerade as price feeds',()=>{
 for(const value of [{metric:'percent-change',unit:'SAR'},{metric:'currency-amount',unit:'%'},{metric:'currency-amount',unit:'SAR',endpoint:'/v1/stats/DPV_CLI_CHANGE_MONTH'}])assert.throws(()=>assertCurrencyPriceMetric(value));
 assert.doesNotThrow(()=>assertCurrencyPriceMetric({metric:'currency-amount',unit:'SAR'}));
});
const page=()=>({page_number:1,total_pages:2,products:[{sku:'test',title:'Synthetic milk 1L label',price:40,barcodes:['123'],active:true}]});
test('adapter itself rejects a rate endpoint even when given a currency context',()=>{
 assert.throws(()=>read(page(),{...context(),endpoint:'/v1/stats/DPV_CLI_CHANGE_MONTH'}),/endpoint/);
});
test('acquisition timestamp must be UTC and calendar-valid, not normalized local time',()=>{
 for(const observedAt of ['2026-02-30T10:20:00Z','2026-10-14T10:20:00','2026-10-14T10:20:00+03:00'])assert.throws(()=>read(page(),{...context(),observedAt}));
 assert.doesNotThrow(()=>read(page(),{...context(),observedAt:'2026-10-14T10:20:00.123Z'}));
});
test('catalog read preserves price but cannot infer packs, stock, effective date or runtime',()=>{
 const result=read(page(),context()),p=result.candidates[0];assert.equal(p.amount,40);assert.equal(p.pack,null);assert.equal(p.priceAsOf,null);assert.equal(p.availability,null);assert.equal(p.runtimeReady,false);assert.equal(p.reuseApproved,false);assert.equal(p.unitPrice,null);assert.equal(result.nextPage,2);assert.equal(result.completeCatalog,false);
});
test('vendor pages never deduplicate repeated SKUs silently',()=>{const p=page();p.products.push({...p.products[0],price:45});assert.throws(()=>read(p,context()),/duplicate/);});
test('country currency, city and access scope are required independently',()=>{
 for(const edit of [{currency:'SAR'},{city:null},{vendorId:''},{accessScope:'all-stores'},{catalogSha256:null}])assert.throws(()=>read(page(),{...context(),...edit}));
});
test('weight-based source fields cannot silently become kilogram price or piece weight',()=>{
 const p=page();p.products[0].is_sold_by_weight=true;p.products[0].weight_specifications={base_weight:1.5,base_weight_unit:'KG',average_weight_per_piece:3.2};
 const result=read(p,context()).candidates[0];assert.deepEqual(result.sourceWeightSpecifications,p.products[0].weight_specifications);assert.equal(result.pack,null);assert.equal(result.unitPrice,null);
 result.sourceWeightSpecifications.base_weight=99;assert.equal(p.products[0].weight_specifications.base_weight,1.5);
});
test('inactive listing is unavailable; invalid prices and pagination fail closed',()=>{
 const p=page();p.products[0].active=false;assert.equal(read(p,context()).candidates[0].availability,false);
 for(const value of [null,0,-1,Infinity,'40']){p.products[0].price=value;assert.throws(()=>read(p,context()));}
 const q=page();q.page_number=3;assert.throws(()=>read(q,context()));
});
