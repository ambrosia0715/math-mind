import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.isAnonymous,
    this.username,
  });

  factory AppUser.fromFirebaseUser(
    User user, {
    String? displayNameOverride,
    String? username,
  }) {
    return AppUser(
      id: user.uid,
      email: user.email,
      displayName: displayNameOverride ?? user.displayName,
      isAnonymous: user.isAnonymous,
      username: username,
    );
  }

  final String id;
  final String? email;
  final String? displayName;
  final bool isAnonymous;
  final String? username;

  AppUser copyWith({
    String? email,
    String? displayName,
    bool? isAnonymous,
    String? username,
  }) {
    return AppUser(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      username: username ?? this.username,
    );
  }
}
