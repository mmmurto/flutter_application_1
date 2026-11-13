import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/restaurant_menu.dart';

/// Reads the public menu for one restaurant.
///
/// The anon role can only see published restaurants with active categories and
/// available items, so the database decides what is public; this layer never
/// filters by trust and never writes.
abstract interface class MenuRepository {
  /// Returns `null` when no published menu exists for [restaurantSlug].
  Future<RestaurantMenu?> fetchPublishedMenu(String restaurantSlug);
}

class SupabaseMenuRepository implements MenuRepository {
  const SupabaseMenuRepository(this._client);

  final SupabaseClient _client;

  static const _menuSelect =
      'id, name, slug, description, address, phone, '
      'menu_categories(name, sort_order, '
      'menu_items(name, description, price, sort_order, is_vegetarian, is_spicy, is_available))';

  @override
  Future<RestaurantMenu?> fetchPublishedMenu(String restaurantSlug) async {
    final row = await _client
        .from('restaurants')
        .select(_menuSelect)
        .eq('slug', restaurantSlug)
        .maybeSingle();

    if (row == null) return null;

    final menu = RestaurantMenu.fromJson(row);
    if (menu == null || !menu.hasItems) return null;
    return menu;
  }
}
