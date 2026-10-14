import assert from 'node:assert/strict';
const currency={EG:'EGP',SA:'SAR'};
const text=v=>typeof v==='string'&&v.trim().length>0;
export function assertCurrencyPriceMetric({metric,unit,endpoint=''}){
 assert.equal(metric,'currency-amount','Inflation rates and index points are not item prices');
 assert.ok(['EGP','SAR'].includes(unit),'Explicit supported currency required');
 assert.ok(!/DPV_CLI_CHANGE_|\bCPI\b|percent|inflation/i.test(endpoint),'Index/rate endpoint cannot become a currency price source');
}

/** Offline reader for an authorized partner export, never a consumer scraper. */
export function talabatCatalogCandidates(response,context){
 const ctx=structuredClone(context),input=structuredClone(response);
 assertCurrencyPriceMetric({metric:ctx.metric,unit:ctx.currency,endpoint:ctx.endpoint});
 assert.ok(currency[ctx.country]===ctx.currency,'Country/currency mismatch');
 for(const key of ['city','storeKey','chainId','vendorId','evidenceId'])assert.ok(text(ctx[key]),'Explicit branch and source identity required: '+key);
 assert.ok(typeof ctx.observedAt==='string'&&/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z$/.test(ctx.observedAt),'UTC acquisition timestamp required');
 const observed=Date.parse(ctx.observedAt);
 assert.ok(Number.isFinite(observed)&&new Date(observed).toISOString().slice(0,19)===ctx.observedAt.slice(0,19),'Invalid acquisition calendar date');
 assert.ok(/^[a-f0-9]{64}$/.test(ctx.catalogSha256),'Exact archived response hash required');
 assert.equal(ctx.accessScope,'authorized-partner-vendor','No all-stores consumer access inferred');
 assert.ok(Number.isInteger(input.page_number)&&input.page_number>=1);
 assert.ok(Number.isInteger(input.total_pages)&&input.total_pages>=input.page_number);
 assert.ok(Array.isArray(input.products));
 const ids=new Set(),candidates=[];
 for(const p of input.products){
  assert.ok(text(p.sku)&&!ids.has(p.sku),'Missing/duplicate SKU in vendor page');ids.add(p.sku);
  assert.ok(text(p.title),'Missing product name');
  assert.ok(typeof p.price==='number'&&Number.isFinite(p.price)&&p.price>0,'Unknown/free/invalid prices require separate review');
  assert.ok(p.active==null||typeof p.active==='boolean','Invalid activation flag');
  assert.ok(p.is_sold_by_weight==null||typeof p.is_sold_by_weight==='boolean');
  assert.ok(p.barcodes==null||Array.isArray(p.barcodes)&&p.barcodes.every(text));
  candidates.push({
   schemaVersion:1,id:JSON.stringify([ctx.country,ctx.chainId,ctx.vendorId,p.sku,ctx.evidenceId]),
   country:ctx.country,currency:ctx.currency,kind:'retail',channel:'delivery-app',
   city:ctx.city,storeKey:ctx.storeKey,chainId:ctx.chainId,vendorId:ctx.vendorId,sku:p.sku,
   label:p.title,barcodes:p.barcodes??[],amount:p.price,observedAt:ctx.observedAt,
   // Acquisition time is not an upstream effective-price date.
   priceAsOf:null,pack:null,itemKey:null,canonicalFoodId:null,unitPrice:null,
   availability:p.active===false?false:null,listedActive:p.active??null,
   soldByWeight:p.is_sold_by_weight??null,sourceWeightSpecifications:p.weight_specifications??null,
   offer:{discounted:null,validFrom:null,validUntil:null},taxIncluded:null,deliveryFee:null,serviceFee:null,
   evidence:{id:ctx.evidenceId,sha256:ctx.catalogSha256,page:input.page_number,
    documentationUrl:'https://developer.talabat.com/api-specifications',accessScope:ctx.accessScope},
   reuseApproved:false,evidenceChecked:false,runtimeReady:false,
   remainingReview:['permission-to-redistribute','store-and-city','item-and-barcode','pack-and-price-basis','effective-date','availability','offers-tax-and-fees'],
  });
 }
 return {schemaVersion:1,candidates,page:input.page_number,totalPages:input.total_pages,
  completeCatalog:false,nextPage:input.page_number<input.total_pages?input.page_number+1:null,
  note:'One authorized vendor page only; no live connection, approval or full catalog claim.'};
}
