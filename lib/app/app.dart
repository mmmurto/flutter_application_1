import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import 'app_router.dart';

class RestaurantPlatformApp extends StatelessWidget {
  const RestaurantPlatformApp({
    required this.config,
    this.initialRoute,
    super.key,
  });

  final AppConfig config;
  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    final router = AppRouter(config: config);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Restaurant Platform',
      theme: AppTheme.light,
      initialRoute: initialRoute,
      onGenerateRoute: router.onGenerateRoute,
    );
  }
}
