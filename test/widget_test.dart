import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

const _unconfigured = AppConfig(supabaseUrl: '', supabasePublishableKey: '');

void main() {
  testWidgets('customer entry does not expose staff navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const RestaurantPlatformApp(config: _unconfigured));
    expect(find.text('Open a restaurant menu'), findsOneWidget);
    expect(find.text('Restaurant management'), findsNothing);
    expect(find.text('Kitchen access'), findsNothing);
  });

  testWidgets('owner route is protected by a staff access boundary', (
    tester,
  ) async {
    await tester.pumpWidget(
      const RestaurantPlatformApp(
        config: _unconfigured,
        initialRoute: '/owner',
      ),
    );
    expect(find.text('Restaurant management'), findsOneWidget);
    expect(
      find.text(
        'A verified staff account and restaurant permission are required.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('QR route fails closed when backend is not configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      const RestaurantPlatformApp(
        config: _unconfigured,
        initialRoute: '/r/restaurant/table/token',
      ),
    );
    expect(find.text('Service is not configured'), findsOneWidget);
  });
}
