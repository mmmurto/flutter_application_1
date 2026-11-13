import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/config/app_config.dart';
import 'package:flutter_application_1/features/menu/data/menu_repository.dart';
import 'package:flutter_application_1/features/menu/domain/restaurant_menu.dart';
import 'package:flutter_test/flutter_test.dart';

const _configured = AppConfig(
  supabaseUrl: 'http://127.0.0.1:54321',
  supabasePublishableKey: 'test-publishable-key',
);

class _FakeMenuRepository implements MenuRepository {
  _FakeMenuRepository(this._handler);

  final Future<RestaurantMenu?> Function(String slug) _handler;
  int calls = 0;
  String? lastSlug;

  @override
  Future<RestaurantMenu?> fetchPublishedMenu(String slug) {
    calls++;
    lastSlug = slug;
    return _handler(slug);
  }
}

RestaurantMenu _menu() => const RestaurantMenu(
  name: 'Approved Test Restaurant',
  slug: 'approved-test-restaurant',
  description: 'Kitchen approved by the owner for preview.',
  address: '28 May, Baku',
  categories: [
    MenuCategory(
      name: 'Starters',
      items: [
        MenuItem(name: 'Dolma', description: 'Grape leaves', price: 7.5),
        MenuItem(
          name: 'Spicy bread',
          price: 2,
          isSpicy: true,
          isVegetarian: true,
        ),
      ],
    ),
    MenuCategory(name: 'Empty category', items: []),
  ],
);

Widget _app(MenuRepository? repository) => RestaurantPlatformApp(
  config: _configured,
  initialRoute: '/r/approved-test-restaurant/table/qr-token',
  menuRepository: repository,
);

void main() {
  testWidgets('published menu renders categories, items, and AZN prices', (
    tester,
  ) async {
    final repository = _FakeMenuRepository((_) async => _menu());
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(repository.lastSlug, 'approved-test-restaurant');
    expect(repository.calls, 1, reason: 'a QR deep link mounts one page');
    expect(find.text('Approved Test Restaurant'), findsOneWidget);
    expect(find.text('Starters'), findsOneWidget);
    expect(find.text('Dolma'), findsOneWidget);
    expect(find.text('7.50 \u20BC'), findsOneWidget);
    expect(find.text('2.00 \u20BC'), findsOneWidget);
    expect(find.text('Vegetarian · Spicy'), findsOneWidget);
    expect(find.text('Empty category'), findsNothing);
    expect(
      find.textContaining('Ordering and payment at the table'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a missing or unpublished menu stays closed with a clear message',
    (tester) async {
      final repository = _FakeMenuRepository((_) async => null);
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      expect(find.text('Menu unavailable'), findsOneWidget);
      expect(
        find.text('No verified, published menu was found for this QR code.'),
        findsOneWidget,
      );
      expect(find.text('Dolma'), findsNothing);
    },
  );

  testWidgets('a failed read shows an error and retry reloads the menu', (
    tester,
  ) async {
    var shouldFail = true;
    final repository = _FakeMenuRepository((_) async {
      if (shouldFail) throw Exception('offline');
      return _menu();
    });

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Menu could not be loaded'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(find.text('Approved Test Restaurant'), findsOneWidget);
    expect(find.text('Menu could not be loaded'), findsNothing);
  });

  test('menu parsing accepts the verified PostgREST response shape', () {
    // Captured from the local stack with the anon key: a published restaurant
    // exposing only its available items. Draft restaurants return no row.
    final menu = RestaurantMenu.fromJson({
      'id': '90000000-0000-0000-0000-000000000001',
      'name': 'E2E Approved Fixture',
      'slug': 'e2e-check',
      'description': 'Temporary verification row.',
      'address': 'Baku',
      'phone': null,
      'menu_categories': [
        {
          'name': 'Starters',
          'sort_order': 1,
          'menu_items': [
            {
              'name': 'Dolma',
              'price': 7.50,
              'is_spicy': false,
              'sort_order': 1,
              'description': 'Grape leaves',
              'is_available': true,
              'is_vegetarian': true,
            },
          ],
        },
      ],
    });

    expect(menu, isNotNull);
    expect(menu!.name, 'E2E Approved Fixture');
    final item = menu.categories.single.items.single;
    expect(item.name, 'Dolma');
    expect(item.price, 7.5);
    expect(item.formattedPrice, '7.50 \u20BC');
    expect(item.isVegetarian, isTrue);
    expect(item.isSpicy, isFalse);
  });

  test('menu parsing tolerates string prices and skips malformed rows', () {
    final menu = RestaurantMenu.fromJson({
      'name': 'Approved Test Restaurant',
      'slug': 'approved-test-restaurant',
      'menu_categories': [
        {
          'name': 'Starters',
          'sort_order': 2,
          'menu_items': [
            {'name': 'Dolma', 'price': '7.50', 'is_vegetarian': true},
            {'name': 'No price'},
            {'name': '', 'price': 1},
            {'name': 'Hidden item', 'price': 1, 'is_available': false},
          ],
        },
        {
          'name': 'Mains',
          'sort_order': 1,
          'menu_items': [
            {'name': 'Pilaf', 'price': 12},
          ],
        },
        {'name': null, 'menu_items': []},
      ],
    });

    expect(menu, isNotNull);
    expect(menu!.categories.map((category) => category.name), [
      'Mains',
      'Starters',
    ]);
    expect(menu.categories.last.items.single.name, 'Dolma');
    expect(menu.categories.last.items.single.price, 7.5);
    expect(menu.categories.last.items.single.isVegetarian, isTrue);
    expect(menu.hasItems, isTrue);
  });
}
