import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/config/app_config.dart';
import 'package:flutter_application_1/features/discovery/data/restaurant_directory_repository.dart';
import 'package:flutter_application_1/features/discovery/domain/restaurant_summary.dart';
import 'package:flutter_application_1/features/menu/data/menu_repository.dart';
import 'package:flutter_application_1/features/menu/domain/directions.dart';
import 'package:flutter_application_1/features/menu/domain/restaurant_menu.dart';
import 'package:flutter_test/flutter_test.dart';

const _configured = AppConfig(
  supabaseUrl: 'http://127.0.0.1:54321',
  supabasePublishableKey: 'test-publishable-key',
);

class _FakeDirectory implements RestaurantDirectoryRepository {
  _FakeDirectory(this._rows);

  final List<RestaurantSummary> _rows;
  int calls = 0;

  @override
  Future<List<RestaurantSummary>> fetchPublishedRestaurants() async {
    calls++;
    return _rows;
  }
}

class _FakeMenuRepository implements MenuRepository {
  _FakeMenuRepository(this._handler);

  final Future<RestaurantMenu?> Function(String slug) _handler;

  @override
  Future<RestaurantMenu?> fetchPublishedMenu(String slug) => _handler(slug);
}

const _restaurants = [
  RestaurantSummary(
    name: 'Budget Bistro',
    slug: 'budget-bistro',
    description: 'Everyday dishes',
    address: '28 May, Baku',
    fromPrice: 4.5,
  ),
  RestaurantSummary(
    name: 'Mid Range Kitchen',
    slug: 'mid-range-kitchen',
    address: 'Nizami Street, Baku',
    fromPrice: 12,
  ),
  RestaurantSummary(
    name: 'Fine Dining Place',
    slug: 'fine-dining-place',
    description: 'Tasting menu',
    fromPrice: 30,
  ),
  RestaurantSummary(
    name: 'Menu Pending Restaurant',
    slug: 'menu-pending',
    description: 'Approved, menu not published yet',
  ),
];

Widget _app({RestaurantDirectoryRepository? directory, MenuRepository? menu}) =>
    RestaurantPlatformApp(
      config: _configured,
      initialRoute: '/',
      directoryRepository: directory,
      menuRepository: menu,
    );

void main() {
  testWidgets('directory lists approved restaurants with from prices', (
    tester,
  ) async {
    await tester.pumpWidget(_app(directory: _FakeDirectory(_restaurants)));
    await tester.pumpAndSettle();

    expect(find.text('Find a restaurant'), findsOneWidget);
    expect(find.text('Budget Bistro'), findsOneWidget);
    expect(find.text('from 4.50 \u20BC'), findsOneWidget);
    expect(find.text('Menu coming soon'), findsOneWidget);
    expect(find.text('Restaurant management'), findsNothing);
    expect(find.text('Kitchen access'), findsNothing);
  });

  testWidgets('search narrows the list by name', (tester) async {
    await tester.pumpWidget(_app(directory: _FakeDirectory(_restaurants)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'bistro');
    await tester.pump();

    expect(find.text('Budget Bistro'), findsOneWidget);
    expect(find.text('Mid Range Kitchen'), findsNothing);
    expect(find.text('Fine Dining Place'), findsNothing);
  });

  testWidgets('budget filter keeps restaurants with a dish in budget', (
    tester,
  ) async {
    await tester.pumpWidget(_app(directory: _FakeDirectory(_restaurants)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Up to 10 \u20BC'));
    await tester.pumpAndSettle();

    expect(find.text('Budget Bistro'), findsOneWidget);
    expect(find.text('Mid Range Kitchen'), findsNothing);
    expect(find.text('Fine Dining Place'), findsNothing);
    // A restaurant without a published price cannot match a budget.
    expect(find.text('Menu Pending Restaurant'), findsNothing);
  });

  testWidgets('an empty directory explains why nothing is listed', (
    tester,
  ) async {
    await tester.pumpWidget(_app(directory: _FakeDirectory(const [])));
    await tester.pumpAndSettle();

    expect(find.text('No approved restaurants yet'), findsOneWidget);
    expect(find.text('Budget Bistro'), findsNothing);
  });

  testWidgets('an unconfigured backend does not pretend to have a directory', (
    tester,
  ) async {
    await tester.pumpWidget(
      const RestaurantPlatformApp(
        config: AppConfig(supabaseUrl: '', supabasePublishableKey: ''),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Service is not configured'), findsOneWidget);
  });

  testWidgets('tapping a restaurant opens its public menu', (tester) async {
    final menu = _FakeMenuRepository(
      (slug) async => RestaurantMenu(
        name: 'Budget Bistro',
        slug: slug,
        address: '28 May, Baku',
        categories: const [
          MenuCategory(
            name: 'Dishes',
            items: [MenuItem(name: 'Plov', price: 4.5)],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      _app(directory: _FakeDirectory(_restaurants), menu: menu),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Budget Bistro'));
    await tester.pumpAndSettle();

    expect(find.text('Plov'), findsOneWidget);
    expect(find.text('4.50 \u20BC'), findsOneWidget);
    expect(find.text('Google Maps'), findsOneWidget);
    expect(find.text('Waze'), findsOneWidget);
  });

  test('directory parsing uses the cheapest available published dish', () {
    // Captured from the local stack with the anon key: the sold-out dish is
    // filtered by RLS, so only available prices reach the client.
    final restaurant = RestaurantSummary.fromJson({
      'id': '91000000-0000-0000-0000-000000000001',
      'name': 'Directory Fixture',
      'slug': 'directory-fixture',
      'description': 'Temporary row.',
      'address': 'Nizami Street, Baku',
      'menu_items': [
        {'price': 4.50, 'is_available': true},
        {'price': 19.00, 'is_available': true},
      ],
    });

    expect(restaurant, isNotNull);
    expect(restaurant!.fromPrice, 4.5);
    expect(restaurant.formattedFromPrice, 'from 4.50 \u20BC');
    expect(restaurant.hasPublishedPrices, isTrue);
  });

  test('filterRestaurants sorts by price and keeps unpriced menus last', () {
    final filtered = filterRestaurants(_restaurants);

    expect(filtered.map((restaurant) => restaurant.slug), [
      'budget-bistro',
      'mid-range-kitchen',
      'fine-dining-place',
      'menu-pending',
    ]);
    expect(
      filterRestaurants(
        _restaurants,
        maxPrice: 10,
      ).map((restaurant) => restaurant.slug),
      ['budget-bistro'],
    );
    expect(
      filterRestaurants(_restaurants, query: 'NIZAMI').single.slug,
      'mid-range-kitchen',
    );
  });

  test('directions links are provider-ready and encode the address', () {
    final query = directionsQuery(
      name: 'Budget Bistro',
      address: '28 May, Baku',
    );

    final maps = googleMapsDirectionsUri(query);
    expect(maps.host, 'www.google.com');
    expect(maps.path, '/maps/search/');
    expect(maps.queryParameters['query'], 'Budget Bistro, 28 May, Baku');

    final waze = wazeDirectionsUri(query);
    expect(waze.host, 'waze.com');
    expect(waze.queryParameters['q'], 'Budget Bistro, 28 May, Baku');

    expect(directionsQuery(name: 'Only Name'), 'Only Name');
  });
}
