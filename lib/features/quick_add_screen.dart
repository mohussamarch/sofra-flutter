import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../data/purchase_reader.dart';
import '../domain/ingredient_directory.dart';
import '../domain/market_profile.dart';
import '../domain/quick_add.dart';
import '../ui/add_tile.dart';
import '../ui/design.dart';
import '../ui/ingredient_art.dart';
import 'common.dart';

/// Takes a picture with the camera or picks one from the phone. Tests
/// replace it, as they have neither.
Future<(Uint8List, String)?> Function(bool camera) pickPurchaseImage =
    (camera) async {
      final file = await ImagePicker().pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 88,
      );
      if (file == null) return null;
      final name = file.name.toLowerCase();
      final type =
          file.mimeType ??
          (name.endsWith('.png')
              ? 'image/png'
              : name.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg');
      return (await file.readAsBytes(), type);
    };

/// Opens "add what you bought" over the current page.
Future<void> openQuickAdd(BuildContext context) {
  final scope = SofraScope.of(context);
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SofraScope(
        controller: scope.notifier!,
        nav: scope.nav,
        child: const Directionality(
          textDirection: TextDirection.rtl,
          child: QuickAddScreen(),
        ),
      ),
    ),
  );
}

enum _Stage { choose, reading, review }

/// Many ingredients at once: a receipt photo, a screenshot of an online
/// order, or a typed list. Whatever is read becomes a draft the user reviews;
/// nothing enters stock before they press add.
class QuickAddScreen extends StatefulWidget {
  const QuickAddScreen({super.key});
  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  final text = TextEditingController();
  final reader = purchaseReader();
  var stage = _Stage.choose;
  var lines = <QuickLine>[];
  String? error;
  var saving = false;

  /// Typed rows the reader is still looking up.
  final asking = <QuickLine>{};

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> _read(
    Future<List<QuickLine>> Function() work, {
    List<QuickLine> Function()? otherwise,
  }) async {
    setState(() {
      stage = _Stage.reading;
      error = null;
    });
    List<QuickLine>? found;
    try {
      found = await work();
    } catch (_) {
      found = otherwise?.call();
    }
    if (!mounted) return;
    setState(() {
      if (found == null) {
        stage = _Stage.choose;
        error = 'تعذّرت القراءة. تحقق من الاتصال، أو اكتب المشتريات بالأسفل.';
      } else if (found.isEmpty) {
        stage = _Stage.choose;
        error = 'لم نجد مكونات هنا. جرّب صورة أوضح، أو اكتبها.';
      } else {
        lines = found;
        stage = _Stage.review;
      }
    });
  }

  Future<void> _photo(bool camera) async {
    final directory = SofraScope.controllerOf(context).directory;
    if (directory == null || reader == null) return;
    final (Uint8List, String)? image;
    try {
      image = await pickPurchaseImage(camera);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = camera
              ? 'الكاميرا غير متاحة. اسمح بها من إعدادات الهاتف.'
              : 'تعذّر فتح الصور.',
        );
      }
      return;
    }
    if (image == null || !mounted) return;
    final picked = image;
    await _read(() => reader!.readImage(picked.$1, picked.$2, directory));
  }

  /// What was typed becomes rows at once, one per item, read on the phone.
  /// A row it cannot place is sent to the reader (brands, English) when there
  /// is one, and filled in if the reader knows it.
  void _addTyped() {
    final directory = SofraScope.controllerOf(context).directory;
    final value = text.text.trim();
    if (directory == null || value.isEmpty) return;
    final added = parseQuickText(value, directory);
    for (final line in added) {
      line.include = line.entry != null;
    }
    setState(() {
      lines = [...lines, ...added];
      error = null;
      text.clear();
    });
    final r = reader;
    if (r == null) return;
    for (final line in added.where((l) => l.entry == null)) {
      unawaited(_ask(r, line, directory));
    }
  }

  Future<void> _ask(
    PurchaseReader r,
    QuickLine line,
    IngredientDirectory directory,
  ) async {
    setState(() => asking.add(line));
    QuickLine? found;
    try {
      found = (await r.readText(
        line.raw,
        directory,
      )).where((l) => l.entry != null).firstOrNull;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      asking.remove(line);
      if (found == null) return;
      line
        ..entry = found.entry
        ..sure = found.sure
        ..include = true
        ..quantity = found.quantity
        ..unit = found.unit
        ..paid = found.paid;
    });
  }

  Widget _choose(SofraController c) {
    final directory = c.directory;
    final preview = directory == null || text.text.trim().isEmpty
        ? const <QuickLine>[]
        : parseQuickText(text.text, directory);
    final ready = lines.where((l) => l.ready).length;
    return ScreenBody(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      footer: lines.isEmpty
          ? null
          : DepthButton(
              key: const ValueKey('quick-add-save'),
              label: ready == 0
                  ? 'علّم صنفًا واحدًا على الأقل'
                  : 'أضف $ready إلى المطبخ',
              icon: Icons.kitchen_rounded,
              onPressed: ready == 0 || saving ? null : _save,
            ),
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AddTile(
                  key: const ValueKey('quick-add-camera'),
                  icon: Icons.photo_camera_rounded,
                  title: 'صوّر الفاتورة',
                  detail: 'بالكاميرا',
                  primary: true,
                  minHeight: 176,
                  onTap: reader == null ? null : () => _photo(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AddTile(
                  key: const ValueKey('quick-add-gallery'),
                  icon: Icons.add_photo_alternate_rounded,
                  title: 'من الصور',
                  detail: 'لقطة طلب أو فاتورة',
                  minHeight: 176,
                  onTap: reader == null ? null : () => _photo(false),
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[const SizedBox(height: 12), _ErrorNote(error!)],
        const SizedBox(height: 24),
        TextField(
          key: const ValueKey('quick-add-text'),
          controller: text,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _addTyped(),
          decoration: InputDecoration(
            hintText: 'أو اكتب: 2 كيلو طماطم',
            prefixIcon: const Icon(Icons.edit_note_rounded),
            suffixIcon: IconButton(
              key: const ValueKey('quick-add-read'),
              tooltip: 'أضف السطر',
              onPressed: text.text.trim().isEmpty ? null : _addTyped,
              icon: const Icon(Icons.add_circle_rounded, color: Sofra.accent),
            ),
          ),
        ),
        // How it is understood, while typing.
        for (final p in preview)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _Preview(line: p, controller: c),
          ),
        const SizedBox(height: 16),
        for (final (i, line) in lines.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: asking.contains(line)
                ? _Asking(raw: line.raw)
                : _LineCard(
                    key: ValueKey('quick-line-$i'),
                    index: i,
                    line: line,
                    controller: c,
                    checkbox: true,
                    onChanged: () => setState(() => error = null),
                  ),
          ),
      ],
    );
  }

  Future<void> _save() async {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final ready = lines.where((l) => l.ready).toList();
    setState(() => saving = true);
    final saved = await c.addArrivals(ready);
    if (!mounted) return;
    setState(() => saving = false);
    if (!saved) {
      setState(
        () => error = 'لم تُحفظ المشتريات. تحقق من الاتصال وحاول مرة أخرى.',
      );
      return;
    }
    Navigator.pop(context);
    nav.notify(
      'أُضيفت ${countText(ready.length, 'مكوّن', 'مكوّنان', 'مكونات')} إلى مطبخك',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final ready = lines.where((l) => l.ready).length;
    return Stack(
      children: [
        const Positioned.fill(
          child: ColoredBox(color: Sofra.cream, child: SofraBackdrop()),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('أضف مشترياتك'),
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
          body: SafeArea(
            child: switch (stage) {
              _Stage.reading => const _Reading(),
              _Stage.choose => _choose(c),
              _Stage.review => ScreenBody(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                footer: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error != null) ...[
                      _ErrorNote(error!),
                      const SizedBox(height: 10),
                    ],
                    DepthButton(
                      key: const ValueKey('quick-add-save'),
                      label: ready == 0
                          ? 'اختر مكوّنًا واحدًا على الأقل'
                          : 'أضف $ready إلى المطبخ',
                      icon: Icons.kitchen_rounded,
                      onPressed: ready == 0 || saving ? null : _save,
                    ),
                  ],
                ),
                children: [
                  _Summary(lines: lines),
                  const SizedBox(height: 14),
                  for (final line in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LineCard(
                        key: ValueKey('quick-line-${lines.indexOf(line)}'),
                        index: lines.indexOf(line),
                        line: line,
                        controller: c,
                        onChanged: () => setState(() => error = null),
                      ),
                    ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: const ValueKey('quick-add-restart'),
                      onPressed: () => setState(() {
                        stage = _Stage.choose;
                        lines = [];
                        error = null;
                      }),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('ابدأ من جديد'),
                    ),
                  ),
                ],
              ),
            },
          ),
        ),
      ],
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: Sofra.accentTint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            size: 44,
            color: Sofra.accent,
          ),
        ),
        const SizedBox(height: 20),
        const SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            minHeight: 4,
            color: Sofra.accent,
            backgroundColor: Sofra.line,
          ),
        ),
        const SizedBox(height: 16),
        Text('نقرأ مشترياتك…', style: Sofra.heading(19)),
      ],
    ),
  );
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Sofra.warnTint,
      borderRadius: BorderRadius.circular(Sofra.r12),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, size: 18, color: Sofra.warn),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            key: const ValueKey('quick-add-error'),
            style: const TextStyle(fontSize: 13, color: Sofra.warn),
          ),
        ),
      ],
    ),
  );
}

/// Counts at a glance: ready lines, and lines that still need a look.
class _Summary extends StatelessWidget {
  const _Summary({required this.lines});
  final List<QuickLine> lines;
  @override
  Widget build(BuildContext context) {
    final kept = lines.where((l) => l.include).toList();
    final ready = kept.where((l) => l.entry != null).length;
    final open = kept.where((l) => l.entry == null).length;
    final check = kept.where((l) => l.entry != null && !l.sure).length;
    Widget pill(IconData icon, String label, Color ink, Color fill) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(Sofra.r12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: ink),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ],
          ),
        );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        pill(
          Icons.check_circle_rounded,
          '$ready جاهزة',
          Sofra.ok,
          Sofra.okTint,
        ),
        if (check > 0)
          pill(
            Icons.visibility_outlined,
            '$check للتأكد',
            Sofra.warn,
            Sofra.warnTint,
          ),
        if (open > 0)
          pill(
            Icons.help_outline_rounded,
            '$open بلا مكوّن',
            Sofra.warn,
            Sofra.warnTint,
          ),
      ],
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    super.key,
    required this.index,
    required this.line,
    required this.controller,
    required this.onChanged,
    this.checkbox = false,
  });
  final int index;
  final QuickLine line;
  final SofraController controller;
  final VoidCallback onChanged;

  /// Typed rows are ticked in or out with a checkbox at the start.
  final bool checkbox;

  Future<void> _pick(BuildContext context) async {
    final directory = controller.directory;
    if (directory == null) return;
    final entry = await showModalBottomSheet<IngredientEntry>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: _PickSheet(directory: directory, raw: line.raw),
      ),
    );
    if (entry == null) return;
    final quantity = line.quantity, unit = line.unit;
    line
      ..entry = entry
      ..sure = true
      ..include = true;
    setAmount(line, quantity, unit);
    onChanged();
  }

  Future<void> _amount(BuildContext context) async {
    final entry = line.entry;
    if (entry == null) return _pick(context);
    final result = await showModalBottomSheet<(double?, String?)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: _AmountSheet(line: line, controller: controller),
      ),
    );
    if (result == null) return;
    line
      ..quantity = result.$1
      ..unit = result.$1 == null ? null : result.$2;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final entry = line.entry;
    final off = !line.include;
    final money = MarketProfile(controller.kitchen.market.country)
        .currencyLabel;
    final amount = entry == null
        ? null
        : line.quantity == null
        ? 'الكمية؟'
        : controller.amountText(entry.id, line.quantity!, line.unit!);
    return Opacity(
      opacity: off ? .45 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: Sofra.surface,
          borderRadius: BorderRadius.circular(Sofra.r16),
          border: Border.all(
            color: entry == null && !off
                ? Sofra.warn.withValues(alpha: .45)
                : Sofra.line,
          ),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 10),
        child: Row(
          children: [
            if (checkbox)
              Checkbox(
                key: ValueKey('quick-toggle-$index'),
                value: line.include,
                activeColor: Sofra.accent,
                onChanged: (v) {
                  line.include = v ?? false;
                  onChanged();
                },
              ),
            entry == null
                ? Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Sofra.warnTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: Sofra.warn,
                      size: 28,
                    ),
                  )
                : Opacity(
                    opacity: off ? .4 : 1,
                    child: IngredientPicture(
                      entry.id,
                      entry.category,
                      size: 56,
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                key: ValueKey('quick-pick-$index'),
                borderRadius: BorderRadius.circular(Sofra.r12),
                onTap: off ? null : () => _pick(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry?.name ?? 'اختر المكوّن',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: entry == null ? Sofra.warn : Sofra.ink,
                              ),
                            ),
                          ),
                          if (entry != null && !line.sure) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.visibility_outlined,
                              size: 15,
                              color: Sofra.warn,
                            ),
                          ],
                        ],
                      ),
                      if (entry == null ||
                          IngredientDirectory.normalizeArabic(line.raw) !=
                              IngredientDirectory.normalizeArabic(entry.name))
                        Text(
                          line.raw,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Sofra.muted,
                          ),
                        ),
                      if (line.paid != null)
                        Text(
                          '${formatAmount(line.paid!)} $money',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Sofra.muted,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (amount != null && !off)
              SofraChip(
                key: ValueKey('quick-amount-$index'),
                label: Text(amount),
                selected: line.quantity != null,
                onPressed: () => _amount(context),
              ),
            if (!checkbox)
              IconButton(
                key: ValueKey('quick-toggle-$index'),
                tooltip: off ? 'أعِده' : 'احذفه',
                onPressed: () {
                  line.include = !line.include;
                  onChanged();
                },
                icon: Icon(
                  off ? Icons.undo_rounded : Icons.close_rounded,
                  color: Sofra.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PickSheet extends StatefulWidget {
  const _PickSheet({required this.directory, required this.raw});
  final IngredientDirectory directory;
  final String raw;
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
            Text('أي مكوّن هذا؟', style: Sofra.heading(20)),
            const SizedBox(height: 4),
            Text(
              widget.raw,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Sofra.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('quick-pick-search'),
              controller: search,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'رز، لبن، زيت…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final e in items)
                    ListTile(
                      key: ValueKey('quick-pick-${e.id}'),
                      contentPadding: EdgeInsets.zero,
                      leading: IngredientPicture(e.id, e.category, size: 40),
                      title: Text(e.name),
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

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({required this.line, required this.controller});
  final QuickLine line;
  final SofraController controller;
  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late final input = TextEditingController(
    text: widget.line.quantity == null
        ? ''
        : formatAmount(widget.line.quantity!),
  );
  late String unit = widget.line.unit ?? widget.line.entry!.units.first;

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  double? get _value {
    final v = double.tryParse(latinDigits(input.text).replaceAll(',', '.'));
    return v == null || !v.isFinite || v <= 0 ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.line.entry!;
    final units = {...entry.units, ?widget.line.unit}.toList();
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: 20,
        end: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('كمية ${entry.name}', style: Sofra.heading(20)),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('quick-amount-input'),
            controller: input,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'الكمية'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final u in units)
                SofraChip(
                  key: ValueKey('quick-unit-$u'),
                  label: Text(widget.controller.unitName(entry.id, u)),
                  selected: u == unit,
                  onSelected: (_) => setState(() => unit = u),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DepthButton(
            key: const ValueKey('quick-amount-save'),
            label: 'حفظ',
            onPressed: _value == null
                ? null
                : () => Navigator.pop(context, (_value, unit)),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              key: const ValueKey('quick-amount-unknown'),
              onPressed: () => Navigator.pop(context, (null, null)),
              child: const Text('لا أعرف الكمية'),
            ),
          ),
        ],
      ),
    );
  }
}

/// While typing: the picture and how the text will be added.
class _Preview extends StatelessWidget {
  const _Preview({required this.line, required this.controller});
  final QuickLine line;
  final SofraController controller;

  @override
  Widget build(BuildContext context) {
    final e = line.entry;
    final amount = e == null || line.quantity == null
        ? null
        : controller.amountText(e.id, line.quantity!, line.unit!);
    return Row(
      children: [
        const SizedBox(width: 8),
        e == null
            ? const Icon(Icons.help_outline_rounded, color: Sofra.warn)
            : IngredientPicture(e.id, e.category, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            e == null ? 'لم نعرفه بعد' : [?amount, e.name].join(' · '),
            style: TextStyle(
              color: e == null ? Sofra.warn : Sofra.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// A typed row the reader is still looking up.
class _Asking extends StatelessWidget {
  const _Asking({required this.raw});
  final String raw;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Sofra.surface,
      borderRadius: BorderRadius.circular(Sofra.r16),
      border: Border.all(color: Sofra.line),
    ),
    child: Row(
      children: [
        const SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'نتعرف على «$raw»…',
            style: const TextStyle(color: Sofra.muted),
          ),
        ),
      ],
    ),
  );
}
