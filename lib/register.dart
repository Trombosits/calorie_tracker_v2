import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:calorie_tracker_v2/login.dart';
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
  String _selectedMode = 'Maintenance';

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
}
