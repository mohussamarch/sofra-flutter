import 'dart:convert';
import 'dart:math' as math;

/// A city, town or district from the bundled OpenStreetMap list
/// (`assets/places/<cc>.json`, ODbL 1.0), used to name an area from a tap on
/// the map or the phone's position. Positions never leave the phone.
class Place {
  const Place(this.name, this.lat, this.lon, this.kind, [this.city]);
  final String name;
  final double lat, lon;

  /// c city, t town, s suburb, q quarter, n neighbourhood.
  final String kind;

  /// The big city a district belongs to, when one is near.
  final String? city;

  bool get isCity => kind == 'c' || kind == 't';

  /// What is saved and shared as the area: «الملز، الرياض». A district is
  /// named with its city because district names repeat between cities.
  String get label => city == null || city == name ? name : '$name، $city';
}

class Places {
  Places._(this.list, this.attribution);
  final List<Place> list;
  final String attribution;

  static Places parse(String text) {
    final json = jsonDecode(text) as Map<String, dynamic>;
    final rows = (json['places'] as List).cast<List>();
    final cities = [
      for (final r in rows)
        if (r[3] == 'c') r[0] as String,
    ];
    return Places._(
      List.unmodifiable([
        for (final r in rows)
          Place(
            r[0] as String,
            (r[1] as num).toDouble(),
            (r[2] as num).toDouble(),
            r[3] as String,
            r.length > 4 ? cities[r[4] as int] : null,
          ),
      ]),
      json['attribution'] as String,
    );
  }

  /// The nearest place to a point, preferring districts: a tap inside a city
  /// names the district under the finger, not the city centre.
  Place? nearest(double lat, double lon, {double maxKm = 25}) {
    Place? best;
    var bestKm = double.infinity;
    for (final p in list) {
      // Districts are small, so a city wins only when it is much closer.
      final d = distanceKm(lat, lon, p.lat, p.lon) * (p.isCity ? 2.5 : 1);
      if (d < bestKm) {
        best = p;
        bestKm = d;
      }
    }
    return bestKm <= maxKm ? best : null;
  }

  /// Places whose name or city starts with or contains [query], names that
  /// start with it first, then cities before districts.
  List<Place> search(String query, {int limit = 8}) {
    final q = normalizePlace(query);
    if (q.isEmpty) return const [];
    final starts = <Place>[], inside = <Place>[];
    for (final p in list) {
      final n = normalizePlace(p.label);
      if (n.startsWith(q)) {
        starts.add(p);
      } else if (n.contains(q)) {
        inside.add(p);
      }
    }
    int byKind(Place a, Place b) => (a.isCity ? 0 : 1) - (b.isCity ? 0 : 1);
    return [
      ...starts..sort(byKind),
      ...inside..sort(byKind),
    ].take(limit).toList();
  }

  /// The place saved as [label], if it is in the list.
  Place? byLabel(String label) {
    final key = normalizePlace(label);
    if (key.isEmpty) return null;
    for (final p in list) {
      if (normalizePlace(p.label) == key) return p;
    }
    return null;
  }
}

String normalizePlace(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp('[ًٌٍَُِّْـ]'), '')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .replaceAll(RegExp(r'\s+'), ' ');

double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const r = math.pi / 180;
  final x = (lon2 - lon1) * r * math.cos((lat1 + lat2) / 2 * r);
  final y = (lat2 - lat1) * r;
  return 6371 * math.sqrt(x * x + y * y);
}
