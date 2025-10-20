import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:mathmind/src/l10n/app_localizations.dart';
import 'package:mathmind/src/features/lessons/presentation/lesson_screen_clean.dart';

void main() {
  testWidgets('LessonScreen builds without exceptions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ko'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: LessonScreen(),
      ),
    );
    await tester.pumpAndSettle();
    // App bar exists
    expect(find.byType(AppBar), findsOneWidget);
    // Difficulty label appears
    expect(find.textContaining('난이도'), findsOneWidget);
  });
}
