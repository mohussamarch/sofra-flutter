import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'design.dart';

/// Trial switch for the glass look of the main tile, compared before it is
/// used anywhere else (`--dart-define=SOFRA_GLASS=true`).
const glassTrial = bool.fromEnvironment('SOFRA_GLASS');

/// A large way in: one single-colour symbol over a short name and how it
/// works, all centred. The symbol rises in once, and answers a press with a
/// small spring and tilt; with reduced motion it simply appears.
class AddTile extends StatefulWidget {
  const AddTile({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.primary = false,
    this.minHeight = 0,
  });

  final IconData icon;
  final String title, detail;

  /// Null shows the tile switched off.
  final VoidCallback? onTap;
  final bool primary;
  final double minHeight;

  @override
  State<AddTile> createState() => _AddTileState();
}

class _AddTileState extends State<AddTile> with TickerProviderStateMixin {
  late final _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  bool _down = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
    } else if (!_enter.isAnimating && _enter.value == 0) {
      _enter.forward();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _press.dispose();
    super.dispose();
  }

  void _tap() {
    if (!MediaQuery.disableAnimationsOf(context)) _press.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;
    final glass = glassTrial;
    final light = primary && !glass; // white type on solid terracotta
    final fg = light ? Colors.white : Sofra.ink;
    final symbolColor = light || (glass && primary)
        ? Colors.white
        : Sofra.accent;
    final radius = BorderRadius.circular(Sofra.r28);

    final symbol = AnimatedBuilder(
      animation: Listenable.merge([_enter, _press]),
      builder: (context, child) {
        final e = Curves.easeOutBack.transform(_enter.value);
        // A press: quick squash then a damped spring and a small tilt.
        final p = _press.value;
        final spring = p == 0 ? 0.0 : math.sin(p * math.pi * 3) * (1 - p);
        return Opacity(
          opacity: _enter.value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - e) * 14),
            child: Transform.rotate(
              angle: spring * .14,
              child: Transform.scale(
                scale: (.82 + .18 * e) + spring * .12,
                child: child,
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: glass && primary
              ? Sofra.accent
              : light
              ? Colors.white.withValues(alpha: .16)
              : Sofra.accentTint,
        ),
        child: Icon(widget.icon, size: 40, color: symbolColor),
      ),
    );

    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.minHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            symbol,
            const SizedBox(height: 12),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fg,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.detail,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: light
                    ? Colors.white.withValues(alpha: .85)
                    : Sofra.muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );

    final ink = InkWell(
      onTap: widget.onTap == null ? null : _tap,
      onHighlightChanged: (v) => setState(() => _down = v),
      borderRadius: radius,
      child: content,
    );

    Widget tile;
    if (glass) {
      tile = _Glass(
        radius: Sofra.r28,
        child: Material(type: MaterialType.transparency, child: ink),
      );
    } else {
      tile = Material(
        color: primary ? Sofra.accent : Sofra.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: primary ? BorderSide.none : const BorderSide(color: Sofra.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: ink,
      );
    }

    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.title,
      excludeSemantics: true,
      child: Opacity(
        opacity: widget.onTap == null ? .5 : 1,
        child: AnimatedScale(
          scale: _down ? .97 : 1,
          duration: Sofra.quick,
          curve: Sofra.quickCurve,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: glass
                  ? [
                      BoxShadow(
                        color: const Color(0xFF8A4A2C).withValues(alpha: .15),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                        spreadRadius: -6,
                      ),
                    ]
                  : primary
                  ? [
                      BoxShadow(
                        color: Sofra.accentDark.withValues(alpha: .22),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: tile,
          ),
        ),
      ),
    );
  }
}

/// Hand-built liquid glass, the same on every platform: a clear bevel band
/// round the edge (light blur, so what is behind stays sharp there, like a
/// lens), a frosted centre, a rim that is bright where the light hits and a
/// thin inner line that gives the bevel depth.
class _Glass extends StatelessWidget {
  const _Glass({required this.radius, required this.child});
  final double radius;
  final Widget child;

  static const bevel = 7.0;

  @override
  Widget build(BuildContext context) {
    final outer = BorderRadius.circular(radius);
    final inner = BorderRadius.circular(radius - bevel);
    return ClipRRect(
      borderRadius: outer,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
        child: CustomPaint(
          foregroundPainter: _GlassEdge(radius: radius, bevel: bevel),
          child: ColoredBox(
            color: Colors.white.withValues(alpha: .16),
            child: Padding(
              padding: const EdgeInsets.all(bevel),
              child: ClipRRect(
                borderRadius: inner,
                child: BackdropFilter(
                  filter: ui.ImageFilter.compose(
                    outer: const ColorFilter.matrix(_saturate),
                    inner: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: .46),
                          Colors.white.withValues(alpha: .14),
                        ],
                      ),
                    ),
                    child: child,
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

/// Saturation 1.3 (luminance-weighted) and a touch of light.
const _saturate = <double>[
  1.2362, -0.2146, -0.0217, 0, 4, //
  -0.0638, 1.0854, -0.0217, 0, 4, //
  -0.0638, -0.2146, 1.2783, 0, 4, //
  0, 0, 0, 1, 0, //
];

class _GlassEdge extends CustomPainter {
  _GlassEdge({required this.radius, required this.bevel});
  final double radius, bevel;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    RRect rr(double inset) => RRect.fromRectAndRadius(
      rect.deflate(inset),
      Radius.circular(radius - inset),
    );
    Shader lit(List<Color> colors, List<double> stops) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: stops,
    ).createShader(rect);
    const w = Colors.white;
    // Outer rim: bright at the lit corner, fading, lifting again opposite.
    canvas.drawRRect(
      rr(.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = lit(
          [
            w,
            w.withValues(alpha: .35),
            w.withValues(alpha: .12),
            w.withValues(alpha: .7),
          ],
          const [0, .3, .65, 1],
        ),
    );
    // Soft glint hugging the lit corner.
    canvas.drawRRect(
      rr(2.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
        ..shader = lit(
          [w.withValues(alpha: .9), w.withValues(alpha: 0)],
          const [0, .32],
        ),
    );
    // Inner line of the bevel: shaded on the lit side, light on the far side.
    const shade = Color(0xFF7A4A2E);
    canvas.drawRRect(
      rr(bevel),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = lit(
          [
            shade.withValues(alpha: .16),
            shade.withValues(alpha: .04),
            w.withValues(alpha: .55),
          ],
          const [0, .5, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_GlassEdge old) =>
      old.radius != radius || old.bevel != bevel;
}

/// The app's ground: warm paper under wide pools of light, with a few
/// defined colour orbs near the top, so no page is one flat colour and glass
/// has shapes to blur and bend.
class SofraBackdrop extends StatelessWidget {
  const SofraBackdrop({super.key});

  static const _pools = [
    (Alignment(1, -1), 1.15, Color(0xFFEBB79A)),
    (Alignment(-1.05, .2), .95, Color(0xFFF0D9A6)),
    (Alignment(.7, 1.1), 1.0, Color(0xFFF2C7B4)),
  ];

  @override
  Widget build(BuildContext context) {
    Widget layer = const CustomPaint(
      painter: _Orbs(),
      child: SizedBox.expand(),
    );
    for (final (center, radius, color) in _pools.reversed) {
      layer = DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: center,
            radius: radius,
            colors: [color.withValues(alpha: .85), color.withValues(alpha: 0)],
          ),
        ),
        child: layer,
      );
    }
    return layer;
  }
}

class _Orbs extends CustomPainter {
  const _Orbs();

  // x as a share of the width, y and radius in logical pixels.
  static const _orbs = [
    (.84, 262.0, 84.0, Color(0xFFE2764A)),
    (.30, 318.0, 78.0, Color(0xFFF0B347)),
    (.56, 214.0, 46.0, Color(0xFFEE9C8A)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (x, y, r, color) in _orbs) {
      final c = Offset(size.width * x, y);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.35, -.4),
            colors: [
              Color.lerp(color, Colors.white, .35)!.withValues(alpha: .95),
              color.withValues(alpha: .85),
              color.withValues(alpha: .55),
            ],
            stops: const [0, .65, 1],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_Orbs old) => false;
}
