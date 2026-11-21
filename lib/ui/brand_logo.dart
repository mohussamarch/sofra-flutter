import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';
import 'design.dart';

/// Sofra's wordmark (the owner's chosen logo, «الرقعة على خط المائدة»):
/// «سفرة» in Arabic, "Sofra" in English, the light-on-dark cut in the dark
/// look. Bitmaps at 1x/2x/3x/4x, rendered from tool/brand/svg by
/// tool/brand/render_brand.py.
class SofraLogo extends StatelessWidget {
  const SofraLogo({super.key, this.height = 32})
    : assert(
        height * arabicScale <= maxHeight,
        'SofraLogo bitmaps are drawn for $maxHeight or less',
      );

  /// Height of the 1x bitmap (LOGO_H in tool/brand/render_brand.py). Larger
  /// would upscale the bitmap and soften it.
  static const double maxHeight = 48;

  /// «سفرة» is a shorter, lighter word than "Sofra" at the same box height,
  /// so the Arabic cut is drawn a little taller to read at the same size.
  static const double arabicScale = 1.1;

  /// Height in logical pixels, as the English wordmark; the Arabic one is
  /// [arabicScale] times taller.
  final double height;

  static String asset({required bool english, required bool dark}) =>
      'assets/brand/logo-${english ? 'en' : 'ar'}${dark ? '-dark' : ''}.png';

  @override
  Widget build(BuildContext context) {
    final path = asset(english: L10n.isEnglish, dark: Sofra.isDark);
    return Semantics(
      label: context.l10n.appTitle,
      image: true,
      excludeSemantics: true,
      child: Image.asset(
        path,
        key: ValueKey('brand-logo:$path'),
        height: L10n.isEnglish ? height : height * arabicScale,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        // Keeps the space while the bitmap loads, so nothing jumps.
        gaplessPlayback: true,
      ),
    );
  }
}
