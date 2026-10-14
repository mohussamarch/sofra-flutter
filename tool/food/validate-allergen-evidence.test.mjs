import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { validateAllergenEvidence } from './validate-allergen-evidence.mjs';

const url = new URL('../../data/food/allergen-evidence/20261014/official-evidence.json', import.meta.url);
const fixture = () => JSON.parse(readFileSync(url, 'utf8'));
const rejects = (edit, pattern) => {
  const bank = fixture();
  edit(bank);
  assert.throws(() => validateAllergenEvidence(bank), pattern);
};

test('bounded official bank validates with explicit counts', () => {
  assert.deepEqual(validateAllergenEvidence(fixture()), {
    sources: 4, retrievedSources: 2, claims: 7, mappingProposals: 15, runtimeApprovals: 0,
  });
});
test('missing guidance and absent warnings remain unknown', () => {
  const bank = fixture();
  assert.equal(bank.jurisdictionCoverage.find(x => x.jurisdiction === 'EG').vocabulary, 'unknown');
  assert.equal(bank.semantics.find(x => x.status === 'unknown').evidenceClaimId, null);
  rejects(b => b.semantics.find(x => x.status === 'unknown').evidenceClaimId = 'sa-contains', /unvalidated status/);
});
test('Saudi evidence cannot establish Egyptian rules or mappings', () => {
  rejects(b => b.claims[0].jurisdiction = 'EG', /jurisdiction/);
  rejects(b => b.vocabularyMappings[0].jurisdiction = 'EG', /jurisdiction/);
  rejects(b => b.jurisdictionCoverage[1].vocabulary = 'sourceBackedProposals', /Egypt/);
});
test('unavailable sources cannot support claims and dates stay unknown', () => {
  rejects(b => b.claims[0].sourceId = 'nfsa-access-attempt', /source unavailable/);
  rejects(b => b.sources[2].publishedDate = '2026-01-01', /unavailable source/);
});
test('source/anchor references and duplicate IDs are checked', () => {
  rejects(b => b.claims[0].sourceId = 'missing', /source missing/);
  rejects(b => b.vocabularyMappings[0].anchorId = 'missing', /anchor missing/);
  rejects(b => b.vocabularyMappings[1].id = b.vocabularyMappings[0].id, /duplicate/);
});
test('only official authority domains with matching jurisdiction are accepted', () => {
  rejects(b => b.sources[0].url = 'https://sfda.gov.sa.example.org/x', /official URL/);
  rejects(b => b.sources[0].authority = 'NFSA', /authority\/jurisdiction/);
  rejects(b => b.sources[0].url = 'https://name:secret@sfda.gov.sa/x', /official URL/);
});
test('wheat and gluten stay distinct, exact group proposals cannot become specific ingredients', () => {
  rejects(b => b.vocabularyMappings[0].canonicalId = 'wheat', /exact vocabulary/);
  rejects(b => b.vocabularyMappings[14].canonicalId = 'gluten', /exact vocabulary/);
  rejects(b => b.vocabularyMappings[1].termKind = 'specificIngredient', /exact vocabulary/);
});
test('nuts, peanuts, crustaceans and molluscs are not merged', () => {
  for (const [index, id] of [[4, 'treeNuts'], [6, 'peanut'], [1, 'molluscs'], [9, 'crustaceans']]) {
    rejects(b => b.vocabularyMappings[index].canonicalId = id, /exact vocabulary/);
  }
});
test('vocabulary proposal cannot become a product declaration or free-from claim', () => {
  for (const status of ['contains', 'mayContain', 'freeFrom']) {
    rejects(b => b.vocabularyMappings[0].productStatus = status, /product status/);
  }
  rejects(b => b.semantics.find(x => x.status === 'freeFrom').evidenceClaimId = 'sa-contains', /unvalidated status/);
});
test('unarchived bodies have null hashes and source reuse licence stays unknown', () => {
  rejects(b => b.sources[0].bodySha256 = 'a'.repeat(64), /unarchived/);
  rejects(b => b.sources[0].license = 'CC0', /licence/);
});
test('runtime, clinical, legal and alias approvals cannot be promoted', () => {
  for (const key of ['runtimeReady', 'clinicalApproved', 'legalCurrentnessVerified']) {
    rejects(b => b.approvals[key] = true, /approvals/);
  }
  rejects(b => b.approvals.runtimeAliasChanges = 1, /approvals/);
  rejects(b => b.claims[0].runtimeApproved = true, /runtime/);
  rejects(b => b.vocabularyMappings[0].status = 'approved', /proposal/);
  rejects(b => b.jurisdictionCoverage[0].currentLegalApplicability = 'verified', /legal/);
});
test('unknown fields and malformed/future chronology fail closed', () => {
  rejects(b => b.autoApply = true, /unknown field/);
  rejects(b => b.sources[0].retrievedAt = '2026-13-01T00:00:00Z', /timestamp/);
  rejects(b => b.sources[0].publishedDate = '2026-02-30', /date/);
  rejects(b => b.sources[0].publishedDate = '2099-01-01', /publication after/);
});
