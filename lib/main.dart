import 'package:calorie_tracker_v2/login.dart';
import 'package:calorie_tracker_v2/navbar.dart';
import 'package:calorie_tracker_v2/register.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeNotifier.seedColor,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFFFE3C7),
            useMaterial3: true,
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isProfileComplete(Map<String, dynamic> profile) {
    return profile['berat'] != null &&
        profile['tinggi'] != null &&
        profile['usia'] != null &&
        profile['jenis_kelamin'] != null &&
        profile['level_aktivitas'] != null &&
        profile['target_kalori'] != null;
  }

  Map<String, dynamic> _profileFromMetadata({
    required String userId,
    required Map<String, dynamic> metadata,
    required String fallbackName,
  }) {
    final profile = <String, dynamic>{
      'id_user': userId,
      'nama_lengkap': (metadata['nama_lengkap'] ??
              metadata['full_name'] ??
              metadata['name'] ??
              fallbackName)
          .toString(),
    };

    // Metadata ini diisi oleh register email biasa. Kalau email confirmation aktif,
    // data profil sementara disimpan di auth.user_metadata, lalu dipindahkan ke
    // public.users saat user login setelah verifikasi.
    final keys = [
      'berat',
      'tinggi',
      'usia',
      'jenis_kelamin',
      'level_aktivitas',
      'bmi',
      'bmr',
      'tdee',
      'target_mode',
      'target_kalori',
    ];

    for (final key in keys) {
      if (metadata.containsKey(key) && metadata[key] != null) {
        profile[key] = metadata[key];
      }
    }

    return profile;
  }

  Future<bool> _loadProfileStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final metadata = Map<String, dynamic>.from(user.userMetadata ?? {});
    final fallbackName =
        (metadata['full_name'] ??
                metadata['name'] ??
                user.email ??
                'Pengguna LangsingIn')
            .toString();

    final metadataProfile = _profileFromMetadata(
      userId: user.id,
      metadata: metadata,
      fallbackName: fallbackName,
    );

    final existing = await supabase
        .from('users')
        .select(
          'id_user, nama_lengkap, berat, tinggi, usia, jenis_kelamin, level_aktivitas, target_kalori',
        )
        .eq('id_user', user.id)
        .maybeSingle();

    // Kalau belum ada row di public.users:
    // - Google baru: buat row minimal, lalu arahkan ke lengkapi profil.
    // - Email biasa setelah verifikasi: metadata sudah lengkap, buat row lengkap.
    if (existing == null) {
      await supabase.from('users').insert(metadataProfile);
      return _isProfileComplete(metadataProfile);
    }

    final currentName = existing['nama_lengkap']?.toString().trim();
    if (currentName == null || currentName.isEmpty || currentName == 'EMPTY') {
      await supabase
          .from('users')
          .update({'nama_lengkap': fallbackName})
          .eq('id_user', user.id);
    }

    // Kalau row sudah ada tapi belum lengkap, dan metadata dari register email
    // ternyata lengkap, update row dari metadata.
    if (!_isProfileComplete(existing) && _isProfileComplete(metadataProfile)) {
      await supabase
          .from('users')
          .update(metadataProfile..remove('id_user'))
          .eq('id_user', user.id);
      return true;
    }

    return _isProfileComplete(existing);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;

        if (session == null) {
          return const LoginPage();
        }

        return FutureBuilder<bool>(
          future: _loadProfileStatus(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Gagal memuat profil: ${profileSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final isComplete = profileSnapshot.data ?? false;

            if (!isComplete) {
              return const RegisterPage(isGoogleSetup: true);
            }

            return const MainNavigation();
          },
        );
      },
    );
  }
}
