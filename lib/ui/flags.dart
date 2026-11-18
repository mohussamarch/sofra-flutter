import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design.dart';

/// A simplified round flag for a country or cuisine code (for example
/// 'egyptian'); [known] says whether one is drawn for [code].
class CountryFlag extends StatelessWidget {
  const CountryFlag(this.code, {super.key, this.size = 24});
  final String code;
  final double size;

  static bool known(String code) => FlagPainter.drawn.contains(code);

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Sofra.line, width: 1.5),
    ),
    child: ClipOval(child: CustomPaint(painter: FlagPainter(code))),
  );
}

/// The flag for a catalog cuisine name, or a globe when it has none.
class CuisineFlag extends StatelessWidget {
  const CuisineFlag(this.cuisine, {super.key, this.size = 24});
  final String cuisine;
  final double size;

  @override
  Widget build(BuildContext context) {
    final code = flagCodeFor(cuisine);
    if (code != null && CountryFlag.known(code)) {
      return CountryFlag(code, size: size);
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Sofra.cream,
      ),
      child: Icon(Icons.public_rounded, size: size * .7, color: Sofra.muted),
    );
  }
}

/// The flag code for an Arabic catalog cuisine name such as «مصري», or null
/// when the cuisine is regional or mixed and has no single flag (شامي،
/// متوسطي، كشميري، تبتي، آسيوي، عالمي متنوع، غير محدد، أمريكي جنوبي) or is
/// unknown. Regional cuisines map to their country (بنجابي → indian).
/// Hamza forms, diacritics and spacing are ignored; a drawn code is returned
/// as is.
String? flagCodeFor(String cuisine) {
  final key = _normalise(cuisine);
  if (FlagPainter.drawn.contains(key)) return key;
  final code = _codes[key];
  if (code != null) return code;
  if (key.endsWith('ة')) return _codes[key.substring(0, key.length - 1)];
  return null;
}

final _marks = RegExp('[ً-ْٰـ]');
final _alef = RegExp('[أإآٱ]');
final _space = RegExp(r'\s+');

String _normalise(String s) => s
    .trim()
    .replaceAll(_marks, '')
    .replaceAll(_alef, 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll(_space, ' ')
    .toLowerCase();

final Map<String, String> _codes = {
  for (final e in const {
    'مصري': 'egyptian',
    'سعودي': 'saudi',
    'مغربي': 'moroccan',
    'إيطالي': 'italian',
    'فرنسي': 'french',
    'يوناني': 'greek',
    'إسباني': 'spanish',
    'تركي': 'turkish',
    'صيني': 'chinese',
    'ياباني': 'japanese',
    'هندي': 'indian',
    'تايلاندي': 'thai',
    'كوري': 'korean',
    'مكسيكي': 'mexican',
    'تونسي': 'tunisian',
    'لبناني': 'lebanese',
    'فلسطيني': 'palestinian',
    'يمني': 'yemeni',
    'أردني': 'jordanian',
    'سوري': 'syrian',
    'عُماني': 'omani',
    'إماراتي': 'emirati',
    'كويتي': 'kuwaiti',
    'جزائري': 'algerian',
    'ليبي': 'libyan',
    'سوداني': 'sudanese',
    'باكستاني': 'pakistani',
    'أيرلندي': 'irish',
    'بيروفي': 'peruvian',
    'جامايكي': 'jamaican',
    'أمريكي': 'american',
    'برازيلي': 'brazilian',
    'روسي': 'russian',
    'أوزبكي': 'uzbek',
    'مجري': 'hungarian',
    'برتغالي': 'portuguese',
    'بولندي': 'polish',
    'ألماني': 'german',
    'أوكراني': 'ukrainian',
    'سويدي': 'swedish',
    'فنلندي': 'finnish',
    'نمساوي': 'austrian',
    'أرجنتيني': 'argentinian',
    'فلبيني': 'filipino',
    'فيتنامي': 'vietnamese',
    'إندونيسي': 'indonesian',
    'ماليزي': 'malaysian',
    'إثيوبي': 'ethiopian',
    'بريطاني': 'british',
    'أسترالي': 'australian',
    'بوسني': 'bosnian',
    'دومينيكاني': 'dominican',
    'ليتواني': 'lithuanian',
    'مالطي': 'maltese',
    'فنزويلي': 'venezuelan',
    'سويسري': 'swiss',
    'هولندي': 'dutch',
    'بلجيكي': 'belgian',
    // Regional cuisines take their country's flag.
    'بنجابي': 'indian',
    'سيتشواني': 'chinese',
    'كاجوني': 'american',
    'إيطالي أمريكي': 'american',
    'مكسيكي أمريكي': 'american',
  }.entries)
    _normalise(e.key): e.value,
};

class FlagPainter extends CustomPainter {
  const FlagPainter(this.code);
  final String code;

  static const drawn = {
    'egyptian',
    'saudi',
    'moroccan',
    'italian',
    'french',
    'greek',
    'spanish',
    'turkish',
    'chinese',
    'japanese',
    'indian',
    'thai',
    'korean',
    'mexican',
    'tunisian',
    'lebanese',
    'palestinian',
    'yemeni',
    'jordanian',
    'syrian',
    'omani',
    'emirati',
    'kuwaiti',
    'algerian',
    'libyan',
    'sudanese',
    'pakistani',
    'irish',
    'peruvian',
    'jamaican',
    'american',
    'brazilian',
    'russian',
    'uzbek',
    'hungarian',
    'portuguese',
    'polish',
    'german',
    'ukrainian',
    'swedish',
    'finnish',
    'austrian',
    'argentinian',
    'filipino',
    'vietnamese',
    'indonesian',
    'malaysian',
    'ethiopian',
    'british',
    'australian',
    'bosnian',
    'dominican',
    'lithuanian',
    'maltese',
    'venezuelan',
    'swiss',
    'dutch',
    'belgian',
  };

  static const _white = Colors.white;
  static const _black = Color(0xFF111111);

  void _bands(
    Canvas c,
    Size s,
    List<Color> colors, {
    bool vertical = false,
    Rect? area,
  }) {
    final r = area ?? Offset.zero & s;
    final total = colors.length;
    for (var i = 0; i < total; i++) {
      final paint = Paint()..color = colors[i];
      c.drawRect(
        vertical
            ? Rect.fromLTWH(
                r.left + r.width * i / total,
                r.top,
                r.width / total,
                r.height,
              )
            : Rect.fromLTWH(
                r.left,
                r.top + r.height * i / total,
                r.width,
                r.height / total,
              ),
        paint,
      );
    }
  }

  Path _star(Offset o, double r, {double inner = .4, int points = 5}) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? r : r * inner;
      final a = -math.pi / 2 + i * math.pi / points;
      final p = o + Offset(math.cos(a) * radius, math.sin(a) * radius);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  /// A crescent: the disc at [o] with the disc at [o] + [cut] removed.
  Path _crescent(Offset o, double r, Offset cut, double cutR) => Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: o, radius: r)),
    Path()..addOval(Rect.fromCircle(center: o + cut, radius: cutR)),
  );

  /// A triangle from the hoist (left) edge to [depth] of the width.
  void _hoist(Canvas c, Size s, double depth, Color color) => c.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(s.width * depth, s.height / 2)
      ..lineTo(0, s.height)
      ..close(),
    Paint()..color = color,
  );

  /// A Nordic cross with its upright towards the hoist.
  void _nordic(Canvas c, Size s, Color bg, Color cross, double t) {
    c.drawRect(Offset.zero & s, Paint()..color = bg);
    final p = Paint()..color = cross;
    c.drawRect(
      Rect.fromLTWH(s.width * .38 - s.width * t / 2, 0, s.width * t, s.height),
      p,
    );
    c.drawRect(
      Rect.fromLTWH(0, s.height * (.5 - t / 2), s.width, s.height * t),
      p,
    );
  }

  void _union(Canvas c, Rect r) {
    const navy = Color(0xFF012169), red = Color(0xFFC8102E);
    c.save();
    c.clipRect(r);
    c.drawRect(r, Paint()..color = navy);
    final u = r.shortestSide;
    final white = Paint()
      ..color = _white
      ..strokeWidth = u * .2;
    c.drawLine(r.topLeft, r.bottomRight, white);
    c.drawLine(r.topRight, r.bottomLeft, white);
    // The red saltire is counterchanged: in each arm it sits off-centre,
    // on the side that comes next going anticlockwise (below the arm in the
    // upper hoist quarter).
    final diagonal = Paint()
      ..color = red
      ..strokeWidth = u * .067;
    for (final (corner, side) in [
      (r.topLeft, const Offset(-1, 1)),
      (r.topRight, const Offset(-1, -1)),
      (r.bottomRight, const Offset(1, -1)),
      (r.bottomLeft, const Offset(1, 1)),
    ]) {
      final shift = side / math.sqrt2 * (u * .033);
      c.save();
      c.clipRect(Rect.fromPoints(r.center, corner));
      c.drawLine(r.center + shift, corner + shift, diagonal);
      c.restore();
    }
    for (final (paint, t) in [(_white, .3), (red, .18)]) {
      final p = Paint()..color = paint;
      c.drawRect(
        Rect.fromCenter(center: r.center, width: r.width, height: u * t),
        p,
      );
      c.drawRect(
        Rect.fromCenter(center: r.center, width: u * t, height: r.height),
        p,
      );
    }
    c.restore();
  }

  void _sun(Canvas c, Offset o, double r, Color color) {
    final p = Paint()..color = color;
    c.drawCircle(o, r, p);
    final ray = Paint()
      ..color = color
      ..strokeWidth = r * .35
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(o + d * r * 1.3, o + d * r * 1.75, ray);
    }
  }

  @override
  void paint(Canvas canvas, Size s) {
    final mid = s.center(Offset.zero);
    final w = s.width;
    final h = s.height;
    Offset at(double x, double y) => Offset(w * x, h * y);
    Paint fill(Color color) => Paint()..color = color;
    switch (code) {
      case 'egyptian':
        _bands(canvas, s, const [Color(0xFFCE1126), _white, _black]);
        canvas.drawCircle(mid, w * .09, fill(const Color(0xFFC09300)));
      case 'saudi':
        canvas.drawColor(const Color(0xFF006C35), BlendMode.src);
        final white = Paint()
          ..color = _white
          ..strokeWidth = w * .05
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(at(.25, .62), at(.75, .62), white);
        for (var i = 0; i < 4; i++) {
          canvas.drawCircle(at(.3 + i * .13, .42), w * .035, white);
        }
      case 'moroccan':
        canvas.drawColor(const Color(0xFFC1272D), BlendMode.src);
        canvas.drawPath(
          _star(mid, w * .26, inner: .38),
          Paint()
            ..color = const Color(0xFF006233)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * .05,
        );
      case 'italian':
        _bands(canvas, s, const [
          Color(0xFF009246),
          _white,
          Color(0xFFCE2B37),
        ], vertical: true);
      case 'french':
        _bands(canvas, s, const [
          Color(0xFF0055A4),
          _white,
          Color(0xFFEF4135),
        ], vertical: true);
      case 'greek':
        const blue = Color(0xFF0D5EAF);
        _bands(canvas, s, [
          for (var i = 0; i < 9; i++) i.isEven ? blue : _white,
        ]);
        final box = Rect.fromLTWH(0, 0, w * .45, h * 5 / 9);
        canvas.drawRect(box, fill(blue));
        canvas.drawRect(
          Rect.fromCenter(center: box.center, width: box.width, height: h / 9),
          fill(_white),
        );
        canvas.drawRect(
          Rect.fromCenter(center: box.center, width: w / 9, height: box.height),
          fill(_white),
        );
      case 'spanish':
        _bands(canvas, s, const [
          Color(0xFFAA151B),
          Color(0xFFF1BF00),
          Color(0xFFF1BF00),
          Color(0xFFAA151B),
        ]);
      case 'turkish':
        const red = Color(0xFFE30A17);
        canvas.drawColor(red, BlendMode.src);
        canvas.drawCircle(at(.42, .5), w * .24, fill(_white));
        canvas.drawCircle(at(.48, .5), w * .19, fill(red));
        canvas.drawPath(_star(at(.7, .5), w * .1), fill(_white));
      case 'chinese':
        canvas.drawColor(const Color(0xFFDE2910), BlendMode.src);
        final gold = fill(const Color(0xFFFFDE00));
        canvas.drawPath(_star(at(.38, .42), w * .2), gold);
        for (final (dx, dy) in const [
          (.62, .2),
          (.73, .32),
          (.73, .49),
          (.62, .62),
        ]) {
          canvas.drawPath(_star(at(dx, dy), w * .055), gold);
        }
      case 'japanese':
        canvas.drawColor(_white, BlendMode.src);
        canvas.drawCircle(mid, w * .24, fill(const Color(0xFFBC002D)));
      case 'indian':
        _bands(canvas, s, const [Color(0xFFFF9933), _white, Color(0xFF138808)]);
        canvas.drawCircle(
          mid,
          w * .11,
          Paint()
            ..color = const Color(0xFF000080)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * .03,
        );
      case 'thai':
        const red = Color(0xFFA51931), white = Color(0xFFF4F5F8);
        _bands(canvas, s, const [
          red,
          white,
          Color(0xFF2D2A4A),
          Color(0xFF2D2A4A),
          white,
          red,
        ]);
      case 'korean':
        canvas.drawColor(_white, BlendMode.src);
        const red = Color(0xFFCD2E3A), blue = Color(0xFF0047A0);
        final r = w * .22;
        final box = Rect.fromCircle(center: mid, radius: r);
        canvas.drawArc(box, math.pi, math.pi, true, fill(red));
        canvas.drawArc(box, 0, math.pi, true, fill(blue));
        canvas.drawCircle(mid - Offset(r / 2, 0), r / 2, fill(red));
        canvas.drawCircle(mid + Offset(r / 2, 0), r / 2, fill(blue));
        final black = Paint()
          ..color = Colors.black
          ..strokeWidth = w * .035;
        for (final (a, b) in [
          (at(.12, .2), at(.26, .1)),
          (at(.74, .1), at(.88, .2)),
          (at(.12, .8), at(.26, .9)),
          (at(.74, .9), at(.88, .8)),
        ]) {
          canvas.drawLine(a, b, black);
        }
      case 'mexican':
        _bands(canvas, s, const [
          Color(0xFF006847),
          _white,
          Color(0xFFCE1126),
        ], vertical: true);
        canvas.drawCircle(mid, w * .08, fill(const Color(0xFF8C5A2B)));
      case 'tunisian':
        const red = Color(0xFFE70013);
        canvas.drawColor(red, BlendMode.src);
        canvas.drawCircle(mid, w * .28, fill(_white));
        canvas.drawPath(
          _crescent(at(.47, .5), w * .2, Offset(w * .06, 0), w * .16),
          fill(red),
        );
        canvas.drawPath(_star(at(.57, .5), w * .09), fill(red));
      case 'lebanese':
        const red = Color(0xFFED1C24);
        _bands(canvas, s, const [red, _white, _white, red]);
        final cedar = Path();
        for (final (top, bottom, half) in const [
          (.27, .41, .09),
          (.35, .52, .14),
          (.45, .64, .2),
        ]) {
          cedar
            ..moveTo(w * .5, h * top)
            ..lineTo(w * (.5 + half), h * bottom)
            ..lineTo(w * (.5 - half), h * bottom)
            ..close();
        }
        cedar.addRect(Rect.fromLTRB(w * .47, h * .62, w * .53, h * .72));
        canvas.drawPath(cedar, fill(const Color(0xFF00A651)));
      case 'palestinian':
        _bands(canvas, s, const [_black, _white, Color(0xFF009736)]);
        _hoist(canvas, s, .45, const Color(0xFFEE2A35));
      case 'yemeni':
        _bands(canvas, s, const [Color(0xFFCE1126), _white, _black]);
      case 'jordanian':
        _bands(canvas, s, const [_black, _white, Color(0xFF007A3D)]);
        _hoist(canvas, s, .5, const Color(0xFFCE1126));
        canvas.drawPath(
          _star(at(.19, .5), w * .07, points: 7, inner: .5),
          fill(_white),
        );
      case 'syrian':
        // The flag in use since 2025: green, white and black with three red
        // stars.
        _bands(canvas, s, const [Color(0xFF007A3D), _white, _black]);
        final red = fill(const Color(0xFFCE1126));
        for (final x in const [.27, .5, .73]) {
          canvas.drawPath(_star(at(x, .5), w * .085), red);
        }
      case 'omani':
        const red = Color(0xFFDB161B);
        _bands(canvas, s, const [
          _white,
          red,
          Color(0xFF008000),
        ], area: Rect.fromLTRB(w * .3, 0, w, h));
        canvas.drawRect(Rect.fromLTRB(0, 0, w * .3, h), fill(red));
      case 'emirati':
        _bands(canvas, s, const [
          Color(0xFF00732F),
          _white,
          _black,
        ], area: Rect.fromLTRB(w * .28, 0, w, h));
        canvas.drawRect(
          Rect.fromLTRB(0, 0, w * .28, h),
          fill(const Color(0xFFFF0000)),
        );
      case 'kuwaiti':
        _bands(canvas, s, const [Color(0xFF007A3D), _white, Color(0xFFCE1126)]);
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..lineTo(w * .3, h / 3)
            ..lineTo(w * .3, h * 2 / 3)
            ..lineTo(0, h)
            ..close(),
          fill(_black),
        );
      case 'algerian':
        const red = Color(0xFFD21034);
        _bands(canvas, s, const [Color(0xFF006233), _white], vertical: true);
        canvas.drawPath(
          _crescent(at(.49, .5), w * .24, Offset(w * .07, 0), w * .2),
          fill(red),
        );
        canvas.drawPath(_star(at(.61, .5), w * .1), fill(red));
      case 'libyan':
        _bands(canvas, s, const [
          Color(0xFFE70013),
          _black,
          _black,
          Color(0xFF239E46),
        ]);
        canvas.drawPath(
          _crescent(at(.46, .5), w * .15, Offset(w * .04, 0), w * .125),
          fill(_white),
        );
        canvas.drawPath(_star(at(.59, .5), w * .065), fill(_white));
      case 'sudanese':
        _bands(canvas, s, const [Color(0xFFD21034), _white, _black]);
        _hoist(canvas, s, .42, const Color(0xFF007229));
      case 'pakistani':
        canvas.drawColor(const Color(0xFF01411C), BlendMode.src);
        canvas.drawRect(Rect.fromLTRB(0, 0, w * .25, h), fill(_white));
        canvas.drawPath(
          _crescent(at(.6, .52), w * .23, Offset(w * .07, -h * .06), w * .2),
          fill(_white),
        );
        canvas.drawPath(_star(at(.72, .4), w * .08), fill(_white));
      case 'irish':
        _bands(canvas, s, const [
          Color(0xFF169B62),
          _white,
          Color(0xFFFF883E),
        ], vertical: true);
      case 'peruvian':
        _bands(canvas, s, const [
          Color(0xFFD91023),
          _white,
          Color(0xFFD91023),
        ], vertical: true);
      case 'jamaican':
        canvas.drawColor(const Color(0xFF009B3A), BlendMode.src);
        for (final x in [0.0, w]) {
          canvas.drawPath(
            Path()
              ..moveTo(x, 0)
              ..lineTo(mid.dx, mid.dy)
              ..lineTo(x, h)
              ..close(),
            fill(_black),
          );
        }
        final gold = Paint()
          ..color = const Color(0xFFFED100)
          ..strokeWidth = w * .15;
        canvas.drawLine(Offset.zero, Offset(w, h), gold);
        canvas.drawLine(Offset(w, 0), Offset(0, h), gold);
      case 'american':
        _bands(canvas, s, [
          for (var i = 0; i < 13; i++)
            i.isEven ? const Color(0xFFB22234) : _white,
        ]);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, w * .5, h * 7 / 13),
          fill(const Color(0xFF3C3B6E)),
        );
        for (final x in const [.2, .3, .4]) {
          for (final y in const [.17, .29, .41]) {
            canvas.drawCircle(at(x, y), w * .025, fill(_white));
          }
        }
      case 'brazilian':
        canvas.drawColor(const Color(0xFF009C3B), BlendMode.src);
        canvas.drawPath(
          Path()
            ..moveTo(w * .07, h * .5)
            ..lineTo(w * .5, h * .16)
            ..lineTo(w * .93, h * .5)
            ..lineTo(w * .5, h * .84)
            ..close(),
          fill(const Color(0xFFFFDF00)),
        );
        canvas.drawCircle(mid, w * .2, fill(const Color(0xFF002776)));
        canvas.save();
        canvas.clipPath(
          Path()..addOval(Rect.fromCircle(center: mid, radius: w * .2)),
        );
        canvas.drawPath(
          Path()
            ..moveTo(w * .28, h * .44)
            ..quadraticBezierTo(w * .5, h * .4, w * .72, h * .56),
          Paint()
            ..color = _white
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * .045,
        );
        canvas.restore();
      case 'russian':
        _bands(canvas, s, const [_white, Color(0xFF0039A6), Color(0xFFD52B1E)]);
      case 'uzbek':
        const red = Color(0xFFCE1126);
        canvas.drawRect(
          Rect.fromLTRB(0, 0, w, h * .33),
          fill(const Color(0xFF0099B5)),
        );
        canvas.drawRect(Rect.fromLTRB(0, h * .33, w, h * .67), fill(red));
        canvas.drawRect(Rect.fromLTRB(0, h * .355, w, h * .645), fill(_white));
        canvas.drawRect(
          Rect.fromLTRB(0, h * .67, w, h),
          fill(const Color(0xFF1EB53A)),
        );
        canvas.drawPath(
          _crescent(at(.3, .17), w * .1, Offset(w * .035, 0), w * .085),
          fill(_white),
        );
      case 'hungarian':
        _bands(canvas, s, const [Color(0xFFCD2A3E), _white, Color(0xFF436F4D)]);
      case 'portuguese':
        canvas.drawRect(
          Rect.fromLTRB(0, 0, w * .4, h),
          fill(const Color(0xFF006600)),
        );
        canvas.drawRect(
          Rect.fromLTRB(w * .4, 0, w, h),
          fill(const Color(0xFFFF0000)),
        );
        final c = at(.4, .5);
        canvas.drawCircle(
          c,
          w * .17,
          Paint()
            ..color = const Color(0xFFFFE900)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * .05,
        );
        canvas.drawRect(
          Rect.fromCenter(center: c, width: w * .13, height: h * .15),
          fill(_white),
        );
        canvas.drawRect(
          Rect.fromCenter(center: c, width: w * .08, height: h * .1),
          fill(const Color(0xFFFF0000)),
        );
      case 'polish':
        _bands(canvas, s, const [_white, Color(0xFFDC143C)]);
      case 'german':
        _bands(canvas, s, const [_black, Color(0xFFDD0000), Color(0xFFFFCE00)]);
      case 'ukrainian':
        _bands(canvas, s, const [Color(0xFF0057B7), Color(0xFFFFD700)]);
      case 'swedish':
        _nordic(
          canvas,
          s,
          const Color(0xFF006AA7),
          const Color(0xFFFECC00),
          .16,
        );
      case 'finnish':
        _nordic(canvas, s, _white, const Color(0xFF002F6C), .18);
      case 'austrian':
        _bands(canvas, s, const [Color(0xFFED2939), _white, Color(0xFFED2939)]);
      case 'argentinian':
        const blue = Color(0xFF74ACDF);
        _bands(canvas, s, const [blue, _white, blue]);
        _sun(canvas, mid, w * .075, const Color(0xFFF6B40E));
      case 'filipino':
        _bands(canvas, s, const [Color(0xFF0038A8), Color(0xFFCE1126)]);
        _hoist(canvas, s, .5, _white);
        _sun(canvas, at(.17, .5), w * .065, const Color(0xFFFCD116));
      case 'vietnamese':
        canvas.drawColor(const Color(0xFFDA251D), BlendMode.src);
        canvas.drawPath(_star(mid, w * .3), fill(const Color(0xFFFFFF00)));
      case 'indonesian':
        _bands(canvas, s, const [Color(0xFFCE1126), _white]);
      case 'malaysian':
        _bands(canvas, s, [
          for (var i = 0; i < 14; i++)
            i.isEven ? const Color(0xFFCC0001) : _white,
        ]);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, w * .52, h * 8 / 14),
          fill(const Color(0xFF010066)),
        );
        const yellow = Color(0xFFFFCC00);
        canvas.drawPath(
          _crescent(at(.24, .29), w * .14, Offset(w * .045, 0), w * .12),
          fill(yellow),
        );
        canvas.drawPath(
          _star(at(.38, .29), w * .08, points: 14, inner: .5),
          fill(yellow),
        );
      case 'ethiopian':
        _bands(canvas, s, const [
          Color(0xFF078930),
          Color(0xFFFCDD09),
          Color(0xFFDA121A),
        ]);
        canvas.drawCircle(mid, w * .2, fill(const Color(0xFF0F47AF)));
        canvas.drawPath(
          _star(mid, w * .15, inner: .38),
          Paint()
            ..color = const Color(0xFFFCDD09)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * .03,
        );
      case 'british':
        _union(canvas, Offset.zero & s);
      case 'australian':
        canvas.drawColor(const Color(0xFF012169), BlendMode.src);
        _union(canvas, Rect.fromLTWH(0, 0, w * .5, h * .5));
        canvas.drawPath(
          _star(at(.27, .75), w * .1, points: 7, inner: .45),
          fill(_white),
        );
        for (final (x, y, r) in const [
          (.75, .22, .055),
          (.6, .48, .055),
          (.88, .42, .055),
          (.75, .8, .06),
        ]) {
          canvas.drawPath(
            _star(at(x, y), w * r, points: 7, inner: .45),
            fill(_white),
          );
        }
      case 'bosnian':
        canvas.drawColor(const Color(0xFF002395), BlendMode.src);
        canvas.drawPath(
          Path()
            ..moveTo(w * .28, 0)
            ..lineTo(w * .76, 0)
            ..lineTo(w * .76, h)
            ..close(),
          fill(const Color(0xFFFECB00)),
        );
        for (var i = 0; i < 7; i++) {
          final t = .07 + i * .145;
          canvas.drawPath(
            _star(at(.28 + t * .48 - .09, t), w * .045),
            fill(_white),
          );
        }
      case 'dominican':
        const blue = Color(0xFF002D62), red = Color(0xFFCE1126);
        canvas.drawRect(Rect.fromLTRB(0, 0, w / 2, h / 2), fill(blue));
        canvas.drawRect(Rect.fromLTRB(w / 2, 0, w, h / 2), fill(red));
        canvas.drawRect(Rect.fromLTRB(0, h / 2, w / 2, h), fill(red));
        canvas.drawRect(Rect.fromLTRB(w / 2, h / 2, w, h), fill(blue));
        canvas.drawRect(
          Rect.fromCenter(center: mid, width: w, height: h * .16),
          fill(_white),
        );
        canvas.drawRect(
          Rect.fromCenter(center: mid, width: w * .16, height: h),
          fill(_white),
        );
        canvas.drawCircle(mid, w * .06, fill(const Color(0xFF2E7D32)));
      case 'lithuanian':
        _bands(canvas, s, const [
          Color(0xFFFDB913),
          Color(0xFF006A44),
          Color(0xFFC1272D),
        ]);
      case 'maltese':
        _bands(canvas, s, const [_white, Color(0xFFCF142B)], vertical: true);
        final grey = fill(const Color(0xFF9EA3A8));
        final c = at(.27, .3);
        canvas.drawRect(
          Rect.fromCenter(center: c, width: w * .14, height: h * .045),
          grey,
        );
        canvas.drawRect(
          Rect.fromCenter(center: c, width: w * .045, height: h * .14),
          grey,
        );
      case 'venezuelan':
        _bands(canvas, s, const [
          Color(0xFFFFCC00),
          Color(0xFF00247D),
          Color(0xFFCF142B),
        ]);
        for (var i = 0; i < 8; i++) {
          final a = math.pi * (1.12 + i * .76 / 7);
          canvas.drawCircle(
            Offset(
              w * .5 + math.cos(a) * w * .2,
              h * .64 + math.sin(a) * h * .2,
            ),
            w * .025,
            fill(_white),
          );
        }
      case 'swiss':
        canvas.drawColor(const Color(0xFFDA291C), BlendMode.src);
        canvas.drawRect(
          Rect.fromCenter(center: mid, width: w * .56, height: h * .18),
          fill(_white),
        );
        canvas.drawRect(
          Rect.fromCenter(center: mid, width: w * .18, height: h * .56),
          fill(_white),
        );
      case 'dutch':
        _bands(canvas, s, const [Color(0xFFAE1C28), _white, Color(0xFF21468B)]);
      case 'belgian':
        _bands(canvas, s, const [
          _black,
          Color(0xFFFDDA24),
          Color(0xFFEF3340),
        ], vertical: true);
    }
  }

  @override
  bool shouldRepaint(FlagPainter old) => old.code != code;
}
