import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const read=p=>readFile(p,'utf8');
test('curated household measures match exact source portions, versions, hashes and forms',async()=>{
 const bank=JSON.parse(await read('data/nutrition/household-measures-review.json'));
 const refs=JSON.parse(await read('data/nutrition/recipe-reference-review.json'));
 const expected=new Set(refs.entries.flatMap(e=>e.candidates.map(c=>JSON.stringify([c.foodId,c.form]))));
 const keys=new Set(),options=new Set(),files=new Map();let total=0,gaps=0;
 for(const e of bank.entries){
  const key=JSON.stringify([e.foodId,e.form]);assert.ok(expected.has(key)&&!keys.has(key));keys.add(key);
  assert.match(e.sourceFile,/^data\/usda\/shards\/[0-9]{2}\.json$/);
  if(!files.has(e.sourceFile)){const text=(await read(e.sourceFile)).replaceAll('\r\n','\n');files.set(e.sourceFile,{sha:createHash('sha256').update(text).digest('hex'),rows:JSON.parse(text)});}
  const f=files.get(e.sourceFile);assert.equal(e.sourceSha256,f.sha);
  const raw=f.rows.find(r=>r.id===e.foodId);assert.ok(raw);
  assert.equal(raw.version,e.sourceVersion);assert.equal(raw.name,e.sourceDescription);
  assert.equal(e.sourceUrl,`https://fdc.nal.usda.gov/food-details/${raw.fdcId}/nutrients`);
  if(!e.options.length){gaps++;assert.ok(e.issues.length);}
  const indices=new Set();
  for(const o of e.options){
   assert.ok(!options.has(o.id)&&!indices.has(o.sourcePortionIndex));options.add(o.id);indices.add(o.sourcePortionIndex);
   assert.ok(Number.isInteger(o.sourcePortionIndex)&&o.sourcePortionIndex>=0);
   const p=raw.portions[o.sourcePortionIndex];assert.ok(p);
   for(const k of ['amount','gramWeight','measureUnit','modifier','description'])assert.deepEqual(o[k],p[k]);
   assert.ok(Number.isFinite(o.amount)&&o.amount>0&&Number.isFinite(o.gramWeight)&&o.gramWeight>0);
   assert.ok(![o.measureUnit,o.modifier,o.description].some(v=>/RACC/i.test(v??'')));
   assert.ok(o.label&&o.rationale);total++;
  }
 }
 assert.deepEqual(keys,expected);assert.equal(keys.size,36);assert.equal(total,103);assert.equal(gaps,6);assert.equal(bank.licenseCC0,true);
});
