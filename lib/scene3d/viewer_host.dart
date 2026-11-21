import 'package:flutter/widgets.dart';

import 'viewer_host_io.dart' if (dart.library.js_interop) 'viewer_host_web.dart';

/// The surface the kitchen viewer page (`assets/scene3d/index.html`) runs in:
/// a WebView on the phone, an iframe on the web. It only draws; touches are
/// the app's, which asks the page what was hit.
abstract class ViewerHost {
  /// The page, filling its box. It takes no pointer events.
  Widget get view;

  /// Sends one JSON command to the page (see `kitchen.js`).
  void send(String json);

  void dispose();
}

/// Trial switches for the page, for comparing on a real phone, for example
/// `--dart-define=SOFRA_3D_QUERY=unmerged=1` (one switch; `&` does not
/// survive every shell). Empty in normal builds.
const viewerTrialQuery = String.fromEnvironment('SOFRA_3D_QUERY');

/// The page's address query: its id, then any trial switches.
String viewerQuery(String id) =>
    viewerTrialQuery.isEmpty ? 'id=$id' : 'id=$id&$viewerTrialQuery';

/// Opens the viewer page. [onMessage] gets the page's JSON messages.
ViewerHost openViewer({
  required String id,
  required void Function(String json) onMessage,
}) => createViewerHost(id: id, onMessage: onMessage);
