import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  CARBON BEATS — App Theme
//  Single source of truth for all colors,
//  text styles, radii, gradients & ThemeData.
// ─────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ── Core backgrounds ──
  static const background     = Color(0xFF111111);
  static const surface        = Color(0xFF1E1E1E);
  static const surfaceDeep    = Color(0xFF161616);
  static const carbon         = Color(0xFF3A3A3A);

  // ── Accent ──
  static const red            = Color(0xFFE0281A);
  static const redSoft        = Color(0xFF2A0A08);

  // ── Text ──
  static const textPrimary    = Color(0xFFF0F0F0);
  static const textSecondary  = Color(0xFF888888);
  static const textMuted      = Color(0xFF555555);
  static const textDisabled   = Color(0xFF444444);

  // ── Borders / dividers ──
  static const border         = Color(0xFF2A2A2A);
  static const borderSubtle   = Color(0xFF222222);
  static const borderLight    = Color(0xFF1A1A1A);

  // ── Tile borders (used in SongTile) ──
  static const surfaceBorder  = Color(0xFF272730);

  // ── Icon circle bg (null artwork fallback) ──
  static const iconCircle     = Color(0xFF1E1E26);

  // ── Semantic ──
  static const white          = Color(0xFFFFFFFF);
  static const transparent    = Colors.transparent;
}

// ─────────────────────────────────────────────

class AppGradients {
  AppGradients._();

  static const LinearGradient appBar = LinearGradient(
    colors: [AppColors.surface, AppColors.background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient body = LinearGradient(
    colors: [AppColors.background, AppColors.surface, AppColors.background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient miniPlayer = LinearGradient(
    colors: [AppColors.surface, AppColors.background],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splash = LinearGradient(
    colors: [AppColors.background, AppColors.surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient songTileActive = LinearGradient(
    colors: [AppColors.carbon, AppColors.surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient songTileIdle = LinearGradient(
    colors: [
      AppColors.white.withOpacity(0.04),
      AppColors.white.withOpacity(0.02),
    ],
  );

  static const LinearGradient redAccent = LinearGradient(
    colors: [AppColors.red, Color(0xFFB01E13)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────

class AppRadius {
  AppRadius._();

  static const double xs   = 6.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 28.0;

  static BorderRadius get xsBorderRadius  => BorderRadius.circular(xs);
  static BorderRadius get smBorderRadius  => BorderRadius.circular(sm);
  static BorderRadius get mdBorderRadius  => BorderRadius.circular(md);
  static BorderRadius get lgBorderRadius  => BorderRadius.circular(lg);
  static BorderRadius get xlBorderRadius  => BorderRadius.circular(xl);
  static BorderRadius get xxlBorderRadius => BorderRadius.circular(xxl);
}

// ─────────────────────────────────────────────

class AppTextStyles {
  AppTextStyles._();

  // ── Display ──
  static const TextStyle appName = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.4,
  );

  // ── Headings ──
  static const TextStyle h1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 1.0,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body ──
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    letterSpacing: 0.8,
  );

  // ── Labels / captions ──
  static const TextStyle label = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    color: AppColors.textMuted,
  );

  // ── Tagline ──
  static const TextStyle tagline = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    letterSpacing: 0.8,
  );

  // ── Section label (e.g. "All Songs • 47") ──
  static const TextStyle sectionLabel = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  // ── Player ──
  static const TextStyle songTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle artistName = TextStyle(
    fontSize: 15,
    color: AppColors.textSecondary,
  );

  static const TextStyle timeStamp = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  static const TextStyle sleepTimer = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 2,
  );

  // ── Accent message (italic) ──
  static const TextStyle beatlyMessage = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 18,
    fontStyle: FontStyle.italic,
  );

  // ── Nav label ──
  static const TextStyle navLabel = TextStyle(fontSize: 10);

  // ── Mini player ──
  static const TextStyle miniTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle miniArtist = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
  );

  // ── Badge ──
  static const TextStyle badge = TextStyle(
    color: Color(0xFFFFF0EE),
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );

  // ── Empty state ──
  static const TextStyle emptyPrimary = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 16,
  );

  static const TextStyle emptySecondary = TextStyle(
    color: AppColors.textMuted,
    fontSize: 13,
  );
}

// ─────────────────────────────────────────────

class AppDecorations {
  AppDecorations._();

  // ── Card / tile base ──
  static BoxDecoration tile({bool isActive = false}) => BoxDecoration(
    borderRadius: AppRadius.lgBorderRadius,
    color: isActive ? AppColors.red.withOpacity(0.07) : AppColors.surface,
    border: Border.all(
      color: isActive
          ? AppColors.red.withOpacity(0.32)
          : AppColors.surfaceBorder,
      width: isActive ? 1.0 : 0.5,
    ),
  );

  // ── Song icon circle ──
  static BoxDecoration iconCircle({bool isActive = false}) => BoxDecoration(
    borderRadius: AppRadius.mdBorderRadius,
    color: isActive ? AppColors.redSoft : AppColors.iconCircle,
  );

  // ── Search field ──
  static BoxDecoration searchField = BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.mdBorderRadius,
    border: Border.all(color: AppColors.red.withOpacity(0.4)),
  );

  // ── Mini player bar ──
  static BoxDecoration miniPlayerBar = BoxDecoration(
    gradient: AppGradients.miniPlayer,
    border: const Border(top: BorderSide(color: AppColors.border)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.35),
        blurRadius: 14,
        offset: const Offset(0, -2),
      ),
    ],
  );

  // ── Bottom nav ──
  static BoxDecoration bottomNav = const BoxDecoration(
    color: AppColors.surface,
    border: Border(top: BorderSide(color: AppColors.border)),
  );

  // ── Sleep timer box ──
  static BoxDecoration sleepTimerBox = BoxDecoration(
    color: AppColors.surfaceDeep,
    borderRadius: AppRadius.smBorderRadius,
  );

  // ── Play button circle ──
  static BoxDecoration playButton = const BoxDecoration(
    shape: BoxShape.circle,
    color: AppColors.red,
  );

  // ── Track icon box ──
  static BoxDecoration trackIconBox({bool isActive = false}) => BoxDecoration(
    borderRadius: AppRadius.xsBorderRadius,
    color: isActive ? AppColors.redSoft : AppColors.carbon,
  );

  // ── Badge pill ──
  static BoxDecoration badge = BoxDecoration(
    color: AppColors.red,
    borderRadius: AppRadius.xsBorderRadius,
  );

  // ── Progress / volume bar bg ──
  static BoxDecoration progressBg = BoxDecoration(
    color: AppColors.carbon,
    borderRadius: AppRadius.xsBorderRadius,
  );

  // ── Queue / bottom sheet ──
  static BoxDecoration queueCard = BoxDecoration(
    color: AppColors.surfaceDeep,
    borderRadius: AppRadius.mdBorderRadius,
    border: Border.all(color: AppColors.borderSubtle),
  );
}

// ─────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.red,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.red,
      secondary: AppColors.carbon,
      surface: AppColors.surface,
      onPrimary: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.red,
      unselectedItemColor: AppColors.textMuted,
      showUnselectedLabels: true,
      elevation: 0,
    ),

    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.textPrimary,
      inactiveTrackColor: AppColors.carbon,
      thumbColor: AppColors.textPrimary,
      overlayColor: Colors.transparent,
      trackHeight: 3,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
    ),

    iconTheme: const IconThemeData(color: AppColors.textSecondary),

    textTheme: const TextTheme(
      displayLarge:   AppTextStyles.appName,
      headlineLarge:  AppTextStyles.h1,
      headlineMedium: AppTextStyles.h2,
      headlineSmall:  AppTextStyles.h3,
      bodyLarge:      AppTextStyles.body,
      bodyMedium:     AppTextStyles.bodySmall,
      labelLarge:     AppTextStyles.label,
      labelSmall:     AppTextStyles.caption,
    ),

    listTileTheme: const ListTileThemeData(
      textColor: AppColors.textPrimary,
      iconColor: AppColors.textSecondary,
    ),

    dividerColor: AppColors.border,
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 0.5,
      space: 0,
    ),
  );
}