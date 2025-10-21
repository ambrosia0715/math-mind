import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/app_user.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']) {
    _authSubscription = _firebaseAuth.authStateChanges().listen(
      _onAuthStateChanged,
    );
  }

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  StreamSubscription<User?>? _authSubscription;

  AppUser? _currentUser;
  AuthStatus _status = AuthStatus.initial;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  AuthStatus get status => _status;
  bool get isSignedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> ensureSignedIn() async {
    if (_status != AuthStatus.initial) {
      return;
    }

    final existingUser = _firebaseAuth.currentUser;
    if (existingUser != null) {
      await _hydrateUser(existingUser);
      return;
    }

    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() => _setError(null);

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();

    if (trimmedName.isEmpty || trimmedEmail.isEmpty || password.isEmpty) {
      const message = '모든 필드를 입력해주세요.';
      _setError(message);
      throw AuthFailure(message);
    }

    _setLoading(true);
    _setError(null);

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        const message = '계정 생성에 실패했습니다. 잠시 후 다시 시도해주세요.';
        _setError(message);
        throw AuthFailure(message);
      }

      await firebaseUser.updateDisplayName(trimmedName);
      await firebaseUser.reload();

      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'email': trimmedEmail,
        'name': trimmedName,
        'provider': 'password',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _setError(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      final message = _mapFirebaseAuthError(error);
      debugPrint('Email sign-up failed: $error\n$stackTrace');
      _setError(message);
      throw AuthFailure(message);
    } on PlatformException catch (error, stackTrace) {
      const message = '디바이스에서 인증을 처리하지 못했습니다.';
      debugPrint('Platform error during sign-up: $error\n$stackTrace');
      _setError(message);
      throw AuthFailure(message);
    } on AuthFailure {
      rethrow;
    } catch (error, stackTrace) {
      const message = '예상치 못한 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      debugPrint('Unknown error during sign-up: $error\n$stackTrace');
      _setError(message);
      throw AuthFailure(message);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error, stackTrace) {
      final message = _mapFirebaseAuthError(error);
      debugPrint('Email sign-in failed: $error\n$stackTrace');
      _setError(message);
      throw AuthFailure(message);
    } on PlatformException catch (error, stackTrace) {
      const message = '디바이스에서 인증을 처리하지 못했습니다.';
      debugPrint('Platform error during sign-in: $error\n$stackTrace');
      _setError(message);
      throw AuthFailure(message);
    } catch (error, stackTrace) {
      const message = '예상치 못한 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      debugPrint('Unknown error during email sign-in: $error\n$stackTrace');
      _setError(message);
      throw AuthFailure(message);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);

    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        await _googleSignIn.signOut();
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          const message = '로그인이 취소되었습니다.';
          _setError(message);
          throw AuthFailure(message);
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _firebaseAuth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (error, stackTrace) {
      final message = _mapFirebaseAuthError(error);
      debugPrint('Google sign-in failed: $error\n$stackTrace');
      _setError(message);
      throw AuthFailure(message);
    } on PlatformException catch (error, stackTrace) {
      const message = 'Google 로그인 중 오류가 발생했습니다.';
      debugPrint('Platform error during Google sign-in: $error\n$stackTrace');
      _setError(message);
      throw AuthFailure(message);
    } catch (error, stackTrace) {
      const message = 'Google 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.';
      debugPrint('Unknown error during Google sign-in: $error\n$stackTrace');
      _setError(message);
      throw AuthFailure(message);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (error, stackTrace) {
      debugPrint('Sign-out failed: $error\n$stackTrace');
    }
  }

  void _onAuthStateChanged(User? firebaseUser) {
    if (firebaseUser == null) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    unawaited(_hydrateUser(firebaseUser));
  }

  Future<void> _hydrateUser(User firebaseUser) async {
    try {
      final docRef = _firestore.collection('users').doc(firebaseUser.uid);
      var snapshot = await docRef.get();

      if (!snapshot.exists) {
        final providerId = firebaseUser.providerData.isNotEmpty
            ? firebaseUser.providerData.first.providerId
            : (firebaseUser.isAnonymous ? 'anonymous' : 'firebase');
        await docRef.set({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email,
          'name': firebaseUser.displayName,
          'provider': providerId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        snapshot = await docRef.get();
      } else {
        await docRef.update({'updatedAt': FieldValue.serverTimestamp()});
      }

      final data = snapshot.data();
      final displayName =
          (data?['name'] as String?)?.trim() ?? firebaseUser.displayName;

      _currentUser = AppUser.fromFirebaseUser(
        firebaseUser,
        displayNameOverride: displayName,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to hydrate user profile: $error\n$stackTrace');
      _currentUser = AppUser.fromFirebaseUser(firebaseUser);
    }

    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    if (_errorMessage == message) {
      return;
    }
    _errorMessage = message;
    notifyListeners();
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '이메일 형식이 올바르지 않습니다.';
      case 'weak-password':
        return '비밀번호는 6자 이상이어야 합니다.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case 'account-exists-with-different-credential':
        return '다른 로그인 방식으로 이미 가입된 계정입니다.';
      case 'popup-closed-by-user':
        return '로그인 창이 닫혔습니다.';
      default:
        return '인증 중 오류가 발생했습니다. (${error.code})';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
