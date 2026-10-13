import test from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {loadUsdaReviewSnapshots} from './usda-review-reader.mjs';
const hash=v=>createHash('sha256').update(v).digest('hex');
function fixture(edit=()=>{}){
 const rows=[{id:'usda:1',fdcId:1,version:'fixture-v1',name:'Synthetic flour',sourceDataset:'fixture',form:null,nutrients:[],basis:null},{id:'usda:2',fdcId:2,version:'fixture-v1',name:'Synthetic salt',sourceDataset:'fixture',form:null,nutrients:[],basis:null}];
 const index={schemaVersion:1,foods:rows.map((r,i)=>({id:r.id,version:r.version,name:r.name,dataset:'fixture',file:`0${i}.json`}))};
 const manifest={schemaVersion:1,count:2,sources:[{id:'fixture',license:'CC0-1.0',url:'https://example.org/fixture.zip',release:'fixture-v1',sha256:'a'.repeat(64)}],files:{}};
 edit({rows,index,manifest});
 const files=new Map([['index.json',Buffer.from(JSON.stringify(index)+'\r\n')],['shards/00.json',Buffer.from(JSON.stringify([rows[0]]))],['shards/01.json',Buffer.from(JSON.stringify([rows[1]]))]]);
 for(const [key,value]of files)manifest.files[key]=hash(value);
 files.set('manifest.json',Buffer.from(JSON.stringify(manifest)));
 const calls=[];const read=async p=>{calls.push(p);assert.ok(files.has(p),`Unexpected path ${p}`);return files.get(p);};
 return {rows,index,manifest,files,calls,read};
}
test('reads only requested shard, preserves unknowns and gives independent source evidence',async()=>{
 const f=fixture();const result=await loadUsdaReviewSnapshots(['usda:1'],{read:f.read});
 assert.deepEqual(f.calls,['manifest.json','index.json','shards/00.json']);
 assert.equal(result.snapshots.get('usda:1').basis,null);
 assert.equal(result.evidence.get('usda:1').license,'CC0-1.0');
 assert.equal(result.evidence.get('usda:1').shardSha256,f.manifest.files['shards/00.json']);
 result.snapshots.get('usda:1').name='Changed';assert.equal(f.rows[0].name,'Synthetic flour');
});
test('rejects byte corruption including silent line ending normalization',async()=>{
 for(const file of ['index.json','shards/00.json']){const f=fixture();f.files.set(file,Buffer.concat([f.files.get(file),Buffer.from(' ')]));await assert.rejects(loadUsdaReviewSnapshots(['usda:1'],{read:f.read}),/hash/i);}
 const f=fixture();f.files.set('index.json',Buffer.from(f.files.get('index.json').toString().replace(/\r\n/g,'\n')));await assert.rejects(loadUsdaReviewSnapshots(['usda:1'],{read:f.read}),/hash/i);
});
test('unknown IDs and duplicate requested IDs fail without name fallback',async()=>{
 for(const ids of [['usda:9'],['usda:1','usda:1'],['flour'],[]]){const f=fixture();await assert.rejects(loadUsdaReviewSnapshots(ids,{read:f.read}));assert.ok(!f.calls.some(p=>p.startsWith('shards/')));}
});
test('unsafe shard filenames fail before any path can be read',async()=>{
 const f=fixture(({index})=>index.foods[0].file='../outside.json');await assert.rejects(loadUsdaReviewSnapshots(['usda:1'],{read:f.read}),/shard/i);assert.ok(!f.calls.includes('shards/../outside.json'));
});
test('duplicate index or shard identities cannot silently win',async()=>{
 const f=fixture(({index})=>index.foods[1].id='usda:1');await assert.rejects(loadUsdaReviewSnapshots(['usda:1'],{read:f.read}),/duplicate/i);
 const g=fixture();g.files.set('shards/00.json',Buffer.from(JSON.stringify([g.rows[0],g.rows[0]])));g.manifest.files['shards/00.json']=hash(g.files.get('shards/00.json'));g.files.set('manifest.json',Buffer.from(JSON.stringify(g.manifest)));await assert.rejects(loadUsdaReviewSnapshots(['usda:1'],{read:g.read}),/identity/i);
});
test('index and record versions, names, datasets and FDC identifiers must agree',async()=>{
 for(const key of ['version','name','sourceDataset','fdcId']){const f=fixture();const row={...f.rows[0],[key]:key==='fdcId'?99:'Changed'};f.files.set('shards/00.json',Buffer.from(JSON.stringify([row])));f.manifest.files['shards/00.json']=hash(f.files.get('shards/00.json'));f.files.set('manifest.json',Buffer.from(JSON.stringify(f.manifest)));await assert.rejects(loadUsdaReviewSnapshots(['usda:1'],{read:f.read}),/identity/i);}
});
test('source licence and manifest count are validated, never inferred',async()=>{
 for(const edit of [({manifest})=>manifest.sources[0].license='unknown',({manifest})=>manifest.count=3]){const f=fixture(edit);await assert.rejects(loadUsdaReviewSnapshots(['usda:1'],{read:f.read}));}
});
