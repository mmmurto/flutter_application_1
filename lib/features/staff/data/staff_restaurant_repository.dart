import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/staff_restaurant.dart';

/// Reads the restaurants the signed-in staff member belongs to.
///
/// The request runs with the user's own session, so RLS returns only their
/// membership rows and only restaurants they may see. No restaurant id is ever
/// supplied by the client.
abstract interface class StaffRestaurantRepository {
  Future<List<StaffRestaurant>> fetchMyRestaurants();
}

class SupabaseStaffRestaurantRepository implements StaffRestaurantRepository {
  const SupabaseStaffRestaurantRepository(this._client);

  final SupabaseClient _client;

  static const _membershipSelect =
      'role, is_active, restaurants(name, slug, publication_status)';

  @override
  Future<List<StaffRestaurant>> fetchMyRestaurants() async {
    // An owner or manager may read every membership of their restaurant, so the
    // query must still be narrowed to this account's own rows. RLS remains the
    // authority; this only prevents the same restaurant appearing once per
    // colleague.
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    final rows = await _client
        .from('restaurant_memberships')
        .select(_membershipSelect)
        .eq('profile_id', userId)
        .order('created_at');

    final restaurants = <StaffRestaurant>[];
    for (final row in rows) {
      final restaurant = StaffRestaurant.fromJson(row);
      // The owner may still see their own inactive membership so they know it
      // was removed; it must not appear as usable access.
      if (restaurant == null || !restaurant.isActive) continue;
      restaurants.add(restaurant);
    }
    return restaurants;
  }
}
