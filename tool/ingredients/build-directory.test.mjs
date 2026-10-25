import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import test from 'node:test';

import {
  buildDirectory,
  matchName,
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
