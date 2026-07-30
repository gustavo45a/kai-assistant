import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'models/app_theme.dart';
import 'services/app_settings.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/login_screen.dart';

// --- ARRANQUE COMPLETO CON BLINDAJE NATIVO ---
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Capturar errores del framework de Flutter y mostrarlos en pantalla
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF020408),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bug_report_rounded, color: Colors.redAccent, size: 32),
                    SizedBox(width: 8),
                    Text(
                      "VENTABLACK FATAL ERROR",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  details.exceptionAsString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Stacktrace:",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details.stack?.toString() ?? "No stacktrace available",
                  style: const TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint("ASYNCHRONOUS EXCEPTION DETECTED: $error");
    debugPrint(stack.toString());
    return true;
  };

  runApp(const VantablackApp());
}

class VantablackApp extends StatefulWidget {
  const VantablackApp({super.key});

  @override
  State<VantablackApp> createState() => _VantablackAppState();
}

class _VantablackAppState extends State<VantablackApp> {
  bool _isLoading = true;
  bool _isFirstLaunch = true;
  String _username = "Gustavo";
  AppThemeStyle _currentTheme = AppThemeStyle.vantablackGlass;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final firstLaunch = await AppSettings.isFirstLaunch();
    final username = await AppSettings.getUsername();
    final theme = await AppSettings.getSavedTheme();
    setState(() {
      _isFirstLaunch = firstLaunch;
      _username = username;
      _currentTheme = theme;
      _isLoading = false;
    });
  }

  void _onThemeChanged(AppThemeStyle newTheme) async {
    setState(() {
      _currentTheme = newTheme;
    });
    await AppSettings.saveTheme(newTheme);
  }

  void _onOnboardingComplete(String username, AppThemeStyle theme) {
    setState(() {
      _username = username;
      _currentTheme = theme;
      _isFirstLaunch = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = AppThemeConfig.getTheme(_currentTheme);

    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF020408),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF00B4D8)),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Vantablack Hub v3.0.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: themeData.backgroundColor,
        colorScheme: ColorScheme.dark(
          primary: themeData.primaryColor,
          surface: themeData.surfaceColor,
        ),
      ),
      home: _isFirstLaunch
          ? OnboardingScreen(
              initialTheme: _currentTheme,
              onComplete: _onOnboardingComplete,
            )
          : LoginScreen(
              username: _username,
              currentTheme: _currentTheme,
              onThemeChanged: _onThemeChanged,
            ),
    );
  }
}