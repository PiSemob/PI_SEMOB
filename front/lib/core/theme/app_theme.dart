import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color ink = Color(0xFF14233A);

  static const Color sidebar = Color(0xFFEDF3FA);
  static const Color sidebarHover = Color(0xFFE2ECF7);
  static const Color sidebarActive = Color(0xFFD6E4F3);
  static const Color sidebarText = Color(0xFF41546E);

  static const Color brandTop = Color(0xFFEEF4FA);
  static const Color brandBottom = Color(0xFFDCE8F5);
  static const Color fundoLogin = Color(0xFFE6EFF9);

  static const Color mapaMunicipio = brandBottom;
  static const Color mapaContorno = Color(0xFF7FAEDF);
  static const Color mapaBairro = Color(0xFFC3D6EA);
  static const Color mapaVia = surface;

  static const Color sombra = Color(0x1414233A);

  static const Color accent = Color(0xFF3D7CC9);
  static const Color accentSoft = Color(0xFFE3EDF8);

  static const Color primary = Color(0xFF1F5FA8);
  static const Color primaryHover = Color(0xFF184D8A);
  static const Color primarySoft = Color(0xFFE8F0FA);
  static const Color secondary = Color(0xFF6B7F99);

  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFFB7791F);
  static const Color danger = Color(0xFFC0392B);
  static const Color teal = Color(0xFF2F7F86);

  static const Color background = Color(0xFFF5F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF2F6FB);
  static const Color border = Color(0xFFD9E2EC);
  static const Color borderStrong = Color(0xFFBFCCDB);

  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF52647C);
  static const Color textMuted = Color(0xFF8595AA);

  static const List<Color> chart = <Color>[
    primary,
    Color(0xFF7FAEDF),
    Color(0xFF0E3A66),
    Color(0xFFB4C8DD),
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

  static const double radiusSm = 8;
  static const double radius = 12;
  static const double radiusPill = 999;
}

class AppTextStyles {
  const AppTextStyles._();

  static const String mono = 'IBM Plex Mono';

  static const TextStyle display = TextStyle(
    fontSize: 32,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle section = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle metric = TextStyle(
    fontFamily: mono,
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.6,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13.5,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );
}

class AppTheme {
  const AppTheme._();

  static const String _fonte = 'IBM Plex Sans';

  static const RoundedRectangleBorder _controle = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
  );

  static const RoundedRectangleBorder _painel = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radius)),
    side: BorderSide(color: AppColors.border),
  );

  static const TextStyle _textoBotao = TextStyle(
    fontFamily: _fonte,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
  );

  static OutlineInputBorder _borda(Color cor, [double largura = 1]) =>
      OutlineInputBorder(
        borderRadius:
            const BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
        borderSide: BorderSide(color: cor, width: largura),
      );

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primarySoft,
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
      fontFamily: _fonte,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: NoSplash.splashFactory,
      hoverColor: AppColors.primary.withValues(alpha: 0.04),
      focusColor: AppColors.primary.withValues(alpha: 0.10),
      highlightColor: AppColors.primary.withValues(alpha: 0.06),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hoverColor: AppColors.surfaceMuted,
        hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
        prefixIconColor: WidgetStateColor.resolveWith(
          (Set<WidgetState> estados) => estados.contains(WidgetState.focused)
              ? AppColors.primary
              : AppColors.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: _borda(AppColors.borderStrong),
        enabledBorder: _borda(AppColors.borderStrong),
        focusedBorder: _borda(AppColors.primary, 2),
        errorBorder: _borda(AppColors.danger),
        focusedErrorBorder: _borda(AppColors.danger, 2),
        errorStyle: const TextStyle(fontSize: 12, color: AppColors.danger),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          foregroundColor: Colors.white,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          shape: _controle,
          textStyle: _textoBotao,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> estados) {
              if (estados.contains(WidgetState.disabled)) {
                return AppColors.sidebarActive;
              }
              if (estados.contains(WidgetState.hovered) ||
                  estados.contains(WidgetState.pressed)) {
                return AppColors.primaryHover;
              }
              return AppColors.primary;
            },
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.borderStrong),
          shape: _controle,
          textStyle: _textoBotao,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: _controle,
          textStyle: _textoBotao,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: _controle,
          hoverColor: AppColors.surfaceMuted,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: _controle,
        side: const BorderSide(color: AppColors.secondary, width: 1.4),
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> estados) =>
              estados.contains(WidgetState.selected) ? AppColors.primary : null,
        ),
        checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> estados) => estados.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.sidebarActive,
        ),
        thumbColor: const WidgetStatePropertyAll<Color>(Colors.white),
        trackOutlineColor:
            const WidgetStatePropertyAll<Color>(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.sidebarActive,
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primarySoft,
        side: BorderSide(color: AppColors.border),
        labelStyle: TextStyle(
          fontFamily: _fonte,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: _fonte,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        shape: _controle,
        showCheckmark: false,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: _painel,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: _painel,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
        rangeSelectionBackgroundColor: AppColors.primarySoft,
        shape: _painel,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: Color(0x2214233A),
        shape: _painel,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(
          fontFamily: _fonte,
          fontSize: 13,
          color: Colors.white,
        ),
        actionTextColor: Color(0xFFA9C9EE),
        shape: _controle,
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
        ),
        textStyle: TextStyle(
          fontFamily: _fonte,
          fontSize: 12,
          color: Colors.white,
        ),
      ),
      listTileTheme: const ListTileThemeData(shape: _controle),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: AppTextStyles.overline,
        dataTextStyle: AppTextStyles.body,
        headingRowColor:
            const WidgetStatePropertyAll<Color>(AppColors.surfaceMuted),
        dataRowColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> estados) => estados.contains(WidgetState.hovered)
              ? AppColors.surfaceMuted
              : null,
        ),
        dividerThickness: 1,
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(AppSpacing.radiusSm),
        thickness: const WidgetStatePropertyAll<double>(6),
        thumbColor: WidgetStatePropertyAll<Color>(
          AppColors.secondary.withValues(alpha: 0.35),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
    );
  }
}
