import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../app/scope.dart';
import '../domain/market_profile.dart';
import '../ui/brand_logo.dart';
import '../ui/design.dart';
import '../ui/illustrations.dart';
import 'common.dart';
import 'library_settings.dart';
import 'look_settings.dart';
import 'onboarding_screen.dart';
import 'place_picker.dart';
import 'reminder_settings.dart';

/// "حسابي": the household, its taste, meals, allergies and health notes.
/// Each choice group shows only what is chosen; the rest wait in an «أضف»
/// menu. App settings live in [SettingsScreen].
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final p = c.profile;
    final t = context.l10n;
    final country = c.market.country == MarketCountry.egypt
        ? t.profCountryEgypt
        : t.profCountrySaudi;
    return ScreenBody(
      children: [
        const SizedBox(height: 8),
        _ProfileHeader(
          house: p.houseName,
          line: [
            p.displayName,
            country,
            if (p.area.trim().isNotEmpty) p.area.trim(),
          ].join(' · '),
          stats: [
            ('${p.servings}', t.profStatPeople),
            ('${p.meals.length}', t.profStatMealsDaily),
            ('${p.saved.length}', t.profStatSaved),
          ],
        ),
        SectionTitle(t.profHousehold),
        Surface(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              _InfoRow(
                key: const ValueKey('profile-house'),
                icon: Icons.home_rounded,
                label: t.profHouseName,
                value: p.houseName,
                onTap: () => _editText(
                  context,
                  title: t.profHouseName,
                  initial: p.house,
                  hint: t.profHouseHint(p.displayName),
                  save: (v) => c.updateProfile((p) => p.copyWith(house: v)),
                ),
              ),
              _InfoRow(
                key: const ValueKey('profile-name'),
                icon: Icons.person_rounded,
                label: t.profYourName,
                value: p.displayName,
                onTap: () => _editText(
                  context,
                  title: t.profYourName,
                  initial: p.name,
                  save: (v) => c.updateProfile((p) => p.copyWith(name: v)),
                ),
              ),
              _InfoRow(
                key: const ValueKey('profile-country'),
                icon: Icons.public_rounded,
                label: t.profCountry,
                value: country,
                onTap: () => _pickCountry(context),
              ),
              _InfoRow(
                key: const ValueKey('profile-area'),
                icon: Icons.place_rounded,
                label: t.profArea,
                value: p.area.trim().isEmpty ? t.profAddArea : p.area.trim(),
                muted: p.area.trim().isEmpty,
                onTap: () async {
                  final place = await showPlacePicker(context);
                  if (place != null) {
                    c.updateProfile((p) => p.copyWith(area: place.label));
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const _RowIcon(Icons.groups_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.profTableSize,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Counter(
                      value: p.servings,
                      onChanged: (v) =>
                          c.updateProfile((p) => p.copyWith(servings: v)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SectionTitle(t.profTaste),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: c.recipes.cuisineGroups,
                builder: (context, snap) {
                  final groups = snap.data;
                  if (groups == null) return const LoadingBlock();
                  return PickedGroup(
                    id: 'cuisine',
                    title: t.profCuisines,
                    empty: t.profAllCuisines,
                    options: [
                      for (final g in groups)
                        SetupOption(
                          g['id'] as String,
                          L10n.term(g['name'] as String),
                        ),
                    ],
                    selected: p.cuisines,
                    onChanged: (v) =>
                        c.updateProfile((p) => p.copyWith(cuisines: v)),
                  );
                },
              ),
              Divider(height: 28, color: Sofra.line),
              PickedGroup(
                id: 'meal',
                title: t.profMeals,
                empty: t.profNoMeal,
                options: setupMeals,
                selected: p.meals,
                onChanged: (v) => c.updateProfile((p) => p.copyWith(meals: v)),
              ),
              Divider(height: 20, color: Sofra.line),
              SwitchListTile.adaptive(
                key: const ValueKey('profile-quick'),
                contentPadding: EdgeInsets.zero,
                secondary: const _RowIcon(Icons.bolt_rounded),
                title: Text(
                  t.profQuickFirst,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                value: p.quickMeals,
                onChanged: (v) =>
                    c.updateProfile((p) => p.copyWith(quickMeals: v)),
              ),
            ],
          ),
        ),
        SectionTitle(t.profHealth),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PickedGroup(
                id: 'avoid',
                title: t.profAllergies,
                empty: t.profNoAllergies,
                info: t.profAllergiesInfo,
                options: setupAvoid,
                selected: p.allergies,
                onChanged: (v) =>
                    c.updateProfile((p) => p.copyWith(allergies: v)),
              ),
              Divider(height: 28, color: Sofra.line),
              PickedGroup(
                id: 'health',
                title: t.profConditions,
                empty: t.profNoConditions,
                info: t.profConditionsInfo,
                options: setupHealth,
                selected: p.health,
                onChanged: (v) => c.updateProfile((p) => p.copyWith(health: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  static Future<void> _pickCountry(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: CountryPicker(),
        ),
      );

  static Future<void> _editText(
    BuildContext context, {
    required String title,
    required String initial,
    required ValueChanged<String> save,
    String? hint,
  }) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _TextDialog(title: title, initial: initial, hint: hint),
    );
    if (value != null) save(value.trim());
  }
}

/// One line of text to edit. It owns its field, which outlives the call
/// while the dialog animates away.
class _TextDialog extends StatefulWidget {
  const _TextDialog({required this.title, required this.initial, this.hint});
  final String title, initial;
  final String? hint;
  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final field = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      key: const ValueKey('profile-edit-field'),
      controller: field,
      autofocus: true,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(hintText: widget.hint),
      onSubmitted: (v) => Navigator.of(context).pop(v),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.profCancel),
      ),
      FilledButton(
        key: const ValueKey('profile-edit-save'),
        onPressed: () => Navigator.of(context).pop(field.text),
        child: Text(context.l10n.profSave),
      ),
    ],
  );
}

/// The household at a glance: chef, house name, who and where, and three
/// counts.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.house,
    required this.line,
    required this.stats,
  });
  final String house, line;
  final List<(String, String)> stats;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [Sofra.mint, Sofra.accentTint.withValues(alpha: .9)],
      ),
      borderRadius: BorderRadius.circular(Sofra.r22),
      boxShadow: Sofra.shadow(),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const ChefArt(size: 76, compact: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    house,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Sofra.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (final (i, s) in stats.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Sofra.card.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(Sofra.r16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        s.$1,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        s.$2,
                        style: TextStyle(color: Sofra.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

class _RowIcon extends StatelessWidget {
  const _RowIcon(this.icon);
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: Sofra.accentTint,
      borderRadius: BorderRadius.circular(Sofra.r12),
    ),
    child: Icon(icon, size: 20, color: Sofra.accent),
  );
}

/// One editable fact: icon, label, its value and a pencil.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.muted = false,
  });
  final IconData icon;
  final String label, value;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label: $value',
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Sofra.r12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Sofra.line, width: .6)),
        ),
        child: Row(
          children: [
            _RowIcon(icon),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted ? Sofra.accent : Sofra.muted,
                  fontWeight: muted ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.edit_rounded, size: 16, color: Sofra.muted),
          ],
        ),
      ),
    ),
  );
}

/// A choice group that shows only what is chosen, each removable, then an
/// «أضف» menu with the rest. Chosen values outside [options] (typed by the
/// user during setup) still show and can be removed.
class PickedGroup extends StatelessWidget {
  const PickedGroup({
    super.key,
    required this.id,
    required this.title,
    required this.empty,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.info,
  });
  final String id, title, empty;
  final String? info;
  final List<SetupOption> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = {for (final o in options) o.value: o.label};
    final chosen = [
      for (final o in options)
        if (selected.contains(o.value)) o.value,
      for (final v in selected)
        if (!labels.containsKey(v)) v,
    ];
    final rest = [
      for (final o in options)
        if (!selected.contains(o.value)) o,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            if (info != null)
              Tooltip(
                message: info!,
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 4),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Sofra.muted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: Sofra.motion(context, true),
          curve: Sofra.quickCurve,
          alignment: AlignmentDirectional.topStart,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (chosen.isEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: Text(empty, style: TextStyle(color: Sofra.muted)),
                ),
              for (final v in chosen)
                _Picked(
                  key: ValueKey('$id-$v'),
                  label: L10n.term(labels[v] ?? v),
                  onRemove: () => onChanged({...selected}..remove(v)),
                ),
              if (rest.isNotEmpty)
                _AddMenu(
                  key: ValueKey('$id-add'),
                  id: id,
                  options: rest,
                  onPick: (v) => onChanged({...selected, v}),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Picked extends StatelessWidget {
  const _Picked({super.key, required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Sofra.r12);
    return Semantics(
      button: true,
      label: context.l10n.profRemove(label),
      excludeSemantics: true,
      child: PressScale(
        child: Material(
          color: Sofra.accentTint,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: Sofra.accent.withValues(alpha: .3)),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onRemove,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Sofra.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Sofra.accent.withValues(alpha: .7),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddMenu extends StatelessWidget {
  const _AddMenu({
    super.key,
    required this.id,
    required this.options,
    required this.onPick,
  });
  final String id;
  final List<SetupOption> options;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: context.l10n.profAdd,
    onSelected: onPick,
    position: PopupMenuPosition.under,
    color: Sofra.paper,
    constraints: const BoxConstraints(minWidth: 180, maxHeight: 360),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Sofra.r16),
    ),
    itemBuilder: (_) => [
      for (final o in options)
        PopupMenuItem(
          key: ValueKey('$id-pick-${o.value}'),
          value: o.value,
          child: Row(
            children: [
              if (o.icon != null) ...[
                Icon(o.icon, size: 20, color: Sofra.muted),
                const SizedBox(width: 10),
              ],
              Text(L10n.term(o.label)),
            ],
          ),
        ),
    ],
    child: Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsetsDirectional.only(start: 10, end: 12),
      decoration: BoxDecoration(
        color: Sofra.surface,
        borderRadius: BorderRadius.circular(Sofra.r12),
        border: Border.all(color: Sofra.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_rounded, size: 18, color: Sofra.ink),
          SizedBox(width: 4),
          Text(
            context.l10n.profAdd,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Icon(Icons.expand_more_rounded, size: 18, color: Sofra.muted),
        ],
      ),
    ),
  );
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
    final t = context.l10n;
    return ScreenBody(
      children: [
        const SizedBox(height: 8),
        _AccountCard(
          name: p.houseName,
          initial: p.name.trim(),
          onTap: () => nav.goTab(AppTab.profile),
        ),
        SectionTitle(t.profCountryCurrency),
        const Surface(child: CountryPicker()),
        SectionTitle(t.profReminders),
        const ReminderSettings(),
        if (c.recipes.library != null) ...[
          SectionTitle(t.librarySection),
          const LibrarySettings(),
        ],
        SectionTitle(t.lookSection),
        const LookSettings(),
        const SizedBox(height: 24),
        if (c.persistent) ...[
          Center(
            child: Text(
              c.saving
                  ? t.profSaving
                  : c.saveError != null
                  ? t.profUnsaved
                  : c.storeLabel,
              key: const ValueKey('save-status'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Sofra.muted, fontSize: 12),
            ),
          ),
          if (signOut != null)
            Center(
              child: TextButton(
                onPressed: c.saving || c.saveError != null ? null : signOut,
                child: Text(t.profSignOut),
              ),
            ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 24),
        const Center(child: SofraLogo(height: 24)),
        const SizedBox(height: 4),
        Center(
          child: Text(
            t.profFooter,
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
    final shown = name.trim().isEmpty
        ? context.l10n.profMyAccount
        : name.trim();
    return Material(
      color: Sofra.inverse,
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
                decoration: BoxDecoration(
                  color: Sofra.accentTint,
                  shape: BoxShape.circle,
                ),
                child: initial.isEmpty
                    ? Icon(Icons.person_rounded, color: Sofra.accent, size: 30)
                    : Text(
                        initial.characters.first,
                        style: TextStyle(
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
                      style: TextStyle(
                        color: Sofra.onInverse,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.profAccountLine,
                      style: TextStyle(
                        color: Sofra.onInverse.withValues(alpha: .75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Sofra.onInverse),
            ],
          ),
        ),
      ),
    );
  }
}
