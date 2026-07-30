import 'package:flutter/material.dart';
import '../../models/app_theme.dart';
import '../../services/app_settings.dart';
import '../widgets/theme_selector_modal.dart';
import '../widgets/dynamic_multicolor_background.dart';
import 'home_screen.dart';

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
      body: DynamicMulticolorBackground(
        child: Container(
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
                        onPressed: () => mostrarSelectorTemasModal(context, widget.currentTheme, widget.onThemeChanged),
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
    ),
  );
}
}
