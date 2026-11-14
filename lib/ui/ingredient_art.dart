import 'package:flutter/material.dart';

import 'symbols.g.dart';

/// Stand-in art for an ingredient until Codex's drawn set arrives
/// (`assets/ingredients/<id>.webp`, CL2C-001/4): a fitting emoji, else one for
/// its category.
String ingredientGlyph(String id, String? category) =>
    _glyphs[id] ?? _categoryGlyphs[category] ?? '🥣';

const _categoryGlyphs = {
  'توابل': '🧂',
  'مشروبات': '🧃',
  'صوصات': '🥫',
  'حبوب': '🌾',
  'ألبان': '🥛',
  'زيوت': '🫒',
  'مكسرات': '🥜',
  'خضار': '🥬',
  'فاكهة': '🍎',
  'بروتين': '🍖',
  'مخبوزات': '🍞',
  'بقوليات': '🫘',
};

const _glyphs = {
  'tomato': '🍅',
  'cherry-tomato': '🍅',
  'cucumber': '🥒',
  'carrot': '🥕',
  'onion': '🧅',
  'red-onion': '🧅',
  'shallot': '🧅',
  'garlic': '🧄',
  'potato': '🥔',
  'sweet-potato': '🍠',
  'eggplant': '🍆',
  'bell-pepper': '🫑',
  'hot-pepper': '🌶️',
  'jalapeno': '🌶️',
  'chili': '🌶️',
  'lettuce': '🥬',
  'cabbage': '🥬',
  'spinach': '🥬',
  'arugula': '🥬',
  'molokhia': '🥬',
  'chard': '🥬',
  'broccoli': '🥦',
  'cauliflower': '🥦',
  'corn': '🌽',
  'mushrooms': '🍄',
  'avocado': '🥑',
  'ginger': '🫚',
  'peas': '🫛',
  'snow-peas': '🫛',
  'green-beans': '🫛',
  'lemon': '🍋',
  'lime': '🍋',
  'lemon-juice': '🍋',
  'lime-juice': '🍋',
  'orange': '🍊',
  'mandarin': '🍊',
  'orange-juice': '🧃',
  'apple': '🍎',
  'banana': '🍌',
  'mango': '🥭',
  'pineapple': '🍍',
  'green-olives': '🫒',
  'black-olives': '🫒',
  'chicken': '🐔',
  'chicken-breast': '🍗',
  'chicken-thighs': '🍗',
  'chicken-wings': '🍗',
  'drumsticks': '🍗',
  'turkey': '🦃',
  'duck': '🦆',
  'beef': '🥩',
  'veal': '🥩',
  'lamb': '🥩',
  'liver': '🥩',
  'sausage': '🌭',
  'fish': '🐟',
  'salmon': '🐟',
  'smoked-salmon': '🐟',
  'tuna': '🐟',
  'shrimp': '🦐',
  'calamari': '🦑',
  'octopus': '🐙',
  'eggs': '🥚',
  'milk': '🥛',
  'buttermilk': '🥛',
  'cream': '🥛',
  'whipping-cream': '🥛',
  'butter': '🧈',
  'ghee': '🧈',
  'parmigiano': '🧀',
  'pecorino': '🧀',
  'mozzarella': '🧀',
  'feta': '🧀',
  'cheddar': '🧀',
  'white-cheese': '🧀',
  'romy-cheese': '🧀',
  'cream-cheese': '🧀',
  'ricotta': '🧀',
  'gruyere': '🧀',
  'swiss-cheese': '🧀',
  'kashkaval': '🧀',
  'bread': '🍞',
  'toast-bread': '🍞',
  'baladi-bread': '🫓',
  'pita-bread': '🫓',
  'baguette': '🥖',
  'rice': '🍚',
  'honey': '🍯',
  'salt': '🧂',
  'water': '💧',
  'coconut-milk': '🥥',
  'peanuts': '🥜',
};

/// The ingredient's picture: a soft 3D symbol (Fluent Emoji, MIT) chosen for
/// it or for its category; the plain glyph only if neither has one.
class IngredientPicture extends StatelessWidget {
  const IngredientPicture(this.id, this.category, {super.key, this.size = 48});

  final String id;
  final String? category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = symbolById[id] ?? symbolByCategory[category];
    final glyph = Text(
      ingredientGlyph(id, category),
      style: TextStyle(fontSize: size * .72, height: 1),
    );
    return SizedBox.square(
      dimension: size,
      child: name == null
          ? Center(child: glyph)
          : Image.asset(
              'assets/symbols/$name.png',
              width: size,
              height: size,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => Center(child: glyph),
            ),
    );
  }
}
