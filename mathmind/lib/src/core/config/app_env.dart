import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv({
    required this.openAIApiKey,
    required this.firebaseOptions,
    required this.fcmServerKey,
    required this.googleCloudApiKey,
    required this.revenuecatKey,
  });

  factory AppEnv.fromDotEnv() {
    FirebaseOptions? options;
    try {
      options = _parseFirebaseOptions(dotenv.maybeGet('FIREBASE_CONFIG'));
    } catch (error, stackTrace) {
      log(
        'Failed to parse FIREBASE_CONFIG env variable',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return AppEnv(
      openAIApiKey: dotenv.maybeGet('OPENAI_API_KEY') ?? '',
      firebaseOptions: options,
      fcmServerKey: dotenv.maybeGet('FCM_SERVER_KEY'),
      googleCloudApiKey: dotenv.maybeGet('GOOGLE_CLOUD_API_KEY'),
      revenuecatKey: dotenv.maybeGet('REVENUECAT_KEY'),
    );
  }

  final String openAIApiKey;
  final FirebaseOptions? firebaseOptions;
  final String? fcmServerKey;
  final String? googleCloudApiKey;
  final String? revenuecatKey;

  bool get isDevelopment => kDebugMode;

  static FirebaseOptions? _parseFirebaseOptions(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final Map<String, dynamic> config = jsonDecode(raw) as Map<String, dynamic>;
    return FirebaseOptions(
      apiKey: config['apiKey'] as String,
      appId: config['appId'] as String,
      messagingSenderId: config['messagingSenderId'] as String,
      projectId: config['projectId'] as String,
      storageBucket: config['storageBucket'] as String?,
      authDomain: config['authDomain'] as String?,
      measurementId: config['measurementId'] as String?,
      databaseURL: config['databaseURL'] as String?,
    );
  }
}
