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
    final fg = primary ? Colors.white : Sofra.ink;
    final symbolColor = primary ? Colors.white : Sofra.accent;
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
          color: primary
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
                color: primary
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
      // Liquid glass (refs: Apple HIG materials and tinted button, Flutter
      // liquid_glass_renderer, specular rim maps). The light pools behind
      // show through, blurred and a little more saturated; primary glass is
      // tinted terracotta but stays see-through; a bright rim catches the
      // light at the top corner and fades round the edge.
      tile = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.compose(
            outer: const ColorFilter.matrix(_saturate),
            inner: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          ),
          child: CustomPaint(
            foregroundPainter: _RimPainter(radius: Sofra.r28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: primary
                      ? [
                          const Color(0xFFD9774F).withValues(alpha: .58),
                          Sofra.accentDark.withValues(alpha: .80),
                        ]
                      : [
                          const Color(0xFFFFFAF3).withValues(alpha: .70),
                          const Color(0xFFFFF4E8).withValues(alpha: .48),
                        ],
                ),
              ),
              child: DecoratedBox(
                // A soft specular bloom in the lit corner, not a band.
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: RadialGradient(
                    center: const AlignmentDirectional(
                      .85,
                      -1.05,
                    ).resolve(Directionality.of(context)),
                    radius: .9,
                    colors: [
                      Colors.white.withValues(alpha: primary ? .30 : .45),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Material(type: MaterialType.transparency, child: ink),
              ),
            ),
          ),
        ),
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
              boxShadow: primary
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

/// The app's ground: warm paper under three clear pools of light (terracotta
/// top corner, honey on the side, peach low down), so no page is one flat
/// colour and glass has something to show through.
class SofraBackdrop extends StatelessWidget {
  const SofraBackdrop({super.key});

  static const _pools = [
    (Alignment(1, -1), 1.15, Color(0xFFEBB79A)),
    (Alignment(-1.05, .2), .95, Color(0xFFF0D9A6)),
    (Alignment(.7, 1.1), 1.0, Color(0xFFF2C7B4)),
  ];

  @override
  Widget build(BuildContext context) {
    Widget layer = const SizedBox.expand();
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

/// Saturation 1.3 (luminance-weighted) and a touch of light: what is behind glass looks richer.
const _saturate = <double>[
  1.2362, -0.2146, -0.0217, 0, 4, //
  -0.0638, 1.0854, -0.0217, 0, 4, //
  -0.0638, -0.2146, 1.2783, 0, 4, //
  0, 0, 0, 1, 0, //
];

/// The glass rim: bright where the light hits (top corner), fading round the
/// sides, with a faint lift on the far bottom edge.
class _RimPainter extends CustomPainter {
  _RimPainter({required this.radius});
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(.75),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.white.withValues(alpha: .95),
          Colors.white.withValues(alpha: .18),
          Colors.white.withValues(alpha: .08),
          Colors.white.withValues(alpha: .45),
        ],
        stops: const [0, .35, .7, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.radius != radius;
}
