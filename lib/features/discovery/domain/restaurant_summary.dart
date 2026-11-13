/// Public restaurant directory models and filtering.
///
/// Only data the anon role may read is represented here: published, active
/// restaurants and their available menu prices. Prices are shown as an
/// estimated "from" value per person; they are never treated as a quote.
library;

class RestaurantSummary {
  const RestaurantSummary({
    required this.name,
    required this.slug,
    this.description,
    this.address,
    this.fromPrice,
  });

  final String name;
  final String slug;
  final String? description;
  final String? address;

  /// Cheapest available dish, in AZN. `null` when the approved menu is not
  /// published yet.
  final double? fromPrice;

  bool get hasPublishedPrices => fromPrice != null;

  String get formattedFromPrice {
    final price = fromPrice;
    if (price == null) return 'Menu coming soon';
    return 'from ${price.toStringAsFixed(2)} \u20BC';
  }

  static RestaurantSummary? fromJson(Map<String, Object?> json) {
    final name = _string(json['name']);
    final slug = _string(json['slug']);
    if (name == null || slug == null) return null;

    return RestaurantSummary(
      name: name,
      slug: slug,
      description: _string(json['description']),
      address: _string(json['address']),
      fromPrice: _cheapestPrice(json['menu_items']),
    );
  }
}

/// Applies the customer's search text and per-person budget.
///
/// A restaurant matches the budget when it has at least one approved dish at or
/// below [maxPrice]. That is deliberately a "has dishes within budget" filter,
/// not a promise that a full meal fits.
List<RestaurantSummary> filterRestaurants(
  List<RestaurantSummary> restaurants, {
  String query = '',
  double? maxPrice,
}) {
  final needle = query.trim().toLowerCase();
  final filtered = restaurants.where((restaurant) {
    if (needle.isNotEmpty) {
      final haystack = [
        restaurant.name,
        restaurant.description,
        restaurant.address,
      ].whereType<String>().join(' ').toLowerCase();
      if (!haystack.contains(needle)) return false;
    }
    if (maxPrice != null) {
      final price = restaurant.fromPrice;
      if (price == null || price > maxPrice) return false;
    }
    return true;
  }).toList();

  filtered.sort((a, b) {
    final aPrice = a.fromPrice;
    final bPrice = b.fromPrice;
    if (aPrice == null && bPrice == null) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }
    if (aPrice == null) return 1;
    if (bPrice == null) return -1;
    final byPrice = aPrice.compareTo(bPrice);
    return byPrice != 0
        ? byPrice
        : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return filtered;
}

double? _cheapestPrice(Object? menuItems) {
  if (menuItems is! List) return null;
  double? cheapest;
  for (final item in menuItems) {
    if (item is! Map<String, Object?>) continue;
    if (item['is_available'] == false) continue;
    final price = _double(item['price']);
    if (price == null || price < 0) continue;
    if (cheapest == null || price < cheapest) cheapest = price;
  }
  return cheapest;
}

String? _string(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
