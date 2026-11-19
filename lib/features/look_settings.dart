import 'package:flutter/material.dart';

import '../app/look.dart';
import '../app/scope.dart';
import '../ui/design.dart';

/// "راحتك في التطبيق": appearance, text size, colour correction and motion,
/// one compact row each. Explanations sit behind an info icon.
class LookSettings extends StatelessWidget {
  const LookSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final p = c.profile;
    final divider = Divider(height: 1, thickness: 1, color: Sofra.line);
    return Surface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          _Row(
            icon: Icons.contrast_rounded,
            label: 'المظهر',
            control: _Segments<Appearance>(
              id: 'look-appearance',
              value: p.appearance,
              onChanged: (v) =>
                  c.updateProfile((p) => p.copyWith(appearance: v)),
              options: const [
                (Appearance.light, 'فاتح', Icons.light_mode_rounded, null),
                (
                  Appearance.system,
                  'حسب الهاتف',
                  Icons.brightness_auto_rounded,
                  null,
                ),
                (Appearance.dark, 'داكن', Icons.dark_mode_rounded, null),
              ],
            ),
          ),
          divider,
          _Row(
            icon: Icons.format_size_rounded,
            label: 'حجم الخط',
            control: _Segments<int>(
              id: 'look-text',
              value: p.textStep,
              onChanged: (v) => c.updateProfile((p) => p.copyWith(textStep: v)),
              options: const [
                (0, 'عادي', null, 13.0),
                (1, 'كبير', null, 16.0),
                (2, 'أكبر', null, 19.0),
              ],
            ),
          ),
          divider,
          _Row(
            icon: Icons.palette_outlined,
            label: 'تمييز الألوان',
            info:
                'لمن يصعب عليه تمييز بعض الألوان: يغيّر ألوان التطبيق كله '
                'لتصبح أوضح، مثل «تصحيح الألوان» في إعدادات الهاتف.',
            control: _VisionMenu(
              value: p.colorVision,
              onChanged: (v) =>
                  c.updateProfile((p) => p.copyWith(colorVision: v)),
            ),
          ),
          divider,
          _Row(
            icon: Icons.animation_rounded,
            label: 'تقليل الحركة',
            info: 'انتقالات أهدأ دون ارتداد أو حركة في الخلفية.',
            control: Switch.adaptive(
              key: const ValueKey('look-motion'),
              value: p.reduceMotion,
              onChanged: (v) =>
                  c.updateProfile((p) => p.copyWith(reduceMotion: v)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.control,
    this.info,
  });
  final IconData icon;
  final String label;
  final Widget control;
  final String? info;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 56),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Sofra.muted),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          if (info != null)
            Tooltip(
              message: info!,
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 5),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 17,
                  color: Sofra.muted,
                ),
              ),
            ),
          const Spacer(),
          const SizedBox(width: 8),
          control,
        ],
      ),
    ),
  );
}

/// A small segmented choice. Each option is (value, name, icon, glyphSize):
/// an icon, or the letter «أ» at glyphSize; the name is its tooltip and
/// screen-reader label.
class _Segments<T> extends StatelessWidget {
  const _Segments({
    required this.id,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String id;
  final T value;
  final List<(T, String, IconData?, double?)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: Sofra.sand,
      borderRadius: BorderRadius.circular(Sofra.r12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (v, name, icon, glyph) in options)
          _Segment(
            key: ValueKey('$id-${v is Enum ? v.name : v}'),
            name: name,
            selected: v == value,
            onTap: () => onChanged(v),
            child: icon != null
                ? Icon(icon, size: 19)
                : Text(
                    'أ',
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: glyph,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
      ],
    ),
  );
}

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
    required this.child,
  });
  final String name;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ink = selected ? Sofra.accent : Sofra.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: Tooltip(
        message: name,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: Sofra.motion(context, true),
            curve: Sofra.quickCurve,
            width: 42,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Sofra.card : Sofra.sand.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(Sofra.r12 - 3),
              boxShadow: selected ? Sofra.shadow(.25) : null,
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: ink),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: ink),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VisionMenu extends StatelessWidget {
  const _VisionMenu({required this.value, required this.onChanged});
  final ColorVision value;
  final ValueChanged<ColorVision> onChanged;

  static const _short = {
    ColorVision.none: 'عادي',
    ColorVision.protan: 'الأحمر',
    ColorVision.deutan: 'الأخضر',
    ColorVision.tritan: 'الأزرق',
  };
  static const _full = {
    ColorVision.none: 'دون تصحيح',
    ColorVision.protan: 'صعوبة تمييز الأحمر',
    ColorVision.deutan: 'صعوبة تمييز الأخضر',
    ColorVision.tritan: 'صعوبة تمييز الأزرق',
  };

  @override
  Widget build(BuildContext context) => PopupMenuButton<ColorVision>(
    key: const ValueKey('look-vision'),
    tooltip: 'تمييز الألوان',
    initialValue: value,
    onSelected: onChanged,
    position: PopupMenuPosition.under,
    constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Sofra.r16),
    ),
    itemBuilder: (_) => [
      for (final v in ColorVision.values)
        PopupMenuItem(
          key: ValueKey('look-vision-${v.name}'),
          value: v,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                v == value
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 18,
                color: v == value ? Sofra.accent : Sofra.line,
              ),
              const SizedBox(width: 10),
              Flexible(child: Text(_full[v]!)),
            ],
          ),
        ),
    ],
    child: Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
      decoration: BoxDecoration(
        color: Sofra.sand,
        borderRadius: BorderRadius.circular(Sofra.r12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _short[value]!,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: value == ColorVision.none ? Sofra.muted : Sofra.accent,
            ),
          ),
          Icon(Icons.expand_more_rounded, size: 18, color: Sofra.muted),
        ],
      ),
    ),
  );
}
