import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../domain/market_profile.dart';
import '../ui/design.dart';
import '../ui/illustrations.dart';
import 'common.dart';
import 'onboarding_screen.dart';
import 'reminder_settings.dart';

/// "بروفايلي": the household, its taste and allergies. App settings live in
/// [SettingsScreen].
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                      'لكل بيت طعمه، وهذه سفرتك',
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
                    ? 'لا توجد حساسية مسجّلة'
                    : p.allergies.join('، '),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'تظهر كتنبيه بالاسم فقط، ويجب أن تراجع المكونات بنفسك.',
                style: TextStyle(fontSize: 12, color: Sofra.muted),
              ),
              TextButton(
                onPressed: () => nav.editOnboarding(4),
                child: const Text('تعديل الحساسية'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        DepthButton(
          secondary: true,
          label: 'راجع بيانات البيت',
          onPressed: () => nav.editOnboarding(1),
        ),
      ],
    );
  }
}

/// "الإعدادات": country, motion, saving and the account.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.signOut});
  final Future<void> Function()? signOut;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final p = c.profile;
    final nav = SofraScope.navOf(context);
    return ScreenBody(
      children: [
        const SizedBox(height: 8),
        _AccountCard(
          name: p.houseName,
          initial: p.name.trim(),
          onTap: () => nav.goTab(AppTab.profile),
        ),
        const SectionTitle('البلد والعملة'),
        const Surface(child: CountryPicker()),
        const SectionTitle('راحتك في التطبيق'),
        Surface(
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'تقليل الحركة',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'انتقالات أهدأ دون ارتداد',
              style: TextStyle(fontSize: 11),
            ),
            value: p.reduceMotion,
            onChanged: (v) =>
                c.updateProfile((p) => p.copyWith(reduceMotion: v)),
          ),
        ),
        const SectionTitle('التذكيرات'),
        const ReminderSettings(),
        const SizedBox(height: 24),
        if (c.persistent) ...[
          Center(
            child: Text(
              c.saving
                  ? 'جاري حفظ التغييرات…'
                  : c.saveError != null
                  ? 'توجد تغييرات لم تُحفظ'
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
        const SizedBox(height: 22),
        const Center(
          child: Text(
            'سفرة · صُنع بحب للبيوت',
            style: TextStyle(color: Sofra.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// The account, on its own at the top of settings and set apart from the
/// setting rows below it: a dark card with the person's initial.
class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.initial,
    required this.onTap,
  });

  final String name, initial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shown = name.trim().isEmpty ? 'حسابي' : name.trim();
    return Material(
      color: Sofra.ink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sofra.r22),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('settings-profile'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Sofra.accentTint,
                  shape: BoxShape.circle,
                ),
                child: initial.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        color: Sofra.accent,
                        size: 30,
                      )
                    : Text(
                        initial.characters.first,
                        style: const TextStyle(
                          color: Sofra.accent,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shown,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'حسابك وتفضيلات بيتك',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
