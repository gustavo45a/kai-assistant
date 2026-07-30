import 'package:flutter/material.dart';

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
