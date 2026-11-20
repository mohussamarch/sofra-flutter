import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../ui/design.dart';

/// Light, dark, or following the phone.
enum Appearance { system, light, dark }

/// Colour correction for a colour vision deficiency, the same idea as the
/// phone's own "colour correction": colours the eye mixes up are shifted
/// toward ones it tells apart.
enum ColorVision { none, protan, deutan, tritan }

/// The app's language: Arabic (right to left) or English (left to right).
enum AppLanguage {
  ar,
  en;

  Locale get locale => Locale(name);
  TextDirection get direction =>
      this == ar ? TextDirection.rtl : TextDirection.ltr;
}

/// How the app looks for this household: appearance, text size, colour
/// correction, motion and language. The shell publishes it from the profile; [LookRoot]
/// applies it above every screen, dialog and sheet.
@immutable
class SofraLook {
  const SofraLook({
    this.appearance = Appearance.system,
    this.textStep = 0,
    this.colorVision = ColorVision.none,
    this.reduceMotion = false,
    this.language = AppLanguage.ar,
  });

  final Appearance appearance;

  /// 0 normal, 1 large, 2 larger; multiplies the phone's own text size.
  final int textStep;
  final ColorVision colorVision;
  final bool reduceMotion;
  final AppLanguage language;

  static const textScales = [1.0, 1.15, 1.3];
  double get textScale => textScales[textStep.clamp(0, 2)];

  static final notifier = ValueNotifier(const SofraLook());

  /// Publishes [look], after the current frame if one is being built.
  static void publish(SofraLook look) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => notifier.value = look,
      );
    } else {
      notifier.value = look;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SofraLook &&
      other.appearance == appearance &&
      other.textStep == textStep &&
      other.colorVision == colorVision &&
      other.reduceMotion == reduceMotion &&
      other.language == language;

  @override
  int get hashCode =>
      Object.hash(appearance, textStep, colorVision, reduceMotion, language);
}

/// Applies [SofraLook.notifier] to everything below it: the palette and
/// theme, text size, reduced motion, colour correction and the language's
/// reading direction.
class LookRoot extends StatefulWidget {
  const LookRoot({super.key, required this.child});
  final Widget child;

  @override
  State<LookRoot> createState() => _LookRootState();
}

class _LookRootState extends State<LookRoot> {
  @override
  void initState() {
    super.initState();
    SofraLook.notifier.addListener(_changed);
  }

  @override
  void dispose() {
    SofraLook.notifier.removeListener(_changed);
    super.dispose();
  }

  AppLanguage? _language;

  void _changed() => setState(() {});

  /// Rebuilds every element after the palette changes, so widgets built
  /// once as constants pick up the new colours too.
  void _repaintAll() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    if (mounted) (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) {
    final look = SofraLook.notifier.value;
    final media = MediaQuery.of(context);
    final dark = switch (look.appearance) {
      Appearance.dark => true,
      Appearance.light => false,
      Appearance.system => media.platformBrightness == Brightness.dark,
    };
    final palette = dark ? SofraPalette.dark : SofraPalette.light;
    if (!identical(Sofra.palette, palette)) {
      Sofra.use(palette);
      SchedulerBinding.instance.addPostFrameCallback((_) => _repaintAll());
    }
    if (_language != null && _language != look.language) {
      // Strings read without a context change too; rebuild them all.
      SchedulerBinding.instance.addPostFrameCallback((_) => _repaintAll());
    }
    _language = look.language;
    final base = media.textScaler.scale(14) / 14;
    Widget child = Theme(
      data: sofraTheme(),
      child: MediaQuery(
        data: media.copyWith(
          textScaler: TextScaler.linear(base * look.textScale),
          disableAnimations: media.disableAnimations || look.reduceMotion,
        ),
        child: Directionality(
          textDirection: look.language.direction,
          child: widget.child,
        ),
      ),
    );
    final correction = colorCorrection(look.colorVision);
    if (correction != null) {
      child = ColorFiltered(
        colorFilter: ColorFilter.matrix(correction),
        child: child,
      );
    }
    return child;
  }
}

/// The 4x5 colour matrix correcting [vision], or null for none.
///
/// Daltonization (Fidaner, Lin and Ozguven): simulate what the eye sees in
/// LMS space, take the error against the original, and add it back shifted
/// into the channels the eye still separates.
List<double>? colorCorrection(ColorVision vision) {
  if (vision == ColorVision.none) return null;
  const rgb2lms = [
    [17.8824, 43.5161, 4.11935],
    [3.45565, 27.1554, 3.86714],
    [0.0299566, 0.184309, 1.46709],
  ];
  const lms2rgb = [
    [0.0809444479, -0.130504409, 0.116721066],
    [-0.0102485335, 0.0540193266, -0.113614708],
    [-0.000365296938, -0.00412161469, 0.693511405],
  ];
  final sim = switch (vision) {
    ColorVision.protan => const [
      [0.0, 2.02344, -2.52581],
      [0.0, 1.0, 0.0],
      [0.0, 0.0, 1.0],
    ],
    ColorVision.deutan => const [
      [1.0, 0.0, 0.0],
      [0.494207, 0.0, 1.24827],
      [0.0, 0.0, 1.0],
    ],
    _ => const [
      [1.0, 0.0, 0.0],
      [0.0, 1.0, 0.0],
      [-0.395913, 0.801109, 0.0],
    ],
  };
  const shift = [
    [0.0, 0.0, 0.0],
    [0.7, 1.0, 0.0],
    [0.7, 0.0, 1.0],
  ];
  List<List<double>> mul(List<List<double>> a, List<List<double>> b) => [
    for (var i = 0; i < 3; i++)
      [
        for (var j = 0; j < 3; j++)
          a[i][0] * b[0][j] + a[i][1] * b[1][j] + a[i][2] * b[2][j],
      ],
  ];
  final simulate = mul(lms2rgb, mul(sim, rgb2lms));
  final error = [
    for (var i = 0; i < 3; i++)
      [for (var j = 0; j < 3; j++) (i == j ? 1.0 : 0.0) - simulate[i][j]],
  ];
  final add = mul(shift, error);
  final m = [
    for (var i = 0; i < 3; i++)
      [for (var j = 0; j < 3; j++) (i == j ? 1.0 : 0.0) + add[i][j]],
  ];
  return [
    for (final row in m) ...[...row, 0, 0],
    0,
    0,
    0,
    1,
    0,
  ];
}

final _field = OutlineInputBorder(
  borderRadius: BorderRadius.circular(Sofra.r16),
  borderSide: BorderSide.none,
);

/// The Material theme for the current palette.
ThemeData sofraTheme() => ThemeData(
  useMaterial3: true,
  brightness: Sofra.isDark ? Brightness.dark : Brightness.light,
  fontFamily: 'IBMPlexSansArabic',
  scaffoldBackgroundColor: Sofra.cream,
  splashFactory: InkSparkle.splashFactory,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Sofra.accent,
    brightness: Sofra.isDark ? Brightness.dark : Brightness.light,
    primary: Sofra.accent,
    onPrimary: Sofra.onAccent,
    secondary: Sofra.warn,
    surface: Sofra.cream,
    onSurface: Sofra.ink,
    surfaceContainerHighest: Sofra.surface,
  ),
  textTheme: TextTheme(
    bodyMedium: TextStyle(color: Sofra.ink, fontSize: 15, height: 1.6),
    bodyLarge: TextStyle(color: Sofra.ink, fontSize: 16, height: 1.6),
    titleLarge: TextStyle(
      fontFamily: Sofra.headingFamily,
      color: Sofra.ink,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation('wght', 700)],
    ),
  ),
  iconTheme: IconThemeData(color: Sofra.ink),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Sofra.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    hintStyle: TextStyle(color: Sofra.muted),
    border: _field,
    enabledBorder: _field,
    focusedBorder: _field.copyWith(
      borderSide: BorderSide(color: Sofra.sage, width: 1.5),
    ),
    errorBorder: _field.copyWith(
      borderSide: BorderSide(color: Sofra.orange, width: 1.5),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Sofra.surface,
    selectedColor: Sofra.accentTint,
    side: BorderSide.none,
    labelStyle: TextStyle(
      fontWeight: FontWeight.w700,
      color: Sofra.ink,
      height: 1.3,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Sofra.r12),
    ),
    showCheckmark: false,
    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: Sofra.cream,
    showDragHandle: true,
    dragHandleColor: Sofra.line,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Sofra.r28)),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: Sofra.cream,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Sofra.r28),
    ),
  ),
  popupMenuTheme: PopupMenuThemeData(color: Sofra.paper),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Sofra.inverse,
    contentTextStyle: TextStyle(color: Sofra.onInverse),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Sofra.r16),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? Sofra.onAccent : Sofra.muted,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? Sofra.accent : Sofra.sand,
    ),
    trackOutlineColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? Sofra.accent : Sofra.line,
    ),
  ),
);
