/// Read models for the public, restaurant-approved menu.
///
/// These models only describe data the public anon role is allowed to read:
/// published restaurants and their active, available menu content. Parsing is
/// deliberately tolerant — a malformed row is skipped instead of breaking the
/// whole menu — but no value here is ever treated as authoritative for
/// pricing or ordering. Server-side totals and order creation come later.
library;

class MenuItem {
  const MenuItem({
    required this.name,
    required this.price,
    this.description,
    this.isVegetarian = false,
    this.isSpicy = false,
  });

  final String name;
  final String? description;
  final double price;
  final bool isVegetarian;
  final bool isSpicy;

  static MenuItem? fromJson(Map<String, Object?> json) {
    final name = _string(json['name']);
    if (name == null) return null;

    final price = _double(json['price']);
    if (price == null || price < 0) return null;

    return MenuItem(
      name: name,
      description: _string(json['description']),
      price: price,
      isVegetarian: json['is_vegetarian'] == true,
      isSpicy: json['is_spicy'] == true,
    );
  }

  /// AZN, two decimals and the manat sign. Full locale support is deferred.
  String get formattedPrice => '${price.toStringAsFixed(2)} \u20BC';
}

class MenuCategory {
  const MenuCategory({
    required this.name,
    required this.items,
    this.sortOrder = 0,
  });

  final String name;
  final List<MenuItem> items;
  final int sortOrder;

  static MenuCategory? fromJson(Map<String, Object?> json) {
    final name = _string(json['name']);
    if (name == null) return null;

    final items = <MenuItem>[];
    final rawItems = json['menu_items'];
    if (rawItems is List) {
      for (final rawItem in rawItems) {
        if (rawItem is Map<String, Object?>) {
          // RLS already hides unavailable items from anonymous readers; keep
          // the guard so an authenticated staff session cannot render them.
          if (rawItem['is_available'] == false) continue;
          final item = MenuItem.fromJson(rawItem);
          if (item != null) items.add(item);
        }
      }
    }
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return MenuCategory(
      name: name,
      items: items,
      sortOrder: _int(json['sort_order']) ?? 0,
    );
  }
}

class RestaurantMenu {
  const RestaurantMenu({
    required this.name,
    required this.slug,
    required this.categories,
    this.description,
    this.address,
    this.phone,
  });

  final String name;
  final String slug;
  final String? description;
  final String? address;
  final String? phone;
  final List<MenuCategory> categories;

  bool get hasItems => categories.any((category) => category.items.isNotEmpty);

  static RestaurantMenu? fromJson(Map<String, Object?> json) {
    final name = _string(json['name']);
    final slug = _string(json['slug']);
    if (name == null || slug == null) return null;

    final categories = <MenuCategory>[];
    final rawCategories = json['menu_categories'];
    if (rawCategories is List) {
      for (final rawCategory in rawCategories) {
        if (rawCategory is Map<String, Object?>) {
          final category = MenuCategory.fromJson(rawCategory);
          if (category != null) categories.add(category);
        }
      }
    }
    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return RestaurantMenu(
      name: name,
      slug: slug,
      description: _string(json['description']),
      address: _string(json['address']),
      phone: _string(json['phone']),
      categories: categories,
    );
  }
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

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
