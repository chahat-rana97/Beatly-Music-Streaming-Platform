import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlayerProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Beatly',

        // 🌙 BEATLY PREMIUM THEME
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F2C34),

          primaryColor: const Color(0xFF1F4E5F),
          colorScheme: const ColorScheme.dark(
            primary: Colors.tealAccent,
            secondary: Colors.teal,
          ),

          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF0F2C34),
            selectedItemColor: Colors.tealAccent,
            unselectedItemColor: Colors.white54,
            showUnselectedLabels: true,
          ),
        ),

        // 🚀 SPLASH ENTRY POINT
        home: const SplashScreen(),
      ),
    );
  }
}
