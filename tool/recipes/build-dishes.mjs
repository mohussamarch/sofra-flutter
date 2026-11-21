// Builds recipes/data/dishes.json: one dish, several ways of making it
// (different countries or methods). The groups below are reviewed by hand:
// a dish joins only recipes that are the same dish, never just a shared word
// ("كاري" or "كفتة" cover different dishes and are not grouped).
//
// Usage: node tool/recipes/build-dishes.mjs [--check]
import {readFileSync, writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';

const root = fileURLToPath(new URL('../../', import.meta.url));
const indexFile = `${root}recipes/data/index.json`;
const outFile = `${root}recipes/data/dishes.json`;

/** Dish id, display name, and the exact recipe names that are ways of it. */
export const dishes = [
  ['shakshuka', 'شكشوكة', ['شكشوكة بالفلفل الحلو', 'شكشوكة حجازية']],
  ['foul-medammes', 'فول مدمس', ['فول مدمس', 'فول مدمس لبناني سريع', 'فول بالخلطة السعودية']],
  ['mandi', 'مندي', ['مندي لحم', 'مندي دجاج يمني', 'مندي الدجاج بالفرن']],
  ['maamoul', 'معمول', ['معمول تمر', 'معمول سعودي', 'معمول لبناني بالعسل والجوز']],
  ['lentil-soup', 'شوربة العدس', ['شوربة عدس مصري', 'حساء العدس اللبناني', 'حساء العدس الأحمر التركي', 'حساء العدس الإسباني', 'حساء العدس الأحمر المتبل على الطريقة الهندية']],
  ['fatteh', 'فتة', ['فتة', 'فتة الدجاج بالزبادي والحمص', 'فتة لحم بدون صلصة', 'فتة حمص', 'فتة باذنجان']],
  ['kabsa', 'كبسة', ['كبسة دجاج', 'كبسة الجمبري']],
  ['sayadieh', 'صيادية السمك', ['صيادية سمك', 'صيادية السمك']],
  ['feteer-meshaltet', 'فطير مشلتت', ['فطير مشلتت باللوز والصنوبر', 'فطير مشلتت بالسمن البلدي']],
  ['musakhan', 'مسخن', ['مسخن دجاج على الطابون', 'مسخن دجاج (لفائف)']],
  ['liver', 'كبدة', ['كبدة إسكندراني', 'كبدة بالردة', 'كبدة حجازي']],
  ['biryani', 'برياني', ['برياني لحم ضأن', 'برياني لحم ضأن بنجابي', 'برياني دجاج كشميري', 'برياني الروبيان بالأرز الهندي المتبّل']],
  ['stuffed-cabbage', 'ملفوف محشي', ['ملفوف محشي بالليمون والنعناع', 'ملفوف محشي هنغاري']],
  ['hssoua-belboula', 'حسوة بالبلبولة', ['حسوة بالبلبولة بالطماطم', 'حسوة بالبلبولة بالحليب']],
  ['tzatziki', 'تزاتزيكي', ['تزاتزيكي', 'تزاتزيكي يوناني قليل الدسم']],
  ['paella', 'باييا', ['باييا بلنسية', 'باييّا إسبانية نباتية']],
  ['baklava', 'بقلاوة', ['بقلاوة يونانية', 'بقلاوة يونانية خفيفة بالعسل واللوز']],
  ['tikka-masala', 'دجاج تيكا ماسالا', ['دجاج تيكا ماسالا', 'دجاج تيكا ماسالا هندي']],
  ['fettuccine-alfredo', 'فيتوتشيني ألفريدو', ['فيتوتشيني ألفريدو', 'فيتوتشيني ألفريدو بالروبيان']],
  ['gazpacho', 'غازباتشو', ['حساء غازباتشو إسباني', 'حساء غازباتشو إسباني نيئ مع خبز بالجبن النباتي']],
  ['soda-bread', 'خبز الصودا', ['خبز الصودا الأيرلندي المنزلي', 'خبز الصودا الأيرلندي بالزبيب']],
  ['ceviche', 'سيفيتشي', ['سيفيتشي بالسمك والليمون الأخضر', 'سيفيتشي السمك البيروفي الشمالي']],
  ['jerk-chicken', 'دجاج جيرك', ['دجاج جامايكي جيرك مشوي', 'دجاج جامايكي جيرك مع صلصة البابايا']],
  ['stroganoff', 'ستروغانوف', ['ستروغانوف لحم البقر', 'ستروغانوف برازيلي', 'ستروغانوف الفطر']],
  ['pilaf', 'بيلاف', ['بيلاف تركي سهل بالطماطم', 'بيلاف يوناني بالأرز والأعشاب', 'بيلاف بالأرز واللحم']],
];

export function build(index) {
  const active = index.recipes.filter((r) => r.catalogStatus === 'active');
  const byName = new Map();
  for (const r of active) byName.set(r.name.trim(), [...(byName.get(r.name.trim()) ?? []), r]);
  const seen = new Set();
  const out = [];
  for (const [id, name, names] of dishes) {
    const ways = [];
    for (const n of names) {
      const rows = byName.get(n);
      if (!rows) throw new Error(`${id}: no active recipe named "${n}"`);
      for (const r of rows) {
        if (seen.has(r.id)) throw new Error(`${id}: ${r.id} is already in another dish`);
        seen.add(r.id);
        ways.push(r.id);
      }
    }
    if (ways.length < 2) throw new Error(`${id}: a dish needs at least 2 ways`);
    out.push({id, name, recipes: ways});
  }
  return {version: 1, dishes: out};
}

const self = fileURLToPath(import.meta.url);
if (process.argv[1] && fileURLToPath(new URL(`file:///${process.argv[1].replace(/\\/g, '/')}`)) === self) {
  const data = build(JSON.parse(readFileSync(indexFile, 'utf8')));
  const text = `${JSON.stringify(data, null, 2)}\n`;
  if (process.argv.includes('--check')) {
    // A Windows checkout with core.autocrlf has CRLF on disk; compare content.
    if (readFileSync(outFile, 'utf8').replace(/\r\n/g, '\n') !== text) {
      console.error('dishes.json is out of date; run without --check');
      process.exit(1);
    }
  } else {
    writeFileSync(outFile, text);
  }
  console.log(`${data.dishes.length} dishes, ${data.dishes.reduce((n, d) => n + d.recipes.length, 0)} ways`);
}
