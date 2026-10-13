import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const need=(v,m)=>{if(!v)throw new Error(m);};
const text=v=>typeof v==='string'&&v.trim().length>0;
const sha=v=>typeof v==='string'&&/^[a-f0-9]{64}$/.test(v);
const hash=v=>createHash('sha256').update(v).digest('hex');
const parse=v=>JSON.parse(v.toString('utf8').replace(/^\uFEFF/,''));
const defaultRead=path=>readFile(new URL(`../../data/usda/${path}`,import.meta.url));

/** Trusted local manifest consistency, not independent scientific or signature verification. */
export async function loadUsdaReviewSnapshots(ids,{read=defaultRead}={}){
  need(Array.isArray(ids)&&ids.length>0&&ids.every(id=>typeof id==='string'&&/^usda:[1-9][0-9]*$/.test(id))&&new Set(ids).size===ids.length,'Invalid or duplicate USDA IDs');
  const manifestBytes=await read('manifest.json'),manifest=parse(manifestBytes);
  need(manifest.schemaVersion===1&&Number.isInteger(manifest.count)&&manifest.count>0&&Array.isArray(manifest.sources)&&manifest.sources.length>0,'Invalid USDA manifest');
  const sources=new Map();
  for(const source of manifest.sources){
    need(text(source.id)&&!sources.has(source.id)&&source.license==='CC0-1.0'&&sha(source.sha256)&&text(source.release),'Invalid or duplicate source licence/evidence');
    const url=new URL(source.url);need(url.protocol==='https:'&&!url.username&&!url.password,'Invalid source URL');
    sources.set(source.id,source);
  }
  const verified=async path=>{
    need(sha(manifest.files?.[path]),`Missing manifest hash for ${path}`);
    const bytes=await read(path);need(hash(bytes)===manifest.files[path],`Source hash mismatch: ${path}`);
    return parse(bytes);
  };
  const index=await verified('index.json');
  need(index.schemaVersion===1&&Array.isArray(index.foods)&&index.foods.length===manifest.count,'Manifest/index count mismatch');
  const entries=new Map();
  for(const entry of index.foods){
    need(/^usda:[1-9][0-9]*$/.test(entry.id)&&text(entry.version)&&text(entry.name)&&sources.has(entry.dataset),'Invalid index identity');
    need(/^\d{2}\.json$/.test(entry.file),'Unsafe shard filename');
    need(!entries.has(entry.id),'Duplicate index identity');entries.set(entry.id,entry);
  }
  need(ids.every(id=>entries.has(id)),'Unknown USDA ID; no name fallback');
  const shards=new Map(),snapshots=new Map(),evidence=new Map();
  for(const id of ids){
    const entry=entries.get(id),path=`shards/${entry.file}`;
    if(!shards.has(path)){const rows=await verified(path);need(Array.isArray(rows),'Invalid source shard');shards.set(path,rows);}
    const matching=shards.get(path).filter(row=>row.id===id);need(matching.length===1,'Missing or duplicate shard identity');
    const row=matching[0];
    need(Number.isSafeInteger(row.fdcId)&&row.fdcId>0&&id===`usda:${row.fdcId}`&&row.version===entry.version&&row.name===entry.name&&row.sourceDataset===entry.dataset,'Record/index identity mismatch');
    snapshots.set(id,structuredClone(row));
    const source=sources.get(entry.dataset);
    evidence.set(id,{sourceId:'usda',dataset:entry.dataset,license:source.license,archiveUrl:source.url,archiveSha256:source.sha256,release:source.release,manifestSha256:hash(manifestBytes),indexSha256:manifest.files['index.json'],shardPath:path,shardSha256:manifest.files[path]});
  }
  return {snapshots,evidence,manifestSha256:hash(manifestBytes)};
}
