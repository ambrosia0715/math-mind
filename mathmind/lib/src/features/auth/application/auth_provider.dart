import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/app_user.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    _authSubscription = _firebaseAuth.authStateChanges().listen(
      _onAuthStateChanged,
    );
  }

  final FirebaseAuth _firebaseAuth;
  StreamSubscription<User?>? _authSubscription;

  AppUser? _currentUser;
  AuthStatus _status = AuthStatus.initial;

  AppUser? get currentUser => _currentUser;
  AuthStatus get status => _status;

  bool get isSignedIn => _currentUser != null;

  Future<void> ensureSignedIn() async {
    if (_firebaseAuth.currentUser != null) {
      return;
    }

    try {
      await _firebaseAuth.signInAnonymously();
    } on FirebaseAuthException catch (error) {
      debugPrint('Anonymous sign-in failed: $error');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  void _onAuthStateChanged(User? firebaseUser) {
    if (firebaseUser == null) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    } else {
      _currentUser = AppUser.fromFirebaseUser(firebaseUser);
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
