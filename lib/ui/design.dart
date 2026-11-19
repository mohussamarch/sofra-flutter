import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// One full set of Sofra colours. [light] is direction A (warm editorial,
/// chosen by the owner); [dark] keeps the same warm family at night.
class SofraPalette {
  const SofraPalette({
    required this.ink,
    required this.muted,
    required this.accent,
    required this.accentDark,
    required this.accentTint,
    required this.onAccent,
    required this.paper,
    required this.surface,
    required this.card,
    required this.inverse,
    required this.onInverse,
    required this.ok,
    required this.okTint,
    required this.warn,
    required this.warnTint,
    required this.sage,
    required this.sand,
    required this.line,
    required this.yellow,
    required this.washes,
    required this.washBase,
    required this.shadow,
  });

  final Color ink, muted, accent, accentDark, accentTint, onAccent;
  final Color paper, surface, card, inverse, onInverse;
  final Color ok, okTint, warn, warnTint, sage, sand, line, yellow;

  /// The backdrop's soft colour washes, and the gradient under them.
  final List<Color> washes, washBase;
  final Color shadow;

  static const light = SofraPalette(
    ink: Color(0xFF2A211B),
    muted: Color(0xFF7A6C60),
    accent: Color(0xFFB4522F),
    accentDark: Color(0xFF8E3F23),
    accentTint: Color(0xFFF4E4D9),
    onAccent: Color(0xFFFFFFFF),
    paper: Color(0xFFF7F1E6),
    surface: Color(0xFFFFFDF8),
    card: Color(0xFFFFFFFF),
    inverse: Color(0xFF2A211B),
    onInverse: Color(0xFFFFFFFF),
    ok: Color(0xFF4E7356),
    okTint: Color(0xFFE7EEE4),
    warn: Color(0xFF9A5B1C),
    warnTint: Color(0xFFF6E7D2),
    sage: Color(0xFFD6B7A2),
    sand: Color(0xFFEFE6D7),
    line: Color(0xFFE5DACA),
    yellow: Color(0xFFE9C77B),
    washes: [
      Color(0xFFEFB49A),
      Color(0xFFF3D9A8),
      Color(0xFFF6CDBB),
      Color(0xFFF1D2B0),
      Color(0xFFEBBBA6),
    ],
    washBase: [Color(0xFFF7E6D8), Color(0xFFF8EDE0), Color(0xFFF5E2D3)],
    shadow: Color(0xFF2A211B),
  );

  /// Warm night: deep brown paper, cream ink, a lighter terracotta that
  /// keeps 4.5:1 on the cards, with dark text on it.
  static const dark = SofraPalette(
    ink: Color(0xFFF2E9DE),
    muted: Color(0xFFB5A595),
    accent: Color(0xFFE38A62),
    accentDark: Color(0xFFF2AA88),
    accentTint: Color(0xFF3D2B22),
    onAccent: Color(0xFF1F1611),
    paper: Color(0xFF1B1613),
    surface: Color(0xFF26201B),
    card: Color(0xFF2C251F),
    inverse: Color(0xFF3A2F27),
    onInverse: Color(0xFFF7EFE6),
    ok: Color(0xFF93C29B),
    okTint: Color(0xFF223127),
    warn: Color(0xFFE6A866),
    warnTint: Color(0xFF3A2A1A),
    sage: Color(0xFF7A604E),
    sand: Color(0xFF14100D),
    line: Color(0xFF3B322A),
    yellow: Color(0xFFD9B565),
    washes: [
      Color(0xFF5A2E1E),
      Color(0xFF4A3920),
      Color(0xFF4F2A22),
      Color(0xFF3F3020),
      Color(0xFF55301F),
    ],
    washBase: [Color(0xFF1E1714), Color(0xFF1B1613), Color(0xFF201813)],
    shadow: Color(0xFF000000),
  );
}

/// Sofra design tokens. Colours come from the current [SofraPalette]
/// (light or dark), set once per look change by the app root.
abstract final class Sofra {
  static SofraPalette _p = SofraPalette.light;
  static SofraPalette get palette => _p;
  static bool get isDark => identical(_p, SofraPalette.dark);

  /// Switches every token; the caller rebuilds the whole tree after it.
  static void use(SofraPalette palette) => _p = palette;

  static Color get ink => _p.ink;
  static Color get muted => _p.muted;
  static Color get accent => _p.accent;
  static Color get accentDark => _p.accentDark;
  static Color get accentTint => _p.accentTint;

  /// Text and icons on an [accent] fill.
  static Color get onAccent => _p.onAccent;
  static Color get paper => _p.paper;
  static Color get surface => _p.surface;

  /// The brightest raised surface: white in the light look.
  static Color get card => _p.card;

  /// A dark block that stays dark in both looks (the account card), and
  /// what goes on it.
  static Color get inverse => _p.inverse;
  static Color get onInverse => _p.onInverse;

  /// Meaning only: done / in stock, and missing / needs attention.
  static Color get ok => _p.ok;
  static Color get okTint => _p.okTint;
  static Color get warn => _p.warn;
  static Color get warnTint => _p.warnTint;

  // Older role names, kept so every screen moves to direction A at once.
  static Color get green => _p.accent;
  static Color get greenDark => _p.accentDark;
  static Color get sage => _p.sage;
  static Color get mint => _p.accentTint;
  static Color get cream => _p.paper;
  static Color get sand => _p.sand;
  static Color get line => _p.line;
  static Color get orange => _p.warn;
  static Color get peach => _p.warnTint;
  static Color get yellow => _p.yellow;

  /// Headings: El Messiri. Body text uses the theme's IBM Plex Sans Arabic.
  static const display = 'ElMessiri';
  static TextStyle heading(double size, {Color? color}) => TextStyle(
    fontFamily: display,
    fontSize: size,
    height: 1.3,
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation('wght', 700)],
    color: color ?? ink,
  );

  /// Corner radius scale; nothing outside it.
  static const r12 = 12.0, r16 = 16.0, r22 = 22.0, r28 = 28.0;

  /// Named springs: quick for presses and tabs, calm for pages and sheets.
  static const quick = Duration(milliseconds: 220);
  static const calm = Duration(milliseconds: 450);
  static const quickCurve = Curves.easeOutCubic;
  static const calmCurve = Curves.easeInOutCubic;
  static Duration motion(BuildContext context, [bool quick = false]) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : quick
      ? Sofra.quick
      : calm;

  /// Soft two-layer shadow tinted with the ink, never a hard edge.
  static List<BoxShadow> shadow([double lift = 1]) => [
    BoxShadow(
      color: _p.shadow.withValues(alpha: (isDark ? .25 : .05) * lift),
      blurRadius: 28 * lift,
      offset: Offset(0, 12 * lift),
    ),
    BoxShadow(
      color: _p.shadow.withValues(alpha: isDark ? .2 : .04),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];
}

/// Shrinks to 0.97 while pressed and springs back (its resting state).
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;
  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool down = false;
  void _set(bool value) {
    if (widget.enabled && down != value) setState(() => down = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: down ? .97 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Duration(milliseconds: down ? 90 : 220),
      curve: Sofra.quickCurve,
      child: widget.child,
    ),
  );
}

class DepthButton extends StatelessWidget {
  const DepthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.icon,
    this.compact = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool compact;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final face = !enabled
        ? Sofra.line
        : secondary
        ? Sofra.card
        : Sofra.green;
    final ink = !enabled
        ? Sofra.muted
        : secondary
        ? Sofra.ink
        : Sofra.onAccent;
    final radius = BorderRadius.circular(Sofra.r16);
    return PressScale(
      enabled: enabled,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: face,
          borderRadius: radius,
          boxShadow: enabled
              ? secondary
                    ? Sofra.shadow(.6)
                    : [
                        BoxShadow(
                          color: Sofra.green.withValues(alpha: .28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: compact ? 48 : 56),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 14 : 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: ink),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 14 : 16,
                          color: ink,
                        ),
                      ),
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

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
    this.border = false,
  });
  final Widget child;

  /// Defaults to [Sofra.card].
  final Color? color;
  final EdgeInsetsGeometry padding;

  /// A flat, quieter card (no lift) for secondary content.
  final bool border;
  @override
  Widget build(BuildContext context) {
    final paper = Paper.isOn(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: paper
            ? const Color(0x33FFF9EC)
            : border
            ? Sofra.sand.withValues(alpha: .6)
            : color ?? Sofra.card,
        borderRadius: BorderRadius.circular(Sofra.r22),
        border: paper
            ? Border.all(color: Paper.ink.withValues(alpha: .12))
            : null,
        boxShadow: border || paper ? null : Sofra.shadow(),
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

/// Frosted translucent panel for things floating over the kitchen scene.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = Sofra.r22,
    this.padding = EdgeInsets.zero,
    this.tint,
    this.opacity = .72,
  });
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// Defaults to [Sofra.card].
  final Color? tint;
  final double opacity;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: Sofra.shadow(.8),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: ColoredBox(
          color: (tint ?? Sofra.card).withValues(alpha: opacity),
          child: Padding(padding: padding, child: child),
        ),
      ),
    ),
  );
}

class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon = Icons.check_circle_outline_rounded,
  });
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Sofra.r16);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: selected,
        child: PressScale(
          child: AnimatedContainer(
            duration: Sofra.motion(context, true),
            curve: Sofra.quickCurve,
            decoration: BoxDecoration(
              color: selected ? Sofra.mint : Sofra.card,
              borderRadius: radius,
              boxShadow: selected ? null : Sofra.shadow(.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: selected ? Sofra.greenDark : Sofra.muted,
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  color: Sofra.muted,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: Sofra.motion(context, true),
                        child: Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          key: ValueKey(selected),
                          color: selected ? Sofra.green : Sofra.line,
                          size: 23,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SoftTag extends StatelessWidget {
  const SoftTag(this.text, {super.key, this.color, this.ink, this.icon});
  final String text;
  final Color? color, ink;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final ink = this.ink ?? Sofra.greenDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color ?? Sofra.mint,
        borderRadius: BorderRadius.circular(Sofra.r12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: ink),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 10),
    child: Row(
      children: [
        Expanded(child: Text(title, style: Sofra.heading(20))),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: Sofra.green),
            child: Text(
              action!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    ),
  );
}

class Counter extends StatelessWidget {
  const Counter({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = 12,
  });
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Sofra.sand,
      borderRadius: BorderRadius.circular(Sofra.r16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _step(Icons.add_rounded, 'زيادة العدد', value < max ? value + 1 : null),
        SizedBox(
          width: 46,
          child: AnimatedSwitcher(
            duration: Sofra.motion(context, true),
            child: Text(
              '$value',
              key: ValueKey(value),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        _step(
          Icons.remove_rounded,
          'تقليل العدد',
          value > 1 ? value - 1 : null,
        ),
      ],
    ),
  );

  Widget _step(IconData icon, String tip, int? next) => IconButton(
    onPressed: next == null ? null : () => onChanged(next),
    tooltip: tip,
    style: IconButton.styleFrom(
      backgroundColor: next == null ? Colors.transparent : Sofra.card,
      minimumSize: const Size(44, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sofra.r12),
      ),
    ),
    icon: Icon(icon, color: next == null ? Sofra.line : Sofra.ink),
  );
}

/// Apple-style liquid glass: strong blur, a bright rim and a soft inner sheen.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.radius = Sofra.r28,
    this.padding = EdgeInsets.zero,
    this.dark = false,
    this.strong = false,
  });
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool dark;

  /// Nearly opaque frosting, for text that must read over a bright scene.
  final bool strong;
  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .3 : .12),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: shape,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? [
                        Colors.white.withValues(alpha: .16),
                        Colors.white.withValues(alpha: .06),
                      ]
                    : [
                        Sofra.surface.withValues(alpha: strong ? .9 : .62),
                        Sofra.surface.withValues(alpha: strong ? .8 : .38),
                      ],
              ),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: dark
                      ? .22
                      : Sofra.isDark
                      ? .12
                      : .7,
                ),
                width: 1,
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Marks a subtree as drawn on the recipe book's page; cards soften to it.
class Paper extends InheritedWidget {
  const Paper({super.key, required super.child});
  static bool isOn(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Paper>() != null;
  @override
  bool updateShouldNotify(Paper old) => false;

  /// The page's outline ink; the current ink on the dark page.
  static Color get ink => Sofra.isDark ? Sofra.ink : const Color(0xFF3A2416);
  static const tone = Color(0xFFEBDDBF);
}

/// Old sepia page: warm base, fibres, foxing spots, burnt edges and the
/// spine's shadow on the start (right in Arabic) side.
class PaperPainter extends CustomPainter {
  const PaperPainter({this.seed = 7});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF0E4C8), Paper.tone, Color(0xFFE3D1AA)],
        ).createShader(rect),
    );
    var state = seed;
    double next() {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      return state / 0x7fffffff;
    }

    final fibre = Paint()
      ..strokeWidth = .6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 260; i++) {
      final p = Offset(next() * size.width, next() * size.height);
      final a = next() * 3.1416;
      final l = 4 + next() * 10;
      fibre.color = const Color(0xFF8A6A3C)
          .withValues(alpha: .05 + next() * .06);
      canvas.drawLine(p, p + Offset.fromDirection(a, l), fibre);
    }
    final speck = Paint();
    for (var i = 0; i < 900; i++) {
      speck.color = const Color(0xFF7A5A30)
          .withValues(alpha: .03 + next() * .05);
      canvas.drawCircle(
        Offset(next() * size.width, next() * size.height),
        .4 + next() * .9,
        speck,
      );
    }
    final fox = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    for (var i = 0; i < 7; i++) {
      fox.color = const Color(0xFFB08850).withValues(alpha: .06 + next() * .05);
      canvas.drawCircle(
        Offset(next() * size.width, next() * size.height),
        14 + next() * 26,
        fox,
      );
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: .95,
          colors: [
            Colors.transparent,
            const Color(0xFF8B6533).withValues(alpha: .1),
            const Color(0xFF6B4A22).withValues(alpha: .28),
          ],
          stops: const [.55, .82, 1],
        ).createShader(rect),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - 26, 0, 26, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            const Color(0xFF5A3D1A).withValues(alpha: .22),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(size.width - 26, 0, 26, size.height)),
    );
  }

  @override
  bool shouldRepaint(PaperPainter old) => old.seed != seed;
}

/// A selectable pill: accent tint when selected, paper surface otherwise.
/// Drop-in for ChoiceChip, whose label clipped Arabic text in this app.
class SofraChip extends StatelessWidget {
  const SofraChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.onPressed,
    this.backgroundColor,
    this.avatar,
    this.selectedColor,
    this.labelStyle,
    this.showCheckmark = false,
    this.padding,
  });
  final Widget label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  /// For an action pill (no selection), like ActionChip.
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Widget? avatar;
  final Color? selectedColor;
  final TextStyle? labelStyle;
  final bool showCheckmark;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Sofra.r12);
    final enabled = onSelected != null || onPressed != null;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: PressScale(
        enabled: enabled,
        child: AnimatedContainer(
          duration: Sofra.motion(context, true),
          curve: Sofra.quickCurve,
          decoration: BoxDecoration(
            color: selected
                ? (selectedColor ?? Sofra.accentTint)
                : (backgroundColor ?? Sofra.surface),
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? Sofra.accent.withValues(alpha: .35)
                  : Sofra.line,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap:
                  onPressed ??
                  (onSelected == null ? null : () => onSelected!(!selected)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (avatar != null) ...[
                        IconTheme.merge(
                          data: IconThemeData(
                            size: 18,
                            color: selected ? Sofra.accentDark : Sofra.muted,
                          ),
                          child: avatar!,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: DefaultTextStyle.merge(
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: selected ? Sofra.accentDark : Sofra.ink,
                          ).merge(labelStyle),
                          child: label,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
