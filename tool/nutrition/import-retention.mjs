import assert from 'node:assert/strict';import {createHash} from 'node:crypto';import {readFile,writeFile} from 'node:fs/promises';import path from 'node:path';import {fileURLToPath} from 'node:url';
const sha=raw=>createHash('sha256').update(raw).digest('hex');
const sourceUrl='https://www.ars.usda.gov/ARSUserFiles/80400535/Data/retn/retn06.txt';
const nutrients=new Map([['401','vitaminC'],['404','thiamin'],['405','riboflavin']]);
const selectedCodes=['0381','0382','0432'];
export function parseRetentionArchive(text){
 assert.equal(typeof text,'string');const records=[],ids=new Set(),categories=new Map();
 for(const [index,line] of text.split(/\r?\n/).entries()){
  if(!line.trim())continue;
  const fields=line.split('^');assert.equal(fields.length,7,`Invalid field count at line${index+1}`);
  const values=fields.map((v,i)=>{if(i===5&&v==='')return '';assert.ok(v.startsWith('~')&&v.endsWith('~'),`Missing source delimiter at line${index+1}`);return v.slice(1,-1);});
  const [retentionCode,foodGroupCode,description,nutrientNumber,nutrientDescription,percent,updated]=values;
  assert.match(retentionCode,/^\d{4}$/);assert.match(foodGroupCode,/^\d{2,4}$/);assert.match(nutrientNumber,/^\d{3}$/);
  assert.ok(description.trim()&&nutrientDescription.trim());if(percent!==''){assert.match(percent,/^\d{1,3}$/);assert.ok(Number(percent)<=100);}
  if(updated)assert.match(updated,/^(0[1-9]|1[0-2])\/\d{4}$/);
  const id=retentionCode+':'+nutrientNumber;assert.ok(!ids.has(id),'Duplicate retention/nutrient source identity');ids.add(id);
  const category=JSON.stringify([foodGroupCode,description]);assert.ok(!categories.has(retentionCode)||categories.get(retentionCode)===category,'Inconsistent source category');categories.set(retentionCode,category);
  records.push({retentionCode,foodGroupCode,description,nutrientNumber,nutrientDescription,factorPercent:percent===''?null:Number(percent),sourceUpdated:updated||null,sourceLine:index+1});
 }
 assert.ok(records.length,'Empty retention archive');return records;
}
export function buildRetentionCandidates(raw,meta){
 assert.ok(Buffer.isBuffer(raw));assert.equal(meta.schemaVersion,1);assert.equal(meta.url,sourceUrl);assert.equal(sha(raw),meta.sha256,'Source archive hash mismatch');assert.equal(raw.length,meta.bytes);
 assert.ok(Number.isFinite(Date.parse(meta.retrievedAt)));assert.ok(typeof meta.license==='string'&&meta.license.trim());assert.equal(meta.archiveFile,'research/nutrition/usda/retn06.txt');
 const text=raw.toString('utf8');assert.ok(Buffer.from(text,'utf8').equals(raw),'Invalid source encoding');
 const records=parseRetentionArchive(text),byId=new Map(records.map(v=>[v.retentionCode+':'+v.nutrientNumber,v]));const entries=[];
 for(const code of selectedCodes)for(const [number,nutrientId] of nutrients){
  const r=byId.get(code+':'+number);assert.ok(r,'Requested source factor absent');assert.notEqual(r.factorPercent,null,'Requested source factor unknown');
  const line=text.split(/\r?\n/)[r.sourceLine-1];
  entries.push({...r,id:'usda-retention6:'+code+':'+number,nutrientId,factor:r.factorPercent/100,factorUnit:'fraction',
    status:'source-extracted-unmapped',foodIds:[],massYield:null,edibleFraction:null,sourceLineSha256:sha(Buffer.from(line,'utf8'))});
 }
 return {schemaVersion:1,source:{...meta},quantityKind:'nutrientRetention',basis:'percentage of nutrient amount retained, not food mass yield',sourceRecordCount:records.length,
  approvedTransformCount:0,unknownSourceFactorRows:records.filter(v=>v.factorPercent===null).length,entries,limitations:['Source factors may be imputed; exact food and preparation matching is not approved','Not mass yield, edible fraction, clinical advice or a finished mixed-recipe multiplier','Only three exact nutrient definitions mapped; remaining nutrients are unknown, never default1','Source-specific reuse license not verified; not inherited FDC CC0','No automatic runtime transforms or food bindings created']};
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 const args=process.argv.slice(2);
 if(args.length===1&&['--help','-h'].includes(args[0]))console.log('Usage: node tool/nutrition/import-retention.mjs (from repository root, offline fixed archive paths)');
 else{
  assert.equal(args.length,0,'No custom CLI arguments accepted; use --help');
  const raw=await readFile('research/nutrition/usda/retn06.txt'),meta=JSON.parse(await readFile('research/nutrition/usda/retn06.metadata.json','utf8'));
  const bank=buildRetentionCandidates(raw,meta);await writeFile('data/nutrition/retention-candidates.json',JSON.stringify(bank,null,2)+'\n');
  console.log(JSON.stringify({sourceRecords:bank.sourceRecordCount,candidates:bank.entries.length,approvedTransforms:bank.approvedTransformCount,sha256:bank.source.sha256}));
 }
}
