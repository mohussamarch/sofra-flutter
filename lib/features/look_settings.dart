import 'package:flutter/material.dart';

import '../app/look.dart';
import '../app/scope.dart';
import '../l10n/l10n.dart';
import '../ui/design.dart';
import 'language_switch.dart';

/// Display and language: appearance, text size, colour correction, motion
/// and language, one compact row each. Explanations sit behind an info icon.
class LookSettings extends StatelessWidget {
  const LookSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final p = c.profile;
    final t = context.l10n;
    final divider = Divider(height: 1, thickness: 1, color: Sofra.line);
    return Surface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          _Row(
            icon: Icons.contrast_rounded,
            label: t.lookAppearance,
            control: SofraSegments<Appearance>(
              id: 'look-appearance',
              label: t.lookAppearance,
              value: p.appearance,
              onChanged: (v) =>
                  c.updateProfile((p) => p.copyWith(appearance: v)),
              options: [
                SofraSegment(
                  Appearance.light,
                  t.lookLight,
                  icon: Icons.light_mode_rounded,
                ),
                // A phone: «same as the phone».
                SofraSegment(
                  Appearance.system,
                  t.lookSystem,
                  icon: Icons.smartphone_rounded,
                ),
                SofraSegment(
                  Appearance.dark,
                  t.lookDark,
                  icon: Icons.dark_mode_rounded,
                ),
              ],
            ),
          ),
          divider,
          _Row(
            icon: Icons.format_size_rounded,
            label: t.lookTextSize,
            control: SofraSegments<int>(
              id: 'look-text',
              label: t.lookTextSize,
              value: p.textStep,
              onChanged: (v) => c.updateProfile((p) => p.copyWith(textStep: v)),
              options: [
                for (final (step, name, size) in [
                  (0, t.lookTextNormal, 12.0),
                  (1, t.lookTextLarge, 16.0),
                  (2, t.lookTextLarger, 21.0),
                ])
                  SofraSegment(step, name, glyph: t.lookGlyph, glyphSize: size),
              ],
            ),
          ),
          divider,
          _Row(
            icon: Icons.palette_outlined,
            label: t.lookColors,
            info: t.lookColorsInfo,
            control: _VisionMenu(
              value: p.colorVision,
              onChanged: (v) =>
                  c.updateProfile((p) => p.copyWith(colorVision: v)),
            ),
          ),
          divider,
          _Row(
            icon: Icons.animation_rounded,
            label: t.lookMotion,
            info: t.lookMotionInfo,
            control: Switch.adaptive(
              key: const ValueKey('look-motion'),
              value: p.reduceMotion,
              onChanged: (v) =>
                  c.updateProfile((p) => p.copyWith(reduceMotion: v)),
            ),
          ),
          divider,
          _Row(
            icon: Icons.translate_rounded,
            label: t.lookLanguage,
            control: const LanguageSwitch(id: 'look-lang'),
          ),
        ],
      ),
    );
  }
}

/// One setting: icon and name at the start edge, the control pinned to the
/// end edge. When the name and the control cannot share a line (larger
/// text, a long English name) the control drops under the name.
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
  Widget build(BuildContext context) {
    final name = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Sofra.muted),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        if (info != null) _InfoButton(info!),
      ],
    );
    // Both sides share one 50 high band, so they centre on each other.
    Widget band(Widget child, AlignmentGeometry at) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: Align(widthFactor: 1, alignment: at, child: child),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      // Name at the start edge, control at the end edge; when they do not
      // fit on one line, the control drops under the name; both then keep
      // the start edge, so the name never drifts away from its icon.
      child: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.start,
        spacing: 12,
        children: [
          band(name, AlignmentDirectional.centerStart),
          band(
            FittedBox(fit: BoxFit.scaleDown, child: control),
            AlignmentDirectional.centerEnd,
          ),
        ],
      ),
    );
  }
}

/// The «i» beside a setting: a 44 x 44 target that shows the explanation.
class _InfoButton extends StatelessWidget {
  const _InfoButton(this.message);
  final String message;

  /// A small popover that stays until a tap elsewhere, never a tooltip
  /// that disappears on its own before a slow reader is done.
  @override
  Widget build(BuildContext context) => MenuAnchor(
    style: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(Sofra.inverse),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(6),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sofra.r12)),
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
    ),
    menuChildren: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Text(
          message,
          style: TextStyle(color: Sofra.onInverse, fontSize: 14, height: 1.6),
        ),
      ),
    ],
    builder: (context, menu, _) => Semantics(
      button: true,
      label: message,
      excludeSemantics: true,
      child: InkResponse(
        radius: 22,
        onTap: () => menu.isOpen ? menu.close() : menu.open(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.info_outline_rounded, size: 18, color: Sofra.muted),
        ),
      ),
    ),
  );
}

class _VisionMenu extends StatelessWidget {
  const _VisionMenu({required this.value, required this.onChanged});
  final ColorVision value;
  final ValueChanged<ColorVision> onChanged;

  static String _short(AppLocalizations t, ColorVision v) => switch (v) {
    ColorVision.none => t.lookVisionNoneShort,
    ColorVision.protan => t.lookVisionProtanShort,
    ColorVision.deutan => t.lookVisionDeutanShort,
    ColorVision.tritan => t.lookVisionTritanShort,
  };
  static String _full(AppLocalizations t, ColorVision v) => switch (v) {
    ColorVision.none => t.lookVisionNone,
    ColorVision.protan => t.lookVisionProtan,
    ColorVision.deutan => t.lookVisionDeutan,
    ColorVision.tritan => t.lookVisionTritan,
  };

  @override
  Widget build(BuildContext context) => PopupMenuButton<ColorVision>(
    key: const ValueKey('look-vision'),
    tooltip: context.l10n.lookColors,
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
                v == value ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 18,
                color: v == value ? Sofra.accent : Sofra.muted,
              ),
              const SizedBox(width: 10),
              Flexible(child: Text(_full(context.l10n, v))),
            ],
          ),
        ),
    ],
    child: Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
      decoration: BoxDecoration(
        color: Sofra.sand,
        borderRadius: BorderRadius.circular(Sofra.r12),
        border: Border.all(color: Sofra.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _short(context.l10n, value),
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
