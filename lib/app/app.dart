import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../features/discovery/data/restaurant_directory_repository.dart';
import '../features/menu/data/menu_repository.dart';
import 'app_router.dart';

class RestaurantPlatformApp extends StatelessWidget {
  const RestaurantPlatformApp({
    required this.config,
    this.initialRoute,
    this.menuRepository,
    this.directoryRepository,
    super.key,
  });

  final AppConfig config;
  final String? initialRoute;
  final MenuRepository? menuRepository;
  final RestaurantDirectoryRepository? directoryRepository;

  @override
  Widget build(BuildContext context) {
    final router = AppRouter(
      config: config,
      menuRepository: menuRepository,
      directoryRepository: directoryRepository,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Restaurant Platform',
      theme: AppTheme.light,
      initialRoute: initialRoute,
      onGenerateRoute: router.onGenerateRoute,
      onGenerateInitialRoutes: router.onGenerateInitialRoutes,
    );
  }
}
