import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

const productLabelEvidenceAsset =
    'data/food/product-label-evidence/20261014/manufacturer-evidence.json';
const productLabelEvidenceSha256 =
    '1428c31beb18be0c8800b111f9f0ce0e79f84afe994961b8ca16cd90639b6f67';
typedef LabelEvidenceReader = Future<Uint8List> Function(String path);

Map<String, dynamic> _copy(Map<String, dynamic> v) =>
    jsonDecode(jsonEncode(v)) as Map<String, dynamic>;
void _need(bool condition, String message) {
  if (!condition) throw FormatException(message);
}

Map<String, dynamic> _map(Object? v) {
  _need(v is Map<String, dynamic>, 'Expected evidence object');
  return v as Map<String, dynamic>;
}

List<dynamic> _list(Object? v) {
  _need(v is List, 'Expected evidence list');
  return v as List;
}

String _text(Object? v) {
  _need(v is String && v.trim().isNotEmpty, 'Missing evidence text');
  return v as String;
}

void _keys(Map<String, dynamic> v, List<String> keys) {
  _need(
    v.length == keys.length && keys.every(v.containsKey),
    'Unsupported or missing evidence fields',
  );
}

void _exact(Map<String, dynamic> v, Map<String, dynamic> expected) {
  _need(
    v.length == expected.length &&
        expected.entries.every(
          (e) => v.containsKey(e.key) && v[e.key] == e.value,
        ),
    'Evidence promotion or unsupported schema',
  );
}

enum LabelDeclarationKind { contains, mayContain }

/// A published web statement with a proposed vocabulary mapping, not a FoodRecord.
class LabelDeclaration {
  const LabelDeclaration._(
    this.sourceTerm,
    this.proposedCanonicalId,
    this.evidenceId,
    this.kind,
  );
  final String sourceTerm, proposedCanonicalId, evidenceId;
  final LabelDeclarationKind kind;
  String get mappingStatus => 'proposed';
}

class ManufacturerLabelObservation {
  ManufacturerLabelObservation._(
    Map<String, dynamic> product,
    Map<String, dynamic> source,
    Map<String, dynamic> batch,
    List<LabelDeclaration> contains,
    List<LabelDeclaration> mayContain,
  ) : _product = _copy(product),
      _source = _copy(source),
      _batch = _copy(batch),
      contains = List.unmodifiable(contains),
      mayContain = List.unmodifiable(mayContain);
  final Map<String, dynamic> _product, _source, _batch;
  final List<LabelDeclaration> contains, mayContain;
  String get id => _product['researchId'] as String;
  String get brand => _product['pageFacts']['brand'] as String;
  String get exactProductName =>
      _product['pageFacts']['exactProductName'] as String;
  String get sourceUrl => _source['url'] as String;
  Map<String, dynamic> get product => _copy(_product);
  Map<String, dynamic> get source => _copy(_source);
  Map<String, dynamic> get batchMetadata => _copy(_batch);
}

/// Read-only, bounded research asset. Contact location never establishes SKU market.
class ProductLabelEvidenceRepository {
  ProductLabelEvidenceRepository({
    this.expectedSha256 = productLabelEvidenceSha256,
    LabelEvidenceReader? read,
  }) : _read = read ?? _asset;
  final String expectedSha256;
  final LabelEvidenceReader _read;
  Future<List<ManufacturerLabelObservation>>? _cached;
  static Future<Uint8List> _asset(String path) async {
    final data = await rootBundle.load(path);
    return Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  Future<List<ManufacturerLabelObservation>> all() =>
      _cached ??= _load().catchError((Object error, StackTrace stack) {
        _cached = null;
        Error.throwWithStackTrace(error, stack);
      });
  Future<List<ManufacturerLabelObservation>> search(String query) async {
    final q = query.trim().toLowerCase();
    return List.unmodifiable(
      (await all()).where(
        (v) => '${v.brand} ${v.exactProductName}'.toLowerCase().contains(q),
      ),
    );
  }

  Future<List<ManufacturerLabelObservation>> byProposedAllergen(
    String id, {
    bool includeMayContain = true,
  }) async => List.unmodifiable(
    (await all()).where(
      (v) => [
        ...v.contains,
        if (includeMayContain) ...v.mayContain,
      ].any((d) => d.proposedCanonicalId == id),
    ),
  );

  Future<List<ManufacturerLabelObservation>> _load() async {
    final bytes = Uint8List.fromList(await _read(productLabelEvidenceAsset));
    _need(
      RegExp(r'^[a-f0-9]{64}$').hasMatch(expectedSha256) &&
          sha256.convert(bytes).toString() == expectedSha256,
      'Product label evidence byte drift',
    );
    return _parse(_map(jsonDecode(utf8.decode(bytes, allowMalformed: false))));
  }
}

const _catalog = {
  'domty-bran': ['https://domty.org/product/bran-toast/', 'Bran Toast'],
  'domty-milk': ['https://domty.org/product/milk-toast/', 'Milk Toast'],
  'domty-brioche': [
    'https://domty.org/product/brioche-toast/',
    'Brioche Toast',
  ],
  'domty-high-protein': [
    'https://domty.org/product/high-protein-toast-with-chia-seeds/',
    'High Protein Toast with Chia Seeds',
  ],
  'juhayna-dairy': [
    'https://www.juhayna.com/brands-category/juhayna-dairy/',
    '',
  ],
  'almarai-failed': [
    'https://www.almarai.com/en/brands/almarai/fresh-dairy/fresh-milk/full-fat-fresh-milk',
    '',
  ],
};
const _proposals = {
  'Gluten': 'gluten',
  'Soy': 'soy',
  'Milk': 'milk',
  'Milk and Milk Products': 'milk',
  'Eggs': 'egg',
};

List<ManufacturerLabelObservation> _parse(Map<String, dynamic> bank) {
  _keys(bank, [
    'schemaVersion',
    'batchId',
    'scope',
    'capturedAt',
    'approvals',
    'sources',
    'products',
  ]);
  _need(
    bank['schemaVersion'] == 1 &&
        bank['batchId'] == 'product-label-evidence-20261014' &&
        bank['scope'] == 'research-only-manufacturer-web-declarations',
    'Unsupported research scope',
  );
  _exact(_map(bank['approvals']), {
    'runtime': false,
    'clinical': false,
    'currentLaw': false,
    'redistribution': false,
  });
  final captured = DateTime.tryParse(_text(bank['capturedAt']));
  _need(captured != null && captured.isUtc, 'Evidence date');
  final sources = <String, Map<String, dynamic>>{};
  for (final raw in _list(bank['sources'])) {
    final s = _map(raw), id = _text(s['id']), spec = _catalog[id];
    _keys(s, [
      'id',
      'url',
      'authority',
      'kind',
      'access',
      'retrievedAt',
      'publishedAt',
      'publicationScope',
      'retrievalMethod',
      'archived',
      'bodySha256',
      'rights',
      'sourceMarket',
      'contactCountryContext',
      'evidence',
      'accessNote',
    ]);
    _need(s['retrievalMethod'] == 'web-opened-page', 'Retrieval method');
    if (s['contactCountryContext'] != null) {
      final contact = _map(s['contactCountryContext']);
      _keys(contact, ['country', 'basis', 'locator']);
      _need(
        contact['country'] == 'EG' &&
            contact['basis'] == 'contact-address-only',
        'Contact country is not SKU market',
      );
      _text(contact['locator']);
    }
    _need(
      spec != null && !sources.containsKey(id) && s['url'] == spec[0],
      'Source identity',
    );
    final date = DateTime.tryParse(_text(s['retrievedAt']));
    _need(
      date != null && date.isUtc && !date.isAfter(captured!),
      'Source chronology',
    );
    _need(
      s['sourceMarket'] == null &&
          s['publishedAt'] == null &&
          s['archived'] == false &&
          s['bodySha256'] == null &&
          s['rights'] == 'unknown' &&
          s['publicationScope'] == 'unknown',
      'Unknown source facts',
    );
    if (spec![1].isNotEmpty) {
      _need(
        s['access'] == 'retrieved' &&
            s['kind'] == 'manufacturer-product-page' &&
            s['authority'] == 'Arabian Food Industries Company (Domty)',
        'Manufacturer identity/access',
      );
      final evidence = _map(s['evidence']);
      _keys(evidence, ['id', 'kind', 'locator', 'excerpt']);
      _need(s['accessNote'] == null, 'Product source access note');
      _need(
        evidence['id'] == '$id-allergens' &&
            evidence['kind'] == 'explicit-allergen-statement',
        'Explicit source evidence',
      );
      _text(evidence['locator']);
      _text(evidence['excerpt']);
    } else {
      _need(
        s['access'] == (id == 'almarai-failed' ? 'unavailable' : 'retrieved') &&
            s['kind'] ==
                (id == 'almarai-failed'
                    ? 'manufacturer-product-page'
                    : 'manufacturer-category-page') &&
            s['authority'] == (id == 'almarai-failed' ? 'Almarai' : 'Juhayna'),
        'Source access context',
      );
      _text(s['accessNote']);
      _need(s['evidence'] == null, 'Non-declaration source');
    }
    sources[id] = s;
  }
  final rows = <ManufacturerLabelObservation>[],
      ids = <String>{},
      usedSources = <String>{};
  final metadata = _copy(bank)
    ..remove('products')
    ..remove('sources');
  for (final raw in _list(bank['products'])) {
    final p = _map(raw),
        id = _text(p['researchId']),
        f = _map(p['pageFacts']),
        sid = _text(f['sourceId']);
    _keys(p, [
      'researchId',
      'pageFacts',
      'declarations',
      'pendingLocalProductMatch',
      'runtimeFoodRecordApproval',
      'unknowns',
    ]);
    _keys(f, [
      'brand',
      'exactProductName',
      'variant',
      'sourceId',
      'packQuantity',
      'labelVersion',
      'gtin',
      'form',
      'sourceMarket',
      'sourceMarketEvidence',
      'nutrition',
    ]);
    final s = sources[sid], spec = _catalog[sid];
    _need(
      ids.add(id) &&
          usedSources.add(sid) &&
          s != null &&
          spec != null &&
          spec[1].isNotEmpty,
      'Missing/duplicate product source',
    );
    _need(
      id == '$sid-web-observation' &&
          f['brand'] == 'Domty' &&
          f['exactProductName'] == spec![1] &&
          f['variant'] == spec[1],
      'Exact product identity',
    );
    for (final key in [
      'packQuantity',
      'labelVersion',
      'gtin',
      'form',
      'sourceMarket',
      'sourceMarketEvidence',
      'nutrition',
    ]) {
      _need(f.containsKey(key) && f[key] == null, 'Unknown product fact: $key');
    }
    _exact(_map(p['pendingLocalProductMatch']), {
      'status': 'pending',
      'foodRecordId': null,
      'foodRecordVersion': null,
      'gtin': null,
      'reviewed': false,
    });
    _exact(_map(p['runtimeFoodRecordApproval']), {
      'approved': false,
      'approvedAt': null,
      'approvedBy': null,
    });
    _need(_list(p['unknowns']).isNotEmpty, 'Missing limitations');
    for (final note in _list(p['unknowns'])) {
      _text(note);
    }
    final d = _map(p['declarations']), e = _map(s!['evidence']);
    _keys(d, [
      'basis',
      'sourceId',
      'evidenceId',
      'contains',
      'mayContain',
      'freeFrom',
      'unlistedStatus',
    ]);
    _need(
      d['basis'] == 'explicit-manufacturer-allergen-statement' &&
          d['sourceId'] == sid &&
          d['evidenceId'] == e['id'] &&
          d['unlistedStatus'] == 'unknown' &&
          _list(d['freeFrom']).isEmpty,
      'Declaration source/promotion',
    );
    final match = RegExp(
      r'^Contains ([^.]+)\.(?: The product may contain traces of ([^.]+)\.)?$',
    ).firstMatch(_text(e['excerpt']));
    _need(match != null, 'Explicit statement grammar');
    final seen = <String>{};
    List<LabelDeclaration> declarations(
      String key,
      LabelDeclarationKind kind,
      List<String> terms,
    ) {
      final values = _list(d[key]);
      _need(values.length == terms.length, 'Statement status mismatch');
      return List.generate(values.length, (i) {
        final value = _map(values[i]),
            term = _text(value['sourceTerm']),
            proposed = _text(value['canonicalId']);
        _keys(value, [
          'sourceTerm',
          'canonicalId',
          'mappingStatus',
          'evidenceId',
        ]);
        _need(
          term == terms[i] &&
              _proposals[term] == proposed &&
              seen.add(proposed) &&
              value['mappingStatus'] == 'proposed' &&
              value['evidenceId'] == e['id'],
          'Invalid declaration proposal',
        );
        return LabelDeclaration._(term, proposed, e['id'] as String, kind);
      });
    }

    final contains = declarations(
      'contains',
      LabelDeclarationKind.contains,
      match!.group(1)!.split(' - '),
    );
    final may = declarations(
      'mayContain',
      LabelDeclarationKind.mayContain,
      match.group(2) == null ? [] : [match.group(2)!],
    );
    rows.add(ManufacturerLabelObservation._(p, s, metadata, contains, may));
  }
  _need(rows.isNotEmpty, 'Empty product evidence');
  return List.unmodifiable(rows);
}
