/// Read models for a restaurant's own menu, including unpublished content.
///
/// These are only returned to signed-in staff through RLS. Editing is not
/// implemented yet, so nothing here is writable from the client.
library;

class ManagedMenuItem {
  const ManagedMenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
    this.description,
    this.isVegetarian = false,
    this.isSpicy = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final double price;
  final bool isAvailable;
  final String? description;
  final bool isVegetarian;
  final bool isSpicy;
  final int sortOrder;

  String get formattedPrice => '${price.toStringAsFixed(2)} \u20BC';

  static ManagedMenuItem? fromJson(Map<String, Object?> json) {
    final id = _string(json['id']);
    final name = _string(json['name']);
    final price = _double(json['price']);
    if (id == null || name == null || price == null) return null;

    return ManagedMenuItem(
      id: id,
      name: name,
      price: price,
      isAvailable: json['is_available'] != false,
      description: _string(json['description']),
      isVegetarian: json['is_vegetarian'] == true,
      isSpicy: json['is_spicy'] == true,
      sortOrder: _int(json['sort_order']) ?? 0,
    );
  }
}

class ManagedMenuCategory {
  const ManagedMenuCategory({
    required this.id,
    required this.name,
    required this.isActive,
    required this.items,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final bool isActive;
  final List<ManagedMenuItem> items;
  final int sortOrder;

  static ManagedMenuCategory? fromJson(Map<String, Object?> json) {
    final id = _string(json['id']);
    final name = _string(json['name']);
    if (id == null || name == null) return null;

    final items = <ManagedMenuItem>[];
    final rawItems = json['menu_items'];
    if (rawItems is List) {
      for (final rawItem in rawItems) {
        if (rawItem is! Map<String, Object?>) continue;
        final item = ManagedMenuItem.fromJson(rawItem);
        if (item != null) items.add(item);
      }
    }
    items.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0
          ? byOrder
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return ManagedMenuCategory(
      id: id,
      name: name,
      isActive: json['is_active'] != false,
      items: items,
      sortOrder: _int(json['sort_order']) ?? 0,
    );
  }
}

class ManagedMenu {
  const ManagedMenu({
    required this.name,
    required this.slug,
    required this.publicationStatus,
    required this.categories,
    this.address,
    this.description,
  });

  final String name;
  final String slug;
  final String publicationStatus;
  final List<ManagedMenuCategory> categories;
  final String? address;
  final String? description;

  bool get isPublished => publicationStatus == 'published';

  String get publicationLabel => switch (publicationStatus) {
    'published' => 'Published',
    'pending_review' => 'In review',
    'suspended' => 'Suspended',
    _ => 'Not published yet',
  };

  int get hiddenItemCount => categories.fold(
    0,
    (total, category) =>
        total + category.items.where((item) => !item.isAvailable).length,
  );

  static ManagedMenu? fromJson(Map<String, Object?> json) {
    final name = _string(json['name']);
    final slug = _string(json['slug']);
    if (name == null || slug == null) return null;

    final categories = <ManagedMenuCategory>[];
    final rawCategories = json['menu_categories'];
    if (rawCategories is List) {
      for (final rawCategory in rawCategories) {
        if (rawCategory is! Map<String, Object?>) continue;
        final category = ManagedMenuCategory.fromJson(rawCategory);
        if (category != null) categories.add(category);
      }
    }
    categories.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0
          ? byOrder
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return ManagedMenu(
      name: name,
      slug: slug,
      publicationStatus: _string(json['publication_status']) ?? 'draft',
      categories: categories,
      address: _string(json['address']),
      description: _string(json['description']),
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
