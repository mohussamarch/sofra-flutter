import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design.dart';

/// Original Sofra character: a tomato chef, drawn as scalable layered shapes.
/// All illustration coordinates are inside its own vector canvas, never UI layout.
class ChefArt extends StatelessWidget {
  const ChefArt({
    super.key,
    this.size = 240,
    this.celebrate = false,
    this.compact = false,
  });
  final double size;
  final bool celebrate;
  final bool compact;
  @override
  Widget build(BuildContext context) => Semantics(
    label: celebrate
        ? 'شيف سفرة مبسوط وجاهز للطبخ'
        : 'شيف سفرة، طماطماية مرحة بقبعة شيف',
    image: true,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: .94, end: 1),
      duration: Sofra.motion(context),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: SizedBox(
        width: size,
        height: size * .88,
        child: CustomPaint(
          painter: _ChefPainter(celebrate: celebrate, compact: compact),
        ),
      ),
    ),
  );
}

class _ChefPainter extends CustomPainter {
  const _ChefPainter({required this.celebrate, required this.compact});
  final bool celebrate;
  final bool compact;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 320, s.height / 282);
    final p = Paint()..isAntiAlias = true;
    void oval(Rect r, Color color) => c.drawOval(
      r,
      p
        ..shader = null
        ..color = color,
    );
    void round(Rect r, double radius, Color color) => c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      p
        ..shader = null
        ..color = color,
    );
    void line(Offset a, Offset b, Color color, double width) => c.drawLine(
      a,
      b,
      p
        ..shader = null
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
    oval(const Rect.fromLTWH(45, 30, 238, 235), const Color(0xFFE5EFD9));
    oval(const Rect.fromLTWH(78, 248, 170, 18), const Color(0xFFD2DFCB));
    // Playful ingredients around the chef, with quiet contact shadows.
    if (!compact) {
      c.save();
      c.translate(278, 105);
      c.rotate(.35);
      oval(const Rect.fromLTWH(-17, -24, 34, 48), const Color(0xFFB6D395));
      line(
        const Offset(0, 15),
        const Offset(0, -14),
        const Color(0xFF729D60),
        3,
      );
      c.restore();
      c.save();
      c.translate(44, 184);
      c.rotate(-.4);
      round(const Rect.fromLTWH(-15, -22, 30, 49), 13, const Color(0xFFFFCD70));
      line(const Offset(-8, -25), const Offset(-15, -36), Sofra.green, 7);
      line(const Offset(0, -25), const Offset(1, -39), Sofra.green, 7);
      c.restore();
      for (final a in [const Offset(54, 85), const Offset(270, 214)]) {
        line(a.translate(-6, 0), a.translate(6, 0), const Color(0xFFDBB85C), 3);
        line(a.translate(0, -6), a.translate(0, 6), const Color(0xFFDBB85C), 3);
      }
    }
    // Feet and arms are behind the soft tomato body.
    oval(const Rect.fromLTWH(107, 231, 43, 25), const Color(0xFF264F3C));
    oval(const Rect.fromLTWH(173, 231, 43, 25), const Color(0xFF264F3C));
    line(
      const Offset(101, 157),
      const Offset(73, 190),
      const Color(0xFFDE6042),
      19,
    );
    line(
      const Offset(73, 190),
      const Offset(60, 178),
      const Color(0xFFEE855A),
      18,
    );
    line(
      const Offset(222, 150),
      Offset(celebrate ? 255 : 249, celebrate ? 115 : 171),
      const Color(0xFFDF6146),
      20,
    );
    if (celebrate) {
      oval(const Rect.fromLTWH(241, 92, 27, 32), const Color(0xFFFFAB7E));
    } else {
      line(
        const Offset(250, 174),
        const Offset(260, 122),
        const Color(0xFFC09861),
        8,
      );
      oval(const Rect.fromLTWH(249, 98, 27, 34), const Color(0xFFE7BD83));
      oval(const Rect.fromLTWH(256, 105, 12, 19), const Color(0xFFCE9D61));
    }
    final body = const Rect.fromLTWH(82, 91, 160, 151);
    p.shader = const RadialGradient(
      center: Alignment(-.55, -.65),
      radius: 1.25,
      colors: [
        Color(0xFFFFAE7C),
        Color(0xFFF58860),
        Color(0xFFE66A4E),
        Color(0xFFC94F3E),
      ],
      stops: [0, .38, .76, 1],
    ).createShader(body);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(66)), p);
    oval(const Rect.fromLTWH(99, 109, 30, 19), const Color(0x55FFE0BC));
    // Rounded apron and visible pocket give the little cook a tactile identity.
    round(const Rect.fromLTWH(117, 193, 92, 46), 22, const Color(0x337C4330));
    final apron = const Rect.fromLTWH(116, 189, 92, 46);
    p
      ..color = Colors.white
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFDEA), Color(0xFFE8EDCF)],
      ).createShader(apron);
    c.drawRRect(RRect.fromRectAndRadius(apron, const Radius.circular(22)), p);
    round(const Rect.fromLTWH(139, 210, 44, 15), 7, const Color(0xFFE0E9CE));
    line(
      const Offset(144, 212),
      const Offset(177, 212),
      const Color(0xFFCFDDBC),
      2,
    );
    line(
      const Offset(125, 194),
      const Offset(114, 180),
      const Color(0xFFF5F4DC),
      9,
    );
    line(
      const Offset(198, 194),
      const Offset(210, 180),
      const Color(0xFFF5F4DC),
      9,
    );
    // Tomato calyx peeking out from under the chef hat.
    final leaf = Path()
      ..moveTo(128, 104)
      ..quadraticBezierTo(147, 74, 161, 101)
      ..quadraticBezierTo(192, 78, 204, 107)
      ..quadraticBezierTo(180, 114, 163, 105)
      ..quadraticBezierTo(143, 119, 128, 104);
    c.drawPath(
      leaf,
      p
        ..shader = null
        ..color = const Color(0xFF36895A),
    );
    // One continuous hat silhouette keeps its soft crown visible on cream.
    round(const Rect.fromLTWH(121, 67, 87, 36), 13, const Color(0xFFDCE4CD));
    var hat = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(118, 59, 88, 35),
          const Radius.circular(13),
        ),
      );
    for (final crown in [
      const Rect.fromLTWH(101, 33, 54, 50),
      const Rect.fromLTWH(137, 15, 58, 65),
      const Rect.fromLTWH(177, 32, 49, 50),
    ]) {
      hat = Path.combine(PathOperation.union, hat, Path()..addOval(crown));
    }
    p
      ..color = Colors.white
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFEF6), Color(0xFFF6F6E8), Color(0xFFDEE5CD)],
        stops: [0, .62, 1],
      ).createShader(const Rect.fromLTWH(101, 15, 125, 80));
    c.drawPath(hat, p);
    c.drawPath(
      hat,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0xFFDDE4D0),
    );
    line(
      const Offset(128, 88),
      const Offset(195, 88),
      const Color(0xFFE8EDD9),
      5,
    );
    // Eyes look toward the person, with two little highlights.
    oval(const Rect.fromLTWH(119, 135, 35, 41), const Color(0x22A84131));
    oval(const Rect.fromLTWH(178, 135, 35, 41), const Color(0x22A84131));
    oval(const Rect.fromLTWH(117, 132, 35, 41), const Color(0xFFFFFEF4));
    oval(const Rect.fromLTWH(176, 132, 35, 41), const Color(0xFFFFFEF4));
    oval(const Rect.fromLTWH(128, 143, 17, 25), Sofra.ink);
    oval(const Rect.fromLTWH(182, 143, 17, 25), Sofra.ink);
    oval(const Rect.fromLTWH(130, 146, 5, 7), Colors.white);
    oval(const Rect.fromLTWH(184, 146, 5, 7), Colors.white);
    oval(const Rect.fromLTWH(107, 168, 21, 12), const Color(0xFFFFB18D));
    oval(const Rect.fromLTWH(200, 167, 20, 12), const Color(0xFFFFB18D));
    final smile = Path()
      ..moveTo(150, 176)
      ..quadraticBezierTo(164, 197, 179, 176)
      ..close();
    c.drawPath(smile, p..color = Sofra.ink);
    oval(const Rect.fromLTWH(159, 181, 14, 6), const Color(0xFFF9BDA8));
    if (celebrate) {
      final colors = [Sofra.green, Sofra.yellow, Sofra.orange];
      for (var i = 0; i < 9; i++) {
        final x = 35.0 + i * 31;
        final y = 24.0 + (i % 3) * 20;
        c.save();
        c.translate(x, y);
        c.rotate(i * .7);
        round(const Rect.fromLTWH(-3, -6, 6, 12), 2, colors[i % 3]);
        c.restore();
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_ChefPainter oldDelegate) =>
      oldDelegate.celebrate != celebrate || oldDelegate.compact != compact;
}

class MealArt extends StatelessWidget {
  const MealArt({super.key, this.kind = 0, this.size = 170});
  final int kind;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size * .82,
      child: CustomPaint(painter: _MealPainter(kind)),
    ),
  );
}

class _MealPainter extends CustomPainter {
  const _MealPainter(this.kind);
  final int kind;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 220, size.height / 180);
    final p = Paint()..isAntiAlias = true;
    void oval(Rect r, Color color) => c.drawOval(
      r,
      p
        ..shader = null
        ..color = color,
    );
    oval(const Rect.fromLTWH(15, 30, 194, 138), const Color(0xFFCFD9BE));
    oval(const Rect.fromLTWH(13, 22, 194, 138), const Color(0xFFF3F3E7));
    oval(const Rect.fromLTWH(20, 20, 180, 127), Colors.white);
    oval(const Rect.fromLTWH(38, 34, 145, 99), const Color(0xFFF0F1DF));
    if (kind == 1) {
      oval(const Rect.fromLTWH(48, 38, 125, 87), const Color(0xFFDB973A));
      oval(const Rect.fromLTWH(52, 38, 119, 74), const Color(0xFFF5BC58));
      for (var i = 0; i < 6; i++) {
        oval(
          Rect.fromLTWH(75.0 + i * 10, 61.0 + (i % 3) * 12, 10, 6),
          Sofra.green,
        );
      }
    } else if (kind == 2) {
      oval(const Rect.fromLTWH(45, 36, 134, 91), const Color(0xFFD96647));
      for (final o in [const Offset(75, 59), const Offset(115, 74)]) {
        oval(Rect.fromLTWH(o.dx, o.dy, 45, 33), const Color(0xFFFFF9DF));
        oval(
          Rect.fromLTWH(o.dx + 13, o.dy + 7, 21, 20),
          const Color(0xFFF7C347),
        );
      }
    } else if (kind == 3) {
      oval(const Rect.fromLTWH(63, 36, 100, 95), const Color(0xFFDDE7D2));
      oval(const Rect.fromLTWH(64, 31, 96, 84), Colors.white);
      c.drawArc(
        const Rect.fromLTWH(88, 52, 49, 35),
        0,
        math.pi * 1.7,
        false,
        p
          ..color = const Color(0xFFD99B38)
          ..strokeWidth = 9
          ..style = PaintingStyle.stroke,
      );
      p.style = PaintingStyle.fill;
    } else {
      oval(const Rect.fromLTWH(49, 40, 70, 78), const Color(0xFFFFFCDF));
      for (var i = 0; i < 24; i++) {
        oval(
          Rect.fromLTWH(56 + (i % 5) * 10.0, 49 + (i ~/ 5) * 12.0, 8, 3),
          const Color(0xFFE1DCC0),
        );
      }
      final chicken = const Rect.fromLTWH(98, 59, 70, 50);
      p.shader = const LinearGradient(
        colors: [Color(0xFFECA34C), Color(0xFFC76A31)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(chicken);
      c.drawRRect(
        RRect.fromRectAndRadius(chicken, const Radius.circular(24)),
        p,
      );
      c.drawLine(
        const Offset(149, 98),
        const Offset(164, 112),
        p
          ..shader = null
          ..color = const Color(0xFFFFF5D9)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
      oval(const Rect.fromLTWH(158, 107, 16, 13), const Color(0xFFFFF5D9));
      for (var i = 0; i < 4; i++) {
        oval(
          Rect.fromLTWH(114 + i * 12.0, 35 + (i % 2) * 13.0, 20, 14),
          i.isEven ? const Color(0xFF74A85B) : const Color(0xFF9AC375),
        );
      }
      oval(const Rect.fromLTWH(147, 43, 17, 15), const Color(0xFFF08358));
      oval(const Rect.fromLTWH(131, 34, 14, 13), const Color(0xFFE87450));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_MealPainter oldDelegate) => oldDelegate.kind != kind;
}
