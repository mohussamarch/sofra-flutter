#!/usr/bin/env node
// Research consistency checks only. No network, runtime imports or product decisions.
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const defaultBank = new URL('../../data/food/allergen-evidence/20261014/official-evidence.json', import.meta.url);
const vocabulary = new Map([
  ['الحبوب التي تحتوي على الجلوتين', ['gluten', 'group']],
  ['القشريات', ['crustaceans', 'group']], ['الأسماك', ['fish', 'group']],
  ['البيض', ['egg', 'group']], ['الفول السوداني', ['peanut', 'group']],
  ['الخردل', ['mustard', 'group']], ['المكسرات', ['treeNuts', 'group']],
  ['بذور السمسم', ['sesame', 'group']], ['الحليب', ['milk', 'group']],
  ['الرخويات', ['molluscs', 'group']], ['الكبريتيت', ['sulphites', 'group']],
  ['الترمس', ['lupin', 'group']], ['الكرفس', ['celery', 'group']],
  ['فول الصويا', ['soy', 'group']], ['القمح', ['wheat', 'specificIngredient']],
]);
const canonicalIds = new Set([...vocabulary.values()].map(x => x[0]));
const statuses = ['contains', 'mayContain', 'freeFrom', 'unknown'];
const check = (value, message) => { if (!value) throw new Error(message); };
const text = (v, name) => check(typeof v === 'string' && v.trim().length > 0, 'missing text: ' + name);
function shape(value, keys, name) {
  check(value && typeof value === 'object' && !Array.isArray(value), 'object required: ' + name);
  const actual = Object.keys(value);
  check(actual.every(k => keys.includes(k)), 'unknown field: ' + name);
  check(keys.every(k => Object.hasOwn(value, k)), 'missing field: ' + name);
}
function array(value, name) {
  check(Array.isArray(value), 'array required: ' + name);
}
function unique(rows, name) {
  array(rows, name);
  const ids = new Set();
  for (const row of rows) {
    text(row.id, name + '.id');
    check(!ids.has(row.id), 'duplicate id: ' + row.id);
    ids.add(row.id);
  }
}
function timestamp(value) {
  check(typeof value === 'string' && /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$/.test(value) &&
    Number.isFinite(Date.parse(value)) &&
    new Date(value).toISOString().slice(0, 19) === value.slice(0, 19), 'invalid timestamp');
}
function date(value) {
  check(typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value) &&
    Number.isFinite(Date.parse(value)) && new Date(value).toISOString().slice(0, 10) === value, 'invalid publication date');
}

export function validateAllergenEvidence(bank) {
  shape(bank, ['schemaVersion', 'id', 'createdAt', 'purpose', 'sources', 'claims',
    'vocabularyMappings', 'semantics', 'jurisdictionCoverage', 'approvals'], 'bank');
  check(bank.schemaVersion === 1, 'unsupported schema');
  text(bank.id, 'bank id'); text(bank.purpose, 'purpose'); timestamp(bank.createdAt);
  shape(bank.approvals, ['runtimeReady', 'clinicalApproved', 'legalCurrentnessVerified',
    'productDeclarations', 'runtimeAliasChanges'], 'approvals');
  check(bank.approvals.runtimeReady === false && bank.approvals.clinicalApproved === false &&
    bank.approvals.legalCurrentnessVerified === false && bank.approvals.productDeclarations === 0 &&
    bank.approvals.runtimeAliasChanges === 0, 'research approvals must remain false/zero');
  unique(bank.sources, 'sources'); unique(bank.claims, 'claims'); unique(bank.vocabularyMappings, 'mappings');
  const sources = new Map();
  for (const source of bank.sources) {
    shape(source, ['id', 'authority', 'jurisdiction', 'url', 'title', 'publishedDate',
      'publishedDateBasis', 'retrievedAt', 'scope', 'retrievalStatus', 'failure', 'license',
      'archived', 'bodySha256', 'anchors'], 'source');
    const domain = source.authority === 'SFDA' && source.jurisdiction === 'SA' ? 'sfda.gov.sa' :
      source.authority === 'NFSA' && source.jurisdiction === 'EG' ? 'nfsa.gov.eg' : null;
    check(domain, 'unsupported authority/jurisdiction');
    let url;
    try { url = new URL(source.url); } catch { throw new Error('invalid official URL'); }
    check(url.protocol === 'https:' && !url.username && !url.password &&
      !url.port && (url.hostname === domain || url.hostname === 'www.' + domain), 'invalid official URL');
    for (const key of ['title', 'publishedDateBasis', 'scope']) text(source[key], key);
    timestamp(source.retrievedAt);
    check(Date.parse(source.retrievedAt) <= Date.parse(bank.createdAt), 'retrieval after bank creation');
    if (source.publishedDate !== null) {
      date(source.publishedDate);
      check(source.publishedDate <= source.retrievedAt.slice(0, 10), 'publication after retrieval');
    }
    check(source.license === 'unknown', 'unverified source licence');
    check(source.archived === false && source.bodySha256 === null, 'unarchived body must have null hash');
    check(['retrieved', 'unavailable'].includes(source.retrievalStatus), 'invalid retrieval status');
    unique(source.anchors, 'anchors');
    for (const anchor of source.anchors) {
      shape(anchor, ['id', 'locator'], 'anchor'); text(anchor.locator, 'locator');
    }
    if (source.retrievalStatus === 'unavailable') {
      text(source.failure, 'failure');
      check(source.publishedDate === null && source.anchors.length === 0, 'unavailable source has evidence');
    } else check(source.failure === null && source.anchors.length > 0, 'retrieved source lacks anchors');
    sources.set(source.id, source);
  }
  const evidence = (row) => {
    const source = sources.get(row.sourceId);
    check(source, 'source missing: ' + row.sourceId);
    check(source.retrievalStatus === 'retrieved', 'source unavailable');
    check(source.jurisdiction === row.jurisdiction, 'evidence jurisdiction mismatch');
    check(source.anchors.some(x => x.id === row.anchorId), 'anchor missing');
    check(row.runtimeApproved === false, 'runtime approval prohibited');
    return source;
  };
  const claims = new Map();
  for (const claim of bank.claims) {
    shape(claim, ['id', 'sourceId', 'anchorId', 'jurisdiction', 'kind', 'statement', 'status',
      'currentLegalApplicability', 'runtimeApproved'], 'claim');
    evidence(claim);
    check(['vocabulary', 'disclosureScope', 'containsMeaning', 'mayContainMeaning',
      'precautionaryBoundary', 'packagedContext', 'specificVocabulary'].includes(claim.kind), 'unsupported claim kind');
    check(claim.status === 'sourceParaphrase' && claim.currentLegalApplicability === 'unknown', 'claim legal/status approval');
    text(claim.statement, 'statement'); claims.set(claim.id, claim);
  }
  const terms = new Set();
  for (const proposal of bank.vocabularyMappings) {
    shape(proposal, ['id', 'sourceId', 'anchorId', 'jurisdiction', 'sourceTerm', 'canonicalId',
      'termKind', 'status', 'rationale', 'notImpliedCanonicalIds', 'productStatus', 'runtimeApproved'], 'mapping');
    evidence(proposal);
    const expected = vocabulary.get(proposal.sourceTerm);
    check(expected && expected[0] === proposal.canonicalId && expected[1] === proposal.termKind,
      'unsupported exact vocabulary mapping');
    check(proposal.jurisdiction === 'SA' &&
      proposal.sourceId === (proposal.termKind === 'group' ? 'sfda-menu-2019' : 'sfda-menu-guide') &&
      proposal.anchorId === (proposal.termKind === 'group' ? 'groups' : 'wheat'), 'mapping evidence scope');
    check(proposal.status === 'proposed', 'mapping must remain proposal');
    check(proposal.productStatus === 'unknown', 'vocabulary is not product status');
    text(proposal.rationale, 'rationale');
    array(proposal.notImpliedCanonicalIds, 'non-inference ids');
    check(proposal.notImpliedCanonicalIds.every(id => canonicalIds.has(id) && id !== proposal.canonicalId) &&
      new Set(proposal.notImpliedCanonicalIds).size === proposal.notImpliedCanonicalIds.length, 'invalid non-inference ids');
    const guard = {gluten: 'wheat', wheat: 'gluten', peanut: 'treeNuts', treeNuts: 'peanut',
      crustaceans: 'molluscs', molluscs: 'crustaceans'}[proposal.canonicalId];
    check(!guard || proposal.notImpliedCanonicalIds.includes(guard), 'missing non-inference guard');
    const key = proposal.jurisdiction + ':' + proposal.sourceTerm;
    check(!terms.has(key), 'duplicate vocabulary proposal'); terms.add(key);
  }
  array(bank.semantics, 'semantics');
  check(bank.semantics.length === statuses.length &&
    statuses.every(status => bank.semantics.filter(x => x.status === status).length === 1), 'four distinct statuses required');
  for (const semantic of bank.semantics) {
    shape(semantic, ['status', 'evidenceClaimId', 'sourceTerm', 'jurisdiction', 'scope', 'runtimeApproved'], 'semantic');
    text(semantic.scope, 'semantic scope'); check(semantic.runtimeApproved === false, 'runtime semantics prohibited');
    if (semantic.status === 'contains' || semantic.status === 'mayContain') {
      const claim = claims.get(semantic.evidenceClaimId);
      check(claim && claim.kind === semantic.status + 'Meaning' && claim.jurisdiction === semantic.jurisdiction,
        'status evidence/jurisdiction mismatch');
      check(semantic.sourceTerm === (semantic.status === 'contains' ? 'يحتوي على' : 'قد يحتوي على'),
        'exact declaration wording required');
    } else check(semantic.evidenceClaimId === null && semantic.sourceTerm === null && semantic.jurisdiction === null,
      'unvalidated status must remain unknown/unscoped');
  }
  array(bank.jurisdictionCoverage, 'coverage');
  check(bank.jurisdictionCoverage.length === 2 &&
    ['SA', 'EG'].every(j => bank.jurisdictionCoverage.filter(x => x.jurisdiction === j).length === 1), 'SA/EG coverage required');
  for (const coverage of bank.jurisdictionCoverage) {
    shape(coverage, ['jurisdiction', 'vocabulary', 'declarationSemantics', 'currentLegalApplicability',
      'freeFromRequirements', 'limitations'], 'coverage');
    text(coverage.limitations, 'coverage limitations');
    check(coverage.currentLegalApplicability === 'unknown' && coverage.freeFromRequirements === 'unknown',
      'current legal/free-from requirements unverified');
    if (coverage.jurisdiction === 'EG') check(coverage.vocabulary === 'unknown' &&
      coverage.declarationSemantics === 'unknown', 'Egypt guidance must remain unknown');
    else check(coverage.vocabulary === 'sourceBackedProposals' &&
      coverage.declarationSemantics === 'sourceBackedResearch', 'Saudi research coverage mismatch');
  }
  return {sources: sources.size, retrievedSources: [...sources.values()].filter(x => x.retrievalStatus === 'retrieved').length,
    claims: claims.size, mappingProposals: bank.vocabularyMappings.length, runtimeApprovals: 0};
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    check(process.argv.length <= 3, 'usage: node validate-allergen-evidence.mjs [bank.json]');
    const result = validateAllergenEvidence(JSON.parse(readFileSync(process.argv[2] ?? defaultBank, 'utf8')));
    console.log(JSON.stringify(result));
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
