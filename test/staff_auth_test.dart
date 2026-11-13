import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/config/app_config.dart';
import 'package:flutter_application_1/features/auth/data/auth_repository.dart';
import 'package:flutter_application_1/features/auth/domain/app_user.dart';
import 'package:flutter_application_1/features/auth/presentation/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const _configured = AppConfig(
  supabaseUrl: 'http://127.0.0.1:54321',
  supabasePublishableKey: 'test-publishable-key',
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.failureMessage, AppUser? initialUser})
    : _user = initialUser;

  final String? failureMessage;
  final _changes = StreamController<AppUser?>.broadcast();

  AppUser? _user;
  int signOutCalls = 0;
  String? lastEmail;
  String? lastPassword;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get userChanges => _changes.stream;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;
    final failure = failureMessage;
    if (failure != null) throw StaffAuthException(failure);
    _user = AppUser(id: 'staff-1', email: email.trim());
    _changes.add(_user);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _user = null;
    _changes.add(null);
  }

  void restoreSession(AppUser user) {
    _user = user;
    _changes.add(user);
  }

  Future<void> close() => _changes.close();
}

Widget _app(AuthController? controller, {String route = '/owner'}) =>
    RestaurantPlatformApp(
      config: _configured,
      initialRoute: route,
      authController: controller,
    );

AuthController _controller(_FakeAuthRepository repository) {
  final controller = AuthController(repository);
  addTearDown(controller.dispose);
  addTearDown(repository.close);
  return controller;
}

Future<void> _fillCredentials(
  WidgetTester tester, {
  String email = 'staff@example.test',
  String password = 'secret-pass',
}) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), password);
}

void main() {
  testWidgets('an unconfigured backend keeps the staff boundary closed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const RestaurantPlatformApp(
        config: AppConfig(supabaseUrl: '', supabasePublishableKey: ''),
        initialRoute: '/owner',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'A verified staff account and restaurant permission are required.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets('staff see a sign-in form and no self-registration', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_app(_controller(repository)));
    await tester.pumpAndSettle();

    expect(find.text('Restaurant sign in'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.textContaining('no public sign-up'), findsOneWidget);
  });

  testWidgets('empty credentials are rejected before any request', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_app(_controller(repository)));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(repository.lastEmail, isNull);
  });

  testWidgets('valid credentials sign the staff member in', (tester) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_app(_controller(repository)));
    await tester.pumpAndSettle();

    await _fillCredentials(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(repository.lastEmail, 'staff@example.test');
    expect(repository.lastPassword, 'secret-pass');
    expect(find.text('Signed in as staff@example.test.'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('a rejected sign-in shows the provider message', (tester) async {
    final repository = _FakeAuthRepository(
      failureMessage: 'Invalid login credentials',
    );
    await tester.pumpWidget(_app(_controller(repository)));
    await tester.pumpAndSettle();

    await _fillCredentials(tester, password: 'wrong');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid login credentials'), findsOneWidget);
    expect(find.text('Restaurant sign in'), findsOneWidget);
  });

  testWidgets('signing out returns to the form and clears the session', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_app(_controller(repository)));
    await tester.pumpAndSettle();

    await _fillCredentials(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(repository.signOutCalls, 1);
    expect(find.text('Restaurant sign in'), findsOneWidget);
    expect(find.text('Signed in as staff@example.test.'), findsNothing);
  });

  testWidgets('a restored session opens the kitchen surface directly', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    final controller = _controller(repository);
    await tester.pumpWidget(_app(controller, route: '/kitchen'));
    await tester.pumpAndSettle();

    expect(find.text('Kitchen sign in'), findsOneWidget);

    repository.restoreSession(
      const AppUser(id: 'staff-1', email: 'chef@example.test'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('Signed in as chef@example.test.'), findsOneWidget);
  });

  test('controller exposes the restored user without rebuilding', () {
    final repository = _FakeAuthRepository(
      initialUser: const AppUser(id: 'staff-1', email: 'owner@example.test'),
    );
    final controller = _controller(repository);

    expect(controller.isSignedIn, isTrue);
    expect(controller.user?.email, 'owner@example.test');
  });
}
