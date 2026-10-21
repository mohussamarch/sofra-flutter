import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { gunzipSync } from 'node:zlib';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const folder = 'data/recipes/modern-scale-20261021b-bulk';
const collectionFolder = 'data/recipes/curated-local/foodista-scale-20261021b';
let packFolder = collectionFolder;
const commit = '4fd174745182885bea01d47c8ba71b1946375898';
const sha = v => createHash('sha256').update(v).digest('hex');
const fmt = v => JSON.stringify(v, null, 2) + '\n';
const need = (v, m) => { if (!v) throw new Error(m); };
const norm = s => String(s ?? '').normalize('NFKC').toLowerCase().replace(/https?:\/\/\S+/g, '').replace(/[^\p{L}\p{N}]/gu, '');
function isTerminalHeading(line) {
  const heading = String(line ?? '').replace(/^#{1,6}\s*/, '').replace(/\s*#+$/, '').trim().replace(/:$/, '').trim();
  return /^(?:tools?|comments?|about|notes?|nutrition(?:al information)?|source|tags?|reviews?|discussion)$/i.test(heading);
}
function advanceTargetSection(state, heading) {
  const target = /^ingredients?\b/i.test(heading) ? 'ingredients' : /^(preparation|directions?|instructions?|method|steps?)\b/i.test(heading) ? 'method' : null;
  if (!target) return false;
  if (target === 'ingredients') {
    if (!state.ingredientStarted) state.ingredientStarted = true;
    else if (state.section !== 'ingredients' && state.methodStarted) state.complexSectionOrder = true;
  } else {
    if (!state.methodStarted) state.methodStarted = true;
    else if (state.section !== 'method' && state.ingredientStarted) state.complexSectionOrder = true;
  }
  // A repeated label inside its active section is formatting; keep collecting
  // lines. A later switch back is retained but flagged as a complex source.
  state.section = target;
  return true;
}

export function extract(text) {
  const lines = String(text).replace(/^\uFEFF/, '').replace(/\r\n?/g, '\n').split('\n');
  const state = { section: null, ingredientStarted: false, methodStarted: false, complexSectionOrder: false };
  let title = null;
  const ingredients = [], method = [];
  for (const raw of lines) {
    const line = raw.replace(/^\uFEFF/, '').trim();
    if (!line) continue;
    const h = line.match(/^#{1,6}\s*(.+?)\s*#*$/);
    if (h) {
      const heading = h[1].replace(/[*_`]/g, '').trim();
      if (!title && !/^(ingredients?|preparation|directions?|instructions?|method|steps?)\b/i.test(heading)) title = heading;
      if (isTerminalHeading(heading)) break;
      advanceTargetSection(state, heading);
      continue;
    }
    if (isTerminalHeading(line)) break;
    if (/^(ingredients?|preparation|directions?|instructions?|method|steps?)\s*:?\s*$/i.test(line)) {
      advanceTargetSection(state, line);
      continue;
    }
    const clean = line.replace(/^\s*(?:[-*+]\s+|\d+[.)]\s+)/, '').replace(/\s+#+$/, '').trim();
    if (!title && state.section===null && !/^(?:By|Published|Updated|Prep(?:aration)? Time|Cook(?:ing)? Time)\s*:/i.test(clean)) { title=clean.replace(/^#+\s*/, '').trim(); continue; }
    if (state.section === 'ingredients' && clean && !/^\[.*\]\(https?:/i.test(clean)) ingredients.push(clean);
    if (state.section === 'method' && clean && !/^\[.*\]\(https?:/i.test(clean)) method.push(clean);
  }
  return { title, ingredients, method, complexSectionOrder: state.complexSectionOrder };
}

export function sectionCoverage(text, parsed) {
  const state = { section: null, ingredientStarted: false, methodStarted: false, complexSectionOrder: false };
  const ingredients=[], method=[];
  for(const raw of String(text??'').replace(/^\uFEFF/,'').replace(/\r\n?/g,'\n').split('\n')){
    const line=raw.replace(/^\uFEFF/,'').trim(); if(!line)continue;
    const heading=line.replace(/^#{1,6}\s*/,'').replace(/\s*#+$/,'').trim();
    if(isTerminalHeading(heading))break;
    if(/^(ingredients?|preparation|directions?|instructions?|method|steps?)\s*:?\s*$/i.test(heading)){advanceTargetSection(state,heading);continue}
    const clean=line.replace(/^[-*+•]\s+/, '').replace(/^\d+[.)]\s+/, '').trim();
    if(state.section==='ingredients')ingredients.push(clean);
    if(state.section==='method')method.push(clean);
  }
  const key=xs=>norm(xs.join('\n'));
  return {ingredientsExact:key(ingredients)===key(parsed.ingredients),methodExact:key(method)===key(parsed.method),sourceIngredientLines:ingredients.length,sourceMethodLines:method.length};
}

const methodAction=/\b(?:add|arrange|assemble|bake|beat|blend|boil|braise|broil|brown|brush|chill|chop|combine|cook|cool|cover|cut|dice|drain|drizzle|fold|fry|garnish|grate|grill|heat|knead|layer|marinate|mash|melt|mince|mix|peel|place|poach|pour|preheat|press|refrigerate|roast|roll|sauté|saute|season|serve|shake|sift|simmer|slice|sprinkle|stir|strain|stuff|sauté|thaw|toss|whisk|wrap|let rest|allow to|bring to|remove from|set aside|turn off|turn over)\b/i;
export function rejectReason(title,method) {
  const body=method.join('\n').trim();
  if(/^(?:my plan is this\b|recipe of the week\b)|\bblog post\b/i.test(title??''))return 'article-or-blog-title';
  if(/https?:\/\/|\bsee (?:the )?link\b|\bfull description\b|\bclick here\b|\bclick (?:this|the) link\b|\bvisit (?:the )?link\b|\bvisit\s+\S+(?:\s+\S+){0,5}\s+(?:for\s+)?(?:complete|full|more) instructions\b|\bfor complete instructions\b|\bplace your ad here\b|\bloading\.\.\./i.test(body))return 'link-ad-or-placeholder-method';
  if(!methodAction.test(body))return 'no-preparation-action';
  if(/\b(?:bread|cake|cookies?|muffins?)\b/i.test(title??'')&&!/\b(?:bake|cook|preheat|fry|boil|steam|grill|broil|roast|microwave|heat|simmer|poach|toast|brown|freeze|chill|refrigerat|set|press|whip)\b/i.test(body)&&!/\b(?:starter|frosting|smoothie|filling mix|no[- ]bake)\b/i.test(`${title} ${body}`))return 'baked-title-missing-cooking-or-setting-action';
  return null;
}

export function rightsConflictReason(text) {
  const s=String(text??'').normalize('NFKC');
  if(/all\s+rights\s+reserved|copyright\s*(?:©|\(c\)|\d{4})|©\s*\d{4}|used\s+with\s+permission/i.test(s))return 'explicit-copyright-or-permission-reservation';
  if(/\b(?:adapted|reprinted|reproduced|copied|borrowed|taken)\s+from\b|\b(?:originally\s+(?:published|posted|appeared)\s+(?:at|in|on|by)|recipe\s+source\s*:|courtesy\s+of|reprinted\s+with\s+permission\s+from)\b/i.test(s))return 'explicit-third-party-source-attribution';
  if(/\brecipe\s+by\s+(?!anonymous\b|foodista\b)[\p{Lu}][\p{L}'’-]+/iu.test(s))return 'named-person-recipe-attribution';
  if(/\b(?:paula\s+deen|food\s+network|allrecipes|food52|epicurious|bbc\s+good\s+food|new\s+york\s+times\s+cooking|bon\s+app[eé]tit|taste\s+of\s+home)\b.{0,80}\b(?:recipe\s+(?:is\s+)?(?:from|by)|source\s*:|courtesy\s+of|original(?:ly)?\s+(?:recipe\s+)?by)\b/i.test(s) || /\b(?:recipe\s+(?:is\s+)?(?:from|by)|source\s*:|courtesy\s+of|original(?:ly)?\s+(?:recipe\s+)?by)\b.{0,80}\b(?:paula\s+deen|food\s+network|allrecipes|food52|epicurious|bbc\s+good\s+food|new\s+york\s+times\s+cooking|bon\s+app[eé]tit|taste\s+of\s+home)\b/i.test(s))return 'named-third-party-recipe-source';
  return null;
}

function classifyReviewKind(title, ingredients, method) {
  const text = `${title}\n${ingredients.join('\n')}\n${method.join('\n')}`;
  const flags = [];
  if (/\b(?:sauce|seasoning|spice mix|spice blend|rub|crumb topping|topping|frosting|starter|dressing|vinaigrette|syrup|marinade|glaze|filling|batter|stock|broth|ketchup)\b/i.test(text)) flags.push('possible-component');
  if (/\b(?:rum|vodka|gin|whisk(?:y|ey)|tequila|brandy|bourbon|beer|wine|champagne|liqueur|vermouth|sake|sherry|alcohol)\b/i.test(text)) flags.push('possible-alcohol-term');
  return { recipeKind: flags.length ? 'component-review' : 'unknown', recipeKindReviewFlags: flags };
}

function contentKey(r) { return sha(norm(r.ingredients.map(x => x.sourceText).join('\n')) + '|' + norm(r.steps.map(x => x.text).join('\n'))); }
function licenseInfo(declaration) {
  const value=String(declaration??'').trim();
  const uri=value.match(/https?:\/\/creativecommons\.org\/licenses\/by\/(?:3\.0|4\.0)\/?/i)?.[0];
  if (!uri || !/^creative commons\s*[-–:]?\s*attribution\b/i.test(value)) return null;
  return {uri, declaration:value};
}
function sourceProof(row, rawLine, shard, fetchedAt, shardSha) {
  const lic = licenseInfo(row.metadata.license);
  need(lic, 'No explicit row-level CC BY 3.0/4.0 license');
  return {
    recordId: `common-pile-foodista:${commit}:${shard}:${row.id}`,
    sourceId: 'common-pile-foodista', sourceRevision: commit, sourceRevisionTimestamp: null, translationStatus:'not-translated',
    sourceUrl: row.metadata.url, sourceSha256: sha(rawLine), sourceTextSha256: sha(row.text),
    sourceSnapshotFile: `${packFolder}/source-snapshots/${row.id}.json`, retrievedAt: fetchedAt,
    sourceShard: shard, sourceShardSha256: shardSha,
    author: row.metadata.authors ?? null, sourceCreatedAt: row.created ?? null, commonPileAddedAt: row.added ?? null,
    license: { id: 'CC-BY-' + (lic.uri.match(/by\/(3\.0|4\.0)/i)?.[1] ?? '').replace('.', '-'), uri: lic.uri, declaration:lic.declaration, attributionRequired: true,
      changesMustBeIndicated: true, primaryEvidenceUrl: 'https://www.foodista.com/terms',
      republisherEvidenceUrl: 'https://huggingface.co/datasets/common-pile/foodista', historicalPerRecordLicense: true,
      caveat: 'Foodista current terms show CC BY 4.0; this row declares its historical CC BY license. Republisher warns generally that metadata may be inaccurate; no independent archived per-page license capture.' },
  };
}

async function main() {
  const args=process.argv.slice(2), val=name=>{const i=args.indexOf(name);return i<0?null:args[i+1]};
  const target=Number(val('--target')??1000); need(Number.isInteger(target)&&target>0,'--target must be a positive integer');
  const batch=Number(val('--batch')??1); need(Number.isInteger(batch)&&batch>0,'--batch must be a positive integer');
  const skipAccepted=args.includes('--skip-accepted');
  packFolder=batch===1?collectionFolder:`${collectionFolder}/batches/batch-${String(batch).padStart(4,'0')}`;
  const manifest = JSON.parse(await readFile(resolve(root, 'data/recipes/curated-local/flutter-manifest.json'), 'utf8'));
  const priorUrls = new Set(), priorKeys = new Set();
  for (const p of manifest.packs) {
    // The parent may already have pinned this collection's first pack while a
    // correction pass is underway; it is rebuilt below and deduped via priorFiles.
    if (p.file.replace(/\\/g, '/').startsWith(`${collectionFolder}/`)) continue;
    const b = await readFile(resolve(root, p.file)); need(sha(b) === p.sha256, `Baseline pack hash drift: ${p.file}`);
    for (const r of JSON.parse(b).recipes ?? []) {
      const u = r.sourceUrl ?? r.provenance?.sourceUrl; if (u) priorUrls.add(u.replace(/[?#].*$/, '').toLowerCase());
      if (r.ingredients?.length && r.steps?.length) priorKeys.add(contentKey({ingredients:r.ingredients.map(x=>({sourceText:x.sourceText??x.name})),steps:r.steps.map(x=>({text:x.text??x.textAr??''}))}));
    }
  }
  if(skipAccepted){
    // Include only batches before the one being rebuilt (never include itself).
    const priorFiles=[resolve(root,`${collectionFolder}/normalized-recipes.json`),...Array.from({length:Math.max(0,batch-2)},(_,i)=>resolve(root,`${collectionFolder}/batches/batch-${String(i+2).padStart(4,'0')}/normalized-recipes.json`))];
    for(const path of priorFiles){try{const bytes=await readFile(path);const pack=JSON.parse(bytes);for(const r of pack.recipes??[]){const u=r.sourceUrl??r.provenance?.sourceUrl;if(u)priorUrls.add(u.replace(/[?#].*$/,'').toLowerCase());if(r.ingredients?.length&&r.steps?.length)priorKeys.add(contentKey({ingredients:r.ingredients.map(x=>({sourceText:x.sourceText??x.name})),steps:r.steps.map(x=>({text:x.text??x.textAr??''}))}))}}catch(e){if(e.code!=='ENOENT')throw e}}
  }
  const collectedAt = new Date().toISOString();
  const checkpoints = [], recipes = [], snapshots = [], seenUrls = new Set(), seenKeys = new Set();
  let totalRows=0, foodistaUrls=0, complete=0, incomplete=0, nonRecipe=0, noLicense=0, duplicates=0, requestCount=0, ingredientCoverageFailures=0, methodCoverageFailures=0, qualityRejected=0, rightsExcluded=0, repeatedNumberingReview=0;
  const rejectedByReason={};
  const requestHistory=[{phase:'initial-assessment',knownLogicalRequests:6,detail:'00000 twice, 00004 three times, HF revision API once; statuses not all retained'},{phase:'first-bulk-pass',knownHttp200:4,detail:'00000-00003; fifth-shard outcome unknown; one request may have been attempted and is uncheckpointed'},{phase:'cache-recovery',knownHttp200:2,detail:'00000 and 00003 saved before parsing'},{phase:'direct-source-check',knownLogicalRequests:1,detail:'Foodista page returned a Vercel checkpoint; no bypass or retry'}];
  const endpointBase = `https://huggingface.co/datasets/common-pile/foodista/resolve/${commit}/v0/documents/`;
  const quota = JSON.parse(process.env.MODERN_BULK_QUOTA ?? 'null');
  need(quota?.ordinary === true && [quota.primary,quota.weekly].every(x=>Number.isFinite(x)&&x<98), 'Fresh quota evidence under 98% required in MODERN_BULK_QUOTA');
  need(Date.now()-Date.parse(quota.capturedAt) >= 0 && Date.now()-Date.parse(quota.capturedAt) <= 30000, 'Quota evidence must be <=30 seconds old');
  const cacheDir=resolve(root,folder,'source-cache'); await mkdir(cacheDir,{recursive:true});

  for (let shardNo=0; shardNo<4 && recipes.length<target; shardNo++) {
    const shard = `${String(shardNo).padStart(5,'0')}_foodista.jsonl.gz`;
    const url = endpointBase + shard; const startedAt = new Date().toISOString();
    const cachePath=resolve(cacheDir,shard); let bytes;
    try { bytes=await readFile(cachePath); }
    catch(e) {
      if(e.code!=='ENOENT') throw e;
      if (process.env.MODERN_BULK_CACHE_ONLY === '1') continue;
      requestCount++;
      const response = await fetch(url, { redirect:'follow', headers:{'User-Agent':'Sofra-Recipe-Research/1.0 (public dataset acquisition; contact: none)'} });
      need(response.status === 200, `Stop on HTTP ${response.status} for ${shard}; no retry`);
      bytes = Buffer.from(await response.arrayBuffer());
      // Persist the exact compressed body before inspecting any rows.
      await writeFile(cachePath,bytes,{flag:'wx'});
    }
    const bodySha=sha(bytes), plain=gunzipSync(bytes).toString('utf8'); let shardRows=0, shardAccepted=0;
    for (const rawLine of plain.split('\n')) {
      if (!rawLine.trim()) continue; totalRows++; shardRows++;
      let row; try { row=JSON.parse(rawLine); } catch { continue; }
      const sourceUrl = row.metadata?.url;
      if (row.source !== 'foodista' || !/^https?:\/\/(?:www\.)?foodista\.com\/recipe\//i.test(sourceUrl ?? '')) { nonRecipe++; continue; }
      if (!licenseInfo(row.metadata?.license)) { noLicense++; continue; }
      foodistaUrls++;
      const parsed=extract(row.text);
      if (!parsed.title || parsed.ingredients.length < 2 || parsed.method.length < 1) { incomplete++; continue; }
      const coverage=sectionCoverage(row.text,parsed);
      if(!coverage.ingredientsExact){ingredientCoverageFailures++;continue}
      if(!coverage.methodExact){methodCoverageFailures++;continue}
      complete++;
      if(parsed.complexSectionOrder){qualityRejected++;rejectedByReason['complex-section-order-review']=(rejectedByReason['complex-section-order-review']??0)+1;continue}
      const rightsRejected=rightsConflictReason(row.text);
      if(rightsRejected){rightsExcluded++;qualityRejected++;rejectedByReason[rightsRejected]=(rejectedByReason[rightsRejected]??0)+1;continue}
      const rejected=rejectReason(parsed.title,parsed.method);
      if(rejected){qualityRejected++;rejectedByReason[rejected]=(rejectedByReason[rejected]??0)+1;continue}
      const id=`modern-bulk:foodista:${row.id}`; const canonical=sourceUrl.replace(/[?#].*$/,'').toLowerCase();
      const draft={ingredients:parsed.ingredients.map(sourceText=>({sourceText})),steps:parsed.method.map(text=>({text}))};
      const key=contentKey(draft);
      if (priorUrls.has(canonical) || seenUrls.has(canonical) || priorKeys.has(key) || seenKeys.has(key)) { duplicates++; continue; }
      const proof=sourceProof(row,rawLine,shard,collectedAt,bodySha);
      const kind = classifyReviewKind(parsed.title, parsed.ingredients, parsed.method);
      const snapshot={schemaVersion:1,sourceRecord:proof,sourceTitle:parsed.title,sourceText:row.text,parsedSource:{ingredients:draft.ingredients,steps:draft.steps}};
      const snapText=fmt(snapshot); snapshots.push({file:proof.sourceSnapshotFile,text:snapText,sha256:sha(snapText)});
      const repeatedOrdinal=/\b(\d{1,2})\s+\1[.)]\s+/i.test(parsed.method.join('\n'));
      if(repeatedOrdinal)repeatedNumberingReview++;
      const recipe={id,recordVersion:1,name:parsed.title,nameAr:null,status:'needs-review',recipeKind:kind.recipeKind,recipeKindReviewFlags:kind.recipeKindReviewFlags,familyId:null,methodId:null,cuisines:[],yield:null,time:null,
        ingredients:draft.ingredients.map((x,i)=>({sourceLineIndex:i,name:x.sourceText,nameAr:null,amount:null,unit:null,optional:null,included:null,sourceText:x.sourceText,quantityPrecision:'unparsed-source-text',scales:null,foodBinding:null})),
        supplementalIngredients:[],steps:draft.steps.map((x,i)=>({n:i+1,text:x.text,textAr:null,sourceStepIndices:[i],duration:null})),excludedSourceSteps:[],notes:[{code:'source-language-en',text:'English source text retained verbatim.'},{code:'manual-review-required',text:'No quantities, cuisine, yield, timing, nutrition, food identity, or safety claims inferred.'},...(repeatedOrdinal?[{code:'source-numbering-review',text:'Source contains repeated ordinal markers; retained verbatim and flagged for review.'}]:[])],blockers:['Ingredient identities and quantities require review','Method completeness and safety require culinary review','License attribution review required',...(repeatedOrdinal?['Repeated source ordinal markers require review']:[])],
        provenance:{...proof,sourceSnapshotSha256:sha(snapText),translationStatus:'not-translated',changeNotice:'Extracted source English ingredient and method sections; only list/number markers normalized. No translation or inferred recipe facts.',extractionCoverage:{ingredientSectionExact:coverage.ingredientsExact,methodSectionExact:coverage.methodExact,sourceIngredientLines:coverage.sourceIngredientLines,sourceMethodLines:coverage.sourceMethodLines,sourceTextSha256:proof.sourceTextSha256,sourceNumberingReview:repeatedOrdinal,complexSectionOrder:parsed.complexSectionOrder},methodQualityScreen:'at-least-one-preparation-action; no external-link, advertisement or placeholder method; title not flagged as blog/article'},nutrition:null,runtimeReady:false,actuallyKitchenTested:false,
        gates:{culinaryReview:false,kitchenTested:false,ingredientIdentitiesReviewed:false,nutritionReviewed:false,runtimeApproved:false},sourceLanguage:'en'};
      recipe.contentSha256=sha(JSON.stringify({ingredients:recipe.ingredients,steps:recipe.steps}));
      // Keep accepted content in the in-batch dedup sets as well as comparing
      // against earlier packs; otherwise same-batch normalized-content twins pass.
      seenUrls.add(canonical); seenKeys.add(key);
      recipes.push(recipe); shardAccepted++;
      if (recipes.length>=target) break;
    }
    checkpoints.push({shard,requestUrl:url,inputMode:process.env.MODERN_BULK_CACHE_ONLY==='1'?'local-cache':'network-or-cache',originalFetchStatus:200,startedAt,finishedAt:new Date().toISOString(),compressedBytes:bytes.length,compressedSha256:bodySha,rows:shardRows,accepted:shardAccepted});
    const checkpoint={schemaVersion:1,sourceId:'common-pile-foodista',sourceRevision:commit,collectedAt,target,batch,skipAccepted,counts:{totalRows,foodistaUrls,complete,incomplete,noLicense,ingredientCoverageFailures,methodCoverageFailures,qualityRejected,rightsExcluded,rejectedByReason,repeatedNumberingReview,duplicates,accepted:recipes.length},requests:checkpoints,requestHistory,knownLogicalRequestCount:13,unknownRequestAttemptCount:1,stopPolicy:'Stop on any non-200; no retries, bypass, images, or media.'};
    await mkdir(resolve(root,folder),{recursive:true}); await writeFile(resolve(root,folder,'checkpoint.json'),fmt(checkpoint));
    if (shardNo<3 && recipes.length<target && process.env.MODERN_BULK_CACHE_ONLY!=='1') await new Promise(r=>setTimeout(r,850));
  }
  await mkdir(resolve(root,packFolder,'source-snapshots'),{recursive:true});
  for (const s of snapshots) await writeFile(resolve(root,s.file),s.text);
  const pack={schemaVersion:1,reviewedAt:collectedAt,reviewer:'Source extraction only; no independent culinary review',changeNotice:'Common Pile Foodista rows under explicit per-row CC BY declarations. Exact source ingredient/method text retained apart from list numbering; rejected external-link, advertisement, placeholder methods and titles flagged as blog/article. No amounts, times, nutrition, cuisines, or food bindings inferred.',sourceCount:recipes.length,sourceEvidence:{republisher:'https://huggingface.co/datasets/common-pile/foodista',sourceTerms:'https://www.foodista.com/terms',revision:commit,revisionTimestamp:null,requests:checkpoints,requestHistory,knownLogicalRequestCount:13,unknownRequestAttemptCount:1,extractionPolicy:{ingredientMethodSectionCoverage:'exact normalized equality against captured source sections',minimalMethodAction:'at least one cooking/preparation action verb',rejectReasons:Object.keys(rejectedByReason)}},recipes,relationships:[],counts:{recipes:recipes.length,ingredientsAndMethodSectionCoverageExact:recipes.length,runtimeReady:0},duplicateReview:{againstManifestPacks:manifest.packs.length,exactSourceUrlOrContentDuplicates:duplicates}};
  const packText=fmt(pack); await writeFile(resolve(root,packFolder,'normalized-recipes.json'),packText);
  const summary={schemaVersion:1,completedAt:new Date().toISOString(),target,batch,skipAccepted,accepted:recipes.length,remaining:target-recipes.length,counts:{totalRows,foodistaUrls,complete,incomplete,noLicense,ingredientCoverageFailures,methodCoverageFailures,qualityRejected,rightsExcluded,rejectedByReason,repeatedNumberingReview,duplicates,accepted:recipes.length},requests:checkpoints,requestHistory:pack.sourceEvidence.requestHistory,knownLogicalRequestCount:13,unknownRequestAttemptCount:1,packPath:`${packFolder}/normalized-recipes.json`,packSha256:sha(packText),snapshotCount:snapshots.length,sourceRevision:commit,sourceRevisionTimestamp:null,sourceShardHashes:Object.fromEntries(checkpoints.map(c=>[c.shard,c.compressedSha256])),stopPolicy:'No retries; stop on access/status failure.'};
  await writeFile(resolve(root,folder,'checkpoint.json'),fmt(summary));
  console.log(fmt(summary));
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main().catch(e=>{ console.error(e.message); process.exitCode=1; });
