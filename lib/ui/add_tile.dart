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
    final glass = primary && glassTrial;
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
      // Liquid glass: the room behind shows through, blurred, under a warm
      // tint, a light rim and a soft shine across the top.
      tile = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Sofra.accent.withValues(alpha: .62),
                  Sofra.accentDark.withValues(alpha: .78),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: .45),
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 10,
                  right: 10,
                  top: 1,
                  height: 46,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Sofra.r22),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: .30),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Material(type: MaterialType.transparency, child: ink),
              ],
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

/// The app's ground: warm paper with two soft light pools, so pages are not
/// one flat colour and glass has something to show.
class SofraBackdrop extends StatelessWidget {
  const SofraBackdrop({super.key});

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(.9, -.95),
        radius: 1.1,
        colors: [Color(0xFFF3D9C6), Color(0x00F3D9C6)],
      ),
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-1, .35),
          radius: .9,
          colors: [Color(0x99F2E3BF), Color(0x00F2E3BF)],
        ),
      ),
      child: SizedBox.expand(),
    ),
  );
}
