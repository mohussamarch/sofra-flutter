import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import 'online_recipe_library.dart';

abstract class StateStore {
  Future<Map<String, dynamic>?> load();
  Future<void> save(Map<String, dynamic> data);
  String get label;
}

class LocalStateStore implements StateStore {
  LocalStateStore({
    SharedPreferencesAsync? preferences,
    this.key = 'sofra.state.v1',
  }) : preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync preferences;
  final String key;
  @override
  String get label => L10n.current.appSavedOnDevice;

  @override
  Future<Map<String, dynamic>?> load() async {
    final text = await preferences.getString(key);
    return text == null ? null : jsonDecode(text) as Map<String, dynamic>;
  }

  @override
  Future<void> save(Map<String, dynamic> data) =>
      preferences.setString(key, jsonEncode(data));
}

class StateConflict implements Exception {}

class CloudStateStore implements StateStore, HasSavedRecipeArchive {
  CloudStateStore(FirebaseFirestore firestore, String uid)
    : document = firestore.doc('users/$uid/state/current'),
      _shared = false;

  /// A kitchen shared by invitation; every member reads and writes it.
  CloudStateStore.shared(FirebaseFirestore firestore, String kitchenId)
    : document = firestore.doc('kitchens/$kitchenId/state/current'),
      _shared = true;

  final DocumentReference<Map<String, dynamic>> document;
  int? _revision;

  final bool _shared;

  @override
  late final SavedRecipeArchive savedRecipes = FirestoreSavedRecipes(
    document.parent.parent!.collection('savedRecipes'),
  );

  @override
  String get label => _shared
      ? L10n.current.appSavedInSharedKitchen
      : L10n.current.appSavedInAccount;

  @override
  Future<Map<String, dynamic>?> load() async {
    // A server read prevents an old cache overwriting a newer device's state.
    final snapshot = await document.get(
      const GetOptions(source: Source.server),
    );
    final record = snapshot.data();
    _revision = (record?['revision'] as num?)?.toInt() ?? 0;
    return record == null
        ? null
        : Map<String, dynamic>.from(record['data'] as Map);
  }

  @override
  Future<void> save(Map<String, dynamic> data) async {
    if (_revision == null) throw StateError('Load before saving');
    final expected = _revision!;
    await document.firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      final actual = (snapshot.data()?['revision'] as num?)?.toInt() ?? 0;
      if (actual != expected) throw StateConflict();
      transaction.set(document, {
        'revision': expected + 1,
        'data': data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    _revision = expected + 1;
  }
}

/// Serializes writes so slower older saves cannot replace newer edits.
class StateWriter {
  StateWriter(this.store);
  final StateStore store;
  Future<void> _tail = Future<void>.value();

  Future<void> save(Map<String, dynamic> data) {
    final frozen = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    final result = _tail.then((_) => store.save(frozen));
    _tail = result.catchError((Object _) {});
    return result;
  }
}

/// Saved recipes kept in the account, one document each beside the state
/// document (users/{uid}/savedRecipes or kitchens/{id}/savedRecipes), so the
/// 850KB state document never carries recipe text.
class FirestoreSavedRecipes implements SavedRecipeArchive {
  FirestoreSavedRecipes(this.collection);
  final CollectionReference<Map<String, dynamic>> collection;

  @override
  Future<Map<String, SavedRecipeCopy>> list() async {
    final snapshot = await collection.get(
      const GetOptions(source: Source.server),
    );
    final result = <String, SavedRecipeCopy>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      try {
        result[doc.id] = SavedRecipeCopy(
          row: Map<String, dynamic>.from(jsonDecode(data['row'] as String) as Map),
          body: data['body'] as String,
          sha256: data['sha256'] as String,
        );
      } catch (_) {
        // A copy that does not read is skipped; the next save replaces it.
      }
    }
    return result;
  }

  @override
  Future<void> put(String id, SavedRecipeCopy copy) => collection.doc(id).set({
    'row': jsonEncode(copy.row),
    'body': copy.body,
    'sha256': copy.sha256,
    'savedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> remove(String id) => collection.doc(id).delete();
}
