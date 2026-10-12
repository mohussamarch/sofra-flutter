import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile, readdir, mkdtemp, mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import { validGtin, normalize, sha256, buildBank } from './import.mjs';

const provenance={retrievedAt:'2026-10-12T00:00:00Z',archive:'raw/test.json'};
const synthetic={code:'4006381333931',product_name:'Synthetic test record only',countries_tags:['en:egypt'],categories_tags:['en:chocolates'],product_quantity_unit:'g',nutriments:{proteins_100g:3,proteins_unit:'mg',proteins_modifier:'<',carbohydrates_100g:50,sugars_100g:70,salt_100g:-1,fat_prepared_100g:2,energy_100g:100,'energy-kcal_100g':800,ph_100g:4}};
test('GTIN checksum, supported lengths and leading zero are preserved',()=>{
  for(const code of ['4006381333931','96385074','036000291452','00036000291452']) assert.equal(validGtin(code),true,code);
  for(const code of ['4006381333932','123','400638133393X','0000000000001','00000000']) assert.equal(validGtin(code),false,code);
});
test('OFF standardized values preserve modifier, prepared basis, unknowns and standard unit',()=>{
  const r=normalize(synthetic,provenance);
  assert.equal(r.nutrition.basis.unit,null);
  assert.equal(r.nutrition.basis.requiresLabelReview,true);
  assert.equal(r.nutrition.basis.packageUnitHint,'g');
  assert.deepEqual(r.nutrition.asSold.proteins,{value:3,unit:'g',sourceField:'proteins_100g',modifier:'<'});
  assert.equal(r.nutrition.prepared.fat.value,2);
  assert.equal('fat' in r.nutrition.asSold,false);
  assert.equal('salt' in r.nutrition.asSold,false);
  assert.equal('ph' in r.nutrition.asSold,false);
  assert.equal(r.allergens.status,'unknown');
  assert.ok(r.quality.warnings.includes('energy-units-inconsistent'));
  assert.ok(r.quality.warnings.includes('sugars-exceed-carbohydrates'));
});
test('invalid product identity is quarantined; allergens and traces never conflate',()=>{
  assert.equal(normalize({...synthetic,code:'bad'},provenance).rejected,'invalid-gtin');
  const r=normalize({...synthetic,allergens_tags:['en:milk'],traces_tags:['en:nuts']},provenance);
  assert.deepEqual(r.allergens.declaredTags,['en:milk']);
  assert.deepEqual(r.allergens.traceTags,['en:nuts']);
  assert.equal(r.allergens.status,'source-reported');
});
test('archive rebuild is reproducible and duplicate revisions do not blend',async()=>{
  const out=await mkdtemp(path.join(os.tmpdir(),'sofra-food-bank-'));
  await mkdir(path.join(out,'raw'));
  const envelope={retrievedAt:provenance.retrievedAt,requestedUrl:'https://world.openfoodfacts.org/cgi/search.pl?test=fixture',products:[synthetic,{...synthetic,last_modified_t:100,brands:'New revision'},{...synthetic,code:'bad'}]};
  await writeFile(path.join(out,'raw','test.json'),JSON.stringify(envelope));
  const first=await buildBank(out),second=await buildBank(out);
  assert.equal(first.productCount,1);assert.equal(first.quarantinedCount,1);assert.equal(first.duplicateOccurrences,1);
  assert.equal(first.productsSha256,second.productsSha256);assert.equal(first.indexSha256,second.indexSha256);
  const r=JSON.parse((await readFile(path.join(out,'products.jsonl'),'utf8')).trim());
  assert.equal(r.brands,'New revision');
});

if(process.env.SOFRA_FOOD_BANK) test('actual shipped bank hashes, identity, attribution and source nutrient values match archives',async()=>{
  const out=process.env.SOFRA_FOOD_BANK;
  const manifest=JSON.parse(await readFile(path.join(out,'manifest.json'),'utf8'));
  const bytes=await readFile(path.join(out,'products.jsonl'));
  assert.equal(sha256(bytes),manifest.productsSha256);
  assert.equal(sha256(await readFile(path.join(out,'index.json'))),manifest.indexSha256);
  const records=bytes.toString('utf8').trim().split('\n').map(JSON.parse);
  assert.equal(records.length,manifest.productCount);
  assert.equal(new Set(records.map(r=>r.barcode)).size,records.length);
  const pages=new Map();
  for(const archive of manifest.archives){
    const raw=await readFile(path.join(out,archive.file));assert.equal(sha256(raw),archive.sha256);
    pages.set(archive.file,JSON.parse(raw).products);
  }
  for(const r of records){
    assert.ok(validGtin(r.barcode));assert.equal(r.source.databaseLicense,'ODbL-1.0');
    assert.equal(r.quality.verification,'unreviewed');assert.equal(r.nutrition.basis.unit,null);
    const original=pages.get(r.source.rawArchive).find(p=>String(p.code)===r.barcode && (p.last_modified_t??null)===r.source.lastModifiedEpoch);
    assert.ok(original,r.id);
    for(const n of [...Object.values(r.nutrition.asSold),...Object.values(r.nutrition.prepared)]) assert.equal(n.value,original.nutriments[n.sourceField]);
  }
});
