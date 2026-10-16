import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:tabkha_demo/domain/person_nutrition.dart';

void main() {
  MealBatch batch({
    String id = 'batch',
    double? grams = 1000,
    bool complete = true,
    Map<String, AllergenPresence> allergens = const {},
  }) => MealBatch(
    id: id,
    recipeId: 'bechamel',
    sourceSnapshotId: 'recipe-v1',
    cookedGrams: grams,
    allergens: allergens,
    nutrients: {
      'protein': PersonNutrientValue(
        knownSubtotal: 100,
        complete: complete,
        unit: 'g',
      ),
    },
  );
  NutritionEvent event(
    String id, {
    String batchId = 'batch',
    NutritionEventKind kind = NutritionEventKind.consumed,
    String? person = 'member-1',
    double fraction = .25,
    String? corrects,
    bool cancelled = false,
  }) => NutritionEvent(
    id: id,
    batchId: batchId,
    kind: kind,
    personId: person,
    portion: PortionAmount(fraction, PortionUnit.batchFraction),
    day: '2026-10-12',
    actorId: 'user-1',
    recordedAt: DateTime.utc(2026, 10, 12),
    corrects: corrects,
    cancelled: cancelled,
  );
  NutrientTarget target({String? reviewOn}) => NutrientTarget(
    nutrientId: 'protein',
    unit: 'g',
    minimum: 20,
    maximum: 40,
    authority: TargetAuthority.user,
    source: 'Entered by user',
    recordedOn: '2026-10-12',
    validFrom: '2026-10-12',
    reviewOn: reviewOn,
  );

  test(
    'person IDs and explicit dates survive versioned immutable roundtrip',
    () {
      final profile = NutritionPersonProfile(
        memberId: 'member-1',
        birthDate: '2015-02-28',
        declaredAgeYears: 11,
        ageRecordedOn: '2026-10-12',
        healthNote: 'Free text is not a medical rule',
        targets: [target()],
        allergies: [
          AllergyRule(
            allergenId: 'milk',
            source: 'user',
            recordedOn: '2026-10-12',
          ),
        ],
        favoriteRecipeIds: {'bechamel'},
      );
      final restored = NutritionPersonProfile.fromJson(
        jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>,
      );
      expect(restored.toJson(), profile.toJson());
      expect(() => profile.targets.add(target()), throwsUnsupportedError);
      expect(() => profile.favoriteRecipeIds.add('x'), throwsUnsupportedError);
      expect(
        () => NutritionPersonProfile(memberId: 'a', declaredAgeYears: 10),
        throwsArgumentError,
      );
      expect(
        () => NutritionPersonProfile(memberId: 'a', birthDate: '2026-02-31'),
        throwsFormatException,
      );
      expect(
        () => NutritionPersonProfile(
          memberId: 'a',
          targets: [target(), target()],
        ),
        throwsArgumentError,
      );
      expect(
        () => NutritionPersonProfile.fromJson({
          ...profile.toJson(),
          'version': 2,
        }),
        throwsFormatException,
      );
    },
  );

  test('planning and actual intake remain separate; retries and reopen do not duplicate', () {
    var ledger = NutritionLedger.empty().addBatch(batch());
    ledger = ledger.append(
      event('plan', kind: NutritionEventKind.planned, fraction: .5),
    );
    final intake = event('actual');
    ledger = ledger.append(intake);
    expect(identical(ledger.append(intake), ledger), isTrue);
    final restored = NutritionLedger.fromJson(
      jsonDecode(jsonEncode(ledger.toJson())) as Map<String, dynamic>,
    );
    expect(restored.append(intake).events.length, 2);
    expect(
      restored
          .report(
            personId: 'member-1',
            day: '2026-10-12',
            kind: NutritionEventKind.consumed,
          )
          .nutrients['protein']!
          .value,
      25,
    );
    expect(
      restored
          .report(
            personId: 'member-1',
            day: '2026-10-12',
            kind: NutritionEventKind.planned,
          )
          .nutrients['protein']!
          .value,
      50,
    );
    expect(
      () => ledger.append(event('actual', fraction: .5)),
      throwsStateError,
    );
    expect(() => ledger.addBatch(batch(grams: 800)), throwsStateError);
    expect(() => ledger.events.clear(), throwsUnsupportedError);
  });

  test('measured grams require known cooked mass; fractions are explicit without mass', () {
    final unknown = batch(grams: null);
    expect(
      PortionAmount(.3, PortionUnit.batchFraction).fractionOf(unknown),
      .3,
    );
    expect(
      () => PortionAmount(300, PortionUnit.grams).fractionOf(unknown),
      throwsStateError,
    );
    expect(PortionAmount(300, PortionUnit.grams).fractionOf(batch()), .3);
    expect(
      () => PortionAmount(1.1, PortionUnit.batchFraction),
      throwsArgumentError,
    );
    expect(
      () => PortionAmount(double.nan, PortionUnit.grams),
      throwsArgumentError,
    );
  });

  test(
    'conservation includes leftovers and waste but not planned allocations',
    () {
      var ledger = NutritionLedger.empty().addBatch(batch());
      ledger = ledger.append(
        event('p', kind: NutritionEventKind.planned, fraction: 1),
      );
      ledger = ledger.append(event('a', fraction: .5));
      ledger = ledger.append(
        event(
          'left',
          kind: NutritionEventKind.leftover,
          person: null,
          fraction: .4,
        ),
      );
      ledger = ledger.append(
        event(
          'waste',
          kind: NutritionEventKind.waste,
          person: null,
          fraction: .1,
        ),
      );
      expect(ledger.balance('batch').unaccounted, closeTo(0, 1e-9));
      expect(
        () => ledger.append(event('extra', fraction: .01)),
        throwsStateError,
      );
      expect(
        () => ledger.append(
          event('extra-plan', kind: NutritionEventKind.planned, fraction: .01),
        ),
        throwsStateError,
      );
      expect(ledger.events.length, 4);
      ledger = ledger.append(
        event(
          'left-reduced',
          kind: NutritionEventKind.leftover,
          person: null,
          fraction: .2,
          corrects: 'left',
        ),
      );
      ledger = ledger.append(event('later-intake', fraction: .2));
      expect(ledger.balance('batch').consumed, .7);
    },
  );

  test('corrections preserve originals and change active totals once', () {
    var ledger = NutritionLedger.empty()
        .addBatch(batch())
        .append(event('old', fraction: .5));
    ledger = ledger.append(event('fixed', fraction: .2, corrects: 'old'));
    expect(ledger.events.length, 2);
    expect(ledger.activeEvents.single.id, 'fixed');
    expect(ledger.balance('batch').consumed, .2);
    expect(
      () => ledger.append(event('forked', corrects: 'old')),
      throwsStateError,
    );
    expect(
      () => ledger.append(
        event('wrong-person', person: 'member-2', corrects: 'fixed'),
      ),
      throwsStateError,
    );
    ledger = ledger.append(event('void', corrects: 'fixed', cancelled: true));
    expect(ledger.events.length, 3);
    expect(ledger.activeEvents, isEmpty);
    expect(ledger.balance('batch').consumed, 0);
    final restored = NutritionLedger.fromJson(ledger.toJson());
    expect(restored.toJson(), ledger.toJson());
  });

  test(
    'partial or missing nutrition never becomes a complete personal value',
    () {
      var ledger = NutritionLedger.empty().addBatch(batch(complete: false));
      ledger = ledger.append(event('a'));
      var report = ledger.report(
        personId: 'member-1',
        day: '2026-10-12',
        kind: NutritionEventKind.consumed,
      );
      expect(report.nutrients['protein']!.knownSubtotal, 25);
      expect(report.nutrients['protein']!.value, isNull);
      ledger = ledger.addBatch(
        MealBatch(
          id: 'unknown',
          recipeId: 'x',
          sourceSnapshotId: 'x-v1',
          nutrients: {},
        ),
      );
      ledger = ledger.append(event('b', batchId: 'unknown'));
      report = ledger.report(
        personId: 'member-1',
        day: '2026-10-12',
        kind: NutritionEventKind.consumed,
      );
      expect(report.nutrients['protein']!.complete, isFalse);
      expect(report.nutrients['protein']!.knownSubtotal, 25);
      final empty = ledger.report(
        personId: 'member-2',
        day: '2026-10-12',
        kind: NutritionEventKind.consumed,
        nutrientIds: {'protein'},
      );
      expect(empty.nutrients['protein'], isNull);
    },
  );

  test('allergy presence/crosscontact/unknown suppress celebration; no health inference', () {
    NutritionPersonProfile person({
      CrossContactPolicy policy = CrossContactPolicy.avoid,
    }) => NutritionPersonProfile(
      memberId: 'member-1',
      favoriteRecipeIds: {'bechamel'},
      healthNote: 'diabetes',
      allergies: [
        AllergyRule(
          allergenId: 'milk',
          crossContact: policy,
          source: 'user',
          recordedOn: '2026-10-12',
        ),
      ],
    );
    List<NutritionInteraction> interactions(
      AllergenPresence status, {
      CrossContactPolicy policy = CrossContactPolicy.avoid,
    }) => mealInteractions(
      person: person(policy: policy),
      batch: batch(allergens: {'milk': status}),
      triggerId: 'meal-1',
    );
    expect(
      interactions(AllergenPresence.present).single.kind,
      NutritionInteractionKind.allergyConflict,
    );
    expect(
      interactions(AllergenPresence.mayContain).single.kind,
      NutritionInteractionKind.allergyConflict,
    );
    expect(
      interactions(
        AllergenPresence.mayContain,
        policy: CrossContactPolicy.warn,
      ).single.kind,
      NutritionInteractionKind.allergyCrossContactWarning,
    );
    expect(
      interactions(AllergenPresence.unknown).single.kind,
      NutritionInteractionKind.allergyUnknown,
    );
    expect(
      interactions(AllergenPresence.absent).single.kind,
      NutritionInteractionKind.favoriteCelebration,
    );
    expect(
      interactions(AllergenPresence.absent).single.id,
      interactions(AllergenPresence.absent).single.id,
    );
    expect(
      mealInteractions(
        person: NutritionPersonProfile(
          memberId: 'member-1',
          healthNote: 'diabetes',
        ),
        batch: batch(),
        triggerId: 'm',
      ),
      isEmpty,
    );
  });

  test('target gaps require a complete period and nutrients, units, and reviewed target', () {
    final person = NutritionPersonProfile(
      memberId: 'member-1',
      targets: [target()],
    );
    PersonNutritionReport report(
      double value, {
      bool complete = true,
      String unit = 'g',
      bool? estimated = false,
    }) => PersonNutritionReport(
      personId: 'member-1',
      day: '2026-10-12',
      kind: NutritionEventKind.consumed,
      eventCount: 1,
      nutrients: {
        'protein': PersonNutrientValue(
          knownSubtotal: value,
          complete: complete,
          unit: unit,
          estimated: estimated,
        ),
      },
    );
    NutritionInteractionKind status(
      PersonNutritionReport r, {
      bool periodComplete = true,
      NutritionPersonProfile? profile,
    }) => targetInteractions(
      person: profile ?? person,
      report: r,
      periodComplete: periodComplete,
      triggerId: 'daily',
    ).single.kind;
    expect(status(report(25)), NutritionInteractionKind.targetWithin);
    expect(status(report(10)), NutritionInteractionKind.targetBelow);
    expect(status(report(50)), NutritionInteractionKind.targetAbove);
    expect(
      status(report(25, estimated: true)),
      NutritionInteractionKind.targetEstimated,
    );
    expect(
      status(report(25, estimated: null)),
      NutritionInteractionKind.targetUnknown,
    );
    expect(
      status(report(10), periodComplete: false),
      NutritionInteractionKind.targetUnknown,
    );
    expect(
      status(report(10, complete: false)),
      NutritionInteractionKind.targetUnknown,
    );
    expect(
      status(report(10, unit: 'mg')),
      NutritionInteractionKind.targetUnknown,
    );
    expect(
      status(
        report(10),
        profile: NutritionPersonProfile(
          memberId: 'member-1',
          targets: [target(reviewOn: '2026-10-12')],
        ),
      ),
      NutritionInteractionKind.targetNeedsReview,
    );
  });

  test('ledger confidence cannot certify a daily target', () {
    final person = NutritionPersonProfile(
      memberId: 'member-1',
      targets: [target()],
    );
    for (final (confidence, expected) in [
      (true, NutritionInteractionKind.targetEstimated),
      (null, NutritionInteractionKind.targetUnknown),
    ]) {
      final ledger = NutritionLedger.empty()
          .addBatch(
            MealBatch(
              id: 'batch',
              recipeId: 'bechamel',
              sourceSnapshotId: 'recipe-v1',
              nutrients: {
                'protein': PersonNutrientValue(
                  knownSubtotal: 100,
                  complete: true,
                  unit: 'g',
                  estimated: confidence,
                ),
              },
            ),
          )
          .append(event('actual'));
      final report = ledger.report(
        personId: 'member-1',
        day: '2026-10-12',
        kind: NutritionEventKind.consumed,
      );
      expect(report.nutrients['protein']!.estimated, confidence);
      expect(
        targetInteractions(
          person: person,
          report: report,
          periodComplete: true,
          triggerId: 'daily',
        ).single.kind,
        expected,
      );
    }
  });
}
