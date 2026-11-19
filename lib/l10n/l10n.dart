import 'package:flutter/widgets.dart';

import '../app/look.dart';
import 'app_localizations.dart';
import 'data_terms.dart';

export '../app/look.dart' show AppLanguage;
export 'app_localizations.dart';

/// The app's language, read from the published look so code without a
/// [BuildContext] (controller, domain messages, reminders) speaks the same
/// language as the screens.
abstract final class L10n {
  static final _cache = <AppLanguage, AppLocalizations>{};

  static AppLanguage get language => SofraLook.notifier.value.language;
  static bool get isEnglish => language == AppLanguage.en;
  static bool get isArabic => language == AppLanguage.ar;

  /// Strings in the current language.
  static AppLocalizations get current => of(language);

  static AppLocalizations of(AppLanguage language) =>
      _cache[language] ??= lookupAppLocalizations(Locale(language.name));

  static const supportedLocales = AppLocalizations.supportedLocales;
  static const delegates = AppLocalizations.localizationsDelegates;

  /// A label from the data (a cuisine, a category, a unit) in the current
  /// language; Arabic data without an English name stays as it is.
  static String term(String arabic) {
    if (!isEnglish) return arabic;
    return dataTermsEn[arabic.trim()] ?? arabic;
  }

  /// [arabic] or, in English, [english] when the data has it.
  static String pick(String arabic, String? english) =>
      isEnglish && english != null && english.trim().isNotEmpty
      ? english.trim()
      : arabic;
}

extension L10nContext on BuildContext {
  /// Strings in the current language. Depends on [Localizations] when the
  /// app provides them, so the widget rebuilds when the language changes.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      L10n.current;
}
