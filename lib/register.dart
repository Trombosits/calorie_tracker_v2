import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:calorie_tracker_v2/login.dart';
import 'package:calorie_tracker_v2/navbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final supabase = Supabase.instance.client;

class RegisterPage extends StatefulWidget {
  final bool isGoogleSetup;

  const RegisterPage({super.key, this.isGoogleSetup = false});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  /* ---------- CONTROLLERS ---------- */
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();

  /* ---------- STATE ---------- */
  String? _selectedGender;
  String? _activityLevel;
  int _currentStep = 0;
  bool _loading = false;
  bool _obscurePassword = true;
  DateTime? _selectedDate;
  String _selectedMode = 'Maintenance'; // Default awal

  /* ---------- CALCULATED ---------- */
  double _bmi = 0;
  double _bmr = 0;
  double _tdee = 0;
  int _maintenance = 0;
  int _surplus = 0;
  int _deficit = 0;
  int _age = 0;

  /* ---------- NAMA DEPAN UNTUK STEP 1 ---------- */
  String _namaDepan = '';

  int get _lastStep => widget.isGoogleSetup ? 5 : 6;
  int get _stepCount => widget.isGoogleSetup ? 6 : 7;

  @override
  void initState() {
    super.initState();

    if (widget.isGoogleSetup) {
      final user = supabase.auth.currentUser;
      final metadata = user?.userMetadata ?? {};
      final googleName = (metadata['full_name'] ?? metadata['name'] ?? '')
          .toString()
          .trim();
      final googleEmail = user?.email ?? '';

      if (googleName.isNotEmpty) {
        _firstNameCtrl.text = googleName.split(' ').first;
        _namaDepan = _firstNameCtrl.text;
      }

      if (googleEmail.isNotEmpty) {
        _emailCtrl.text = googleEmail;
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _usernameCtrl.dispose();
    _firstNameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  /* ---------- NAVIGASI STEP ---------- */
  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep == 0) _namaDepan = _firstNameCtrl.text.trim();
    if (_currentStep < _lastStep) {
      setState(() => _currentStep++);
      if (_currentStep == 5) _calculateCalories();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      if (widget.isGoogleSetup) {
        supabase.auth.signOut();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  /* ---------- VALIDASI PER STEP ---------- */
  bool _validateCurrentStep() {
    String? error;
    switch (_currentStep) {
      case 0:
        if (_firstNameCtrl.text.isEmpty) error = 'Nama depan harus diisi!';
        break;
      case 2:
        final h = double.tryParse(_heightCtrl.text);
        final w = double.tryParse(_weightCtrl.text);
        if (h == null || w == null || h < 50 || h > 250 || w < 20 || w > 300) {
          error = 'Tinggi (50-250 cm) & berat (20-300 kg) harus valid!';
        }
        break;
      case 3:
        if (_birthDateCtrl.text.isEmpty || _selectedDate == null) {
          error = 'Tanggal lahir harus dipilih!';
        } else if (_selectedGender == null) {
          error = 'Jenis kelamin harus dipilih!';
        }
        break;
      case 4:
        if (_activityLevel == null) error = 'Level aktivitas harus dipilih!';
        break;
      case 6:
        if (!widget.isGoogleSetup &&
            (_emailCtrl.text.isEmpty ||
            _usernameCtrl.text.isEmpty ||
            _passCtrl.text.isEmpty ||
            _passCtrl.text.length < 6)) {
          error = 'Lengkapi email, nama pengguna & password (min 6 karakter)!';
        }
        break;
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return false;
    }
    return true;
  }

  /* ---------- HITUNG KALORI + TENTUKAN TARGET ---------- */
  void _calculateCalories() {
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final h = double.tryParse(_heightCtrl.text) ?? 0;
    final heightM = h / 100;
    _bmi = w / (heightM * heightM);

    _bmr = (_selectedGender == 'Laki-laki')
        ? (10 * w) + (6.25 * h) - (5 * _age) + 5
        : (10 * w) + (6.25 * h) - (5 * _age) - 161;

    double factor = 1.2;
    switch (_activityLevel) {
      case 'Ringan':
        factor = 1.375;
        break;
      case 'Sedang':
        factor = 1.55;
        break;
      case 'Berat':
        factor = 1.725;
        break;
      case 'Sangat Berat':
        factor = 1.9;
        break;
    }
    _tdee = _bmr * factor;
    _maintenance = _tdee.round();
    _surplus = _maintenance + 300;
    _deficit = _maintenance - 300;
  }

  /* ---------- PILIH TANGGAL ---------- */
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2006),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthDateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
        _age = DateTime.now().year - picked.year;
      });
    }
  }

  /* ---------- MAPPING AKTIVITAS ---------- */
  String _toDbActivity(String? val) {
    switch (val) {
      case 'Rendah':
        return 'Jarang Bergerak';
      case 'Ringan':
        return 'Ringan';
      case 'Sedang':
        return 'Menengah';
      case 'Berat':
        return 'Berat';
      case 'Sangat Berat':
        return 'Sangat Berat';
      default:
        return 'Jarang Bergerak';
    }
  }

  /* ---------- REGISTRASI + SIMPAN TARGET ---------- */
  Future<void> _register() async {
    if (!_validateCurrentStep()) return;
    setState(() => _loading = true);

    try {
      // Tentukan mode dan kalori berdasarkan pilihan user
      String mode = 'maintenance';
      int kaloriTarget = _maintenance;

      if (_selectedMode == 'Deficit (Cutting)') {
        mode = 'cutting';
        kaloriTarget = _deficit;
      } else if (_selectedMode == 'Surplus (Bulking)') {
        mode = 'bulking';
        kaloriTarget = _surplus;
      }

      final profileData = <String, dynamic>{
        'nama_lengkap': _firstNameCtrl.text.trim(),
        'berat': double.tryParse(_weightCtrl.text),
        'tinggi': double.tryParse(_heightCtrl.text),
        'usia': _age,
        'jenis_kelamin': _selectedGender,
        'level_aktivitas': _toDbActivity(_activityLevel),
        'bmi': _bmi,
        'bmr': _bmr,
        'tdee': _tdee,
        'target_mode': mode,
        'target_kalori': kaloriTarget,
      };

      if (widget.isGoogleSetup) {
        final user = supabase.auth.currentUser;

        if (user == null) {
          throw Exception('Sesi Google tidak ditemukan. Silakan login ulang.');
        }

        await supabase.from('users').upsert({
          'id_user': user.id,
          ...profileData,
        }, onConflict: 'id_user');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil dilengkapi. Selamat datang!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );

        return;
      }

      final authRes = await supabase.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        data: profileData,
      );

      final user = authRes.user;
      if (user == null) throw Exception('Gagal membuat akun');

      final hasActiveSession =
          authRes.session != null || supabase.auth.currentSession != null;

      if (hasActiveSession) {
        await supabase.from('users').upsert({
          'id_user': user.id,
          ...profileData,
        }, onConflict: 'id_user');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Selamat datang di LangsingIn.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registrasi berhasil! Silakan cek email untuk verifikasi, lalu login.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ---------- UI ---------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBD1B7),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18, top: 8, bottom: 8),
          child: Material(
            color: Colors.white.withOpacity(0.92),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            child: InkWell(
              onTap: _prevStep,
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: Color(0xFF1F1B18),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE3C8),
              Color(0xFFEBD1B7),
              Color(0xFFFFF4EA),
            ],
          ),
        ),
        child: Stack(
          children: [
            _decorCircle(top: -100, left: -65, size: 230, opacity: 0.20),
            _decorCircle(bottom: -70, right: -70, size: 230, opacity: 0.16),
            _decorCircle(top: 160, right: 28, size: 64, opacity: 0.15),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        _buildTopBrand(),
                        const SizedBox(height: 18),
                        _buildRegisterCard(),
                      ],
                    ),
                  ),
                ),
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
          color: const Color(0xFFFF7C36).withOpacity(opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildTopBrand() {
    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7C36), Color(0xFFE95D14)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7C36).withOpacity(0.30),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/image/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.isGoogleSetup ? 'Lengkapi Profil' : 'Buat Akun',
          style: GoogleFonts.spirax(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F1B18),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.isGoogleSetup
              ? 'Lengkapi data tubuh agar rekomendasi kalori harianmu akurat.'
              : 'Lengkapi data singkat untuk rekomendasi kalori harianmu.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black.withOpacity(0.58),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.70)),
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
          _buildProgressIndicator(),
          const SizedBox(height: 18),
          _buildStepHeader(),
          const SizedBox(height: 22),
          _buildStepContent(),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7C36),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: _loading ? null : (_currentStep == _lastStep ? _register : _nextStep),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentStep == _lastStep
                              ? (widget.isGoogleSetup ? 'Simpan Profil' : 'Daftar Sekarang')
                              : 'Lanjut',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep == _lastStep
                              ? Icons.check_circle_outline_rounded
                              : Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
          if (!widget.isGoogleSetup && _currentStep == 6) ...[
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text(
                  'Sudah punya akun? ',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: Text(
                    'Masuk',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFE95D14),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFFE95D14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    final titles = [
      'Kenalan dulu',
      'Apa itu RDI?',
      'Data tubuh',
      'Profil dasar',
      'Aktivitas harian',
      'Pilih target',
      'Akun masuk',
    ];

    final subtitles = [
      'Masukkan nama depan agar pengalaman aplikasinya terasa personal.',
      'Sedikit penjelasan sebelum menghitung rekomendasi kalori.',
      'Tinggi dan berat dipakai untuk menghitung BMI dan kebutuhan energi.',
      'Tanggal lahir dan jenis kelamin membantu menghitung BMR lebih akurat.',
      'Pilih yang paling mendekati rutinitasmu sehari-hari.',
      'Pilih rekomendasi kalori yang sesuai dengan tujuanmu.',
      'Buat email, username, dan password untuk menyimpan progres.',
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E3),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0xFFFF7C36).withOpacity(0.16)),
          ),
          child: Text(
            'Langkah ${_currentStep + 1} dari $_stepCount',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFE95D14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          titles[_currentStep],
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1F1B18),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          subtitles[_currentStep],
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.45,
            color: Colors.black.withOpacity(0.58),
          ),
        ),
      ],
    );
  }

  /* ---------- WIDGET BANTU ---------- */
  Widget _buildProgressIndicator() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _stepCount,
            minHeight: 9,
            backgroundColor: const Color(0xFFF1E5D8),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF7C36)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_stepCount, (index) {
            final isActive = index <= _currentStep;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: isActive
                    ? const Color(0xFFFF7C36)
                    : const Color(0xFFEADCCE),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildRDIInfoStep();
      case 2:
        return _buildBodyDataStep();
      case 3:
        return _buildBirthAndGenderStep();
      case 4:
        return _buildActivityBoxStep();
      case 5:
        return _buildCalorieResultStep();
      case 6:
        return widget.isGoogleSetup ? const SizedBox.shrink() : _buildFinalFormStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameStep() {
    return _cardForm([
      TextField(
        controller: _firstNameCtrl,
        style: GoogleFonts.inter(
          color: const Color(0xFF1F1B18),
          fontWeight: FontWeight.w600,
        ),
        cursorColor: const Color(0xFFFF7C36),
        textInputAction: TextInputAction.next,
        decoration: _inputDecoration(
          label: 'Nama depan',
          icon: Icons.person_outline_rounded,
        ),
      ),
    ]);
  }

  Widget _buildRDIInfoStep() {
    return _cardForm([
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4EA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF7C36).withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: const Color(0xFFFF7C36),
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              'Oke $_namaDepan, kita hitung RDI-mu dulu ya.',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1F1B18),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'RDI adalah Recommended Daily Intake, yaitu estimasi asupan harian yang direkomendasikan. Di LangsingIn, data ini dipakai sebagai dasar untuk menentukan target kalori yang lebih sesuai dengan tubuh dan aktivitasmu.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.55,
                color: Colors.black.withOpacity(0.66),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildBodyDataStep() {
    return _cardForm([
      _blackBoxField(
        label: 'Tinggi badan (cm)',
        icon: Icons.height_rounded,
        controller: _heightCtrl,
        keyboard: TextInputType.number,
      ),
      const SizedBox(height: 14),
      _blackBoxField(
        label: 'Berat badan (kg)',
        icon: Icons.monitor_weight_outlined,
        controller: _weightCtrl,
        keyboard: TextInputType.number,
      ),
      const SizedBox(height: 8),
      _infoPill(
        icon: Icons.info_outline_rounded,
        text: 'Gunakan angka saja, contoh: 170 untuk tinggi dan 65 untuk berat.',
      ),
    ]);
  }

  Widget _blackBoxField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required TextInputType keyboard,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(
        color: const Color(0xFF1F1B18),
        fontWeight: FontWeight.w600,
      ),
      cursorColor: const Color(0xFFFF7C36),
      decoration: _inputDecoration(label: label, icon: icon),
      keyboardType: keyboard,
    );
  }

  Widget _buildBirthAndGenderStep() {
    return _cardForm([
      InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          decoration: _fieldBoxDecoration(),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: Color(0xFFE95D14)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _birthDateCtrl.text.isEmpty ? 'Pilih tanggal lahir' : _birthDateCtrl.text,
                  style: GoogleFonts.inter(
                    color: _birthDateCtrl.text.isEmpty
                        ? Colors.black.withOpacity(0.42)
                        : const Color(0xFF1F1B18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.black.withOpacity(0.45),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: _fieldBoxDecoration(),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedGender,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black.withOpacity(0.45),
            ),
            dropdownColor: Colors.white,
            isExpanded: true,
            hint: Text(
              'Pilih jenis kelamin',
              style: GoogleFonts.inter(color: Colors.black.withOpacity(0.42)),
            ),
            items: ['Laki-laki', 'Perempuan']
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1F1B18),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedGender = val),
          ),
        ),
      ),
    ]);
  }

  Widget _buildActivityBoxStep() {
    final options = [
      {
        'title': 'Rendah',
        'desc':
            'Sebagian besar waktu duduk dan jarang bergerak. Hampir tidak pernah olahraga.',
      },
      {
        'title': 'Ringan',
        'desc':
            'Ada sedikit aktivitas fisik harian atau olahraga ringan 1-3 kali seminggu.',
      },
      {
        'title': 'Sedang',
        'desc':
            'Rutin olahraga 3-5 kali seminggu atau pekerjaan yang cukup banyak gerak.',
      },
      {
        'title': 'Berat',
        'desc':
            'Latihan intens hampir setiap hari atau pekerjaan fisik yang berat.',
      },
      {
        'title': 'Sangat Berat',
        'desc':
            'Latihan sangat intens setiap hari atau kerja fisik berat sepanjang hari.',
      },
    ];

    return _cardForm([
      ...options.map((o) => _activityBox(o['title']!, o['desc']!)).toList(),
    ]);
  }

  Widget _activityBox(String title, String desc) {
    final isSelected = _activityLevel == title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _activityLevel = title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF0E3) : const Color(0xFFF8F1EA),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF7C36)
                  : Colors.black.withOpacity(0.05),
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFFFF7C36).withOpacity(0.14),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF7C36) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected ? Icons.check_rounded : Icons.directions_walk_rounded,
                  size: 19,
                  color: isSelected ? Colors.white : const Color(0xFFE95D14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? const Color(0xFFE95D14)
                            : const Color(0xFF1F1B18),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        height: 1.35,
                        color: Colors.black.withOpacity(0.58),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rdiBox(String label, int value, Color color) {
    final isSelected = _selectedMode == label;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => _selectedMode = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.10) : const Color(0xFFF8F1EA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : Colors.black.withOpacity(0.05),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.flag_outlined,
                color: isSelected ? Colors.white : color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? color : const Color(0xFF1F1B18),
                ),
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)} kkal',
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: isSelected ? color : const Color(0xFF1F1B18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieResultStep() {
    return _cardForm([
      Row(
        children: [
          Expanded(
            child: _metricMiniCard('BMI', _bmi.toStringAsFixed(1)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _metricMiniCard('BMR', '${_bmr.toStringAsFixed(0)}'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _metricMiniCard('TDEE', '${_tdee.toStringAsFixed(0)}'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _rdiBox('Maintenance', _maintenance, Colors.blue),
      const SizedBox(height: 12),
      _rdiBox('Surplus (Bulking)', _surplus, Colors.green),
      const SizedBox(height: 12),
      _rdiBox('Deficit (Cutting)', _deficit, Colors.red),
      const SizedBox(height: 16),
      _infoPill(
        icon: Icons.tips_and_updates_outlined,
        text: 'Angka ini adalah rekomendasi awal. Kamu tetap bisa menyesuaikan target sesuai progres.',
      ),
    ]);
  }

  Widget _buildFinalFormStep() {
    return _cardForm([
      TextField(
        controller: _emailCtrl,
        style: GoogleFonts.inter(
          color: const Color(0xFF1F1B18),
          fontWeight: FontWeight.w600,
        ),
        cursorColor: const Color(0xFFFF7C36),
        decoration: _inputDecoration(
          label: 'Email',
          icon: Icons.email_outlined,
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _usernameCtrl,
        style: GoogleFonts.inter(
          color: const Color(0xFF1F1B18),
          fontWeight: FontWeight.w600,
        ),
        cursorColor: const Color(0xFFFF7C36),
        decoration: _inputDecoration(
          label: 'Nama pengguna',
          icon: Icons.alternate_email_rounded,
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _passCtrl,
        style: GoogleFonts.inter(
          color: const Color(0xFF1F1B18),
          fontWeight: FontWeight.w600,
        ),
        cursorColor: const Color(0xFFFF7C36),
        decoration: _inputDecoration(
          label: 'Kata sandi',
          icon: Icons.lock_outline_rounded,
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
        obscureText: _obscurePassword,
      ),
      const SizedBox(height: 10),
      _infoPill(
        icon: Icons.shield_outlined,
        text: 'Minimal 6 karakter. Gunakan kombinasi huruf dan angka agar lebih aman.',
      ),
    ]);
  }

  Widget _metricMiniCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF7C36).withOpacity(0.11)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.black.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFE95D14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF7C36).withOpacity(0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFE95D14), size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.35,
                color: Colors.black.withOpacity(0.58),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        color: Colors.black.withOpacity(0.45),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFFE95D14)),
      filled: true,
      fillColor: const Color(0xFFF8F1EA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.04)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFFF7C36), width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  BoxDecoration _fieldBoxDecoration() {
    return BoxDecoration(
      color: const Color(0xFFF8F1EA),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.black.withOpacity(0.04)),
    );
  }

  Widget _cardForm(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
