import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Sofra design tokens. The palette comes from the Blender kitchen itself:
/// sage cabinets, cream walls, warm floor tiles and the terracotta curtain.
abstract final class Sofra {
  static const ink = Color(0xFF2B3830);
  static const muted = Color(0xFF6B766E);
  static const green = Color(0xFF3F6B52);
  static const greenDark = Color(0xFF2E5240);
  static const sage = Color(0xFF8AA591);
  static const mint = Color(0xFFE5EDE5);
  static const cream = Color(0xFFFAF6EF);
  static const sand = Color(0xFFF1E8DA);
  static const line = Color(0xFFE6DFD2);
  static const orange = Color(0xFFCF6747);
  static const peach = Color(0xFFF7E4D8);
  static const yellow = Color(0xFFF1D58C);

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
      color: ink.withValues(alpha: .05 * lift),
      blurRadius: 28 * lift,
      offset: Offset(0, 12 * lift),
    ),
    BoxShadow(
      color: ink.withValues(alpha: .04),
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
        ? Colors.white
        : Sofra.green;
    final ink = !enabled
        ? Sofra.muted
        : secondary
        ? Sofra.ink
        : Colors.white;
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
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
    this.border = false,
  });
  final Widget child;
  final Color color;
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
            : color,
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
    this.tint = Colors.white,
    this.opacity = .72,
  });
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color tint;
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
          color: tint.withValues(alpha: opacity),
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
              color: selected ? Sofra.mint : Colors.white,
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
                                style: const TextStyle(
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
  const SoftTag(
    this.text, {
    super.key,
    this.color = Sofra.mint,
    this.ink = Sofra.greenDark,
    this.icon,
  });
  final String text;
  final Color color;
  final Color ink;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color,
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
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              letterSpacing: -.2,
            ),
          ),
        ),
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
      backgroundColor: next == null ? Colors.transparent : Colors.white,
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
  });
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool dark;
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
                        Colors.white.withValues(alpha: .62),
                        Colors.white.withValues(alpha: .38),
                      ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: dark ? .22 : .7),
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

/// Marks a subtree as drawn on aged recipe-book paper; cards soften to it.
class Paper extends InheritedWidget {
  const Paper({super.key, required super.child});
  static bool isOn(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Paper>() != null;
  @override
  bool updateShouldNotify(Paper old) => false;

  static const ink = Color(0xFF4A3A28);
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
