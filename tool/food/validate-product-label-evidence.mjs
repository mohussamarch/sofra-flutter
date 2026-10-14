import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const domtyAuthority = 'Arabian Food Industries Company (Domty)';
const catalog = new Map([
  ['domty-bran', ['https://domty.org/product/bran-toast/', domtyAuthority, 'manufacturer-product-page', 'retrieved', 'Bran Toast']],
  ['domty-milk', ['https://domty.org/product/milk-toast/', domtyAuthority, 'manufacturer-product-page', 'retrieved', 'Milk Toast']],
  ['domty-brioche', ['https://domty.org/product/brioche-toast/', domtyAuthority, 'manufacturer-product-page', 'retrieved', 'Brioche Toast']],
  ['domty-high-protein', ['https://domty.org/product/high-protein-toast-with-chia-seeds/', domtyAuthority, 'manufacturer-product-page', 'retrieved', 'High Protein Toast with Chia Seeds']],
  ['juhayna-dairy', ['https://www.juhayna.com/brands-category/juhayna-dairy/', 'Juhayna', 'manufacturer-category-page', 'retrieved', null]],
  ['almarai-failed', ['https://www.almarai.com/en/brands/almarai/fresh-dairy/fresh-milk/full-fat-fresh-milk', 'Almarai', 'manufacturer-product-page', 'unavailable', null]],
]);
const proposedIds = new Map([
  ['Gluten', 'gluten'], ['Soy', 'soy'], ['Milk', 'milk'],
  ['Milk and Milk Products', 'milk'], ['Eggs', 'egg'],
]);
const fail = message => { throw new Error(message); };
const expect = (value, message) => { if (!value) fail(message); };
const text = (value, field) => expect(typeof value === 'string' && value.trim().length > 0, field);
function object(value, keys, field) {
  expect(value !== null && typeof value === 'object' && !Array.isArray(value), field);
  expect(Object.keys(value).every(key => keys.includes(key)), field + ': unknown fields');
  expect(keys.every(key => Object.hasOwn(value, key)), field + ': missing fields');
}
function array(value, field) { expect(Array.isArray(value), field); }
function exactObject(value, expected, field) {
  object(value, Object.keys(expected), field);
  for (const [key, expectedValue] of Object.entries(expected)) expect(value[key] === expectedValue, field + '.' + key);
}
function utc(value, field) {
  expect(typeof value === 'string' && /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{3})?Z$/.test(value) && Number.isFinite(Date.parse(value)), field);
  const normalized = new Date(value).toISOString();
  expect(normalized === value || normalized.replace('.000Z', 'Z') === value, field);
}
const words = value => (value.match(/[\p{L}\p{N}]+(?:['’-][\p{L}\p{N}]+)*/gu) ?? []).length;
// This is the reviewed grammar of this bounded batch, not an ingredient inference
// engine or an upstream text authentication check.
function extractDeclaration(excerpt) {
  const match = /^Contains ([^.]+)\.(?: The product may contain traces of ([^.]+)\.)?$/.exec(excerpt);
  expect(match, 'explicit allergen statement grammar');
  return { contains: match[1].split(' - '), mayContain: match[2] ? [match[2]] : [] };
}

export function validateProductLabelEvidence(bank) {
  object(bank, ['schemaVersion', 'batchId', 'scope', 'capturedAt', 'approvals', 'sources', 'products'], 'bank');
  expect(bank.schemaVersion === 1 && bank.batchId === 'product-label-evidence-20261014' &&
    bank.scope === 'research-only-manufacturer-web-declarations', 'research scope');
  utc(bank.capturedAt, 'capturedAt');
  exactObject(bank.approvals, { runtime: false, clinical: false, currentLaw: false, redistribution: false }, 'approvals');
  array(bank.sources, 'sources'); array(bank.products, 'products');
  expect(bank.sources.length > 0 && bank.products.length > 0, 'empty bank');
  const sources = new Map();
  for (const source of bank.sources) {
    object(source, ['id', 'url', 'authority', 'kind', 'access', 'retrievedAt', 'publishedAt', 'publicationScope', 'retrievalMethod', 'archived', 'bodySha256', 'rights', 'sourceMarket', 'contactCountryContext', 'evidence', 'accessNote'], 'source');
    text(source.id, 'source id');
    expect(!sources.has(source.id), 'duplicate source');
    const spec = catalog.get(source.id);
    expect(spec, 'unreviewed source');
    let url;
    try { url = new URL(source.url); } catch { fail('official URL'); }
    expect(url.protocol === 'https:' && !url.username && !url.password && source.url === spec[0], 'official URL');
    expect(source.authority === spec[1] && source.kind === spec[2] && source.access === spec[3], 'manufacturer source identity/access');
    utc(source.retrievedAt, 'retrievedAt');
    expect(Date.parse(source.retrievedAt) <= Date.parse(bank.capturedAt), 'retrievedAt chronology');
    expect(source.publishedAt === null, 'publishedAt remains unknown');
    expect(source.publicationScope === 'unknown', 'publicationScope');
    expect(source.retrievalMethod === 'web-opened-page', 'retrievalMethod');
    expect(source.archived === false && source.bodySha256 === null, 'unarchived source hash');
    expect(source.rights === 'unknown', 'rights');
    expect(source.sourceMarket === null, 'sourceMarket cannot derive from manufacturer address');
    if (source.contactCountryContext !== null) {
      object(source.contactCountryContext, ['country', 'basis', 'locator'], 'contactCountryContext');
      expect(source.contactCountryContext.country === 'EG' && source.contactCountryContext.basis === 'contact-address-only', 'contactCountryContext');
      text(source.contactCountryContext.locator, 'contactCountryContext locator');
    }
    if (spec[4] !== null) {
      expect(source.access === 'retrieved', 'retrieved manufacturer product');
      object(source.evidence, ['id', 'kind', 'locator', 'excerpt'], 'evidence');
      expect(source.evidence.id === source.id + '-allergens', 'evidenceId');
      expect(source.evidence.kind === 'explicit-allergen-statement', 'explicit allergen statement');
      text(source.evidence.locator, 'locator'); text(source.evidence.excerpt, 'excerpt');
      expect(words(source.evidence.excerpt) + words(spec[4]) <= 25, 'source title/excerpt exceeds 25 words');
      const declarations = extractDeclaration(source.evidence.excerpt);
      for (const term of [...declarations.contains, ...declarations.mayContain]) expect(proposedIds.has(term), 'exact proposed mapping');
      expect(source.accessNote === null, 'product source accessNote');
    } else {
      expect(source.evidence === null, 'non-declaration source evidence');
      text(source.accessNote, 'accessNote');
    }
    sources.set(source.id, source);
  }
  const productIds = new Set();
  const usedSources = new Set();
  let contains = 0, mayContain = 0;
  for (const product of bank.products) {
    object(product, ['researchId', 'pageFacts', 'declarations', 'pendingLocalProductMatch', 'runtimeFoodRecordApproval', 'unknowns'], 'product');
    text(product.researchId, 'researchId');
    expect(!productIds.has(product.researchId), 'duplicate product');
    productIds.add(product.researchId);
    const facts = product.pageFacts;
    object(facts, ['brand', 'exactProductName', 'variant', 'sourceId', 'packQuantity', 'labelVersion', 'gtin', 'form', 'sourceMarket', 'sourceMarketEvidence', 'nutrition'], 'pageFacts');
    const source = sources.get(facts.sourceId), spec = catalog.get(facts.sourceId);
    expect(source && spec[4] !== null && source.access === 'retrieved' && source.evidence, 'retrieved manufacturer product');
    expect(!usedSources.has(facts.sourceId), 'duplicate product source');
    usedSources.add(facts.sourceId);
    expect(product.researchId === facts.sourceId + '-web-observation' && facts.brand === 'Domty' && facts.exactProductName === spec[4] && facts.variant === spec[4], 'exact product identity');
    for (const key of ['packQuantity', 'labelVersion', 'gtin', 'form', 'sourceMarket', 'sourceMarketEvidence', 'nutrition']) expect(facts[key] === null, 'pageFacts.' + key + ' remains unknown in this batch');
    const declarations = product.declarations;
    object(declarations, ['basis', 'sourceId', 'evidenceId', 'contains', 'mayContain', 'freeFrom', 'unlistedStatus'], 'declarations');
    expect(declarations.basis === 'explicit-manufacturer-allergen-statement', 'explicit declaration basis');
    const declarationSource = sources.get(declarations.sourceId);
    expect(declarationSource && declarationSource.access === 'retrieved' && declarationSource.kind === 'manufacturer-product-page' && declarationSource.evidence, 'retrieved manufacturer product');
    expect(declarations.sourceId === facts.sourceId && declarations.evidenceId === source.evidence.id, 'evidenceId and source linkage');
    array(declarations.freeFrom, 'freeFrom');
    expect(declarations.freeFrom.length === 0, 'freeFrom cannot be inferred');
    expect(declarations.unlistedStatus === 'unknown', 'unlistedStatus must remain unknown');
    const extracted = extractDeclaration(source.evidence.excerpt);
    const ids = new Set();
    for (const status of ['contains', 'mayContain']) {
      array(declarations[status], status);
      for (const declaration of declarations[status]) {
        object(declaration, ['sourceTerm', 'canonicalId', 'mappingStatus', 'evidenceId'], 'declaration');
        expect(proposedIds.get(declaration.sourceTerm) === declaration.canonicalId && declaration.mappingStatus === 'proposed', 'exact proposed mapping');
        expect(declaration.evidenceId === source.evidence.id, 'evidenceId');
        expect(!ids.has(declaration.canonicalId), 'duplicate declaration');
        ids.add(declaration.canonicalId);
      }
      expect(declarations[status].length === extracted[status].length &&
        declarations[status].every((d, index) => d.sourceTerm === extracted[status][index]), 'explicit statement/status mismatch');
    }
    contains += declarations.contains.length; mayContain += declarations.mayContain.length;
    exactObject(product.pendingLocalProductMatch, { status: 'pending', foodRecordId: null, foodRecordVersion: null, gtin: null, reviewed: false }, 'pendingLocalProductMatch');
    exactObject(product.runtimeFoodRecordApproval, { approved: false, approvedAt: null, approvedBy: null }, 'runtimeFoodRecordApproval');
    array(product.unknowns, 'unknowns');
    expect(product.unknowns.length > 0, 'unknowns required');
    product.unknowns.forEach(value => text(value, 'unknown note'));
  }
  return { sources: sources.size, retrievedSources: [...sources.values()].filter(s => s.access === 'retrieved').length,
    products: productIds.size, contains, mayContain, verifiedMarketProducts: 0, runtimeApprovals: 0 };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const path = process.argv[2] ?? fileURLToPath(new URL('../../data/food/product-label-evidence/20261014/manufacturer-evidence.json', import.meta.url));
    const result = validateProductLabelEvidence(JSON.parse(readFileSync(path, 'utf8')));
    console.log(JSON.stringify(result));
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
