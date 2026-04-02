import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'state/app_state.dart';
import 'ui/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const SettlementApp(),
    ),
  );
}

class SettlementApp extends StatelessWidget {
  const SettlementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Group Debt Settler',
      debugShowCheckedModeBanner: false,

      // Auto locale follows device
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],

      // Auto dark/light mode follows system
      themeMode: ThemeMode.system,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),

      home: const DashboardScreen(),
    );
  }

  ThemeData _buildLightTheme() {
    const primary = Color(0xFF5B5BF6);
    const secondary = Color(0xFF00BDD4);
    const tertiary = Color(0xFFFF6B9D);
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: const Color(0xFFF5F5FF),
        surfaceContainerHighest: const Color(0xFFEEEEFF),
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
      scaffoldBackgroundColor: const Color(0xFFF5F5FF),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE0E0F0), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1A2E),
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const primary = Color(0xFF7B78FF);
    const secondary = Color(0xFF00D4FF);
    const tertiary = Color(0xFFFF6B9D);
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: const Color(0xFF0E0E1A),
        surfaceContainerHighest: const Color(0xFF1C1C2E),
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
      scaffoldBackgroundColor: const Color(0xFF0E0E1A),
      cardTheme: CardThemeData(
        color: const Color(0xFF1C1C2E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.07), width: 0.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    );
  }
}
