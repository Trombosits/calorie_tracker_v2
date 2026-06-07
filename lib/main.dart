import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme.dart';
import 'login.dart'; 
import 'navbar.dart'; 

Future<void> main() async {
  // Wajib dipanggil pertama kali agar binding async berjalan lancar di Web
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Memuat konfigurasi .env
    await dotenv.load(fileName: "assets/.env");

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANONKEY'];

    // Validasi pencegah layar putih buntu
    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception(
        "Waduh! 'SUPABASE_URL' atau 'SUPABASE_ANONKEY' tidak ditemukan di file .env kamu. "
        "Pastikan penulisan key di file .env sudah benar!"
      );
    }

    // Inisialisasi Supabase dengan aman
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

  } catch (e) {
    debugPrint("EROR SAAT INISIALISASI: $e");
  }

  // Menangkap error global widget
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
          
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeNotifier.seedColor,
              brightness: Brightness.light, 
            ),
            scaffoldBackgroundColor: const Color(0xFFFFE3C7),
            useMaterial3: true,
          ),
          
          // Masuk menggunakan mekanisme AuthGate
          home: const AuthGate(),
        );
      }
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      initialData: AuthState(AuthChangeEvent.initialSession, supabase.auth.currentSession),
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return const MainNavigation(); 
        }

        return const LoginPage();
      },
    );
  }
}