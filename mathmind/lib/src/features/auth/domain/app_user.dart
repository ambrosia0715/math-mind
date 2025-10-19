import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.isAnonymous,
  });

  factory AppUser.fromFirebaseUser(
    User user, {
    String? displayNameOverride,
  }) {
    return AppUser(
      id: user.uid,
      email: user.email,
      displayName: displayNameOverride ?? user.displayName,
      isAnonymous: user.isAnonymous,
    );
  }

  final String id;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  AppUser copyWith({
    String? email,
    String? displayName,
    bool? isAnonymous,
  }) {
    return AppUser(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}
