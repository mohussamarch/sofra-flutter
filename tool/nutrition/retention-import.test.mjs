import test from 'node:test';import assert from 'node:assert/strict';import {readFile} from 'node:fs/promises';
import {parseRetentionArchive,buildRetentionCandidates} from './import-retention.mjs';
const row=(code='0381',nutrient='401',percent='70',description='PASTA,BOILED,DRAINED',group='20',date='09/1975')=>`~${code}~^~${group}~^~${description}~^~${nutrient}~^~Vitamin C, total ascorbic acid~^~${percent}~^~${date}~`;
test('strict source parse preserves codes, percentages, row dates and physical line numbers',()=>{
 const p=parseRetentionArchive(row()+'\r\n'+row('0382','401','0')+'\r\n');assert.equal(p.length,2);assert.equal(p[0].retentionCode,'0381');assert.equal(p[0].sourceLine,1);assert.equal(p[1].factorPercent,0);assert.equal(p[1].sourceLine,2);
});
test('malformed headers/IDs/dates/percentages and duplicate conflicting identities reject',()=>{
 for(const raw of [row().replace('~0381~','0381'),row('381'),row('0381','40'),row('0381','401','NaN'),row('0381','401','-1'),row('0381','401','101'),row('0381','401','',undefined,undefined,'13/2007'),row('0381','401','70',undefined,undefined,'13/2007'),row()+'\n'+row(),row()+'\n'+row('0381','404','65','DIFFERENT')])assert.throws(()=>parseRetentionArchive(raw));
});
test('candidate build requires all requested source rows and explicit unapproved provenance',()=>{
 const raw=Buffer.from(row());const meta={url:'https://www.ars.usda.gov/ARSUserFiles/80400535/Data/retn/retn06.txt',retrievedAt:'2026-10-13T10:00:00Z',sha256:'not-matching'};
 assert.throws(()=>buildRetentionCandidates(raw,meta));
});
test('shipped candidates reproduce exact archived source rows and keep unknowns/approvals separate',async()=>{
 const raw=await readFile('research/nutrition/usda/retn06.txt');const meta=JSON.parse(await readFile('research/nutrition/usda/retn06.metadata.json','utf8'));
 const bank=JSON.parse(await readFile('data/nutrition/retention-candidates.json','utf8'));
 assert.deepEqual(buildRetentionCandidates(raw,meta),bank);assert.equal(bank.entries.length,9);assert.equal(bank.approvedTransformCount,0);
 for(const e of bank.entries){assert.equal(e.status,'source-extracted-unmapped');assert.deepEqual(e.foodIds,[]);assert.equal(e.massYield,null);assert.equal(e.edibleFraction,null);assert.equal(e.factor,e.factorPercent/100);assert.equal(e.factorUnit,'fraction');}
 const pasta=bank.entries.find(v=>v.retentionCode==='0381'&&v.nutrientId==='thiamin');assert.equal(pasta.factorPercent,65);
 const baked=bank.entries.find(v=>v.retentionCode==='0382'&&v.nutrientId==='thiamin');assert.equal(baked.factorPercent,55);
 const rice=bank.entries.find(v=>v.retentionCode==='0432'&&v.nutrientId==='riboflavin');assert.equal(rice.factorPercent,90);
});

test('published blank factor is unknown, never zero, and valid zero stays zero',()=>{
 const unknown=parseRetentionArchive(row().replace('~70~',''))[0];assert.equal(unknown.factorPercent,null);
 const zero=parseRetentionArchive(row('0381','401','0'))[0];assert.equal(zero.factorPercent,0);
});
