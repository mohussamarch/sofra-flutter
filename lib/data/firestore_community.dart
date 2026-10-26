import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/community.dart';
import 'community_backend.dart';

/// Firestore paths (free tier only; see firestore.rules):
/// - `users/{uid}/membership/current` {kitchenId}
/// - `kitchens/{id}` {owner, members, names, createdAt, joinedWith?}
/// - `kitchens/{id}/state/current` same shape as a personal state document
/// - `invites/{code}` {kitchenId, by, expiresAt}
/// - `communityRecipes/{id}` and `.../ratings/{uid}`
/// - `priceReports/{id}`
/// - `challenges/{week}/entries/{uid}`
class FirestoreCommunity implements CommunityBackend {
  FirestoreCommunity(this.db, this.uid);
  final FirebaseFirestore db;
  @override
  final String uid;

  DocumentReference<Map<String, dynamic>> get _membership =>
      db.doc('users/$uid/membership/current');

  static DateTime? _time(Object? v) => v is Timestamp ? v.toDate() : null;

  @override
  Future<String?> membership() async {
    try {
      return (await _membership.get()).data()?['kitchenId'] as String?;
    } on FirebaseException catch (e) {
      // Rules without shared kitchens (not yet deployed): personal kitchen.
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  @override
  Future<SharedKitchen> kitchen(String kitchenId) async {
    final d = (await db.doc('kitchens/$kitchenId').get()).data()!;
    return SharedKitchen(
      id: kitchenId,
      owner: d['owner'] as String,
      members: List<String>.from(d['members'] as List),
      names: Map<String, String>.from(d['names'] as Map),
    );
  }

  @override
  Future<String> createSharedKitchen(
    Map<String, dynamic> data,
    String name,
  ) async {
    final ref = db.collection('kitchens').doc();
    await ref.set({
      'owner': uid,
      'members': [uid],
      'names': {uid: name},
      'createdAt': FieldValue.serverTimestamp(),
    });
    await ref.collection('state').doc('current').set({
      'revision': 1,
      'data': data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _membership.set({'kitchenId': ref.id});
    return ref.id;
  }

  @override
  Future<String> createInvite(String kitchenId) async {
    final code = newInviteCode();
    await db.doc('invites/$code').set({
      'kitchenId': kitchenId,
      'by': uid,
      'expiresAt': Timestamp.fromDate(DateTime.now().add(inviteLife)),
    });
    return code;
  }

  @override
  Future<String> joinKitchen(String raw, String name) async {
    final code = normalizeInvite(raw);
    if (!validInvite(code)) throw const InviteProblem('الكود ده مش موجود.');
    final invite = (await db.doc('invites/$code').get()).data();
    if (invite == null) throw const InviteProblem('الكود ده مش موجود.');
    final expires = _time(invite['expiresAt']);
    if (expires == null || !expires.isAfter(DateTime.now())) {
      throw const InviteProblem('الكود ده خلص. اطلب كود جديد.');
    }
    final kitchenId = invite['kitchenId'] as String;
    await db.doc('kitchens/$kitchenId').update({
      'members': FieldValue.arrayUnion([uid]),
      'names.$uid': name,
      'joinedWith': code,
    });
    await _membership.set({'kitchenId': kitchenId});
    return kitchenId;
  }

  @override
  Future<void> leaveKitchen(String kitchenId) async {
    final k = await kitchen(kitchenId);
    if (k.owner != uid) {
      await db.doc('kitchens/$kitchenId').update({
        'members': FieldValue.arrayRemove([uid]),
        'names.$uid': FieldValue.delete(),
      });
    }
    await _membership.delete();
  }

  @override
  Future<void> shareRecipe(SharedRecipe recipe) => db
      .doc('communityRecipes/${recipe.id}')
      .set({...recipe.toJson(), 'createdAt': FieldValue.serverTimestamp()});

  @override
  Future<List<SharedRecipe>> recentRecipes({int limit = 30}) async {
    final q = await db
        .collection('communityRecipes')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return [
      for (final d in q.docs)
        SharedRecipe.fromJson(
          d.id,
          d.data(),
          createdAt: _time(d.data()['createdAt']),
        ),
    ];
  }

  @override
  Future<void> rate(String recipeId, Rating rating) => db
      .doc('communityRecipes/$recipeId/ratings/$uid')
      .set({...rating.toJson(), 'at': FieldValue.serverTimestamp()});

  @override
  Future<List<Rating>> ratings(String recipeId) async {
    final q = await db
        .collection('communityRecipes/$recipeId/ratings')
        .limit(200)
        .get();
    return [
      for (final d in q.docs)
        Rating.fromJson(d.id, d.data(), at: _time(d.data()['at'])),
    ];
  }

  @override
  Future<void> reportPrice(PriceReport report) => db
      .collection('priceReports')
      .add({...report.toJson(), 'createdAt': FieldValue.serverTimestamp()});

  @override
  Future<List<PriceReport>> areaReports(String country, String area) async {
    final q = await db
        .collection('priceReports')
        .where('country', isEqualTo: country)
        .where('area', isEqualTo: areaKey(area))
        .limit(500)
        .get();
    return [for (final d in q.docs) PriceReport.fromJson(d.data())];
  }

  @override
  Future<void> saveChallengeEntry(String week, ChallengeEntry entry) => db
      .doc('challenges/$week/entries/$uid')
      .set({...entry.toJson(), 'at': FieldValue.serverTimestamp()});

  @override
  Future<List<ChallengeEntry>> challengeEntries(String week) async {
    final q = await db
        .collection('challenges/$week/entries')
        .orderBy('progress', descending: true)
        .limit(50)
        .get();
    return [for (final d in q.docs) ChallengeEntry.fromJson(d.id, d.data())];
  }
}
