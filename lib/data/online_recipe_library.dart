import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// The online recipe library (Firebase Hosting site "library", built by
/// tool/recipes/publish-library.mjs) as the app keeps it on the phone.
///
/// Always on the device: the published catalog index (listing, search,
/// filters and stock matching read only it) and the dish groups. Full recipe
/// bodies are kept one recipe at a time, only once opened, cooked, planned or
/// saved. They are capped at [maxBodyBytes]: past it the least recently used
/// opened recipes are evicted; saved (pinned) ones never are.
///
/// Nothing here blocks the screens on the network: the catalog is read from
/// the device (or, before the first download, the bundled seed), and updates
/// replace it only after every file matches its sha256. The swap is atomic:
/// new files are written under their hash, then the manifest that points at
/// them, then the old files are removed.
class OnlineRecipeLibrary extends ChangeNotifier {
  OnlineRecipeLibrary({
    required this.store,
    Uri? baseUrl,
    LibraryFetch? fetch,
    DateTime Function()? clock,
    this.checkEvery = const Duration(hours: 6),
    this.retryAfterFailure = const Duration(minutes: 30),
    int? maxBodyBytes,
  }) : maxBodyBytes = maxBodyBytes ?? defaultMaxBodyBytes,
       baseUrl = _folder(baseUrl ?? Uri.parse(defaultBaseUrl)),
       _fetch = fetch ?? httpLibraryFetch,
       _clock = clock ?? DateTime.now;

  /// Override with --dart-define=SOFRA_LIBRARY_URL=https://…/
  static const defaultBaseUrl = String.fromEnvironment(
    'SOFRA_LIBRARY_URL',
    defaultValue: 'https://sofra-library.web.app/',
  );
  static const schema = 1;

  /// Recipe bodies kept on the device, in UTF-8 bytes. The web keeps much
  /// less: its localStorage holds about 5 MB for the whole app.
  static const defaultMaxBodyBytes = kIsWeb ? 1536 * 1024 : 30 * 1024 * 1024;

  final LibraryStore store;
  final Uri baseUrl;
  final LibraryFetch _fetch;
  final DateTime Function() _clock;
  final Duration checkEvery;

  /// After a failed or rejected check, automatic checks wait this long (the
  /// button always checks), so a broken library is not downloaded again on
  /// every launch and tab.
  final Duration retryAfterFailure;
  final int maxBodyBytes;

  /// Throws when a downloaded index is not a catalog the app can use; set by
  /// the recipe repository so a bad index never replaces a good one.
  void Function(String indexText)? validateIndex;

  /// Bumps every time a new catalog is swapped in.
  int get generation => _generation;
  int _generation = 0;

  /// A check is running.
  bool get checking => _checking != null;
  Future<bool>? _checking;

  /// The last check could not reach the library or rejected what it got.
  bool get lastCheckFailed => _lastCheckFailed;
  bool _lastCheckFailed = false;

  static Uri _folder(Uri uri) =>
      uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');

  // ---- On-device state ----------------------------------------------------

  _State? _state;
  Future<_State>? _loading;
  final _texts = <String, String>{};
  Future<void> _tail = Future<void>.value();

  Future<_State> get _loaded async {
    if (_state != null) return _state!;
    return _loading ??= () async {
      Map<String, dynamic>? map(String? text) {
        if (text == null) return null;
        try {
          return Map<String, dynamic>.from(jsonDecode(text) as Map);
        } on Object {
          return null;
        }
      }

      final manifest = map(await store.read('manifest'));
      final bodies = map(await store.read('bodies')) ?? {};
      final pins = map(await store.read('pins')) ?? {};
      final checked = int.tryParse(await store.read('checkedAt') ?? '');
      final failed = int.tryParse(await store.read('failedAt') ?? '');
      return _state = _State(
        failedAt: failed == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(failed),
        rejected: await store.read('rejectedVersion'),
        manifest: manifest,
        bodies: {
          for (final e in bodies.entries)
            if (e.value is Map)
              e.key: _BodyMeta.fromJson(Map<String, dynamic>.from(e.value)),
        },
        pins: {
          for (final e in pins.entries)
            if (e.value is Map)
              e.key: _Pin.fromJson(Map<String, dynamic>.from(e.value)),
        },
        checkedAt: checked == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(checked),
      );
    }();
  }

  /// Runs [change] after every earlier change, so writes never interleave.
  Future<T> _locked<T>(Future<T> Function(_State s) change) {
    final result = _tail.then((_) async => change(await _loaded));
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<void> _saveMeta(_State s) async {
    await store.write(
      'bodies',
      jsonEncode({for (final e in s.bodies.entries) e.key: e.value.toJson()}),
    );
    await store.write(
      'pins',
      jsonEncode({for (final e in s.pins.entries) e.key: e.value.toJson()}),
    );
  }

  static String hashOf(String text) =>
      sha256.convert(utf8.encode(text)).toString();

  /// The stored text under [key] when it still hashes to [sha].
  Future<String?> _verified(String key, String sha) async {
    final memo = _texts[key];
    if (memo != null) return memo;
    final text = await store.read(key);
    if (text == null || hashOf(text) != sha) return null;
    return _texts[key] = text;
  }

  static String? _fileSha(Map<String, dynamic>? manifest, String name) {
    final files = manifest?['files'];
    if (files is! Map) return null;
    final entry = files[name];
    final sha = entry is Map ? entry['sha256'] : null;
    return sha is String && _sha.hasMatch(sha) ? sha : null;
  }

  static final _sha = RegExp(r'^[0-9a-f]{64}$');

  /// The downloaded catalog index, or null before the first download (the
  /// repository then reads the bundled seed).
  Future<String?> catalogIndex() async {
    final s = await _loaded;
    final sha = _fileSha(s.manifest, 'index.json');
    return sha == null ? null : _verified('index.$sha', sha);
  }

  /// The downloaded dish groups, or null.
  Future<String?> catalogDishes() async {
    final s = await _loaded;
    final sha = _fileSha(s.manifest, 'dishes.json');
    return sha == null ? null : _verified('dishes.$sha', sha);
  }

  /// When the library on the device was published; null before the first
  /// download.
  Future<DateTime?> publishedAt() async =>
      DateTime.tryParse('${(await _loaded).manifest?['generatedAt'] ?? ''}');

  /// When the library was last checked.
  Future<DateTime?> checkedAt() async => (await _loaded).checkedAt;

  // ---- Recipe bodies ------------------------------------------------------

  /// The full recipe whose body hashes to [sha]: from memory or the device,
  /// else downloaded (and kept as opened). Offline, an older copy of the same
  /// recipe kept on the device is returned instead. Throws
  /// [RecipeNotOnDevice] when there is neither.
  Future<String> body(String id, String sha) async {
    if (!_sha.hasMatch(sha)) throw RecipeNotOnDevice(id);
    final kept = await _verified('body.$sha', sha);
    if (kept != null) {
      unawaited(_locked((s) => _touch(s, id, sha, kept)));
      return kept;
    }
    try {
      final response = await _fetch(baseUrl.resolve('r/$sha.json'));
      if (response.status == 200) {
        final text = utf8.decode(response.bytes);
        if (hashOf(text) == sha) {
          _texts['body.$sha'] = text;
          try {
            await _locked((s) => _keep(s, id, sha, text));
          } on Object {
            // The device is full: the recipe still opens, from memory.
          }
          return text;
        }
      } else if (response.status == 404) {
        // The library moved on since this catalog was downloaded: the
        // repository updates the catalog and asks again with the new hash.
        throw RecipeMoved(id);
      }
    } on RecipeMoved {
      rethrow;
    } on Object {
      // Offline or unreachable: fall back to what the device has.
    }
    final s = await _loaded;
    for (final other in [s.pins[id]?.sha, s.bodies[id]?.sha]) {
      if (other == null || other == sha) continue;
      final text = await _verified('body.$other', other);
      if (text != null) return text;
    }
    throw RecipeNotOnDevice(id);
  }

  Future<void> _touch(_State s, String id, String sha, String text) async {
    final meta = s.bodies[id];
    if (meta != null && meta.sha == sha) {
      s.bodies[id] = meta.copyWith(at: _clock());
      await _saveMeta(s);
    } else {
      await _keep(s, id, sha, text);
    }
  }

  Future<void> _keep(_State s, String id, String sha, String text) async {
    final size = utf8.encode(text).length;
    // Room first, so the new body fits under the cap.
    await _evict(s, keep: id, adding: size);
    await _write(s, 'body.$sha', text, keep: id);
    _texts['body.$sha'] = text;
    final old = s.bodies[id];
    s.bodies[id] = _BodyMeta(sha: sha, size: size, at: _clock());
    if (old != null && old.sha != sha) await _dropBody(s, old.sha);
    await _saveMeta(s);
  }

  /// Writes [key]; when the device store is full (web localStorage), evicts
  /// every opened recipe except [keep] and tries once more.
  Future<void> _write(
    _State s,
    String key,
    String value, {
    String? keep,
  }) async {
    try {
      await store.write(key, value);
    } on Object {
      await _evict(s, keep: keep, everything: true);
      await _saveMeta(s);
      await store.write(key, value);
    }
  }

  /// Removes a body file no entry uses any more.
  Future<void> _dropBody(_State s, String sha) async {
    if (s.bodies.values.any((b) => b.sha == sha) ||
        s.pins.values.any((p) => p.sha == sha)) {
      return;
    }
    _texts.remove('body.$sha');
    await store.remove('body.$sha');
  }

  /// Marks a kept recipe as just used, for least recently used eviction.
  void touch(String id) => unawaited(
    _locked((s) async {
      final meta = s.bodies[id];
      if (meta == null) return;
      s.bodies[id] = meta.copyWith(at: _clock());
      await _saveMeta(s);
    }).catchError((Object _) {}),
  );

  /// Bytes of the distinct recipe bodies kept (opened and saved).
  int _bodyBytes(_State s) {
    final sizes = <String, int>{for (final b in s.bodies.values) b.sha: b.size};
    return sizes.values.fold(0, (a, b) => a + b);
  }

  /// Evicts the least recently used opened (unsaved) recipes until the
  /// bodies, plus [adding] more bytes, fit in [maxBodyBytes]; with
  /// [everything], all of them. Saved recipes and [keep] always stay.
  Future<void> _evict(
    _State s, {
    String? keep,
    int adding = 0,
    bool everything = false,
  }) async {
    final opened =
        s.bodies.entries
            .where((e) => !s.pins.containsKey(e.key) && e.key != keep)
            .toList()
          ..sort((a, b) => a.value.at.compareTo(b.value.at));
    for (final e in opened) {
      if (!everything && _bodyBytes(s) + adding <= maxBodyBytes) break;
      s.bodies.remove(e.key);
      await _dropBody(s, e.value.sha);
    }
  }

  // ---- Saved recipes (pinned) ---------------------------------------------

  /// Recipes saved on this device, pinned so they are never evicted.
  Future<Set<String>> pinnedIds() async => (await _loaded).pins.keys.toSet();

  /// The catalog rows of the pinned recipes, as they were when pinned (or
  /// last refreshed), so saved recipes still list after the library drops
  /// them.
  Future<Map<String, Map<String, dynamic>>> pinnedRows() async => {
    for (final e in (await _loaded).pins.entries) e.key: e.value.row,
  };

  /// The pinned copy of a saved recipe: row, body text and its sha256.
  Future<SavedRecipeCopy?> pinnedCopy(String id) async {
    final pin = (await _loaded).pins[id];
    if (pin == null) return null;
    final text = await _verified('body.${pin.sha}', pin.sha);
    return text == null
        ? null
        : SavedRecipeCopy(row: pin.row, body: text, sha256: pin.sha);
  }

  /// Pins a saved recipe's full text on the device.
  Future<void> pin(String id, Map<String, dynamic> row, String body) =>
      restorePinned(
        id,
        SavedRecipeCopy(row: row, body: body, sha256: hashOf(body)),
      );

  /// Pins a copy kept in the account, after checking its hash.
  Future<void> restorePinned(String id, SavedRecipeCopy copy) {
    if (hashOf(copy.body) != copy.sha256) {
      throw const LibraryIntegrityError('Saved recipe copy does not match');
    }
    return _locked((s) async {
      await _write(s, 'body.${copy.sha256}', copy.body, keep: id);
      _texts['body.${copy.sha256}'] = copy.body;
      final old = s.pins[id];
      s.pins[id] = _Pin(row: _rowOnly(copy.row), sha: copy.sha256);
      final meta = s.bodies[id];
      if (meta == null || meta.sha != copy.sha256) {
        s.bodies[id] = _BodyMeta(
          sha: copy.sha256,
          size: utf8.encode(copy.body).length,
          at: _clock(),
        );
        if (meta != null) await _dropBody(s, meta.sha);
      }
      if (old != null && old.sha != copy.sha256) await _dropBody(s, old.sha);
      await _saveMeta(s);
      notifyListeners();
    });
  }

  /// No longer saved: the body stays as an opened recipe until evicted.
  Future<void> unpin(String id) => _locked((s) async {
    if (s.pins.remove(id) == null) return;
    await _evict(s);
    await _saveMeta(s);
    notifyListeners();
  });

  /// Listing fields only; the ingredient list is not needed for a saved row.
  static Map<String, dynamic> _rowOnly(Map<String, dynamic> row) => {
    for (final e in row.entries)
      if (e.key != 'ingredients') e.key: e.value,
  };

  // ---- Updates --------------------------------------------------------------

  /// Checks the library at most every [checkEvery] (always with [force]) and
  /// swaps in a newer catalog. True when the catalog changed. Never throws;
  /// a failure leaves the device's library as it was.
  Future<bool> update({bool force = false, bool? retryRejected}) {
    final running = _checking;
    if (running != null) return running;
    final result = _update(force, retryRejected ?? force).whenComplete(() {
      _checking = null;
      notifyListeners();
    });
    _checking = result;
    notifyListeners();
    return result;
  }

  Future<bool> _update(bool force, bool retryRejected) async {
    final s = await _loaded;
    final now = _clock();
    // A clock set back (a time in the future) never stops the checks.
    bool recent(DateTime? at, Duration within) {
      if (at == null) return false;
      final age = now.difference(at);
      return !age.isNegative && age < within;
    }

    if (!force &&
        (recent(s.checkedAt, checkEvery) ||
            recent(s.failedAt, retryAfterFailure))) {
      return false;
    }
    String? version;
    try {
      final manifest = _parseManifest(
        await _download(baseUrl.resolve('manifest.json'), null),
      );
      version = manifest['version'] as String;
      var changed = false;
      if (version != s.manifest?['version'] || await catalogIndex() == null) {
        // A version already rejected is not downloaded again until the
        // library publishes another one (the button still tries).
        if (!retryRejected && version == s.rejected) {
          throw const LibraryRejected('Library version rejected');
        }
        await _swap(manifest);
        changed = true;
      }
      await _locked((s) async {
        s.checkedAt = _clock();
        s.failedAt = null;
        await store.write(
          'checkedAt',
          '${s.checkedAt!.millisecondsSinceEpoch}',
        );
        await store.remove('failedAt');
        if (s.rejected != null) {
          s.rejected = null;
          await store.remove('rejectedVersion');
        }
      });
      _lastCheckFailed = false;
      if (changed) {
        _generation++;
        notifyListeners();
        await _refreshKept();
      }
      return changed;
    } on Object catch (e) {
      _lastCheckFailed = true;
      try {
        await _locked((s) async {
          s.failedAt = _clock();
          await store.write(
            'failedAt',
            '${s.failedAt!.millisecondsSinceEpoch}',
          );
          // Only an index the app cannot use; a bad download may retry.
          if (version != null && e is LibraryRejected) {
            s.rejected = version;
            await store.write('rejectedVersion', version);
          }
        });
      } on Object {
        // The device store is unwritable: the next check simply runs.
      }
      return false;
    }
  }

  static Map<String, dynamic> _parseManifest(String text) {
    final json = jsonDecode(text);
    if (json is! Map ||
        json['schema'] != schema ||
        json['version'] is! String ||
        !_sha.hasMatch(json['version'] as String) ||
        _fileSha(Map<String, dynamic>.from(json), 'index.json') == null) {
      throw const LibraryIntegrityError('Unsupported library manifest');
    }
    return Map<String, dynamic>.from(json);
  }

  /// Downloads [uri]; with [sha], only a body that hashes to it.
  Future<String> _download(Uri uri, String? sha, {int? size}) async {
    final response = await _fetch(uri);
    if (response.status != 200) {
      throw LibraryIntegrityError('HTTP ${response.status} for ${uri.path}');
    }
    if (size != null && response.bytes.length != size) {
      throw LibraryIntegrityError('Size mismatch for ${uri.path}');
    }
    final text = utf8.decode(response.bytes);
    if (sha != null && hashOf(text) != sha) {
      throw LibraryIntegrityError('sha256 mismatch for ${uri.path}');
    }
    return text;
  }

  Future<void> _swap(Map<String, dynamic> manifest) async {
    final files = Map<String, dynamic>.from(manifest['files'] as Map);
    final indexSha = _fileSha(manifest, 'index.json')!;
    final dishesSha = _fileSha(manifest, 'dishes.json');
    int? size(String name) => (files[name] as Map)['size'] is int
        ? (files[name] as Map)['size'] as int
        : null;
    final index = await _download(
      baseUrl.resolve('index.json?v=$indexSha'),
      indexSha,
      size: size('index.json'),
    );
    try {
      validateIndex?.call(index);
    } on Object catch (e) {
      throw LibraryRejected('Index rejected: $e');
    }
    String? dishes;
    if (dishesSha != null) {
      dishes = await _download(
        baseUrl.resolve('dishes.json?v=$dishesSha'),
        dishesSha,
        size: size('dishes.json'),
      );
      if (jsonDecode(dishes) is! Map) {
        throw const LibraryIntegrityError('Invalid dishes file');
      }
    }
    await _locked((s) async {
      final oldIndex = _fileSha(s.manifest, 'index.json');
      final oldDishes = _fileSha(s.manifest, 'dishes.json');
      // A full device store (web) first gives up opened recipes; if the
      // catalog still does not fit, this update fails and the old one stays.
      await _write(s, 'index.$indexSha', index);
      if (dishes != null) await _write(s, 'dishes.$dishesSha', dishes);
      // The pointer: until this write the old catalog stays in use.
      await store.write('manifest', jsonEncode(manifest));
      s.manifest = manifest;
      _texts['index.$indexSha'] = index;
      if (dishes != null) _texts['dishes.$dishesSha'] = dishes;
      if (oldIndex != null && oldIndex != indexSha) {
        _texts.remove('index.$oldIndex');
        await store.remove('index.$oldIndex');
      }
      if (oldDishes != null && oldDishes != dishesSha) {
        _texts.remove('dishes.$oldDishes');
        await store.remove('dishes.$oldDishes');
      }
    });
  }

  /// After a new catalog: kept recipes that changed are downloaded again
  /// (the old copy stays until the new one is verified) and saved rows are
  /// refreshed. A saved recipe the library dropped keeps its pinned copy.
  Future<void> _refreshKept() async {
    final text = await catalogIndex();
    if (text == null) return;
    final rows = <String, Map<String, dynamic>>{
      for (final r in (jsonDecode(text) as Map)['recipes'] as List)
        (r as Map)['id'] as String: Map<String, dynamic>.from(r),
    };
    final s = await _loaded;
    final kept = {...s.bodies.keys, ...s.pins.keys};
    for (final id in kept) {
      final row = rows[id];
      final sha = row?['body'];
      // Held rows (off the catalog) keep the copy the device has.
      if (row == null ||
          row['catalogStatus'] != 'active' ||
          sha is! String ||
          !_sha.hasMatch(sha)) {
        continue;
      }
      final current = s.pins[id]?.sha ?? s.bodies[id]?.sha;
      try {
        if (current != sha) {
          final body = await _download(baseUrl.resolve('r/$sha.json'), sha);
          if (s.pins.containsKey(id)) {
            await pin(id, row, body);
          } else {
            await _locked((s) => _keep(s, id, sha, body));
          }
        } else if (s.pins.containsKey(id)) {
          await _locked((s) async {
            s.pins[id] = _Pin(row: _rowOnly(row), sha: sha);
            await _saveMeta(s);
          });
        }
      } on Object {
        // Offline again: the older copy keeps working.
      }
    }
  }

  // ---- Settings -----------------------------------------------------------

  /// What the library keeps on this device.
  Future<LibraryUsage> usage() async {
    final s = await _loaded;
    var bytes = 0;
    int size(String? text) => text == null ? 0 : utf8.encode(text).length;
    bytes += size(await catalogIndex());
    bytes += size(await catalogDishes());
    if (s.manifest != null) bytes += size(jsonEncode(s.manifest));
    final shas = {for (final b in s.bodies.values) b.sha: b.size};
    for (final p in s.pins.values) {
      shas.putIfAbsent(p.sha, () => 0);
    }
    for (final e in shas.entries) {
      bytes += e.value > 0 ? e.value : size(await store.read('body.${e.key}'));
    }
    bytes += size(
      jsonEncode({for (final e in s.pins.entries) e.key: e.value.toJson()}),
    );
    return LibraryUsage(
      onDevice: {...s.bodies.keys, ...s.pins.keys}.length,
      saved: s.pins.length,
      bytes: bytes,
      publishedAt: DateTime.tryParse('${s.manifest?['generatedAt'] ?? ''}'),
      checkedAt: s.checkedAt,
    );
  }
}

class _State {
  _State({
    required this.manifest,
    required this.bodies,
    required this.pins,
    required this.checkedAt,
    required this.failedAt,
    required this.rejected,
  });
  Map<String, dynamic>? manifest;
  final Map<String, _BodyMeta> bodies;
  final Map<String, _Pin> pins;
  DateTime? checkedAt;
  DateTime? failedAt;

  /// A published version whose index the app could not use.
  String? rejected;
}

class _BodyMeta {
  const _BodyMeta({required this.sha, required this.size, required this.at});
  _BodyMeta.fromJson(Map<String, dynamic> json)
    : sha = json['sha'] as String,
      size = (json['size'] as num?)?.toInt() ?? 0,
      at = DateTime.fromMillisecondsSinceEpoch(
        (json['at'] as num?)?.toInt() ?? 0,
      );
  final String sha;
  final int size;
  final DateTime at;
  _BodyMeta copyWith({DateTime? at}) =>
      _BodyMeta(sha: sha, size: size, at: at ?? this.at);
  Map<String, dynamic> toJson() => {
    'sha': sha,
    'size': size,
    'at': at.millisecondsSinceEpoch,
  };
}

class _Pin {
  const _Pin({required this.row, required this.sha});
  _Pin.fromJson(Map<String, dynamic> json)
    : row = Map<String, dynamic>.from(json['row'] as Map),
      sha = json['sha'] as String;
  final Map<String, dynamic> row;
  final String sha;
  Map<String, dynamic> toJson() => {'row': row, 'sha': sha};
}

/// What the settings show about the library on this device.
class LibraryUsage {
  const LibraryUsage({
    required this.onDevice,
    required this.saved,
    required this.bytes,
    required this.publishedAt,
    required this.checkedAt,
  });

  /// Full recipes kept on the device (opened or saved).
  final int onDevice;
  final int saved;

  /// Everything the library stores, catalog included.
  final int bytes;

  /// When the library on the device was published; null for the bundled one.
  final DateTime? publishedAt;
  final DateTime? checkedAt;
}

/// A saved recipe's full copy, on the device and in the account.
class SavedRecipeCopy {
  const SavedRecipeCopy({
    required this.row,
    required this.body,
    required this.sha256,
  });
  final Map<String, dynamic> row;
  final String body;
  final String sha256;
}

/// Saved recipes kept in the account (one document each, outside the state
/// document), so they survive a phone change and a library that drops them.
abstract class SavedRecipeArchive {
  Future<Map<String, SavedRecipeCopy>> list();
  Future<void> put(String id, SavedRecipeCopy copy);
  Future<void> remove(String id);
}

/// A state store whose account also keeps saved recipes.
abstract class HasSavedRecipeArchive {
  SavedRecipeArchive get savedRecipes;
}

/// The full recipe is neither on the device nor reachable now.
class RecipeNotOnDevice implements Exception {
  const RecipeNotOnDevice(this.recipeId);
  final String recipeId;
  @override
  String toString() => 'RecipeNotOnDevice($recipeId)';
}

/// The library no longer has the recipe body the catalog on the device
/// points at (a newer library was published since).
class RecipeMoved extends RecipeNotOnDevice {
  const RecipeMoved(super.recipeId);
  @override
  String toString() => 'RecipeMoved($recipeId)';
}

class LibraryIntegrityError implements Exception {
  const LibraryIntegrityError(this.message);
  final String message;
  @override
  String toString() => 'LibraryIntegrityError($message)';
}

class LibraryResponse {
  const LibraryResponse(this.status, this.bytes);
  final int status;
  final List<int> bytes;
}

typedef LibraryFetch = Future<LibraryResponse> Function(Uri uri);

/// Real network reads (Android and web).
Future<LibraryResponse> httpLibraryFetch(Uri uri) async {
  final response = await http.get(uri).timeout(const Duration(seconds: 20));
  return LibraryResponse(response.statusCode, response.bodyBytes);
}

/// Where the library keeps its files: a string per key.
abstract class LibraryStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class MemoryLibraryStore implements LibraryStore {
  final data = <String, String>{};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> remove(String key) async => data.remove(key);
}

/// shared_preferences: app storage on Android, localStorage on the web
/// (which is why only the catalog and opened or saved recipes are kept).
class PreferencesLibraryStore implements LibraryStore {
  PreferencesLibraryStore({SharedPreferencesAsync? preferences})
    : preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync preferences;
  static const prefix = 'sofra.library.';
  @override
  Future<String?> read(String key) => preferences.getString('$prefix$key');
  @override
  Future<void> write(String key, String value) =>
      preferences.setString('$prefix$key', value);
  @override
  Future<void> remove(String key) => preferences.remove('$prefix$key');
}

/// A published library the app cannot use (its index fails the app's
/// catalog checks): remembered, so it is not downloaded again until the
/// library publishes another version.
class LibraryRejected extends LibraryIntegrityError {
  const LibraryRejected(super.message);
}
