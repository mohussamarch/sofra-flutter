import 'package:webview_flutter/webview_flutter.dart';

/// Runs [code] in the model viewer's WebView (Android/iOS).
Future<void> runViewerJs(String code, WebViewController? controller) async =>
    controller?.runJavaScript(code);
