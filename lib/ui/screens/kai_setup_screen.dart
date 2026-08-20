import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/app_theme.dart';
import '../../models/kai_persona.dart';
import '../../services/app_settings.dart';
import '../../services/memory_service.dart';
import '../../services/kai_tts_service.dart';
import '../widgets/dynamic_multicolor_background.dart';
import '../widgets/kai_avatar_view.dart';

/// Pantalla de configuración y bienvenida inicial estilo Apple Setup Assistant
/// con transiciones fluidas, diseño Vantablack Glass y personalización inclusiva.
class KaiSetupScreen extends StatefulWidget {
  final AppThemeStyle initialTheme;
  final Function(String username, AppThemeStyle theme) onComplete;

  const KaiSetupScreen({
    super.key,
    required this.initialTheme,
    required this.onComplete,
  });

  @override
  State<KaiSetupScreen> createState() => _KaiSetupScreenState();
}

class _KaiSetupScreenState extends State<KaiSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  late AppThemeStyle _selectedTheme;
  late TextEditingController _nameController;
  late TextEditingController _customGenderController;

  String _selectedDialect = "es-US";
  String _selectedDialectName = "Español Internacional";
  String _selectedGender = "Masculino";
  bool _isCustomGender = false;

  final List<String> _helloGreetings = [
    "Hola",
    "Hello",
    "Bonjour",
    "Ciao",
    "Olá",
    "こんにちは",
  ];
  int _greetingIndex = 0;
  Timer? _greetingTimer;

  final List<Map<String, String>> _dialects = [
    {
      "code": "es-US",
      "flag": "🌐",
      "name": "Español Neutro Internacional",
      "desc": "Estándar global, ingeniería y desarrollo",
    },
    {
      "code": "es-MX",
      "flag": "🇲🇽",
      "name": "Español México",
      "desc": "Neutro latinoamericano y amigable",
    },
    {
      "code": "es-ES",
      "flag": "🇪🇸",
      "name": "Español España",
      "desc": "Castizo peninsular y técnico formal",
    },
    {
      "code": "es-AR",
      "flag": "🇦🇷",
      "name": "Español Argentina",
      "desc": "Río de la Plata y dinámico",
    },
    {
      "code": "es-CO",
      "flag": "🇨🇴",
      "name": "Español Colombia",
      "desc": "Claro, pausado y articulado",
    },
  ];

  final List<Map<String, String>> _genderOptions = [
    {
      "title": "Masculino",
      "emoji": "👨‍💻",
      "desc": "Trato: Bienvenido, Amigo, Desarrollador",
    },
    {
      "title": "Femenino",
      "emoji": "👩‍💻",
      "desc": "Trato: Bienvenida, Amiga, Desarrolladora",
    },
    {
      "title": "No binario / Neutro",
      "emoji": "🧑‍💻",
      "desc": "Trato: Bienvenide, Colega, Desarrolladore",
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.initialTheme;
    _nameController = TextEditingController(text: "Gustavo");
    _customGenderController = TextEditingController();

    _greetingTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (mounted) {
        setState(() {
          _greetingIndex = (_greetingIndex + 1) % _helloGreetings.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _pageController.dispose();
    _nameController.dispose();
    _customGenderController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _greetingTimer?.cancel();
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finishSetup() async {
    final username = _nameController.text.trim().isEmpty ? "Usuario Kai" : _nameController.text.trim();
    final gender = _isCustomGender && _customGenderController.text.trim().isNotEmpty
        ? _customGenderController.text.trim()
        : _selectedGender;

    // 1. Guardar configuración completa en SharedPreferences
    await AppSettings.completeSetup(
      username: username,
      dialect: _selectedDialectName,
      gender: gender,
      theme: _selectedTheme,
    );

    // 2. Inicializar memorias clave aprendidas
    await MemoryService.instance.init();
    await MemoryService.instance.addMemory("El nombre del usuario es $username.");
    await MemoryService.instance.addMemory("Dialecto preferido: $_selectedDialectName.");
    await MemoryService.instance.addMemory("Preferencia de trato e identidad: $gender.");
    await MemoryService.instance.addMemory("Asistente oficial: Kai (Motor Cognitivo Vantablack).");

    // 3. Saludo vocal de Kai
    KaiTtsService.instance.speakWithEmotion(
      "¡Hola $username! Todo está listo. Es un gran gusto estar contigo. Comencemos a crear.",
      KaiEmotion.happy,
    );

    // 4. Notificar finalización
    widget.onComplete(username, _selectedTheme);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeConfig.getTheme(_selectedTheme);
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.backgroundColor,
      body: DynamicMulticolorBackground(
        child: Container(
          decoration: BoxDecoration(gradient: theme.backgroundGradient),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isLandscape ? 720 : 540,
                  maxHeight: isLandscape ? 440 : 800,
                ),
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 20 : 16,
                    vertical: isLandscape ? 8 : 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(theme.borderRadius),
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: theme.shadows,
                  ),
                  child: Column(
                    children: [
                      // BARRA SUPERIOR DE PROGRESO ESTILO APPLE SETUP
                      Padding(
                        padding: const EdgeInsets.only(top: 14, left: 16, right: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentPage > 0)
                              IconButton(
                                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: theme.subtitleColor),
                                tooltip: "Paso anterior",
                                onPressed: _previousPage,
                              )
                            else
                              const SizedBox(width: 40),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(_totalPages, (index) {
                                final isActive = index == _currentPage;
                                final isPassed = index < _currentPage;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: isActive ? 22 : 8,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: isActive
                                        ? theme.primaryColor
                                        : (isPassed
                                            ? theme.primaryColor.withValues(alpha: 0.4)
                                            : theme.borderColor),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),

                      // CUERPO DEL SETUP (PAGE VIEW ANIMADO)
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (page) {
                            setState(() => _currentPage = page);
                          },
                          children: [
                            _buildStep1Welcome(theme, isLandscape),
                            _buildStep2Username(theme, isLandscape),
                            _buildStep3Dialect(theme, isLandscape),
                            _buildStep4Gender(theme, isLandscape),
                            _buildStep5Summary(theme, isLandscape),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- PASO 1: BIENVENIDA (HELLO / HOLA) ---
  Widget _buildStep1Welcome(AppThemeData theme, bool isLandscape) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isLandscape ? 16 : 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              _helloGreetings[_greetingIndex],
              key: ValueKey(_helloGreetings[_greetingIndex]),
              style: TextStyle(
                fontSize: isLandscape ? 30 : 42,
                fontWeight: FontWeight.w300,
                letterSpacing: 2.0,
                color: theme.textColor,
                fontFamily: 'sans-serif',
              ),
            ),
          ),
          SizedBox(height: isLandscape ? 10 : 16),
          KaiAvatarView(
            emotion: KaiEmotion.happy,
            size: isLandscape ? 68 : 88,
            isThinking: true,
            theme: theme,
          ),
          SizedBox(height: isLandscape ? 12 : 20),
          Text(
            "Bienvenido a Kai",
            style: TextStyle(
              fontSize: isLandscape ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Tu asistente técnico de élite y núcleo de inteligencia artificial local para Vantablack Hub.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isLandscape ? 11.5 : 13,
              color: theme.subtitleColor,
              height: 1.4,
            ),
          ),
          SizedBox(height: isLandscape ? 16 : 28),
          _buildActionButton(
            theme: theme,
            label: "Comenzar Configuración",
            icon: Icons.arrow_forward_rounded,
            onTap: _nextPage,
            isLandscape: isLandscape,
          ),
        ],
      ),
    );
  }

  // --- PASO 2: NOMBRE DE USUARIO ---
  Widget _buildStep2Username(AppThemeData theme, bool isLandscape) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isLandscape ? 16 : 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          KaiAvatarView(
            emotion: KaiEmotion.neutral,
            size: isLandscape ? 52 : 68,
            theme: theme,
          ),
          SizedBox(height: isLandscape ? 10 : 16),
          Text(
            "¿Cómo te llamas?",
            style: TextStyle(
              fontSize: isLandscape ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Kai utilizará este nombre para comunicarse contigo y personalizar su asistencia.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isLandscape ? 11.5 : 13, color: theme.subtitleColor),
          ),
          SizedBox(height: isLandscape ? 14 : 24),
          TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textColor,
              fontSize: isLandscape ? 16 : 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: "Escribe tu nombre...",
              hintStyle: TextStyle(color: theme.subtitleColor),
              filled: true,
              fillColor: theme.backgroundColor.withValues(alpha: 0.6),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.primaryColor, width: 1.6),
              ),
            ),
            onSubmitted: (_) => _nextPage(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ["Gustavo", "Alex", "Dev", "Ingeniero"].map((name) {
              return ActionChip(
                backgroundColor: theme.cardColor,
                side: BorderSide(color: theme.borderColor),
                label: Text(name, style: TextStyle(color: theme.subtitleColor, fontSize: 11)),
                onPressed: () {
                  setState(() {
                    _nameController.text = name;
                  });
                },
              );
            }).toList(),
          ),
          SizedBox(height: isLandscape ? 14 : 24),
          _buildActionButton(
            theme: theme,
            label: "Continuar",
            icon: Icons.arrow_forward_rounded,
            onTap: _nextPage,
            isLandscape: isLandscape,
          ),
        ],
      ),
    );
  }

  // --- PASO 3: IDIOMA / DIALECTO ---
  Widget _buildStep3Dialect(AppThemeData theme, bool isLandscape) {
    return Padding(
      padding: EdgeInsets.all(isLandscape ? 12 : 20),
      child: Column(
        children: [
          Text(
            "Selecciona tu Dialecto",
            style: TextStyle(
              fontSize: isLandscape ? 17 : 20,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Configura la entonación para la voz acústica TTS y el vocabulario de Kai.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isLandscape ? 11 : 12.5, color: theme.subtitleColor),
          ),
          SizedBox(height: isLandscape ? 10 : 16),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _dialects.length,
              itemBuilder: (context, index) {
                final dialect = _dialects[index];
                final isSelected = _selectedDialect == dialect["code"];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _selectedDialect = dialect["code"]!;
                        _selectedDialectName = dialect["name"]!;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primaryColor.withValues(alpha: 0.18)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? theme.primaryColor : theme.borderColor,
                          width: isSelected ? 1.5 : 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(dialect["flag"]!, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dialect["name"]!,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 13,
                                    color: isSelected ? theme.textColor : theme.textColor,
                                  ),
                                ),
                                Text(
                                  dialect["desc"]!,
                                  style: TextStyle(fontSize: 10.5, color: theme.subtitleColor),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, color: theme.primaryColor, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            theme: theme,
            label: "Continuar",
            icon: Icons.arrow_forward_rounded,
            onTap: _nextPage,
            isLandscape: isLandscape,
          ),
        ],
      ),
    );
  }

  // --- PASO 4: IDENTIDAD / GÉNERO INCLUSIVO ---
  Widget _buildStep4Gender(AppThemeData theme, bool isLandscape) {
    return Padding(
      padding: EdgeInsets.all(isLandscape ? 12 : 20),
      child: Column(
        children: [
          Text(
            "Trato e Identidad",
            style: TextStyle(
              fontSize: isLandscape ? 17 : 20,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Selecciona cómo prefieres que Kai se dirija a ti de forma inclusiva y natural.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isLandscape ? 11 : 12.5, color: theme.subtitleColor),
          ),
          SizedBox(height: isLandscape ? 10 : 16),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                ..._genderOptions.map((opt) {
                  final isSelected = !_isCustomGender && _selectedGender == opt["title"];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _isCustomGender = false;
                          _selectedGender = opt["title"]!;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.primaryColor.withValues(alpha: 0.18)
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? theme.primaryColor : theme.borderColor,
                            width: isSelected ? 1.5 : 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(opt["emoji"]!, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opt["title"]!,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 13,
                                      color: theme.textColor,
                                    ),
                                  ),
                                  Text(
                                    opt["desc"]!,
                                    style: TextStyle(fontSize: 10.5, color: theme.subtitleColor),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: theme.primaryColor, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // OPCIÓN PERSONALIZADA
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _isCustomGender = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isCustomGender
                            ? theme.primaryColor.withValues(alpha: 0.18)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isCustomGender ? theme.primaryColor : theme.borderColor,
                          width: _isCustomGender ? 1.5 : 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text("✏️", style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Personalizado / Prefiero especificarlo",
                                  style: TextStyle(
                                    fontWeight: _isCustomGender ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 13,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                              if (_isCustomGender)
                                Icon(Icons.check_circle_rounded, color: theme.primaryColor, size: 20),
                            ],
                          ),
                          if (_isCustomGender) ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: _customGenderController,
                              style: TextStyle(color: theme.textColor, fontSize: 12.5),
                              decoration: InputDecoration(
                                hintText: "Ej. Desarrolladorx, Ingeniere, etc.",
                                hintStyle: TextStyle(color: theme.subtitleColor),
                                isDense: true,
                                filled: true,
                                fillColor: theme.backgroundColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            theme: theme,
            label: "Continuar",
            icon: Icons.arrow_forward_rounded,
            onTap: _nextPage,
            isLandscape: isLandscape,
          ),
        ],
      ),
    );
  }

  // --- PASO 5: RESUMEN Y ACTIVACIÓN ---
  Widget _buildStep5Summary(AppThemeData theme, bool isLandscape) {
    final username = _nameController.text.trim().isEmpty ? "Gustavo" : _nameController.text.trim();
    final gender = _isCustomGender && _customGenderController.text.trim().isNotEmpty
        ? _customGenderController.text.trim()
        : _selectedGender;

    return Padding(
      padding: EdgeInsets.all(isLandscape ? 14 : 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          KaiAvatarView(
            emotion: KaiEmotion.smug,
            size: isLandscape ? 64 : 80,
            isThinking: true,
            theme: theme,
          ),
          SizedBox(height: isLandscape ? 8 : 14),
          Text(
            "¡Todo Listo, $username!",
            style: TextStyle(
              fontSize: isLandscape ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Kai ha sincronizado tus preferencias en su memoria local.",
            style: TextStyle(fontSize: isLandscape ? 11 : 12.5, color: theme.subtitleColor),
          ),
          SizedBox(height: isLandscape ? 10 : 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.borderColor),
            ),
            child: Column(
              children: [
                _buildSummaryRow("Usuario", username, theme.primaryColor),
                const Divider(height: 12, color: Colors.white10),
                _buildSummaryRow("Dialecto", _selectedDialectName, theme.secondaryColor),
                const Divider(height: 12, color: Colors.white10),
                _buildSummaryRow("Trato", gender, theme.textColor),
                const Divider(height: 12, color: Colors.white10),
                _buildSummaryRow("Motor", "Vantablack Hub v3.0.0", theme.primaryColor),
              ],
            ),
          ),
          SizedBox(height: isLandscape ? 14 : 22),
          _buildActionButton(
            theme: theme,
            label: "⚡ Activar Núcleo de Kai",
            icon: Icons.check_rounded,
            onTap: _finishSetup,
            isLandscape: isLandscape,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.white60)),
        Text(
          value,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required AppThemeData theme,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isLandscape,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.black,
        minimumSize: Size(double.infinity, isLandscape ? 40 : 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 4,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isLandscape ? 12.5 : 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
