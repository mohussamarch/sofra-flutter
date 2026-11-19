import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app/sofra_controller.dart';
import '../domain/ingredient_directory.dart';
import '../l10n/l10n.dart';
import '../ui/design.dart';
import 'common.dart';

/// Off in widget tests, which have no camera.
bool scanWithCamera = true;

/// Opens the camera on a product barcode; the number can also be typed.
/// Returns the code, or null when the user backs out.
Future<String?> scanBarcode(BuildContext context) => Navigator.of(context)
    .push<String>(
      MaterialPageRoute(builder: (_) => _ScanPage(camera: scanWithCamera)),
    );

class _ScanPage extends StatefulWidget {
  const _ScanPage({required this.camera});
  final bool camera;
  @override
  State<_ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<_ScanPage> {
  final typed = TextEditingController();
  var done = false;

  @override
  void dispose() {
    typed.dispose();
    super.dispose();
  }

  void _finish(String? code) {
    final v = code?.trim() ?? '';
    if (done || !RegExp(r'^\d{6,14}$').hasMatch(v)) return;
    done = true;
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(t.addScanTitle)),
      body: Column(
        children: [
          if (widget.camera)
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  for (final b in capture.barcodes) {
                    _finish(b.rawValue);
                  }
                },
                errorBuilder: (context, error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      t.addScanCameraOff,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('barcode-manual'),
                    controller: typed,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(hintText: t.addScanManualHint),
                    onSubmitted: _finish,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: const ValueKey('barcode-manual-go'),
                  tooltip: t.addScanGo,
                  onPressed: () => _finish(typed.text),
                  // Mirrors with the reading direction (matchTextDirection).
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks which kitchen ingredient a scanned product is. The product name is
/// shown but never matched automatically.
Future<IngredientEntry?> pickIngredientFor(
  BuildContext context,
  ScannedProduct product,
  IngredientDirectory directory,
) => showModalBottomSheet<IngredientEntry>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _PickSheet(product: product, directory: directory),
);

class _PickSheet extends StatefulWidget {
  const _PickSheet({required this.product, required this.directory});
  final ScannedProduct product;
  final IngredientDirectory directory;
  @override
  State<_PickSheet> createState() => _PickSheetState();
}

class _PickSheetState extends State<_PickSheet> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final p = widget.product;
    final q = search.text.trim();
    final items = q.isEmpty
        ? const <IngredientEntry>[]
        : widget.directory.search(q).take(30).toList();
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: 20,
        end: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.known ? p.name! : t.addScanUnknownProduct,
              key: const ValueKey('scan-product-name'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              [
                if (p.brand != null) p.brand!,
                if (p.packageLabel != null) t.addScanPackage(p.packageLabel!),
                p.code,
              ].join(' · '),
              style: TextStyle(color: Sofra.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(t.addScanWhich),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('scan-search'),
              controller: search,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: t.addScanSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final e in items)
                    ListTile(
                      key: ValueKey('scan-pick-${e.id}'),
                      leading: Icon(categoryIcon(e.category)),
                      title: Text(L10n.term(e.name)),
                      onTap: () => Navigator.pop(context, e),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
