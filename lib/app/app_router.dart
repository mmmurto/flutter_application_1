import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/customer/presentation/customer_entry_page.dart';
import '../features/discovery/data/restaurant_directory_repository.dart';
import '../features/menu/data/menu_repository.dart';
import '../features/menu/presentation/restaurant_menu_page.dart';
import '../features/staff/presentation/staff_access_page.dart';

abstract final class AppRoutes {
  static const customer = '/';
  static const owner = '/owner';
  static const kitchen = '/kitchen';

  /// Menu without table context: `/r/<restaurantSlug>`.
  static String restaurantMenu(String slug) => '/r/$slug';

  /// Table menu from a printed QR code: `/r/<restaurantSlug>/table/<qrToken>`.
  static String tableMenu(String slug, String token) => '/r/$slug/table/$token';
}

class AppRouter {
  const AppRouter({
    required this.config,
    this.menuRepository,
    this.directoryRepository,
    this.authController,
  });

  final AppConfig config;
  final MenuRepository? menuRepository;
  final RestaurantDirectoryRepository? directoryRepository;
  final AuthController? authController;

  /// One route for the whole deep link.
  ///
  /// The Navigator's default behaviour splits an initial route like
  /// `/r/<slug>/table/<token>` into `/r`, `/r/<slug>`, ... and pushes each one,
  /// which would mount intermediate screens (and re-run their reads) before the
  /// requested page. A printed QR link must land on exactly one page.
  List<Route<void>> onGenerateInitialRoutes(String initialRoute) => [
    onGenerateRoute(RouteSettings(name: initialRoute)),
  ];

  Route<void> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? AppRoutes.customer);
    if (uri == null) {
      return _page(
        const CustomerEntryPage(directoryRepository: null),
        settings,
      );
    }
    if (uri.path == AppRoutes.owner) {
      return _page(
        StaffAccessPage(area: StaffArea.owner, authController: authController),
        settings,
      );
    }
    if (uri.path == AppRoutes.kitchen) {
      return _page(
        StaffAccessPage(
          area: StaffArea.kitchen,
          authController: authController,
        ),
        settings,
      );
    }

    final segments = uri.pathSegments;
    if (segments.isEmpty) {
      return _page(
        CustomerEntryPage(directoryRepository: directoryRepository),
        settings,
      );
    }

    // `/r/<slug>` — public menu from discovery.
    if (segments.length == 2 && segments[0] == 'r' && segments[1].isNotEmpty) {
      return _page(
        RestaurantMenuPage(
          restaurantSlug: segments[1],
          tableToken: null,
          menuRepository: menuRepository,
        ),
        settings,
      );
    }

    // `/r/<slug>/table/<qrToken>` — menu from a table QR code.
    if (segments.length == 4 &&
        segments[0] == 'r' &&
        segments[2] == 'table' &&
        segments[1].isNotEmpty &&
        segments[3].isNotEmpty) {
      return _page(
        RestaurantMenuPage(
          restaurantSlug: segments[1],
          tableToken: segments[3],
          menuRepository: menuRepository,
        ),
        settings,
      );
    }

    return _page(
      CustomerEntryPage(directoryRepository: directoryRepository),
      settings,
    );
  }

  MaterialPageRoute<void> _page(Widget child, RouteSettings settings) =>
      MaterialPageRoute<void>(builder: (_) => child, settings: settings);
}
