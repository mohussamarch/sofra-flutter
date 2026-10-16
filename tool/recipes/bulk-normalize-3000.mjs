import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {loadInputs as loadArchiveInputs,buildBatch,sha,validateBaseline} from './bulk-normalize-1000.mjs';

const root=fileURLToPath(new URL('../../',import.meta.url));
export const folder='data/recipes/curated-local/bulk-3000-20261015';
export const packFile=`${folder}/normalized-recipes.json`;
export const baselineFile=`${folder}/baseline-manifest.json`;
export const baselineManifestSha256='4006dee753cae5703fa666cdbd642c778557e4875c0cf24898db7437d64c9a97';
const need=(ok,message)=>{if(!ok)throw Error(message);};

export function selectedManifestBaseline(current){return {...current,packs:current.packs.filter(p=>p.file!==packFile)};}

/** Freeze all2090 prior records; future registrations cannot shift this batch. */
export async function loadInputs(){
 const loaded=await loadArchiveInputs(),read=file=>readFile(resolve(root,file));
 const current=JSON.parse(await read('data/recipes/curated-local/flutter-manifest.json'));
 let baselineRaw;
 try{baselineRaw=await read(baselineFile);}catch(error){if(error.code!=='ENOENT')throw error;baselineRaw=Buffer.from(JSON.stringify(selectedManifestBaseline(current),null,2)+'\n');}
 need(sha(baselineRaw)===baselineManifestSha256,'Third frozen baseline manifest drift');
 const baseline=validateBaseline(current,JSON.parse(baselineRaw)),previous=[];
 for(const p of baseline.packs){
  const bytes=await read(p.file);need(sha(bytes)===p.sha256,'Previous selected pack drift: '+p.file);
  previous.push(...JSON.parse(bytes).recipes);
 }
 need(previous.length===2090,'Third batch requires exactly2090 frozen previous records');
 return {...loaded,previous,inputManifestSha256:sha(baselineRaw),baselineManifestRaw:baselineRaw.toString('utf8')};
}

export function buildThirdBatch(inputs){return buildBatch(inputs,1000,{outputFolder:folder});}

export async function run({check=false}={}){
 const result=buildThirdBatch(await loadInputs());
 if(!check)await mkdir(resolve(root,folder,'source-snapshots'),{recursive:true});
 for(const [file,content]of result.files){
  if(check)need(await readFile(resolve(root,file),'utf8')===content,'Third converted output drift: '+file);
  else await writeFile(resolve(root,file),content,'utf8');
 }
 return result.report;
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url))console.log(JSON.stringify(await run({check:process.argv.includes('--check')})));
