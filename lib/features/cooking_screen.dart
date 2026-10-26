import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../domain/kitchen_core.dart';
import '../domain/recipe_catalog.dart';
import '../ui/design.dart';
import '../ui/illustrations.dart';
import 'common.dart';

/// Step-by-step cooking for one planned meal, ending in an explicit stock
/// confirmation (what is deducted, what is kept out and why).
class CookingScreen extends StatefulWidget {
  const CookingScreen({super.key, required this.meal, required this.onDone});
  final PlannedMeal meal;
  final VoidCallback onDone;
  @override
  State<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends State<CookingScreen> {
  Future<CatalogRecipe>? recipe;
  int step = 0;
  bool cooked = false;
  bool busy = false;
  // One operation ID per confirmation so a retry never cooks twice.
  late final operationId = SofraScope.controllerOf(context)
      .newId('cook-${widget.meal.id}');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    recipe ??= SofraScope.controllerOf(context).recipeForPlan(widget.meal.id);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CatalogRecipe>(
    future: recipe,
    builder: (context, snap) {
      if (snap.hasError) {
        return const ScreenBody(children: [ErrorBlock('تعذّر فتح الوصفة.')]);
      }
      final r = snap.data;
      if (r == null) return const LoadingBlock();
      if (cooked) return _success(r);
      if (r.steps.isEmpty) {
        return ScreenBody(
          footer: DepthButton(
            key: const ValueKey('finish-cooking'),
            label: 'خلصنا الطبخ · راجع الخصم',
            onPressed: busy ? null : () => _confirm(r),
          ),
          children: const [Text('الوصفة دي مالهاش خطوات مكتوبة في المصدر.')],
        );
      }
      return _step(r);
    },
  );

  Widget _step(CatalogRecipe r) {
    final steps = r.steps;
    final last = step >= steps.length - 1;
    final s = steps[step];
    return ScreenBody(
      footer: DepthButton(
        key: ValueKey(last ? 'finish-cooking' : 'next-cooking-step'),
        label: last ? 'خلصنا الطبخ · راجع الخصم' : 'الخطوة اللي بعدها',
        onPressed: busy
            ? null
            : last
            ? () => _confirm(r)
            : () => setState(() => step++),
      ),
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                r.name,
                style: const TextStyle(color: Sofra.muted, fontSize: 14),
              ),
            ),
            SoftTag('${step + 1} من ${steps.length}'),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (step + 1) / steps.length,
            minHeight: 8,
            backgroundColor: Sofra.line,
            color: Sofra.green,
          ),
        ),
        const SizedBox(height: 28),
        Surface(
          color: Sofra.mint,
          child: Center(child: ChefArt(size: 200, celebrate: last)),
        ),
        const SizedBox(height: 28),
        Text(s.text, style: const TextStyle(fontSize: 19, height: 1.7)),
        const SizedBox(height: 20),
        if (s.minutes != null)
          SoftTag(
            'حوالي ${formatAmount(s.minutes!)} دقيقة',
            icon: Icons.schedule_rounded,
            color: Sofra.peach,
            ink: const Color(0xFF995333),
          ),
        if (s.tip != null) ...[
          const SizedBox(height: 12),
          Text(s.tip!, style: const TextStyle(color: Sofra.muted)),
        ],
        const SizedBox(height: 20),
        if (step > 0)
          TextButton.icon(
            onPressed: () => setState(() => step--),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('الخطوة اللي فاتت'),
          ),
      ],
    );
  }

  Future<void> _confirm(CatalogRecipe r) async {
    final c = SofraScope.controllerOf(context);
    final check = c.checkStock(r.forServings(widget.meal.servings));
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: _ConfirmSheet(check: check),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => busy = true);
    final record = await c.cook(widget.meal, check, operationId);
    if (!mounted) return;
    setState(() {
      busy = false;
      cooked = record != null;
    });
  }

  Widget _success(CatalogRecipe r) => ScreenBody(
    children: [
      const SizedBox(height: 24),
      const Center(child: ChefArt(size: 260, celebrate: true)),
      const SizedBox(height: 18),
      const Center(
        child: Text(
          'بالهنا والشفا!',
          key: ValueKey('cooking-success'),
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: Text(
          'اتطبخت ${r.name}، وخصمنا اللي أكدته من المخزون.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Sofra.muted),
        ),
      ),
      const SizedBox(height: 24),
      _LeftoversCard(name: r.name, maxServings: widget.meal.servings),
      const SizedBox(height: 16),
      DepthButton(
        key: const ValueKey('after-cooking-kitchen'),
        label: 'شوف اللي فاضل في مطبخك',
        onPressed: () {
          widget.onDone();
          SofraScope.navOf(context).goTab(AppTab.kitchen);
        },
      ),
    ],
  );
}

/// "Anything left?" after cooking: the servings go to the fridge as a covered
/// dish, and the microwave offers them later.
class _LeftoversCard extends StatefulWidget {
  const _LeftoversCard({required this.name, required this.maxServings});
  final String name;
  final int maxServings;
  @override
  State<_LeftoversCard> createState() => _LeftoversCardState();
}

class _LeftoversCardState extends State<_LeftoversCard> {
  double servings = 0;
  bool saved = false;

  /// Days until the reminder; null: no reminder.
  int? remind = 2;

  @override
  Widget build(BuildContext context) {
    if (saved) {
      return Surface(
        color: Sofra.mint,
        child: Text(
          'حطينا ${formatAmount(servings)} حصة في التلاجة، هتلاقيها في الميكروويف لما تحب تسخنها.',
          key: const ValueKey('leftovers-saved'),
          textAlign: TextAlign.center,
        ),
      );
    }
    Widget step(String key, IconData icon, double by) => IconButton.filledTonal(
      key: ValueKey(key),
      icon: Icon(icon),
      onPressed: () => setState(
        () =>
            servings = (servings + by).clamp(0, widget.maxServings.toDouble()),
      ),
    );
    return Surface(
      child: Column(
        children: [
          const Text(
            'فضل أكل؟',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'سجّله ونحطه في التلاجة عشان تسخنه بعدين.',
            style: TextStyle(color: Sofra.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              step('leftover-less', Icons.remove_rounded, -.5),
              SizedBox(
                width: 96,
                child: Text(
                  '${formatAmount(servings)} حصة',
                  key: const ValueKey('leftover-servings'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              step('leftover-more', Icons.add_rounded, .5),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'فكّرني بيها بعد',
            style: TextStyle(color: Sofra.muted, fontSize: 13),
          ),
          Wrap(
            spacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final d in const [null, 1, 2, 3, 4, 5])
                ChoiceChip(
                  key: ValueKey('leftover-remind-${d ?? 0}'),
                  label: Text(
                    d == null
                        ? 'من غير'
                        : d == 1
                        ? 'يوم'
                        : '$d أيام',
                  ),
                  selected: remind == d,
                  onSelected: (_) => setState(() => remind = d),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const ValueKey('save-leftovers'),
            onPressed: servings <= 0
                ? null
                : () async {
                    final ok = await SofraScope.controllerOf(context)
                        .saveLeftovers(
                          widget.name,
                          servings,
                          remindAfterDays: remind,
                        );
                    if (ok && mounted) setState(() => saved = true);
                  },
            child: const Text('حطه في التلاجة'),
          ),
        ],
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({required this.check});
  final CookingCheck check;

  @override
  Widget build(BuildContext context) {
    final deduct = check.where(LineStock.inStock).toList();
    final partial = check.lines.where((l) => l.partial).toList();
    final kept = [
      ...check.where(LineStock.missing).where((l) => !l.partial),
      ...check.where(LineStock.unresolved),
    ];
    final unmeasured = check.where(LineStock.unmeasured).toList();
    String amount(CookingLine l) => l.quantity == null
        ? ''
        : l.partial
        ? 'عندك ${formatAmount(l.quantity! - l.missing!)} من ${formatAmount(l.quantity!)} ${l.ingredient.unit ?? ''}'
        : '${formatAmount(l.quantity!)} ${l.ingredient.unit ?? ''}';
    Widget group(
      String title,
      String note,
      List<CookingLine> lines,
      Color color,
    ) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
          Text(note, style: const TextStyle(fontSize: 11, color: Sofra.muted)),
          const SizedBox(height: 6),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.stockId == null
                          ? l.ingredient.name
                          : '${l.ingredient.name} · هنستخدم ${SofraScope.controllerOf(context).ingredientName(l.stockId!)}',
                    ),
                  ),
                  Text(amount(l), style: const TextStyle(color: Sofra.muted)),
                ],
              ),
            ),
        ],
      ),
    );
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'قبل ما نخصم من المخزون',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              if (deduct.isNotEmpty)
                group(
                  'هيتخصم',
                  'موجود عندك بنفس الوحدة',
                  deduct,
                  Sofra.greenDark,
                ),
              if (partial.isNotEmpty)
                group(
                  'هيتخصم اللي عندك بس',
                  'الباقي ناقص؛ لو جبته من برّه مش محتاج تسجله.',
                  partial,
                  Sofra.greenDark,
                ),
              if (kept.isNotEmpty)
                group(
                  'مش هيتخصم',
                  'ناقص أو متسجل بوحدة مختلفة. التكلفة هتبقى غير معروفة.',
                  kept,
                  const Color(0xFF995333),
                ),
              if (unmeasured.isNotEmpty)
                group(
                  'مش مقاس في الوصفة',
                  'زي «حسب الرغبة»، مش هيتخصم',
                  unmeasured,
                  Sofra.muted,
                ),
              const SizedBox(height: 20),
              DepthButton(
                key: const ValueKey('confirm-cooking'),
                label: 'تأكيد',
                onPressed: () => Navigator.pop(context, true),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('لسه'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
