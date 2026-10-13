export const QUANTITY_PARSER_VERSION = 'source-prefix-v2';

const FRACTIONS = Object.freeze({
  '½': [1, 2], '⅓': [1, 3], '⅔': [2, 3],
  '¼': [1, 4], '¾': [3, 4],
  '⅕': [1, 5], '⅖': [2, 5], '⅗': [3, 5], '⅘': [4, 5],
  '⅙': [1, 6], '⅚': [5, 6],
  '⅛': [1, 8], '⅜': [3, 8], '⅝': [5, 8], '⅞': [7, 8],
});

const UNIT_ALIASES = new Map();
for (const alias of ['g', 'gram', 'grams', 'gramme', 'grammes']) UNIT_ALIASES.set(alias, 'g');
for (const alias of ['kg', 'kilogram', 'kilograms', 'kilogramme', 'kilogrammes']) UNIT_ALIASES.set(alias, 'kg');
for (const alias of ['ml', 'milliliter', 'milliliters', 'millilitre', 'millilitres']) UNIT_ALIASES.set(alias, 'ml');
for (const alias of ['l', 'liter', 'liters', 'litre', 'litres']) UNIT_ALIASES.set(alias, 'l');
for (const alias of ['cup', 'cups']) UNIT_ALIASES.set(alias, 'cup');
for (const alias of ['tbsp', 'tbs', 'tablespoon', 'tablespoons']) UNIT_ALIASES.set(alias, 'tbsp');
for (const alias of ['tsp', 'teaspoon', 'teaspoons']) UNIT_ALIASES.set(alias, 'tsp');

function unresolved(sourceText, reason, quantityText = null, unitText = null, remainingText = null) {
  return {
    sourceText,
    parserVersion: QUANTITY_PARSER_VERSION,
    status: 'unresolved',
    amount: null,
    unit: null,
    quantityText,
    unitText,
    remainingText,
    reason,
    reviewStatus: 'unreviewed-source-transcription',
  };
}

function readLeadingQuantity(sourceText) {
  const fractionChars = Object.keys(FRACTIONS).join('');
  const pattern = new RegExp(
    `^\\s*([+-]?)(?:(\\d+)\\s+(\\d+)\\s*\\/\\s*(\\d+)|(\\d+)\\s*\\/\\s*(\\d+)|(\\d+)\\s+([${fractionChars}])|(\\d+)?([${fractionChars}])|((?:\\d+(?:\\.\\d+)?|\\.\\d+)))`,
  );
  const match = sourceText.match(pattern);
  if (!match) return null;

  const sign = match[1] === '-' ? -1 : 1;
  let value;
  if (match[2] !== undefined) {
    const denominator = Number(match[4]);
    value = Number(match[2]) + Number(match[3]) / denominator;
  } else if (match[5] !== undefined) {
    value = Number(match[5]) / Number(match[6]);
  } else if (match[8] !== undefined) {
    const [numerator, denominator] = FRACTIONS[match[8]];
    value = Number(match[7]) + numerator / denominator;
  } else if (match[10] !== undefined) {
    const [numerator, denominator] = FRACTIONS[match[10]];
    value = Number(match[9] ?? 0) + numerator / denominator;
  } else {
    value = Number(match[11]);
  }
  return { match, value: sign * value };
}

export function parseIngredientQuantity(sourceText) {
  if (typeof sourceText !== 'string') throw new TypeError('sourceText must be a string.');
  const trimmed = sourceText.trimStart();
  if (!trimmed) return unresolved(sourceText, 'empty-source-text');
  if (/^(?:about|approx(?:imately)?|around|roughly)\b|^[~≈]/i.test(trimmed)) {
    return unresolved(sourceText, 'approximate-quantity');
  }
  if (/^\d+\s*(?:-|–|—|to)\s*\d+(?:\s|$)/i.test(trimmed)) {
    return unresolved(sourceText, 'quantity-range');
  }
  if (/^\d+,\d+/.test(trimmed)) return unresolved(sourceText, 'ambiguous-decimal-comma');

  const parsed = readLeadingQuantity(sourceText);
  if (!parsed) return unresolved(sourceText, 'no-unambiguous-leading-quantity');
  const { match, value } = parsed;
  const quantityText = match[0].trim();
  const rawRemaining = sourceText.slice(match[0].length);
  const remainingAfterSpace = rawRemaining.trimStart();
  const unitMatch = remainingAfterSpace.match(/^([A-Za-z]+\.?)(?=\s|$|[,(])/);
  const unitText = unitMatch?.[1] ?? null;
  const remainingText = unitMatch ? remainingAfterSpace.slice(unitMatch[0].length).trimStart() : remainingAfterSpace || null;

  if (!Number.isFinite(value) || value <= 0) {
    return unresolved(sourceText, 'quantity-must-be-positive-and-finite', quantityText, unitText, remainingText);
  }
  if (!rawRemaining) {
    return unresolved(sourceText, 'explicit-unit-required', quantityText, unitText, remainingText);
  }
  if (!unitText) return unresolved(sourceText, 'explicit-unit-required', quantityText, null, remainingText);
  const normalizedUnit = UNIT_ALIASES.get(unitText.toLowerCase().replace(/\.$/, ''));
  if (!normalizedUnit) return unresolved(sourceText, 'unknown-or-count-unit', quantityText, unitText, remainingText);

  return {
    sourceText,
    parserVersion: QUANTITY_PARSER_VERSION,
    status: 'parsed-source-candidate',
    amount: value,
    unit: normalizedUnit,
    quantityText,
    unitText,
    remainingText,
    reason: normalizedUnit === 'cup' ? 'cup-volume-system-unspecified' : ['tsp','tbsp'].includes(normalizedUnit) ? 'spoon-volume-system-unspecified' : null,
    reviewStatus: 'unreviewed-source-transcription',
    canonicalAmount: null,
    canonicalUnit: null,
    foodBinding: null,
  };
}
