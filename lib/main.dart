import 'package:calorie_tracker_v2/dashboard.dart';
import 'package:calorie_tracker_v2/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '/theme.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANONKEY']!,
  );

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('GLOBAL ERROR ➜ ${details.exception}');
  };

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, child) {
        return MaterialApp(
          title: 'LangsingIn',
          debugShowCheckedModeBanner: false,

          // Hanya ada konfigurasi Tema Terang (Light Mode)
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeNotifier.seedColor,
              brightness: Brightness.light, // Paksa light mode selalu
            ),
            scaffoldBackgroundColor: const Color(0xFFFFE3C7),
            useMaterial3: true,
          ),

          // Routing halaman utama
          home: supabase.auth.currentSession != null
              ? DashboardPage(
                  totalTargetKalori: 2000,
                  totalKaloriMasuk: 0,
                  totalKaloriKeluar: 0,
                  protein: 0,
                  karbohidrat: 0,
                  lemak: 0,
                )
              : LoginPage(),
        );
      },
    );
  }
}
