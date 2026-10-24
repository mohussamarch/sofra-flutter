import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../domain/market_profile.dart';
import '../ui/design.dart';
import '../ui/illustrations.dart';
import 'common.dart';
import 'onboarding_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.signOut});
  final Future<void> Function()? signOut;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final p = c.profile;
    return ScreenBody(
      children: [
        const SizedBox(height: 8),
        Surface(
          color: Sofra.mint,
          child: Row(
            children: [
              const ChefArt(size: 92, compact: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.houseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 23,
                      ),
                    ),
                    const Text(
                      'كل بيت له طعم.. ودي سفرتك',
                      style: TextStyle(color: Sofra.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('أهل البيت'),
        Surface(
          child: Column(
            children: [
              summaryLine(
                Icons.person_outline_rounded,
                p.displayName,
                c.market.country == MarketCountry.egypt ? 'مصر' : 'السعودية',
              ),
              const Divider(height: 28, color: Sofra.line),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'عدد أفراد السفرة',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Counter(
                    value: p.servings,
                    onChanged: (v) =>
                        c.updateProfile((p) => p.copyWith(servings: v)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const CountryPicker(),
            ],
          ),
        ),
        const SectionTitle('ذوقك في الأكل'),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CuisineChips(),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'الوصفات السريعة الأول',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                value: p.quickMeals,
                onChanged: (v) =>
                    c.updateProfile((p) => p.copyWith(quickMeals: v)),
              ),
            ],
          ),
        ),
        const SectionTitle('حساسية الأكل'),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.allergies.isEmpty
                    ? 'مفيش حساسية مسجّلة'
                    : p.allergies.join('، '),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'بتظهر كتنبيه بالاسم بس، ولازم تراجع المكونات بنفسك.',
                style: TextStyle(fontSize: 12, color: Sofra.muted),
              ),
              TextButton(
                onPressed: () => nav.editOnboarding(4),
                child: const Text('تعديل الحساسية'),
              ),
            ],
          ),
        ),
        const SectionTitle('راحتك في التطبيق'),
        Surface(
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'تقليل الحركة',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'انتقالات أهدى من غير ارتداد',
              style: TextStyle(fontSize: 11),
            ),
            value: p.reduceMotion,
            onChanged: (v) =>
                c.updateProfile((p) => p.copyWith(reduceMotion: v)),
          ),
        ),
        const SizedBox(height: 24),
        if (c.persistent) ...[
          Center(
            child: Text(
              c.saving
                  ? 'جاري حفظ التغييرات…'
                  : c.saveError != null
                  ? 'في تغييرات لم تُحفظ'
                  : c.storeLabel,
              key: const ValueKey('save-status'),
              textAlign: TextAlign.center,
            ),
          ),
          if (signOut != null)
            Center(
              child: TextButton(
                onPressed: c.saving || c.saveError != null ? null : signOut,
                child: const Text('تسجيل الخروج'),
              ),
            ),
          const SizedBox(height: 12),
        ],
        DepthButton(
          secondary: true,
          label: 'راجع بيانات البيت',
          onPressed: () => nav.editOnboarding(1),
        ),
        const SizedBox(height: 22),
        const Center(
          child: Text(
            'سفرة  ·  معمول بحب للبيوت',
            style: TextStyle(color: Sofra.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
