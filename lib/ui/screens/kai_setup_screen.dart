import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/app_theme.dart';
import '../../models/kai_persona.dart';
import '../../services/app_settings.dart';
import '../../services/device_profile.dart';
import '../../services/memory_service.dart';
import '../../services/kai_tts_service.dart';
import '../../services/neural_tts_service.dart';
import '../widgets/chat/chat_style.dart';

/// Configuración inicial al estilo del Asistente de Configuración de Apple:
/// un "Hola" multilingüe, títulos grandes, listas con palomita y un botón
/// tipo píldora siempre en la parte inferior.
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
  static const int _totalPages = 6;

  late AppThemeStyle _selectedTheme;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _customGenderController = TextEditingController();

  String _selectedDialectName = "Español Neutro Internacional";
  String _selectedGender = "Masculino";
  bool _isCustomGender = false;
  bool? _voiceChoice;

  static const List<String> _helloGreetings = [
    "Hola",
    "Hello",
    "Bonjour",
    "Ciao",
    "Olá",
    "Hallo",
    "こんにちは",
  ];
  int _greetingIndex = 0;
  Timer? _greetingTimer;

  static const List<Map<String, String>> _dialects = [
    {"flag": "🌐", "name": "Español Neutro Internacional", "desc": "Claro y estándar para todos"},
    {"flag": "🇲🇽", "name": "Español México", "desc": "Cercano y amigable"},
    {"flag": "🇪🇸", "name": "Español España", "desc": "Peninsular"},
    {"flag": "🇦🇷", "name": "Español Argentina", "desc": "Rioplatense"},
    {"flag": "🇨🇴", "name": "Español Colombia", "desc": "Pausado y articulado"},
  ];

  static const List<Map<String, String>> _genderOptions = [
    {"title": "Masculino", "desc": "Bienvenido, amigo"},
    {"title": "Femenino", "desc": "Bienvenida, amiga"},
    {"title": "No binario / Neutro", "desc": "Te doy la bienvenida, colega"},
  ];

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.initialTheme;
    _greetingTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (mounted) {
        setState(() => _greetingIndex = (_greetingIndex + 1) % _helloGreetings.length);
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
    FocusScope.of(context).unfocus();
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    }
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    }
  }

  /// Por defecto, voz neuronal salvo en equipos de gama baja.
  bool get _useNeuralVoice => _voiceChoice ?? !DeviceProfile.instance.isLowEnd;

  String get _username {
    final name = _nameController.text.trim();
    return name.isEmpty ? "Usuario Kai" : name;
  }

  Future<void> _finishSetup() async {
    final username = _username;
    final gender = _isCustomGender && _customGenderController.text.trim().isNotEmpty
        ? _customGenderController.text.trim()
        : _selectedGender;

    await AppSettings.completeSetup(
      username: username,
      dialect: _selectedDialectName,
      gender: gender,
      theme: _selectedTheme,
    );

    await MemoryService.instance.init();
    await MemoryService.instance.addMemory("El nombre del usuario es $username.");
    await MemoryService.instance.addMemory("Dialecto preferido: $_selectedDialectName.");
    await MemoryService.instance.addMemory("Preferencia de trato e identidad: $gender.");
    await MemoryService.instance.addMemory("Asistente oficial: Kai (Motor Cognitivo Vantablack).");

    await KaiTtsService.instance.setUseNeural(_useNeuralVoice);
    if (_useNeuralVoice) {
      // La voz se descarga en segundo plano: el usuario puede empezar a chatear ya.
      final voice = NeuralTtsService.instance.recommendedVoice;
      unawaited(NeuralTtsService.instance.download(voice).catchError((Object e) {
        debugPrint("Descarga de voz en segundo plano falló: $e");
      }));
    }

    KaiTtsService.instance.speakWithEmotion(
      "¡Hola $username! Todo está listo. Me da mucho gusto conocerte.",
      KaiEmotion.happy,
    );

    widget.onComplete(username, _selectedTheme);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeConfig.getTheme(_selectedTheme);
    final colors = ChatColors.of(theme);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colors.accent),
                      tooltip: "Paso anterior",
                      onPressed: _previousPage,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: _currentPage == 0
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(end: _currentPage / (_totalPages - 1)),
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) => LinearProgressIndicator(
                                  value: value,
                                  minHeight: 3,
                                  color: colors.accent,
                                  backgroundColor: colors.surfaceHigh,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildHello(colors),
                  _buildName(colors),
                  _buildDialect(colors),
                  _buildGender(colors),
                  _buildVoice(colors),
                  _buildDone(colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Estructura común de cada paso: contenido desplazable centrado y botón fijo abajo.
  Widget _page({
    required ChatColors colors,
    required List<Widget> children,
    required String buttonLabel,
    required VoidCallback? onPressed,
    bool centered = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 460;
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: compact ? 8 : 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(28, 8, 28, compact ? 10 : 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.text,
                      foregroundColor: colors.background,
                      disabledBackgroundColor: colors.surfaceHigh,
                      disabledForegroundColor: colors.muted,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                    ),
                    child: Text(buttonLabel, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _title(ChatColors colors, String text, {TextAlign align = TextAlign.start}) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(color: colors.text, fontSize: 32, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.6),
    );
  }

  Widget _subtitle(ChatColors colors, String text, {TextAlign align = TextAlign.start}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(text, textAlign: align, style: TextStyle(color: colors.muted, fontSize: 16, height: 1.4)),
    );
  }

  // --- 1. HOLA ---
  Widget _buildHello(ChatColors colors) {
    return _page(
      colors: colors,
      centered: true,
      buttonLabel: "Comenzar",
      onPressed: _nextPage,
      children: [
        const SizedBox(height: 40),
        SizedBox(
          height: 90,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(animation), child: child),
            ),
            child: ShaderMask(
              key: ValueKey(_greetingIndex),
              shaderCallback: (bounds) => colors.brandGradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Text(
                _helloGreetings[_greetingIndex],
                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w600, letterSpacing: -1.5, color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          "Bienvenido a Kai",
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.text, fontSize: 24, fontWeight: FontWeight.w600),
        ),
        _subtitle(
          colors,
          "Tu asistente con inteligencia artificial que funciona en tu dispositivo, incluso sin internet.",
          align: TextAlign.center,
        ),
      ],
    );
  }

  // --- 2. NOMBRE ---
  Widget _buildName(ChatColors colors) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _nameController,
      builder: (context, value, _) {
        return _page(
          colors: colors,
          buttonLabel: "Continuar",
          onPressed: value.text.trim().isEmpty ? null : _nextPage,
          children: [
            _title(colors, "¿Cómo te llamas?"),
            _subtitle(colors, "Kai usará tu nombre para hablarte de forma personal."),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: colors.text, fontSize: 24, fontWeight: FontWeight.w500),
              cursorColor: colors.accent,
              decoration: InputDecoration(
                hintText: "Tu nombre",
                hintStyle: TextStyle(color: colors.muted.withValues(alpha: 0.6)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.divider, width: 1.5)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.accent, width: 2)),
              ),
              onSubmitted: (_) {
                if (_nameController.text.trim().isNotEmpty) _nextPage();
              },
            ),
          ],
        );
      },
    );
  }

  /// Lista agrupada estilo Ajustes de iOS con una palomita en la opción elegida.
  Widget _groupedList(ChatColors colors, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 16, color: colors.divider),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _optionRow(
    ChatColors colors, {
    required String title,
    String? subtitle,
    String? leading,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            if (leading != null) ...[
              Text(leading, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: colors.text, fontSize: 16)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle, style: TextStyle(color: colors.muted, fontSize: 13)),
                    ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(Icons.check_rounded, color: colors.accent, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. DIALECTO ---
  Widget _buildDialect(ChatColors colors) {
    return _page(
      colors: colors,
      buttonLabel: "Continuar",
      onPressed: _nextPage,
      children: [
        _title(colors, "¿Cómo hablas?"),
        _subtitle(colors, "Kai adaptará sus expresiones y su voz a tu forma de hablar."),
        const SizedBox(height: 24),
        _groupedList(colors, [
          for (final d in _dialects)
            _optionRow(
              colors,
              leading: d["flag"],
              title: d["name"]!,
              subtitle: d["desc"],
              selected: _selectedDialectName == d["name"],
              onTap: () => setState(() => _selectedDialectName = d["name"]!),
            ),
        ]),
      ],
    );
  }

  // --- 4. TRATO ---
  Widget _buildGender(ChatColors colors) {
    return _page(
      colors: colors,
      buttonLabel: "Continuar",
      onPressed: _nextPage,
      children: [
        _title(colors, "¿Cómo prefieres que te trate?"),
        _subtitle(colors, "Kai usará el género gramatical que elijas al hablarte."),
        const SizedBox(height: 24),
        _groupedList(colors, [
          for (final g in _genderOptions)
            _optionRow(
              colors,
              title: g["title"]!,
              subtitle: g["desc"],
              selected: !_isCustomGender && _selectedGender == g["title"],
              onTap: () => setState(() {
                _isCustomGender = false;
                _selectedGender = g["title"]!;
              }),
            ),
          _optionRow(
            colors,
            title: "Otro",
            subtitle: "Escríbelo a tu manera",
            selected: _isCustomGender,
            onTap: () => setState(() => _isCustomGender = true),
          ),
        ]),
        if (_isCustomGender) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _customGenderController,
            style: TextStyle(color: colors.text, fontSize: 16),
            cursorColor: colors.accent,
            decoration: InputDecoration(
              hintText: "¿Cómo quieres que te trate?",
              hintStyle: TextStyle(color: colors.muted),
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ],
      ],
    );
  }

  // --- 5. VOZ ---
  Widget _buildVoice(ChatColors colors) {
    final voice = NeuralTtsService.instance.recommendedVoice;
    return _page(
      colors: colors,
      buttonLabel: "Continuar",
      onPressed: _nextPage,
      children: [
        _title(colors, "Elige la voz de Kai"),
        _subtitle(colors, "Puedes cambiarla cuando quieras en Ajustes › Voz de Kai."),
        const SizedBox(height: 24),
        _groupedList(colors, [
          _optionRow(
            colors,
            leading: "🎙️",
            title: "Voz neuronal hiperrealista",
            subtitle: "Suena casi humana y funciona sin internet. Se descarga una vez (${voice.sizeMb} MB) "
                "mientras usas la app.",
            selected: _useNeuralVoice,
            onTap: () => setState(() => _voiceChoice = true),
          ),
          _optionRow(
            colors,
            leading: "📱",
            title: "Voz del sistema",
            subtitle: "Sin descargas. Más ligera, pero suena más robótica.",
            selected: !_useNeuralVoice,
            onTap: () => setState(() => _voiceChoice = false),
          ),
        ]),
        if (DeviceProfile.instance.isLowEnd)
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 4),
            child: Text(
              "Tu equipo es de gama de entrada: si eliges la voz neuronal se usará la versión ligera.",
              style: TextStyle(color: colors.muted, fontSize: 13),
            ),
          ),
      ],
    );
  }

  // --- 6. LISTO ---
  Widget _buildDone(ChatColors colors) {
    return _page(
      colors: colors,
      centered: true,
      buttonLabel: "Empezar a usar Kai",
      onPressed: _finishSetup,
      children: [
        const SizedBox(height: 32),
        TweenAnimationBuilder<double>(
          key: ValueKey(_currentPage == _totalPages - 1),
          tween: Tween(begin: 0.6, end: 1.0),
          duration: const Duration(milliseconds: 650),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: colors.brandGradient),
            child: Icon(Icons.check_rounded, color: colors.background, size: 52),
          ),
        ),
        const SizedBox(height: 28),
        _title(colors, "Todo listo, $_username", align: TextAlign.center),
        _subtitle(
          colors,
          "Kai ya está configurado. Descarga un modelo desde el menú para empezar a conversar sin internet.",
          align: TextAlign.center,
        ),
      ],
    );
  }
}
