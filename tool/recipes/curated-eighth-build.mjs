import {readFile, mkdir, writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {loadRecipeReviewSnapshots} from './recipe-review-reader.mjs';
import {snapshotFingerprint} from './review-target.mjs';
import {normalize, cookbook, validateDecision} from './curated-local-build.mjs';
import {auditRecipeImportDraft} from './import-preflight.mjs';
import {makePreflight as priorPreflight} from './curated-third-build.mjs';

const root=fileURLToPath(new URL('../../',import.meta.url));
export const folder='data/recipes/curated-local/eighth-reviewed-20261015';
export const frozen=[
 ['data/recipes/curated-local/first-reviewed-20261014/normalized-recipes.json','2e8b81cba110ea979f6199dd0a7e8e67c9626e3081c98491897b83664d032946'],
 ['data/recipes/curated-local/gap-review-20261014/normalized-recipes.json','9b4e2d203b80dd25c9c1392ef7b35d3dab097e0fc5e67cbee5a43908851aa4e5'],
 ['data/recipes/curated-local/third-reviewed-20261014/normalized-recipes.json','bef4b419623fd9a981d131232d04b5aa52e1d9e2fab50a0f57b5a313fe821d21'],
 ['data/recipes/curated-local/fourth-reviewed-20261014/normalized-recipes.json','a6d83f85b46fc25983145378445d8aac9e61f43618fc12d3ba70c93ac2da29e7'],
 ['data/recipes/curated-local/fifth-reviewed-20261014/normalized-recipes.json','1df899307df2cf630c3fe850dc5ddb997a1f179dd8a1e2ea67bdb7eb77fbf6be'],
 ['data/recipes/curated-local/sixth-reviewed-20261015/normalized-recipes.json','bf8453d0ac1c7f3caaef4b48083a780b9211f02b147ba7bd0309cc9572854a84'],
 ['data/recipes/curated-local/seventh-reviewed-20261015/normalized-recipes.json','b311d73afa69110f18907991d04db5fb1ea4bc823921a49f6e2af72bd6207435']
];
export const sha=v=>createHash('sha256').update(v).digest('hex');
const fmt=v=>JSON.stringify(v,null,2)+'\n';
const need=(v,m)=>{if(!v)throw Error(m);};
const reviewedAt='2026-10-15T00:00:00.000Z';
const changeNotice='Six Arabic adaptations from exact revisions already present in the local Wikibooks archive. Source categories are retained as evidence, not approved national cuisine. Original quantities, alternatives, unknowns, and timing gaps remain explicit. No new books or network requests. CC BY-SA 4.0 attribution and change notice retained; page-specific rights exceptions are not reviewed.';

// Each tuple: [Arabic ingredient, displayed source quantity, numeric quantity, unit, optional, review note].
const rows=[
  {
    "id": 13447,
    "nameAr": "بولغوغي كوري (لحم بقري مشوي بالتتبيلة)",
    "family": "korean-bulgogi-grilled-beef",
    "method": "marinate-grill",
    "cuisine": [
      "korean",
      "كوري",
      "Category:Korean recipes"
    ],
    "time": {
      "declaredTotalMinutes": null,
      "prepMinutes": null,
      "cookMinutes": null,
      "sourceText": "الزمن الإجمالي غير منشور"
    },
    "i": [
      [
        "لحم بقري للشواء مقطع رقيقًا",
        "1 lb (450 g)",
        450,
        "g",
        false,
        "المصدر يذكر 1 رطل ومعادله المنشور 450 جم؛ أُخذت قيمة الجرام من النص دون حساب تحويل."
      ],
      [
        "بصل أخضر مقطع مائلًا",
        "3 green onions",
        3,
        "green-onion",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "فطر أبيض مقطع",
        "4 button mushrooms",
        4,
        "mushroom",
        true,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "بصل مقطع رقيقًا",
        "½ onion",
        0.5,
        "onion",
        true,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "صلصة صويا",
        "¾ cup",
        0.75,
        "cup",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "سكر أبيض حبيبي",
        "¼ cup",
        0.25,
        "cup",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "زيت سمسم",
        "¼ cup (4 tbsp)",
        0.25,
        "cup",
        false,
        "المصدر يذكر ربع كوب (4 ملاعق كبيرة)؛ نظام الحجم غير محدد."
      ],
      [
        "فلفل",
        "4 tsp",
        4,
        "tsp",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "ثوم مفروم",
        "1–2 tbsp",
        null,
        null,
        false,
        "مدى 1–2 ملعقة كبيرة محفوظ؛ لم يُختر مقدار واحد."
      ],
      [
        "ميرين",
        "1 tbsp",
        1,
        "tbsp",
        true,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ]
    ],
    "s": [
      "اخلط كل المكونات في وعاء كبير، واتركها تتبل 30 دقيقة على الأقل؛ يذكر المصدر أن التتبيل طوال الليل يعطي أفضل نكهة وتطرية.",
      "اشوِ اللحم البقري.",
      "قدّم مع الأرز."
    ],
    "notes": [
      "قائمة المصدر تذكر ثلاثة أرباع كوب صويا وربع كوب سكر؛ ملاحظة لاحقة تقول استخدام المقدار نفسه منهما. حُفظت القائمة مع إعلان التعارض دون اختيار تصحيح.",
      "المصدر يذكر خفض الصويا والتبريد عند التحضير قبل يوم، ويقترح المقلاة أو إضافة الكولا بدل السكر أو ثمرة كمثرى كورية مفرومة/مبشورة بدل السكر أو الكولا؛ هذه بدائل غير مختارة وليست طرقًا مراجعة مستقلة.",
      "ست حصص منشورة في قالب المصدر؛ زمن الشواء وحرارته العددية غير منشورين."
    ],
    "blockers": [
      "تعارض نسبة الصويا والسكر، ومدى الثوم، وزمن الشواء مجهول؛ لا اعتماد أو تحجيم تلقائي."
    ],
    "durations": {
      "0": {
        "min": 30,
        "max": null,
        "scope": "minimum-marinade",
        "approximate": false
      }
    },
    "supplementalIngredients": [
      {
        "name": "rice",
        "nameAr": "أرز للتقديم",
        "amount": null,
        "unit": null,
        "optional": false,
        "included": true,
        "sourceText": "Serve with rice.",
        "reason": "مذكور في التقديم فقط دون مقدار."
      }
    ],
    "yield": {
      "amount": 6,
      "min": 6,
      "max": 6,
      "unit": "servings",
      "sourceText": "6"
    }
  },
  {
    "id": 14459,
    "nameAr": "موكيكا برازيلية (يخنة السمك بحليب جوز الهند)",
    "family": "brazilian-moqueca-fish-coconut",
    "method": "marinate-layer-boil",
    "cuisine": [
      "brazilian",
      "برازيلي",
      "Category:Brazilian recipes"
    ],
    "time": {
      "declaredTotalMinutes": null,
      "prepMinutes": null,
      "cookMinutes": null,
      "sourceText": "الزمن الإجمالي غير منشور"
    },
    "i": [
      [
        "سمك أبيض طازج مقطع شرائح بعرض إصبعين",
        "1 kg",
        1,
        "kg",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "عصير ليمونة",
        "1 lemon, juiced",
        1,
        "lemon",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "بصل متوسط مقطع حلقات",
        "2 mid-sized onions",
        2,
        "onion",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "فلفل حلو: واحدة حمراء وواحدة خضراء",
        "2 bell peppers",
        2,
        "pepper",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "ثوم مهروس",
        "1 clove",
        1,
        "clove",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "طماطم ناضجة مفرومة، وتقشيرها اختياري",
        "4 ripe tomatoes",
        4,
        "tomato",
        false,
        "الطماطم مطلوبة؛ الاختيار يخص التقشير وحده ولا يعني استبعاد المكون."
      ],
      [
        "سيقان كزبرة بأوراقها مفرومة",
        "4 cilantro stems with leaves",
        4,
        "stem",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "زيت نخيل دينديه",
        "12 tablespoons",
        12,
        "tbsp",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "حليب جوز الهند",
        "200 ml",
        200,
        "ml",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "ملح",
        "Salt",
        null,
        null,
        false,
        "المقدار غير منشور؛ لم يُستنتج من ملاحظة التتبيل."
      ],
      [
        "فلفل مطحون ناعم",
        "Pepper",
        null,
        null,
        false,
        "المقدار غير منشور."
      ]
    ],
    "s": [
      "انقع السمك في عصير الليمون والفلفل الناعم ساعة على الأقل.",
      "رتّب السمك والبصل والفلفل الحلو والثوم والطماطم والكزبرة في طبقات متعددة داخل قدر.",
      "اسكب زيت دينديه وحليب جوز الهند فوق المكونات، واغلِها 20 دقيقة. من حين إلى آخر، انقل بعض السائل من قاع القدر إلى أعلاه بحذر كي لا يتكسر السمك.",
      "أضف الملح حسب الذوق.",
      "قدّم مع الأرز الأبيض."
    ],
    "notes": [
      "يصف المصدر الطبق بأنه من باهيا ويشدد على زيت دينديه؛ لم تُستبدل هويته بزيت آخر.",
      "خمس حصص معلنة؛ زمن التحضير والإجمالي غير منشورين، ولم تجمع مدة التتبيل والطهي لتخمين الإجمالي."
    ],
    "blockers": [
      "مقادير الملح والفلفل وأرز التقديم مجهولة؛ لا تغذية أو تحجيم أو اعتماد سلامة."
    ],
    "durations": {
      "0": {
        "min": 60,
        "max": null,
        "scope": "minimum-marinade",
        "approximate": false
      },
      "2": {
        "min": 20,
        "max": 20,
        "scope": "boil-stew",
        "approximate": false
      }
    },
    "supplementalIngredients": [
      {
        "name": "white rice",
        "nameAr": "أرز أبيض للتقديم",
        "amount": null,
        "unit": null,
        "optional": false,
        "included": true,
        "sourceText": "Serve with white rice.",
        "reason": "مذكور في التقديم فقط دون مقدار."
      }
    ],
    "yield": {
      "amount": 5,
      "min": 5,
      "max": 5,
      "unit": "servings",
      "sourceText": "5"
    }
  },
  {
    "id": 219286,
    "nameAr": "ساغاناكي يونانية (جبن أبيض مملح بالمقلاة)",
    "family": "greek-saganaki-pan-fried-cheese",
    "method": "optional-flour-pan-fry",
    "cuisine": [
      "greek",
      "يوناني",
      "Category:Greek recipes"
    ],
    "time": {
      "declaredTotalMinutes": 5,
      "prepMinutes": null,
      "cookMinutes": null,
      "sourceText": "5 minutes"
    },
    "i": [
      [
        "شريحة كبيرة من جبن أبيض مملح محفوظ في محلول ملحي مثل فيتا أو سيريني",
        "1 large slice",
        1,
        "slice",
        false,
        "شريحة كبيرة بحسب النص؛ النوع والوزن غير محسومين."
      ],
      [
        "زيت زيتون غير بكر ممتاز",
        "1 tablespoon",
        1,
        "tbsp",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "قطعة ليمون كبيرة",
        "1 large lemon wedge",
        1,
        "wedge",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "دقيق للتغليف",
        "A small amount",
        null,
        null,
        true,
        "كمية صغيرة غير محددة؛ المكون اختياري."
      ],
      [
        "خبز بيتا أو خبز آخر",
        "Pita or other bread",
        null,
        null,
        true,
        "بدائل التقديم اختيارية وبلا مقدار."
      ]
    ],
    "s": [
      "سخّن مقلاة صغيرة على نار متوسطة إلى عالية.",
      "أثناء تسخين المقلاة، قطّع الجبن بالسمك والحجم المطلوبين. القطع السميكة تحتاج وقتًا أطول وقد تحترق؛ والرفيعة قد لا تتحمر جيدًا بحسب المصدر.",
      "يمكن تغليف الشرائح بالدقيق اختياريًا لقشرة أغمق وأكثر قرمشة قليلًا وتقليل تناثر الزيت.",
      "أضف الزيت إلى المقلاة الساخنة وحرّكه. عندما يلمع ويبدو أكثر سيولة أضف الجبن وابتعد عن تناثره الناتج عن ماء المحلول الملحي.",
      "اقلب الجبن بعد دقيقة أو دقيقتين؛ يذكر المصدر أن شريحة بسمك ثلاثة أرباع سنتيمتر تحتاج نحو 1–2 دقيقة لكل جانب.",
      "قدّم فورًا مع الليمون، ومع الخبز اختياريًا."
    ],
    "notes": [
      "حصة واحدة وزمن 5 دقائق منشوران في قالب المصدر. المدة المذكورة لكل وجه مرتبطة بشريحة سمكها ثلاثة أرباع سنتيمتر، وليست زمنًا لجميع الأحجام.",
      "الجبن له بدائل فيتا/سيريني، وملاحظة المصدر تقترح كفالوجرافييرا أو كاسيري أو كفالوتيري؛ لم يُختر نوع نهائي."
    ],
    "blockers": [
      "وزن ونوع الجبن والدقيق والخبز غير محسومة؛ وجود زمن وناتج لا يثبت اكتمال الكميات أو التغذية."
    ],
    "durations": {
      "4": {
        "min": 1,
        "max": 2,
        "scope": "per-side-for-0.75-cm-cheese",
        "approximate": true
      }
    },
    "supplementalIngredients": [],
    "yield": {
      "amount": 1,
      "min": 1,
      "max": 1,
      "unit": "servings",
      "sourceText": "1"
    }
  },
  {
    "id": 294156,
    "nameAr": "ليفسه نرويجية (خبز البطاطس المسطح)",
    "family": "norwegian-lefse-potato-flatbread",
    "method": "mix-roll-griddle",
    "cuisine": [
      "norwegian",
      "نرويجي",
      "Category:Norwegian recipes"
    ],
    "time": {
      "declaredTotalMinutes": null,
      "prepMinutes": null,
      "cookMinutes": 60,
      "sourceText": "Prep: 1–2 hours; Cooking: 1 hour"
    },
    "i": [
      [
        "بطاطس روسيت مسلوقة ومهروسة وما زالت ساخنة",
        "8 cups",
        8,
        "cup",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "زبدة مذابة",
        "½ cup",
        0.5,
        "cup",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "دقيق غير مبيض",
        "3 cups",
        3,
        "cup",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "سكر حبيبي",
        "2 tablespoons",
        2,
        "tbsp",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "ملح",
        "2 teaspoons",
        2,
        "tsp",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "قشدة",
        "1 cup",
        1,
        "cup",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ]
    ],
    "s": [
      "اخلط البطاطس المهروسة بالزبدة المذابة.",
      "إذا حضرتها مسبقًا، برّد الخليط طوال الليل، وأخرج البطاطس قبل استكمال التحضير بساعة.",
      "اخلط السكر والملح والقشدة وخليط البطاطس في وعاء كبير. أضف الدقيق تدريجيًا مع التقليب.",
      "خذ في كل مرة نحو ملعقتين كبيرتين من الخليط أو قطعة بحجم كرة غولف، وافردها دوائر مسطحة على سطح أملس. استخدم الدقيق لمنع الالتصاق بالسطح والنشابة.",
      "ضع الدوائر على صاج، واطهها حتى يتحمر أسفلها. اقلبها وكرر على الجانب الآخر.",
      "أضف إضافات التقديم، وقدّمها ساخنة."
    ],
    "notes": [
      "الناتج المنشور نحو 40 قطعة وليس رقمًا مؤكدًا؛ التحضير 1–2 ساعة والطهي ساعة، دون زمن إجمالي منفرد أو مدة لكل قطعة.",
      "خطوة التبريد طوال الليل مشروطة بالتحضير المسبق. ملاحظات المصدر تذكر زبدة وسكرًا للتقديم وإمكان زيادة القشدة/الدقيق عند الحاجة؛ لم تُضف تلك الزيادات إلى المقادير الأساسية أو يُستنتج وزن."
    ],
    "blockers": [
      "دقيق الفرد وإضافات التقديم بلا مقدار؛ الناتج والتحضير تقريبيان/مدى، ولا تحجيم تلقائي."
    ],
    "durations": {},
    "supplementalIngredients": [
      {
        "name": "flour for dusting",
        "nameAr": "دقيق إضافي للفرد",
        "amount": null,
        "unit": null,
        "optional": false,
        "included": true,
        "sourceText": "Use flour to keep the mix from sticking",
        "reason": "مذكور في الخطوات؛ مقدار الزيادة غير منشور."
      },
      {
        "name": "toppings",
        "nameAr": "إضافات التقديم",
        "amount": null,
        "unit": null,
        "optional": false,
        "included": true,
        "sourceText": "Add toppings",
        "reason": "لا تحدد الخطوة نوعًا أو مقدارًا؛ الاقتراحات في الملاحظات غير مختارة."
      }
    ],
    "yield": {
      "amount": null,
      "min": null,
      "max": null,
      "unit": "pieces",
      "sourceText": "About 40 lefse"
    }
  },
  {
    "id": 234180,
    "nameAr": "كليبون إندونيسية (كرات الأرز بسكر النخيل وجوز الهند)",
    "family": "indonesian-klepon-palm-sugar-rice",
    "method": "fill-boil-coconut-coat",
    "cuisine": [
      "indonesian",
      "إندونيسي",
      "Category:Indonesian recipes"
    ],
    "time": {
      "declaredTotalMinutes": null,
      "prepMinutes": null,
      "cookMinutes": null,
      "sourceText": "الزمن الإجمالي غير منشور"
    },
    "i": [
      [
        "أوراق باندان أو معجون باندان",
        "8–10 pandan leaves or pandan paste",
        null,
        null,
        false,
        "مدى 8–10 أوراق أو معجون؛ كمية المعجون غير محددة ولم يُختر البديل."
      ],
      [
        "دقيق أرز دبق",
        "300 g",
        300,
        "g",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "دقيق ساغو",
        "30 g",
        30,
        "g",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "سكر نخيل غولا جاوا",
        "150 g",
        150,
        "g",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "جوز هند مبشور",
        "300 g",
        300,
        "g",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "ماء",
        "Water",
        null,
        null,
        false,
        "ماء للعجين والطهي؛ لا كمية منشورة."
      ]
    ],
    "s": [
      "إذا استخدمت أوراق الباندان الكاملة، اطحنها إلى معجون ناعم مع قليل من الماء عند الحاجة.",
      "اخلط دقيق الأرز الدبق ودقيق الساغو جيدًا. أضف معجون الباندان، ثم الماء تدريجيًا حتى تتكون عجينة خضراء طرية.",
      "شكّل كرات قطرها نحو 2–3 سم، واصنع فتحة في كل كرة. املأها بسكر النخيل وأغلق العجين عليه، ثم أعد تشكيل الكرة برفق عند الحاجة.",
      "اغلِ كمية كبيرة من الماء في قدر واسع، وضع الكرات واحدة تلو الأخرى. اطهها نحو 5 دقائق حتى تطفو.",
      "صفِّ الكرات.",
      "دحرجها في جوز الهند المبشور وقدّمها."
    ],
    "notes": [
      "يذكر النص أنها من المطبخ الجاوي ضمن إندونيسيا؛ وسم الحزمة يعتمد تصنيف المصدر الإندونيسي، دون اعتماد مطبخ مستقل أو تخمين.",
      "الناتج والزمن الإجمالي مجهولان؛ خمس دقائق مدة طهي تقريبية فقط."
    ],
    "blockers": [
      "كمية الماء واختيار الباندان والناتج غير محددة؛ لا تغذية أو تحجيم تلقائي."
    ],
    "durations": {
      "3": {
        "min": 5,
        "max": 5,
        "scope": "boil-until-floating",
        "approximate": true
      }
    },
    "supplementalIngredients": [],
    "yield": {
      "amount": null,
      "min": null,
      "max": null,
      "unit": null,
      "sourceText": null
    }
  },
  {
    "id": 452631,
    "nameAr": "أرز إندونيسي بحليب جوز الهند",
    "family": "indonesian-coconut-rice-pandan",
    "method": "simmer-rest-coconut-rice",
    "cuisine": [
      "indonesian",
      "إندونيسي",
      "Category:Indonesian recipes"
    ],
    "time": {
      "declaredTotalMinutes": null,
      "prepMinutes": null,
      "cookMinutes": null,
      "sourceText": "الزمن الإجمالي غير منشور"
    },
    "i": [
      [
        "أرز أبيض طويل الحبة غير مطهو",
        "300 grams",
        300,
        "g",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "حليب جوز الهند",
        "400 ml",
        400,
        "ml",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "كراث أحمر صغير (شالوت)",
        "2 red shallots",
        2,
        "shallot",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "شرائح زنجبيل طازج",
        "2 slices",
        2,
        "slice",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ],
      [
        "بذور حلبة",
        "1 pinpoint",
        null,
        null,
        false,
        "المصدر يقول pinpoint دون مقدار قياسي؛ لا تحويل إلى رشة أو وزن."
      ],
      [
        "أوراق باندان",
        "2 pandan leaves",
        2,
        "leaf",
        false,
        "الكمية كما وردت؛ لا تحويل إلى وزن أو غذاء معيّن."
      ]
    ],
    "s": [
      "اشطف الأرز وصفِّه.",
      "ضع كل المكونات في مقلاة عميقة أو قدر، مع التأكد من غمر الأرز بحليب جوز الهند بمقدار 2 سم بحسب النص.",
      "غطِّ القدر واطهه على نار متوسطة إلى منخفضة حتى يمتص السائل.",
      "أزل أوراق الباندان.",
      "اسكب بقية حليب جوز الهند فوق الأرز.",
      "اتركه يرتاح 15 دقيقة في درجة حرارة الغرفة ثم قدّمه."
    ],
    "notes": [
      "المصدر يقول وضع كل المكونات أولًا ثم إضافة بقية الحليب لاحقًا دون تحديد تقسيم 400 مل؛ حُفظ التناقض واحتاج مراجعة، ولم يُختر مقدار للجزء الأول أو الأخير.",
      "أربع حصص معلنة. زمن الطبخ غير محدد؛ 15 دقيقة للراحة فقط.",
      "ملاحظات المصدر تقترح 2 ديسيلتر حليب مع 2 ديسيلتر ماء أو 350 جم أرز وفق السمك والنقع والتفضيل؛ بدائل غير مختارة ولم تُبدّل المقادير الأساسية."
    ],
    "blockers": [
      "توزيع الحليب بين الخطوات ومقدار الحلبة وزمن الطهي غير محسومة؛ لا تنفيذ أو تحجيم تلقائي."
    ],
    "durations": {
      "5": {
        "min": 15,
        "max": 15,
        "scope": "rest-room-temperature",
        "approximate": false
      }
    },
    "supplementalIngredients": [],
    "yield": {
      "amount": 4,
      "min": 4,
      "max": 4,
      "unit": "servings",
      "sourceText": "4"
    }
  }
];

function decision(spec,source){
 need(spec.i.length===source.recipe.ingredients.length,'Ingredient count mismatch '+spec.id);
 need(spec.s.length===source.recipe.steps.length,'Step count mismatch '+spec.id);
 return {sourcePageId:spec.id,sourceRecordId:source.recordId,sourceSha256:source.sourceSha256,derivedRecipeSha256:snapshotFingerprint(source),nameAr:spec.nameAr,status:'needs-review',family:spec.family,method:spec.method,cuisines:[spec.cuisine],yield:spec.yield,time:spec.time,
  ingredients:spec.i.map((x,index)=>[index,x[0],source.recipe.ingredients[index].name,x[2],x[3],x[4],x[5]]),
  steps:spec.s.map((text,index)=>[[index],text,spec.durations?.[index]??null]),supplementalIngredients:spec.supplementalIngredients??[],notes:spec.notes,blockers:spec.blockers};
}
async function immutable(path,bytes){try{need((await readFile(path,'utf8'))===bytes,'Immutable output differs: '+path);}catch(e){if(e.code!=='ENOENT')throw e;await writeFile(path,bytes,{flag:'wx'});}}
async function generated(path,bytes){await writeFile(path,bytes);}

export async function build(){
 const {recipes,evidence}=await loadRecipeReviewSnapshots();
 const rawBytes=await readFile(resolve(root,'data/recipes/bulk/wikibooks-cookbook/source-pages.jsonl'));
 const rawMap=new Map(rawBytes.toString('utf8').split(/\r?\n/).filter(Boolean).map(JSON.parse).map(r=>[r.sourcePageId,r]));
 const previous=[];for(const [path,expected] of frozen){const bytes=await readFile(resolve(root,path));need(sha(bytes)===expected,'Frozen prior pack drift: '+path);previous.push(...JSON.parse(bytes).recipes);}
 const creators=[];for(const path of ['2026-10-first-batch.json','second-batch-20261014/recipes.json','third-batch-20261014/recipes.json','fourth-batch-20261014/recipes.json','fifth-batch-20261014/recipes.json','sixth-batch-20261014/recipes.json','seventh-batch-20261015/recipes.json']){try{const o=JSON.parse(await readFile(resolve(root,'data/recipes/arabic-youtube',path),'utf8'));creators.push(...(Array.isArray(o)?o:o.recipes??[]));}catch(e){if(e.code!=='ENOENT')throw e;}}
 const ids=new Set(previous.map(r=>r.id)),families=new Set(previous.map(r=>r.familyId)),titles=new Set(previous.flatMap(r=>[r.name,r.nameAr]));for(const r of creators){if(r.id)ids.add(r.id);if(r.familyId)families.add(r.familyId);if(r.name)titles.add(r.name);if(r.nameAr)titles.add(r.nameAr);}
 const decisions=rows.map(spec=>{const source=recipes.get('wikibooks:'+spec.id);need(source,'Missing archived recipe '+spec.id);const raw=rawMap.get(spec.id);need(raw&&String(raw.sourceRevision)===String(source.sourceRevision),'Source revision mismatch');const d=decision(spec,source);validateDecision(d,source,raw);need(raw.sourceCategories.includes(spec.cuisine[2]),'Cuisine category is not exact source evidence');need(!ids.has('curated-local:'+spec.id),'Duplicate source identity');need(!families.has('curated-local:'+spec.family),'Duplicate selected family');need(!titles.has(spec.nameAr)&&!titles.has(source.recipe.name),'Duplicate selected title');ids.add('curated-local:'+spec.id);families.add(spec.family);titles.add(spec.nameAr);titles.add(source.recipe.name);return {spec,source,raw,d};});
 const dest=resolve(root,folder);await mkdir(resolve(dest,'source-snapshots'),{recursive:true});await mkdir(resolve(dest,'preflight-drafts'),{recursive:true});
 const normalized=[],draftReports=[];
 for(const {spec,source,raw,d} of decisions){
  const snapshotBytes=fmt({schemaVersion:1,sourceRecord:raw,authoritativeParsedRecipe:source,authoritativeEvidence:evidence}),snapshotName=spec.id+'.json';
  await immutable(resolve(dest,'source-snapshots',snapshotName),snapshotBytes);
  const provenance={sourceId:source.sourceId,recordId:source.recordId,sourceRevision:source.sourceRevision,sourceRevisionTimestamp:raw.sourceRevisionTimestamp,retrievedAt:raw.retrievedAt,sourceUrl:source.sourceUrl,sourceSha256:source.sourceSha256,derivedRecipeSha256:snapshotFingerprint(source),sourceSnapshotFile:folder+'/source-snapshots/'+snapshotName,sourceSnapshotSha256:sha(snapshotBytes),license:source.license,licenseSha256:snapshotFingerprint(source.license),changeNotice};
  const r=normalize(d,source,raw,provenance);r.contentSha256=snapshotFingerprint(r);normalized.push(r);
  const draft=priorPreflight(r,source,reviewedAt);for(const step of r.steps)if(step.duration?.approximate)for(const index of step.sourceStepIndices)draft.stepMinutes[index]=null;
  const draftBytes=fmt(draft);await immutable(resolve(dest,'preflight-drafts',snapshotName),draftBytes);draftReports.push({curatedRecipeId:r.id,draftFile:folder+'/preflight-drafts/'+snapshotName,draftSha256:sha(draftBytes),...auditRecipeImportDraft(source,draft)});
 }
 const catalogue=[];for(const slug of ['egyptian','levantine','saudi','italian'])catalogue.push(...JSON.parse(await readFile(resolve(root,'recipes/data/'+slug+'.json'),'utf8')).recipes);
 const counts={recipes:normalized.length,ingredientLines:normalized.reduce((n,r)=>n+r.ingredients.length,0),supplementalIngredients:normalized.reduce((n,r)=>n+r.supplementalIngredients.length,0),steps:normalized.reduce((n,r)=>n+r.steps.length,0),fullySpecified:normalized.filter(r=>r.status==='fully-specified').length,needsReview:normalized.filter(r=>r.status==='needs-review').length,notCookable:normalized.filter(r=>r.status==='not-cookable').length,sourceSupportedCuisineLabels:new Set(normalized.flatMap(r=>r.cuisines.map(c=>c.id))).size,runtimeReady:0};
 const priorLabels=new Set(previous.flatMap(r=>r.cuisines.map(c=>c.id))),newLabels=[...new Set(normalized.flatMap(r=>r.cuisines.map(c=>c.id)))].filter(id=>!priorLabels.has(id));
 const all=[...previous,...normalized],combinedLocal={recipes:all.length,fullySpecified:all.filter(r=>r.status==='fully-specified').length,needsReview:all.filter(r=>r.status==='needs-review').length,notCookable:all.filter(r=>r.status==='not-cookable').length,ingredientLines:all.reduce((n,r)=>n+r.ingredients.length,0),supplementalIngredients:all.reduce((n,r)=>n+r.supplementalIngredients.length,0),steps:all.reduce((n,r)=>n+r.steps.length,0),sourceSupportedCuisineLabels:new Set(all.flatMap(r=>r.cuisines.map(c=>c.id))).size,runtimeReady:0};
 const pack={schemaVersion:1,reviewedAt,reviewer:'Bounded offline archived-source Arabic transcription; no kitchen testing',changeNotice,sourceEvidence:evidence,sourceCount:normalized.length,recipes:normalized,relationships:[],counts,duplicateReview:{scope:'Exact source identities, titles, family IDs, selected labels, and existing 54 catalogue names compared with seven prior local packs and archived creator records; no global 6056-record uniqueness claim.',priorLocalRecords:previous.length,creatorArchiveRecords:creators.length,duplicateSourceIds:0,duplicateTitles:0,duplicateFamilies:0,existingCatalogueCount:catalogue.length,exactCatalogueNameMatches:normalized.flatMap(r=>catalogue.filter(c=>c.name===r.name||c.name===r.nameAr).map(c=>({curatedId:r.id,catalogueId:c.id}))),crossLanguageDuplicateReview:'not performed; no global uniqueness claim'}};
 need(pack.duplicateReview.exactCatalogueNameMatches.length===0,'Selected source title duplicates an existing planning recipe');
 const report={schemaVersion:1,reviewedAt,networkRequests:0,newBooks:0,selectedSourcePageIds:normalized.map(r=>Number(r.id.split(':')[1])),sourceRevisions:normalized.map(r=>({sourcePageId:Number(r.id.split(':')[1]),revision:r.provenance.sourceRevision,sourceSha256:r.provenance.sourceSha256,sourceSnapshotSha256:r.provenance.sourceSnapshotSha256})),frozenPacks:frozen.map(([file,sha256])=>({file,sha256})),frozenPreviousRecords:previous.length,creatorArchiveRecords:creators.length,counts,combinedLocal,newLabels,draftComplete:0,runtimeReady:0,draftIssues:draftReports.reduce((n,r)=>n+r.issues.length,0),newDraftReports:draftReports,remainingGates:['all six records need independent culinary review; no kitchen testing','source cuisine labels remain evidence only, not approved cuisines','unknown yield/time/amounts, ranges and alternatives remain unresolved','no food binding, scaling, nutrition, legal page-exception review, or runtime approval']};
 const allFrozen=new Set(frozen.map(x=>x[0]));need(allFrozen.size===7&&normalized.length===6,'Expected six records and seven frozen packs');
 await generated(resolve(dest,'review-decisions.json'),fmt({schemaVersion:1,reviewedAt,reviewer:pack.reviewer,changeNotice,recipes:decisions.map(x=>x.d)}));
 await generated(resolve(dest,'normalized-recipes.json'),fmt(pack));
 const readablePack={...pack,recipes:pack.recipes.map(r=>({...r,yield:{...r.yield,sourceText:r.yield.sourceText??'غير منشور',unit:r.yield.unit??'غير محدد'}}))};
 let humanBook=cookbook(readablePack).replace('# أول مجموعة وصفات من الأرشيف المحلي','# الدفعة الثامنة من وصفات الأرشيف المحلي').replaceAll('..','.').replaceAll('كمية مجهولة  —','كمية مجهولة —');
 for(const [from,to] of Object.entries({' g —':' جم —',' lb —':' رطل —',' cup —':' كوب —',' egg —':' بيض —',' onion —':' بصلة —',' tomato —':' ثمرة طماطم —',' clove —':' فص —',' leaf —':' ورقة —',' pepper —':' حبة فلفل —',' pod —':' قرن —',' lime —':' ليمونة خضراء —',' kg —':' كجم —',' tsp —':' ملعقة صغيرة —',' tbsp —':' ملعقة كبيرة —'}))humanBook=humanBook.replaceAll(from,to);
 await generated(resolve(dest,'COOKBOOK.ar.md'),humanBook);
 await generated(resolve(dest,'review-report.json'),fmt(report));
 for(const [path,expected] of frozen)need(sha(await readFile(resolve(root,path)))===expected,'Frozen prior pack changed during build');
 console.log(JSON.stringify({folder,...counts,newLabels,combinedLocal,draftIssues:report.draftIssues,packSha256:sha(fmt(pack))}));return {pack,report};
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url))build().catch(e=>{console.error(e);process.exitCode=1;});
