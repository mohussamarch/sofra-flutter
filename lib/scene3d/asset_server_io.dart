import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

/// The viewer's WebView only gets the model itself from model_viewer_plus;
/// the lighting files (probe HDRs, bounce lightmaps) come from this small
/// loopback server reading the app's bundled assets. Started once.
Future<String>? _base;

Future<String> viewerAssetBase() => _base ??= _start();

Future<String> _start() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final response = request.response
      ..headers.add('Access-Control-Allow-Origin', '*');
    final key = Uri.decodeComponent(request.uri.path).replaceFirst('/', '');
    // Only the kitchen's own folder is served.
    if (!key.startsWith('assets/spike3d/')) {
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
  });
  return 'http://127.0.0.1:${server.port}';
}

String _type(String key) => key.endsWith('.png')
    ? 'image/png'
    : key.endsWith('.hdr')
    ? 'image/vnd.radiance'
    : 'application/octet-stream';
