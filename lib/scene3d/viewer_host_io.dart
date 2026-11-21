import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'asset_server_io.dart';
import 'viewer_host.dart';

ViewerHost createViewerHost({
  required String id,
  required void Function(String json) onMessage,
}) => _WebViewHost(id, onMessage);

/// The viewer in a WebView (Android, iOS), fed by the app's loopback asset
/// server: the page, three.js, the model and the lighting files all come
/// from the bundle, so the kitchen opens with no network.
class _WebViewHost implements ViewerHost {
  _WebViewHost(String id, this._onMessage) {
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        _channel,
        onMessageReceived: (m) {
          if (!_disposed) _onMessage(m.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          // The page itself did not load: say so now, not after a long wait.
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? false) _fail(error.description);
          },
        ),
      );
    viewerAssetBase().then((base) {
      if (_disposed) return;
      _controller.loadRequest(
        Uri.parse('$base/assets/scene3d/index.html?id=$id'),
      );
    }, onError: (Object e) => _fail('$e'));
  }

  static const _channel = 'SofraKitchen';
  final void Function(String) _onMessage;
  final _controller = WebViewController();
  var _disposed = false;

  void _fail(String why) {
    if (!_disposed) _onMessage(jsonEncode({'t': 'error', 'message': why}));
  }

  @override
  Widget get view => WebViewWidget(controller: _controller);

  @override
  void send(String json) {
    if (_disposed) return;
    // Before the page is up this fails quietly; the page says hello when it
    // can listen and the state is sent again.
    _controller
        .runJavaScript('window.sofraKitchen&&window.sofraKitchen($json)')
        .catchError((Object _) {});
  }

  /// The native WebView outlives this object until it is collected: empty
  /// its page now, so the model, its textures and its graphics context go.
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _controller.removeJavaScriptChannel(_channel).catchError((Object _) {});
    _controller.loadHtmlString('<html></html>').catchError((Object _) {});
  }
}
