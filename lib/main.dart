import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/audio_service.dart';
import 'services/content_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioService.init();
  await ContentService.init();
  runApp(const NeuroCareApp());
}

class NeuroCareApp extends StatelessWidget {
  const NeuroCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Petit Pas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF4693D4), // Bleu du logo
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4693D4),
          primary: const Color(0xFF4693D4),    // Bleu (Action/Structure)
          secondary: const Color(0xFF39A773),  // Vert (Croissance/Santé)
          tertiary: const Color(0xFFF09A37),   // Orange (Accent)
          surface: Colors.white,
          onSurface: const Color(0xFF4A4A4A),  // Gris foncé pour le texte
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF4A4A4A)),
          bodyMedium: TextStyle(color: Color(0xFF4A4A4A)),
          titleLarge: TextStyle(color: Color(0xFF4A4A4A)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF4A4A4A),
          elevation: 0,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('yo', 'NG'),
        Locale('en', 'US'),
      ],
      home: const HomeScreen(),
    );
  }
}
