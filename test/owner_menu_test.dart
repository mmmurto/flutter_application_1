import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/config/app_config.dart';
import 'package:flutter_application_1/features/auth/data/auth_repository.dart';
import 'package:flutter_application_1/features/auth/domain/app_user.dart';
import 'package:flutter_application_1/features/auth/presentation/auth_controller.dart';
import 'package:flutter_application_1/features/owner/data/owner_menu_repository.dart';
import 'package:flutter_application_1/features/owner/domain/managed_menu.dart';
import 'package:flutter_application_1/features/staff/data/staff_restaurant_repository.dart';
import 'package:flutter_application_1/features/staff/domain/staff_restaurant.dart';
import 'package:flutter_test/flutter_test.dart';

const _configured = AppConfig(
  supabaseUrl: 'http://127.0.0.1:54321',
  supabasePublishableKey: 'test-publishable-key',
);

class _FakeAuth implements AuthRepository {
  _FakeAuth([this._user]);

  final _changes = StreamController<AppUser?>.broadcast();
  final AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get userChanges => _changes.stream;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}
}

class _FakeOwnerMenu implements OwnerMenuRepository {
  _FakeOwnerMenu(this._handler);

  final Future<ManagedMenu?> Function(String slug) _handler;
  int calls = 0;

  @override
  Future<ManagedMenu?> fetchManagedMenu(String restaurantSlug) {
    calls++;
    return _handler(restaurantSlug);
  }
}

class _FakeStaffRestaurants implements StaffRestaurantRepository {
  _FakeStaffRestaurants(this._rows);

  final List<StaffRestaurant> _rows;

  @override
  Future<List<StaffRestaurant>> fetchMyRestaurants() async => _rows;
}

ManagedMenu _menu() => ManagedMenu.fromJson({
  'id': '93000000-0000-0000-0000-000000000001',
  'name': 'Local Test Restaurant',
  'slug': 'local-test-restaurant',
  'publication_status': 'draft',
  'menu_categories': [
    {
      'id': '93000000-0000-0000-0000-000000000002',
      'name': 'Starters',
      'sort_order': 1,
      'is_active': true,
      'menu_items': [
        {
          'id': '93000000-0000-0000-0000-000000000003',
          'name': 'Dolma',
          'description': 'Grape leaves',
          'price': 7.5,
          'sort_order': 1,
          'is_available': true,
          'is_vegetarian': true,
          'is_spicy': false,
        },
        {
          'id': '93000000-0000-0000-0000-000000000004',
          'name': 'Sold out dish',
          'price': 3,
          'sort_order': 2,
          'is_available': false,
        },
      ],
    },
    {
      'id': '93000000-0000-0000-0000-000000000005',
      'name': 'Retired section',
      'sort_order': 2,
      'is_active': false,
      'menu_items': <Map<String, Object?>>[],
    },
  ],
})!;

Widget _app({
  required AuthController controller,
  required OwnerMenuRepository ownerMenu,
  List<StaffRestaurant> memberships = const [],
}) => RestaurantPlatformApp(
  config: _configured,
  initialRoute: '/owner/menu/local-test-restaurant',
  authController: controller,
  ownerMenuRepository: ownerMenu,
  staffRestaurantRepository: _FakeStaffRestaurants(memberships),
);

AuthController _controller({bool signedIn = true}) {
  final repository = _FakeAuth(
    signedIn ? const AppUser(id: 'staff-1', email: 'owner@example.test') : null,
  );
  final controller = AuthController(repository);
  addTearDown(controller.dispose);
  addTearDown(repository._changes.close);
  return controller;
}

void main() {
  testWidgets('owners see their own draft menu with hidden markers', (
    tester,
  ) async {
    final repository = _FakeOwnerMenu((_) async => _menu());
    await tester.pumpWidget(
      _app(controller: _controller(), ownerMenu: repository),
    );
    await tester.pumpAndSettle();

    expect(repository.calls, 1);
    expect(find.text('Local Test Restaurant'), findsOneWidget);
    expect(find.text('Not published yet'), findsOneWidget);
    expect(find.textContaining('1 hidden from guests'), findsOneWidget);
    expect(find.text('Dolma'), findsOneWidget);
    expect(find.text('7.50 \u20BC'), findsOneWidget);
    expect(find.text('Hidden from guests'), findsOneWidget);
    expect(find.text('Retired section'), findsOneWidget);
    expect(find.text('Hidden'), findsOneWidget);
    expect(find.textContaining('Editing is not available yet'), findsOneWidget);
  });

  testWidgets('a signed-out deep link keeps the sign-in guard', (tester) async {
    final repository = _FakeOwnerMenu((_) async => _menu());
    await tester.pumpWidget(
      _app(controller: _controller(signedIn: false), ownerMenu: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Restaurant sign in'), findsOneWidget);
    expect(repository.calls, 0);
  });

  testWidgets('a restaurant the account cannot see is not disclosed', (
    tester,
  ) async {
    final repository = _FakeOwnerMenu((_) async => null);
    await tester.pumpWidget(
      _app(controller: _controller(), ownerMenu: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('No access to this restaurant'), findsOneWidget);
    expect(find.text('Local Test Restaurant'), findsNothing);
  });

  testWidgets('a failed menu read offers a retry', (tester) async {
    var fail = true;
    final repository = _FakeOwnerMenu((_) async {
      if (fail) throw Exception('offline');
      return _menu();
    });
    await tester.pumpWidget(
      _app(controller: _controller(), ownerMenu: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Menu could not be loaded'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(find.text('Dolma'), findsOneWidget);
  });

  testWidgets('the staff home opens the restaurant workspace', (tester) async {
    final repository = _FakeOwnerMenu((_) async => _menu());
    const membership = StaffRestaurant(
      name: 'Local Test Restaurant',
      slug: 'local-test-restaurant',
      role: 'owner',
      publicationStatus: 'draft',
    );

    await tester.pumpWidget(
      RestaurantPlatformApp(
        config: _configured,
        initialRoute: '/owner',
        authController: _controller(),
        ownerMenuRepository: repository,
        staffRestaurantRepository: _FakeStaffRestaurants(const [membership]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Local Test Restaurant'));
    await tester.pumpAndSettle();

    expect(repository.calls, 1);
    expect(find.textContaining('Editing is not available yet'), findsOneWidget);
    expect(find.text('Owner · Not published yet'), findsNothing);
  });

  test('managed menu parsing keeps hidden items and counts them', () {
    final menu = _menu();

    expect(menu.categories.length, 2);
    expect(menu.categories.first.name, 'Starters');
    expect(menu.categories.first.items.length, 2);
    expect(menu.hiddenItemCount, 1);
    expect(menu.categories.last.isActive, isFalse);
    expect(menu.categories.last.items, isEmpty);
    expect(menu.isPublished, isFalse);
  });
}
