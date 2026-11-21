import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/widgets.dart';

import 'viewer_host.dart';

ViewerHost createViewerHost({
  required String id,
  required void Function(String json) onMessage,
}) => _FrameHost(id, onMessage);

/// The viewer in an iframe on the web. The page posts its messages to the
/// app window tagged with [id]; commands go back through `postMessage`.
class _FrameHost implements ViewerHost {
  _FrameHost(this.id, this.onMessage) {
    _listener = ((JSAny? event) {
      final source = (event as JSObject?)?['source'];
      final frame = _frame?['contentWindow'];
      // Only this viewer's own frame is listened to.
      if (source == null || frame == null || !source.strictEquals(frame).toDart) {
        return;
      }
      final data = event?['data'];
      if (data == null || !data.isA<JSObject>()) return;
      final object = data as JSObject;
      final from = object['sofraKitchen'];
      final text = object['data'];
      if (from == null || text == null) return;
      if (!from.isA<JSString>() || (from as JSString).toDart != id) return;
      if (text.isA<JSString>()) onMessage((text as JSString).toDart);
    }).toJS;
    globalContext.callMethod('addEventListener'.toJS, 'message'.toJS, _listener);
  }

  final String id;
  final void Function(String) onMessage;
  late final JSFunction _listener;
  JSObject? _frame;

  @override
  late final Widget view = HtmlElementView.fromTagName(
    tagName: 'iframe',
    onElementCreated: (element) {
      final frame = _frame = element as JSObject;
      final style = frame['style'] as JSObject;
      style['border'] = '0'.toJS;
      style['width'] = '100%'.toJS;
      style['height'] = '100%'.toJS;
      style['background'] = 'transparent'.toJS;
      // Touches stay with the app, which asks the page what was hit.
      style['pointerEvents'] = 'none'.toJS;
      frame.callMethod('setAttribute'.toJS, 'allowtransparency'.toJS, 'true'.toJS);
      // The web serves Flutter assets one folder deeper.
      frame['src'] = 'assets/assets/scene3d/index.html?id=$id'.toJS;
    },
  );

  @override
  void send(String json) {
    final window = _frame?['contentWindow'];
    if (window == null) return;
    final message = JSObject()..['sofraKitchenCmd'] = json.toJS;
    (window as JSObject).callMethod('postMessage'.toJS, message, '*'.toJS);
  }

  @override
  void dispose() {
    globalContext.callMethod(
      'removeEventListener'.toJS,
      'message'.toJS,
      _listener,
    );
    _frame = null;
  }
}
