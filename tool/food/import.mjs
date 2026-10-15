import {offResearchUserAgent} from './off-contact.mjs';
import { mkdir, readFile, writeFile, readdir, access } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

export const categories = [
  ['sweets', 'en:confectioneries'], ['chocolate', 'en:chocolates'],
  ['biscuits', 'en:biscuits'], ['snacks', 'en:salty-snacks'],
  ['dairy', 'en:dairies'], ['oils', 'en:vegetable-oils'], ['ghee', 'en:ghee'],
  ['rice', 'en:rices'], ['pasta', 'en:pastas'], ['flour', 'en:flours'],
  ['pulses', 'en:legumes'], ['canned-fish', 'en:canned-fishes'],
  ['meat', 'en:meats'], ['canned-vegetables', 'en:canned-vegetables'],
  ['condiments', 'en:condiments'], ['spices', 'en:spices'],
  ['beverages', 'en:beverages'], ['frozen', 'en:frozen-foods'],
  ['bakery', 'en:breads'], ['baby', 'en:baby-foods'],
];
export const sha256 = data => createHash('sha256').update(data).digest('hex');
export function validGtin(code) {
  if (!/^(\d{8}|\d{12}|\d{13}|\d{14})$/.test(code) || /^0+$/.test(code)) return false;
  let sum = 0;
  for (let i = code.length - 2, n = 0; i >= 0; i--, n++) sum += Number(code[i]) * (n % 2 === 0 ? 3 : 1);
  return (10 - sum % 10) % 10 === Number(code.at(-1));
}
const array = value => Array.isArray(value) ? value : [];
const text = value => typeof value === 'string' ? value.trim() : '';
const numeric = value => typeof value === 'number' && Number.isFinite(value) && value >= 0;
const unitFor = name => name === 'energy' || name === 'energy-kj' ? 'kJ' : name === 'energy-kcal' ? 'kcal' : name === 'alcohol' ? '% vol' : name === 'ph' ? null : 'g';
export function normalize(raw, provenance) {
  const code = String(raw.code ?? '');
  if (!validGtin(code)) return { rejected: 'invalid-gtin', barcode: code };
  const names = { ar: text(raw.product_name_ar), en: text(raw.product_name_en), original: text(raw.product_name) };
  if (!Object.values(names).some(Boolean)) return { rejected: 'missing-name', barcode: code };
  const warnings = [], asSold = {}, prepared = {};
  for (const [field, value] of Object.entries(raw.nutriments ?? {})) {
    const match = /^(.*?)(_prepared)?_100g$/.exec(field);
    if (!match) continue;
    if (!numeric(value)) { warnings.push(`invalid-nutrient:${field}`); continue; }
    // Standardized units belong to _100g fields; *_unit may describe entered values instead.
    const unit = unitFor(match[1]);
    if (unit === null || /^(nutrition-score|nova|carbon-footprint|fruits-vegetables|water-hardness|glycemic)/.test(match[1])) continue;
    if (unit === 'g' && value > 100) { warnings.push(`implausible-nutrient:${field}`); continue; }
    const modifier = raw.nutriments[`${match[1]}${match[2] ?? ''}_modifier`] ?? null;
    (match[2] ? prepared : asSold)[match[1]] = { value, unit, sourceField: field, modifier };
  }
  const tags = array(raw.categories_tags);
  const marketTags = array(raw.countries_tags);
  const markets = [['EG', 'en:egypt'], ['SA', 'en:saudi-arabia']].filter(([, tag]) => marketTags.includes(tag)).map(([id]) => id);
  const groups = categories.filter(([, tag]) => tags.includes(tag)).map(([id]) => id);
  if (!groups.length) groups.push('unclassified');
  const packageUnit = ['g', 'ml'].includes(raw.product_quantity_unit) ? raw.product_quantity_unit : null;
  const declared = array(raw.allergens_tags), traces = array(raw.traces_tags);
  warnings.push('community-data-unverified', 'nutrition-basis-needs-label-review');
  if (!text(raw.brands)) warnings.push('missing-brand');
  if (array(raw.data_quality_errors_tags).length) warnings.push('source-data-quality-errors');
  const energyKj=asSold['energy-kj'] ?? asSold.energy;
  if (asSold['energy-kcal'] && energyKj && Math.abs(asSold['energy-kcal'].value * 4.184 - energyKj.value) > Math.max(20, energyKj.value * 0.08)) warnings.push('energy-units-inconsistent');
  if (asSold.sugars && asSold.carbohydrates && asSold.sugars.value > asSold.carbohydrates.value + 1) warnings.push('sugars-exceed-carbohydrates');
  if (asSold['saturated-fat'] && asSold.fat && asSold['saturated-fat'].value > asSold.fat.value + 1) warnings.push('saturated-fat-exceeds-total-fat');
  if (!Object.keys(asSold).length) warnings.push('missing-nutrition');
  if (!text(raw.ingredients_text) && !text(raw.ingredients_text_ar) && !text(raw.ingredients_text_en)) warnings.push('missing-ingredients');
  if (!markets.length) warnings.push('market-not-confirmed');
  return {
    id: `off:${code}`, barcode: code, names, brands: text(raw.brands), categories: groups,
    sourceCategoryTags: tags, markets, sourceCountryTags: marketTags,
    package: { label: text(raw.quantity), quantity: numeric(raw.product_quantity) ? raw.product_quantity : null, unit: packageUnit },
    nutrition: {
      // OFF uses the same _100g key for 100g and 100ml. Packaging is only a hint.
      basis: { amount: 100, unit: null, packageUnitHint: packageUnit, requiresLabelReview: true },
      sourceEnteredBasis: raw.nutrition_data_per ?? null,
      sourcePreparedBasis: raw.nutrition_data_prepared_per ?? null,
      asSold, prepared,
      serving: { label: text(raw.serving_size), quantity: raw.serving_quantity ?? null, unit: raw.serving_quantity_unit ?? null },
    },
    allergens: { status: declared.length ? 'source-reported' : 'unknown', declaredTags: declared, traceTags: traces,
      declaration: text(raw.allergens), traceDeclaration: text(raw.traces),
      ingredientsText: { original: text(raw.ingredients_text), ar: text(raw.ingredients_text_ar), en: text(raw.ingredients_text_en) } },
    source: { provider: 'Open Food Facts', url: `https://world.openfoodfacts.org/product/${code}`,
      retrievedAt: provenance.retrievedAt, lastModifiedEpoch: raw.last_modified_t ?? null,
      databaseLicense: 'ODbL-1.0', contentsLicense: 'DbCL-1.0', rawArchive: provenance.archive,
      dataQualityErrors: array(raw.data_quality_errors_tags), dataQualityWarnings: array(raw.data_quality_warnings_tags) },
    quality: { verification: 'unreviewed', warnings },
  };
}

const fields = ['code','product_name','product_name_ar','product_name_en','brands','categories_tags','countries_tags','quantity','product_quantity','product_quantity_unit','serving_size','serving_quantity','serving_quantity_unit','nutrition_data','nutrition_data_per','nutrition_data_prepared_per','nutriments','allergens','allergens_tags','traces','traces_tags','ingredients_text','ingredients_text_ar','ingredients_text_en','last_modified_t','data_quality_errors_tags','data_quality_warnings_tags','states_tags'];
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
export async function fetchArchive(out, { country, page = 1, category = null, id, fetchImpl = fetch, contactEmail = process.env.SOFRA_OFF_CONTACT_EMAIL, now = () => new Date().toISOString() }) {
  try { await access(path.join(out,'raw',`${id}.json`)); console.log(`${id}: cached`); return 0; } catch {}
  const userAgent = offResearchUserAgent(contactEmail);
  const url = new URL('https://world.openfoodfacts.org/cgi/search.pl');
  for (const [key, value] of Object.entries({action:'process',json:1,page_size:100,page,sort_by:'unique_scans_n',fields:fields.join(','),tagtype_0:'countries',tag_contains_0:'contains',tag_0:country})) url.searchParams.set(key, value);
  if (category) for (const [key, value] of Object.entries({tagtype_1:'categories',tag_contains_1:'contains',tag_1:category})) url.searchParams.set(key,value);
  const response = await fetchImpl(url, { headers: {'User-Agent':userAgent}, signal: AbortSignal.timeout(60000) });
  if (!response.ok) {
    // Undici requires consuming or cancelling bodies to release connections.
    // Cleanup failure must not replace the HTTP status used for source backoff.
    try { await response.body?.cancel(); } catch {}
    throw new Error(`OFF ${response.status}: ${url}`);
  }
  const data = await response.json();
  if (!Array.isArray(data.products)) throw new Error('Invalid OFF response');
  const envelope = { retrievedAt:now(), requestedUrl:url.href, query:{country,page,category}, count:data.count, products:data.products };
  await mkdir(path.join(out,'raw'),{recursive:true});
  await writeFile(path.join(out,'raw',`${id}.json`),JSON.stringify(envelope)+'\n');
  console.log(`${id}: ${data.products.length} / ${data.count}`);
  return data.products.length;
}
export async function collect(out, plans) {
  const failures=[];
  for (const plan of plans) {
    try { await fetchArchive(out,plan); }
    catch (error) { console.error(`${plan.id}: ${error.message}`); failures.push({plan:{country:plan.country,page:plan.page??1,category:plan.category??null,id:plan.id},error:String(error.message),at:new Date().toISOString()}); }
    await sleep(8000);
  }
  await mkdir(out,{recursive:true});
  await writeFile(path.join(out,'fetch-failures.json'),JSON.stringify(failures,null,2)+'\n');
  return buildBank(out);
}

export async function buildBank(out) {
  const files = (await readdir(path.join(out,'raw'))).filter(f=>f.endsWith('.json')).sort();
  const products = new Map(), quarantine = [], duplicates = [], archives=[];
  for (const file of files) {
    const rawText = await readFile(path.join(out,'raw',file),'utf8');
    const page = JSON.parse(rawText);
    archives.push({file:`raw/${file}`,sha256:sha256(rawText),records:page.products.length,retrievedAt:page.retrievedAt,url:page.requestedUrl});
    for (const raw of page.products) {
      const record = normalize(raw,{retrievedAt:page.retrievedAt,archive:`raw/${file}`});
      if (record.rejected) {quarantine.push({...record,archive:`raw/${file}`});continue;}
      const old = products.get(record.barcode);
      if (old) {
        const replace = (record.source.lastModifiedEpoch ?? 0) > (old.source.lastModifiedEpoch ?? 0);
        duplicates.push({barcode:record.barcode,kept:replace ? record.source.rawArchive : old.source.rawArchive,other:replace ? old.source.rawArchive : record.source.rawArchive,reason:'same-source-barcode-newest-revision-kept'});
        // Do not blend different revisions; keep the later OFF revision intact.
        if (replace) products.set(record.barcode,record);
      } else products.set(record.barcode,record);
    }
  }
  const records=[...products.values()].sort((a,b)=>a.barcode.localeCompare(b.barcode));
  const data=records.map(r=>JSON.stringify(r)).join('\n')+'\n';
  await writeFile(path.join(out,'products.jsonl'),data);
  const index = {schemaVersion:1,products:records.map(r=>({id:r.id,barcode:r.barcode,name:r.names.ar||r.names.en||r.names.original,brands:r.brands,markets:r.markets,categories:r.categories}))};
  const indexText=JSON.stringify(index)+'\n';
  await writeFile(path.join(out,'index.json'),indexText);
  await writeFile(path.join(out,'quarantine.json'),JSON.stringify(quarantine,null,2)+'\n');
  await writeFile(path.join(out,'duplicates.json'),JSON.stringify(duplicates,null,2)+'\n');
  const counts = key => Object.fromEntries(key.map(k=>[k,records.filter(r=>(r.categories.includes(k)||r.markets.includes(k))).length]));
  const manifest = {schemaVersion:1,dataset:'Sofra packaged food bank / Open Food Facts',builtAt:new Date().toISOString(),
    source:'https://world.openfoodfacts.org',databaseLicense:'ODbL-1.0',contentsLicense:'DbCL-1.0',
    productCount:records.length,quarantinedCount:quarantine.length,duplicateOccurrences:duplicates.length,
    productsSha256:sha256(data),indexSha256:sha256(indexText),marketCounts:counts(['EG','SA']),categoryCounts:counts(categories.map(([id])=>id)),
    withNutrition:records.filter(r=>Object.keys(r.nutrition.asSold).length).length,
    withCoreMacros:records.filter(r=>['energy-kcal','proteins','carbohydrates','fat'].every(k=>k in r.nutrition.asSold)).length,
    withIngredients:records.filter(r=>Object.values(r.allergens.ingredientsText).some(Boolean)).length,
    withBrand:records.filter(r=>r.brands).length,
    withDeclaredAllergens:records.filter(r=>r.allergens.declaredTags.length).length,
    unreviewedBasisCount:records.length,archives,
    limitations:['Not a complete catalogue or verified market popularity ranking','Market tags are community assertions, not availability/price guarantees','No nutritional basis is approved for calculation until label review','Absence of allergens or traces never means safe','No product photos or prices downloaded','Baby foods are segregated category only, no recommendations']};
  await writeFile(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
  console.log(JSON.stringify({...manifest,archives:archives.length}));
  return manifest;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const out=process.argv[3] ?? path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../data/food/openfoodfacts');
  if(process.argv[2]==='fetch') {
    const plans=[];
    for(const country of ['egypt','saudi-arabia']) for(let page=1;page<=3;page++) plans.push({country,page,id:`${country}-p${page}`});
    await collect(out,plans);
  } else if(process.argv[2]==='fetch-category') {
    const [id,category]=categories.find(([id])=>id===process.argv[4]) ?? [];
    if(!id) throw new Error('Unknown category');
    await collect(out,['egypt','saudi-arabia'].map(country=>({country,category,id:`${country}-${id}`})));
  } else if(process.argv[2]==='fetch-categories') {
    await collect(out,categories.flatMap(([id,category])=>['egypt','saudi-arabia'].map(country=>({country,category,id:`${country}-${id}`}))));
  } else if(process.argv[2]==='build') await buildBank(out);
  else throw new Error('Use fetch|fetch-categories|fetch-category|build [output-directory] [category-id]');
}
