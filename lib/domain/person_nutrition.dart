import 'dart:convert';

import 'food_nutrition.dart' show canonicalAllergenId;

void _id(String value) {
  if (value.trim().isEmpty) throw ArgumentError('An identifier is required');
}

void _number(double value, {bool positive = false}) {
  if (!value.isFinite || (positive ? value <= 0 : value < 0)) {
    throw ArgumentError('Expected a finite nonnegative number');
  }
}

void _version(Map<String, dynamic> json) {
  if (json['version'] != 1) throw const FormatException('Unsupported version');
}

DateTime _day(String value) {
  final date = DateTime.tryParse(value);
  if (date == null || dayKey(date) != value) {
    throw const FormatException('Expected a valid YYYY-MM-DD date');
  }
  return DateTime(date.year, date.month, date.day);
}

String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

enum AllergySeverity { unspecified, mild, moderate, severe }

enum CrossContactPolicy { warn, avoid }

enum AllergenPresence { absent, present, mayContain, unknown }

class AllergyRule {
  AllergyRule({
    required String allergenId,
    this.severity = AllergySeverity.unspecified,
    this.crossContact = CrossContactPolicy.avoid,
    required this.source,
    required this.recordedOn,
  }) : allergenId = canonicalAllergenId(allergenId) {
    _id(this.allergenId);
    _id(source);
    _day(recordedOn);
  }
  final String allergenId, source, recordedOn;
  final AllergySeverity severity;
  final CrossContactPolicy crossContact;
  Map<String, dynamic> toJson() => {
    'allergenId': allergenId,
    'severity': severity.name,
    'crossContact': crossContact.name,
    'source': source,
    'recordedOn': recordedOn,
  };
  factory AllergyRule.fromJson(Map<String, dynamic> v) => AllergyRule(
    allergenId: v['allergenId'] as String,
    severity: AllergySeverity.values.byName(v['severity'] as String),
    crossContact: CrossContactPolicy.values.byName(v['crossContact'] as String),
    source: v['source'] as String,
    recordedOn: v['recordedOn'] as String,
  );
}

enum TargetAuthority { user, clinician }

/// Explicit daily range, never inferred from age, illness or sex.
class NutrientTarget {
  NutrientTarget({
    required this.nutrientId,
    required this.unit,
    this.minimum,
    this.maximum,
    required this.authority,
    required this.source,
    required this.recordedOn,
    required this.validFrom,
    this.validUntil,
    this.reviewOn,
  }) {
    _id(nutrientId);
    _id(unit);
    _id(source);
    _day(recordedOn);
    final start = _day(validFrom);
    if (minimum == null && maximum == null) {
      throw ArgumentError('Target needs at least one bound');
    }
    if (minimum != null) _number(minimum!);
    if (maximum != null) _number(maximum!);
    if (minimum != null && maximum != null && minimum! > maximum!) {
      throw ArgumentError('Target range reversed');
    }
    if (validUntil != null && _day(validUntil!).isBefore(start)) {
      throw ArgumentError('Target dates reversed');
    }
    if (reviewOn != null) _day(reviewOn!);
  }
  final String nutrientId, unit, source, recordedOn, validFrom;
  final String? validUntil, reviewOn;
  final double? minimum, maximum;
  final TargetAuthority authority;
  bool appliesOn(String day) {
    final d = _day(day);
    return !d.isBefore(_day(validFrom)) &&
        (validUntil == null || !d.isAfter(_day(validUntil!)));
  }

  Map<String, dynamic> toJson() => {
    'nutrientId': nutrientId,
    'unit': unit,
    'minimum': minimum,
    'maximum': maximum,
    'authority': authority.name,
    'source': source,
    'recordedOn': recordedOn,
    'validFrom': validFrom,
    'validUntil': validUntil,
    'reviewOn': reviewOn,
  };
  factory NutrientTarget.fromJson(Map<String, dynamic> v) => NutrientTarget(
    nutrientId: v['nutrientId'] as String,
    unit: v['unit'] as String,
    minimum: (v['minimum'] as num?)?.toDouble(),
    maximum: (v['maximum'] as num?)?.toDouble(),
    authority: TargetAuthority.values.byName(v['authority'] as String),
    source: v['source'] as String,
    recordedOn: v['recordedOn'] as String,
    validFrom: v['validFrom'] as String,
    validUntil: v['validUntil'] as String?,
    reviewOn: v['reviewOn'] as String?,
  );
}

/// memberId is exactly the existing HouseholdMember.id, not a second identity.
class NutritionPersonProfile {
  NutritionPersonProfile({
    required this.memberId,
    this.birthDate,
    this.declaredAgeYears,
    this.ageRecordedOn,
    List<AllergyRule> allergies = const [],
    List<NutrientTarget> targets = const [],
    Set<String> favoriteRecipeIds = const {},
    Set<String> dislikedFoodIds = const {},
    this.healthNote = '',
    this.celebrationsEnabled = true,
  }) : allergies = List.unmodifiable(allergies),
       targets = List.unmodifiable(targets),
       favoriteRecipeIds = Set.unmodifiable(favoriteRecipeIds),
       dislikedFoodIds = Set.unmodifiable(dislikedFoodIds) {
    _id(memberId);
    if (birthDate != null) _day(birthDate!);
    if (declaredAgeYears != null) {
      if (declaredAgeYears! < 0 ||
          declaredAgeYears! > 130 ||
          ageRecordedOn == null) {
        throw ArgumentError('Explicit age needs a valid value and date');
      }
    }
    if (ageRecordedOn != null) _day(ageRecordedOn!);
    if (allergies.map((a) => a.allergenId).toSet().length != allergies.length) {
      throw ArgumentError('Duplicate allergen rule');
    }
    for (final id in {...favoriteRecipeIds, ...dislikedFoodIds}) {
      _id(id);
    }
    for (var i = 0; i < targets.length; i++) {
      for (var j = i + 1; j < targets.length; j++) {
        final a = targets[i], b = targets[j];
        if (a.nutrientId == b.nutrientId &&
            (a.validUntil == null ||
                a.validUntil!.compareTo(b.validFrom) >= 0) &&
            (b.validUntil == null ||
                b.validUntil!.compareTo(a.validFrom) >= 0)) {
          throw ArgumentError('Overlapping targets for the same nutrient');
        }
      }
    }
  }
  final String memberId, healthNote;
  final String? birthDate, ageRecordedOn;
  final int? declaredAgeYears;
  final bool celebrationsEnabled;
  final List<AllergyRule> allergies;
  final List<NutrientTarget> targets;
  final Set<String> favoriteRecipeIds, dislikedFoodIds;
  Map<String, dynamic> toJson() => {
    'version': 1,
    'memberId': memberId,
    'birthDate': birthDate,
    'declaredAgeYears': declaredAgeYears,
    'ageRecordedOn': ageRecordedOn,
    'healthNote': healthNote,
    'celebrationsEnabled': celebrationsEnabled,
    'allergies': allergies.map((a) => a.toJson()).toList(),
    'targets': targets.map((t) => t.toJson()).toList(),
    'favoriteRecipeIds': favoriteRecipeIds.toList()..sort(),
    'dislikedFoodIds': dislikedFoodIds.toList()..sort(),
  };
  factory NutritionPersonProfile.fromJson(Map<String, dynamic> v) {
    _version(v);
    return NutritionPersonProfile(
      memberId: v['memberId'] as String,
      birthDate: v['birthDate'] as String?,
      declaredAgeYears: v['declaredAgeYears'] as int?,
      ageRecordedOn: v['ageRecordedOn'] as String?,
      healthNote: v['healthNote'] as String,
      celebrationsEnabled: v['celebrationsEnabled'] as bool,
      allergies: (v['allergies'] as List)
          .map((a) => AllergyRule.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList(),
      targets: (v['targets'] as List)
          .map(
            (a) => NutrientTarget.fromJson(Map<String, dynamic>.from(a as Map)),
          )
          .toList(),
      favoriteRecipeIds: Set<String>.from(v['favoriteRecipeIds'] as List),
      dislikedFoodIds: Set<String>.from(v['dislikedFoodIds'] as List),
    );
  }
}

/// Adapter from nutrition_core.NutrientTotal. A subtotal is not a complete value.
class PersonNutrientValue {
  PersonNutrientValue({
    required this.knownSubtotal,
    required this.complete,
    required this.unit,
    this.estimated,
  }) {
    _number(knownSubtotal);
    _id(unit);
  }
  final double knownSubtotal;
  final bool complete;

  /// null means legacy/unknown confidence; completeness is a separate axis.
  final bool? estimated;
  final String unit;
  double? get value => complete ? knownSubtotal : null;
  Map<String, dynamic> toJson() => {
    'knownSubtotal': knownSubtotal,
    'estimated': estimated,
    'complete': complete,
    'unit': unit,
  };
  factory PersonNutrientValue.fromJson(Map<String, dynamic> v) =>
      PersonNutrientValue(
        knownSubtotal: (v['knownSubtotal'] as num).toDouble(),
        estimated: v['estimated'] as bool?,
        complete: v['complete'] as bool,
        unit: v['unit'] as String,
      );
}

class MealBatch {
  MealBatch({
    required this.id,
    required this.recipeId,
    required this.sourceSnapshotId,
    required Map<String, PersonNutrientValue> nutrients,
    this.cookedGrams,
    Map<String, AllergenPresence> allergens = const {},
  }) : nutrients = Map.unmodifiable(nutrients),
       allergens = Map.unmodifiable(allergens) {
    _id(id);
    _id(recipeId);
    _id(sourceSnapshotId);
    if (cookedGrams != null) _number(cookedGrams!, positive: true);
    for (final key in {...nutrients.keys, ...allergens.keys}) {
      _id(key);
    }
  }
  final String id, recipeId, sourceSnapshotId;
  final double? cookedGrams;
  final Map<String, PersonNutrientValue> nutrients;
  final Map<String, AllergenPresence> allergens;
  Map<String, dynamic> toJson() => {
    'id': id,
    'recipeId': recipeId,
    'sourceSnapshotId': sourceSnapshotId,
    'cookedGrams': cookedGrams,
    'nutrients': {
      for (final k in nutrients.keys.toList()..sort())
        k: nutrients[k]!.toJson(),
    },
    'allergens': {
      for (final k in allergens.keys.toList()..sort()) k: allergens[k]!.name,
    },
  };
  factory MealBatch.fromJson(Map<String, dynamic> v) => MealBatch(
    id: v['id'] as String,
    recipeId: v['recipeId'] as String,
    sourceSnapshotId: v['sourceSnapshotId'] as String,
    cookedGrams: (v['cookedGrams'] as num?)?.toDouble(),
    nutrients: (v['nutrients'] as Map).map(
      (k, a) => MapEntry(
        k as String,
        PersonNutrientValue.fromJson(Map<String, dynamic>.from(a as Map)),
      ),
    ),
    allergens: (v['allergens'] as Map).map(
      (k, a) =>
          MapEntry(k as String, AllergenPresence.values.byName(a as String)),
    ),
  );
}

enum PortionUnit { grams, batchFraction }

class PortionAmount {
  PortionAmount(this.amount, this.unit) {
    _number(amount, positive: true);
    if (unit == PortionUnit.batchFraction && amount > 1) {
      throw ArgumentError('A portion cannot exceed the batch');
    }
  }
  final double amount;
  final PortionUnit unit;
  double fractionOf(MealBatch batch) {
    if (unit == PortionUnit.batchFraction) return amount;
    if (batch.cookedGrams == null) {
      throw StateError(
        'Measured cooked batch mass is required for gram portions',
      );
    }
    return amount / batch.cookedGrams!;
  }

  Map<String, dynamic> toJson() => {'amount': amount, 'unit': unit.name};
  factory PortionAmount.fromJson(Map<String, dynamic> v) => PortionAmount(
    (v['amount'] as num).toDouble(),
    PortionUnit.values.byName(v['unit'] as String),
  );
}

enum NutritionEventKind { planned, consumed, leftover, waste }

/// Append-only attributed record. actorId identifies the recording user, it is
/// not a cryptographic signature. Corrections preserve the previous record.
class NutritionEvent {
  NutritionEvent({
    required this.id,
    required this.batchId,
    required this.kind,
    this.personId,
    required this.portion,
    required this.day,
    required this.actorId,
    required this.recordedAt,
    this.corrects,
    this.cancelled = false,
  }) {
    _id(id);
    _id(batchId);
    _id(actorId);
    _day(day);
    if (kind == NutritionEventKind.planned ||
        kind == NutritionEventKind.consumed) {
      if (personId == null) throw ArgumentError('Person is required');
      _id(personId!);
    } else if (personId != null) {
      throw ArgumentError('Leftover and waste belong to the batch');
    }
    if (corrects != null) _id(corrects!);
    if (cancelled && corrects == null) {
      throw ArgumentError('Only corrections can cancel');
    }
  }
  final String id, batchId, day, actorId;
  final String? personId, corrects;
  final NutritionEventKind kind;
  final PortionAmount portion;
  final DateTime recordedAt;
  final bool cancelled;
  Map<String, dynamic> toJson() => {
    'id': id,
    'batchId': batchId,
    'kind': kind.name,
    'personId': personId,
    'portion': portion.toJson(),
    'day': day,
    'actorId': actorId,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    'corrects': corrects,
    'cancelled': cancelled,
  };
  factory NutritionEvent.fromJson(Map<String, dynamic> v) => NutritionEvent(
    id: v['id'] as String,
    batchId: v['batchId'] as String,
    kind: NutritionEventKind.values.byName(v['kind'] as String),
    personId: v['personId'] as String?,
    portion: PortionAmount.fromJson(
      Map<String, dynamic>.from(v['portion'] as Map),
    ),
    day: v['day'] as String,
    actorId: v['actorId'] as String,
    recordedAt: DateTime.parse(v['recordedAt'] as String),
    corrects: v['corrects'] as String?,
    cancelled: v['cancelled'] as bool,
  );
}

class BatchBalance {
  const BatchBalance({
    required this.planned,
    required this.consumed,
    required this.leftover,
    required this.waste,
  });
  final double planned, consumed, leftover, waste;
  double get unaccounted => (1 - consumed - leftover - waste).clamp(0, 1);
}

class PersonNutritionReport {
  PersonNutritionReport({
    required this.personId,
    required this.day,
    required this.kind,
    required Map<String, PersonNutrientValue> nutrients,
    required this.eventCount,
  }) : nutrients = Map.unmodifiable(nutrients);
  final String personId, day;
  final NutritionEventKind kind;
  final Map<String, PersonNutrientValue> nutrients;
  final int eventCount;
}

/// Immutable ledger; persist the returned value once via the application owner.
/// Planned allocations are separate from actual consumption, never added to it.
class NutritionLedger {
  NutritionLedger._(this.batches, this.events);
  factory NutritionLedger.empty() => NutritionLedger._(const {}, const []);
  final Map<String, MealBatch> batches;
  final List<NutritionEvent> events;
  NutritionLedger addBatch(MealBatch batch) {
    final existing = batches[batch.id];
    if (existing != null) {
      if (jsonEncode(existing.toJson()) != jsonEncode(batch.toJson())) {
        throw StateError('Batch snapshot is immutable');
      }
      return this;
    }
    return NutritionLedger._(
      Map.unmodifiable({...batches, batch.id: batch}),
      events,
    );
  }

  List<NutritionEvent> get activeEvents {
    final replaced = events.map((e) => e.corrects).whereType<String>().toSet();
    return List.unmodifiable(
      events.where((e) => !replaced.contains(e.id) && !e.cancelled),
    );
  }

  NutritionLedger append(NutritionEvent event) {
    for (final old in events) {
      if (old.id == event.id) {
        if (jsonEncode(old.toJson()) != jsonEncode(event.toJson())) {
          throw StateError('Event identifier already used with different data');
        }
        return this;
      }
    }
    final batch = batches[event.batchId];
    if (batch == null) throw StateError('Unknown batch');
    event.portion.fractionOf(batch);
    if (event.corrects != null) {
      final previous = events.where((e) => e.id == event.corrects).firstOrNull;
      if (previous == null || events.any((e) => e.corrects == previous.id)) {
        throw StateError('Correction must replace the current leaf record');
      }
      if (previous.batchId != event.batchId ||
          previous.personId != event.personId ||
          previous.kind != event.kind ||
          event.recordedAt.isBefore(previous.recordedAt)) {
        throw StateError('Correction changes identity or predates original');
      }
    }
    final next = NutritionLedger._(
      batches,
      List.unmodifiable([...events, event]),
    );
    final balance = next.balance(event.batchId);
    if (balance.planned > 1 + 1e-9 ||
        balance.consumed + balance.leftover + balance.waste > 1 + 1e-9) {
      throw StateError('Portions, leftovers and waste exceed the batch');
    }
    return next;
  }

  BatchBalance balance(String batchId) {
    final batch = batches[batchId];
    if (batch == null) throw StateError('Unknown batch');
    final totals = {for (final kind in NutritionEventKind.values) kind: 0.0};
    for (final event in activeEvents.where((e) => e.batchId == batchId)) {
      totals[event.kind] =
          totals[event.kind]! + event.portion.fractionOf(batch);
    }
    return BatchBalance(
      planned: totals[NutritionEventKind.planned]!,
      consumed: totals[NutritionEventKind.consumed]!,
      leftover: totals[NutritionEventKind.leftover]!,
      waste: totals[NutritionEventKind.waste]!,
    );
  }

  PersonNutritionReport report({
    required String personId,
    required String day,
    required NutritionEventKind kind,
    Set<String> nutrientIds = const {},
  }) {
    _id(personId);
    _day(day);
    if (kind != NutritionEventKind.planned &&
        kind != NutritionEventKind.consumed) {
      throw ArgumentError('A person report is planned or consumed');
    }
    final selected = activeEvents
        .where((e) => e.personId == personId && e.day == day && e.kind == kind)
        .toList();
    final ids = {
      ...nutrientIds,
      for (final e in selected) ...batches[e.batchId]!.nutrients.keys,
    };
    final values = <String, PersonNutrientValue>{};
    for (final id in ids) {
      var subtotal = 0.0, complete = selected.isNotEmpty;
      bool? estimated = false;
      String? unit;
      for (final event in selected) {
        final batch = batches[event.batchId]!, value = batch.nutrients[id];
        if (value == null) {
          complete = false;
          if (estimated != true) estimated = null;
          continue;
        }
        if (unit != null && unit != value.unit) {
          throw StateError('Conflicting nutrient units');
        }
        unit = value.unit;
        if (value.estimated == true) {
          estimated = true;
        } else if (value.estimated == null && estimated != true) {
          estimated = null;
        }
        subtotal += value.knownSubtotal * event.portion.fractionOf(batch);
        complete = complete && value.complete;
      }
      if (unit != null) {
        values[id] = PersonNutrientValue(
          knownSubtotal: subtotal,
          estimated: estimated,
          complete: complete,
          unit: unit,
        );
      }
    }
    return PersonNutritionReport(
      personId: personId,
      day: day,
      kind: kind,
      nutrients: values,
      eventCount: selected.length,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'batches': [
      for (final id in batches.keys.toList()..sort()) batches[id]!.toJson(),
    ],
    'events': events.map((e) => e.toJson()).toList(),
  };
  factory NutritionLedger.fromJson(Map<String, dynamic> v) {
    _version(v);
    var ledger = NutritionLedger.empty();
    for (final raw in v['batches'] as List) {
      final batch = MealBatch.fromJson(Map<String, dynamic>.from(raw as Map));
      if (ledger.batches.containsKey(batch.id)) {
        throw const FormatException('Duplicate batch');
      }
      ledger = ledger.addBatch(batch);
    }
    for (final raw in v['events'] as List) {
      final event = NutritionEvent.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
      if (ledger.events.any((e) => e.id == event.id)) {
        throw const FormatException('Duplicate event');
      }
      ledger = ledger.append(event);
    }
    return ledger;
  }
}

enum NutritionInteractionKind {
  favoriteCelebration,
  allergyConflict,
  allergyCrossContactWarning,
  allergyUnknown,
  targetBelow,
  targetAbove,
  targetWithin,
  targetUnknown,
  targetEstimated,
  targetNeedsReview,
}

class NutritionInteraction {
  const NutritionInteraction(this.id, this.personId, this.kind, this.subjectId);
  final String id, personId, subjectId;
  final NutritionInteractionKind kind;
}

List<NutritionInteraction> mealInteractions({
  required NutritionPersonProfile person,
  required MealBatch batch,
  required String triggerId,
}) {
  _id(triggerId);
  final result = <NutritionInteraction>[];
  void add(NutritionInteractionKind kind, String subject) => result.add(
    NutritionInteraction(
      '$triggerId:${person.memberId}:${kind.name}:$subject',
      person.memberId,
      kind,
      subject,
    ),
  );
  for (final allergy in person.allergies) {
    final status =
        batch.allergens[allergy.allergenId] ?? AllergenPresence.unknown;
    switch (status) {
      case AllergenPresence.present:
        add(NutritionInteractionKind.allergyConflict, allergy.allergenId);
      case AllergenPresence.mayContain:
        add(
          allergy.crossContact == CrossContactPolicy.avoid
              ? NutritionInteractionKind.allergyConflict
              : NutritionInteractionKind.allergyCrossContactWarning,
          allergy.allergenId,
        );
      case AllergenPresence.unknown:
        add(NutritionInteractionKind.allergyUnknown, allergy.allergenId);
      case AllergenPresence.absent:
        break;
    }
  }
  if (result.isEmpty &&
      person.celebrationsEnabled &&
      person.favoriteRecipeIds.contains(batch.recipeId)) {
    add(NutritionInteractionKind.favoriteCelebration, batch.recipeId);
  }
  return List.unmodifiable(result);
}

/// periodComplete must be explicitly asserted by the caller. A partial day or
/// unknown meal nutrient cannot establish that a daily target was satisfied.
/// A complete but estimated subtotal remains a separate review state; legacy
/// null confidence is unknown and cannot certify within/below/above either.
List<NutritionInteraction> targetInteractions({
  required NutritionPersonProfile person,
  required PersonNutritionReport report,
  required bool periodComplete,
  required String triggerId,
}) {
  if (report.personId != person.memberId) {
    throw ArgumentError('Report person mismatch');
  }
  _id(triggerId);
  final result = <NutritionInteraction>[];
  void add(NutritionInteractionKind kind, String subject) => result.add(
    NutritionInteraction(
      '$triggerId:${person.memberId}:${kind.name}:$subject',
      person.memberId,
      kind,
      subject,
    ),
  );
  for (final target in person.targets.where((t) => t.appliesOn(report.day))) {
    final value = report.nutrients[target.nutrientId];
    if (target.reviewOn != null &&
        report.day.compareTo(target.reviewOn!) >= 0) {
      add(NutritionInteractionKind.targetNeedsReview, target.nutrientId);
      continue;
    }
    if (!periodComplete ||
        value == null ||
        !value.complete ||
        value.unit != target.unit ||
        value.estimated == null) {
      add(NutritionInteractionKind.targetUnknown, target.nutrientId);
    } else if (value.estimated == true) {
      // A complete subtotal can still be estimated; do not certify a target.
      add(NutritionInteractionKind.targetEstimated, target.nutrientId);
    } else if (target.minimum != null &&
        value.knownSubtotal < target.minimum!) {
      add(NutritionInteractionKind.targetBelow, target.nutrientId);
    } else if (target.maximum != null &&
        value.knownSubtotal > target.maximum!) {
      add(NutritionInteractionKind.targetAbove, target.nutrientId);
    } else {
      add(NutritionInteractionKind.targetWithin, target.nutrientId);
    }
  }
  return List.unmodifiable(result);
}
