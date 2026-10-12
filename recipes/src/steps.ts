/**
 * أدوات عرض الخطوات وأوقاتها — بسيطة ومفيهاش أي اعتماد على مكتبات.
 *
 * الهدف: شاشة الوصفة تعرف تعرض «الخطوة دي بتاخد قد إيه» و«إحنا في أنهي وقت»،
 * وتشتغل بالعربي بأرقام عربية-هندية، وتشتغل كمان مع موقّت حقيقي في التطبيق.
 */

import type { Recipe, ScaledRecipe, ScaledStep, Step } from './types.ts';
import { formatClock, formatDuration, round, scaleMinutes, toArabicDigits } from './scale.ts';

/** عنصر واحد في جدول زمن الخطوات */
export interface StepScheduleItem {
  n: number;
  /** رقم الخطوة بالعربي */
  label: string;
  text: string;
  tip?: string;
  /** خطوة انتظار (فرن/تبريد/نقع) */
  passive: boolean;
  /**
   * true = وقتها خارج جلسة الطبخ (نقع ليلة كاملة) ومش محسوب في الوقت الكلي.
   */
  outsideSession: boolean;
  /** المدة بالدقائق بعد التعديل */
  duration: number;
  /** دقائق من بداية الطبخ */
  start: number;
  end: number;
  /** نصوص جاهزة للعرض: "00:20" و "٢٠ دقيقة" */
  startClock: string;
  endClock: string;
  durationText: string;
}

const durationOf = (step: Step | ScaledStep): number =>
  'duration' in step && typeof step.duration === 'number' ? step.duration : 0;

/**
 * جدول زمني كامل للوصفة: كل خطوة ببدايتها ونهايتها بالنسبة لبداية الطبخ.
 *
 * الخطوات اللي مدتها صفر (نقع ليلة كاملة) بتتعرض بـ `outsideSession: true`
 * ووقتها الحقيقي مكتوب في نص الخطوة.
 *
 * @example
 * const schedule = stepSchedule(recipe);
 * schedule[0].startClock;   // "00:00"
 * schedule[0].endClock;     // "20:00"
 */
export function stepSchedule(
  recipe: Pick<Recipe, 'steps'> | Pick<ScaledRecipe, 'steps'>
): StepScheduleItem[] {
  let cursor = 0;
  return recipe.steps.map((step) => {
    const duration = durationOf(step);
    const outsideSession = duration <= 0;
    const start = cursor;
    const end = cursor + duration;
    cursor = end;
    return {
      n: step.n,
      label: toArabicDigits(step.n),
      text: step.text,
      tip: step.tip,
      passive: step.passive === true,
      outsideSession,
      duration,
      start,
      end,
      startClock: formatClock(start),
      endClock: formatClock(end),
      durationText: outsideSession ? 'خارج الوقت' : formatDuration(duration),
    };
  });
}

/** سطر واحد جاهز للعرض: «١. ٠٠:٠٠ – ٢٠:٠٠ (٢٠ دقيقة) انقع العدس…» */
export function formatScheduleLine(item: StepScheduleItem, maxLength = 80): string {
  const text = item.text.length > maxLength ? `${item.text.slice(0, maxLength - 1)}…` : item.text;
  return `${item.label}. ${item.startClock} – ${item.endClock} (${item.durationText}) ${text}`;
}

/** إجمالي الوقت الفعلي (الخطوات اللي المستخدم بيده فيها) */
export function totalActiveMinutes(recipe: Pick<Recipe, 'steps'>): number {
  return recipe.steps
    .filter((s) => s.passive !== true)
    .reduce((sum, s) => sum + durationOf(s), 0);
}

/** إجمالي وقت الانتظار (فرن، تبريد، نقع) */
export function totalPassiveMinutes(recipe: Pick<Recipe, 'steps'>): number {
  return recipe.steps
    .filter((s) => s.passive === true)
    .reduce((sum, s) => sum + durationOf(s), 0);
}

/** عدد الخطوات الفعلية */
export function activeStepCount(recipe: Pick<Recipe, 'steps'>): number {
  return recipe.steps.filter((s) => s.passive !== true).length;
}

/**
 * تقسيم جدول الخطوات لمجموعات لخطوات الطهي، ومجموع الوقت الفعلي لكل مجموعة.
 * مفيد في عرض «مراحل» الوصفة في الواجهة.
 */
export function stepGroups(
  recipe: Pick<Recipe, 'steps'>,
  groupSize = 3
): Array<{ index: number; items: StepScheduleItem[]; totalMinutes: number }> {
  const schedule = stepSchedule(recipe);
  const groups: Array<{ index: number; items: StepScheduleItem[]; totalMinutes: number }> = [];
  for (let i = 0; i < schedule.length; i += groupSize) {
    const items = schedule.slice(i, i + groupSize);
    groups.push({
      index: groups.length + 1,
      items,
      totalMinutes: items.reduce((sum, s) => sum + s.duration, 0),
    });
  }
  return groups;
}

/**
 * الخطة الزمنية لتعديل عدد الأشخاص: بنشرح للمستخدم الوقت الأصلي والجديد.
 * مفيد في رسالة صغيرة تحت زر «عدّل عدد الأشخاص».
 */
export function timingChangeSummary(
  step: Step,
  factor: number
): { base: number; scaled: number; text: string } {
  const scaled = scaleMinutes(step.duration, factor);
  const same = scaled === step.duration;
  return {
    base: step.duration,
    scaled,
    text: same
      ? `الوقت زي ما هو: ${formatDuration(scaled)}`
      : `الوقت اتغيّر من ${formatDuration(step.duration)} لـ ${formatDuration(scaled)}`,
  };
}

/* ============================================================
   موقّت حقيقي (يستخدم في شاشة الطبخ)
   ============================================================ */

/**
 * موقّت خطوة واحدة.
 * الدالة دي نقيّة: بترجع الحالة الجديدة، ومفيش فيها أي `setInterval`
 * عشان تقدر تستخدمها مع أي إطار عمل (React / Vue / Vanilla).
 */
export interface StepTimer {
  /** رقم الخطوة الحالية */
  stepIndex: number;
  /** ثواني متبقية في الخطوة الحالية */
  remaining: number;
  /** الوصفة خلصت؟ */
  finished: boolean;
}

export function createTimer(recipe: Pick<Recipe, 'steps'>): StepTimer {
  return {
    stepIndex: 0,
    remaining: (recipe.steps[0]?.duration ?? 0) * 60,
    finished: recipe.steps.length === 0,
  };
}

export function tickTimer(
  recipe: Pick<Recipe, 'steps'>,
  timer: StepTimer,
  elapsedSeconds = 1
): StepTimer {
  if (timer.finished) return timer;
  const remaining = timer.remaining - elapsedSeconds;

  if (remaining > 0) return { ...timer, remaining };

  // انتقل للخطوة اللي بعدها واحمل الوقت الزايد عليها
  let index = timer.stepIndex + 1;
  let carry = -remaining;

  while (index < recipe.steps.length) {
    const full = (recipe.steps[index].duration ?? 0) * 60;
    if (carry < full) {
      return { stepIndex: index, remaining: full - carry, finished: false };
    }
    carry -= full;
    index += 1;
  }

  return { stepIndex: recipe.steps.length - 1, remaining: 0, finished: true };
}

/** نص الموقّت للعرض: "12:30" */
export function timerText(timer: StepTimer): string {
  const total = Math.max(0, Math.round(timer.remaining));
  const m = Math.floor(total / 60);
  const s = total % 60;
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}

/** نسبة التقدّم في الخطوة الحالية من 0 لـ 1 */
export function timerProgress(recipe: Pick<Recipe, 'steps'>, timer: StepTimer): number {
  const step = recipe.steps[timer.stepIndex];
  if (!step || !step.duration) return 0;
  const full = step.duration * 60;
  return round(Math.min(1, Math.max(0, 1 - timer.remaining / full)), 3);
}
