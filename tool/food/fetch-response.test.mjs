import {createServer} from 'node:http';
import {spawn} from 'node:child_process';
import {once} from 'node:events';
import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,rm,readdir,readFile} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {fetchArchive} from './import.mjs';

async function temporary(fn) {
  const parent=path.resolve(os.tmpdir()),out=await mkdtemp(path.join(parent,'sofra-fetch-body-'));
  try {await fn(out);} finally {
    assert.equal(path.dirname(path.resolve(out)),parent);
    assert.ok(path.basename(out).startsWith('sofra-fetch-body-'));
    await rm(out,{recursive:true,force:true});
  }
}

test('HTTP failure cancels unread response stream and never writes an archive',()=>temporary(async out=>{
  let cancelled=false;
  const body=new ReadableStream({start(c){c.enqueue(new TextEncoder().encode('Unavailable'));},cancel(){cancelled=true;}});
  const response=new Response(body,{status:503});
  await assert.rejects(fetchArchive(out,{country:'egypt',id:'error',fetchImpl:async()=>response}),/OFF 503/);
  assert.equal(cancelled,true,'HTTP failure must release the unread response body');
  assert.deepEqual(await readdir(out),[]);
}));

test('body cancellation failure preserves original HTTP status for backoff',()=>temporary(async out=>{
  let attempted=false;
  const response={ok:false,status:429,body:{cancel:async()=>{attempted=true;throw new Error('Synthetic cleanup failure');}}};
  await assert.rejects(fetchArchive(out,{country:'egypt',id:'error',fetchImpl:async()=>response}),/OFF 429/);
  assert.equal(attempted,true);
  assert.deepEqual(await readdir(out),[]);
}));

test('HTTP failure with no response body remains the original source error',()=>temporary(async out=>{
  await assert.rejects(fetchArchive(out,{country:'egypt',id:'empty',fetchImpl:async()=>new Response(null,{status:503})}),/OFF 503/);
}));

test('successful response is consumed and archived with original source evidence',()=>temporary(async out=>{
  const response=new Response(JSON.stringify({count:0,products:[]}),{status:200});
  await fetchArchive(out,{country:'egypt',page:2,id:'success',now:()=> '2026-10-13T05:50:00Z',fetchImpl:async()=>response});
  const archive=JSON.parse(await readFile(path.join(out,'raw','success.json'),'utf8'));
  assert.equal(response.bodyUsed,true);assert.equal(archive.count,0);assert.deepEqual(archive.products,[]);
  assert.deepEqual(archive.query,{country:'egypt',page:2,category:null});
  assert.equal(archive.retrievedAt,'2026-10-13T05:50:00Z');
  assert.equal(new URL(archive.requestedUrl).hostname,'world.openfoodfacts.org');
}));


test('error cleanup lets a child exit while the HTTP error body remains open',()=>temporary(async out=>{
  // Local fixture leaves its response unfinished, reproducing an active socket.
  const server=createServer((_req,res)=>{res.writeHead(503);res.write('Synthetic unavailable');});
  server.listen(0,'127.0.0.1');await once(server,'listening');
  const endpoint=`http://127.0.0.1:${server.address().port}/`;
  const code=`import {fetchArchive} from ${JSON.stringify(new URL('./import.mjs',import.meta.url).href)};
    try { await fetchArchive(${JSON.stringify(out)},{country:'egypt',id:'child',fetchImpl:(_url,options)=>fetch(${JSON.stringify(endpoint)},options)});process.exitCode=2; }
    catch(error) {if(!/OFF 503/.test(String(error))) {console.error(error);process.exitCode=3;}}`;
  const child=spawn(process.execPath,['--input-type=module','-e',code],{stdio:['ignore','ignore','pipe'],windowsHide:true});
  let timer,stderr='';child.stderr.setEncoding('utf8');child.stderr.on('data',v=>stderr+=v);
  try {
    const result=await Promise.race([
      once(child,'exit'),
      new Promise((_,reject)=>{timer=setTimeout(()=>reject(new Error('Child retained the unfinished HTTP error socket')),10000);}),
    ]);
    assert.equal(result[0],0,stderr);assert.equal(result[1],null);
    assert.deepEqual(await readdir(out),[]);
  } finally {
    clearTimeout(timer);
    if(child.exitCode===null && child.signalCode===null) {const closed=once(child,'exit');child.kill();await closed;}
    server.closeAllConnections();await new Promise(resolve=>server.close(resolve));
  }
}));
