import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

/// The kitchen viewer's WebView loads everything (its page, three.js, the
/// Draco decoder, the model and the lighting files) from this small loopback
/// server reading the app's bundled assets. Started once.
Future<String>? _base;

Future<String> viewerAssetBase() => _base ??= _start().catchError((Object e) {
  // A failed start may be tried again.
  _base = null;
  throw e;
});

Future<String> _start() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    try {
      await _serve(request);
    } on Object {
      // The WebView dropped the request; nothing to answer.
    }
  });
  return 'http://127.0.0.1:${server.port}';
}

Future<void> _serve(HttpRequest request) async {
  final response = request.response
    ..headers.add('Access-Control-Allow-Origin', '*')
    // The port changes on every start: a cached copy is never used again.
    ..headers.add('Cache-Control', 'no-store');
  final key = Uri.decodeComponent(request.uri.path).replaceFirst('/', '');
  // Only the kitchen's own folders are served.
  if (!key.startsWith('assets/scene3d/') &&
      !key.startsWith('assets/spike3d/')) {
    response.statusCode = HttpStatus.notFound;
    await response.close();
    return;
  }
  try {
    final data = await rootBundle.load(key);
    response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.parse(_type(key))
      ..headers.contentLength = data.lengthInBytes
      ..add(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  } on Object {
    response.statusCode = HttpStatus.notFound;
  }
  await response.close();
}

const _types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.hdr': 'image/vnd.radiance',
  '.glb': 'model/gltf-binary',
};

String _type(String key) {
  for (final MapEntry(key: ending, value: type) in _types.entries) {
    if (key.endsWith(ending)) return type;
  }
  return 'application/octet-stream';
}
