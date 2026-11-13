import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'features/discovery/data/restaurant_directory_repository.dart';
import 'features/menu/data/menu_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  MenuRepository? menuRepository;
  RestaurantDirectoryRepository? directoryRepository;
  if (config.backendConfigured) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );
    final client = Supabase.instance.client;
    menuRepository = SupabaseMenuRepository(client);
    directoryRepository = SupabaseRestaurantDirectoryRepository(client);
  }

  runApp(
    RestaurantPlatformApp(
      config: config,
      menuRepository: menuRepository,
      directoryRepository: directoryRepository,
    ),
  );
}
