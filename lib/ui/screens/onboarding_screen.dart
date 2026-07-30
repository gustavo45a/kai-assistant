import 'package:flutter/material.dart';
import '../../models/app_theme.dart';
import '../../services/app_settings.dart';
import '../widgets/dynamic_multicolor_background.dart';

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
      body: DynamicMulticolorBackground(
        child: Container(
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
    ),
  );
}
}
