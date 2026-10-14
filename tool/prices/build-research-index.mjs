import {readFile,writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import assert from 'node:assert/strict';
import {normalizePriceQuote,estimateComparablePrices} from './price-observations.mjs';
const digest=b=>createHash('sha256').update(b).digest('hex');
const unit={g:'g',kg:'kg',L:'l',l:'l',mL:'ml',ml:'ml',cube:'count',piece:'count'};
export async function buildResearchPriceIndex(){
 const files=['data/prices/research/egypt-sources.json','data/prices/research/saudi-sources.json'];
 const banks=await Promise.all(files.map(async file=>{const bytes=await readFile(file);return {file,sha256:digest(bytes),bank:JSON.parse(bytes)}}));
 const entries=[],excluded=[];
 for(const {file,sha256,bank} of banks){
 assert.equal(bank.schemaVersion,1);assert.equal(bank.researchOnly,true);
 const sources=new Set(bank.sources.map(s=>s.id));assert.equal(sources.size,bank.sources.length);
 for(const raw of bank.observations){
 assert.ok(sources.has(raw.sourceId),'Missing source dossier');
 const eg=bank.country==='EG';
 if(!eg&&raw.verifiedPriceEvidence!==true){excluded.push({id:raw.id,reason:'unverified_snippet',sourceFile:file});continue;}
 const amount=eg?raw.price:raw.amount;
 const pack=eg?raw.pack:{value:raw.quantity,unit:raw.unit};
 assert.ok(pack&&unit[pack.unit],'Explicit supported source pack needed');
 const initiative=raw.sourceKind==='government_initiative_retail';
 const reference=eg?raw.offer?.referencePrice:null;
 const discounted=initiative||reference!==null&&reference!==undefined&&reference>amount?true:
 !eg&&typeof raw.offerDisplayed==='boolean'?raw.offerDisplayed:null;
 const availability=!eg&&['out_of_stock','unavailable'].includes(raw.availability?.status)?false:null;
 const quote={schemaVersion:1,id:raw.id,country:bank.country,currency:raw.currency,
 kind:initiative?'initiative':'retail',label:raw.productName,amount,
 pack:{value:pack.value,unit:unit[pack.unit]},sourceUrl:raw.url,
 observedAt:raw.observedAt,priceAsOf:eg?raw.priceAsOf:raw.displayedPriceDate,
 availability,offer:{discounted,validFrom:eg?raw.offer?.validFrom??null:raw.offerValidFrom??null,
 validUntil:eg?raw.offer?.validTo??null:raw.offerValidTo??null},
 reuseApproved:false,evidenceChecked:false,itemKey:null,
 city:eg?raw.geography?.city??null:raw.city??null,
 storeKey:null};
 const normalized=normalizePriceQuote(quote);
 entries.push({quote,normalized:normalized.normalized,derived:true,runtimeReady:false,
 sourceFile:file,sourceFileSha256:sha256,sourceObservationId:raw.id,
 sourceCategory:raw.category,sourcePack:pack,sourceQuoteAsOfMeaning:initiative?'announced-effective-date':'retailer-price-date-unknown',
 sourceVerification:eg?raw.verification:raw.evidence?.level,
 priceEvidence:raw.evidence,barcode:raw.barcode??null,
 taxIncluded:eg?raw.includingVat:raw.vatIncluded,
 availabilityEvidence:raw.availability,
 locationEvidence:eg?raw.geography:{city:raw.city,branch:raw.branch},
 caveats:['Research transcription only; source availability/cache/date retained',
 'Reuse/evidence/identity/store review required before averaging or runtime publication']});
 }
 }
 assert.equal(new Set(entries.map(e=>e.quote.id)).size,entries.length);
 const cohorts=['EG','SA'].map(country=>({country,observations:entries.filter(e=>e.quote.country===country).length,
 retail:entries.filter(e=>e.quote.country===country&&e.quote.kind==='retail').length,
 initiative:entries.filter(e=>e.quote.country===country&&e.quote.kind==='initiative').length}));
 const sample=estimateComparablePrices(entries.map(e=>e.quote),{country:'EG',city:'Cairo',
 itemKey:'unreviewed-no-binding',now:'2026-10-14',maxAgeDays:7});
 assert.equal(sample.meanUnitPrice,null);
 return {schemaVersion:1,researchOnly:true,runtimePriceApprovals:0,
 priceDatePolicy:'retrieval date is not the price effective date; unknown stays null',
 quantityPolicy:'declared pack arithmetic only; cube/piece stay counts, never grams',
 sourcePartitions:banks.map(({file,sha256,bank})=>({file,sha256,sources:bank.sources.length,country:bank.country})),
 observationCount:entries.length,normalizedObservationCount:entries.filter(e=>e.normalized).length,
 cohorts,excluded,entries};
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 const value=await buildResearchPriceIndex();const file='data/prices/research/observations.json';
 if(process.argv.includes('--write'))await writeFile(file,JSON.stringify(value,null,2)+'\n');
 else assert.deepEqual(JSON.parse(await readFile(file,'utf8')),value,'Research index drift;review inputs before rebuilding');
 console.log(JSON.stringify({observations:value.observationCount,cohorts:value.cohorts,
 excluded:value.excluded.length,runtimePriceApprovals:0,mode:process.argv.includes('--write')?'write':'verify'}));
}
