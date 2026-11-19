import 'package:flutter/material.dart';

import '../ui/design.dart';
import '../ui/flags.dart';
import 'common.dart';

/// The mark of a dish made in several countries, at the bottom corner of its
/// card: the countries' flags overlapping, and how many.
class CountriesBadge extends StatelessWidget {
  const CountriesBadge(this.ways, {super.key});

  /// Index rows of the dish's recipes.
  final List<Map<String, dynamic>> ways;

  @override
  Widget build(BuildContext context) {
    final countries = countriesOf(ways);
    final shown = countries.take(3).toList();
    final label = countries.length > 1
        ? countriesLabel(countries.length)
        : waysLabel(ways.length);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        key: const ValueKey('countries-badge'),
        padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 10, 4),
        decoration: BoxDecoration(
          color: Sofra.accentTint,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Sofra.accent.withValues(alpha: .25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20.0 + 13 * (shown.length - 1),
              height: 22,
              child: Stack(
                children: [
                  for (final (i, c) in shown.indexed)
                    PositionedDirectional(
                      start: 13.0 * i,
                      child: CuisineFlag(c, size: 22),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Sofra.accent,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The distinct cuisines of a dish's ways, in the dish's order.
List<String> countriesOf(List<Map<String, dynamic>> ways) => [
  ...{for (final w in ways) '${w['cuisine']}'},
];

/// One colour per way of a dish, for its chip and its own ingredients;
/// lighter hues of the same set in the dark look.
List<Color> get wayColors => Sofra.isDark ? _wayColorsDark : _wayColorsLight;

const _wayColorsLight = [
  Color(0xFF2E7D5B),
  Color(0xFFC0582F),
  Color(0xFF2F5D8C),
  Color(0xFF8C3B5E),
  Color(0xFFB07A0B),
  Color(0xFF3F7F7F),
  Color(0xFF6B4E9B),
  Color(0xFF7A5230),
];

const _wayColorsDark = [
  Color(0xFF6FC29A),
  Color(0xFFEE9068),
  Color(0xFF86AEDB),
  Color(0xFFD889AC),
  Color(0xFFE2B24C),
  Color(0xFF7FC4C4),
  Color(0xFFB399DD),
  Color(0xFFCB9C72),
];

/// «طريقتان»، «3 طرق»، «11 طريقة» (Arabic counting).
String waysLabel(int n) => switch (n) {
  1 => 'طريقة واحدة',
  2 => 'طريقتان',
  <= 10 => '$n طرق',
  _ => '$n طريقة',
};

/// «بلدان»، «3 بلاد»، «11 بلدًا» (Arabic counting).
String countriesLabel(int n) => switch (n) {
  1 => 'بلد واحد',
  2 => 'بلدان',
  <= 10 => '$n بلاد',
  _ => '$n بلدًا',
};

/// The dish's time: one time when its ways agree, else the shortest and the
/// longest («20–45 دقيقة»). Unknown when any way's time is unknown.
String dishTime(List<Map<String, dynamic>> ways) {
  final times = [for (final w in ways) w['totalTime']];
  if (times.any((t) => t is! num)) return minutesLabel(null);
  final values = times.cast<num>().map((t) => t.round()).toList()..sort();
  return values.first == values.last
      ? minutesLabel(values.first)
      : '${values.first}–${values.last} دقيقة';
}
