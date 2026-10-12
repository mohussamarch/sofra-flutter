/**
 * أنواع بيانات دفتر وصفات «سفرة»
 *
 * الملف ده هو المصدر الوحيد للحقيقة (single source of truth) لشكل الوصفة.
 * أي تعديل في السكيما لازم يتعمل هنا وفي `data/*.json` وفي `scripts/validate.mjs` مع بعض.
 */

/** وحدة القياس — نص عربي حر، لكن القيم المعتادة هي دول */
export type Unit =
  | 'كوب'
  | 'ملعقة كبيرة'
  | 'ملعقة صغيرة'
  | 'جرام'
  | 'كيلو'
  | 'مل'
  | 'لتر'
  | 'حبة'
  | 'فص'
  | 'عود'
  | 'رغيف'
  | 'قرص'
  | 'ورقة'
  | 'حزمة'
  | 'رشة';

/** أقسام الوصفات */
export type RecipeCategory =
  | 'طبق رئيسي'
  | 'مقبلات'
  | 'شوربة'
  | 'فطار'
  | 'سلطة'
  | 'مخبوزات'
  | 'حلويات'
  | 'مشروبات';

/** صعوبة الوصفة */
export type Difficulty = 'سهل' | 'متوسط' | 'متقدم';

/** المطابخ المدعومة حالياً */
export type CuisineName = 'مصري' | 'شامي' | 'سعودي' | 'إيطالي';

/** معرّف المطبخ بالإنجليزي (للملفات والمفاتيح) */
export type CuisineSlug = 'egyptian' | 'levantine' | 'saudi' | 'italian';

/**
 * مكوّن واحد في الوصفة.
 *
 * قواعد مهمة لتعديل المقادير (scaling):
 * - `amount` رقم دايمًا لما يكون فيه كمية مقاسة. استخدم 0.5 للنص و 0.25 للربع، وممنوع نصوص زي "1/2".
 * - `amount: null` معناها «مش كمية مقاسة» (ملح، فلفل، بهارات) ولازم معاها `scale: false`.
 * - `scale: false` لما الكمية مينفعش تتضاعف مع عدد الأشخاص (بيكنج بودر، زيت التحمير الغزير، مية العجين التقريبية، فرخة كاملة للشوربة).
 * - `display` نص جاهز بيظهر للمستخدم بدل الرقم، ولما تكون موجودة الكود بيستخدمها زي ما هي.
 */
export interface Ingredient {
  /** معرّف فريد داخل الوصفة (إنجليزي، حروف صغيرة) */
  id: string;
  /** الاسم بالعربي زي ما يظهر للمستخدم */
  name: string;
  /** الكمية للأساس (عدد الأشخاص في `servings`)، أو null لو مش مقاسة */
  amount: number | null;
  /** الوحدة، أو null لو الوصفة بتعتمد على `label` */
  unit: Unit | string | null;
  /** ملاحظة قصيرة تظهر جنب المكوّن (مثال: «يُصفّى ويُعاد استخدامه») */
  note?: string;
  /** نص بديل يظهر لما `amount` تكون null (مثال: «حسب الرغبة») */
  label?: string;
  /** مكوّن اختياري */
  optional?: boolean;
  /** false = الكمية ثابتة ومش بتتغير مع عدد الأشخاص */
  scale?: boolean;
  /** نص جاهز للعرض (يستخدم في الواجهة زي ما هو) */
  display?: string;
}

/** خطوة واحدة في طريقة التحضير */
export interface Step {
  /** رقم الخطوة، يبدأ من 1 ومتسلسل بدون فراغات */
  n: number;
  /** نص الخطوة بالعربي */
  text: string;
  /** مدة الخطوة بالدقائق — تُضرب في نفس معامل عدد الأشخاص */
  duration: number;
  /**
   * true = خطوة انتظار من غير تدخّل (فرن، نقع، تبريد، تخمير، راحة العجين).
   * الخطوات السلبية بتشتغل لوحدها، فالوقت الكلي للوصفة مش مجموع كل الخطوات.
   */
  passive?: boolean;
  /** نصيحة عملية قصيرة (اختياري) */
  tip?: string;
}

/** وصفة كاملة */
export interface Recipe {
  /** معرّف فريد على مستوى كل المطابخ (مثال: eg-koshari) */
  id: string;
  name: string;
  nameEn?: string;
  cuisine: CuisineName;
  category: RecipeCategory;
  description: string;
  /** عدد الأشخاص للأساس اللي المقادير مكتوبة عليه */
  servings: number;
  /** وقت التحضير بالدقائق */
  prepTime: number;
  /** وقت الطهي بالدقائق */
  cookTime: number;
  /** الإجمالي = prepTime + cookTime (المدقّق بيتأكد من ده) */
  totalTime: number;
  difficulty: Difficulty;
  ingredients: Ingredient[];
  steps: Step[];
  tags: string[];
  notes?: string;
}

/** ملف مطبخ واحد = كل وصفات مطبخ معيّن */
export interface CuisineFile {
  cuisine: CuisineName;
  cuisineSlug: CuisineSlug;
  version: string;
  recipes: Recipe[];
}

/** عنصر مختصر في فهرس الوصفات (من غير تفاصيل، لحجم أصغر في الواجهة) */
export interface IndexEntry {
  id: string;
  name: string;
  nameEn?: string;
  cuisine: CuisineName;
  category: RecipeCategory;
  servings: number;
  totalTime: number;
  difficulty: Difficulty;
  tags: string[];
  /** مسار ملف المطبخ نسبةً لمجلد data */
  file: string;
}

/** فهرس كل الوصفات */
export interface RecipeIndex {
  version: string;
  updatedAt: string;
  cuisines: Array<{
    name: CuisineName;
    slug: CuisineSlug;
    file: string;
    count: number;
  }>;
  categories: RecipeCategory[];
  units: string[];
  recipes: IndexEntry[];
}

/** وصفة بعد تعديل المقادير لعدد أشخاص مختلف */
export interface ScaledRecipe extends Omit<Recipe, 'ingredients' | 'steps'> {
  /** عدد الأشخاص الأصلي في الملف */
  baseServings: number;
  /** عدد الأشخاص المطلوب بعد التعديل */
  servings: number;
  /** معامل الضرب المستخدم (المطلوب ÷ الأساس)، مقرّب لثلاث خانات */
  factor: number;
  /** إجمالي وقت التحضير بعد التعديل (الوقت مش خطّي تماماً مع عدد الأشخاص) */
  prepTime: number;
  cookTime: number;
  totalTime: number;
  /** مجموع مدد الخطوات الفعلية (اللي المستخدم بيده فيها) */
  activeTime: number;
  /** الوقت المقضيّ في الانتظار من غير تدخّل (فرن، تبريد، نقع) */
  passiveTime: number;
  ingredients: ScaledIngredient[];
  steps: ScaledStep[];
}

export interface ScaledIngredient extends Omit<Ingredient, 'amount'> {
  /** الكمية الأصلية قبل التعديل */
  baseAmount: number | null;
  /** الكمية بعد التعديل ومقرّبة لرقم عملي في المطبخ */
  amount: number | null;
  /** نص جاهز للعرض (مثال: «1½ كوب») */
  display: string;
}

export interface ScaledStep extends Step {
  /** مدة الخطوة الأصلية */
  baseDuration: number;
  /** المدة بعد التعديل */
  duration: number;
}
