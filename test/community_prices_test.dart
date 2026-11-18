import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/places.dart';
import 'package:tabkha_demo/features/community_prices.dart';

void main() {
  final eg = Places.parse(File('assets/places/eg.json').readAsStringSync());
  final sa = Places.parse(File('assets/places/sa.json').readAsStringSync());

  test('bundled places carry their OpenStreetMap attribution', () {
    for (final file in ['eg', 'sa']) {
      final text = File('assets/places/$file.json').readAsStringSync();
      expect(text, contains('"license":"ODbL-1.0"'));
      expect(text, contains('OpenStreetMap contributors'));
    }
    expect(eg.list.length, greaterThan(1000));
    expect(sa.list.length, greaterThan(1000));
  });

  test('a district is named with its big city, a city alone', () {
    final malaz = sa.search('الملز').first;
    expect(malaz.label, 'الملز، الرياض');
    expect(sa.byLabel('الرياض')!.label, 'الرياض');
    expect(eg.byLabel('القاهرة')!.isCity, isTrue);
  });

  test('every label names one place only', () {
    for (final places in [eg, sa]) {
      final seen = <String>{};
      final repeated = [
        for (final p in places.list)
          if (!seen.add(normalizePlace(p.label))) p.label,
      ];
      expect(repeated, isEmpty);
    }
    final riyadh = sa.byLabel('الرياض')!;
    expect(riyadh.kind, 'c');
    expect(distanceKm(riyadh.lat, riyadh.lon, 24.7, 46.7), lessThan(15));
    final cairo = eg.byLabel('القاهرة')!;
    expect(cairo.kind, 'c');
    expect(distanceKm(cairo.lat, cairo.lon, 30.04, 31.24), lessThan(5));
  });

  test('a town is found up to the full distance limit', () {
    final places = Places.parse(
      '{"attribution":"x","places":[["بلدة",25,45,"t"],["حي",25.5,45,"n",0]]}',
    );
    // 20 km from the town: within 25 km, though 2.5 times 20 is not.
    expect(places.nearest(25.18, 45)?.name, 'بلدة');
    // The district 36 km away ranks before the town (2.5 times 20).
    expect(places.nearest(25.18, 45, maxKm: 40)?.name, 'حي');
    expect(places.nearest(25.18, 45, maxKm: 15), isNull);
  });

  test('a tap names the district under it, not the city centre', () {
    final malaz = sa.byLabel('الملز، الرياض')!;
    final hit = sa.nearest(malaz.lat + .002, malaz.lon + .002);
    expect(hit?.label, 'الملز، الرياض');
    expect(
      sa.nearest(0, 0),
      isNull,
      reason: 'nothing is named far from every known place',
    );
  });

  test('search ignores hamza and ta marbuta differences', () {
    final hits = eg.search('الاسكندريه');
    expect(hits.map((p) => p.name), contains('الإسكندرية'));
    expect(hits.first.isCity, isTrue, reason: 'cities come first');
    expect(eg.search('  '), isEmpty);
  });

  test('typed prices accept Arabic digits and decimal marks', () {
    expect(parsePrice('٤٥'), 45);
    expect(parsePrice('12٫5'), 12.5);
    expect(parsePrice('7,25'), 7.25);
    expect(parsePrice('0'), isNull);
    expect(parsePrice('-3'), isNull);
    expect(parsePrice('سعر'), isNull);
  });
}
