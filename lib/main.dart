import 'dart:io'; 
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:open_file/open_file.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

// --- MOTOR DE 6 TEMAS VISUALES ---
enum AppThemeStyle {
  vantablackGlass,
  doodle,
  neumorphism,
  skeuomorphism,
  auroraUi,
  retroY2K,
}

class AppThemeData {
  final AppThemeStyle style;
  final String name;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final Color borderColor;
  final double borderRadius;
  final bool isGlass;
  final bool isNeumorphic;
  final bool isSkeuomorphic;
  final bool isAurora;
  final bool isRetro;
  final List<BoxShadow>? shadows;
  final Gradient? backgroundGradient;
  final Gradient? cardGradient;

  const AppThemeData({
    required this.style,
    required this.name,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.borderColor,
    required this.borderRadius,
    this.isGlass = false,
    this.isNeumorphic = false,
    this.isSkeuomorphic = false,
    this.isAurora = false,
    this.isRetro = false,
    this.shadows,
    this.backgroundGradient,
    this.cardGradient,
  });
}

class AppThemeConfig {
  static AppThemeData getTheme(AppThemeStyle style) {
    switch (style) {
      case AppThemeStyle.vantablackGlass:
        return const AppThemeData(
          style: AppThemeStyle.vantablackGlass,
          name: "Vantablack Glass",
          description: "Cristal esmerilado oscuro con reflejos de neón",
          icon: Icons.blur_on_rounded,
          primaryColor: Color(0xFF00B4D8),
          secondaryColor: Color(0xFF0077B6),
          backgroundColor: Color(0xFF020408),
          surfaceColor: Color(0xFF090D14),
          cardColor: Color(0x3B1E1E24),
          textColor: Colors.white,
          subtitleColor: Color(0xFF8E9BAE),
          borderColor: Color(0x3300B4D8),
          borderRadius: 16.0,
          isGlass: true,
          shadows: [
            BoxShadow(color: Color(0x1F00B4D8), blurRadius: 20, spreadRadius: 1),
          ],
        );
      case AppThemeStyle.doodle:
        return const AppThemeData(
          style: AppThemeStyle.doodle,
          name: "Ilustrativo / Doodle",
          description: "Colores cálidos, bordes redondeados y estilo manual",
          icon: Icons.draw_rounded,
          primaryColor: Color(0xFFE07A5F),
          secondaryColor: Color(0xFFF2CC8F),
          backgroundColor: Color(0xFF1E1B18),
          surfaceColor: Color(0xFF2A2622),
          cardColor: Color(0xFF2D2824),
          textColor: Color(0xFFF4EBE1),
          subtitleColor: Color(0xFFB0A294),
          borderColor: Color(0xFFE07A5F),
          borderRadius: 22.0,
          shadows: [
            BoxShadow(color: Color(0x40E07A5F), offset: Offset(4, 4), blurRadius: 0),
          ],
        );
      case AppThemeStyle.neumorphism:
        return const AppThemeData(
          style: AppThemeStyle.neumorphism,
          name: "Neumorfismo",
          description: "Sombras suaves de relieve interno/externo",
          icon: Icons.wb_cloudy_rounded,
          primaryColor: Color(0xFF4CC9F0),
          secondaryColor: Color(0xFF7209B7),
          backgroundColor: Color(0xFF1E222B),
          surfaceColor: Color(0xFF1E222B),
          cardColor: Color(0xFF1E222B),
          textColor: Color(0xFFE2E8F0),
          subtitleColor: Color(0xFF94A3B8),
          borderColor: Colors.transparent,
          borderRadius: 18.0,
          isNeumorphic: true,
          shadows: [
            BoxShadow(color: Color(0xFF282D37), offset: Offset(-5, -5), blurRadius: 10),
            BoxShadow(color: Color(0xFF14171E), offset: Offset(5, 5), blurRadius: 10),
          ],
        );
      case AppThemeStyle.skeuomorphism:
        return const AppThemeData(
          style: AppThemeStyle.skeuomorphism,
          name: "Skeuomorfismo",
          description: "Texturas físicas y botones 3D realistas",
          icon: Icons.view_in_ar_rounded,
          primaryColor: Color(0xFFFFB703),
          secondaryColor: Color(0xFFFB8500),
          backgroundColor: Color(0xFF1A1918),
          surfaceColor: Color(0xFF2B2825),
          cardColor: Color(0xFF2B2825),
          textColor: Color(0xFFF4F1DE),
          subtitleColor: Color(0xFFB0A8A0),
          borderColor: Color(0xFF52483E),
          borderRadius: 12.0,
          isSkeuomorphic: true,
          cardGradient: LinearGradient(
            colors: [Color(0xFF383430), Color(0xFF201D1B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          shadows: [
            BoxShadow(color: Colors.black87, offset: Offset(0, 4), blurRadius: 8),
          ],
        );
      case AppThemeStyle.auroraUi:
        return const AppThemeData(
          style: AppThemeStyle.auroraUi,
          name: "Aurora UI",
          description: "Gradientes borrosos tipo aurora boreal luminous",
          icon: Icons.auto_awesome_rounded,
          primaryColor: Color(0xFF00F5D4),
          secondaryColor: Color(0xFF7B2CBF),
          backgroundColor: Color(0xFF0D0B1E),
          surfaceColor: Color(0xFF171238),
          cardColor: Color(0x4D171238),
          textColor: Color(0xFFF1F5F9),
          subtitleColor: Color(0xFFA5B4FC),
          borderColor: Color(0x6600F5D4),
          borderRadius: 20.0,
          isAurora: true,
          backgroundGradient: LinearGradient(
            colors: [Color(0xFF090716), Color(0xFF160D33), Color(0xFF061826)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadows: [
            BoxShadow(color: Color(0x4D00F5D4), blurRadius: 24, spreadRadius: 2),
          ],
        );
      case AppThemeStyle.retroY2K:
        return const AppThemeData(
          style: AppThemeStyle.retroY2K,
          name: "Retro / Y2K",
          description: "Estética del año 2000 y tonos pastel saturados",
          icon: Icons.computer_rounded,
          primaryColor: Color(0xFFFF007F),
          secondaryColor: Color(0xFF00F0FF),
          backgroundColor: Color(0xFF161324),
          surfaceColor: Color(0xFF221C38),
          cardColor: Color(0xFF221C38),
          textColor: Colors.white,
          subtitleColor: Color(0xFFFFD166),
          borderColor: Color(0xFFFF007F),
          borderRadius: 6.0,
          isRetro: true,
          shadows: [
            BoxShadow(color: Color(0xFF00F0FF), offset: Offset(3, 3), blurRadius: 0),
          ],
        );
    }
  }
}

// --- GESTOR DE PREFERENCIAS LOCALES (SharedPreferences) ---
class AppSettings {
  static const String keyFirstLaunch = 'first_launch_v3_0';
  static const String keyUsername = 'user_name';
  static const String keyTheme = 'app_theme_style';

  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyFirstLaunch) ?? true;
  }

  static Future<void> completeOnboarding(String username, AppThemeStyle theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyFirstLaunch, false);
    await prefs.setString(keyUsername, username);
    await prefs.setString(keyTheme, theme.name);
  }

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUsername) ?? 'Gustavo';
  }

  static Future<AppThemeStyle> getSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(keyTheme);
    if (name != null) {
      return AppThemeStyle.values.firstWhere(
        (e) => e.name == name,
        orElse: () => AppThemeStyle.vantablackGlass,
      );
    }
    return AppThemeStyle.vantablackGlass;
  }

  static Future<void> saveTheme(AppThemeStyle theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyTheme, theme.name);
  }

  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUsername, username);
  }
}

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

// --- FLUJO DE ONBOARDING v3.0.0 ---
class OnboardingScreen extends StatefulWidget {
  final AppThemeStyle initialTheme;
  final Function(String username, AppThemeStyle theme) onComplete;

  const OnboardingScreen({
    super.key,
    required this.initialTheme,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late TextEditingController _nameController;
  late AppThemeStyle _selectedTheme;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: "Gustavo");
    _selectedTheme = widget.initialTheme;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _finishOnboarding() async {
    final name = _nameController.text.trim().isEmpty ? "Usuario KAI" : _nameController.text.trim();
    await AppSettings.completeOnboarding(name, _selectedTheme);
    widget.onComplete(name, _selectedTheme);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeConfig.getTheme(_selectedTheme);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: theme.backgroundGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 680),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(theme.borderRadius),
                border: Border.all(color: theme.borderColor, width: 1.5),
                boxShadow: theme.shadows,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ENCABEZADO DE BIENVENIDA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: theme.primaryColor, size: 36),
                      const SizedBox(width: 12),
                      Text(
                        "BIENVENIDO A KAI v3.0.0",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Configura tu identidad y selecciona tu motor de tema visual preferido para comenzar.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: theme.subtitleColor),
                  ),
                  const SizedBox(height: 28),

                  // CAMPO DE NOMBRE DE USUARIO
                  Text(
                    "1. Nombre de Usuario",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      hintText: "Ej. Gustavo",
                      hintStyle: TextStyle(color: theme.subtitleColor.withValues(alpha: 0.6)),
                      prefixIcon: Icon(Icons.person_rounded, color: theme.primaryColor),
                      filled: true,
                      fillColor: theme.backgroundColor.withValues(alpha: 0.5),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // SELECTOR DE TEMAS
                  Text(
                    "2. Selecciona tu Tema Visual (6 Estilos)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.1,
                    ),
                    itemCount: AppThemeStyle.values.length,
                    itemBuilder: (context, index) {
                      final itemStyle = AppThemeStyle.values[index];
                      final itemTheme = AppThemeConfig.getTheme(itemStyle);
                      final isSelected = itemStyle == _selectedTheme;

                      return InkWell(
                        onTap: () => setState(() => _selectedTheme = itemStyle),
                        borderRadius: BorderRadius.circular(itemTheme.borderRadius),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: itemTheme.cardColor,
                            borderRadius: BorderRadius.circular(itemTheme.borderRadius),
                            border: Border.all(
                              color: isSelected ? itemTheme.primaryColor : itemTheme.borderColor.withValues(alpha: 0.4),
                              width: isSelected ? 2.5 : 1.0,
                            ),
                            boxShadow: isSelected ? itemTheme.shadows : [],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(itemTheme.icon, color: itemTheme.primaryColor, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      itemTheme.name,
                                      style: TextStyle(
                                        color: itemTheme.textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle_rounded, color: itemTheme.primaryColor, size: 18),
                                ],
                              ),
                              Text(
                                itemTheme.description,
                                style: TextStyle(
                                  color: itemTheme.subtitleColor,
                                  fontSize: 10,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // BOTÓN DE CONTINUAR
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                    ),
                    onPressed: _finishOnboarding,
                    icon: const Icon(Icons.rocket_launch_rounded),
                    label: const Text(
                      "COMENZAR EXPERIENCIA VANTABLACK V3",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  final String username;
  final AppThemeStyle currentTheme;
  final Function(AppThemeStyle) onThemeChanged;

  const LoginScreen({
    super.key,
    required this.username,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _usernameController;
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
  }

  void _handleLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Por favor ingresa todos los campos.";
      });
      return;
    }

    if ((username == "admin" && password == "admin") || (username == "gustavo" && password == "zynoox") || (username == widget.username && password == "zynoox")) {
      setState(() {
        _errorMessage = null;
      });
      AppSettings.saveUsername(username);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VantablackHome(
            username: username,
            currentTheme: widget.currentTheme,
            onThemeChanged: widget.onThemeChanged,
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = "Credenciales incorrectas (Utiliza admin/admin o gustavo/zynoox).";
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeConfig.getTheme(widget.currentTheme);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(gradient: theme.backgroundGradient),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(theme.borderRadius),
                border: Border.all(color: theme.borderColor),
                boxShadow: theme.shadows,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.shield_rounded, color: theme.primaryColor, size: 48),
                      IconButton(
                        icon: Icon(Icons.palette_rounded, color: theme.primaryColor),
                        tooltip: "Cambiar Tema Visual",
                        onPressed: () => _mostrarSelectorTemasModal(context, widget.currentTheme, widget.onThemeChanged),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "VANTABLACK HUB v3.0.0",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Acceso seguro para ${widget.username}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _usernameController,
                    style: TextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      labelText: "Usuario",
                      labelStyle: TextStyle(color: theme.subtitleColor),
                      prefixIcon: Icon(Icons.person_outline_rounded, color: theme.primaryColor),
                      fillColor: theme.backgroundColor.withValues(alpha: 0.5),
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      labelStyle: TextStyle(color: theme.subtitleColor),
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: theme.primaryColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: theme.subtitleColor,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      fillColor: theme.backgroundColor.withValues(alpha: 0.5),
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.primaryColor),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    onPressed: _handleLogin,
                    child: const Text(
                      "Iniciar Sesión",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- DIÁLOGO GLOBAL DE SELECTOR DE TEMAS ---
void _mostrarSelectorTemasModal(BuildContext context, AppThemeStyle currentStyle, Function(AppThemeStyle) onThemeChanged) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final theme = AppThemeConfig.getTheme(currentStyle);

          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(theme.borderRadius),
              border: Border.all(color: theme.primaryColor.withValues(alpha: 0.5), width: 1.5),
              boxShadow: theme.shadows,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette_rounded, color: theme.primaryColor, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      "MOTOR DE TEMAS VISUALES (6 ESTILOS)",
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: theme.subtitleColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: AppThemeStyle.values.length,
                  itemBuilder: (context, index) {
                    final itemStyle = AppThemeStyle.values[index];
                    final itemTheme = AppThemeConfig.getTheme(itemStyle);
                    final isSelected = itemStyle == currentStyle;

                    return InkWell(
                      onTap: () {
                        onThemeChanged(itemStyle);
                        setModalState(() {
                          currentStyle = itemStyle;
                        });
                      },
                      borderRadius: BorderRadius.circular(itemTheme.borderRadius),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: itemTheme.cardColor,
                          borderRadius: BorderRadius.circular(itemTheme.borderRadius),
                          border: Border.all(
                            color: isSelected ? itemTheme.primaryColor : itemTheme.borderColor.withValues(alpha: 0.4),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(itemTheme.icon, color: itemTheme.primaryColor, size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    itemTheme.name,
                                    style: TextStyle(
                                      color: itemTheme.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded, color: itemTheme.primaryColor, size: 16),
                              ],
                            ),
                            Text(
                              itemTheme.description,
                              style: TextStyle(color: itemTheme.subtitleColor, fontSize: 9.5),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// --- MODELOS Y CLASES AUXILIARES DE NÚCLEO ---
enum CoreMode { estudiante, normal }

class LocalModel {
  final String id;
  final String name;
  final String size;
  final double requiredRamGb;
  final String urlGguf;
  final String badge;
  final Color badgeColor;
  final String description;
  bool isDownloaded;

  LocalModel({
    required this.id,
    required this.name,
    required this.size,
    required this.requiredRamGb,
    required this.urlGguf,
    required this.badge,
    required this.badgeColor,
    required this.description,
    this.isDownloaded = false,
  });
}

class HardwareScanner {
  static Future<Map<String, dynamic>> scan() async {
    final cores = kIsWeb ? 1 : Platform.numberOfProcessors;
    double freeRamGb = 4.0;
    double totalRamGb = 8.0;

    if (!kIsWeb && (Platform.isAndroid || Platform.isLinux)) {
      try {
        final file = File('/proc/meminfo');
        if (await file.exists()) {
          final lines = await file.readAsLines();
          double? memTotal;
          double? memAvailable;
          double? memFree;
          
          for (var line in lines) {
            if (line.startsWith('MemTotal:')) {
              final parts = line.split(RegExp(r'\s+'));
              final kb = double.tryParse(parts[1]);
              if (kb != null) {
                memTotal = kb / (1024 * 1024);
              }
            } else if (line.startsWith('MemAvailable:')) {
              final parts = line.split(RegExp(r'\s+'));
              final kb = double.tryParse(parts[1]);
              if (kb != null) {
                memAvailable = kb / (1024 * 1024);
              }
            } else if (line.startsWith('MemFree:')) {
              final parts = line.split(RegExp(r'\s+'));
              final kb = double.tryParse(parts[1]);
              if (kb != null) {
                memFree = kb / (1024 * 1024);
              }
            }
          }
          freeRamGb = memAvailable ?? memFree ?? 4.0;
          totalRamGb = memTotal ?? 8.0;
        }
      } catch (_) {}
    } else {
      freeRamGb = cores > 4 ? 5.5 : 3.2;
      totalRamGb = cores > 4 ? 8.0 : 4.0;
    }

    final recommendedModelId = totalRamGb >= 7.5 ? "llama_3_2_1b" : "qwen_0.5b_chat_q4";

    return {
      'cores': cores,
      'freeRamGb': freeRamGb,
      'totalRamGb': totalRamGb,
      'recommendedModelId': recommendedModelId,
    };
  }
}

class LocalLLMService {
  static final LocalLLMService instance = LocalLLMService._internal();
  LocalLLMService._internal();

  final LlamaController _controller = LlamaController();
  bool _isModelLoaded = false;
  bool _isGenerating = false;
  String _modelPath = '';

  bool get isGenerating => _isGenerating;
  bool get isModelLoaded => _isModelLoaded;

  Future<void> stop() async {
    try {
      if (_isGenerating) {
        await _controller.stop();
        _isGenerating = false;
      }
    } catch (_) {}
  }

  Future<void> initializeRealModel(String path, {int threads = 2}) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception("Modelo local no encontrado en el almacenamiento. Requiere descarga inicial.");
    }

    if (_isModelLoaded && _modelPath == path) {
      return;
    }

    ZRamMemoryManager.optimizeMemory(true);

    if (_isModelLoaded) {
      try {
        await _controller.dispose();
      } catch (_) {}
      _isModelLoaded = false;
    }

    _modelPath = path;
    final safeThreads = (threads > 0 && threads <= 2) ? threads : 2;

    try {
      await _controller.loadModel(
        modelPath: _modelPath,
        threads: safeThreads,
        contextSize: 768,
      );
      _isModelLoaded = true;
    } catch (e) {
      _isModelLoaded = false;
      throw Exception("RAM insuficiente o error al alojar el modelo local: $e");
    }
  }

  Stream<String> generateResponseStream(String prompt, Map<String, dynamic> variables, {List<Map<String, String>>? history}) async* {
    if (!_isModelLoaded) {
      yield "[ERROR HARDWARE]: El motor local no está inicializado. Descarga los pesos del modelo Hugging Face primero.";
      return;
    }

    if (_isGenerating) {
      await stop();
    }

    _isGenerating = true;

    final StringBuffer promptFormatted = StringBuffer();
    promptFormatted.writeln("<|im_start|>system");
    promptFormatted.writeln("Eres VANTABLACK, una matriz de inteligencia artificial offline de alta eficiencia.");
    if (variables['modoEstudiante'] == true) {
      promptFormatted.writeln("MODO ESTUDIANTE ACTIVO: Explica de forma didáctica, clara y con ejemplos paso a paso.");
    }
    promptFormatted.writeln("<|im_end|>");

    if (history != null && history.isNotEmpty) {
      final recentHistory = history.length > 6 ? history.sublist(history.length - 6) : history;
      for (var msg in recentHistory) {
        final role = msg['sender'] == 'user' ? 'user' : 'assistant';
        final text = msg['text'] ?? '';
        if (text.isNotEmpty && !text.startsWith('[ERROR')) {
          final cleanText = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'), '');
          promptFormatted.writeln("<|im_start|>$role");
          promptFormatted.writeln(cleanText);
          promptFormatted.writeln("<|im_end|>");
        }
      }
    }

    final cleanPrompt = prompt.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'), '');
    promptFormatted.writeln("<|im_start|>user");
    promptFormatted.writeln(cleanPrompt);
    promptFormatted.writeln("<|im_end|>");
    promptFormatted.writeln("<|im_start|>assistant");

    try {
      final stream = _controller.generate(
        prompt: promptFormatted.toString(),
        maxTokens: 512,
        temperature: 0.6,
        topP: 0.9,
        repeatPenalty: 1.18,
      );

      await for (final chunk in stream) {
        if (!_isGenerating) break;
        if (chunk.contains("<|im_end|>") || chunk.contains("<|endoftext|>")) {
          final cleanChunk = chunk.replaceAll("<|im_end|>", "").replaceAll("<|endoftext|>", "");
          if (cleanChunk.isNotEmpty) yield cleanChunk;
          break;
        }
        yield chunk;
      }
    } catch (e) {
      yield "\n[EXCEPCIÓN EN MOTOR NATIVO C++]: $e";
    } finally {
      _isGenerating = false;
    }
  }
}

class ChatThread {
  final String id;
  String title;
  String iaModel;
  final List<Map<String, String>> messages;
  bool modeloInicializado;
  String? rutaModeloLocal;
  bool pensando;

  ChatThread({
    required this.id,
    required this.title,
    required this.iaModel,
    required this.messages,
    this.modeloInicializado = false,
    this.rutaModeloLocal,
    this.pensando = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'iaModel': iaModel,
        'messages': messages,
        'modeloInicializado': modeloInicializado,
        'rutaModeloLocal': rutaModeloLocal,
      };

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
        id: json['id'],
        title: json['title'],
        iaModel: json['iaModel'],
        messages: List<Map<String, String>>.from(
          (json['messages'] as List).map((item) => Map<String, String>.from(item)),
        ),
        modeloInicializado: json['modeloInicializado'] ?? false,
        rutaModeloLocal: json['rutaModeloLocal'],
        pensando: false,
      );
}

class ZRamMemoryManager {
  static Future<Map<String, dynamic>> optimizeMemory(bool isEnabled) async {
    double freedMb = 0.0;
    if (isEnabled) {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      try {
        final tempDir = await getTemporaryDirectory();
        if (await tempDir.exists()) {
          final files = tempDir.listSync(recursive: true);
          for (var file in files) {
            if (file is File) {
              final len = await file.length();
              freedMb += len / (1024 * 1024);
              try {
                await file.delete();
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }
    return {
      'freedMb': freedMb,
      'status': 'Caché liberada correctamente'
    };
  }
}

class LocalWebServerService {
  static final LocalWebServerService instance = LocalWebServerService._internal();
  LocalWebServerService._internal();

  HttpServer? _server;
  String _serverIp = 'Buscando IP...';
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  String get serverUrl => 'http://$_serverIp:8080';

  Future<void> startServer(List<ChatThread> Function() getThreads) async {
    if (_isRunning) return;

    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            _serverIp = addr.address;
            break;
          }
        }
      }

      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      _isRunning = true;

      _server!.listen((HttpRequest request) {
        request.response.headers.contentType = ContentType.html;
        
        final threads = getThreads();
        final sb = StringBuffer();
        sb.writeln("<!DOCTYPE html><html><head><title>Vantablack Hub Remote</title>");
        sb.writeln("<meta charset='utf-8'><style>body{background:#020408;color:#00B4D8;font-family:sans-serif;padding:20px;} .card{background:#090D14;padding:15px;margin-bottom:10px;border-radius:8px;border:1px solid #00B4D8;}</style></head><body>");
        sb.writeln("<h1>⚡ VANTABLACK LOCAL SERVER REMOTE</h1>");
        sb.writeln("<p>Conexión remota activa desde Galaxy Tab / Red Local.</p>");
        sb.writeln("<h2>Instancias de Chat Activas:</h2>");
        
        for (var t in threads) {
          sb.writeln("<div class='card'><h3>${t.title} (${t.iaModel})</h3>");
          sb.writeln("<p>Mensajes: ${t.messages.length}</p></div>");
        }
        
        sb.writeln("</body></html>");
        request.response.write(sb.toString());
        request.response.close();
      });
    } catch (e) {
      _isRunning = false;
    }
  }

  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _isRunning = false;
    }
  }
}

// --- PANTALLA PRINCIPAL VANTABLACK HOME ---
class VantablackHome extends StatefulWidget {
  final String username;
  final AppThemeStyle currentTheme;
  final Function(AppThemeStyle) onThemeChanged;

  const VantablackHome({
    super.key,
    required this.username,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<VantablackHome> createState() => _VantablackHomeState();
}

class _VantablackHomeState extends State<VantablackHome> {
  final String _versionHub = "3.0.0";
  final String _urlApkRemoto = "https://gustavo45a.github.io/kai-assistant/docs/vantablack_hub.apk";
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  late AppThemeStyle _currentThemeStyle;
  CoreMode _currentMode = CoreMode.normal;
  List<ChatThread> _threads = [];
  String? _activeThreadId;

  bool _isGenerating = false;
  bool _descargandoOta = false;
  bool _descargandoModelo = false;
  double _progresoOta = 0.0;
  double _progresoModelo = 0.0;

  double _freeRamGb = 4.0;
  double _totalRamGb = 8.0;
  int _cpuCores = 4;

  bool isZRamEnabled = true;
  bool _ttsEnabled = false;
  bool isWebServidorActive = false;
  bool isModoPro = false;
  bool isVirtualAssistantActive = false;

  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  bool _speechInitialized = false;

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<LocalModel> _modelosDisponibles = [
    LocalModel(
      id: "llama_3_2_1b",
      name: "Llama 3.2 1B Instruct",
      size: "750 MB",
      requiredRamGb: 2.5,
      urlGguf: "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
      badge: "RECOMENDADO",
      badgeColor: const Color(0xFF00B4D8),
      description: "Modelo ultrarrápido optimizado por Meta para dispositivos móviles con RAM ajustada.",
    ),
    LocalModel(
      id: "qwen_0.5b_chat_q4",
      name: "Qwen 2.5 0.5B Chat",
      size: "390 MB",
      requiredRamGb: 1.5,
      urlGguf: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
      badge: "LIGERO",
      badgeColor: const Color(0xFF2ECC71),
      description: "Respuesta instantánea con huella de RAM mínima. Ideal para pruebas en caliente.",
    ),
    LocalModel(
      id: "deepseek_r1_1.5b",
      name: "DeepSeek R1 Distill 1.5B",
      size: "1.1 GB",
      requiredRamGb: 3.8,
      urlGguf: "https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf",
      badge: "RAZONAMIENTO",
      badgeColor: const Color(0xFF9D4EDD),
      description: "Capacidad avanzada de razonamiento y resolución de código paso a paso.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentThemeStyle = widget.currentTheme;
    _initTts();
    scheduleMicrotask(() async {
      final diagnostic = await HardwareScanner.scan();
      if (mounted) {
        setState(() {
          _cpuCores = diagnostic['cores'];
          _freeRamGb = diagnostic['freeRamGb'];
          _totalRamGb = diagnostic['totalRamGb'];
        });
      }
      await _verificarModelosDescargados();
      await _cargarDatosDesdeDisco();
      await _checkUpdates();
    });
  }

  Future<void> _initTts() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _flutterTts.setEngine("com.google.android.tts");
      }
      await _flutterTts.setLanguage("es-ES");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
    } catch (e) {
      debugPrint("Error TTS: $e");
    }
  }

  Future<void> _speakText(String text) async {
    if (!_ttsEnabled || text.isEmpty) return;
    try {
      final cleanText = text
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'[\*\_~`]'), '')
          .trim();
      if (cleanText.isNotEmpty) {
        await _flutterTts.speak(cleanText);
      }
    } catch (_) {}
  }

  Future<void> _toggleListening() async {
    if (!_speechInitialized) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          _mostrarModalErrorWindowsXP("Se requiere permiso de micrófono para reconocimiento de voz.", titulo: "Permiso denegado - Vantablack Hub");
        }
        return;
      }
      _speechInitialized = await _speechToText.initialize();
    }

    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _chatController.text = result.recognizedWords;
            _chatController.selection = TextSelection.fromPosition(
              TextPosition(offset: _chatController.text.length),
            );
          });
        },
        listenOptions: stt.SpeechListenOptions(localeId: "es_ES"),
      );
    }
  }

  Future<void> _checkUpdates() async {
    try {
      final dio = Dio();
      final response = await dio.get("https://gustavo45a.github.io/kai-assistant/version.json");
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        final latestVersion = data["version"] ?? _versionHub;
        if (latestVersion != _versionHub && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00B4D8),
              content: Text("⚡ Nueva versión Vantablack Hub v$latestVersion disponible!"),
              action: SnackBarAction(
                label: "ACTUALIZAR",
                textColor: Colors.black,
                onPressed: _ejecutarActualizacionOTA,
              ),
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _ejecutarActualizacionOTA() async {
    if (_descargandoOta) return;
    setState(() {
      _descargandoOta = true;
      _progresoOta = 0.0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = "${dir.path}/vantablack_update.apk";
      final dio = Dio();

      await dio.download(
        _urlApkRemoto,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progresoOta = received / total;
            });
          }
        },
      );

      setState(() => _descargandoOta = false);
      final result = await OpenFile.open(savePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("APK guardado en: $savePath")),
        );
      }
    } catch (e) {
      setState(() => _descargandoOta = false);
      if (mounted) {
        _mostrarModalErrorWindowsXP("Error al descargar la actualización OTA: $e");
      }
    }
  }

  Future<void> _verificarModelosDescargados() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      for (var model in _modelosDisponibles) {
        final filePath = "${dir.path}/${model.id}.gguf";
        final file = File(filePath);
        model.isDownloaded = await file.exists();
      }
      setState(() {});
    } catch (_) {}
  }

  Future<void> _descargarModeloLlmNativamente(ChatThread thread) async {
    final model = _modelosDisponibles.firstWhere(
      (m) => m.id == thread.iaModel,
      orElse: () => _modelosDisponibles.first,
    );

    setState(() {
      _descargandoModelo = true;
      _progresoModelo = 0.0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/${model.id}.gguf";
      final dio = Dio();

      await dio.download(
        model.urlGguf,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progresoModelo = received / total;
            });
          }
        },
      );

      model.isDownloaded = true;
      thread.rutaModeloLocal = filePath;

      await LocalLLMService.instance.initializeRealModel(filePath, threads: _cpuCores > 2 ? 2 : 1);
      thread.modeloInicializado = true;

      setState(() {
        _descargandoModelo = false;
      });

      await _guardarDatosEnDisco();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("¡Modelo ${model.name} inicializado nativamente!")),
        );
      }
    } catch (e) {
      setState(() {
        _descargandoModelo = false;
      });
      if (mounted) {
        _mostrarModalErrorWindowsXP("Error al descargar modelo local: $e");
      }
    }
  }

  Future<void> _cargarDatosDesdeDisco() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('vantablack_threads');
      if (jsonStr != null) {
        final List dynamicList = jsonDecode(jsonStr);
        _threads = dynamicList.map((item) => ChatThread.fromJson(item)).toList();
      }

      if (_threads.isEmpty) {
        _crearNuevaInstanciaLocal("llama_3_2_1b");
      } else {
        _activeThreadId = _threads.first.id;
      }
      setState(() {});
    } catch (_) {
      if (_threads.isEmpty) {
        _crearNuevaInstanciaLocal("llama_3_2_1b");
      }
    }
  }

  Future<void> _guardarDatosEnDisco() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_threads.map((t) => t.toJson()).toList());
      await prefs.setString('vantablack_threads', jsonStr);
    } catch (_) {}
  }

  void _crearNuevaInstanciaLocal(String modelId) {
    final newId = const Uuid().v4();
    final newThread = ChatThread(
      id: newId,
      title: "Matriz ${modelId.toUpperCase().replaceAll('_', ' ')}",
      iaModel: modelId,
      messages: [
        {"sender": "system", "text": "INSTANCIA KAI V3 INICIALIZADA."},
      ],
    );
    setState(() {
      _threads.add(newThread);
      _activeThreadId = newId;
    });
    _guardarDatosEnDisco();
  }

  ChatThread get _activeThread {
    return _threads.firstWhere(
      (t) => t.id == _activeThreadId,
      orElse: () => _threads.isNotEmpty ? _threads.first : ChatThread(id: '0', title: 'Default', iaModel: 'llama_3_2_1b', messages: []),
    );
  }

  Future<void> _procesarMensajeLocal() async {
    final threadActual = _activeThread;
    if (_chatController.text.trim().isEmpty || threadActual.pensando || _isGenerating) return;

    final textoUsuario = _chatController.text.trim();
    _chatController.clear();

    setState(() {
      _isGenerating = true;
      threadActual.messages.add({"sender": "user", "text": textoUsuario});
      threadActual.messages.add({"sender": "assistant", "text": "..."});
      threadActual.pensando = true;
    });

    _scrollToBottom();

    try {
      if (!LocalLLMService.instance.isModelLoaded && threadActual.rutaModeloLocal != null) {
        await LocalLLMService.instance.initializeRealModel(threadActual.rutaModeloLocal!, threads: 2);
        threadActual.modeloInicializado = true;
      }

      if (LocalLLMService.instance.isModelLoaded) {
        final stream = LocalLLMService.instance.generateResponseStream(
          textoUsuario,
          {'modoEstudiante': _currentMode == CoreMode.estudiante},
          history: threadActual.messages,
        );

        final responseBuffer = StringBuffer();
        await for (final chunk in stream) {
          responseBuffer.write(chunk);
          if (mounted) {
            setState(() {
              threadActual.messages.last = {"sender": "assistant", "text": responseBuffer.toString()};
            });
            _scrollToBottom();
          }
        }
        await _speakText(responseBuffer.toString());
      } else {
        await Future.delayed(const Duration(seconds: 1));
        final fallbackMsg = "El modelo ${threadActual.iaModel} requiere ser descargado a almacenamiento local primero.";
        setState(() {
          threadActual.messages.last = {"sender": "assistant", "text": fallbackMsg};
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          threadActual.messages.last = {"sender": "assistant", "text": "[EXCEPCIÓN LOCAL]: $e"};
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          threadActual.pensando = false;
        });
      } else {
        _isGenerating = false;
        threadActual.pensando = false;
      }
      await _guardarDatosEnDisco();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- PANEL DE HERRAMIENTAS LOCALES (TOOLBOX) ---
  void _mostrarModalToolbox(BuildContext context) {
    final theme = AppThemeConfig.getTheme(_currentThemeStyle);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(theme.borderRadius),
            border: Border.all(color: theme.primaryColor.withValues(alpha: 0.5), width: 1.5),
            boxShadow: theme.shadows,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.handyman_rounded, color: theme.primaryColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    "PANEL DE HERRAMIENTAS LOCALES (TOOLBOX)",
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: theme.subtitleColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.1,
                children: [
                  _buildToolTile(
                    theme: theme,
                    title: "Captura y Análisis",
                    subtitle: "Screenshot -> Modelo IA",
                    icon: Icons.camera_alt_rounded,
                    color: const Color(0xFF00B4D8),
                    onTap: () {
                      Navigator.pop(context);
                      _ejecutarCapturaPantallaAnalisis();
                    },
                  ),
                  _buildToolTile(
                    theme: theme,
                    title: "Resumidor RAG Local",
                    subtitle: "Inyectar .txt / .pdf",
                    icon: Icons.description_rounded,
                    color: const Color(0xFF9D4EDD),
                    onTap: () {
                      Navigator.pop(context);
                      _ejecutarResumidorRagLocal();
                    },
                  ),
                  _buildToolTile(
                    theme: theme,
                    title: "Cajón Utilidades Dev",
                    subtitle: "Formatear JSON / Code",
                    icon: Icons.code_rounded,
                    color: const Color(0xFF2ECC71),
                    onTap: () {
                      Navigator.pop(context);
                      _mostrarCajonUtilidadesDev();
                    },
                  ),
                  _buildToolTile(
                    theme: theme,
                    title: "Optimizador Memoria",
                    subtitle: "Limpiar Caché y RAM",
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFFF9500),
                    onTap: () {
                      Navigator.pop(context);
                      _ejecutarOptimizadorMemoria();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolTile({
    required AppThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(theme.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(theme.borderRadius),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.subtitleColor,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TOOL 1: Captura de pantalla y análisis
  Future<void> _ejecutarCapturaPantallaAnalisis() async {
    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          _mostrarModalErrorWindowsXP("No se pudo obtener el renderizado de la pantalla actual.");
        }
        return;
      }

      final image = await boundary.toImage(pixelRatio: 1.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (bytes != null && mounted) {
        final promptController = TextEditingController(
          text: "Analiza la captura de pantalla de esta interfaz e identifica los elementos visuales clave.",
        );

        showDialog(
          context: context,
          builder: (context) {
            final theme = AppThemeConfig.getTheme(_currentThemeStyle);
            return AlertDialog(
              backgroundColor: theme.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.borderRadius)),
              title: Row(
                children: [
                  Icon(Icons.camera_alt_rounded, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text("Captura de Pantalla", style: TextStyle(color: theme.textColor, fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(bytes, height: 180, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: promptController,
                      maxLines: 3,
                      style: TextStyle(color: theme.textColor, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Instrucción de análisis IA",
                        labelStyle: TextStyle(color: theme.subtitleColor),
                        filled: true,
                        fillColor: theme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancelar", style: TextStyle(color: theme.subtitleColor)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
                  onPressed: () {
                    Navigator.pop(context);
                    final prompt = promptController.text.trim();
                    _chatController.text = "[CAPTURA DE PANTALLA ADJUNTA - VANTABLACK V3]\n$prompt";
                    _procesarMensajeLocal();
                  },
                  icon: const Icon(Icons.send_rounded, size: 16, color: Colors.black),
                  label: const Text("Enviar a la IA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        _mostrarModalErrorWindowsXP("Error al capturar pantalla: $e");
      }
    }
  }

  // TOOL 2: Resumidor RAG Local
  Future<void> _ejecutarResumidorRagLocal() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'md', 'json', 'log', 'csv', 'dart', 'py'],
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        String rawBytesString = '';

        if (pickedFile.path != null) {
          final file = File(pickedFile.path!);
          final ext = pickedFile.extension?.toLowerCase() ?? '';
          final bytes = await file.readAsBytes();
          if (ext == 'pdf') {
            rawBytesString = _parsePdfBytes(bytes);
          } else {
            rawBytesString = utf8.decode(bytes, allowMalformed: true);
          }
        } else if (pickedFile.bytes != null) {
          final ext = pickedFile.extension?.toLowerCase() ?? '';
          if (ext == 'pdf') {
            rawBytesString = _parsePdfBytes(pickedFile.bytes!);
          } else {
            rawBytesString = utf8.decode(pickedFile.bytes!, allowMalformed: true);
          }
        }

        // Filtrado estricto de texto: elimina caracteres corruptos o no imprimibles
        String cleanText = rawBytesString.replaceAll(RegExp(r'[^\x20-\x7E\n\áéíóúÁÉÍÓÚñÑüÜ]'), '');

        // Rechazo limpio antes de invocar el motor C++ si el archivo no contiene texto legible
        if (cleanText.trim().isEmpty) {
          if (mounted) {
            _mostrarModalErrorWindowsXP("El documento '${pickedFile.name}' no contiene texto legible o es un archivo binario no compatible.");
          }
          return;
        }

        if (cleanText.length > 3000) {
          cleanText = "${cleanText.substring(0, 3000)}\n...[CONTENIDO TRUNCADO POR TAMAÑO DE CONTEXTO]";
        }

        _chatController.text = "[DOCUMENTO RAG LOCAL: ${pickedFile.name}]\n"
            "Formato: .${pickedFile.extension} | Tamaño: ${pickedFile.size} bytes\n\n"
            "--- CONTENIDO EXTRAÍDO ---\n"
            "$cleanText\n"
            "--- FIN CONTENIDO ---\n\n"
            "Genera un resumen estructurado con puntos clave de este documento.";

        _procesarMensajeLocal();
      }
    } catch (e) {
      if (mounted) {
        _mostrarModalErrorWindowsXP("Error al leer archivo RAG: $e");
      }
    }
  }

  String _parsePdfBytes(Uint8List bytes) {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String extractedText = PdfTextExtractor(document).extractText();
      document.dispose();
      final cleaned = extractedText.replaceAll(RegExp(r'[^\x20-\x7E\n\áéíóúÁÉÍÓÚñÑüÜ]'), '').trim();
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    } catch (e) {
      debugPrint("Error al extraer texto de PDF: $e");
    }
    return "";
  }

  void _mostrarModalErrorWindowsXP(String mensaje, {String titulo = "Error crítico - Vantablack Hub"}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: WindowsXPErrorDialog(mensaje: mensaje, titulo: titulo),
        );
      },
    );
  }

  // TOOL 3: Cajón de Utilidades Dev
  void _mostrarCajonUtilidadesDev() {
    final theme = AppThemeConfig.getTheme(_currentThemeStyle);
    final codeController = TextEditingController();
    String validationResult = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.borderRadius)),
              title: Row(
                children: [
                  Icon(Icons.code_rounded, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text("Cajón de Utilidades Dev", style: TextStyle(color: theme.textColor, fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      maxLines: 7,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Pega aquí tu fragmento de Código o JSON sin formatear...",
                        hintStyle: TextStyle(color: theme.subtitleColor),
                        filled: true,
                        fillColor: theme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B4D8)),
                          onPressed: () {
                            try {
                              final obj = jsonDecode(codeController.text);
                              final pretty = const JsonEncoder.withIndent('  ').convert(obj);
                              setDialogState(() {
                                codeController.text = pretty;
                                validationResult = "✅ JSON Válido y Formateado Correctamente";
                              });
                            } catch (e) {
                              setDialogState(() {
                                validationResult = "❌ Error de Sintaxis JSON: $e";
                              });
                            }
                          },
                          icon: const Icon(Icons.data_object_rounded, size: 14, color: Colors.black),
                          label: const Text("Formatear JSON", style: TextStyle(color: Colors.black, fontSize: 11)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9D4EDD)),
                          onPressed: () {
                            final code = codeController.text;
                            int openBraces = 0, openParens = 0, openBrackets = 0;
                            for (var rune in code.runes) {
                              final char = String.fromCharCode(rune);
                              if (char == '{') openBraces++;
                              if (char == '}') openBraces--;
                              if (char == '(') openParens++;
                              if (char == ')') openParens--;
                              if (char == '[') openBrackets++;
                              if (char == ']') openBrackets--;
                            }
                            if (openBraces == 0 && openParens == 0 && openBrackets == 0) {
                              setDialogState(() {
                                validationResult = "✅ Símbolos balanceados ({}, (), []). Sintaxis correcta.";
                              });
                            } else {
                              setDialogState(() {
                                validationResult = "⚠️ Desbalance: Braces: $openBraces, Parens: $openParens, Brackets: $openBrackets";
                              });
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.white),
                          label: const Text("Validar Sintaxis", style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ],
                    ),
                    if (validationResult.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        validationResult,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: validationResult.startsWith("✅") ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cerrar", style: TextStyle(color: theme.subtitleColor)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
                  onPressed: () {
                    Navigator.pop(context);
                    if (codeController.text.isNotEmpty) {
                      _chatController.text = "```\n${codeController.text}\n```\nRevisa este fragmento de código.";
                    }
                  },
                  child: const Text("Inyectar en Chat", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // TOOL 4: Optimizador de Memoria
  Future<void> _ejecutarOptimizadorMemoria() async {
    final result = await ZRamMemoryManager.optimizeMemory(true);
    final freedMb = (result['freedMb'] as double).toStringAsFixed(2);
    final hardware = await HardwareScanner.scan();
    final freeRam = (hardware['freeRamGb'] as double).toStringAsFixed(2);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          final theme = AppThemeConfig.getTheme(_currentThemeStyle);
          return AlertDialog(
            backgroundColor: theme.surfaceColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.borderRadius)),
            title: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Color(0xFFFF9500)),
                const SizedBox(width: 8),
                Text("Optimizador Galaxy Tab RAM", style: TextStyle(color: theme.textColor, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("¡Optimización de memoria ejecutada con éxito!"),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Caché Eliminada:", style: TextStyle(fontSize: 12, color: Colors.white70)),
                          Text("$freedMb MB", style: const TextStyle(fontSize: 12, color: Color(0xFFFF9500), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("RAM Libre en Galaxy Tab:", style: TextStyle(fontSize: 12, color: Colors.white70)),
                          Text("$freeRam GB", style: const TextStyle(fontSize: 12, color: Color(0xFF00B4D8), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9500)),
                onPressed: () => Navigator.pop(context),
                child: const Text("Aceptar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    }
  }

  // --- COMPONENTES VISUALES Y HEADER ---
  @override
  Widget build(BuildContext context) {
    final theme = AppThemeConfig.getTheme(_currentThemeStyle);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: RepaintBoundary(
        key: _repaintBoundaryKey,
        child: Container(
          decoration: BoxDecoration(gradient: theme.backgroundGradient),
          child: Row(
            children: [
              // BARRA LATERAL NATIVA
              Container(
                width: 270,
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  border: Border(right: BorderSide(color: theme.borderColor, width: 0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 36),
                    
                    Center(
                      child: GestureDetector(
                        onTap: _ejecutarActualizacionOTA,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 130, height: 130, 
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(theme.borderRadius),
                            boxShadow: theme.shadows,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(theme.borderRadius),
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: theme.cardColor,
                                  child: Icon(
                                    Icons.shield_rounded,
                                    color: theme.primaryColor,
                                    size: 36,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 15),

                    _buildHardwareTelemetryCard(theme),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLiquidGlassButton(
                            theme: theme,
                            title: "Modo Normal",
                            icon: Icons.bolt_rounded,
                            isSelected: _currentMode == CoreMode.normal,
                            activeColor: theme.primaryColor,
                            onTap: () => setState(() => _currentMode = CoreMode.normal),
                          ),
                          _buildLiquidGlassButton(
                            theme: theme,
                            title: "Estudiante",
                            icon: Icons.menu_book_rounded,
                            isSelected: _currentMode == CoreMode.estudiante,
                            activeColor: theme.secondaryColor,
                            onTap: () => setState(() => _currentMode = CoreMode.estudiante),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          foregroundColor: theme.textColor,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(theme.borderRadius),
                            side: BorderSide(color: theme.borderColor),
                          ),
                        ),
                        onPressed: _mostrarSelectorNuevoChat,
                        icon: Icon(Icons.add_rounded, size: 18, color: theme.primaryColor),
                        label: const Text("Nueva Instancia", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text("MATRICES LOCALES ACTIVAS", style: TextStyle(fontSize: 9, color: theme.subtitleColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _threads.length,
                        itemBuilder: (context, index) {
                          final thread = _threads[index];
                          final isSelected = thread.id == _activeThreadId;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            child: ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              selected: isSelected,
                              selectedTileColor: theme.cardColor,
                              leading: Icon(Icons.code_rounded, size: 16, color: isSelected ? theme.primaryColor : theme.subtitleColor),
                              title: Text(
                                thread.title,
                                style: TextStyle(color: isSelected ? theme.textColor : theme.subtitleColor, fontSize: 12.5),
                              ),
                              onTap: () {
                                setState(() {
                                  _activeThreadId = thread.id;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    if (_descargandoOta)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Descargando actualización...", style: TextStyle(fontSize: 9, color: Colors.amber)),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(value: _progresoOta, color: const Color(0xFFFF9500), minHeight: 2),
                          ],
                        ),
                      ),
                    if (_descargandoModelo)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Descargando pesos de IA...", style: TextStyle(fontSize: 9, color: theme.primaryColor)),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(value: _progresoModelo, color: theme.primaryColor, minHeight: 2),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text("User: ${widget.username} | V$_versionHub", style: TextStyle(fontSize: 9, color: theme.subtitleColor, fontFamily: 'monospace')),
                    )
                  ],
                ),
              ),
              
              // NÚCLEO DEL CHAT
              Expanded(
                child: Column(
                  children: [
                    // BARRA SUPERIOR CON SELECCIONADOR DE TEMA
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.surfaceColor,
                        border: Border(bottom: BorderSide(color: theme.borderColor, width: 0.8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _activeThread.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.memory_rounded, size: 12, color: theme.primaryColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Modelo: ${_activeThread.iaModel}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: Icon(Icons.palette_rounded, color: theme.primaryColor, size: 20),
                                tooltip: "Cambiar Tema Visual",
                                onPressed: () {
                                  _mostrarSelectorTemasModal(
                                    context,
                                    _currentThemeStyle,
                                    (newTheme) {
                                      setState(() {
                                        _currentThemeStyle = newTheme;
                                      });
                                      widget.onThemeChanged(newTheme);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(24),
                        itemCount: _activeThread.messages.length,
                        itemBuilder: (context, index) {
                          final msg = _activeThread.messages[index];
                          final sender = msg["sender"];
                          
                          Alignment align = Alignment.centerLeft;
                          BoxDecoration decoration = BoxDecoration(
                            color: theme.surfaceColor,
                            borderRadius: BorderRadius.circular(theme.borderRadius),
                            border: Border.all(color: theme.borderColor),
                            boxShadow: theme.shadows,
                          );
                          TextStyle textStyle = TextStyle(color: theme.textColor, fontSize: 14, height: 1.4);

                          if (sender == "user") {
                            align = Alignment.centerRight;
                            decoration = BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(theme.borderRadius),
                              border: Border.all(color: theme.primaryColor.withValues(alpha: 0.4)),
                            );
                          } else if (sender == "system") {
                            align = Alignment.center;
                            decoration = BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            );
                            textStyle = TextStyle(color: theme.primaryColor, fontSize: 11, fontFamily: 'monospace');
                          }

                          return Align(
                            alignment: align,
                            child: Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: decoration,
                              child: Text(msg["text"]!, style: textStyle),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: _descargandoModelo 
                          ? Column(
                              children: [
                                LinearProgressIndicator(value: _progresoModelo, color: theme.primaryColor),
                                const SizedBox(height: 8),
                                Text(
                                  "Descargando modelo: ${(_progresoModelo * 100).toStringAsFixed(0)}% completado",
                                  style: TextStyle(fontSize: 12, color: theme.subtitleColor),
                                ),
                              ],
                            )
                          : !_activeThread.modeloInicializado
                              ? ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF9500),
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () => _descargarModeloLlmNativamente(_activeThread),
                                  icon: const Icon(Icons.download_rounded),
                                  label: Text("Descargar Modelo Nativamente (${_activeThread.iaModel})"),
                                )
                              : Container(
                                  margin: const EdgeInsets.only(bottom: 8, left: 6, right: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: theme.surfaceColor,
                                      borderRadius: BorderRadius.circular(theme.borderRadius),
                                      border: Border.all(color: theme.borderColor, width: 1.2),
                                      boxShadow: theme.shadows,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextField(
                                          controller: _chatController,
                                          minLines: 1,
                                          maxLines: 5,
                                          style: TextStyle(color: theme.textColor, fontSize: 14, height: 1.4),
                                          decoration: InputDecoration(
                                            hintText: (_activeThread.pensando || _isGenerating) ? "Procesando matriz nativa..." : "Escribe un mensaje...",
                                            hintStyle: TextStyle(color: theme.subtitleColor, fontSize: 14),
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // BOTÓN TOOLBOX (MALETÍN / HERRAMIENTAS)
                                            InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: () => _mostrarModalToolbox(context),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: theme.primaryColor.withValues(alpha: 0.15),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3), width: 1),
                                                ),
                                                child: Icon(Icons.work_rounded, color: theme.primaryColor, size: 20),
                                              ),
                                            ),

                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _currentMode = _currentMode == CoreMode.normal
                                                          ? CoreMode.estudiante
                                                          : CoreMode.normal;
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: _currentMode == CoreMode.estudiante
                                                          ? theme.secondaryColor.withValues(alpha: 0.25)
                                                          : theme.primaryColor.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(
                                                        color: _currentMode == CoreMode.estudiante
                                                            ? theme.secondaryColor
                                                            : theme.primaryColor,
                                                        width: 1.0,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          _currentMode == CoreMode.estudiante ? Icons.school_rounded : Icons.bolt_rounded,
                                                          size: 13,
                                                          color: _currentMode == CoreMode.estudiante ? theme.secondaryColor : theme.primaryColor,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          _currentMode == CoreMode.estudiante ? "Estudiante" : "Local",
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: _currentMode == CoreMode.estudiante ? theme.secondaryColor : theme.primaryColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),

                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                  icon: Icon(
                                                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                                                    color: _isListening ? const Color(0xFFFF0055) : theme.subtitleColor,
                                                    size: 20,
                                                  ),
                                                  onPressed: _toggleListening,
                                                ),
                                                const SizedBox(width: 6),

                                                GestureDetector(
                                                  onTap: (_activeThread.pensando || _isGenerating) ? null : () async {
                                                    setState(() => _isGenerating = true);
                                                    try {
                                                      await _procesarMensajeLocal();
                                                    } finally {
                                                      setState(() => _isGenerating = false);
                                                    }
                                                  },
                                                  child: Container(
                                                    width: 38,
                                                    height: 38,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: theme.primaryColor,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: theme.primaryColor.withValues(alpha: 0.5),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Center(
                                                      child: (_activeThread.pensando || _isGenerating)
                                                          ? const SizedBox(
                                                              width: 16,
                                                              height: 16,
                                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                                            )
                                                          : const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 20),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidGlassButton({
    required AppThemeData theme,
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? activeColor : theme.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? activeColor : theme.subtitleColor),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : theme.subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHardwareTelemetryCard(AppThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.developer_board_rounded, color: theme.primaryColor, size: 16),
              const SizedBox(width: 6),
              Text(
                "HARDWARE GALAXY TAB",
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cuerpos CPU:", style: TextStyle(fontSize: 10, color: theme.subtitleColor)),
              Text("$_cpuCores Hilos", style: TextStyle(fontSize: 10, color: theme.textColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("RAM Libre:", style: TextStyle(fontSize: 10, color: theme.subtitleColor)),
              Text("${_freeRamGb.toStringAsFixed(1)} GB / ${_totalRamGb.toStringAsFixed(1)} GB", style: TextStyle(fontSize: 10, color: theme.primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  void _mostrarSelectorNuevoChat() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = AppThemeConfig.getTheme(_currentThemeStyle);
        return AlertDialog(
          backgroundColor: theme.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.borderRadius)),
          title: Text("Nueva Instancia de IA Local", style: TextStyle(color: theme.textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _modelosDisponibles.map((model) {
              return ListTile(
                title: Text(model.name, style: TextStyle(color: theme.textColor, fontSize: 14)),
                subtitle: Text("${model.size} | RAM Req: ${model.requiredRamGb}GB", style: TextStyle(color: theme.subtitleColor, fontSize: 11)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: model.badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(model.badge, style: TextStyle(color: model.badgeColor, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _crearNuevaInstanciaLocal(model.id);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// --- WIDGET DE MODAL DE ERROR ESTILO WINDOWS XP / 2000 ---
class WindowsXPErrorDialog extends StatelessWidget {
  final String mensaje;
  final String titulo;

  const WindowsXPErrorDialog({
    super.key,
    required this.mensaje,
    this.titulo = "Error crítico - Vantablack Hub",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      decoration: const BoxDecoration(
        color: Color(0xFFECE9D8),
        border: Border(
          top: BorderSide(color: Colors.white, width: 2),
          left: BorderSide(color: Colors.white, width: 2),
          right: BorderSide(color: Color(0xFF404040), width: 2),
          bottom: BorderSide(color: Color(0xFF404040), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // BARRA DE TÍTULO DE WINDOWS XP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0055EA), Color(0xFF0A246A)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          titulo,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD42A00),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Center(
                      child: Icon(Icons.close, color: Colors.white, size: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // CUERPO DEL DIÁLOGO (CÍRCULO ROJO CON 'X' Y TEXTO DESCRIPTIVO)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD32F2F),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    mensaje,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // BOTÓN INFERIOR RETRO [ ACEPTAR ]
          Padding(
            padding: const EdgeInsets.only(bottom: 14.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECE9D8),
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 2),
                        left: BorderSide(color: Colors.white, width: 2),
                        right: BorderSide(color: Color(0xFF404040), width: 2),
                        bottom: BorderSide(color: Color(0xFF404040), width: 2),
                      ),
                    ),
                    child: const Text(
                      "Aceptar",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}