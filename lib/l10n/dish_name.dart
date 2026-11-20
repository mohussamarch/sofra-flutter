import 'dish_names.g.dart';
import 'l10n.dart';

/// A catalog dish's reviewed English name (data/dish-names/glossary.json).
class DishName {
  const DishName(this.en, {this.say, this.countryEn, this.countryAr});

  /// The English name: the most used verified spelling.
  final String en;

  /// How to say the transliterated words, stressed syllable in capitals;
  /// null when the name is plain English.
  final String? say;

  /// Set only when dishes of several countries share [en]: the country
  /// word shown as a small tag next to the name.
  final String? countryEn, countryAr;

  /// The country tag in the current language, or null when the name is
  /// not shared across countries.
  String? get country => countryEn == null
      ? null
      : L10n.isEnglish
      ? countryEn
      : countryAr;

  /// The reviewed name of recipe [id], or null when it has none.
  static DishName? of(Object? id) => dishNames[id];
}
