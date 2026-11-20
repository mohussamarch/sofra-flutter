import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../data/online_recipe_library.dart';
import '../data/recipe_repository.dart';
import '../l10n/l10n.dart';
import '../ui/design.dart';

/// «الوصفات على جهازك»: what the online recipe library keeps on this phone
/// (full recipes opened or saved, saved ones, storage), when the library was
/// last published, and a button to look for new recipes now. Nothing shows
/// without an online library (the bundled catalog only).
class LibrarySettings extends StatefulWidget {
  const LibrarySettings({super.key, this.recipes, this.onUpdate});

  /// Defaults to the controller's repository.
  final RecipeRepository? recipes;

  /// Defaults to the controller's forced library check.
  final Future<bool> Function()? onUpdate;

  @override
  State<LibrarySettings> createState() => _LibrarySettingsState();
}

class _LibrarySettingsState extends State<LibrarySettings> {
  Future<(LibraryUsage, DateTime?)>? usage;
  OnlineRecipeLibrary? library;

  /// The result of the last «update now» on this screen.
  bool? updated;

  RecipeRepository get _recipes =>
      widget.recipes ?? SofraScope.controllerOf(context).recipes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = _recipes.library;
    if (next != library) {
      library?.removeListener(_changed);
      library = next?..addListener(_changed);
      usage = _usage();
    }
  }

  @override
  void dispose() {
    library?.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() => usage = _usage());
  }

  Future<(LibraryUsage, DateTime?)>? _usage() {
    final library = this.library;
    if (library == null) return null;
    final recipes = _recipes;
    Future<(LibraryUsage, DateTime?)> load() async =>
        (await library.usage(), await recipes.catalogDate);
    return load();
  }

  Future<void> _update() async {
    final run =
        widget.onUpdate ??
        () => SofraScope.controllerOf(context).checkLibrary(force: true);
    setState(() => updated = null);
    final changed = await run();
    if (mounted) setState(() => updated = changed);
  }

  static String _date(DateTime d) {
    final l = d.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)}';
  }

  static String _megabytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return mb >= 10 ? mb.toStringAsFixed(0) : mb.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final library = this.library;
    if (library == null) return const SizedBox.shrink();
    final l = context.l10n;
    return Surface(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: FutureBuilder<(LibraryUsage, DateTime?)>(
        future: usage,
        builder: (context, snap) {
          final data = snap.data;
          final u = data?.$1;
          final failed = library.lastCheckFailed && updated == null;
          final status = library.checking
              ? l.libraryUpdating
              : failed || (updated == false && library.lastCheckFailed)
              ? l.libraryUpdateFailed
              : updated == false
              ? l.libraryUpToDate
              : data?.$2 == null
              ? ''
              : l.libraryUpdated(_date(data!.$2!));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Stat(
                    key: const ValueKey('library-on-device'),
                    value: u == null ? '–' : '${u.onDevice}',
                    label: l.libraryOnDevice,
                  ),
                  const SizedBox(width: 8),
                  _Stat(
                    key: const ValueKey('library-saved'),
                    value: u == null ? '–' : '${u.saved}',
                    label: l.librarySaved,
                  ),
                  const SizedBox(width: 8),
                  _Stat(
                    key: const ValueKey('library-size'),
                    value: u == null
                        ? '–'
                        : l.librarySizeValue(_megabytes(u.bytes)),
                    label: l.librarySize,
                  ),
                  Tooltip(
                    message: l.libraryInfo,
                    triggerMode: TooltipTriggerMode.tap,
                    showDuration: const Duration(seconds: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Sofra.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      status,
                      key: const ValueKey('library-updated'),
                      maxLines: 2,
                      style: TextStyle(color: Sofra.muted, fontSize: 13),
                    ),
                  ),
                  if (library.checking)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    TextButton.icon(
                      key: const ValueKey('library-update-now'),
                      onPressed: _update,
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: Text(l.libraryUpdateNow),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({super.key, required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Sofra.surface,
          borderRadius: BorderRadius.circular(Sofra.r12),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Sofra.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
