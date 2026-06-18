import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_strings.dart';
import 'screens/auth_screen.dart';
import 'screens/shell_screen.dart';
import 'services/firebase_service.dart';
import 'theme.dart';

class FamilyPlannerApp extends StatefulWidget {
  const FamilyPlannerApp({super.key});

  @override
  State<FamilyPlannerApp> createState() => _FamilyPlannerAppState();
}

class _FamilyPlannerAppState extends State<FamilyPlannerApp> {
  final authRepository = AuthRepository();
  final familyRepository = FamilyRepository();
  Locale locale = const Locale('da');
  ThemeMode themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Family Planner',
      locale: locale,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      localizationsDelegates: const [
        AppStringsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppStrings.supportedLocales,
      home: StreamBuilder<User?>(
        stream: authRepository.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data == null) {
            return AuthScreen(
              authRepository: authRepository,
              locale: locale,
              onLocaleChanged: (value) => setState(() => locale = value),
            );
          }
          return ShellScreen(
            authRepository: authRepository,
            familyRepository: familyRepository,
            locale: locale,
            onLocaleChanged: (value) => setState(() => locale = value),
            onThemeModeChanged: (value) {
              if (themeMode != value) {
                setState(() => themeMode = value);
              }
            },
          );
        },
      ),
    );
  }
}
