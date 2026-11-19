import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../l10n/l10n.dart';
import '../ui/design.dart';

/// A small pill that switches to the other language, named in that
/// language («English» while in Arabic, «العربية» while in English).
class LanguagePill extends StatelessWidget {
  const LanguagePill({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final other = c.profile.language == AppLanguage.ar
        ? AppLanguage.en
        : AppLanguage.ar;
    // A fixed size chip: it sits beside the step header at any text size.
    return MediaQuery.withNoTextScaling(child: _pill(c, other));
  }

  Widget _pill(SofraController c, AppLanguage other) {
    return Material(
      color: Sofra.sand,
      shape: const StadiumBorder(),
      child: InkWell(
        key: const ValueKey('lang-toggle'),
        customBorder: const StadiumBorder(),
        onTap: () => c.updateProfile((p) => p.copyWith(language: other)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.translate_rounded, size: 16, color: Sofra.muted),
                const SizedBox(width: 6),
                Text(
                  L10n.of(c.profile.language).langToggle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Sofra.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
