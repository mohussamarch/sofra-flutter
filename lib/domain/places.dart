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

  /// The city or town the label names: the big city a district belongs to,
  /// or, for a name that repeats, the nearest town of another name.
  final String? city;

  bool get isCity => kind == 'c' || kind == 't';

  /// What is saved and shared as the area: «الملز، الرياض». A district is
  /// named with its city because district names repeat between cities.
  /// Labels are unique per country (the build makes them so).
  String get label => city == null || city == name ? name : '$name، $city';
}

class Places {
  Places._(this.list, this.attribution)
    : _keys = List.unmodifiable([
        for (final p in list) normalizePlace(p.label),
      ]) {
    for (var i = 0; i < list.length; i++) {
      _byKey.putIfAbsent(_keys[i], () => list[i]);
    }
  }
  final List<Place> list;
  final String attribution;

  /// normalizePlace(label) of each place in [list], worked out once.
  final List<String> _keys;
  final _byKey = <String, Place>{};

  static Places parse(String text) {
    final json = jsonDecode(text) as Map<String, dynamic>;
    final rows = (json['places'] as List).cast<List>();
    return Places._(
      List.unmodifiable([
        for (final r in rows)
          Place(
            r[0] as String,
            (r[1] as num).toDouble(),
            (r[2] as num).toDouble(),
            r[3] as String,
            // The index of the parent city or town row.
            r.length > 4 ? rows[r[4] as int][0] as String : null,
          ),
      ]),
      json['attribution'] as String,
    );
  }

  /// The nearest place within [maxKm] of a point, preferring districts: a
  /// tap inside a city names the district under the finger, not the city
  /// centre.
  Place? nearest(double lat, double lon, {double maxKm = 25}) {
    Place? best;
    var bestRank = double.infinity;
    for (final p in list) {
      final d = distanceKm(lat, lon, p.lat, p.lon);
      if (d > maxKm) continue;
      // Districts are small, so a city wins only when it is much closer.
      final rank = d * (p.isCity ? 2.5 : 1);
      if (rank < bestRank) {
        best = p;
        bestRank = rank;
      }
    }
    return best;
  }

  /// Places whose name or city starts with or contains [query], names that
  /// start with it first, then cities before districts.
  List<Place> search(String query, {int limit = 8}) {
    final q = normalizePlace(query);
    if (q.isEmpty) return const [];
    final starts = <Place>[], inside = <Place>[];
    for (var i = 0; i < list.length; i++) {
      final n = _keys[i];
      if (n.startsWith(q)) {
        starts.add(list[i]);
      } else if (n.contains(q)) {
        inside.add(list[i]);
      }
    }
    int byKind(Place a, Place b) => (a.isCity ? 0 : 1) - (b.isCity ? 0 : 1);
    return [
      ...starts..sort(byKind),
      ...inside..sort(byKind),
    ].take(limit).toList();
  }

  /// The place saved as [label], if it is in the list.
  Place? byLabel(String label) => _byKey[normalizePlace(label)];
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
