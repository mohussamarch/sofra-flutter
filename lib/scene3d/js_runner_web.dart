import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:webview_flutter/webview_flutter.dart';

/// Runs [code] on the page; on the web the model viewer lives in the DOM.
Future<void> runViewerJs(String code, WebViewController? controller) async {
  globalContext.callMethod('eval'.toJS, code.toJS);
}
