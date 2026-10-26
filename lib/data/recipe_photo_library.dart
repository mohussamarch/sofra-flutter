import 'dart:convert';

import 'package:flutter/services.dart';

/// One licensed photo of a catalog dish, bundled with the app.
class RecipePhoto {
  RecipePhoto({
    required this.file,
    required this.credit,
    required this.licence,
    this.source,
    this.width,
    this.height,
  }) {
    if (!RegExp(r'^[a-z0-9-]+(-\d+)?\.(webp|jpg|png)$').hasMatch(file) ||
        credit.trim().isEmpty ||
        licence.trim().isEmpty) {
      throw FormatException('Invalid recipe photo $file');
    }
  }
  final String file, credit, licence;
  final String? source;
  final int? width, height;

  String get asset => '${RecipePhotoLibrary.folder}/$file';

  factory RecipePhoto.fromJson(Map<String, dynamic> j) => RecipePhoto(
    file: j['file'] as String,
    credit: j['credit'] as String,
    licence: j['licence'] as String,
    source: j['source'] as String?,
    width: (j['width'] as num?)?.toInt(),
    height: (j['height'] as num?)?.toInt(),
  );
}

/// Dish photos by recipe ID, from `assets/recipe-photos/manifest.json`
/// (contract: docs/dev/RECIPE-PHOTOS.md). Empty until photos are added;
/// a dish without a photo shows none, never a stand-in from another dish.
class RecipePhotoLibrary {
  RecipePhotoLibrary({Future<String> Function(String)? read})
    : _read = read ?? rootBundle.loadString;
  static const folder = 'assets/recipe-photos';
  final Future<String> Function(String) _read;
  Future<Map<String, List<RecipePhoto>>>? _photos;

  Future<Map<String, List<RecipePhoto>>> get all =>
      _photos ??= _load().catchError((Object e) {
        _photos = null;
        throw e;
      });

  Future<List<RecipePhoto>> photosOf(String recipeId) async =>
      (await all)[recipeId] ?? const [];

  Future<Map<String, List<RecipePhoto>>> _load() async {
    final json = jsonDecode(
      await _read('$folder/manifest.json'),
    ) as Map<String, dynamic>;
    if (json['version'] != 1) throw const FormatException('Photo manifest');
    return Map.unmodifiable({
      for (final e in (json['photos'] as Map<String, dynamic>).entries)
        e.key: List<RecipePhoto>.unmodifiable([
          for (final p in e.value as List)
            RecipePhoto.fromJson(Map<String, dynamic>.from(p as Map)),
        ]),
    });
  }
}
