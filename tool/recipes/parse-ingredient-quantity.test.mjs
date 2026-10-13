import test from 'node:test';
import assert from 'node:assert/strict';
import { parseIngredientQuantity } from './parse-ingredient-quantity.mjs';

test('parses explicit unit names and aliases without changing source text', () => {
  const cases = [
    ['250 grams sifted flour', 250, 'g', 'sifted flour'],
    ['1.5 kg potatoes', 1.5, 'kg', 'potatoes'],
    ['300 millilitres water', 300, 'ml', 'water'],
    ['2 litres stock', 2, 'l', 'stock'],
    ['1 cup chopped herbs', 1, 'cup', 'chopped herbs'],
    ['2 tbsp olive oil', 2, 'tbsp', 'olive oil'],
    ['3 teaspoons sugar', 3, 'tsp', 'sugar'],
  ];
  for (const [sourceText, amount, unit, remainingText] of cases) {
    const result = parseIngredientQuantity(sourceText);
    assert.equal(result.status, 'parsed-source-candidate', sourceText);
    assert.equal(result.amount, amount, sourceText);
    assert.equal(result.unit, unit, sourceText);
    assert.equal(result.remainingText, remainingText, sourceText);
    assert.equal(result.sourceText, sourceText);
    assert.equal(result.reviewStatus, 'unreviewed-source-transcription');
  }
});

test('parses simple, mixed, and common Unicode fractions exactly as numeric candidates', () => {
  const cases = [
    ['1/2 cup rice', 0.5],
    ['1 1/2 cups rice', 1.5],
    ['1 ½ cups rice', 1.5],
    ['2½ cups rice', 2.5],
    ['¾ tsp salt', 0.75],
    ['⅝ kg beans', 0.625],
  ];
  for (const [sourceText, amount] of cases) {
    const result = parseIngredientQuantity(sourceText);
    assert.equal(result.status, 'parsed-source-candidate', sourceText);
    assert.equal(result.amount, amount, sourceText);
  }
});

test('marks cup-system ambiguity explicitly and makes no conversion', () => {
  const result = parseIngredientQuantity('2 cups water');
  assert.equal(result.status, 'parsed-source-candidate');
  assert.equal(result.amount, 2);
  assert.equal(result.unit, 'cup');
  assert.equal(result.reason, 'cup-volume-system-unspecified');
  assert.equal(result.ml, undefined);
  assert.equal(result.g, undefined);
});

test('leaves ranges, approximations, nonpositive values, and malformed fractions unresolved', () => {
  const cases = [
    '1-2 cups flour', '1–2 cups flour', '1 to 2 cups flour',
    'about 2 cups flour', '~2 cups flour', 'approximately 2 cups flour',
    '0 cups flour', '-1 cup flour', '1/0 cup flour', '1,5 cups flour',
  ];
  for (const sourceText of cases) {
    const result = parseIngredientQuantity(sourceText);
    assert.equal(result.status, 'unresolved', sourceText);
    assert.equal(result.amount, null, sourceText);
    assert.equal(result.unit, null, sourceText);
    assert.equal(result.sourceText, sourceText);
  }
});

test('does not interpret counts, unknown units, or package descriptions as measured quantities', () => {
  const cases = ['2 eggs', '1 large onion', '1 can (400g) tomatoes', '1 (400g) can tomatoes', '1 pinch salt', '1 c rice'];
  for (const sourceText of cases) {
    const result = parseIngredientQuantity(sourceText);
    assert.equal(result.status, 'unresolved', sourceText);
    assert.equal(result.amount, null, sourceText);
    assert.equal(result.unit, null, sourceText);
  }
});

test('does not mutate input or claim canonical ingredient identity', () => {
  const sourceText = '1 cup flour';
  const before = sourceText;
  const result = parseIngredientQuantity(sourceText);
  assert.equal(sourceText, before);
  assert.equal(result.sourceText, before);
  assert.equal(result.foodBinding, null);
  assert.equal(result.canonicalAmount, null);
  assert.equal(result.canonicalUnit, null);
});

test('spoon volume systems also remain unspecified', () => {
  for(const unit of ['tsp','tbsp']) {
    const result=parseIngredientQuantity(`2 ${unit} sugar`);
    assert.equal(result.reason,'spoon-volume-system-unspecified');
    assert.equal(result.canonicalAmount,null);
  }
});
