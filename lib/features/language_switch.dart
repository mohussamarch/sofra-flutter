import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../l10n/l10n.dart';
import '../ui/design.dart';

/// The language choice: «العربية | English», each name in its own script,
/// the current one raised. The same control sits centred at the top of the
/// first setup step and in the last row of «العرض واللغة» in settings.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key, this.id = 'lang'});

  /// Each part is keyed `<id>-ar` and `<id>-en`.
  final String id;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final t = context.l10n;
    // Fixed order in both languages («العربية» right, «English» left):
    // the layout flips when the language changes, but the two names must
    // not swap places under the finger; only the selection slides.
    // Shrinks rather than overflows at the largest text sizes.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SofraSegments<AppLanguage>(
          id: id,
          label: t.lookLanguage,
          value: c.profile.language,
          onChanged: (v) => c.updateProfile((p) => p.copyWith(language: v)),
          options: [
            SofraSegment(
              AppLanguage.ar,
              t.lookLanguageArabic,
              text: t.lookLanguageArabic,
            ),
            SofraSegment(
              AppLanguage.en,
              t.lookLanguageEnglish,
              text: t.lookLanguageEnglish,
            ),
          ],
        ),
      ),
    );
  }
}
