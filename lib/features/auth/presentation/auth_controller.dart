import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../domain/app_user.dart';

/// Holds the signed-in staff session for the UI.
///
/// This is presentation state only. It never decides access to data; RLS and
/// restaurant memberships do that on every request.
class AuthController extends ChangeNotifier {
  AuthController(this._repository) : _user = _repository.currentUser {
    _subscription = _repository.userChanges.listen((user) {
      if (user == _user) return;
      _user = user;
      notifyListeners();
    });
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _subscription;

  AppUser? _user;
  bool _isBusy = false;
  String? _errorMessage;

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  /// Signs in a staff account. Returns `true` when the credentials were accepted.
  Future<bool> signIn({required String email, required String password}) async {
    if (_isBusy) return false;
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      _user = _repository.currentUser ?? _user;
      return true;
    } on StaffAuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Sign-in failed. Check your connection and try again.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_isBusy) return;
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signOut();
      _user = null;
    } catch (_) {
      _errorMessage = 'Sign-out failed. Try again.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
