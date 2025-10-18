import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_env.dart';
import 'core/services/ai_content_service.dart';
import 'core/services/lesson_history_service.dart';
import 'core/services/speech_service.dart';
import 'core/services/subscription_service.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/dashboard/presentation/dashboard_shell.dart';
import 'features/lessons/application/lesson_session_provider.dart';
import 'features/retention/application/retention_provider.dart';
import 'features/retention/services/retention_service.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/subscription/application/subscription_provider.dart';
import 'navigation/app_router.dart';

class MathMindApp extends StatelessWidget {
  const MathMindApp({super.key, required this.env});

  final AppEnv env;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: env),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider(create: (_) => LessonHistoryService()),
        Provider(create: (_) => AiContentService(env)),
        Provider(create: (_) => SpeechService()),
        Provider(
          create: (context) =>
              RetentionService(context.read<LessonHistoryService>()),
        ),
        Provider(create: (_) => SubscriptionService(env)),
        ChangeNotifierProvider(
          create: (context) => SubscriptionProvider(
            service: context.read<SubscriptionService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => LessonSessionProvider(
            authProvider: context.read<AuthProvider>(),
            historyService: context.read<LessonHistoryService>(),
            aiContentService: context.read<AiContentService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => RetentionProvider(
            authProvider: context.read<AuthProvider>(),
            retentionService: context.read<RetentionService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'MathMind',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        initialRoute: SplashScreen.routeName,
        onGenerateRoute: AppRouter.onGenerateRoute,
        routes: {DashboardShell.routeName: (_) => const DashboardShell()},
      ),
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4A6CF7),
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF4F6FF),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: base.colorScheme.onSurface,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        border: const OutlineInputBorder(),
      ),
    );
  }
}
