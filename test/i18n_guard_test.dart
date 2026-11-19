import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files whose Arabic literals are data, not UI text: catalogs, matching
/// tables and vocabularies read or compared against stored Arabic values.
/// Their labels reach the screen through `L10n.term` or the data's own
/// English fields.
const dataFiles = <String>{
  // Parser vocabulary for typed or pasted purchase lists.
  'lib/domain/quick_add.dart',
  // Generated: ingredient-group ids from vocabulary.json -> symbol.
  'lib/ui/symbols.g.dart',
  // Sample household content, like the recipe JSON.
  'lib/data/demo_data.dart',
  // Dev spike entry point, not part of the shipped app.
  'lib/main_scene_spike.dart',
};

/// A line may also keep an Arabic literal that is a stored value or a
/// matching key (never shown as is) by ending with this marker.
const marker = '// i18n-data';

final _arabic = RegExp(r'[؀-ۿ]');

/// [line] without its trailing `//` comment, skipping `//` inside quotes.
String _code(String line) {
  String? quote;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (quote != null) {
      if (ch == r'\') {
        i++;
      } else if (line.startsWith(quote, i)) {
        i += quote.length - 1;
        quote = null;
      }
    } else if (ch == "'" || ch == '"') {
      quote = line.startsWith(ch * 3, i) ? ch * 3 : ch;
      i += quote.length - 1;
    } else if (line.startsWith('//', i)) {
      return line.substring(0, i);
    }
  }
  return line;
}

void main() {
  test('no Arabic string literal is used as UI text in lib/', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final path = file.path.replaceAll(r'\', '/');
      if (path.startsWith('lib/l10n/')) continue;
      if (dataFiles.contains(path)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimRight().endsWith(marker)) continue;
        if (_arabic.hasMatch(_code(line))) {
          offenders.add('$path:${i + 1}: ${line.trim()}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Move UI text to lib/l10n/app_ar.arb and app_en.arb, or mark a '
          'stored value with "$marker".\n${offenders.join('\n')}',
    );
  });

  test('every listed data file still exists', () {
    for (final path in dataFiles) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
