import 'package:webview_flutter/webview_flutter.dart';

/// Runs [code] in the model viewer's WebView (Android/iOS).
Future<void> runViewerJs(String code, WebViewController? controller) async =>
    controller?.runJavaScript(code);

/// On a device the WebView's JavaScript channel carries the messages.
void registerViewerChannel(String name, void Function(String) onMessage) {}
