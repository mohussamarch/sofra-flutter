import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,readdir,rm} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import os from 'node:os';import path from 'node:path';import {fileURLToPath} from 'node:url';
import {parseCollectorArgs} from './collect-incremental.mjs';
test('help and unsupported flags cannot become output directories',()=>{
 assert.equal(parseCollectorArgs(['--help']).help,true);assert.equal(parseCollectorArgs(['-h']).help,true);
 assert.equal(parseCollectorArgs([]).help,false);assert.equal(parseCollectorArgs(['./custom-bank']).out,path.resolve('./custom-bank'));
 for(const args of [['--bogus'],['--help','extra'],['one','two']]) assert.throws(()=>parseCollectorArgs(args),/usage/i);
});
test('actual CLI help exits naturally and creates no bank or lock',async()=>{
 const tmp=await mkdtemp(path.join(os.tmpdir(),'sofra-cli-'));
 const script=fileURLToPath(new URL('./collect-incremental.mjs',import.meta.url));
 try{
  for(const flag of ['--help','-h','--unsupported']){
   const child=spawnSync(process.execPath,[script,flag],{cwd:tmp,encoding:'utf8',timeout:5000});
   assert.equal(child.error,undefined);assert.equal(child.signal,null);
   if(flag==='--unsupported')assert.notEqual(child.status,0);else{assert.equal(child.status,0);assert.match(child.stdout,/usage/i);}
   assert.deepEqual(await readdir(tmp),[]);
  }
 }finally{assert.ok(path.resolve(tmp).startsWith(path.resolve(os.tmpdir())+path.sep));await rm(tmp,{recursive:true,force:true});}
});
