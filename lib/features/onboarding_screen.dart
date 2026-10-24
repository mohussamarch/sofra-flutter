import 'package:flutter/material.dart';

import '../app/scope.dart';
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

/// Five-step household setup; the step index lives in the shell so profile
/// screens can jump back to a specific step.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.step,
    required this.onStep,
    required this.name,
    required this.house,
  });
  final int step;
  final ValueChanged<int> onStep;
  final TextEditingController name, house;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final allergySearch = TextEditingController();

  @override
  void dispose() {
    allergySearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final step = widget.step;
    final optional = step == 3 || step == 4;
    return Column(
      children: [
        if (step == 0)
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Icon(Icons.restaurant_rounded, color: Sofra.green, size: 25),
                SizedBox(width: 8),
                Text(
                  'سفرة',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
                ),
                Spacer(),
                SoftTag('من البيت.. للبيت', color: Sofra.peach, ink: Sofra.ink),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('onboarding-back'),
                  onPressed: () => widget.onStep(step - 1),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'رجوع',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: step / 5,
                      minHeight: 10,
                      backgroundColor: Sofra.line,
                      color: Sofra.green,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '$step / 5',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Sofra.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (optional)
                  TextButton(
                    key: const ValueKey('onboarding-skip'),
                    onPressed: () => widget.onStep(step + 1),
                    child: const Text('تخطي'),
                  ),
              ],
            ),
          ),
        Expanded(
          child: ScreenBody(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            footer: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DepthButton(
                  key: const ValueKey('onboarding-next'),
                  label: step == 0
                      ? 'يلا نجهّز سفرتك'
                      : step == 5
                      ? 'افتح سفرتي'
                      : 'كمّل',
                  onPressed: step == 1 && widget.name.text.trim().isEmpty
                      ? null
                      : () {
                          if (step == 5) {
                            c.updateProfile((p) => p.copyWith(onboarded: true));
                          } else {
                            widget.onStep(step + 1);
                          }
                        },
                ),
                const SizedBox(height: 10),
                Text(
                  step == 0
                      ? 'خطوات صغيرة.. وطبخ أسهل كل يوم'
                      : step == 5
                      ? 'تقدر تعدّل اختياراتك من «بيتي» في أي وقت'
                      : 'على راحتك، تقدر ترجع وتغيّر أي اختيار',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Sofra.muted),
                ),
              ],
            ),
            children: [
              AnimatedSwitcher(
                duration: Sofra.motion(context),
                child: KeyedSubtree(key: ValueKey(step), child: _body(step)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _body(int step) {
    final c = SofraScope.controllerOf(context);
    final p = c.profile;
    switch (step) {
      case 0:
        return const Column(
          children: [
            SizedBox(height: 28),
            ChefArt(size: 290),
            SizedBox(height: 18),
            SoftTag(
              'أهلًا بيك في سفرة',
              color: Sofra.peach,
              ink: Color(0xFF995333),
            ),
            SizedBox(height: 18),
            Text(
              'كل اللي في بيتك،\nيعمل أكلة حلوة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: Sofra.ink,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'نعرف الموجود، نفكّر سوا، ونطبخ على قدّنا.\nمن غير حيرة «هناكل إيه النهاردة؟»',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Sofra.muted, height: 1.6),
            ),
            SizedBox(height: 24),
            CountryPicker(),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            introBlock(
              'نتعرف الأول؟',
              'الاسم المناسب لك، واسم البيت لو حابب. مناسب لشخص واحد أو أكتر.',
              icon: Icons.waving_hand_outlined,
            ),
            const SizedBox(height: 24),
            const Text('اسمك', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('field-name'),
              controller: widget.name,
              textInputAction: TextInputAction.next,
              maxLength: 30,
              onChanged: (v) => c.updateProfile((p) => p.copyWith(name: v)),
              decoration: const InputDecoration(
                hintText: 'مثلًا: مريم',
                counterText: '',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'اسم البيت  ·  اختياري',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('field-house'),
              controller: widget.house,
              maxLength: 35,
              onChanged: (v) => c.updateProfile((p) => p.copyWith(house: v)),
              decoration: const InputDecoration(
                hintText: 'بيتي',
                counterText: '',
                prefixIcon: Icon(Icons.home_outlined),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            introBlock(
              'كام حد على السفرة؟',
              'هنظبط كميات الوصفات على عددكم، وتقدر تغيّره لكل طبخة.',
              icon: Icons.groups_outlined,
            ),
            const SizedBox(height: 24),
            Surface(
              color: Sofra.mint,
              child: Column(
                children: [
                  Counter(
                    value: p.servings,
                    onChanged: (v) =>
                        c.updateProfile((p) => p.copyWith(servings: v)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أفراد في البيت',
                    style: TextStyle(color: Sofra.muted),
                  ),
                ],
              ),
            ),
            const SectionTitle('غالبًا بتطبخوا إيه في البيت؟'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final meal in const ['فطار', 'غدا', 'عشا'])
                  FilterChip(
                    label: Text(meal),
                    selected: p.meals.contains(meal),
                    selectedColor: Sofra.mint,
                    onSelected: (_) => c.updateProfile(
                      (p) => p.copyWith(meals: _toggle(p.meals, meal)),
                    ),
                  ),
              ],
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            introBlock(
              'طعم البيت عندك إيه؟',
              'اختار المطابخ اللي بتحبوها، ممكن أكتر من مطبخ.',
              icon: Icons.restaurant_menu_rounded,
            ),
            const SizedBox(height: 24),
            const CuisineChips(),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'بحب الأكلات السريعة',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'خلّي الوصفات القصيرة تظهر الأول',
                style: TextStyle(fontSize: 12),
              ),
              value: p.quickMeals,
              onChanged: (v) =>
                  c.updateProfile((p) => p.copyWith(quickMeals: v)),
            ),
          ],
        );
      case 4:
        const choices = [
          'بيض',
          'ألبان',
          'مكسرات',
          'قمح',
          'سمك',
          'سمسم',
          'فول سوداني',
        ];
        final query = allergySearch.text.trim();
        final filtered = {
          ...choices,
          ...p.allergies,
        }.where((v) => v.contains(query)).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            introBlock(
              'في حاجة ناخد بالنا منها؟',
              'لو عندكم حساسية من مكوّن، سجّلها هنا. الخطوة دي اختيارية.',
              icon: Icons.favorite_border_rounded,
            ),
            const SizedBox(height: 22),
            TextField(
              key: const ValueKey('field-allergy-search'),
              controller: allergySearch,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'دوّر على مكوّن أو اكتب اسمه',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final item in filtered)
                  FilterChip(
                    key: ValueKey('allergy-$item'),
                    label: Text(item),
                    selected: p.allergies.contains(item),
                    selectedColor: Sofra.peach,
                    onSelected: (_) => c.updateProfile(
                      (p) => p.copyWith(allergies: _toggle(p.allergies, item)),
                    ),
                  ),
              ],
            ),
            if (query.isNotEmpty &&
                !choices.contains(query) &&
                !p.allergies.contains(query))
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: DepthButton(
                  secondary: true,
                  label: 'إضافة «$query»',
                  onPressed: () {
                    c.updateProfile(
                      (p) => p.copyWith(allergies: {...p.allergies, query}),
                    );
                    allergySearch.clear();
                  },
                ),
              ),
            const SizedBox(height: 24),
            const Surface(
              color: Sofra.peach,
              padding: EdgeInsets.all(16),
              child: Text(
                'هننبهك لما اسم مكوّن في الوصفة يطابق اللي سجلته. راجع كل وصفة وعبوات المكونات بنفسك؛ التنبيه مش ضمان إن الأكل خالي من مسببات الحساسية.',
                style: TextStyle(fontSize: 12, color: Color(0xFF79513D)),
              ),
            ),
          ],
        );
      default:
        return Column(
          children: [
            const SizedBox(height: 12),
            const ChefArt(size: 250, celebrate: true),
            Text(
              'يا أهلًا يا ${p.displayName}!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'سفرتك جاهزة تتفتح. نبدأ بالموجود عندك،\nحتى لو 3 مكونات بس.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Sofra.muted, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Surface(
              child: Column(
                children: [
                  summaryLine(
                    Icons.home_outlined,
                    p.houseName,
                    c.market.country == MarketCountry.egypt
                        ? 'مصر'
                        : 'السعودية',
                  ),
                  const Divider(height: 28, color: Sofra.line),
                  summaryLine(
                    Icons.groups_outlined,
                    '${p.servings} أفراد',
                    p.meals.join(' · '),
                  ),
                  const Divider(height: 28, color: Sofra.line),
                  summaryLine(
                    Icons.favorite_border_rounded,
                    'حساسية مسجّلة',
                    p.allergies.isEmpty ? 'لا يوجد' : p.allergies.join('، '),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}

Set<String> _toggle(Set<String> set, String value) =>
    set.contains(value) ? ({...set}..remove(value)) : {...set, value};

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
              FilterChip(
                key: ValueKey('cuisine-${g['id']}'),
                label: Text('${g['name']}'),
                selected: c.profile.cuisines.contains(g['id']),
                selectedColor: Sofra.mint,
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
