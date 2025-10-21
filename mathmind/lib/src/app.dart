import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/config/app_env.dart';
import 'core/services/ai_content_service.dart';
import 'core/services/daily_limit_storage.dart';
import 'core/services/details_limit_storage.dart';
import 'core/services/lesson_history_service.dart';
import 'core/services/math_expression_service.dart';
import 'core/services/speech_service.dart';
import 'core/services/subscription_service.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/dashboard/presentation/dashboard_shell.dart';
import 'features/lessons/application/lesson_session_provider.dart';
import 'features/retention/application/retention_provider.dart';
import 'features/retention/services/retention_service.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/subscription/application/subscription_provider.dart';
import 'l10n/app_localizations.dart';
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
          create: (_) => MathExpressionService(),
          dispose: (_, service) {
            unawaited(service.dispose());
          },
        ),
        Provider(create: (_) => DailyLimitStorage()),
        Provider(create: (_) => DetailsLimitStorage()),
        Provider(
          create: (context) =>
              RetentionService(context.read<LessonHistoryService>()),
        ),
        Provider(create: (_) => SubscriptionService(env)),
        ChangeNotifierProvider(
          create: (context) => SubscriptionProvider(
            service: context.read<SubscriptionService>(),
            dailyLimitStorage: context.read<DailyLimitStorage>(),
            detailsLimitStorage: context.read<DetailsLimitStorage>(),
            authProvider: context.read<AuthProvider>(),
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
        locale: const Locale('ko'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: _buildTheme(),
        initialRoute: SplashScreen.routeName,
        onGenerateRoute: AppRouter.onGenerateRoute,
        routes: {
          DashboardShell.routeName: (_) => const DashboardShell(),
          AuthScreen.routeName: (_) => const AuthScreen(),
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    // 개념 위주 학습에 최적화된 색상 팔레트
    const primaryColor = Color(0xFF2C3E85); // 깊은 네이비 블루 - 신뢰감, 학술적
    const accentColor = Color(0xFF5B7FD4); // 밝은 블루 - 강조 요소
    const backgroundColor = Color(0xFFF8F9FC); // 부드러운 화이트 - 눈의 피로 감소
    const surfaceColor = Color(0xFFFFFFFF); // 순수 화이트 - 카드 배경
    const textPrimary = Color(0xFF1A1F36); // 진한 그레이 - 본문
    const textSecondary = Color(0xFF6B7280); // 중간 그레이 - 부가 정보

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        brightness: Brightness.light,
      ),
      fontFamily: 'Pretendard', // 한글 가독성 우수
    );

    return base.copyWith(
      scaffoldBackgroundColor: backgroundColor,

      // AppBar - 깔끔하고 최소한의 디자인
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        foregroundColor: textPrimary,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
      ),

      // Card - 개념 블록을 나타내는 깔끔한 카드
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input - 학습 입력에 집중할 수 있는 디자인
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Button - 명확한 행동 유도
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),

      // Chip - 개념 태그 표현
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xFFF3F4F6),
        selectedColor: accentColor.withOpacity(0.1),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide.none,
        ),
      ),

      // Typography - 수학 개념 표현에 최적화
      textTheme: base.textTheme.copyWith(
        // 제목
        titleLarge: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.3,
          letterSpacing: -0.5,
        ),
        titleMedium: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.4,
          letterSpacing: -0.3,
        ),
        titleSmall: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.4,
          letterSpacing: -0.2,
        ),
        // 본문
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.6,
          letterSpacing: -0.1,
        ),
        bodyMedium: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.6,
          letterSpacing: -0.1,
        ),
        bodySmall: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        // 라벨
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.1,
        ),
        labelMedium: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),

      // Divider - 개념 구분
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
        space: 24,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentColor,
      ),
    );
  }
}
