import 'package:flutter/material.dart';

/// Identidade visual Ferret: painel técnico claro, em tons de cinza, com
/// tipografia monoespaçada e um único destaque laranja.
class AppColors {
  const AppColors._();

  /// Tinta: a cor dos textos principais, das linhas dos gráficos e dos botões.
  static const Color ink = Color(0xFF1C1C1C);

  // Navegação lateral (clara).
  static const Color sidebar = Color(0xFFFAFAFA);
  static const Color sidebarHover = Color(0xFFF0F0F0);
  static const Color sidebarActive = Color(0xFFEAEAEA);
  static const Color sidebarText = Color(0xFF6E6E6E);

  // Marca.
  static const Color brandTop = Color(0xFFF4F4F4);
  static const Color brandBottom = Color(0xFFE6E6E6);

  /// Destaque. Usado com parcimônia: alertas, seleção e o ponto que importa.
  static const Color accent = Color(0xFFF0532A);
  static const Color accentSoft = Color(0xFFFBE2DA);

  // Ação.
  static const Color primary = ink;
  static const Color primaryHover = Color(0xFF000000);
  static const Color secondary = Color(0xFF7A7A7A);

  static const Color success = Color(0xFF3E7C59);
  static const Color warning = Color(0xFFD98A1F);
  static const Color danger = Color(0xFFD8371A);
  static const Color teal = Color(0xFF5E7A7A);
  static const Color purple = Color(0xFFA3A3A3);

  static const Color background = Color(0xFFEDEDED);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceMuted = Color(0xFFF1F1F1);
  static const Color border = Color(0xFFD4D4D4);

  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF5E5E5E);
  static const Color textMuted = Color(0xFF9B9B9B);

  /// Sequência usada nos gráficos (demanda, receita, créditos, frota).
  static const List<Color> chart = <Color>[
    primary,
    accent,
    secondary,
    Color(0xFFB8B8B8),
    teal,
    warning,
  ];
}

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  // Cantos retos em todo o app. Os três nomes continuam existindo porque as
  // telas os usam; o valor é que mudou.
  static const double radiusSm = 2;
  static const double radius = 2;
  static const double radiusPill = 2;
}

/// Tipografia IBM Plex Mono aplicada globalmente pelo tema; aqui ficam apenas
/// pesos, tamanhos e espaçamento entre letras.
class AppTextStyles {
  const AppTextStyles._();

  static const TextStyle display = TextStyle(
    fontSize: 30,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.textPrimary,
  );

  static const TextStyle section = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle metric = TextStyle(
    fontSize: 30,
    height: 1.1,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    color: AppColors.textPrimary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  /// Rótulo maiúsculo dos cards de indicador e dos grupos de navegação.
  static const TextStyle overline = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    color: AppColors.textSecondary,
  );
}

class AppTheme {
  const AppTheme._();

  static const RoundedRectangleBorder _reto = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radius)),
  );

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.surfaceMuted,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.accentSoft,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.secondary,
      error: AppColors.danger,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surfaceMuted,
      surfaceContainerHigh: AppColors.surfaceMuted,
      surfaceContainerHighest: AppColors.sidebarActive,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'IBM Plex Mono',
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: NoSplash.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radius)),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radius)),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radius)),
          borderSide: BorderSide(color: AppColors.ink, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          shape: _reto,
          textStyle: const TextStyle(
            fontFamily: 'IBM Plex Mono',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          side: const BorderSide(color: AppColors.border),
          foregroundColor: AppColors.textPrimary,
          shape: _reto,
          textStyle: const TextStyle(
            fontFamily: 'IBM Plex Mono',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          shape: _reto,
          textStyle: const TextStyle(
            fontFamily: 'IBM Plex Mono',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: _reto),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: _reto,
        side: const BorderSide(color: AppColors.secondary, width: 1.2),
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> estados) =>
              estados.contains(WidgetState.selected) ? AppColors.accent : null,
        ),
        checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> estados) => estados.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.sidebarActive,
        ),
        thumbColor: const WidgetStatePropertyAll<Color>(Colors.white),
        trackOutlineColor:
            const WidgetStatePropertyAll<Color>(AppColors.border),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.sidebarActive,
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.ink,
        side: BorderSide(color: AppColors.border),
        labelStyle: TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          color: Colors.white,
        ),
        shape: _reto,
        showCheckmark: false,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radius)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: _reto,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radius)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 12,
          color: Colors.white,
        ),
        shape: _reto,
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(color: AppColors.ink),
        textStyle: TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 11,
          color: Colors.white,
        ),
      ),
      listTileTheme: const ListTileThemeData(shape: _reto),
      dataTableTheme: const DataTableThemeData(
        headingTextStyle: AppTextStyles.overline,
        dataTextStyle: AppTextStyles.body,
        dividerThickness: 1,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
    );
  }
}
