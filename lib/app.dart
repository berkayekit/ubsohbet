import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/main_shell.dart';
import 'package:ubsohbet/screens/auth/auth_screen.dart';
import 'package:ubsohbet/services/presence_service.dart';

class UbSohbetApp extends StatelessWidget {
  const UbSohbetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: kSun,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UB Sohbet',
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: kSand,
        textTheme:
            GoogleFonts.spaceGroteskTextTheme(baseTheme.textTheme).copyWith(
          headlineLarge: GoogleFonts.bebasNeue(
            fontSize: 32,
            letterSpacing: 1.2,
            color: kMidnight,
          ),
          titleLarge: GoogleFonts.bebasNeue(
            fontSize: 22,
            letterSpacing: 1.1,
            color: kMidnight,
          ),
          bodyLarge: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kMidnight,
          ),
          bodyMedium: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            color: withOpacity(kMidnight, 0.7),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            PresenceService.instance.start();
            return const MainShell();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
