import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'src/app.dart';
import 'src/core/config/app_env.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _loadEnvironment();
  final env = AppEnv.fromDotEnv();

  await _initializeFirebase(env);

  _configureDeviceOrientation();

  runApp(MathMindApp(env: env));
}

Future<void> _loadEnvironment() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (error) {
    if (error is FileSystemException || error is FileNotFoundError) {
      await dotenv.load(fileName: '.env.example');
    } else {
      rethrow;
    }
  }
}

Future<void> _initializeFirebase(AppEnv env) async {
  try {
    final options = env.firebaseOptions;
    if (options != null) {
      await Firebase.initializeApp(options: options);
    } else {
      await Firebase.initializeApp();
    }
  } on FirebaseException catch (error, stackTrace) {
    log(
      'Firebase initialization failed: ${error.message}',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

void _configureDeviceOrientation() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}
