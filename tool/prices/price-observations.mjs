import assert from 'node:assert/strict';

const currencies={EG:'EGP',SA:'SAR'};
function day(value){
 assert.ok(typeof value==='string'&&/^\d{4}-\d{2}-\d{2}$/.test(value),'Exact date required');
 const n=Date.parse(value+'T00:00:00.000Z');
 assert.ok(Number.isFinite(n)&&new Date(n).toISOString().slice(0,10)===value,'Invalid date');
 return n;
}
function stamp(value){
 assert.ok(typeof value==='string','Retrieval date required');
 if(/^\d{4}-\d{2}-\d{2}$/.test(value))return day(value);
 assert.ok(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z$/.test(value),'UTC retrieval stamp required');
 const n=Date.parse(value);
 assert.ok(Number.isFinite(n)&&new Date(n).toISOString().slice(0,19)===value.slice(0,19),'Invalid timestamp');
 return n;
}
export function normalizePriceQuote(input){
 const q=structuredClone(input);
 assert.equal(q.schemaVersion,1);
 assert.ok(typeof q.id==='string'&&q.id.trim()&&q.id===q.id.trim());
 assert.ok(currencies[q.country]&&q.currency===currencies[q.country],'Country/currency mismatch');
 assert.ok(['retail','wholesale','statistical','initiative','community'].includes(q.kind));
 assert.ok(typeof q.label==='string'&&q.label.trim());
 assert.ok(Number.isFinite(q.amount)&&q.amount>0,'Unknown/free gift requires separate review');
 const url=new URL(q.sourceUrl);assert.equal(url.protocol,'https:');
 stamp(q.observedAt);
 if(q.priceAsOf!==null)day(q.priceAsOf);
 assert.ok(q.availability===null||typeof q.availability==='boolean');
 assert.ok(typeof q.reuseApproved==='boolean'&&typeof q.evidenceChecked==='boolean');
 for(const f of ['itemKey','city','storeKey'])
 assert.ok(q[f]===null||(typeof q[f]==='string'&&q[f].trim()&&q[f]===q[f].trim()));
 assert.ok(q.offer&&(q.offer.discounted===null||typeof q.offer.discounted==='boolean'));
 if(q.offer.validFrom!==null)day(q.offer.validFrom);
 if(q.offer.validUntil!==null)day(q.offer.validUntil);
 let normalized=null;
 if(q.pack!==null){
 assert.ok(q.pack&&Number.isFinite(q.pack.value)&&q.pack.value>0);
 const scale={g:['kg',.001],kg:['kg',1],ml:['l',.001],l:['l',1],count:['count',1]};
 assert.ok(Object.hasOwn(scale,q.pack.unit),'No inferred bag/count/weight conversion');
 const [unit,factor]=scale[q.pack.unit],quantity=q.pack.value*factor;
 const unitPrice=q.amount/quantity;
 assert.ok(Number.isFinite(quantity)&&quantity>0&&Number.isFinite(unitPrice));
 normalized={quantity,unit,unitPrice};
 }
 return {quote:q,normalized,runtimeReady:false,derived:true};
}

/** Reviewed and comparable estimates only. No mutation or runtime publication. */
export function estimateComparablePrices(inputs,context){
 assert.ok(currencies[context.country]);
 assert.ok(typeof context.city==='string'&&context.city.trim());
 assert.ok(typeof context.itemKey==='string'&&context.itemKey.trim());
 assert.ok(Number.isFinite(context.maxAgeDays)&&context.maxAgeDays>=0,'Explicit age policy required');
 const now=day(context.now),ids=new Set(),excluded=[],latest=new Map();
 // Ordering evidence is separate from eligibility. A newer unavailable/unknown
 // quote blocks an older quote; it never resurrects stale availability.
 const rank=q=>[q.priceAsOf===null?day(q.observedAt.slice(0,10)):day(q.priceAsOf),stamp(q.observedAt)];
 const signature=v=>JSON.stringify([v.quote.priceAsOf,v.quote.amount,v.quote.pack?.value??null,v.quote.pack?.unit??null,
 v.normalized?.unitPrice??null,v.normalized?.unit??null,v.quote.availability,
 v.quote.offer.discounted,v.quote.offer.validFrom,v.quote.offer.validUntil,
 v.quote.reuseApproved,v.quote.evidenceChecked]);
 for(const input of inputs){
 const value=normalizePriceQuote(input),q=value.quote;
 assert.ok(!ids.has(q.id),'Duplicate quote ID');ids.add(q.id);
 const reason=q.country!==context.country?'country':
 q.kind!=='retail'?'market_kind':
 q.city!==context.city?'city':
 q.itemKey!==context.itemKey?'identity':
 !q.storeKey?'missing_store':null;
 if(reason){excluded.push({id:q.id,reason});continue;}
 const prior=latest.get(q.storeKey);
 if(!prior){latest.set(q.storeKey,value);continue;}
 const a=rank(q),b=rank(prior.quote),order=a[0]-b[0]||a[1]-b[1];
 if(order===0){
 assert.equal(signature(value),signature(prior),'Conflicting latest store evidence');
 excluded.push({id:q.id,reason:'duplicate_same_store'});
 }else if(order>0){
 excluded.push({id:prior.quote.id,reason:'older_same_store'});latest.set(q.storeKey,value);
 }else excluded.push({id:q.id,reason:'older_same_store'});
 }
 const selected=[];
 for(const value of latest.values()){
 const q=value.quote,n=value.normalized;
 const reason=!q.reuseApproved?'reuse_not_reviewed':
 !q.evidenceChecked?'evidence_not_reviewed':
 q.availability!==true?'availability':
 q.priceAsOf===null?'missing_price_date':
 day(q.priceAsOf)>now?'future_price_date':
 (now-day(q.priceAsOf))/86400000>context.maxAgeDays?'stale':
 !n?'unknown_quantity':
 q.offer.discounted===null?'unknown_offer_status':
 q.offer.discounted&&(!context.includeOffers||q.offer.validFrom===null||q.offer.validUntil===null||
 day(q.offer.validFrom)>now||day(q.offer.validUntil)<now)?'offer':null;
 if(reason)excluded.push({id:q.id,reason});else selected.push(value);
 }
 const units=new Set(selected.map(v=>v.normalized.unit));
 assert.ok(units.size<=1,'Mass, volume and count prices are not interchangeable');
 const values=selected.map(v=>v.normalized.unitPrice);
 return {country:context.country,currency:currencies[context.country],city:context.city,
 itemKey:context.itemKey,unit:[...units][0]??null,
 meanUnitPrice:values.length?values.reduce((a,b)=>a+b,0)/values.length:null,
 range:values.length?[Math.min(...values),Math.max(...values)]:null,
 eligibleQuotes:values.length,storeCount:selected.length,estimated:true,runtimeReady:false,
 method:'arithmetic mean after newest comparable evidence per store; no older fallback',
 effectiveDate:selected.map(v=>v.quote.priceAsOf).sort().at(-1)??null,
 selectedIds:selected.map(v=>v.quote.id),excluded};
}
