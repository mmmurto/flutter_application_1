/// Route names and builders shared by the router and screens.
abstract final class AppRoutes {
  static const customer = '/';
  static const owner = '/owner';
  static const kitchen = '/kitchen';

  /// Menu without table context: `/r/<restaurantSlug>`.
  static String restaurantMenu(String slug) => '/r/$slug';

  /// Table menu from a printed QR code: `/r/<restaurantSlug>/table/<qrToken>`.
  static String tableMenu(String slug, String token) => '/r/$slug/table/$token';

  /// Authenticated restaurant workspace: `/owner/menu/<restaurantSlug>`.
  static String ownerMenu(String slug) => '/owner/menu/$slug';
}
