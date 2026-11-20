import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/online_recipe_library.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';

/// The real publisher output, served over real HTTP on localhost, read by the
/// app's real network code (package:http). Skipped where node is missing.
void main() {
  late Directory out;
  late HttpServer server;
  final served = <String>[];

  setUpAll(() async {
    out = await Directory.systemTemp.createTemp('sofra-library-');
    final run = await Process.run('node', [
      'tool/recipes/publish-library.mjs',
      '--out',
      out.path,
      '--generated-at',
      '2026-11-20T00:00:00.000Z',
    ]);
    if (run.exitCode != 0) throw StateError('publish failed: ${run.stderr}');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final path = request.uri.path.substring(1);
      served.add(path);
      final file = File('${out.path}/$path');
      if (path.contains('..') || !await file.exists()) {
        request.response.statusCode = 404;
      } else {
        request.response.headers.contentType = ContentType.json;
        await request.response.addStream(file.openRead());
      }
      await request.response.close();
    });
  });

  tearDownAll(() async {
    await server.close(force: true);
    await out.delete(recursive: true);
  });

  test('the app downloads the published library from a real URL', () async {
    final library = OnlineRecipeLibrary(
      store: MemoryLibraryStore(),
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}/'),
      fetch: httpLibraryFetch,
    );
    final repo = RecipeRepository(
      read: (path) => File(path).readAsString(),
      library: library,
    );
    expect(await library.update(force: true), isTrue);
    expect(served, containsAll(['manifest.json', 'index.json']));
    expect(await repo.catalogDate, DateTime.utc(2026, 11, 20));
    expect(await repo.index, hasLength(495));
    final recipe = await repo.get('eg-koshari');
    expect(recipe.steps, isNotEmpty);
    expect(served.where((p) => p.startsWith('r/')), hasLength(1));
    final usage = await library.usage();
    expect(usage.onDevice, 1);
    expect(usage.bytes, greaterThan(900000));
    // Same version again: only the manifest is read.
    served.clear();
    expect(await library.update(force: true), isFalse);
    expect(served, ['manifest.json']);
  }, skip: _hasNode ? false : 'node is not installed');
}

final _hasNode = () {
  try {
    return Process.runSync('node', ['--version']).exitCode == 0;
  } on Object {
    return false;
  }
}();
