import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/food_repository.dart';
import 'package:tabkha_demo/data/preparation_category_repository.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';

Future<String> read(String p) => File(p).readAsString();
Map<String, dynamic> clone(Map value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

Future<PreparationTransform> accept(
  PreparationCategoryRepository repo,
  FoodRecord food, {
  String code = '0381',
  String note = 'Actual pasta method reviewed: boil and drain',
  bool category = true,
  bool license = true,
}) => repo.accept(
  food,
  retentionCode: code,
  reviewNote: note,
  acceptedAt: DateTime.parse('2026-10-14T03:11:00+03:00'),
  acknowledgeCategoryEstimate: category,
  acknowledgeUnknownLicense: license,
);

void main() {
  late FoodRecord food;
  setUpAll(() async {
    food = await FoodRepository(read: read)
        .usdaFood('usda:168927', form: 'asSold', nameAr: 'مكرونة جافة');
  });
  test(
    'one selected method yields only three vitamins and frozen unknowns',
    () async {
      final repo = PreparationCategoryRepository(read: read);
      expect(await repo.methods(food), ['0381', '0382']);
      for (final entry in {
        '0381': [0.7, 0.65, 0.75],
        '0382': [0.6, 0.55, 0.75],
      }.entries) {
        final t = await accept(repo, food, code: entry.key);
        expect(t.estimated, true);
        expect(t.sourceForm, FoodForm.asSold);
        expect(t.targetForm, FoodForm.cooked);
        expect(t.massYield, null);
        expect(t.retention, {
          NutrientId.vitaminC: entry.value[0],
          NutrientId.thiamin: entry.value[1],
          NutrientId.riboflavin: entry.value[2],
        });
        final e = jsonDecode(t.evidence!) as Map;
        expect(e['food'], food.toJson());
        expect(e['acceptance']['acceptedAt'], '2026-10-14T00:11:00.000Z');
        expect(e['missingNutrients'], hasLength(46));
        expect(e['massYield'], null);
        expect(e['edibleFraction'], null);
        expect(e['exactFoodMatchVerified'], false);
        expect(e['supportsFinishedRecipe'], false);
        expect(e['sourceSpecificLegalApproval'], false);
        expect(e['sourceCandidates'], hasLength(3));
        expect(PreparationCategoryRepository.isCategoryEstimate(t), true);
        PreparationCategoryRepository.validateAccepted(
          food,
          PreparationTransform.fromJson(t.toJson()),
        );
      }
    },
  );
  test(
    'requires exact canonical as sold generic food and explicit acceptance',
    () async {
      final repo = PreparationCategoryRepository(read: read);
      for (final options in [
        {'id': 'usda:170000'},
        {'version': 'other'},
        {'form': 'raw'},
        {'form': 'cooked'},
        {'brand': 'Brand'},
        {'nameEn': 'Other pasta'},
        {'kind': 'packaged', 'brand': 'Brand', 'market': 'SA'},
      ]) {
        final j = clone(food.toJson())..addAll(options);
        final other = FoodRecord.fromJson(j);
        await expectLater(repo.methods(other), throwsArgumentError);
      }
      final j = clone(food.toJson());
      j['nutrition']['values'][0]['value'] = 999;
      await expectLater(
        repo.methods(FoodRecord.fromJson(j)),
        throwsArgumentError,
      );
      await expectLater(
        accept(repo, food, category: false),
        throwsArgumentError,
      );
      await expectLater(
        accept(repo, food, license: false),
        throwsArgumentError,
      );
      await expectLater(accept(repo, food, note: ' '), throwsArgumentError);
      await expectLater(accept(repo, food, code: '0432'), throwsArgumentError);
      await expectLater(
        accept(repo, food, code: '0381+0382'),
        throwsArgumentError,
      );
    },
  );
  test(
    'bank drift, approvals and source row drift fail closed then retry',
    () async {
      for (final mutation in <(String, void Function(Map))>[
        (
          'data/nutrition/preparation-category-review.json',
          (j) => j['approval']['runtimeTransformApproved'] = true,
        ),
        (
          'data/nutrition/preparation-category-review.json',
          (j) => j['methodOptions'][0]['factors'][0]['fraction'] = 0.5,
        ),
        (
          'data/nutrition/retention-candidates.json',
          (j) => j['source']['sha256'] = 'bad',
        ),
        (
          'data/nutrition/retention-candidates.json',
          (j) => j['entries'][0]['sourceLineSha256'] = 'bad',
        ),
        (
          'data/nutrition/retention-candidates.json',
          (j) => j['entries'][0]['factor'] = 0.5,
        ),
        (
          'data/nutrition/retention-candidates.json',
          (j) => j['entries'][0]['massYield'] = 2,
        ),
        (
          'data/nutrition/retention-candidates.json',
          (j) => j['entries'].add(j['entries'][0]),
        ),
        (
          'data/nutrition/retention-candidates.json',
          (j) => j['approvedTransformCount'] = 1,
        ),
      ]) {
        var corrupt = true;
        final repo = PreparationCategoryRepository(
          read: (p) async {
            final text = await read(p);
            if (corrupt && p == mutation.$1) {
              final j = clone(jsonDecode(text) as Map);
              mutation.$2(j);
              return jsonEncode(j);
            }
            return text;
          },
        );
        await expectLater(repo.methods(food), throwsFormatException);
        corrupt = false;
        expect(await repo.methods(food), ['0381', '0382']);
      }
    },
  );
  test(
    'full LF normalized shard hash is checked, CRLF alone remains supported',
    () async {
      final crlf = PreparationCategoryRepository(
        read: (p) async {
          final text = await read(p);
          return p == 'data/usda/shards/31.json'
              ? text.replaceAll('\r\n', '\n').replaceAll('\n', '\r\n')
              : text;
        },
      );
      expect(await crlf.methods(food), ['0381', '0382']);
      final corrupt = PreparationCategoryRepository(
        read: (p) async {
          final text = await read(p);
          return p == 'data/usda/shards/31.json' ? '$text ' : text;
        },
      );
      await expectLater(corrupt.methods(food), throwsFormatException);
    },
  );
  test('saved transform rejects altered method, factors, food, approval and unknowns', () async {
    final t = await accept(PreparationCategoryRepository(read: read), food);
    for (final mutation in <void Function(Map)>[
      (j) => j['estimated'] = false,
      (j) => j['sourceForm'] = 'raw',
      (j) => j['targetForm'] = 'prepared',
      (j) => j['massYield'] = 2,
      (j) => j['retention']['thiamin'] = 0.5,
      (j) => j['source']['license'] = 'CC0',
    ]) {
      final j = clone(t.toJson());
      mutation(j);
      expect(
        () => PreparationCategoryRepository.validateAccepted(
          food,
          PreparationTransform.fromJson(j),
        ),
        throwsFormatException,
      );
    }
    for (final mutation in <void Function(Map)>[
      (e) => e.remove('kind'),
      (e) => e['retentionCode'] = '0382',
      (e) => e['food']['nutrition']['values'][0]['value'] = 999,
      (e) => e['review']['approval']['exactFoodMatchVerified'] = true,
      (e) => e['sourceCandidates'][0]['factor'] = 0.5,
      (e) => e['sourceCandidates'][0]['sourceLineSha256'] = 'bad',
      (e) => e['massYield'] = 1,
      (e) => e['edibleFraction'] = 1,
      (e) => e['missingNutrients'] = [],
      (e) => e['acceptance']['acknowledgeUnknownLicense'] = false,
      (e) => e['acceptance']['acceptedAt'] = '2026-10-14T03:11:00+03:00',
      (e) => e['supportsFinishedRecipe'] = true,
      (e) => e['sourceSpecificLegalApproval'] = true,
    ]) {
      final j = clone(t.toJson()), e = clone(jsonDecode(t.evidence!) as Map);
      mutation(e);
      j['evidence'] = jsonEncode(e);
      final altered = PreparationTransform.fromJson(j);
      expect(PreparationCategoryRepository.isCategoryEstimate(altered), true);
      expect(
        () => PreparationCategoryRepository.validateAccepted(food, altered),
        throwsFormatException,
      );
    }
    final j = clone(t.toJson()), e = clone(jsonDecode(t.evidence!) as Map);
    e.addAll({
      'recipeId': 'recipe',
      'recipeRevisionKey': 'recipe@1',
      'line': 0,
    });
    j['evidence'] = jsonEncode(e);
    PreparationCategoryRepository.validateAccepted(
      food,
      PreparationTransform.fromJson(j),
    );
  });
  test(
    'localized name supported but jointly tampered frozen food is rejected',
    () async {
      final t = await accept(PreparationCategoryRepository(read: read), food);
      final f = clone(food.toJson());
      f['nutrition']['values'][0]['value'] = 999;
      final j = clone(t.toJson()), e = clone(jsonDecode(t.evidence!) as Map);
      e['food'] = f;
      j['evidence'] = jsonEncode(e);
      expect(
        () => PreparationCategoryRepository.validateAccepted(
          FoodRecord.fromJson(f),
          PreparationTransform.fromJson(j),
        ),
        throwsFormatException,
      );
    },
  );
}
