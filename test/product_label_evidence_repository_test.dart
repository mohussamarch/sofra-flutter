import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/product_label_evidence_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bytes = File(productLabelEvidenceAsset).readAsBytesSync();
  final bank = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  ProductLabelEvidenceRepository fixture(Map<String, dynamic> data) {
    final raw = Uint8List.fromList(utf8.encode(jsonEncode(data)));
    return ProductLabelEvidenceRepository(
      expectedSha256: sha256.convert(raw).toString(),
      read: (_) async => raw,
    );
  }

  Map<String, dynamic> copy() =>
      jsonDecode(jsonEncode(bank)) as Map<String, dynamic>;

  test('synchronous reader failure clears cached failed future', () async {
    var calls = 0;
    final repo = ProductLabelEvidenceRepository(
      read: (_) {
        if (++calls == 1) throw StateError('temporary sync');
        return Future.value(bytes);
      },
    );
    await expectLater(repo.all(), throwsStateError);
    expect(await repo.all(), hasLength(4));
    expect(calls, 2);
  });
  test(
    'unsupported fields and source context reject even with matching bytes',
    () async {
      for (final change in <void Function(Map<String, dynamic>)>[
        (b) => b['approved'] = true,
        (b) => b['products'].first['approved'] = true,
        (b) => b['products'].first['pageFacts']['foodRecordId'] = 'food:one',
        (b) => b['products'].first['declarations']['otherAllergens'] = 'absent',
        (b) =>
            b['products'].first['declarations']['contains'].first['approved'] =
                true,
        (b) => b['sources'].first['approved'] = true,
        (b) => b['sources'].first['evidence']['verified'] = true,
        (b) =>
            b['sources'].first['retrievalMethod'] = 'physical-label-reviewed',
        (b) =>
            b['sources'].first['contactCountryContext']['basis'] = 'sku-market',
      ]) {
        final b = copy();
        change(b);
        await expectLater(fixture(b).all(), throwsFormatException);
      }
    },
  );
  test(
    'bundled statements preserve contains, may contain and unknowns',
    () async {
      final repo = ProductLabelEvidenceRepository();
      final rows = await repo.all();
      expect(rows, hasLength(4));
      expect(rows.expand((r) => r.contains), hasLength(13));
      expect(rows.expand((r) => r.mayContain), hasLength(3));
      expect(
        await repo.byProposedAllergen('egg', includeMayContain: false),
        hasLength(1),
      );
      expect(await repo.byProposedAllergen('egg'), hasLength(4));
      expect(await repo.byProposedAllergen('wheat'), isEmpty);
      expect(await repo.search('brioche'), hasLength(1));
      for (final row in rows) {
        expect(row.source['sourceMarket'], isNull);
        expect(row.product['pageFacts']['nutrition'], isNull);
        expect(row.product['pageFacts']['gtin'], isNull);
        expect(row.product['pageFacts']['packQuantity'], isNull);
        expect(row.product['declarations']['freeFrom'], isEmpty);
        expect(
          row.contains.every((d) => d.mappingStatus == 'proposed'),
          isTrue,
        );
      }
    },
  );
  test('original bytes are pinned before strict decoding', () async {
    final drift = ProductLabelEvidenceRepository(
      read: (_) async => Uint8List.fromList([...bytes, 32]),
    );
    await expectLater(drift.all(), throwsFormatException);
    final bad = Uint8List.fromList([0xff]);
    final malformed = ProductLabelEvidenceRepository(
      expectedSha256: sha256.convert(bad).toString(),
      read: (_) async => bad,
    );
    await expectLater(malformed.all(), throwsFormatException);
  });
  test('cache owns evidence and failed reads can retry', () async {
    var calls = 0;
    final repo = ProductLabelEvidenceRepository(
      read: (_) async {
        calls++;
        if (calls == 1) throw StateError('temporary');
        return bytes;
      },
    );
    await expectLater(repo.all(), throwsStateError);
    final rows = await repo.all();
    rows.first.product['pageFacts']['brand'] = 'changed';
    rows.first.source['evidence']['excerpt'] = 'changed';
    rows.first.batchMetadata['approvals']['runtime'] = true;
    expect(() => rows.clear(), throwsUnsupportedError);
    expect(() => rows.first.contains.clear(), throwsUnsupportedError);
    expect((await repo.all()).first.brand, 'Domty');
    expect(
      (await repo.all()).first.source['evidence']['excerpt'],
      isNot('changed'),
    );
    expect(
      (await repo.all()).first.batchMetadata['approvals']['runtime'],
      false,
    );
    expect(calls, 2);
  });
  test(
    'rejects missing source, duplicate identities and wrong evidence',
    () async {
      for (final change in <void Function(Map<String, dynamic>)>[
        (b) => b['sources'].removeAt(0),
        (b) => b['products'].add(b['products'].first),
        (b) => b['sources'].add(b['sources'].first),
        (b) => b['products'].first['declarations']['evidenceId'] = 'wrong',
        (b) => b['sources'].first['access'] = 'unavailable',
        (b) => b['products'].first['declarations']['basis'] =
            'ingredient-inference',
      ]) {
        final b = copy();
        change(b);
        await expectLater(fixture(b).all(), throwsFormatException);
      }
    },
  );
  test(
    'rejects approval, local binding, market and free-from promotion',
    () async {
      for (final change in <void Function(Map<String, dynamic>)>[
        (b) => b['approvals']['runtime'] = true,
        (b) =>
            b['products'].first['runtimeFoodRecordApproval']['approved'] = true,
        (b) => b['products'].first['pendingLocalProductMatch']['foodRecordId'] =
            'food:one',
        (b) => b['products'].first['pageFacts']['sourceMarket'] = 'EG',
        (b) => b['products'].first['declarations']['freeFrom'].add('peanut'),
      ]) {
        final b = copy();
        change(b);
        await expectLater(fixture(b).all(), throwsFormatException);
      }
    },
  );
  test('proposals match the explicit status and source term', () async {
    for (final change in <void Function(Map<String, dynamic>)>[
      (b) =>
          b['products'].first['declarations']['contains'].first['canonicalId'] =
              'wheat',
      (b) =>
          b['products']
                  .first['declarations']['contains']
                  .first['mappingStatus'] =
              'approved',
      (b) => b['products'].first['declarations']['contains'].add(
        b['products'].first['declarations']['mayContain'].removeAt(0),
      ),
    ]) {
      final b = copy();
      change(b);
      await expectLater(fixture(b).all(), throwsFormatException);
    }
  });
}
