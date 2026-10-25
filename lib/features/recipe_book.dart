import 'package:flutter/material.dart';

import '../ui/design.dart';
import 'recipes_screen.dart';

/// The recipe book opened over the kitchen: a leather cover, a stack of page
/// edges, the spine on the right (Arabic binding) and an aged, stained page
/// (`assets/ui/paper-page.webp`, made by `tool/ui/make_paper.py`).
class RecipeBook extends StatelessWidget {
  const RecipeBook({super.key, required this.open, required this.top});
  final bool open;
  final double top;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 100;
    return Positioned(
      left: 8,
      right: 8,
      top: top,
      bottom: bottom,
      child: IgnorePointer(
        ignoring: !open,
        child: AnimatedSlide(
          offset: open ? Offset.zero : const Offset(0, 1.15),
          duration: Sofra.motion(context),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: open ? 1 : 0,
            duration: Sofra.motion(context, true),
            child: _Cover(child: open ? const _Page() : const SizedBox()),
          ),
        ),
      ),
    );
  }
}

/// Dark leather boards with a stitched border, showing round the page.
class _Cover extends StatelessWidget {
  const _Cover({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF5A3721), Color(0xFF3B2215), Color(0xFF2C180E)],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x99000000),
          blurRadius: 34,
          offset: Offset(0, 18),
        ),
      ],
    ),
    child: CustomPaint(
      painter: _StitchPainter(),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(6, 9, 13, 9),
        child: Stack(
          children: [
            // Page edges of the rest of the book, stepping out on the left.
            for (final (i, inset) in const [7.0, 4.0].indexed)
              Positioned(
                left: 0,
                right: inset * 2,
                top: 2 + inset * .6,
                bottom: 2 + inset * .6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0xFFCDB68A),
                      const Color(0xFFDCC79E),
                      i / 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0x334A3A28)),
                  ),
                ),
              ),
            Positioned.fill(left: 10, child: child),
            const PositionedDirectional(top: -9, end: 70, child: _Ribbon()),
          ],
        ),
      ),
    ),
  );
}

class _StitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(4),
      const Radius.circular(14),
    );
    final path = Path()..addRRect(r);
    final paint = Paint()
      ..color = const Color(0xFFC9A46A).withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_StitchPainter old) => false;
}

/// A red silk bookmark hanging over the top edge.
class _Ribbon extends StatelessWidget {
  const _Ribbon();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 18,
    height: 74,
    child: CustomPaint(painter: _RibbonPainter()),
  );
}

class _RibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w / 2, h - 8)
      ..lineTo(0, h)
      ..close();
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF7E1F1A), Color(0xFFA8322A), Color(0xFF7E1F1A)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => false;
}

/// The page: aged paper, the spine's shade on the right, a calligraphic
/// heading and the recipes written into it.
class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final inkLine = UnderlineInputBorder(
      borderSide: BorderSide(color: Paper.ink.withValues(alpha: .45)),
    );
    final theme = base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: 'Amiri',
        bodyColor: Paper.ink,
        displayColor: Paper.ink,
      ),
      iconTheme: const IconThemeData(color: Paper.ink),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: inkLine,
        enabledBorder: inkLine,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Paper.ink, width: 1.4),
        ),
        hintStyle: TextStyle(color: Paper.ink.withValues(alpha: .55)),
        prefixIconColor: Paper.ink,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.transparent,
        color: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Paper.ink.withValues(alpha: .14)
              : Colors.transparent,
        ),
        selectedColor: Paper.ink.withValues(alpha: .12),
        side: BorderSide(color: Paper.ink.withValues(alpha: .35)),
        labelStyle: const TextStyle(
          color: Paper.ink,
          fontFamily: 'Amiri',
          fontSize: 14,
        ),
        checkmarkColor: Paper.ink,
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/ui/paper-page.webp',
          fit: BoxFit.fill,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => const CustomPaint(painter: PaperPainter()),
        ),
        const IgnorePointer(child: CustomPaint(painter: _SpineShade())),
        Theme(
          data: theme,
          child: const Paper(
            child: DefaultTextStyle(
              style: TextStyle(
                color: Paper.ink,
                fontFamily: 'Amiri',
                fontSize: 16,
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: 22, end: 8),
                child: Column(
                  children: [
                    SizedBox(height: 18),
                    Text(
                      'كتاب الوصفات',
                      style: TextStyle(
                        fontFamily: 'ArefRuqaa',
                        fontSize: 34,
                        height: 1.2,
                        color: Color(0xFF3E2A18),
                      ),
                    ),
                    Text(
                      'وصفات البيت، مكتوبة بإيد أصحابها',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B5236)),
                    ),
                    SizedBox(height: 6),
                    _Flourish(),
                    Expanded(child: RecipesScreen()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shade where the page curves into the spine (right) and a soft lift on the
/// outer edge.
class _SpineShade extends CustomPainter {
  const _SpineShade();
  @override
  void paint(Canvas canvas, Size size) {
    final spine = Rect.fromLTWH(size.width - 44, 0, 44, size.height);
    canvas.drawRect(
      spine,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            const Color(0xFF4A3018).withValues(alpha: .18),
            const Color(0xFF2A1A0C).withValues(alpha: .45),
          ],
          stops: const [0, .7, 1],
        ).createShader(spine),
    );
  }

  @override
  bool shouldRepaint(_SpineShade old) => false;
}

/// Ornamental rule under the heading.
class _Flourish extends StatelessWidget {
  const _Flourish();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(width: 70, height: 1, color: Paper.ink.withValues(alpha: .4)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text('❦', style: TextStyle(fontSize: 18, color: Paper.ink)),
      ),
      Container(width: 70, height: 1, color: Paper.ink.withValues(alpha: .4)),
    ],
  );
}
