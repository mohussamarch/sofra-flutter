import 'kitchen_core.dart';
import 'monthly_budget_choices.dart';

/// Checks only caller-declared date/meal-slot coverage. No daily pattern,
/// household member, nutrition target or recipe suitability is inferred.
class MonthlyBudgetSlotCoverageAssessment {
  MonthlyBudgetSlotCoverageAssessment._({
    required List<MonthlyBudgetCoverage> required,
    required List<MonthlyBudgetCoverage> supplied,
    required List<MonthlyBudgetCoverage> missing,
    required List<MonthlyBudgetCoverage> additional,
  }) : required = List.unmodifiable(required),
       supplied = List.unmodifiable(supplied),
       missing = List.unmodifiable(missing),
       additional = List.unmodifiable(additional);

  final List<MonthlyBudgetCoverage> required;
  final List<MonthlyBudgetCoverage> supplied;
  final List<MonthlyBudgetCoverage> missing;
  final List<MonthlyBudgetCoverage> additional;

  /// Additional supplied slots are allowed; their costs remain in the search.
  bool get coversRequired => missing.isEmpty;
}

/// Validates an explicit nonempty required set against the supplied pool slots.
/// Dates must lie in the exact calendar month. Duplicate or blank slots reject.
MonthlyBudgetSlotCoverageAssessment assessMonthlyBudgetSlotCoverage({
  required BudgetPeriod period,
  required List<MonthlyBudgetCoverage> requiredSlots,
  required List<MonthlyBudgetCoverage> suppliedSlots,
}) {
  final start = parseDay(period.start), end = parseDay(period.end);
  if (start.day != 1 || end != DateTime(start.year, start.month + 1)) {
    throw ArgumentError('Budget must span exactly one calendar month');
  }
  if (requiredSlots.isEmpty) {
    throw ArgumentError('Explicit required slots must be nonempty');
  }
  final required = _validatedSlots(period, requiredSlots);
  final supplied = _validatedSlots(period, suppliedSlots);
  final requiredKeys = <(String, String)>{
    for (final slot in required) (slot.date, slot.slot),
  };
  final suppliedKeys = <(String, String)>{
    for (final slot in supplied) (slot.date, slot.slot),
  };
  return MonthlyBudgetSlotCoverageAssessment._(
    required: required,
    supplied: supplied,
    missing: [
      for (final slot in required)
        if (!suppliedKeys.contains((slot.date, slot.slot))) slot,
    ],
    additional: [
      for (final slot in supplied)
        if (!requiredKeys.contains((slot.date, slot.slot))) slot,
    ],
  );
}

List<MonthlyBudgetCoverage> _validatedSlots(
  BudgetPeriod period,
  List<MonthlyBudgetCoverage> slots,
) {
  final seen = <(String, String)>{};
  final owned = <MonthlyBudgetCoverage>[];
  for (final slot in slots) {
    if (!period.includes(parseDay(slot.date)) ||
        slot.slot.trim().isEmpty ||
        !seen.add((slot.date, slot.slot))) {
      throw ArgumentError('Invalid, duplicate or out-of-period slot');
    }
    owned.add(MonthlyBudgetCoverage(slot.date, slot.slot));
  }
  owned.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    return byDate == 0 ? a.slot.compareTo(b.slot) : byDate;
  });
  return owned;
}
