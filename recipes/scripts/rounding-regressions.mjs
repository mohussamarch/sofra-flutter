import assert from 'node:assert/strict';
import { roundAmountForUnit, scaleIngredient } from '../src/scale.ts';

// Explicit kitchen quantities: these must not inherit gram rounding rules.
for (const [amount, unit, expected] of [
  [0.25, 'كوب', 0.25], [0.125, 'كوب', 0.125], [8, 'كوب', 8],
  [11.25, 'كوب', 11.25], [1.25, 'لتر', 1.25], [0.375, 'كيلو', 0.375],
]) assert.equal(roundAmountForUnit(amount, unit), expected, `${amount} ${unit}`);

const halved = scaleIngredient({id:'milk',name:'لبن',amount:0.5,unit:'كوب'}, 0.5);
assert.equal(halved.amount,0.25);
assert.equal(halved.display,'¼ كوب');
const largeFamily = scaleIngredient({id:'rice',name:'رز',amount:2,unit:'كوب'},4);
assert.equal(largeFamily.amount,8);
assert.equal(largeFamily.display,'8 كوب');
const litres = scaleIngredient({id:'water',name:'ماء',amount:2.5,unit:'لتر'},0.5);
assert.equal(litres.amount,1.25);
assert.equal(litres.display,'1¼ لتر');
console.log('Quantity regressions passed: fractional cups/litres/kilograms and household scaling.');
