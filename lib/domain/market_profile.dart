enum MarketCountry { egypt, saudi }

class MarketProfile {
  const MarketProfile(this.country);
  final MarketCountry country;
  String get code => country == MarketCountry.egypt ? 'EG' : 'SA';
  String get locale => country == MarketCountry.egypt ? 'ar-EG' : 'ar-SA';
  String get currency => country == MarketCountry.egypt ? 'EGP' : 'SAR';
  String get currencyLabel => country == MarketCountry.egypt ? 'ج.م' : 'ر.س';
  String get today => country == MarketCountry.egypt ? 'النهارده' : 'اليوم';
  String get fridge => country == MarketCountry.egypt ? 'التلاجة' : 'الثلاجة';
  static MarketProfile fromCode(String? code) =>
      MarketProfile(code == 'SA' ? MarketCountry.saudi : MarketCountry.egypt);
}

/// A market-specific observed/user-entered price, never an exchange-rate guess.
class MarketPrice {
  MarketPrice({
    required this.country,
    required this.ingredientId,
    required this.unit,
    required this.quantity,
    required this.amount,
    required this.recordedAt,
    required this.source,
  }) {
    if (!quantity.isFinite ||
        quantity <= 0 ||
        !amount.isFinite ||
        amount < 0 ||
        source.trim().isEmpty) {
      throw ArgumentError('Invalid price');
    }
  }
  final MarketCountry country;
  final String ingredientId, unit, source;
  final double quantity, amount;
  final DateTime recordedAt;
  double? cost(MarketCountry market, double needed, String requestedUnit) {
    if (!needed.isFinite || needed < 0) throw ArgumentError.value(needed);
    return country == market && unit == requestedUnit
        ? needed / quantity * amount
        : null;
  }
}
