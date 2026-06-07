import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:calorie_tracker_v2/login.dart';
import 'package:calorie_tracker_v2/main.dart'; // Pastikan AuthGate() ada di sini
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final supabase = Supabase.instance.client;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

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
    if (_currentStep < 6) {
      setState(() => _currentStep++);
      if (_currentStep == 5) _calculateCalories();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
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
        if (_emailCtrl.text.isEmpty ||
            _usernameCtrl.text.isEmpty ||
            _passCtrl.text.isEmpty ||
            _passCtrl.text.length < 6) {
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
      final authRes = await supabase.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (authRes.user == null) throw Exception('Gagal membuat akun');

      // PERBAIKAN: Tentukan mode dan kalori berdasarkan pilihan nyata dari UI user
      String mode = 'maintenance';
      int kaloriTarget = _maintenance;

      if (_selectedMode == 'Deficit (Cutting)') {
        mode = 'cutting';
        kaloriTarget = _deficit;
      } else if (_selectedMode == 'Surplus (Bulking)') {
        mode = 'bulking';
        kaloriTarget = _surplus;
      }

      await supabase.from('users').insert({
        'id_user': authRes.user!.id,
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
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Selamat datang di LangsingIn.'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Material(
            color: Colors.white.withOpacity(0.9),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _prevStep,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back, size: 20, color: Colors.black),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0XFFEBD1B7)),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  _buildProgressIndicator(),
                  const SizedBox(height: 24),
                  _buildStepContent(),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0XFFFF5A16),
                      ),
                      onPressed: _loading
                          ? null
                          : (_currentStep == 6 ? _register : _nextStep),
                      child: _loading
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : Text(
                              _currentStep == 6 ? 'Daftar' : 'Lanjut',
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /* ---------- WIDGET BANTU ---------- */
  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index <= _currentStep ? Colors.orange : Colors.white54,
          ),
        );
      }),
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
        return _buildFinalFormStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameStep() {
    return _cardForm([
      const Text(
        'Apa nama depanmu?',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _firstNameCtrl,
        style: const TextStyle(color: Color(0XFFA8A8A8)),
        cursorColor: Colors.white,
        textAlign: TextAlign.left,
        decoration: InputDecoration(
          labelText: 'Nama depan',
          labelStyle: const TextStyle(color: Color(0XFFA8A8A8)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: Colors.black,
        ),
      ),
    ]);
  }

  Widget _buildRDIInfoStep() {
    return _cardForm([
      const SizedBox(height: 16),
      Text(
        'Oke $_namaDepan. Kita hitung dulu RDI-mu ya',
        style: GoogleFonts.sreeKrushnadevaraya(fontSize: 36),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      const Text(
        'RDI adalah singkatan dari Recommended Daily Intake atau Asupan Harian yang Direkomendasikan. Ini adalah jumlah rata-rata asupan nutrisi harian yang cukup untuk memenuhi kebutuhan hampir semua individu sehat dalam kelompok usia dan jenis kelamin tertentu, dan biasanya digunakan sebagai panduan gizi.',
        textAlign: TextAlign.justify,
        style: TextStyle(color: Colors.black),
      ),
    ]);
  }

  Widget _buildBodyDataStep() {
    return _cardForm([
      const Text(
        'Tinggi ?',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      _blackBoxField(
        label: 'Tinggi (cm)',
        icon: Icons.height,
        controller: _heightCtrl,
        keyboard: TextInputType.number,
      ),
      const SizedBox(height: 16),
      const Text(
        'Berat badan ?',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      _blackBoxField(
        label: 'Berat (kg)',
        icon: Icons.monitor_weight,
        controller: _weightCtrl,
        keyboard: TextInputType.number,
      ),
      const SizedBox(height: 24),
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
      style: const TextStyle(color: Colors.grey),
      cursorColor: Colors.grey,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(icon, color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.black,
      ),
      keyboardType: keyboard,
    );
  }

  Widget _buildBirthAndGenderStep() {
    return _cardForm([
      const Text(
        'Tanggal lahir',
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
      const SizedBox(height: 8),
      InkWell(
        onTap: _selectDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _birthDateCtrl.text.isEmpty
                      ? 'Pilih tanggal'
                      : _birthDateCtrl.text,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Jenis kelamin',
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedGender,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            dropdownColor: Colors.black,
            isExpanded: true,
            hint: const Text(
              'Pilih jenis kelamin',
              style: TextStyle(color: Colors.grey),
            ),
            items: ['Laki-laki', 'Perempuan']
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: const TextStyle(color: Colors.grey)),
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
    // PERBAIKAN: Menggunakan struktur List Map untuk menghindari error sintaks Record Dart.
    final options = [
      {
        'title': 'Rendah',
        'desc': 'Sebagian besar waktu duduk dan jarang bergerak. Hampir tidak pernah olahraga.',
      },
      {
        'title': 'Ringan',
        'desc': 'Ada sedikit aktivitas fisik harian atau olahraga ringan 1-3 kali seminggu.',
      },
      {
        'title': 'Sedang',
        'desc': 'Rutin olahraga 3-5 kali seminggu atau pekerjaan yang cukup banyak gerak.',
      },
      {
        'title': 'Berat',
        'desc': 'Latihan intens hampir setiap hari atau pekerjaan fisik yang berat.',
      },
      {
        'title': 'Sangat Berat',
        'desc': 'Latihan sangat intens setiap hari atau kerja fisik berat sepanjang hari.',
      },
    ];

    return _cardForm([
      const Text(
        'Level aktivitas',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 14),
      ...options.map((o) => _activityBox(o['title']!, o['desc']!)).toList(),
      const SizedBox(height: 22),
    ]);
  }

  Widget _activityBox(String title, String desc) {
    final isSelected = _activityLevel == title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _activityLevel = title),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0XFFFDE4C6), // bg abu muda
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF5A16) // oranye seleksi
                  : Colors.black,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFFFF5A16) : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
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
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedMode = label),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : const Color(0XFFFFB669),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0XFFFFB669),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)} kkal',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieResultStep() {
    return _cardForm([
      const Text(
        'Berikut RDI yang direkomendasikan oleh\nLangsingIn. Silakan memilih.',
        style: TextStyle(fontSize: 16, height: 1.4),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),

      /* --- 3 PILIHAN --- */
      _rdiBox('Maintenance', _maintenance, Colors.blue),
      const SizedBox(height: 12),
      _rdiBox('Surplus (Bulking)', _surplus, Colors.green),
      const SizedBox(height: 12),
      _rdiBox('Deficit (Cutting)', _deficit, Colors.red),

      const SizedBox(height: 24),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0XFFFDE4C6), // latar belakang
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black),
        ),
        child: const Text(
          'Angka di atas merupakan rekomendasi asupan\nharian kalorimu sesuai kebutuhan yang kamu jalani',
          style: TextStyle(fontSize: 12, color: Colors.black),
          textAlign: TextAlign.center,
        ),
      ),
    ]);
  }

  Widget _buildFinalFormStep() {
    return _cardForm([
      Text(
        'Masukkan email dan nama pengguna. Jangan lupa diberi kata sandi yang kuat ya!',
        style: GoogleFonts.sreeKrushnadevaraya(fontSize: 24),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _emailCtrl,
        style: const TextStyle(color: Color(0xFFA8A8A8)), // teks input
        cursorColor: const Color(0xFFA8A8A8),
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: const TextStyle(color: Color(0xFFA8A8A8)), // label
          prefixIcon: const Icon(Icons.email, color: Color(0xFFA8A8A8)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.black,
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _usernameCtrl,
        style: const TextStyle(color: Color(0xFFA8A8A8)),
        cursorColor: const Color(0xFFA8A8A8),
        decoration: InputDecoration(
          labelText: 'Nama pengguna',
          labelStyle: const TextStyle(color: Color(0xFFA8A8A8)),
          prefixIcon: const Icon(
            Icons.person_outline,
            color: Color(0xFFA8A8A8),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.black,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _passCtrl,
        style: const TextStyle(color: Color(0xFFA8A8A8)),
        cursorColor: const Color(0xFFA8A8A8),
        decoration: InputDecoration(
          labelText: 'Kata sandi',
          labelStyle: const TextStyle(color: Color(0xFFA8A8A8)),
          prefixIcon: const Icon(Icons.lock, color: Color(0xFFA8A8A8)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.black,
        ),
        obscureText: true,
      ),
      const SizedBox(height: 8),
      const Text(
        'Minimal 6 karakter',
        style: TextStyle(fontSize: 12, color: Colors.black54),
      ),
    ]);
  }

  Widget _cardForm(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}