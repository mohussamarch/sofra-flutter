// Builds recipes/data/dishes.json: one dish, several ways of making it
// (different countries or methods). The groups below are reviewed by hand:
// a dish joins only recipes that are the same dish, never just a shared word
// ("كاري" or "كفتة" cover different dishes and are not grouped).
//
// The online library (recipes/library-only, never bundled) adds creators'
// recipes: their ways are listed by recipe id below, either joining a dish
// above or forming a new one, and written to recipes/library-only/dishes.json
// (the catalog's dishes plus these), which the publisher serves.
//
// Usage: node tool/recipes/build-dishes.mjs [--check]
import {existsSync, readFileSync, writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';

const root = fileURLToPath(new URL('../../', import.meta.url));
const indexFile = `${root}recipes/data/index.json`;
const outFile = `${root}recipes/data/dishes.json`;
const libraryFile = `${root}recipes/library-only/youtube.json`;
const libraryOut = `${root}recipes/library-only/dishes.json`;

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

/** Library recipe ids that join a catalog dish above. */
export const libraryWays = {
  'liver': ['eg-kebda-eskandarani-nadia'],
  'foul-medammes': ['eg-fatma-ful-medames-light-colour', 'w-hala-foul-medames-pot', 'w-hala-ful-medames', 'eg-omar-foul-medames'],
  'mandi': ['sa-yt-mandi-dajaj-jkld'],
  'kabsa': ['yt-heba-quick-saudi-kabsa', 'ar-omar-lamb-kabsa-one-pot', 'sa-kabsa-chicken-daqous-omar'],
  'fatteh': ['eg-fetta-lahma-nadia', 'w-omar-egyptian-fatta', 'yt-hala-lentil-fatta', 'w-omar-lentil-fatteh-gxzwjm00ncu', 'w-omar-lentil-fatteh-tmxu4akwmr0'],
};

/** New dishes of the library: id, display name, recipe ids (catalog or library). */
export const libraryDishes = [
  ['koshari', 'كشري', ['eg-koshari', 'eg-koshari-nadia', 'eg-omar-egyptian-koshari']],
  ['kahk', 'كحك العيد', ['eg-fatma-kahk-eid-ghee-stuffed', 'w-sally-soft-kahk']],
  ['bechamel-pasta', 'مكرونة بالبشاميل', ['eg-bechamel-pasta', 'eg-makarona-bashamel-shofan-nadia', 'w-hala-alexandrian-bechamel-pasta']],
  ['kousa-bechamel', 'كوسة بالبشاميل', ['eg-kousa-bel-bechamel', 'eg-omar-zucchini-bechamel-yt']],
  ['cannelloni', 'كانيلوني بالبشاميل', ['yt-fatma-cannelloni-crepe-bechamel', 'yt-heba-cannelloni-bechamel-tray']],
  ['kunafa-qishta', 'كنافة بالقشطة', ['yt-heba-kunafa-qishta', 'eg-konafa-tasa-nadia', 'eg-konafa-bel-eshta-nadia-cqewqjphy']],
  ['chicken-shawarma', 'شاورما دجاج', ['sh-shawarma-dajaj', 'eg-shawarma-firakh-nadia', 'ar-omar-chicken-shawarma', 'yt-fatma-chicken-shawarma-skewer']],
  ['shish-tawook', 'شيش طاووق', ['sh-shish-tawook', 'eg-shish-tawouk-nadia']],
  ['tiramisu', 'تيراميسو', ['it-tiramisu', 'yt-heba-classic-tiramisu', 'eg-tiramisu-nadia']],
  ['ghorayeba', 'غريبة', ['eg-ghorayeba', 'w-fatma-ghraiba-soft', 'w-hala-ghorayba-samna', 'eg-ghoraybeh-nadia']],
  ['rawani', 'الرواني', ['eg-heba-rawani', 'eg-keika-rawani-nadia', 'w-nadia-revani-cake']],
  ['kebab-halla', 'كباب حلة', ['eg-tagen-lahm-kabab-halla', 'w-cbc-kebab-hala']],
  ['kofta-hatti', 'كفتة الحاتي', ['yt-fatma-hatti-kofta-oven', 'yt-hala-kofta-hatti-grilled', 'yt-hala-hatti-kofta-grilled', 'yt-heba-bulgur-hatti-kofta', 'eg-kofta-hati-nadia', 'eg-omar-kofta-hatti-oven']],
  ['rice-kofta', 'كفتة الأرز بالصلصة', ['w-fatma-rice-kofta-fingers', 'eg-yt-rice-kofta']],
  ['daoud-basha', 'داود باشا', ['lg-daoud-basha', 'w-omar-kofta-daoud-basha-tagine']],
  ['chicken-pane', 'بانيه دجاج', ['w-hala-blender-chicken-pane', 'eg-yt-crispy-chicken-pane']],
];

/** The catalog's dishes plus the library's, over [active] ids (catalog and
 *  library). Every id must be active and in one dish only. */
export function buildWithLibrary(index, libraryRecipes) {
  const core = build(index);
  const active = new Set([
    ...index.recipes.filter((r) => r.catalogStatus === 'active').map((r) => r.id),
    ...libraryRecipes.map((r) => r.id),
  ]);
  const seen = new Set(core.dishes.flatMap((d) => d.recipes));
  const take = (dish, id) => {
    if (!active.has(id)) throw new Error(`${dish}: no active recipe ${id}`);
    if (seen.has(id)) throw new Error(`${dish}: ${id} is already in another dish`);
    seen.add(id);
    return id;
  };
  const dishes = core.dishes.map((d) => ({...d, recipes: [...d.recipes, ...(libraryWays[d.id] ?? []).map((id) => take(d.id, id))]}));
  for (const id of Object.keys(libraryWays)) {
    if (!core.dishes.some((d) => d.id === id)) throw new Error(`no catalog dish ${id}`);
  }
  for (const [id, name, ids] of libraryDishes) {
    if (dishes.some((d) => d.id === id)) throw new Error(`dish ${id} twice`);
    const ways = ids.map((r) => take(id, r));
    if (ways.length < 2) throw new Error(`${id}: a dish needs at least 2 ways`);
    dishes.push({id, name, recipes: ways});
  }
  return {version: 1, dishes};
}

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
  const index = JSON.parse(readFileSync(indexFile, 'utf8'));
  const outputs = [[outFile, build(index)]];
  if (existsSync(libraryFile)) {
    outputs.push([libraryOut, buildWithLibrary(index, JSON.parse(readFileSync(libraryFile, 'utf8')).recipes)]);
  }
  let stale = false;
  for (const [file, data] of outputs) {
    const text = `${JSON.stringify(data, null, 2)}\n`;
    if (process.argv.includes('--check')) {
      // A Windows checkout with core.autocrlf has CRLF on disk; compare content.
      if (!existsSync(file) || readFileSync(file, 'utf8').replace(/\r\n/g, '\n') !== text) {
        console.error(`${file} is out of date; run without --check`);
        stale = true;
      }
    } else {
      writeFileSync(file, text);
    }
    console.log(`${file}: ${data.dishes.length} dishes, ${data.dishes.reduce((n, d) => n + d.recipes.length, 0)} ways`);
  }
  if (stale) process.exit(1);
}
