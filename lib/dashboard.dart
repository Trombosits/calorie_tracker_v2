import 'package:calorie_tracker_v2/fetch_kalori.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatefulWidget {
  final int totalTargetKalori;
  final int totalKaloriMasuk;
  final int totalKaloriKeluar;
  final int protein;
  final int karbohidrat;
  final int lemak;

  const DashboardPage({
    super.key,
    this.totalTargetKalori = 2000,
    this.totalKaloriMasuk = 0,
    this.totalKaloriKeluar = 0,
    this.protein = 0,
    this.karbohidrat = 0,
    this.lemak = 0,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  int _targetKalori = 2000;
  int _kaloriMasuk = 0;
  int _kaloriKeluar = 0;
  int _protein = 0;
  int _karbohidrat = 0;
  int _lemak = 0;
  String? _error;

  @override
  void initState() {
    super.initState();

    _targetKalori = widget.totalTargetKalori;
    _kaloriMasuk = widget.totalKaloriMasuk;
    _kaloriKeluar = widget.totalKaloriKeluar;
    _protein = widget.protein;
    _karbohidrat = widget.karbohidrat;
    _lemak = widget.lemak;

    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final target = await KaloriRepository.fetchTargetKalori(userId: user.id);
      final laporan = await KaloriRepository.fetchLaporanHariIni(
        userId: user.id,
      );

      if (!mounted) return;

      setState(() {
        _targetKalori = target;
        _kaloriMasuk = laporan.totalKaloriIn;
        _kaloriKeluar = laporan.totalKaloriOut;
        _protein = laporan.totalProtein;
        _karbohidrat = laporan.totalKarbo;
        _lemak = laporan.totalLemak;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int sisaKalori = _targetKalori - _kaloriMasuk + _kaloriKeluar;
    if (sisaKalori < 0) sisaKalori = 0;

    double progressFraction =
        _targetKalori > 0 ? (_kaloriMasuk / _targetKalori) : 0.0;
    if (progressFraction > 1.0) progressFraction = 1.0;
    int progressPercentage = (progressFraction * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_loading) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                ],
                if (_error != null) ...[
                  _buildErrorBox(_error!),
                  const SizedBox(height: 16),
                ],

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFA6623),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFA6623).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monitor kalori',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$_kaloriMasuk',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                          Text(
                            ' / $_targetKalori',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          backgroundColor: Colors.white,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFE25212),
                          ),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sisa: $sisaKalori kkal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$progressPercentage%',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildInOutCard(
                  icon: Icons.restaurant_rounded,
                  title: 'Kalori Masuk',
                  value: '$_kaloriMasuk',
                  iconBgColor: const Color(0xFFFCE9DB),
                  iconColor: const Color(0xFFFA6623),
                ),
                const SizedBox(height: 14),

                _buildInOutCard(
                  icon: Icons.directions_run_rounded,
                  title: 'Kalori Keluar',
                  value: '$_kaloriKeluar',
                  iconBgColor: const Color(0xFFF3EDEC),
                  iconColor: const Color(0xFF8A7773),
                ),
                const SizedBox(height: 32),

                const Center(
                  child: Text(
                    'Makronutrien',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNutrientCard(
                      'Protein',
                      '${_protein}g',
                      Icons.egg_alt_outlined,
                    ),
                    _buildNutrientCard(
                      'Karbo',
                      '${_karbohidrat}g',
                      Icons.bakery_dining_outlined,
                    ),
                    _buildNutrientCard(
                      'Lemak',
                      '${_lemak}g',
                      Icons.water_drop_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        'Gagal memuat dashboard: $error',
        style: TextStyle(color: Colors.red.shade800),
      ),
    );
  }

  Widget _buildInOutCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'kkal',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEBEB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.black87),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
