import 'package:flutter/material.dart';

import '../ui/design.dart';
import 'recipes_screen.dart';

/// Cartoon book colours: flat fills and one dark outline, no texture or glow.
abstract final class Book {
  static const ink = Color(0xFF3A2416);
  static const cover = Color(0xFF9A6240);
  static const page = Color(0xFFFFF4DC);
  static const pageEdge = Color(0xFFF2DFB4);
  static const ribbon = Color(0xFFD9534F);
  static const marker = Color(0xFFF6C453);
  static const line = 2.5;
}

BoxDecoration _outlined(Color fill, double radius) => BoxDecoration(
  color: fill,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: Book.ink, width: Book.line),
);

/// The recipe book opened over the kitchen, drawn like a cartoon: a brown
/// cover, the page edges underneath, the spine on the right (Arabic binding)
/// and a red ribbon.
class RecipeBook extends StatelessWidget {
  const RecipeBook({super.key, required this.open, required this.top});
  final bool open;
  final double top;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 100;
    return Positioned(
      left: 12,
      right: 12,
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

class _Cover extends StatelessWidget {
  const _Cover({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: _outlined(Book.cover, Sofra.r22),
    padding: const EdgeInsetsDirectional.fromSTEB(8, 10, 14, 10),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        // Edges of the pages underneath, stepping out on the left.
        Positioned.fill(
          right: 8,
          child: DecoratedBox(decoration: _outlined(Book.pageEdge, Sofra.r16)),
        ),
        Positioned.fill(left: 7, child: child),
        const PositionedDirectional(top: -12, end: 64, child: _Ribbon()),
      ],
    ),
  );
}

class _Ribbon extends StatelessWidget {
  const _Ribbon();
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 22,
    height: 64,
    child: CustomPaint(painter: _RibbonPainter()),
  );
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w / 2, h - 9)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = Book.ribbon);
    canvas.drawPath(
      path,
      Paint()
        ..color = Book.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Book.line
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => false;
}

class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Sofra.r16),
      borderSide: const BorderSide(color: Book.ink, width: 2),
    );
    final theme = base.copyWith(
      iconTheme: const IconThemeData(color: Book.ink),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline,
        hintStyle: TextStyle(color: Book.ink.withValues(alpha: .5)),
        prefixIconColor: Book.ink,
      ),
      chipTheme: base.chipTheme.copyWith(
        color: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Book.marker
              : Colors.white,
        ),
        side: const BorderSide(color: Book.ink, width: 2),
        labelStyle: const TextStyle(
          color: Book.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return Container(
      decoration: _outlined(Book.page, Sofra.r16),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // The spine: a flat band where the page meets the binding.
          const PositionedDirectional(
            top: 0,
            bottom: 0,
            start: 0,
            width: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Book.pageEdge,
                border: BorderDirectional(
                  end: BorderSide(color: Book.ink, width: 2),
                ),
              ),
            ),
          ),
          Theme(
            data: theme,
            child: const Paper(
              child: DefaultTextStyle(
                style: TextStyle(color: Book.ink, fontSize: 15),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: 18),
                  child: Column(
                    children: [
                      SizedBox(height: 16),
                      Text(
                        'كتاب الوصفات',
                        style: TextStyle(
                          fontFamily: 'ArefRuqaa',
                          fontSize: 32,
                          height: 1.25,
                          color: Book.ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      _Rule(),
                      Expanded(child: RecipesScreen()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A short rule with a dot under the heading.
class _Rule extends StatelessWidget {
  const _Rule();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(width: 48, height: Book.line, color: Book.ink),
      Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Book.marker,
          shape: BoxShape.circle,
          border: Border.all(color: Book.ink, width: 2),
        ),
      ),
      Container(width: 48, height: Book.line, color: Book.ink),
    ],
  );
}
