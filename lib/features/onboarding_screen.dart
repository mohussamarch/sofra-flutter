import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../domain/market_profile.dart';
import '../ui/design.dart';
import '../ui/illustrations.dart';
import 'common.dart';

class CountryPicker extends StatelessWidget {
  const CountryPicker({super.key});
  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    return DropdownButtonFormField<MarketCountry>(
      key: const ValueKey('field-country'),
      isExpanded: true,
      initialValue: c.market.country,
      decoration: const InputDecoration(labelText: 'البلد'),
      items: const [
        DropdownMenuItem(
          value: MarketCountry.egypt,
          child: Text('مصر · جنيه مصري'),
        ),
        DropdownMenuItem(
          value: MarketCountry.saudi,
          child: Text('السعودية · ريال سعودي'),
        ),
      ],
      onChanged: (value) {
        if (value != null) c.setCountry(value);
      },
    );
  }
}

/// One choice in the setup: a value as saved, its label and its picture
/// (a flag code or an icon).
class _Opt {
  const _Opt(this.value, this.label, {this.icon, this.flag});
  final String value, label;
  final IconData? icon;
  final String? flag;
}

const _meals = [
  _Opt('فطار', 'فطار', icon: Icons.free_breakfast_rounded),
  _Opt('غداء', 'غداء', icon: Icons.lunch_dining_rounded),
  _Opt('عشاء', 'عشاء', icon: Icons.dinner_dining_rounded),
];

/// Conditions the user may say they have. Labels only: the app gives no
/// medical advice and filters nothing by them.
const _health = [
  _Opt('السكري', 'السكري', icon: Icons.bloodtype_rounded),
  _Opt('ضغط الدم المرتفع', 'ضغط الدم', icon: Icons.monitor_heart_rounded),
  _Opt('الكوليسترول المرتفع', 'الكوليسترول', icon: Icons.water_drop_rounded),
  _Opt('السيلياك', 'السيلياك', icon: Icons.grain_rounded),
  _Opt('القولون العصبي', 'القولون العصبي', icon: Icons.healing_rounded),
  _Opt(
    'ارتجاع المريء',
    'ارتجاع المريء',
    icon: Icons.local_fire_department_rounded,
  ),
  _Opt('أمراض الكلى', 'الكلى', icon: Icons.medical_services_rounded),
  _Opt('النقرس', 'النقرس', icon: Icons.accessibility_new_rounded),
  _Opt('فقر الدم', 'فقر الدم', icon: Icons.opacity_rounded),
  _Opt('الحمل', 'الحمل', icon: Icons.pregnant_woman_rounded),
];

/// Foods to avoid; the recipe warning matches these names in ingredients.
const _avoid = [
  _Opt('ألبان', 'ألبان', icon: Icons.local_drink_rounded),
  _Opt('قمح', 'قمح', icon: Icons.bakery_dining_rounded),
  _Opt('بيض', 'بيض', icon: Icons.egg_rounded),
  _Opt('مكسرات', 'مكسرات', icon: Icons.eco_rounded),
  _Opt('سمك', 'سمك', icon: Icons.set_meal_rounded),
  _Opt('قشريات', 'قشريات', icon: Icons.set_meal_outlined),
  _Opt('سمسم', 'سمسم', icon: Icons.grain_rounded),
  _Opt('فول سوداني', 'فول سوداني', icon: Icons.spa_rounded),
];

/// Six-step setup (welcome, name, table, taste, health, ready); the step
/// index lives in the shell so profile screens can jump back to a step.
/// Each step shows few words: a picture per choice, two choices at most per
/// group on the page and the rest in a list.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.step,
    required this.onStep,
    required this.name,
    required this.house,
  });
  final int step;
  final ValueChanged<int> onStep;

  /// [house] is kept for the shell; setup no longer asks for a house name.
  final TextEditingController name, house;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final optional = step == 3 || step == 4;
    return Column(
      children: [
        if (step == 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.restaurant_rounded,
                  color: Sofra.accent,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text('سفرة', style: Sofra.heading(28)),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 16, 0),
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('onboarding-back'),
                  onPressed: () => onStep(step - 1),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'رجوع',
                ),
                const SizedBox(width: 4),
                Expanded(child: _Progress(step: step)),
                SizedBox(
                  width: 64,
                  child: optional
                      ? TextButton(
                          key: const ValueKey('onboarding-skip'),
                          onPressed: () => onStep(step + 1),
                          child: const Text('تخطي'),
                        )
                      : null,
                ),
              ],
            ),
          ),
        Expanded(
          child: ScreenBody(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            footer: DepthButton(
              key: const ValueKey('onboarding-next'),
              label: step == 0
                  ? 'ابدأ'
                  : step == 5
                  ? 'افتح سفرتي'
                  : 'متابعة',
              onPressed: step == 1 && name.text.trim().isEmpty
                  ? null
                  : () {
                      if (step == 5) {
                        c.updateProfile((p) => p.copyWith(onboarded: true));
                      } else {
                        onStep(step + 1);
                      }
                    },
            ),
            children: [
              AnimatedSwitcher(
                duration: Sofra.motion(context),
                switchInCurve: Sofra.calmCurve,
                child: KeyedSubtree(
                  key: ValueKey(step),
                  child: _body(context, c),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, SofraController c) {
    final p = c.profile;
    switch (step) {
      case 0:
        final egypt = c.market.country == MarketCountry.egypt;
        return Column(
          children: [
            const SizedBox(height: 8),
            const Center(child: ChefArt(size: 250)),
            const SizedBox(height: 16),
            Text(
              'كل ما في مطبخك\nيصنع أكلة طيبة',
              textAlign: TextAlign.center,
              style: Sofra.heading(32),
            ),
            const SizedBox(height: 32),
            _TileRow([
              _Tile(
                key: const ValueKey('country-egypt'),
                opt: const _Opt('egypt', 'مصر', flag: 'egyptian'),
                selected: egypt,
                onTap: () => c.setCountry(MarketCountry.egypt),
              ),
              _Tile(
                key: const ValueKey('country-saudi'),
                opt: const _Opt('saudi', 'السعودية', flag: 'saudi'),
                selected: !egypt,
                onTap: () => c.setCountry(MarketCountry.saudi),
              ),
            ]),
          ],
        );
      case 1:
        final typed = name.text.trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Hero(icon: Icons.waving_hand_rounded, title: 'ما اسمك؟'),
            const SizedBox(height: 32),
            Center(
              child: AnimatedContainer(
                duration: Sofra.motion(context, true),
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: typed.isEmpty ? Sofra.sand : Sofra.accentTint,
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: Sofra.motion(context, true),
                  child: typed.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          key: ValueKey('empty'),
                          size: 56,
                          color: Sofra.muted,
                        )
                      : Text(
                          typed.characters.first,
                          key: ValueKey(typed.characters.first),
                          style: Sofra.heading(48, color: Sofra.accent),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              key: const ValueKey('field-name'),
              controller: name,
              textInputAction: TextInputAction.done,
              maxLength: 30,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              onChanged: (v) => c.updateProfile((p) => p.copyWith(name: v)),
              decoration: const InputDecoration(
                hintText: 'مثلًا: مريم',
                counterText: '',
              ),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Hero(icon: Icons.groups_rounded, title: 'لكم شخصًا تطبخ؟'),
            const SizedBox(height: 24),
            Surface(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
              child: Column(
                children: [
                  _People(count: p.servings),
                  const SizedBox(height: 20),
                  Counter(
                    value: p.servings,
                    onChanged: (v) =>
                        c.updateProfile((p) => p.copyWith(servings: v)),
                  ),
                ],
              ),
            ),
            const _Label('وجباتك'),
            _TileRow([
              for (final m in _meals)
                _Tile(
                  key: ValueKey('meal-${m.value}'),
                  opt: m,
                  selected: p.meals.contains(m.value),
                  onTap: () => c.updateProfile(
                    (p) => p.copyWith(meals: _toggle(p.meals, m.value)),
                  ),
                ),
            ]),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Hero(
              icon: Icons.restaurant_menu_rounded,
              title: 'ما المطابخ التي تحبها؟',
            ),
            const SizedBox(height: 24),
            const _CuisineRow(),
            const SizedBox(height: 24),
            _QuickMeals(
              value: p.quickMeals,
              onChanged: (v) =>
                  c.updateProfile((p) => p.copyWith(quickMeals: v)),
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Hero(
              icon: Icons.health_and_safety_rounded,
              title: 'نراعي صحتك',
            ),
            const _Label('حالتك الصحية'),
            _ChoiceRow(
              id: 'health',
              title: 'حالتك الصحية',
              options: _health,
              selected: p.health,
              customIcon: Icons.medical_services_rounded,
              onChanged: (v) => c.updateProfile((p) => p.copyWith(health: v)),
            ),
            const _Note(
              Icons.lock_outline_rounded,
              'تُحفظ في ملفك فقط، ولا تغني عن طبيبك.',
            ),
            const _Label('أطعمة تتجنبها'),
            _ChoiceRow(
              id: 'allergy',
              title: 'أطعمة تتجنبها',
              options: _avoid,
              selected: p.allergies,
              customIcon: Icons.no_food_rounded,
              onChanged: (v) =>
                  c.updateProfile((p) => p.copyWith(allergies: v)),
            ),
            const _Note(
              Icons.info_outline_rounded,
              'ننبهك إذا ظهرت في وصفة. راجع العبوات بنفسك.',
            ),
          ],
        );
      default:
        final cares = p.health.length + p.allergies.length;
        return Column(
          children: [
            const Center(child: ChefArt(size: 220, celebrate: true)),
            const SizedBox(height: 8),
            Text(
              'أهلًا ${p.displayName}!',
              textAlign: TextAlign.center,
              style: Sofra.heading(30),
            ),
            const SizedBox(height: 4),
            const Text(
              'سفرتك جاهزة',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Sofra.muted),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                for (final (icon, value, label) in [
                  (Icons.groups_rounded, p.servings, 'أشخاص'),
                  (Icons.restaurant_rounded, p.meals.length, 'وجبات'),
                  (Icons.public_rounded, p.cuisines.length, 'مطابخ'),
                  (Icons.health_and_safety_rounded, cares, 'للانتباه'),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _Stat(icon: icon, value: value, label: label),
                    ),
                  ),
              ],
            ),
          ],
        );
    }
  }
}

Set<String> _toggle(Set<String> set, String value) =>
    set.contains(value) ? ({...set}..remove(value)) : {...set, value};

/// Five segments that fill from the start side, one per step.
class _Progress extends StatelessWidget {
  const _Progress({required this.step});
  final int step;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'الخطوة $step من 5',
    child: Row(
      children: [
        for (var i = 1; i <= 5; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: Sofra.motion(context),
              curve: Sofra.calmCurve,
              height: 6,
              decoration: BoxDecoration(
                color: i <= step ? Sofra.accent : Sofra.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// The step's picture and question; nothing else.
class _Hero extends StatelessWidget {
  const _Hero({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Sofra.accentTint,
          borderRadius: BorderRadius.circular(Sofra.r22),
        ),
        child: Icon(icon, color: Sofra.accent, size: 34),
      ),
      const SizedBox(height: 16),
      Text(title, style: Sofra.heading(30)),
    ],
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 32, bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Sofra.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Sofra.muted),
          ),
        ),
      ],
    ),
  );
}

/// Equal tiles across the width.
class _TileRow extends StatelessWidget {
  const _TileRow(this.children);
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ],
    ),
  );
}

/// A picture with its name; selected tiles take the accent and a check.
class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.opt,
    required this.selected,
    required this.onTap,
  });
  final _Opt opt;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Sofra.r22);
    return Semantics(
      button: true,
      selected: selected,
      label: opt.label,
      excludeSemantics: true,
      child: PressScale(
        child: AnimatedContainer(
          duration: Sofra.motion(context, true),
          curve: Sofra.quickCurve,
          decoration: BoxDecoration(
            color: selected ? Sofra.accentTint : Sofra.surface,
            borderRadius: radius,
            border: Border.all(
              color: selected ? Sofra.accent : Sofra.line,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected ? null : Sofra.shadow(.5),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 18, 8, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Picture(opt: opt, selected: selected),
                        const SizedBox(height: 10),
                        Text(
                          opt.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: selected ? Sofra.accentDark : Sofra.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: Sofra.motion(context, true),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Sofra.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The tile's picture: a flag badge or an icon on a soft disc.
class _Picture extends StatelessWidget {
  const _Picture({required this.opt, required this.selected});
  final _Opt opt;
  final bool selected;
  static const size = 48.0;
  @override
  Widget build(BuildContext context) {
    final flag = opt.flag;
    if (flag != null && _Flag.known(flag)) return _Flag(flag, size: size);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? Colors.white : Sofra.accentTint,
      ),
      child: Icon(
        opt.icon ?? Icons.restaurant_rounded,
        size: 26,
        color: Sofra.accent,
      ),
    );
  }
}

/// "More": opens the full list; counts chosen items not shown on the page.
class _MoreTile extends StatelessWidget {
  const _MoreTile({super.key, required this.hidden, required this.onTap});
  final int hidden;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Sofra.r22);
    return Semantics(
      button: true,
      label: hidden > 0 ? 'المزيد، $hidden مختارة' : 'المزيد',
      excludeSemantics: true,
      child: PressScale(
        child: Material(
          color: Sofra.sand.withValues(alpha: .55),
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 18, 8, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: _Picture.size,
                    height: _Picture.size,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    alignment: Alignment.center,
                    child: hidden > 0
                        ? Text(
                            '+$hidden',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Sofra.accent,
                            ),
                          )
                        : const Icon(
                            Icons.add_rounded,
                            size: 28,
                            color: Sofra.ink,
                          ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'المزيد',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two choices on the page (chosen ones first) and the rest in a list.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.id,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.customIcon,
  });
  final String id, title;
  final List<_Opt> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  /// Set when the user may add a name that is not in [options].
  final IconData? customIcon;

  List<_Opt> get _all => [
    ...options,
    for (final v in selected)
      if (!options.any((o) => o.value == v)) _Opt(v, v, icon: customIcon),
  ];

  @override
  Widget build(BuildContext context) {
    final all = _all;
    final shown = [
      ...all.where((o) => selected.contains(o.value)),
      ...all.where((o) => !selected.contains(o.value)),
    ].take(2).toList();
    final hidden = selected
        .where((v) => !shown.any((o) => o.value == v))
        .length;
    return _TileRow([
      for (final o in shown)
        _Tile(
          key: ValueKey('$id-${o.value}'),
          opt: o,
          selected: selected.contains(o.value),
          onTap: () => onChanged(_toggle(selected, o.value)),
        ),
      _MoreTile(
        key: ValueKey('more-$id'),
        hidden: hidden,
        onTap: () => _PickerSheet.show(
          context,
          id: id,
          title: title,
          options: options,
          customIcon: customIcon,
          selected: (p) => switch (id) {
            'health' => p.health,
            'allergy' => p.allergies,
            _ => p.cuisines,
          },
          onChanged: onChanged,
        ),
      ),
    ]);
  }
}

/// The catalog's cuisines: two on the page (the country's own first).
class _CuisineRow extends StatelessWidget {
  const _CuisineRow();
  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: c.recipes.cuisineGroups,
      builder: (context, snap) {
        final groups = snap.data;
        if (groups == null) return const LoadingBlock();
        final home = c.market.country == MarketCountry.egypt
            ? const ['egyptian', 'levantine']
            : const ['saudi', 'levantine'];
        final options =
            [
              for (final id in home)
                for (final g in groups)
                  if (g['id'] == id) g,
              for (final g in groups)
                if (!home.contains(g['id'])) g,
            ].map((g) {
              final id = g['id'] as String;
              return _Opt(
                id,
                '${g['name']}',
                flag: id,
                icon: id == 'other'
                    ? Icons.public_rounded
                    : Icons.kebab_dining_rounded,
              );
            }).toList();
        return _ChoiceRow(
          id: 'cuisine',
          title: 'المطابخ',
          options: options,
          selected: c.profile.cuisines,
          onChanged: (v) => c.updateProfile((p) => p.copyWith(cuisines: v)),
        );
      },
    );
  }
}

/// Every choice of a group, searchable; with [customIcon], a name that is
/// not listed can be added.
class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.id,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.customIcon,
  });
  final String id, title;
  final List<_Opt> options;
  final Set<String> Function(Profile) selected;
  final ValueChanged<Set<String>> onChanged;
  final IconData? customIcon;

  static Future<void> show(
    BuildContext context, {
    required String id,
    required String title,
    required List<_Opt> options,
    required Set<String> Function(Profile) selected,
    required ValueChanged<Set<String>> onChanged,
    IconData? customIcon,
  }) {
    final scope = SofraScope.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Sofra.paper,
      barrierColor: const Color(0x990D0A08),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Sofra.r28)),
      ),
      builder: (_) => SofraScope(
        controller: scope.notifier!,
        nav: scope.nav,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _PickerSheet(
            id: id,
            title: title,
            options: options,
            selected: selected,
            onChanged: onChanged,
            customIcon: customIcon,
          ),
        ),
      ),
    );
  }

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final query = TextEditingController();

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final selected = widget.selected(c.profile);
    final q = query.text.trim();
    final all = [
      ...widget.options,
      for (final v in selected)
        if (!widget.options.any((o) => o.value == v))
          _Opt(v, v, icon: widget.customIcon),
    ];
    final shown = all.where((o) => o.label.contains(q) || o.value.contains(q));
    final canAdd =
        widget.customIcon != null &&
        q.isNotEmpty &&
        !all.any((o) => o.value == q || o.label == q);
    final tiles = [
      for (final o in shown)
        _Tile(
          key: ValueKey('${widget.id}-${o.value}'),
          opt: o,
          selected: selected.contains(o.value),
          onTap: () => widget.onChanged(_toggle(selected, o.value)),
        ),
      if (canAdd)
        _Tile(
          key: ValueKey('add-${widget.id}'),
          opt: _Opt(q, 'إضافة «$q»', icon: Icons.add_rounded),
          selected: false,
          onTap: () {
            widget.onChanged({...selected, q});
            query.clear();
            setState(() {});
          },
        ),
    ];
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * .85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Text(widget.title, style: Sofra.heading(24)),
            ),
            if (all.length > 6 || widget.customIcon != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: TextField(
                  key: ValueKey('field-${widget.id}-search'),
                  controller: query,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: widget.customIcon != null
                        ? 'ابحث أو اكتب اسمًا'
                        : 'ابحث',
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ),
            // Rows of three that size to their tallest tile (labels may wrap,
            // text may be enlarged).
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                children: [
                  for (var i = 0; i < tiles.length; i += 3)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TileRow([
                        for (var j = i; j < i + 3; j++)
                          j < tiles.length ? tiles[j] : const SizedBox(),
                      ]),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              child: DepthButton(
                key: const ValueKey('picker-done'),
                label: 'تم',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row of people that grows with the count (eight shown, then +N).
class _People extends StatelessWidget {
  const _People({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    final shown = math.min(count, 8);
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < shown; i++)
            TweenAnimationBuilder<double>(
              key: ValueKey(i),
              tween: Tween(begin: 0, end: 1),
              duration: Sofra.motion(context, true),
              curve: Curves.easeOutBack,
              builder: (_, t, child) => Transform.scale(scale: t, child: child),
              child: Icon(
                Icons.person_rounded,
                size: 36,
                color: Color.lerp(Sofra.accent, Sofra.sage, i / 8),
              ),
            ),
          if (count > shown)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4),
              child: Text(
                '+${count - shown}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Sofra.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickMeals extends StatelessWidget {
  const _QuickMeals({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Sofra.accentTint,
          ),
          child: const Icon(Icons.bolt_rounded, color: Sofra.accent),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'السريعة أولًا',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        Switch.adaptive(
          key: const ValueKey('quick-meals'),
          value: value,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final int value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: Sofra.surface,
      borderRadius: BorderRadius.circular(Sofra.r22),
      boxShadow: Sofra.shadow(.5),
    ),
    child: Column(
      children: [
        Icon(icon, color: Sofra.accent, size: 26),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Sofra.muted),
        ),
      ],
    ),
  );
}

/// A simplified round flag for a country or cuisine; [known] says whether
/// one is drawn for [code].
class _Flag extends StatelessWidget {
  const _Flag(this.code, {required this.size});
  final String code;
  final double size;

  static bool known(String code) => _FlagPainter.drawn.contains(code);

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Sofra.line, width: 1.5),
    ),
    child: ClipOval(child: CustomPaint(painter: _FlagPainter(code))),
  );
}

class _FlagPainter extends CustomPainter {
  const _FlagPainter(this.code);
  final String code;

  static const drawn = {
    'egyptian',
    'saudi',
    'moroccan',
    'italian',
    'french',
    'greek',
    'spanish',
    'turkish',
    'chinese',
    'japanese',
    'indian',
    'thai',
    'korean',
    'mexican',
  };

  void _bands(Canvas c, Size s, List<Color> colors, {bool vertical = false}) {
    final total = colors.length;
    for (var i = 0; i < total; i++) {
      final paint = Paint()..color = colors[i];
      c.drawRect(
        vertical
            ? Rect.fromLTWH(s.width * i / total, 0, s.width / total, s.height)
            : Rect.fromLTWH(0, s.height * i / total, s.width, s.height / total),
        paint,
      );
    }
  }

  Path _star(Offset o, double r, {double inner = .4}) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = o + Offset(math.cos(a) * radius, math.sin(a) * radius);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size s) {
    final mid = s.center(Offset.zero);
    final w = s.width;
    switch (code) {
      case 'egyptian':
        _bands(canvas, s, const [
          Color(0xFFCE1126),
          Colors.white,
          Color(0xFF111111),
        ]);
        canvas.drawCircle(
          mid,
          w * .09,
          Paint()..color = const Color(0xFFC09300),
        );
      case 'saudi':
        canvas.drawColor(const Color(0xFF006C35), BlendMode.src);
        final white = Paint()
          ..color = Colors.white
          ..strokeWidth = w * .05
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(w * .25, s.height * .62),
          Offset(w * .75, s.height * .62),
          white,
        );
        for (var i = 0; i < 4; i++) {
          canvas.drawCircle(
            Offset(w * (.3 + i * .13), s.height * .42),
            w * .035,
            white,
          );
        }
      case 'moroccan':
        canvas.drawColor(const Color(0xFFC1272D), BlendMode.src);
        canvas.drawPath(
          _star(mid, w * .26, inner: .38),
          Paint()
            ..color = const Color(0xFF006233)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * .05,
        );
      case 'italian':
        _bands(canvas, s, const [
          Color(0xFF009246),
          Colors.white,
          Color(0xFFCE2B37),
        ], vertical: true);
      case 'french':
        _bands(canvas, s, const [
          Color(0xFF0055A4),
          Colors.white,
          Color(0xFFEF4135),
        ], vertical: true);
      case 'greek':
        const blue = Color(0xFF0D5EAF);
        _bands(canvas, s, [
          for (var i = 0; i < 9; i++) i.isEven ? blue : Colors.white,
        ]);
        final box = Rect.fromLTWH(0, 0, w * .45, s.height * 5 / 9);
        canvas.drawRect(box, Paint()..color = blue);
        final white = Paint()..color = Colors.white;
        canvas.drawRect(
          Rect.fromCenter(
            center: box.center,
            width: box.width,
            height: s.height / 9,
          ),
          white,
        );
        canvas.drawRect(
          Rect.fromCenter(center: box.center, width: w / 9, height: box.height),
          white,
        );
      case 'spanish':
        _bands(canvas, s, const [
          Color(0xFFAA151B),
          Color(0xFFF1BF00),
          Color(0xFFF1BF00),
          Color(0xFFAA151B),
        ]);
      case 'turkish':
        canvas.drawColor(const Color(0xFFE30A17), BlendMode.src);
        final white = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(w * .42, s.height / 2), w * .24, white);
        canvas.drawCircle(
          Offset(w * .48, s.height / 2),
          w * .19,
          Paint()..color = const Color(0xFFE30A17),
        );
        canvas.drawPath(_star(Offset(w * .7, s.height / 2), w * .1), white);
      case 'chinese':
        canvas.drawColor(const Color(0xFFDE2910), BlendMode.src);
        final gold = Paint()..color = const Color(0xFFFFDE00);
        canvas.drawPath(_star(Offset(w * .4, s.height * .42), w * .2), gold);
        for (final (dx, dy) in const [(.68, .2), (.78, .36), (.78, .56)]) {
          canvas.drawPath(_star(Offset(w * dx, s.height * dy), w * .06), gold);
        }
      case 'japanese':
        canvas.drawColor(Colors.white, BlendMode.src);
        canvas.drawCircle(
          mid,
          w * .24,
          Paint()..color = const Color(0xFFBC002D),
        );
      case 'indian':
        _bands(canvas, s, const [
          Color(0xFFFF9933),
          Colors.white,
          Color(0xFF138808),
        ]);
        canvas.drawCircle(
          mid,
          w * .11,
          Paint()
            ..color = const Color(0xFF000080)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * .03,
        );
      case 'thai':
        const red = Color(0xFFA51931), white = Color(0xFFF4F5F8);
        _bands(canvas, s, const [
          red,
          white,
          Color(0xFF2D2A4A),
          Color(0xFF2D2A4A),
          white,
          red,
        ]);
      case 'korean':
        canvas.drawColor(Colors.white, BlendMode.src);
        final r = w * .22;
        final box = Rect.fromCircle(center: mid, radius: r);
        canvas.drawArc(
          box,
          math.pi,
          math.pi,
          true,
          Paint()..color = const Color(0xFFCD2E3A),
        );
        canvas.drawArc(
          box,
          0,
          math.pi,
          true,
          Paint()..color = const Color(0xFF0047A0),
        );
        canvas.drawCircle(
          mid - Offset(r / 2, 0),
          r / 2,
          Paint()..color = const Color(0xFFCD2E3A),
        );
        canvas.drawCircle(
          mid + Offset(r / 2, 0),
          r / 2,
          Paint()..color = const Color(0xFF0047A0),
        );
        final black = Paint()
          ..color = Colors.black
          ..strokeWidth = w * .035;
        for (final (a, b) in [
          (Offset(w * .12, s.height * .2), Offset(w * .26, s.height * .1)),
          (Offset(w * .74, s.height * .1), Offset(w * .88, s.height * .2)),
          (Offset(w * .12, s.height * .8), Offset(w * .26, s.height * .9)),
          (Offset(w * .74, s.height * .9), Offset(w * .88, s.height * .8)),
        ]) {
          canvas.drawLine(a, b, black);
        }
      case 'mexican':
        _bands(canvas, s, const [
          Color(0xFF006847),
          Colors.white,
          Color(0xFFCE1126),
        ], vertical: true);
        canvas.drawCircle(
          mid,
          w * .08,
          Paint()..color = const Color(0xFF8C5A2B),
        );
    }
  }

  @override
  bool shouldRepaint(_FlagPainter old) => old.code != code;
}

/// The fifteen primary catalog cuisines plus "other", as selectable chips.
class CuisineChips extends StatelessWidget {
  const CuisineChips({super.key});
  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: c.recipes.cuisineGroups,
      builder: (context, snap) {
        final groups = snap.data;
        if (groups == null) return const LoadingBlock();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in groups)
              SofraChip(
                key: ValueKey('cuisine-${g['id']}'),
                label: Text('${g['name']}'),
                selected: c.profile.cuisines.contains(g['id']),
                selectedColor: Sofra.accentTint,
                onSelected: (_) => c.updateProfile(
                  (p) => p.copyWith(
                    cuisines: _toggle(p.cuisines, g['id'] as String),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
