import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:tabkha_demo/data/online_recipe_library.dart';

/// The bundled catalog files, read from disk: the app's offline seed.
Map<String, String> readSeed() => {
  for (final f in Directory('recipes/data').listSync().whereType<File>())
    if (f.path.endsWith('.json'))
      'recipes/data/${f.uri.pathSegments.last}': f.readAsStringSync(),
};

String sha(String text) => sha256.convert(utf8.encode(text)).toString();

/// A library published the way tool/recipes/publish-library.mjs does, from
/// [seed] after [edit] changes the index rows or recipe bodies (by id).
Map<String, String> publishLibrary(
  Map<String, String> seed, {
  void Function(
    List<Map<String, dynamic>> rows,
    Map<String, Map<String, dynamic>> bodies,
  )?
  edit,
  String generatedAt = '2026-11-20T08:00:00.000Z',
}) {
  final index =
      jsonDecode(seed['recipes/data/index.json']!) as Map<String, dynamic>;
  final bodies = <String, Map<String, dynamic>>{};
  for (final c in index['cuisines'] as List) {
    final file = jsonDecode(seed['recipes/data/${c['file']}']!) as Map;
    for (final r in file['recipes'] as List) {
      bodies[r['id'] as String] = Map<String, dynamic>.from(r as Map);
    }
  }
  final rows = [
    for (final r in index['recipes'] as List) Map<String, dynamic>.from(r),
  ];
  edit?.call(rows, bodies);
  // Keep the cuisine group counts true to the edited rows.
  for (final g in index['cuisineGroups'] as List) {
    g['count'] = rows
        .where(
          (r) => r['catalogStatus'] == 'active' && r['cuisineGroup'] == g['id'],
        )
        .length;
  }
  final files = <String, String>{};
  for (final row in rows) {
    final body = bodies[row['id']]!;
    final text = jsonEncode(body);
    files['r/${sha(text)}.json'] = text;
    row['body'] = sha(text);
    if (row['catalogStatus'] == 'active') {
      row['ingredients'] = [
        for (final line in body['ingredients'] as List)
          {
            'id': line['id'],
            'name': line['name'],
            'amount': line['amount'],
            'unit': line['unit'],
            if (line['scale'] == false) 'scale': false,
            if (line['optional'] == true) 'optional': true,
          },
      ];
    }
  }
  index['recipes'] = rows;
  files['index.json'] = jsonEncode(index);
  files['dishes.json'] = seed['recipes/data/dishes.json']!;
  final entries = {
    for (final name in ['dishes.json', 'index.json'])
      name: {'sha256': sha(files[name]!), 'size': utf8.encode(files[name]!).length},
  };
  files['manifest.json'] = jsonEncode({
    'schema': 1,
    'version': sha(jsonEncode(entries)),
    'generatedAt': generatedAt,
    'recipeCount': rows.where((r) => r['catalogStatus'] == 'active').length,
    'files': entries,
  });
  return files;
}

/// A copy of [from] as a new library recipe with [id] (not in the seed).
void addRecipe(
  List<Map<String, dynamic>> rows,
  Map<String, Map<String, dynamic>> bodies,
  String from,
  String id,
) {
  final row = Map<String, dynamic>.from(rows.firstWhere((r) => r['id'] == from));
  rows.add(row..['id'] = id);
  bodies[id] = {...bodies[from]!, 'id': id};
}

/// The library site, served from memory; can go offline or serve bad bytes.
class FakeLibrarySite {
  Map<String, String> files = {};
  bool offline = false;
  final requests = <String>[];

  /// Paths served with different bytes than published.
  final tampered = <String>{};

  Future<LibraryResponse> fetch(Uri uri) async {
    final path = uri.path.substring(1);
    requests.add(path);
    if (offline) throw const SocketException('offline');
    final text = files[path];
    if (text == null) return const LibraryResponse(404, []);
    return LibraryResponse(
      200,
      // Same size, different bytes: only the sha256 check can catch it.
      utf8.encode(
        tampered.contains(path) ? text.replaceFirst('"', "'") : text,
      ),
    );
  }

  int count(bool Function(String path) where) => requests.where(where).length;
  int get bodyRequests => count((p) => p.startsWith('r/'));
}
