import 'package:flutter/material.dart';

import '../../data/models/alert.dart';

/// Escala única de espaçamentos: nenhuma tela define valores "soltos".
class AppSpacing {
  const AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;

  static const page = EdgeInsets.all(20);
}

/// Cantos bem arredondados deixam a interface mais amigável.
class AppRadius {
  const AppRadius._();
  static const card = 28.0;
  static const button = 20.0;
  static const field = 16.0;
  static const pill = 999.0;
}

/// Largura máxima do conteúdo em telas grandes (tablet/web).
const kContentMaxWidth = 960.0;

/// Cores semânticas de status, com variante própria em cada tema para manter
/// o contraste sobre a superfície correspondente.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.ok,
    required this.attention,
    required this.warning,
    required this.critical,
    required this.forecast,
  });

  final Color ok;
  final Color attention;
  final Color warning;
  final Color critical;

  /// Cor das linhas de previsão nos gráficos.
  final Color forecast;

  Color forSeverity(AlertSeverity severity) => switch (severity) {
    AlertSeverity.attention => attention,
    AlertSeverity.warning => warning,
    AlertSeverity.critical => critical,
  };

  @override
  StatusColors copyWith({
    Color? ok,
    Color? attention,
    Color? warning,
    Color? critical,
    Color? forecast,
  }) => StatusColors(
    ok: ok ?? this.ok,
    attention: attention ?? this.attention,
    warning: warning ?? this.warning,
    critical: critical ?? this.critical,
    forecast: forecast ?? this.forecast,
  );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      ok: Color.lerp(ok, other.ok, t)!,
      attention: Color.lerp(attention, other.attention, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      forecast: Color.lerp(forecast, other.forecast, t)!,
    );
  }
}

/// Paleta da marca "Pulso do Território": azul-índigo institucional (passa
/// confiança, como um serviço público) com fundos lavanda e tons pastel
/// por painel, para um visual acolhedor e fácil de entender por qualquer
/// pessoa. Cores sólidas, sem degradês.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.lilac,
    required this.sky,
    required this.peach,
    required this.sun,
    required this.onTint,
    required this.accent,
    required this.hero,
    required this.onHero,
    required this.heroAccent,
    required this.heroButton,
    required this.onHeroButton,
    this.highContrast = false,
  });

  /// Fundos pastel usados nos cartões (cada painel tem o seu).
  final Color lilac;
  final Color sky;
  final Color peach;
  final Color sun;

  /// Texto sobre os fundos pastel.
  final Color onTint;

  /// Destaque para números importantes (variações, contagens).
  final Color accent;

  /// Cartão de destaque da tela inicial (cor sólida).
  final Color hero;
  final Color onHero;
  final Color heroAccent;
  final Color heroButton;
  final Color onHeroButton;

  /// Tema de alto contraste: cartões ganham borda.
  final bool highContrast;

  @override
  BrandColors copyWith({
    Color? lilac,
    Color? sky,
    Color? peach,
    Color? sun,
    Color? onTint,
    Color? accent,
    Color? hero,
    Color? onHero,
    Color? heroAccent,
    Color? heroButton,
    Color? onHeroButton,
    bool? highContrast,
  }) => BrandColors(
    lilac: lilac ?? this.lilac,
    sky: sky ?? this.sky,
    peach: peach ?? this.peach,
    sun: sun ?? this.sun,
    onTint: onTint ?? this.onTint,
    accent: accent ?? this.accent,
    hero: hero ?? this.hero,
    onHero: onHero ?? this.onHero,
    heroAccent: heroAccent ?? this.heroAccent,
    heroButton: heroButton ?? this.heroButton,
    onHeroButton: onHeroButton ?? this.onHeroButton,
    highContrast: highContrast ?? this.highContrast,
  );

  @override
  BrandColors lerp(BrandColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return BrandColors(
      lilac: l(lilac, other.lilac),
      sky: l(sky, other.sky),
      peach: l(peach, other.peach),
      sun: l(sun, other.sun),
      onTint: l(onTint, other.onTint),
      accent: l(accent, other.accent),
      hero: l(hero, other.hero),
      onHero: l(onHero, other.onHero),
      heroAccent: l(heroAccent, other.heroAccent),
      heroButton: l(heroButton, other.heroButton),
      onHeroButton: l(onHeroButton, other.onHeroButton),
      highContrast: t < 0.5 ? highContrast : other.highContrast,
    );
  }
}

extension ThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  StatusColors get status => Theme.of(this).extension<StatusColors>()!;
  BrandColors get brand => Theme.of(this).extension<BrandColors>()!;
}

/// O app tem um único tema visual. O tema de alto contraste é aplicado
/// automaticamente quando o aparelho está com essa opção de acessibilidade
/// ligada, sem precisar de botão dentro do app.
class AppTheme {
  const AppTheme._();

  static const _indigo = Color(0xFF2E3A8C);
  static const _ink = Color(0xFF1B2150);

  // ---------------------------------------------------------------- claro
  static const _lightBrand = BrandColors(
    lilac: Color(0xFFECE7FB),
    sky: Color(0xFFE2EAFB),
    peach: Color(0xFFFFE7DB),
    sun: Color(0xFFFFF1CC),
    onTint: _ink,
    accent: Color(0xFF6A4BD6),
    hero: Color(0xFF242D72),
    onHero: Color(0xFFFFFFFF),
    heroAccent: Color(0xFFFFCF5C),
    heroButton: Color(0xFFEEF0FD),
    onHeroButton: Color(0xFF242D72),
  );

  static const _lightStatus = StatusColors(
    ok: Color(0xFF1B7F3B),
    attention: Color(0xFF8A5A00),
    warning: Color(0xFFB34700),
    critical: Color(0xFFB3261E),
    forecast: Color(0xFF6A4BD6),
  );

  static final _lightScheme = ColorScheme.fromSeed(seedColor: _indigo).copyWith(
    primary: _indigo,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFDDE2FA),
    onPrimaryContainer: const Color(0xFF151B4D),
    secondary: const Color(0xFF6A4BD6),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFECE7FB),
    onSecondaryContainer: const Color(0xFF26145F),
    surface: const Color(0xFFF5F6FD),
    onSurface: _ink,
    onSurfaceVariant: const Color(0xFF545B82),
    surfaceContainerLow: const Color(0xFFE9ECFA),
    surfaceContainer: const Color(0xFFE1E5F7),
    surfaceContainerHighest: const Color(0xFFD6DBF2),
    outline: const Color(0xFF767DA3),
    outlineVariant: const Color(0xFFD3D8EF),
  );

  // -------------------------------------------------------- alto contraste
  static const _hcBrand = BrandColors(
    lilac: Color(0xFF00294D),
    sky: Color(0xFF00294D),
    peach: Color(0xFF00294D),
    sun: Color(0xFF00294D),
    onTint: Colors.white,
    accent: Color(0xFFFFE14D),
    hero: Color(0xFF00294D),
    onHero: Colors.white,
    heroAccent: Color(0xFFFFE14D),
    heroButton: Color(0xFFFFE14D),
    onHeroButton: Color(0xFF001B33),
    highContrast: true,
  );

  static const _hcStatus = StatusColors(
    ok: Color(0xFF5CFF9D),
    attention: Color(0xFFFFE14D),
    warning: Color(0xFFFFB347),
    critical: Color(0xFFFF8A8A),
    forecast: Color(0xFF7FDBFF),
  );

  /// Azul-marinho profundo com texto branco e destaques em amarelo.
  static final _hcScheme =
      const ColorScheme.highContrastDark(
        primary: Color(0xFFFFE14D),
        onPrimary: Color(0xFF001B33),
        secondary: Color(0xFF7FDBFF),
        onSecondary: Color(0xFF001B33),
        surface: Color(0xFF001B33),
        onSurface: Colors.white,
        error: Color(0xFFFF8A8A),
        onError: Color(0xFF001B33),
      ).copyWith(
        primaryContainer: const Color(0xFF3D3500),
        onPrimaryContainer: Colors.white,
        secondaryContainer: const Color(0xFF00406B),
        onSecondaryContainer: Colors.white,
        surfaceContainerLow: const Color(0xFF00294D),
        surfaceContainer: const Color(0xFF00294D),
        surfaceContainerHighest: const Color(0xFF003A66),
        onSurfaceVariant: Colors.white,
        outline: Colors.white,
        outlineVariant: Colors.white,
      );

  static ThemeData light() => _build(_lightScheme, _lightStatus, _lightBrand);
  static ThemeData highContrast() =>
      _build(_hcScheme, _hcStatus, _hcBrand, bordered: true);

  static ThemeData _build(
    ColorScheme scheme,
    StatusColors status,
    BrandColors brand, {
    bool bordered = false,
  }) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = base.textTheme;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    );
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      extensions: [status, brand],
      textTheme: text.copyWith(
        displaySmall: text.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.5,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.15,
          letterSpacing: -0.3,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: bordered
              ? BorderSide(color: scheme.outline, width: 1.5)
              : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: scheme.outlineVariant, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorMaxLines: 3,
        helperMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: buttonShape,
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 56),
          shape: buttonShape,
          side: BorderSide(color: scheme.outline),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: text.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: buttonShape,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
