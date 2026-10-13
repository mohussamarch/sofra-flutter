import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/food_repository.dart';
import 'package:tabkha_demo/data/retention_candidate_repository.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';

Future<String> read(String p) => File(p).readAsString();
void main() {
  test('source candidate groups preserve partial nutrients and explicit review remains unapplied', () async {
    final repo = RetentionCandidateRepository(read: read),
        food = await FoodRepository(read: read)
            .usdaFood('usda:168927', form: 'asSold');
    final proposal = await repo.proposeMatch(
      food,
      retentionCode: '0381',
      targetForm: FoodForm.cooked,
      reviewNote: 'Review requested for dry generic pasta boiled/drained; exact match not certified',
      acknowledgeNotApproved: true,
    );
    expect(proposal.canApply, false);
    final j = proposal.toJson();
    expect(j['status'], 'matching-review-requested');
    expect(j['food']['id'], food.id);
    expect(j['food']['version'], food.version);
    expect(j['sourceForm'], 'asSold');
    expect(j['targetForm'], 'cooked');
    expect(j['retention']['thiamin'], 0.65);
    expect(j['retention']['riboflavin'], 0.75);
    expect((j['missingNutrients'] as List).length, 46);
    expect(j['massYield'], null);
    expect(j['edibleFraction'], null);
    expect(j['licenseStatus'], 'unknown');
    (j['retention'] as Map).clear();
    expect(proposal.toJson()['retention'].length, 3);
    expect((await repo.codes()).length, 3);
  });
  test(
    'acknowledgement, review note, source state and code are mandatory',
    () async {
      final repo = RetentionCandidateRepository(read: read),
          foods = FoodRepository(read: read),
          food = await foods.usdaFood('usda:168927', form: 'asSold');
      await expectLater(
        repo.proposeMatch(
          food,
          retentionCode: '0381',
          targetForm: FoodForm.cooked,
          reviewNote: 'review',
          acknowledgeNotApproved: false,
        ),
        throwsArgumentError,
      );
      await expectLater(
        repo.proposeMatch(
          food,
          retentionCode: '0381',
          targetForm: FoodForm.cooked,
          reviewNote: ' ',
          acknowledgeNotApproved: true,
        ),
        throwsArgumentError,
      );
      await expectLater(
        repo.proposeMatch(
          food,
          retentionCode: 'absent',
          targetForm: FoodForm.cooked,
          reviewNote: 'review',
          acknowledgeNotApproved: true,
        ),
        throwsStateError,
      );
      final cooked = await foods.usdaFood('usda:168927', form: 'cooked');
      await expectLater(
        repo.proposeMatch(
          cooked,
          retentionCode: '0381',
          targetForm: FoodForm.cooked,
          reviewNote: 'review',
          acknowledgeNotApproved: true,
        ),
        throwsArgumentError,
      );
    },
  );
  test('invalid archive evidence, arithmetic, approval or duplicate candidate is rejected', () async {
    final original = jsonDecode(
      await read('data/nutrition/retention-candidates.json'),
    ) as Map;
    for (final mutate in <void Function(Map)>[
      (j) => j['source']['sha256'] = 'bad',
      (j) => j['entries'][0]['factorUnit'] = 'grams',
      (j) => j['entries'][0]['factor'] = 0.01,
      (j) => j['approvedTransformCount'] = 1,
      (j) => j['entries'][0]['foodIds'] = ['auto-match'],
      (j) => j['entries'].add(j['entries'][0]),
      (j) => j['entries'][0]['sourceLineSha256'] = 'bad',
    ]) {
      final j = jsonDecode(jsonEncode(original)) as Map;
      mutate(j);
      final repo = RetentionCandidateRepository(
        read: (_) async => jsonEncode(j),
      );
      await expectLater(repo.codes(), throwsFormatException);
    }
  });
  test('failed load retries and requests do not assert an automatic name/category match', () async {
    var calls = 0;
    final repo = RetentionCandidateRepository(
      read: (p) async {
        calls++;
        if (calls == 1) throw StateError('offline');
        return read(p);
      },
    );
    await expectLater(repo.codes(), throwsStateError);
    expect(await repo.codes(), ['0381', '0382', '0432']);
    final food = await FoodRepository(read: read)
        .usdaFood('usda:170000', form: 'raw');
    final request = await repo.proposeMatch(
      food,
      retentionCode: '0381',
      targetForm: FoodForm.cooked,
      reviewNote:
          'Deliberately mismatched onion request must remain unapproved',
      acknowledgeNotApproved: true,
    );
    expect(request.canApply, false);
    expect(request.toJson()['foodMatchVerified'], false);
  });
}
