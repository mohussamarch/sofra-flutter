import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { validateProductLabelEvidence } from './validate-product-label-evidence.mjs';

const fixture = () => JSON.parse(readFileSync(new URL('../../data/food/product-label-evidence/20261014/manufacturer-evidence.json', import.meta.url), 'utf8'));
const rejects = (mutate, pattern) => {
  const bank = fixture();
  mutate(bank);
  assert.throws(() => validateProductLabelEvidence(bank), pattern);
};

test('actual manufacturer declarations preserve contains versus possible egg traces', () => {
  const bank = fixture();
  assert.deepEqual(validateProductLabelEvidence(bank), {
    sources: 6, retrievedSources: 5, products: 4, contains: 13, mayContain: 3,
    verifiedMarketProducts: 0, runtimeApprovals: 0,
  });
  assert.equal(bank.products[2].declarations.contains.at(-1).canonicalId, 'egg');
  assert.equal(bank.products[2].declarations.mayContain.length, 0);
});

test('rejects absence and free-from inference', () => {
  rejects(b => b.products[0].declarations.freeFrom.push({ canonicalId: 'peanut' }), /freeFrom/);
  rejects(b => b.products[0].declarations.otherAllergens = 'absent', /unknown fields/);
  rejects(b => b.products[0].declarations.unlistedStatus = 'freeFrom', /unlistedStatus/);
});

test('wheat ingredients do not become declared gluten or wheat claims', () => {
  rejects(b => b.products[0].declarations.contains[0].canonicalId = 'wheat', /exact proposed mapping/);
  rejects(b => b.products[0].declarations.basis = 'ingredients', /explicit/);
  rejects(b => b.products[0].declarations.contains.push({ sourceTerm: 'Wheat Flour', canonicalId: 'wheat', mappingStatus: 'proposed', evidenceId: 'domty-bran-allergens' }), /exact proposed mapping/);
});

test('rejects local identity, runtime and clinical/legal promotion', () => {
  rejects(b => b.products[0].pendingLocalProductMatch.foodRecordId = 'off:123', /pendingLocalProductMatch/);
  rejects(b => b.products[0].runtimeFoodRecordApproval.approved = true, /runtimeFoodRecordApproval/);
  rejects(b => b.products[0].runtimeFoodRecordApproval.foodRecord = {}, /unknown fields/);
  rejects(b => b.approvals.clinical = true, /approvals/);
  rejects(b => b.approvals.currentLaw = true, /approvals/);
});

test('source address cannot establish product market', () => {
  rejects(b => b.products[0].pageFacts.sourceMarket = 'EG', /sourceMarket/);
  rejects(b => b.products[0].pageFacts.sourceMarketEvidence = 'Giza address', /sourceMarketEvidence/);
});

test('unknown pack, form, version, barcode and nutrition stay unknown', () => {
  for (const field of ['packQuantity', 'gtin', 'form', 'labelVersion', 'nutrition']) {
    rejects(b => b.products[0].pageFacts[field] = field === 'nutrition' ? {} : 'guessed', /pageFacts/);
  }
});

test('explicit declaration source and locator are mandatory', () => {
  rejects(b => b.products[0].declarations.sourceId = 'almarai-failed', /retrieved manufacturer product/);
  rejects(b => b.products[0].declarations.evidenceId = 'missing', /evidenceId/);
  rejects(b => b.sources[0].evidence.locator = '', /locator/);
  rejects(b => b.sources[0].evidence.kind = 'ingredient-list', /explicit/);
  rejects(b => b.products[0].declarations.mayContain[0].canonicalId = 'milk', /exact proposed mapping/);
});

test('unknown rights and unarchived source hashes cannot be fabricated', () => {
  rejects(b => b.sources[0].bodySha256 = 'a'.repeat(64), /unarchived/);
  rejects(b => b.sources[0].archived = true, /unarchived/);
  rejects(b => b.sources[0].rights = 'CC0', /rights/);
  rejects(b => b.sources[0].publishedAt = '2026-10-14', /publishedAt/);
});

test('rejects spoofed hosts and search snippets as declaration source', () => {
  rejects(b => b.sources[0].url = 'https://domty.org.evil.example/product/bran-toast/', /official URL/);
  rejects(b => b.sources[0].url = 'https://user:secret@domty.org/product/bran-toast/', /official URL/);
  rejects(b => b.sources[0].retrievalMethod = 'search-snippet', /retrievalMethod/);
});

test('duplicates and unknown fields cannot hide unsupported declarations', () => {
  rejects(b => b.products.push(structuredClone(b.products[0])), /duplicate product/);
  rejects(b => b.sources.push(structuredClone(b.sources[0])), /duplicate source/);
  rejects(b => b.products[0].declarations.contains.push(structuredClone(b.products[0].declarations.contains[0])), /duplicate declaration/);
  rejects(b => b.products[0].price = 0, /unknown fields/);
});

test('retrieval dates and copyright excerpt budget are checked', () => {
  rejects(b => b.sources[0].retrievedAt = 'tomorrow', /retrievedAt/);
  rejects(b => b.sources[0].evidence.excerpt += ' unsupported '.repeat(30), /25 words/);
});
