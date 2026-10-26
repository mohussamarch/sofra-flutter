/// Community and shared-kitchen records: plain data with validation, no I/O.
/// Firestore shapes match firestore.rules.
library;

final _photoPath = RegExp(r'^photos/[A-Za-z0-9_-]{1,64}/[A-Za-z0-9_.-]{1,96}$');

/// A picture kept in file storage. Uploads are not switched on yet (no
/// storage service chosen); records already carry an empty `photos` list so
/// the library can be filled later without reshaping data.
class PhotoRef {
  PhotoRef({
    required this.path,
    required this.byUid,
    this.width,
    this.height,
    this.caption,
  }) {
    if (!_photoPath.hasMatch(path) || byUid.isEmpty) {
      throw ArgumentError('Invalid photo');
    }
  }
  final String path, byUid;
  final int? width, height;
  final String? caption;

  Map<String, Object?> toJson() => {
    'path': path,
    'by': byUid,
    'width': ?width,
    'height': ?height,
    'caption': ?caption,
  };

  factory PhotoRef.fromJson(Map<String, dynamic> j) => PhotoRef(
    path: j['path'] as String,
    byUid: j['by'] as String,
    width: (j['width'] as num?)?.toInt(),
    height: (j['height'] as num?)?.toInt(),
    caption: j['caption'] as String?,
  );
}

List<PhotoRef> _photos(Object? v) => [
  for (final p in (v as List?) ?? const [])
    PhotoRef.fromJson(Map<String, dynamic>.from(p as Map)),
];

String _text(String v, int max, String what) {
  final t = v.trim();
  if (t.isEmpty || t.length > max) throw ArgumentError('Invalid $what');
  return t;
}

/// One ingredient line of a shared recipe, as the author wrote it.
class SharedLine {
  SharedLine(String name, {this.amount, this.unit})
    : name = _text(name, 80, 'line') {
    if ((amount == null) != (unit == null) ||
        (amount != null && (amount! <= 0 || !amount!.isFinite))) {
      throw ArgumentError('Invalid amount');
    }
  }
  final String name;
  final double? amount;
  final String? unit;

  Map<String, Object?> toJson() => {
    'name': name,
    'amount': ?amount,
    'unit': ?unit,
  };
  factory SharedLine.fromJson(Map<String, dynamic> j) => SharedLine(
    j['name'] as String,
    amount: (j['amount'] as num?)?.toDouble(),
    unit: j['unit'] as String?,
  );
}

/// A household's own recipe published to the community.
class SharedRecipe {
  SharedRecipe({
    required this.id,
    required this.authorUid,
    required String authorName,
    required String title,
    required this.servings,
    required List<SharedLine> lines,
    required List<String> steps,
    this.cuisine,
    List<PhotoRef> photos = const [],
    this.createdAt,
  }) : authorName = _text(authorName, 60, 'author'),
       title = _text(title, 80, 'title'),
       lines = List.unmodifiable(lines),
       steps = List.unmodifiable(steps.map((s) => _text(s, 600, 'step'))),
       photos = List.unmodifiable(photos) {
    if (id.isEmpty ||
        authorUid.isEmpty ||
        servings < 1 ||
        servings > 50 ||
        lines.isEmpty ||
        lines.length > 60 ||
        steps.isEmpty ||
        steps.length > 40 ||
        photos.length > 8) {
      throw ArgumentError('Invalid shared recipe');
    }
  }
  final String id, authorUid, authorName, title;
  final String? cuisine;
  final int servings;
  final List<SharedLine> lines;
  final List<String> steps;
  final List<PhotoRef> photos;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => {
    'author': authorUid,
    'authorName': authorName,
    'title': title,
    'cuisine': ?cuisine,
    'servings': servings,
    'lines': [for (final l in lines) l.toJson()],
    'steps': steps,
    'photos': [for (final p in photos) p.toJson()],
  };

  factory SharedRecipe.fromJson(
    String id,
    Map<String, dynamic> j, {
    DateTime? createdAt,
  }) => SharedRecipe(
    id: id,
    authorUid: j['author'] as String,
    authorName: j['authorName'] as String,
    title: j['title'] as String,
    cuisine: j['cuisine'] as String?,
    servings: (j['servings'] as num).toInt(),
    lines: [
      for (final l in j['lines'] as List)
        SharedLine.fromJson(Map<String, dynamic>.from(l as Map)),
    ],
    steps: (j['steps'] as List).cast<String>(),
    photos: _photos(j['photos']),
    createdAt: createdAt,
  );
}

/// One household's stars and optional comment on a shared recipe.
class Rating {
  Rating({
    required this.uid,
    required String name,
    required this.stars,
    String comment = '',
    this.at,
  }) : name = _text(name, 60, 'name'),
       comment = comment.trim() {
    if (uid.isEmpty || stars < 1 || stars > 5 || this.comment.length > 500) {
      throw ArgumentError('Invalid rating');
    }
  }
  final String uid, name, comment;
  final int stars;
  final DateTime? at;

  Map<String, Object?> toJson() => {
    'name': name,
    'stars': stars,
    'comment': comment,
  };
  factory Rating.fromJson(String uid, Map<String, dynamic> j, {DateTime? at}) =>
      Rating(
        uid: uid,
        name: j['name'] as String,
        stars: (j['stars'] as num).toInt(),
        comment: j['comment'] as String? ?? '',
        at: at,
      );
}

/// Average stars, or null with no ratings.
double? averageStars(List<Rating> ratings) => ratings.isEmpty
    ? null
    : ratings.map((r) => r.stars).reduce((a, b) => a + b) / ratings.length;

/// Area key: one spelling for the same place typed differently.
String areaKey(String area) => area
    .trim()
    .toLowerCase()
    .replaceAll(RegExp('[ًٌٍَُِّْـ]'), '')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .replaceAll(RegExp(r'\s+'), ' ');

/// A price a household paid, shared with others in the same area.
class PriceReport {
  PriceReport({
    required this.uid,
    required this.country,
    required String area,
    required this.ingredientId,
    required this.quantity,
    required this.unit,
    required this.amount,
    required this.paidOn,
  }) : area = areaKey(area) {
    if (uid.isEmpty ||
        !{'EG', 'SA'}.contains(country) ||
        this.area.isEmpty ||
        this.area.length > 60 ||
        ingredientId.isEmpty ||
        unit.isEmpty ||
        quantity <= 0 ||
        !quantity.isFinite ||
        amount <= 0 ||
        !amount.isFinite) {
      throw ArgumentError('Invalid price report');
    }
  }
  final String uid, country, area, ingredientId, unit;
  final double quantity, amount;
  final DateTime paidOn;

  double get perUnit => amount / quantity;

  Map<String, Object?> toJson() => {
    'uid': uid,
    'country': country,
    'area': area,
    'ingredientId': ingredientId,
    'quantity': quantity,
    'unit': unit,
    'amount': amount,
    'paidOn': _day(paidOn),
  };
  factory PriceReport.fromJson(Map<String, dynamic> j) => PriceReport(
    uid: j['uid'] as String,
    country: j['country'] as String,
    area: j['area'] as String,
    ingredientId: j['ingredientId'] as String,
    quantity: (j['quantity'] as num).toDouble(),
    unit: j['unit'] as String,
    amount: (j['amount'] as num).toDouble(),
    paidOn: DateTime.parse(j['paidOn'] as String),
  );
}

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// What people in an area paid for one ingredient in one unit.
class AreaPrice {
  const AreaPrice(this.medianPerUnit, this.reports, this.households);
  final double medianPerUnit;
  final int reports, households;
}

/// Median per-unit price from the last [maxAgeDays] days, only when at
/// least [minHouseholds] different households reported it, so one person's
/// number is never shown as "the area's price".
AreaPrice? areaPrice(
  List<PriceReport> reports, {
  required String ingredientId,
  required String unit,
  required DateTime today,
  int maxAgeDays = 60,
  int minHouseholds = 2,
}) {
  final from = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(Duration(days: maxAgeDays));
  final rows = [
    for (final r in reports)
      if (r.ingredientId == ingredientId &&
          r.unit == unit &&
          !r.paidOn.isBefore(from))
        r,
  ];
  final households = rows.map((r) => r.uid).toSet().length;
  if (households < minHouseholds) return null;
  final values = rows.map((r) => r.perUnit).toList()..sort();
  final mid = values.length ~/ 2;
  final median = values.length.isOdd
      ? values[mid]
      : (values[mid - 1] + values[mid]) / 2;
  return AreaPrice(median, rows.length, households);
}

// ---- Weekly challenges -----------------------------------------------------

/// Saturday that starts the week of [day] (the Egyptian/Saudi week).
DateTime weekStart(DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  return d.subtract(Duration(days: (d.weekday - DateTime.saturday) % 7));
}

String weekKey(DateTime day) => _day(weekStart(day));

enum ChallengeKind { cookPlanned, differentRecipes, newRecipes }

/// A goal measured from the household's own cooking record.
class Challenge {
  const Challenge(this.kind, this.goal, this.title, this.detail);
  final ChallengeKind kind;
  final int goal;
  final String title, detail;
}

const challenges = [
  Challenge(
    ChallengeKind.cookPlanned,
    4,
    'اطبخ ٤ وجبات من خطتك',
    'كل وجبة متخططة اتطبخت الأسبوع ده بتتحسب.',
  ),
  Challenge(
    ChallengeKind.differentRecipes,
    3,
    'نوّع: ٣ أكلات مختلفة',
    'كل وصفة مختلفة اتطبخت الأسبوع ده بتتحسب مرة.',
  ),
  Challenge(
    ChallengeKind.newRecipes,
    2,
    'جرّب وصفتين أول مرة',
    'وصفة متطبختش قبل كده في مطبخك.',
  ),
];

/// The same challenge for everyone in a given week, rotating weekly.
Challenge challengeFor(DateTime day) {
  final weeks = weekStart(day).difference(DateTime(2026, 1, 3)).inDays ~/ 7;
  return challenges[weeks % challenges.length];
}

/// Progress from cooked meals: (date `yyyy-mm-dd`, recipe ID) pairs.
int challengeProgress(
  Challenge c,
  DateTime day,
  List<(String, String)> cooked,
) {
  final start = weekKey(day),
      end = _day(weekStart(day).add(const Duration(days: 7)));
  bool inWeek(String d) => d.compareTo(start) >= 0 && d.compareTo(end) < 0;
  final week = [
    for (final m in cooked)
      if (inWeek(m.$1)) m,
  ];
  return switch (c.kind) {
    ChallengeKind.cookPlanned => week.length,
    ChallengeKind.differentRecipes => week.map((m) => m.$2).toSet().length,
    ChallengeKind.newRecipes => {
      for (final m in week)
        if (!cooked.any((o) => o.$2 == m.$2 && o.$1.compareTo(start) < 0)) m.$2,
    }.length,
  };
}

/// A household's standing in this week's challenge.
class ChallengeEntry {
  ChallengeEntry({
    required this.uid,
    required String name,
    required this.progress,
    required this.goal,
  }) : name = _text(name, 60, 'name') {
    if (uid.isEmpty || progress < 0 || progress > 100 || goal < 1) {
      throw ArgumentError('Invalid entry');
    }
  }
  final String uid, name;
  final int progress, goal;
  bool get done => progress >= goal;

  Map<String, Object?> toJson() => {
    'name': name,
    'progress': progress,
    'goal': goal,
  };
  factory ChallengeEntry.fromJson(String uid, Map<String, dynamic> j) =>
      ChallengeEntry(
        uid: uid,
        name: j['name'] as String,
        progress: (j['progress'] as num).toInt(),
        goal: (j['goal'] as num).toInt(),
      );
}

// ---- Shared kitchen -------------------------------------------------------

/// Invite codes avoid look-alike letters (0/O, 1/I/L).
const inviteAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
final _invite = RegExp('^[$inviteAlphabet]{8}\$');

String normalizeInvite(String code) =>
    code.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

bool validInvite(String code) => _invite.hasMatch(code);

/// A kitchen several accounts share by invitation.
class SharedKitchen {
  SharedKitchen({
    required this.id,
    required this.owner,
    required List<String> members,
    required Map<String, String> names,
  }) : members = List.unmodifiable(members),
       names = Map.unmodifiable(names);
  final String id, owner;
  final List<String> members;
  final Map<String, String> names;

  String nameOf(String uid) => names[uid] ?? 'فرد من البيت';
}

// ---- Stories ----------------------------------------------------------------

/// How long a story stays up.
const storyLife = Duration(hours: 24);

/// A short text story from a household (no video). Photos join later
/// through the same [PhotoRef] slot as shared recipes.
class Story {
  Story({
    required this.id,
    required this.uid,
    required String name,
    required String text,
    String? dish,
    required this.createdAt,
    this.colorIndex = 0,
    List<PhotoRef> photos = const [],
  }) : name = _text(name, 60, 'name'),
       text = _text(text, 200, 'story'),
       dish = dish == null || dish.trim().isEmpty
           ? null
           : _text(dish, 80, 'dish'),
       photos = List.unmodifiable(photos) {
    if (id.isEmpty || uid.isEmpty || colorIndex < 0 || colorIndex > 7) {
      throw ArgumentError('Invalid story');
    }
  }
  final String id, uid, name, text;
  final String? dish;
  final DateTime createdAt;
  final int colorIndex;
  final List<PhotoRef> photos;

  DateTime get expiresAt => createdAt.add(storyLife);
  bool liveAt(DateTime now) => now.isBefore(expiresAt);

  Map<String, Object?> toJson() => {
    'uid': uid,
    'name': name,
    'text': text,
    'dish': ?dish,
    'color': colorIndex,
    'photos': [for (final p in photos) p.toJson()],
  };

  factory Story.fromJson(
    String id,
    Map<String, dynamic> j,
    DateTime createdAt,
  ) => Story(
    id: id,
    uid: j['uid'] as String,
    name: j['name'] as String,
    text: j['text'] as String,
    dish: j['dish'] as String?,
    colorIndex: (j['color'] as num?)?.toInt() ?? 0,
    photos: _photos(j['photos']),
    createdAt: createdAt,
  );
}

/// Live stories grouped by household, newest household first, each
/// household's stories oldest first (the order they are watched in).
List<List<Story>> storyRings(List<Story> stories, DateTime now) {
  final by = <String, List<Story>>{};
  for (final s in stories.where((s) => s.liveAt(now))) {
    (by[s.uid] ??= []).add(s);
  }
  final rings = [
    for (final list in by.values)
      list..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
  ]..sort((a, b) => b.last.createdAt.compareTo(a.last.createdAt));
  return rings;
}

/// A cooking channel suggested in the community (verified official channel).
class Creator {
  const Creator(this.id, this.name, this.short, this.channelUrl, this.country);
  final String id, name, short, channelUrl;
  final String? country;

  factory Creator.fromJson(Map<String, dynamic> j) {
    final url = j['channelUrl'] as String;
    if (!url.startsWith('https://www.youtube.com/')) {
      throw FormatException('Not a YouTube channel: $url');
    }
    return Creator(
      j['id'] as String,
      j['name'] as String,
      j['short'] as String,
      url,
      j['country'] as String?,
    );
  }
}
