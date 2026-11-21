import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';
import 'design.dart';

/// Sofra's wordmark (the owner's chosen logo, «الرقعة على خط المائدة»):
/// «سفرة» in Arabic, "Sofra" in English, the light-on-dark cut in the dark
/// look. Bitmaps at 1x/2x/3x, rendered from tool/brand/svg by
/// tool/brand/render_brand.py.
class SofraLogo extends StatelessWidget {
  const SofraLogo({super.key, this.height = 32});

  /// Height in logical pixels; the bitmaps are drawn for 40 or less.
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
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        // Keeps the space while the bitmap loads, so nothing jumps.
        gaplessPlayback: true,
      ),
    );
  }
}
