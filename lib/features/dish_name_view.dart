import 'package:flutter/material.dart';

import '../l10n/dish_name.dart';
import '../l10n/l10n.dart';
import '../ui/design.dart';
import '../ui/flags.dart';

export '../l10n/dish_name.dart' show DishName;

/// A dish name with what the reviewed glossary adds to it: the country tag
/// when dishes of several countries share the English name, and, with
/// [pronunciation], an (i) that shows how to say it.
class DishTitle extends StatelessWidget {
  const DishTitle(
    this.text, {
    super.key,
    required this.recipeId,
    required this.style,
    this.pronunciation = false,
  });

  final String text;
  final String recipeId;
  final TextStyle style;
  final bool pronunciation;

  @override
  Widget build(BuildContext context) {
    final name = DishName.of(recipeId);
    final country = name?.country;
    final say = pronunciation ? name?.say : null;
    if (country == null && say == null) return Text(text, style: style);
    // The name stays its own Text (a long one wraps beside the extras).
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(text, style: style)),
        if (country != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 8),
            child: CountryNameTag(
              name!,
              key: ValueKey('country-tag-$recipeId'),
            ),
          ),
        if (say != null) PronunciationInfo(name!),
      ],
    );
  }
}

/// Small coloured tag with the dish's country, for an English name that
/// several countries share.
class CountryNameTag extends StatelessWidget {
  const CountryNameTag(this.name, {super.key});
  final DishName name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 3, 10, 3),
      decoration: BoxDecoration(
        color: Sofra.okTint,
        borderRadius: BorderRadius.circular(Sofra.r12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CuisineFlag(name.countryAr!, size: 16),
          const SizedBox(width: 6),
          Text(
            name.country!,
            style: TextStyle(
              color: Sofra.ok,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// An (i) after a dish name: a tap shows how to say it.
class PronunciationInfo extends StatelessWidget {
  const PronunciationInfo(this.name, {super.key});
  final DishName name;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final say = name.say!;
    return Tooltip(
      key: const ValueKey('pronunciation-info'),
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 6),
      richMessage: TextSpan(
        children: [
          TextSpan(
            text: '${t.detailPronunciation}\n',
            style: TextStyle(
              fontSize: 12,
              color: Sofra.onInverse.withValues(alpha: .72),
            ),
          ),
          // In Arabic the English spelling comes first, so the sounds
          // have the letters they belong to.
          if (!L10n.isEnglish)
            TextSpan(
              text: '${name.en}\n',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          TextSpan(
            text: say,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      textAlign: TextAlign.start,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Sofra.inverse,
        borderRadius: BorderRadius.circular(Sofra.r12),
      ),
      textStyle: TextStyle(color: Sofra.onInverse, height: 1.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(Icons.info_outline_rounded, size: 20, color: Sofra.muted),
      ),
    );
  }
}
