import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/managed_menu.dart';

/// Reads a restaurant's own menu, including draft and unavailable content.
///
/// The request runs with the staff member's session. RLS only returns menu rows
/// for restaurants the account belongs to, so the slug alone grants nothing.
abstract interface class OwnerMenuRepository {
  Future<ManagedMenu?> fetchManagedMenu(String restaurantSlug);
}

class SupabaseOwnerMenuRepository implements OwnerMenuRepository {
  const SupabaseOwnerMenuRepository(this._client);

  final SupabaseClient _client;

  static const _menuSelect =
      'id, name, slug, description, address, publication_status, '
      'menu_categories(id, name, sort_order, is_active, '
      'menu_items(id, name, description, price, sort_order, is_vegetarian, '
      'is_spicy, is_available))';

  @override
  Future<ManagedMenu?> fetchManagedMenu(String restaurantSlug) async {
    final row = await _client
        .from('restaurants')
        .select(_menuSelect)
        .eq('slug', restaurantSlug)
        .maybeSingle();

    if (row == null) return null;
    return ManagedMenu.fromJson(row);
  }
}
