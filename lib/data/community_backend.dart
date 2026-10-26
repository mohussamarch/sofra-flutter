import 'dart:math';

import '../domain/community.dart';

class InviteProblem implements Exception {
  const InviteProblem(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Sharing a kitchen and the community, for one signed-in account.
/// [FirestoreCommunity] is the real one; [MemoryCommunity] serves tests.
abstract class CommunityBackend {
  String get uid;

  // Shared kitchen.
  Future<String?> membership();
  Future<SharedKitchen> kitchen(String kitchenId);

  /// Moves [data] (the current personal kitchen) into a new shared kitchen.
  Future<String> createSharedKitchen(Map<String, dynamic> data, String name);
  Future<String> createInvite(String kitchenId);
  Future<String> joinKitchen(String code, String name);

  /// Back to the personal kitchen (an owner keeps the shared one as is).
  Future<void> leaveKitchen(String kitchenId);

  // Community.
  Future<void> shareRecipe(SharedRecipe recipe);
  Future<List<SharedRecipe>> recentRecipes({int limit = 30});
  Future<void> rate(String recipeId, Rating rating);
  Future<List<Rating>> ratings(String recipeId);
  Future<void> reportPrice(PriceReport report);
  Future<List<PriceReport>> areaReports(String country, String area);
  Future<void> saveChallengeEntry(String week, ChallengeEntry entry);
  Future<List<ChallengeEntry>> challengeEntries(String week);

  /// Posts a story (its id and time are set here); returns it.
  Future<Story> postStory({
    required String name,
    required String text,
    String? dish,
    int colorIndex = 0,
  });

  /// Stories posted in the last day.
  Future<List<Story>> liveStories();
}

String newInviteCode([Random? random]) {
  final r = random ?? Random.secure();
  return String.fromCharCodes([
    for (var i = 0; i < 8; i++)
      inviteAlphabet.codeUnitAt(r.nextInt(inviteAlphabet.length)),
  ]);
}

/// Invites last a week.
const inviteLife = Duration(days: 7);

/// One process-wide pretend server; each instance is one account on it.
class MemoryServer {
  final kitchens = <String, Map<String, dynamic>>{};
  final kitchenState = <String, Map<String, dynamic>>{};
  final invites = <String, (String, DateTime)>{};
  final memberships = <String, String>{};
  final recipes = <String, SharedRecipe>{};
  final ratings = <String, Map<String, Rating>>{};
  final prices = <PriceReport>[];
  final entries = <String, Map<String, ChallengeEntry>>{};
  final stories = <Story>[];
  DateTime Function() clock = DateTime.now;
  var _seq = 0;
}

class MemoryCommunity implements CommunityBackend {
  MemoryCommunity(this.server, this.uid);
  final MemoryServer server;
  @override
  final String uid;

  @override
  Future<String?> membership() async => server.memberships[uid];

  @override
  Future<SharedKitchen> kitchen(String kitchenId) async {
    final k = server.kitchens[kitchenId]!;
    if (!(k['members'] as List).contains(uid)) throw StateError('Not member');
    return SharedKitchen(
      id: kitchenId,
      owner: k['owner'] as String,
      members: List<String>.from(k['members'] as List),
      names: Map<String, String>.from(k['names'] as Map),
    );
  }

  @override
  Future<String> createSharedKitchen(
    Map<String, dynamic> data,
    String name,
  ) async {
    final id = 'k${server._seq++}';
    server.kitchens[id] = {
      'owner': uid,
      'members': [uid],
      'names': {uid: name},
    };
    server.kitchenState[id] = data;
    server.memberships[uid] = id;
    return id;
  }

  @override
  Future<String> createInvite(String kitchenId) async {
    await kitchen(kitchenId);
    final code = newInviteCode();
    server.invites[code] = (kitchenId, server.clock().add(inviteLife));
    return code;
  }

  @override
  Future<String> joinKitchen(String raw, String name) async {
    final code = normalizeInvite(raw);
    final invite = server.invites[code];
    if (!validInvite(code) || invite == null) {
      throw const InviteProblem('الكود ده مش موجود.');
    }
    if (!invite.$2.isAfter(server.clock())) {
      throw const InviteProblem('الكود ده خلص. اطلب كود جديد.');
    }
    final k = server.kitchens[invite.$1]!;
    final members = k['members'] as List;
    if (!members.contains(uid)) members.add(uid);
    (k['names'] as Map)[uid] = name;
    server.memberships[uid] = invite.$1;
    return invite.$1;
  }

  @override
  Future<void> leaveKitchen(String kitchenId) async {
    final k = server.kitchens[kitchenId]!;
    if (k['owner'] != uid) {
      (k['members'] as List).remove(uid);
      (k['names'] as Map).remove(uid);
    }
    server.memberships.remove(uid);
  }

  @override
  Future<void> shareRecipe(SharedRecipe recipe) async {
    if (recipe.authorUid != uid) throw StateError('Not author');
    server.recipes[recipe.id] = recipe;
  }

  @override
  Future<List<SharedRecipe>> recentRecipes({int limit = 30}) async =>
      server.recipes.values.toList().reversed.take(limit).toList();

  @override
  Future<void> rate(String recipeId, Rating rating) async {
    if (rating.uid != uid) throw StateError('Not rater');
    (server.ratings[recipeId] ??= {})[uid] = rating;
  }

  @override
  Future<List<Rating>> ratings(String recipeId) async =>
      (server.ratings[recipeId] ?? const {}).values.toList();

  @override
  Future<void> reportPrice(PriceReport report) async {
    if (report.uid != uid) throw StateError('Not reporter');
    server.prices.add(report);
  }

  @override
  Future<List<PriceReport>> areaReports(String country, String area) async => [
    for (final r in server.prices)
      if (r.country == country && r.area == areaKey(area)) r,
  ];

  @override
  Future<void> saveChallengeEntry(String week, ChallengeEntry entry) async {
    if (entry.uid != uid) throw StateError('Not entrant');
    (server.entries[week] ??= {})[uid] = entry;
  }

  @override
  Future<List<ChallengeEntry>> challengeEntries(String week) async =>
      (server.entries[week] ?? const {}).values.toList();

  @override
  Future<Story> postStory({
    required String name,
    required String text,
    String? dish,
    int colorIndex = 0,
  }) async {
    final story = Story(
      id: 's${server._seq++}',
      uid: uid,
      name: name,
      text: text,
      dish: dish,
      colorIndex: colorIndex,
      createdAt: server.clock(),
    );
    server.stories.add(story);
    return story;
  }

  @override
  Future<List<Story>> liveStories() async => [
    for (final s in server.stories)
      if (s.liveAt(server.clock())) s,
  ];
}
