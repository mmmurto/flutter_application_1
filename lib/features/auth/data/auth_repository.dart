import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_user.dart';

/// A sign-in failure with a message that is safe to show to staff.
class StaffAuthException implements Exception {
  const StaffAuthException(this.message);

  final String message;

  @override
  String toString() => 'StaffAuthException: $message';
}

/// Password sign-in for restaurant staff.
///
/// Accounts are created by the platform or the restaurant owner; the app never
/// offers self-registration, so a stranger cannot grant themselves a staff
/// account.
abstract interface class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> get userChanges;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  AppUser? get currentUser => _toAppUser(_client.auth.currentUser);

  @override
  Stream<AppUser?> get userChanges => _client.auth.onAuthStateChange.map(
    (state) => _toAppUser(state.session?.user),
  );

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      throw StaffAuthException(error.message);
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email);
  }
}
