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
    final light = primary && !glass; // onAccent type on solid terracotta
    final fg = light ? Sofra.onAccent : Sofra.ink;
    final symbolColor = light || (glass && primary)
        ? Sofra.onAccent
        : Sofra.accent;
    final glow = Sofra.isDark ? Sofra.palette.shadow : const Color(0xFF8A4A2C);
    final r = glass ? 34.0 : Sofra.r28;
    final radius = BorderRadius.circular(r);

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
              ? Sofra.onAccent.withValues(alpha: .16)
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
                    ? Sofra.onAccent.withValues(alpha: .85)
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
      tile = SofraGlass(
        radius: r,
        child: Material(type: MaterialType.transparency, child: ink),
      );
    } else {
      tile = Material(
        color: primary ? Sofra.accent : Sofra.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: primary ? BorderSide.none : BorderSide(color: Sofra.line),
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
                        color: glow.withValues(alpha: .10),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: glow.withValues(alpha: .16),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                        spreadRadius: -10,
                      ),
                    ]
                  : primary
                  // No peach glow at night: accentDark is light there.
                  ? Sofra.isDark
                        ? Sofra.shadow(.6)
                        : [
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

/// Hand-built liquid glass, the same on every platform: one clear sheet (no
/// frame inside a frame), lightly frosted, with a thin band at the edge where
/// what is behind stays almost sharp, a crisp rim of light and a soft glow
/// inside the lit corner.
class SofraGlass extends StatelessWidget {
  const SofraGlass({super.key, required this.radius, required this.child});
  final double radius;
  final Widget child;

  static const band = 3.0;

  @override
  Widget build(BuildContext context) {
    final outer = BorderRadius.circular(radius);
    final inner = BorderRadius.circular(radius - band);
    return ClipRRect(
      borderRadius: outer,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
        child: CustomPaint(
          foregroundPainter: _GlassEdge(radius: radius),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(band),
                  child: ClipRRect(
                    borderRadius: inner,
                    child: BackdropFilter(
                      filter: ui.ImageFilter.compose(
                        outer: const ColorFilter.matrix(_saturate),
                        inner: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              // The sheet itself: a faint milky tint, lighter at the top.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Sofra.card.withValues(alpha: .30),
                        Sofra.card.withValues(alpha: .12),
                        Sofra.card.withValues(alpha: .18),
                      ],
                      stops: const [0, .6, 1],
                    ),
                  ),
                ),
              ),
              child,
            ],
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
  _GlassEdge({required this.radius});
  final double radius;

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
    canvas.save();
    canvas.clipRRect(rr(0));
    // Glow inside the lit corner, and a fainter one where light leaves.
    canvas.drawRRect(
      rr(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..shader = lit(
          [
            w.withValues(alpha: .75),
            w.withValues(alpha: 0),
            w.withValues(alpha: 0),
            w.withValues(alpha: .4),
          ],
          const [0, .38, .7, 1],
        ),
    );
    // A thin shade just inside the far edge gives the sheet thickness.
    const shade = Color(0xFF6B3F27);
    canvas.drawRRect(
      rr(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
        ..shader = lit(
          [
            shade.withValues(alpha: 0),
            shade.withValues(alpha: 0),
            shade.withValues(alpha: .13),
          ],
          const [0, .55, 1],
        ),
    );
    canvas.restore();
    // The rim: crisp and bright all round, strongest at the lit corner.
    canvas.drawRRect(
      rr(.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = lit(
          [
            w,
            w.withValues(alpha: .6),
            w.withValues(alpha: .4),
            w.withValues(alpha: .9),
          ],
          const [0, .35, .7, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_GlassEdge old) => old.radius != radius;
}

/// The app's ground: warm colours that melt into each other, never one flat
/// colour and never a hard edge.
class SofraBackdrop extends StatelessWidget {
  const SofraBackdrop({super.key});

  // Wide soft washes of warm colour that melt into each other: each one
  // fades over its whole radius, so no edge is ever visible. Where each sits
  // and how far it spreads; its colour comes from the current palette.
  static const _spots = [
    (Alignment(1.1, -1.0), 1.25),
    (Alignment(-1.2, -.35), 1.10),
    (Alignment(.3, .1), .95),
    (Alignment(-.9, .95), 1.15),
    (Alignment(1.2, 1.1), 1.10),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = Sofra.palette;
    final washes = [
      for (final (i, (center, radius)) in _spots.indexed)
        (center, radius, palette.washes[i % palette.washes.length]),
    ];
    Widget layer = const SizedBox.expand();
    for (final (center, radius, color) in washes.reversed) {
      layer = DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: center,
            radius: radius,
            colors: [
              color.withValues(alpha: .80),
              color.withValues(alpha: .45),
              color.withValues(alpha: .15),
              color.withValues(alpha: 0),
            ],
            stops: const [0, .35, .7, 1],
          ),
        ),
        child: layer,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: palette.washBase,
        ),
      ),
      child: layer,
    );
  }
}
