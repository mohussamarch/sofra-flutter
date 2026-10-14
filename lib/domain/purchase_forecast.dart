import 'kitchen_core.dart';

/// Remainder after usable known stock; unresolved stock can still cover it.
class ForecastPurchase {
  const ForecastPurchase(this.use, this.estimatedCost);
  final IngredientUse use;
  final double? estimatedCost;
}

/// Read-only estimate: purchase cost and ingredient consumption stay separate.
class PurchaseForecast {
  PurchaseForecast({
    required List<ForecastPurchase> purchases,
    required this.knownPurchaseSubtotal,
    required this.purchaseTotal,
    required this.knownConsumptionSubtotal,
    required this.consumptionTotal,
    required Set<String> unresolvedRequirements,
    required Set<String> unresolvedStock,
    required Set<String> unpricedPurchases,
    required Set<String> unpricedConsumption,
  }) : purchases = List.unmodifiable(purchases),
       unresolvedRequirements = Set.unmodifiable(unresolvedRequirements),
       unresolvedStock = Set.unmodifiable(unresolvedStock),
       unpricedPurchases = Set.unmodifiable(unpricedPurchases),
       unpricedConsumption = Set.unmodifiable(unpricedConsumption);

  final List<ForecastPurchase> purchases;
  final double knownPurchaseSubtotal, knownConsumptionSubtotal;
  final double? purchaseTotal, consumptionTotal;
  final Set<String> unresolvedRequirements, unresolvedStock;
  final Set<String> unpricedPurchases, unpricedConsumption;

  /// Whether new-purchase cost is complete; consumption can remain unpriced.
  bool get complete => purchaseTotal != null;
}

/// Explicit preview only. The pricing callback must be pure and country-scoped.
/// No pack sizes, densities, stock changes, purchases or history are inferred.
PurchaseForecast forecastPurchases(
  List<IngredientUse> requirements,
  List<InventoryLot> stock, {
  required double? Function(IngredientUse) estimateCost,
  List<UnitRule> rules = const [],
  Set<String> unresolvedRequirements = const {},
}) {
  final pending = Set<String>.of(unresolvedRequirements);
  if (pending.any((id) => id.trim().isEmpty)) {
    throw ArgumentError('Missing unresolved requirement identity');
  }
  final combined = <IngredientUse>[];
  for (final use in requirements) {
    if (use.ingredientId.trim().isEmpty || use.unit.isEmpty) {
      throw ArgumentError('Missing requirement identity or unit');
    }
    var merged = false;
    for (var i = 0; i < combined.length; i++) {
      final previous = combined[i];
      if (previous.ingredientId != use.ingredientId) continue;
      final converted = Units.convert(
        use.quantity,
        use.unit,
        previous.unit,
        ingredientId: use.ingredientId,
        rules: rules,
      );
      if (converted == null) continue;
      requireAmount(converted);
      combined[i] = IngredientUse(
        use.ingredientId,
        previous.quantity + converted,
        previous.unit,
      );
      merged = true;
      break;
    }
    if (!merged) combined.add(use);
  }

  if (stock.map((lot) => lot.id).toSet().length != stock.length) {
    throw ArgumentError('Duplicate stock lot IDs');
  }
  // A known empty lot has nothing to allocate, regardless of its unit.
  final assessment = assessStock(
    combined,
    stock.where((lot) => lot.quantity != 0).toList(),
    rules: rules,
  );
  final missingIds = assessment.missing.map((use) => use.ingredientId).toSet();
  final unresolvedStock = assessment.unresolved.intersection(missingIds);
  final unpricedConsumption = <String>{}, unpricedPurchases = <String>{};
  final purchases = <ForecastPurchase>[];
  var consumptionSubtotal = 0.0, purchaseSubtotal = 0.0;

  double? price(IngredientUse use) {
    final cost = estimateCost(use);
    if (cost != null) requireAmount(cost, zero: true);
    return cost;
  }

  for (final use in combined) {
    final cost = price(use);
    if (cost == null) {
      unpricedConsumption.add(use.ingredientId);
    } else {
      consumptionSubtotal += cost;
      requireAmount(consumptionSubtotal, zero: true);
    }
  }
  for (final use in assessment.missing) {
    // An unknown or incompatible lot might cover this apparent shortage.
    // Keep its known-stock remainder visible, but never call it a priced need.
    final blocked = unresolvedStock.contains(use.ingredientId);
    final cost = blocked ? null : price(use);
    purchases.add(ForecastPurchase(use, cost));
    if (cost == null) {
      if (!blocked) unpricedPurchases.add(use.ingredientId);
    } else {
      purchaseSubtotal += cost;
      requireAmount(purchaseSubtotal, zero: true);
    }
  }
  return PurchaseForecast(
    purchases: purchases,
    knownPurchaseSubtotal: purchaseSubtotal,
    purchaseTotal:
        pending.isEmpty && unresolvedStock.isEmpty && unpricedPurchases.isEmpty
        ? purchaseSubtotal
        : null,
    knownConsumptionSubtotal: consumptionSubtotal,
    consumptionTotal: pending.isEmpty && unpricedConsumption.isEmpty
        ? consumptionSubtotal
        : null,
    unresolvedRequirements: pending,
    unresolvedStock: unresolvedStock,
    unpricedPurchases: unpricedPurchases,
    unpricedConsumption: unpricedConsumption,
  );
}
