/**
 * تعديل المقادير وأوقات الخطوات حسب عدد الأشخاص.
 *
 * الفكرة: كل وصفة متكتوبة على عدد أشخاص أساسي (`servings`).
 * لما المستخدم يغيّر العدد، بنحسب معامل = العدد الجديد ÷ العدد الأساسي،
 * وبعدين:
 *   1. نضرب كمية كل مكوّن فيه `amount` رقمي (إلا لو `scale: false`).
 *   2. نقرّب الكمية لرقم عملي في المطبخ (مش 1.3333 كوب، لأ 1⅓ كوب).
 *   3. نضرب مدة كل خطوة، لكن الوقت الكلي مش خطّي تماماً (فرن مليان، تحمير على دفعات).
 *
 * الدوال هنا نقيّة (pure) ومفيش فيها أي اعتماد على React أو Node.
 */

import type {
  Ingredient,
  Recipe,
  ScaledIngredient,
  ScaledRecipe,
  ScaledStep,
  Step,
} from './types.ts';

/** أرقام عربية-هندية للعرض في الواجهة العربية */
const AR_DIGITS = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/** وحدات التحمير الغزير — الكمية فيها مش بتتبع عدد الأشخاص */
const FRYING_UNITS = ['كوب', 'لتر'];

/** كسور شائعة في المطبخ: من 1/8 لحد 7/8 */
const FRACTIONS: Array<[number, string]> = [
  [0.125, '⅛'],
  [0.25, '¼'],
  [0.375, '⅜'],
  [0.5, '½'],
  [0.625, '⅝'],
  [0.75, '¾'],
  [0.875, '⅞'],
];

/* ============================================================
   أدوات مساعدة
   ============================================================ */

/** تقريب لعدد خانات عشرية محدّد مع التخلص من أخطاء الفاصلة العائمة */
export function round(value: number, decimals = 2): number {
  const p = 10 ** decimals;
  return Math.round(value * p + Number.EPSILON) / p;
}

/**
 * هل الكمية دي بتتضاعف مع عدد الأشخاص؟
 * بنرجع false لو المستخدم حدّد `scale: false` صريح، أو لو مفيش كمية أصلًا.
 */
export function isScalable(ingredient: Ingredient): boolean {
  if (ingredient.scale === false) return false;
  if (ingredient.amount === null || ingredient.amount === undefined) return false;
  if (typeof ingredient.amount !== 'number' || !Number.isFinite(ingredient.amount)) return false;
  return true;
}

/**
 * تقريب الكمية حسب الوحدة:
 * - وحدات صغيرة (ملعقة صغيرة/كبيرة) تبقى بنص وفوق.
 * - الجرام/المل بتتقرب عمليًا؛ الكوب واللتر والكيلو يحتفظوا بالكسور.
 * - الوحدات المعدودة (حبة/فص/رغيف) تبقى أرقام صحيحة من غير كسور غريبة.
 */
export function roundAmountForUnit(amount: number, unit: string | null | undefined): number {
  if (!Number.isFinite(amount)) return amount;

  if (unit === 'ملعقة صغيرة' || unit === 'ملعقة كبيرة' || unit === 'رشة') {
    if (amount < 0.25) return 0.25; // أي حاجة أقل من ربع ملعقة تبقى رشة
    return round(Math.round(amount * 4) / 4, 3);
  }

  // Fractional cups/litres/kilograms must retain their quantity; rounding
  // them like grams changed 1/4 cup to 1/2 cup and 8 cups to 10 cups.
  if (unit === 'كوب' || unit === 'لتر' || unit === 'كيلو') {
    return round(amount, 3);
  }

  if (unit === 'جرام' || unit === 'مل') {
    if (amount < 5) return round(Math.round(amount * 2) / 2, 2);
    return round(Math.round(amount / 5) * 5, 2);
  }

  if (
    unit === 'حبة' ||
    unit === 'فص' ||
    unit === 'عود' ||
    unit === 'رغيف' ||
    unit === 'قرص' ||
    unit === 'ورقة' ||
    unit === 'حزمة'
  ) {
    // نص حبة مسموح (مثال: بصلة ونص)، لكن مش ربع حبة
    const r = round(Math.round(amount * 2) / 2, 2);
    return r < 0.5 ? 0.5 : r;
  }

  // وحدات مخصّصة: تقريب لخانتين
  return round(amount, 2);
}

/** تحويل رقم لنص بكسور عربية مقروءة: 1.25 → "1¼" و 0.5 → "½" */
export function formatNumber(value: number, options: { arabicDigits?: boolean } = {}): string {
  const num = round(value, 3);
  const sign = num < 0 ? '-' : '';
  const abs = Math.abs(num);
  const whole = Math.floor(abs + 1e-9);
  const frac = abs - whole;

  let text: string;
  if (frac < 0.015) {
    text = String(whole);
  } else {
    const match = FRACTIONS.find(([v]) => Math.abs(frac - v) < 0.02);
    if (match) {
      text = whole === 0 ? match[1] : `${whole}${match[1]}`;
    } else {
      // مفيش كسر قريب: نعرض رقم عشري من غير أصفار زايدة
      text = String(round(abs, 2));
    }
  }

  if (options.arabicDigits) {
    text = text.replace(/[0-9]/g, (d) => AR_DIGITS[Number(d)]);
  }

  return sign + text;
}

/** تحويل رقم لنص بأرقام عربية-هندية: 4 → "٤" */
export function toArabicDigits(value: number | string): string {
  return String(value).replace(/[0-9]/g, (d) => AR_DIGITS[Number(d)]);
}

/** نص الكمية الجاهز للعرض: «1½ كوب» أو «حسب الرغبة» */
export function formatAmount(
  ingredient: Ingredient,
  amount: number | null = ingredient.amount,
  options: { arabicDigits?: boolean } = {}
): string {
  // نص جاهز من الملف يغلب أي حساب
  if (ingredient.display) return ingredient.display;
  if (amount === null || amount === undefined) {
    return ingredient.label ?? ingredient.note ?? 'حسب الرغبة';
  }

  // الكسور الصغيرة من الكيلو تتحوّل لجرام: 0.9 كيلو تبقى 900 جرام
  if (ingredient.unit === 'كيلو' && amount < 1) {
    const grams = roundAmountForUnit(amount * 1000, 'جرام');
    return `${formatNumber(grams, options)} جرام`;
  }

  const num = formatNumber(amount, options);
  return ingredient.unit ? `${num} ${ingredient.unit}` : num;
}

/* ============================================================
   تعديل الوقت
   ============================================================ */

/**
 * الوقت مش خطّي تماماً مع عدد الأشخاص:
 * - ٣٠ دقيقة تحمير لـ ٤ أشخاص مش هتبقى ساعة لـ ٨ أشخاص.
 * نستخدم جذر المعامل عند الزيادة، ونقصان طفيف عند التقليل.
 */
export function scaleMinutes(minutes: number, factor: number): number {
  if (!Number.isFinite(minutes) || minutes <= 0) return minutes;
  if (factor <= 1) return Math.max(1, Math.round(minutes * Math.max(factor, 0.5)));
  return Math.max(1, Math.round(minutes * Math.sqrt(factor)));
}

/* ============================================================
   التعديل الأساسي
   ============================================================ */

/** تعديل مكوّن واحد */
export function scaleIngredient(ingredient: Ingredient, factor: number): ScaledIngredient {
  const baseAmount = ingredient.amount ?? null;

  if (!isScalable(ingredient) || baseAmount === null) {
    return {
      ...ingredient,
      baseAmount,
      amount: baseAmount,
      display: formatAmount(ingredient, baseAmount),
    };
  }

  const raw = baseAmount * factor;
  const amount = roundAmountForUnit(raw, ingredient.unit);
  return {
    ...ingredient,
    baseAmount,
    amount,
    display: formatAmount(ingredient, amount),
  };
}

/** تعديل خطوة واحدة (المدة بتتغير، والنص زي ما هو) */
export function scaleStep(step: Step, factor: number): ScaledStep {
  return {
    ...step,
    baseDuration: step.duration,
    duration: scaleMinutes(step.duration, factor),
  };
}

/**
 * تعديل وصفة كاملة لعدد أشخاص جديد.
 *
 * @example
 * const scaled = scaleRecipe(koshari, 8);
 * scaled.factor;                       // 2
 * scaled.ingredients[0].display;       // "3 كوب"
 * scaled.ingredients[1].display;       // "2 كوب" (عدس)
 * scaled.totalTime;                    // 90
 * scaled.activeTime;                   // الوقت اللي المستخدم واقف فيه فعلًا
 */
export function scaleRecipe(recipe: Recipe, targetServings: number): ScaledRecipe {
  const base = recipe.servings > 0 ? recipe.servings : 1;
  const target = targetServings > 0 ? targetServings : base;
  const factor = target / base;

  const prepTime = scaleMinutes(recipe.prepTime, factor);
  const cookTime = scaleMinutes(recipe.cookTime, factor);

  const steps = recipe.steps.map((step) => scaleStep(step, factor));

  return {
    ...recipe,
    baseServings: base,
    servings: target,
    factor: round(factor, 3),
    prepTime,
    cookTime,
    totalTime: prepTime + cookTime,
    activeTime: sumByKind(recipe.steps, factor, 'active'),
    passiveTime: sumByKind(recipe.steps, factor, 'passive'),
    ingredients: recipe.ingredients.map((ing) => scaleIngredient(ing, factor)),
    steps,
  };
}

/** مجموع مدد الخطوات (الفعلية أو السلبية) بعد تطبيق المعامل */
function sumByKind(steps: Step[], factor: number, kind: 'active' | 'passive'): number {
  return steps
    .filter((s) => (kind === 'passive' ? s.passive === true : s.passive !== true))
    .reduce((sum, s) => sum + scaleMinutes(s.duration || 0, factor), 0);
}

/**
 * تقدير الوقت الكلي من الخطوات نفسها (يُستخدم للتحقق وللعرض).
 * الخطوات السلبية ممكن تتداخل مع بعضها، فبناخد الأطول منها بدل مجموعها.
 */
export function estimateTotalTime(recipe: Pick<Recipe, 'steps'>): {
  activeTime: number;
  passiveTime: number;
  estimatedTotal: number;
} {
  const active = recipe.steps.filter((s) => s.passive !== true);
  const passive = recipe.steps.filter((s) => s.passive === true);

  const activeTime = active.reduce((sum, s) => sum + (s.duration || 0), 0);
  const passiveLongest = passive.reduce((max, s) => Math.max(max, s.duration || 0), 0);
  const passiveRest = passive.reduce((sum, s) => sum + (s.duration || 0), 0) - passiveLongest;

  return {
    activeTime,
    passiveTime: passive.reduce((sum, s) => sum + (s.duration || 0), 0),
    estimatedTotal: activeTime + Math.max(passiveLongest, passiveRest),
  };
}

/* ============================================================
   أوقات الخطوات
   ============================================================ */

/** إجمالي مدة كل الخطوات بالدقائق */
export function totalStepDuration(recipe: Pick<Recipe, 'steps'>): number {
  return recipe.steps.reduce((sum, step) => sum + (step.duration || 0), 0);
}

/**
 * مؤقّت تراكمي: لكل خطوة بنرجع وقت البداية ووقت النهاية بالنسبة لبداية الطبخ.
 * ده اللي بيشغّل شريط «الوقت» في شاشة الوصفة.
 *
 * @example
 * cumulativeStepTimes(recipe).at(-1)?.end // إجمالي وقت الخطوات
 */
export function cumulativeStepTimes(
  recipe: Pick<Recipe, 'steps'>
): Array<{ n: number; start: number; end: number; duration: number }> {
  let cursor = 0;
  return recipe.steps.map((step) => {
    const start = cursor;
    const duration = step.duration || 0;
    cursor += duration;
    return { n: step.n, start, end: cursor, duration };
  });
}

/** تحويل دقائق لنص عربي مختصر: 75 → «ساعة و15 دقيقة» */
export function formatDuration(minutes: number): string {
  if (!Number.isFinite(minutes) || minutes <= 0) return 'أقل من دقيقة';
  const h = Math.floor(minutes / 60);
  const m = Math.round(minutes % 60);
  const hourText = h === 1 ? 'ساعة' : h === 2 ? 'ساعتين' : `${toArabicDigits(h)} ساعات`;
  if (h === 0) return `${toArabicDigits(m)} دقيقة`;
  if (m === 0) return hourText;
  return `${hourText} و${toArabicDigits(m)} دقيقة`;
}

/** تحويل دقائق لصيغة المؤقّت: 75 → "1:15:00" و 12 → "00:12" */
export function formatClock(minutes: number): string {
  const total = Math.max(0, Math.round(minutes * 60));
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  const pad = (n: number) => String(n).padStart(2, '0');
  return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${pad(m)}:${pad(s)}`;
}

/* ============================================================
   مساعدات للواجهة
   ============================================================ */

/** عدد الأشخاص المقترح للعرض: ‎1, 2, 4, 6, 8, 10, 12 */
export function servingChoices(recipe: Recipe): number[] {
  const base = recipe.servings;
  const set = new Set<number>([base, base * 2, Math.max(1, Math.round(base / 2))]);
  for (let s = 1; s <= 12; s++) set.add(s);
  return [...set].filter((s) => s > 0).sort((a, b) => a - b);
}

/** وصف مختصر لسطر واحد في نتائج البحث: «كشري — مصري — 4 أفراد — 65 دقيقة» */
export function recipeSubtitle(recipe: Pick<Recipe, 'cuisine' | 'servings' | 'totalTime'>): string {
  return `${recipe.cuisine} · ${toArabicDigits(recipe.servings)} أفراد · ${formatDuration(
    recipe.totalTime
  )}`;
}

/* ============================================================
   اختبار ذاتي سريع (يشتغل بالـ node مباشرة)
   ============================================================ */

export function selfTest(): Array<{ name: string; ok: boolean; detail?: string }> {
  const results: Array<{ name: string; ok: boolean; detail?: string }> = [];
  const check = (name: string, ok: boolean, detail?: string) => results.push({ name, ok, detail });

  check('formatNumber(0.5) = ½', formatNumber(0.5) === '½', formatNumber(0.5));
  check('formatNumber(1.25) = 1¼', formatNumber(1.25) === '1¼', formatNumber(1.25));
  check('formatNumber(4) = 4', formatNumber(4) === '4', formatNumber(4));
  check(
    'roundAmountForUnit(11.25, كوب) = 11.25',
    roundAmountForUnit(11.25, 'كوب') === 11.25,
    String(roundAmountForUnit(11.25, 'كوب'))
  );
  check(
    'scaleMinutes(45, 2) = 64 (الوقت مش خطّي)',
    scaleMinutes(45, 2) === 64,
    String(scaleMinutes(45, 2))
  );
  check('formatDuration(75) عربي', formatDuration(75) === 'ساعة و١٥ دقيقة', formatDuration(75));
  check('formatClock(75) = 1:15:00', formatClock(75) === '1:15:00', formatClock(75));

  const recipe: Recipe = {
    id: 'test',
    name: 'اختبار',
    cuisine: 'مصري',
    category: 'طبق رئيسي',
    description: 'وصفة اختبار',
    servings: 4,
    prepTime: 10,
    cookTime: 20,
    totalTime: 30,
    difficulty: 'سهل',
    ingredients: [
      { id: 'rice', name: 'أرز', amount: 2, unit: 'كوب' },
      { id: 'salt', name: 'ملح', amount: null, unit: null, label: 'حسب الرغبة', scale: false },
      { id: 'soda', name: 'بيكنج صودا', amount: 1, unit: 'ملعقة صغيرة', scale: false },
      { id: 'egg', name: 'بيض', amount: 3, unit: 'حبة' },
    ],
    steps: [
      { n: 1, text: 'خطوة أولى', duration: 10 },
      { n: 2, text: 'خطوة تانية', duration: 20 },
    ],
    tags: ['اختبار'],
  };

  const doubled = scaleRecipe(recipe, 8);
  check('المعامل = 2', doubled.factor === 2, String(doubled.factor));
  check('الأرز 2 كوب → 4 كوب', doubled.ingredients[0].display === '4 كوب', doubled.ingredients[0].display);
  check(
    'الملح يفضل حسب الرغبة',
    doubled.ingredients[1].display === 'حسب الرغبة',
    doubled.ingredients[1].display
  );
  check(
    'البيكنج صودا ثابتة',
    doubled.ingredients[2].display === '1 ملعقة صغيرة',
    doubled.ingredients[2].display
  );
  check('البيض 3 → 6', doubled.ingredients[3].display === '6 حبة', doubled.ingredients[3].display);

  const halved = scaleRecipe(recipe, 2);
  check('النص: الأرز 1 كوب', halved.ingredients[0].display === '1 كوب', halved.ingredients[0].display);
  check('النص: البيض 1.5 حبة', halved.ingredients[3].display === '1½ حبة', halved.ingredients[3].display);

  const times = cumulativeStepTimes(doubled);
  check('وقت نهاية آخر خطوة', times[times.length - 1].end === doubled.steps.reduce((s, x) => s + x.duration, 0));

  return results;
}

