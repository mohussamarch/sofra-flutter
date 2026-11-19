import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

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

class CloudStateStore implements StateStore {
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
