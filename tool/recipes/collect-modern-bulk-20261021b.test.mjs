import test from 'node:test';
import assert from 'node:assert/strict';
import { extract, rejectReason, rightsConflictReason, sectionCoverage } from './collect-modern-bulk-20261021b.mjs';

test('keeps a plain first line as the title and extracts the first ingredient and preparation sections', () => {
  const source = `Weeknight Soup\nIngredients\n- 1 cup beans\n- 2 cups water\nPreparation\nMix the beans and water, then simmer.`;
  const parsed = extract(source);
  assert.equal(parsed.title, 'Weeknight Soup');
  assert.deepEqual(parsed.ingredients, ['1 cup beans', '2 cups water']);
  assert.deepEqual(parsed.method, ['Mix the beans and water, then simmer.']);
  assert.deepEqual(sectionCoverage(source, parsed), {
    ingredientsExact: true, methodExact: true, sourceIngredientLines: 2, sourceMethodLines: 1,
  });
});

test('Tools, Comments, and About are terminal and cannot reopen either section', () => {
  const source = `Fresh Fruit Tart\nIngredients\n- 1 cup flour\n- 1 egg\nPreparation\nMix and bake until set.\nTools\n{{ad html}}\nComments\nIngredients\n- stolen section\nPreparation\nClick this link for more.`;
  const parsed = extract(source);
  assert.deepEqual(parsed.ingredients, ['1 cup flour', '1 egg']);
  assert.deepEqual(parsed.method, ['Mix and bake until set.']);
  assert.equal(sectionCoverage(source, parsed).ingredientsExact, true);
  assert.equal(sectionCoverage(source, parsed).methodExact, true);
});

test('a repeated Preparation heading keeps collecting until an actual terminal label', () => {
  const source = `Soup\nIngredients\n- 1 carrot\n- 2 cups stock\nPreparation\nMix and simmer.\nPreparation\nClick this link.`;
  const parsed = extract(source);
  assert.deepEqual(parsed.method, ['Mix and simmer.', 'Click this link.']);
  assert.equal(rejectReason('Soup', parsed.method), 'link-ad-or-placeholder-method');
  assert.equal(sectionCoverage(source, parsed).methodExact, true);
});

test('repeated section labels preserve same-section content and terminal headings are exact labels', () => {
  const source = `Salami Rolls\nIngredients\n- 1 cup ricotta\n- 12 slices salami\n- About 10 olives\nIngredients:\n- 4 tablespoons cheese\nPreparation\nMix and spread.\nPreparation\nRoll and serve.\nAbout\nThis is background text.`;
  const parsed = extract(source);
  assert.deepEqual(parsed.ingredients, ['1 cup ricotta', '12 slices salami', 'About 10 olives', '4 tablespoons cheese']);
  assert.deepEqual(parsed.method, ['Mix and spread.', 'Roll and serve.']);
  assert.equal(sectionCoverage(source, parsed).ingredientsExact, true);
  assert.equal(sectionCoverage(source, parsed).methodExact, true);
});

test('preserves real duplicate ingredient subheadings and repeated method headings in audit cases', () => {
  const salad = `Adobo Nation Salad Sensation\nIngredients\n3 pounds pork/chicken\nFor the salad:\nIngredients:\nBoiled eggs\nTomatoes\nPreparation\nCombine and simmer.`;
  const p = extract(salad);
  assert.deepEqual(p.ingredients, ['3 pounds pork/chicken', 'For the salad:', 'Boiled eggs', 'Tomatoes']);
  assert.deepEqual(p.method, ['Combine and simmer.']);
  const curry = `Thai Green Curry\nIngredients\n1 chicken\nThe Paste\nIngredients:\n15 chilies\n3 shallots\nPreparation\nCook the chicken.\nPreparation for the Paste:\nPound the spices.`;
  const c = extract(curry);
  assert.ok(c.ingredients.includes('15 chilies'));
  assert.ok(c.method.includes('Pound the spices.'));
  assert.equal(c.complexSectionOrder, false);
});

test('a leading BOM does not hide the first Ingredients heading', () => {
  const source = `\uFEFFSoup\n\uFEFFIngredients\n- 1 apple\n- 1 cup water\n\uFEFFPreparation\nMix and simmer.`;
  const parsed = extract(source);
  assert.equal(parsed.title, 'Soup');
  assert.deepEqual(parsed.ingredients, ['1 apple', '1 cup water']);
  assert.deepEqual(parsed.method, ['Mix and simmer.']);
  assert.equal(sectionCoverage(source, parsed).ingredientsExact, true);
});

test('explicit Paula Deen/Food Network attribution is excluded but incidental mention is not', () => {
  assert.equal(rightsConflictReason("Paula Deen's recipe from the Food Network."), 'named-third-party-recipe-source');
  assert.equal(rightsConflictReason('This uses a pan I saw on the Food Network.'), null);
  assert.equal(rightsConflictReason('Recipe adapted from the cookbook.'), 'explicit-third-party-source-attribution');
  assert.equal(rightsConflictReason('Copyright 2015. All rights reserved.'), 'explicit-copyright-or-permission-reservation');
  assert.equal(rightsConflictReason('Braised Short Ribs Recipe By Tom Colicchio'), 'named-person-recipe-attribution');
});

test('a short real preparation action is not rejected for length alone', () => {
  assert.equal(rejectReason('Mint Tea', ['Mix and serve.']), null);
});
