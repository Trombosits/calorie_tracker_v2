import 'package:calorie_tracker_v2/auth_service.dart';
import 'package:calorie_tracker_v2/navbar.dart';
import 'package:calorie_tracker_v2/performance.dart';
import 'package:calorie_tracker_v2/register.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  static const Color _primary = Color(0xFFFF7C36);
  static const Color _primaryDark = Color(0xFFE95D14);
  static const Color _cream = Color(0xFFEBD1B7);
  static const Color _softCream = Color(0xFFFFF4EA);
  static const Color _dark = Color(0xFF1F1B18);

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
      final res = await AuthService.login(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );

      perf.lap('AuthService.login');

      if (res.user != null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );

        perf.lap('navigate');
      }
    } on AuthException catch (e) {
      perf.lap('error');

      String message = e.message;

      if (e.message.toLowerCase().contains('invalid login credentials')) {
        message =
            'Akun ini terdaftar menggunakan Google. Silakan masuk dengan Google.';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      perf.lap('error');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login gagal: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }

      perf.finish();
    }
  }

  Future<void> _loginGoogle() async {
    final perf = Performance('Google Login');

    setState(() => _loading = true);

    try {
      // Untuk Flutter Web / Chrome
      if (kIsWeb) {
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.origin,
        );

        perf.lap('Supabase OAuth Google Web');
        return;
      }

      // Untuk Android / mobile
      final res = await AuthService.signInWithGoogle();
      perf.lap('AuthService.signInWithGoogle');

      if (res.user != null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );

        perf.lap('navigate');
      }
    } on AuthException catch (e) {
      perf.lap('error');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      perf.lap('error');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Google login gagal: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }

      perf.finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE3C8), Color(0xFFEBD1B7), Color(0xFFFFF4EA)],
          ),
        ),
        child: Stack(
          children: [
            _decorCircle(top: -90, left: -60, size: 210, opacity: 0.22),
            _decorCircle(bottom: 70, right: -80, size: 190, opacity: 0.18),
            _decorCircle(top: 130, right: 28, size: 58, opacity: 0.16),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 28,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          children: [
                            _buildLogo(),
                            const SizedBox(height: 18),
                            Text(
                              'Selamat Datang!',
                              style: GoogleFonts.spirax(
                                fontWeight: FontWeight.bold,
                                color: _dark,
                                fontSize: 38,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Masuk untuk melanjutkan perjalanan sehatmu.',
                              style: GoogleFonts.inter(
                                color: Colors.black.withOpacity(0.65),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            _cardForm(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _primary.withOpacity(opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 116,
      height: 116,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset('assets/image/appIcon.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _cardForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Masuk Akun',
              style: GoogleFonts.inter(
                color: _dark,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Isi email dan kata sandi yang sudah terdaftar.',
              style: GoogleFonts.inter(
                color: Colors.black.withOpacity(0.55),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _emailCtrl,
            decoration: _inputDecoration(
              hint: 'Email',
              icon: Icons.email_outlined,
            ),
            style: GoogleFonts.inter(color: _dark),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passCtrl,
            decoration:
                _inputDecoration(
                  hint: 'Kata Sandi',
                  icon: Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.black.withOpacity(0.45),
                    ),
                  ),
                ),
            style: GoogleFonts.inter(color: _dark),
            obscureText: _obscurePassword,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Text(
                      'Masuk',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.black.withOpacity(0.10))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'atau',
                  style: GoogleFonts.inter(
                    color: Colors.black45,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.black.withOpacity(0.10))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _loginGoogle,
              icon: const Icon(Icons.g_mobiledata, size: 34),
              label: Text(
                'Masuk dengan Google',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _dark,
                backgroundColor: _softCream,
                side: BorderSide(color: Colors.black.withOpacity(0.08)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Belum punya akun? ',
                style: GoogleFonts.inter(
                  color: Colors.black.withOpacity(0.65),
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                ),
                child: Text(
                  'Buat di sini',
                  style: GoogleFonts.inter(
                    color: _primaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                    decorationColor: _primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: Colors.black.withOpacity(0.42),
        fontStyle: FontStyle.italic,
      ),
      prefixIcon: Icon(icon, color: _primaryDark),
      filled: true,
      fillColor: const Color(0xFFF8F1EA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.04)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
