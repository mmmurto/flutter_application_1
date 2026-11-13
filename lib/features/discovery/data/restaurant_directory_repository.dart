import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/restaurant_summary.dart';

/// Reads the public restaurant directory.
///
/// Row Level Security limits this to active, published restaurants and their
/// available menu items, so the client does not decide what is public.
abstract interface class RestaurantDirectoryRepository {
  Future<List<RestaurantSummary>> fetchPublishedRestaurants();
}

class SupabaseRestaurantDirectoryRepository
    implements RestaurantDirectoryRepository {
  const SupabaseRestaurantDirectoryRepository(this._client);

  final SupabaseClient _client;

  static const _directorySelect =
      'id, name, slug, description, address, '
      'menu_items(price, is_available)';

  @override
  Future<List<RestaurantSummary>> fetchPublishedRestaurants() async {
    final rows = await _client
        .from('restaurants')
        .select(_directorySelect)
        .order('name');

    final restaurants = <RestaurantSummary>[];
    for (final row in rows) {
      final restaurant = RestaurantSummary.fromJson(row);
      if (restaurant != null) restaurants.add(restaurant);
    }
    return restaurants;
  }
}
