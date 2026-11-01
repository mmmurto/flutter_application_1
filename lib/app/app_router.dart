import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../features/customer/presentation/customer_entry_page.dart';
import '../features/menu/presentation/restaurant_menu_page.dart';
import '../features/staff/presentation/staff_access_page.dart';

abstract final class AppRoutes {
  static const customer = '/';
  static const owner = '/owner';
  static const kitchen = '/kitchen';
}

class AppRouter {
  const AppRouter({required this.config});
  final AppConfig config;

  Route<void> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? AppRoutes.customer);
    if (uri == null) {
      return _page(const CustomerEntryPage(), settings);
    }
    if (uri.path == AppRoutes.owner) {
      return _page(const StaffAccessPage(area: StaffArea.owner), settings);
    }
    if (uri.path == AppRoutes.kitchen) {
      return _page(const StaffAccessPage(area: StaffArea.kitchen), settings);
    }

    final segments = uri.pathSegments;
    if (segments.length == 4 &&
        segments[0] == 'r' &&
        segments[2] == 'table' &&
        segments[1].isNotEmpty &&
        segments[3].isNotEmpty) {
      return _page(
        RestaurantMenuPage(
          restaurantSlug: segments[1],
          tableToken: segments[3],
          backendConfigured: config.backendConfigured,
        ),
        settings,
      );
    }
    return _page(const CustomerEntryPage(), settings);
  }

  MaterialPageRoute<void> _page(Widget child, RouteSettings settings) =>
      MaterialPageRoute<void>(builder: (_) => child, settings: settings);
}
