import 'package:flutter/material.dart';

import '../features/auth/presentation/auth_screen.dart';
import '../features/dashboard/presentation/dashboard_shell.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/lessons/presentation/lesson_screen.dart';
import '../features/retention/presentation/retention_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case DashboardShell.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const DashboardShell(),
          settings: settings,
        );
      case AuthScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const AuthScreen(),
          settings: settings,
        );
      case LessonScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const LessonScreen(),
          settings: settings,
        );
      case RetentionScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const RetentionScreen(),
          settings: settings,
        );
      case HomeScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }
}
