/// User-reviewed whole-recipe yield, never a replacement for source evidence.
class RecipeYieldReview {
  RecipeYieldReview({
    required this.sourceRevisionKey,
    required this.sourceSnapshotVersion,
    required this.baseServings,
    required this.note,
    required this.acknowledgeWholeRecipeYield,
    required DateTime reviewedAt,
  }) : reviewedAt = reviewedAt.toUtc() {
    if (sourceRevisionKey.trim().isEmpty ||
        sourceSnapshotVersion.trim().isEmpty ||
        note.trim().isEmpty ||
        baseServings < 1 ||
        baseServings > 1000 ||
        !acknowledgeWholeRecipeYield) {
      throw ArgumentError(
        'Exact source, whole-recipe yield1..1000 and review note required',
      );
    }
  }
  final String sourceRevisionKey, sourceSnapshotVersion, note;
  final int baseServings;
  final bool acknowledgeWholeRecipeYield;
  final DateTime reviewedAt;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'sourceRevisionKey': sourceRevisionKey,
    'sourceSnapshotVersion': sourceSnapshotVersion,
    'baseServings': baseServings,
    'note': note,
    'acknowledgeWholeRecipeYield': acknowledgeWholeRecipeYield,
    'reviewedAt': reviewedAt.toIso8601String(),
  };
  factory RecipeYieldReview.fromJson(Map<String, dynamic> j) {
    const keys = {
      'version',
      'sourceRevisionKey',
      'sourceSnapshotVersion',
      'baseServings',
      'note',
      'acknowledgeWholeRecipeYield',
      'reviewedAt',
    };
    if (j['version'] != 1 ||
        j.length != keys.length ||
        !keys.every(j.containsKey)) {
      throw const FormatException('Whole-recipe yield review schema');
    }
    final stamp = j['reviewedAt'] as String;
    final date = DateTime.parse(stamp);
    if (!stamp.endsWith('Z') || date.toUtc().toIso8601String() != stamp) {
      throw const FormatException('Canonical UTC review date required');
    }
    return RecipeYieldReview(
      sourceRevisionKey: j['sourceRevisionKey'] as String,
      sourceSnapshotVersion: j['sourceSnapshotVersion'] as String,
      baseServings: j['baseServings'] as int,
      note: j['note'] as String,
      acknowledgeWholeRecipeYield: j['acknowledgeWholeRecipeYield'] as bool,
      reviewedAt: date,
    );
  }
}
