import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import test from 'node:test';

import {
  buildDirectory,
  matchName,
  stockUnitValues,
  validateVocabulary,
  vocabularyFile,
} from './build-directory.mjs';

const vocabularyText = await readFile(new URL(`../../${vocabularyFile}`, import.meta.url), 'utf8');
const vocabulary = JSON.parse(vocabularyText);
const keys = validateVocabulary(vocabulary);
const categories = new Map(vocabulary.map((e) => [e.id, e.category]));
const match = (name) => matchName(name, keys, categories);

test('stated form decides fresh versus ground coriander', () => {
  assert.equal(match('كزبرة طازجة مفرومة'), 'cilantro');
  assert.equal(match('حزمة كزبرة صغيرة'), 'cilantro');
  assert.equal(match('كزبرة مطحونة'), 'coriander');
  assert.equal(match('كزبرة'), null);
});

test('alternatives collapse only when every option is the same product', () => {
  assert.equal(match('بيضة أو بيضتان'), 'eggs');
  assert.equal(match('جزرة أو جزرتان'), 'carrot');
  assert.equal(match('زبدة أو مارغرين'), null);
  assert.equal(match('لحم بقري أو دجاج أو روبيان'), null);
  assert.equal(match('ثوم مفروم أو مسحوق ثوم'), null);
});

test('preparation words never change the product, cooked forms stay apart', () => {
  assert.equal(match('فلفل رومي أحمر قطع نصف بوصة'), 'bell-pepper');
  assert.equal(match('ذرة مجمدة مذابة'), 'corn');
  assert.equal(match('أرز مطهو'), null);
  assert.equal(match('ملح متبل'), null);
  assert.equal(match('مكعبا مرق خضار'), null);
});

test('regional catalog alias is blocked for the cuisine where it differs', () => {
  const lines = [
    {id: 'raw-1', name: 'بطاطا مكعبات', recipe: 'a', cuisine: 'إسباني'},
    {id: 'raw-2', name: 'بطاطا', recipe: 'b', cuisine: 'مصري'},
    {id: 'raw-3', name: 'بطاطا حلوة', recipe: 'c', cuisine: 'مصري'},
  ];
  const {directory} = buildDirectory(vocabularyText, lines);
  assert.equal(directory.idMap['raw-1'], 'potato');
  assert.equal(directory.idMap['raw-2'], undefined);
  assert.equal(directory.idMap['raw-3'], 'sweet-potato');
});

test('catalog-only aliases are excluded from search aliases', () => {
  const potato = vocabulary.find((e) => e.id === 'potato');
  assert.ok(potato.matchAliases.includes('بطاطا'));
  assert.ok(!potato.aliases.includes('بطاطا'));
});

const byId = (id) => vocabulary.find((e) => e.id === id);
const entry = (extra) => ({
  id: 'x',
  name: 'اكس',
  aliases: [],
  zone: 'pantry',
  category: 'أخرى',
  defaultUnit: 'g',
  stockUnits: ['g'],
  ...extra,
});
const rejects = (extra, pattern) =>
  assert.throws(() => validateVocabulary([entry(extra)]), pattern);

test('stock units are validated', () => {
  assert.doesNotThrow(() => validateVocabulary([entry({})]));
  rejects({stockUnits: undefined}, /stockUnits/);
  rejects({stockUnits: []}, /stockUnits/);
  rejects({stockUnits: ['g', 'cup']}, /bad stock unit cup/);
  rejects({stockUnits: ['g', 'g']}, /duplicate stock unit/);
  rejects({defaultUnit: 'kg'}, /defaultUnit must equal/);
  rejects({defaultUnit: 'count', stockUnits: ['count']}, /count needs pieceName/);
  rejects({defaultUnit: 'count', stockUnits: ['count'], pieceName: 'حبة'}, /count needs piecePlural/);
  rejects({pieceName: 'حبة'}, /pieceName without count/);
  rejects({piecePlural: 'حبات'}, /piecePlural without count/);
  assert.doesNotThrow(() =>
    validateVocabulary([
      entry({defaultUnit: 'count', stockUnits: ['count'], pieceName: 'حبة', piecePlural: 'حبات'}),
    ]),
  );
  assert.ok(stockUnitValues.includes('ربطة') && !stockUnitValues.includes('cup'));
});

test('every ingredient has the units a home kitchen keeps it in', () => {
  assert.deepEqual(byId('arugula').stockUnits.slice(0, 1), ['ربطة']);
  const chicken = byId('chicken');
  assert.ok(chicken.stockUnits.includes('count') && chicken.stockUnits.includes('kg'));
  assert.equal(chicken.pieceName, 'فرخة');
  assert.equal(chicken.piecePlural, 'فراخ');
  assert.deepEqual(byId('chicken-breast').stockUnits, ['kg', 'g']);
  assert.equal(byId('chicken-breast').pieceName, undefined);
  assert.equal(byId('eggs').stockUnits[0], 'count');
  assert.equal(byId('eggs').pieceName, 'بيضة');
  const onion = byId('onion');
  assert.ok(onion.stockUnits.includes('count') && onion.stockUnits.includes('kg'));
  assert.equal(onion.pieceName, 'بصلة');
  for (const e of vocabulary) assert.equal(e.defaultUnit, e.stockUnits[0], e.id);
});
