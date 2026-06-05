import 'package:calorie_tracker_v2/auth_service.dart';
import 'package:calorie_tracker_v2/dashboard.dart';
import 'package:calorie_tracker_v2/performance.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:calorie_tracker_v2/register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password Harus diisi')),
      );
      return;
    }

    final perf = Performance('Login');
    setState(() => _loading = true);

    try {
      final res = await AuthService.login(_emailCtrl.text, _passCtrl.text);
      perf.lap('AuthService.login');

      if (res?.user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardPage(
              totalTargetKalori: 2000,
              totalKaloriMasuk: 0,
              totalKaloriKeluar: 0,
              protein: 0,
              karbohidrat: 0,
              lemak: 0,
            ),
          ),
        );
        perf.lap('navigate');
      }
    } on AuthException catch (e) {
      perf.lap('error');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
      perf.finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFEBD1B7),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7C36),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/image/logo.png',
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Selamat Datang!',
                  style: GoogleFonts.spirax(
                    textStyle: Theme.of(context).textTheme.headlineLarge,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 128),
                Text(
                  'Silakan Masuk.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                _cardForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardForm() {
    return Column(
      children: [
        TextField(
          controller: _emailCtrl,
          decoration: InputDecoration(
            hintText: 'Email',
            hintStyle: GoogleFonts.inter(
              fontStyle: FontStyle.italic,
              color: Colors.white70,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.black87,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: GoogleFonts.inter(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passCtrl,
          decoration: InputDecoration(
            hintText: 'Kata Sandi',
            hintStyle: GoogleFonts.inter(
              fontStyle: FontStyle.italic,
              color: Colors.white70,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.black87,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: GoogleFonts.inter(color: Colors.white),
          obscureText: true,
        ),
        const SizedBox(height: 128),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Belum Punya Akun?',
              style: GoogleFonts.inter(color: Colors.black, fontSize: 14),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RegisterPage()),
              ),
              child: Text(
                'Buat Disini',
                style: GoogleFonts.inter(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7C36),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Masuk',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
