import test from 'node:test';
import assert from 'node:assert/strict';
import { validateResearchBank, candidateFingerprint } from './validate-research.mjs';

function fixture() {
  return {
    schemaVersion: 1,
    sources: [{ id: 'source-a', url: 'https://example.org/recipes', title: 'Source',
      publisher: 'Publisher', license: 'unknown', licenseStatus: 'unknown', retrievedAt: '2026-10-13T11:00:00Z' }],
    recipes: [{ id: 'research:one', name: 'Rice', recordVersion: 1, sourceRevision: null, sourceId: 'source-a', sourceRecipeId: 'one',
      sourceUrl: 'https://example.org/recipes/one', familyId: 'research-dish:one',
      variantId: 'research-variant:one', reviewStatus: 'research-only', servings: null,
      ingredients: [{ id: 'line-1', name: 'أرز', amount: null, unit: null,
        sourceText: 'Rice to taste', foodBinding: null }],
      steps: [{ n: 1, text: 'حضّر الأرز حسب الطريقة المنشورة.', durationMinutes: null }],
      nutrition: null, gaps: ['Servings and timing need source review'] }],
  };
}

test('retains unknown quantities/timing/nutrition without turning them into zero', () => {
  const bank = fixture();
  const before = structuredClone(bank);
  const result = validateResearchBank(bank);
  assert.deepEqual(bank, before);
  assert.equal(result.recipeCount, 1);
  assert.equal(result.unknownAmounts, 1);
  assert.equal(result.unknownStepDurations, 1);
  assert.equal(result.unknownServings, 1);
  assert.equal(result.runtimeReadyCount, 0);
  assert.equal(result.unverifiedLicenseSources, 1);
});

test('uses explicit licence review status rather than trusting public-domain words', () => {
  const bank = fixture();
  bank.sources[0].license = 'Archive asserts public domain';
  bank.sources[0].licenseStatus = 'unverified-primary-source';
  assert.equal(validateResearchBank(bank).unverifiedLicenseSources, 1);
  bank.sources[0].licenseStatus = 'verified-license';
  assert.throws(() => validateResearchBank(bank), /license evidence/);
  bank.sources[0].licenseEvidenceUrl = 'https://example.org/license';
  assert.equal(validateResearchBank(bank).unverifiedLicenseSources, 0);
});

test('rejects unreviewed nutrient/food links and a claim of runtime readiness', () => {
  for (const change of [
    b => b.recipes[0].ingredients[0].foodBinding = {foodId:'usda:123'},
    b => b.recipes[0].nutrition = {protein:42},
    b => b.recipes[0].reviewStatus = 'approved',
  ]) {
    const bank = fixture(); change(bank);
    assert.throws(() => validateResearchBank(bank));
  }
});

test('requires source identity and real retrieval timestamp', () => {
  for (const change of [
    b => b.recipes[0].sourceId = 'absent',
    b => b.sources[0].retrievedAt = 'yesterday',
    b => b.sources[0].retrievedAt = '2026-02-30T00:00:00Z',
    b => b.sources[0].license = '',
    b => b.recipes[0].sourceUrl = 'file:///secret',
  ]) {
    const bank = fixture(); change(bank);
    assert.throws(() => validateResearchBank(bank));
  }
});

test('rejects ambiguous IDs and shipping catalogue collisions', () => {
  const bank = fixture(); bank.recipes.push(structuredClone(bank.recipes[0]));
  assert.throws(() => validateResearchBank(bank), /Duplicate/);
  assert.throws(() => validateResearchBank(fixture(), {shippingIds: new Set(['research:one'])}), /catalogue/);
  const duplicate = fixture();
  duplicate.recipes[0].ingredients.push(structuredClone(duplicate.recipes[0].ingredients[0]));
  assert.throws(() => validateResearchBank(duplicate), /Duplicate/);
});

test('rejects negative/zero quantities and invented zero servings; accepts explicit zero timer', () => {
  for (const change of [
    b => b.recipes[0].servings = 0,
    b => b.recipes[0].servings = 1.5,
    b => b.recipes[0].ingredients[0].amount = -1,
    b => b.recipes[0].ingredients[0].amount = 0,
    b => {b.recipes[0].ingredients[0].amount = 1; b.recipes[0].ingredients[0].unit = null;},
    b => b.recipes[0].steps[0].durationMinutes = -5,
  ]) {
    const bank = fixture(); change(bank);
    assert.throws(() => validateResearchBank(bank));
  }
  const bank = fixture(); bank.recipes[0].steps[0].durationMinutes = 0;
  assert.equal(validateResearchBank(bank).unknownStepDurations, 0);
});

test('requires ordered integer steps and complete explicit null fields', () => {
  for (const change of [
    b => b.recipes[0].steps[0].n = 1.5,
    b => b.recipes[0].steps[0].n = 2,
    b => delete b.recipes[0].steps[0].durationMinutes,
    b => delete b.recipes[0].ingredients[0].foodBinding,
    b => delete b.recipes[0].nutrition,
    b => b.recipes[0].gaps = 'not an array',
  ]) {
    const bank = fixture(); change(bank);
    assert.throws(() => validateResearchBank(bank));
  }
});

test('requires a hash to identify archived source bytes, never infers it from candidate content', () => {
  const bank = fixture();
  bank.sources[0].archivePath = 'research/recipes/source-a.html';
  bank.sources[0].sha256 = null;
  assert.throws(() => validateResearchBank(bank), /hash/);
  bank.sources[0].sha256 = 'a'.repeat(64);
  assert.equal(validateResearchBank(bank).sourceCount, 1);
});

test('content fingerprints survive key order but change when an ingredient or source identity changes', () => {
  const recipe = fixture().recipes[0];
  const reordered = Object.fromEntries(Object.entries(recipe).reverse());
  assert.equal(candidateFingerprint(recipe), candidateFingerprint(reordered));
  const changed = structuredClone(recipe); changed.ingredients[0].sourceText += ' changed';
  assert.notEqual(candidateFingerprint(recipe), candidateFingerprint(changed));
  const sourceChanged = structuredClone(recipe); sourceChanged.sourceRecipeId = 'two';
  assert.notEqual(candidateFingerprint(recipe), candidateFingerprint(sourceChanged));
});

test('keeps research record version separate from an unknown source revision', () => {
  const bank = fixture();
  assert.equal(validateResearchBank(bank).recipeCount, 1);
  for (const change of [
    b => b.recipes[0].recordVersion = 0,
    b => b.recipes[0].recordVersion = 1.5,
    b => delete b.recipes[0].recordVersion,
    b => delete b.recipes[0].sourceRevision,
    b => b.recipes[0].sourceRevision = '',
  ]) {
    const changed = fixture(); change(changed);
    assert.throws(() => validateResearchBank(changed));
  }
});
