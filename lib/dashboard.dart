import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  // =========================================================================
  // TANDA UNTUK TEMAN: Variabel di bawah ini adalah penampung data dinamis.
  // Pastikan saat memanggil `DashboardPage()`, data ini dioper dari state/database.
  // =========================================================================
  final int totalTargetKalori;
  final int totalKaloriMasuk;
  final int totalKaloriKeluar;
  final int protein;
  final int karbohidrat;
  final int lemak;

  const DashboardPage({
    Key? key,
    required this.totalTargetKalori,
    required this.totalKaloriMasuk,
    required this.totalKaloriKeluar,
    required this.protein,
    required this.karbohidrat,
    required this.lemak,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Rumus perhitungan sisa kalori harian
    int sisaKalori = totalTargetKalori - totalKaloriMasuk + totalKaloriKeluar;
    if (sisaKalori < 0) sisaKalori = 0;

    // Kalkulasi progress bar (0.0 sampai 1.0)
    double progressFraction = totalTargetKalori > 0 ? (totalKaloriMasuk / totalTargetKalori) : 0.0;
    if (progressFraction > 1.0) progressFraction = 1.0;
    int progressPercentage = (progressFraction * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.white, // Background putih bersih sesuai request
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120), // Jarak bawah agar tidak tertutup navbar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Card Utama: Monitor Kalori (Warna Oranye)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFA6623),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFA6623).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monitor kalori', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$totalKaloriMasuk', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold, height: 1)),
                        Text(' / $totalTargetKalori', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressFraction,
                        backgroundColor: Colors.white,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE25212)),
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sisa: $sisaKalori kkal', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        Text('$progressPercentage%', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Card Kalori Masuk
              _buildInOutCard(
                icon: Icons.restaurant_rounded,
                title: 'Kalori Masuk',
                value: '$totalKaloriMasuk',
                iconBgColor: const Color(0xFFFCE9DB),
                iconColor: const Color(0xFFFA6623),
              ),
              const SizedBox(height: 14),

              // 3. Card Kalori Keluar
              _buildInOutCard(
                icon: Icons.directions_run_rounded,
                title: 'Kalori Keluar',
                value: '$totalKaloriKeluar',
                iconBgColor: const Color(0xFFF3EDEC),
                iconColor: const Color(0xFF8A7773),
              ),
              const SizedBox(height: 32),

              // 4. Section Makronutrien
              const Center(
                child: Text('Makronutrien', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.black87)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNutrientCard('Protein', '${protein}g', Icons.egg_alt_outlined),
                  _buildNutrientCard('Karbo', '${karbohidrat}g', Icons.bakery_dining_outlined),
                  _buildNutrientCard('Lemak', '${lemak}g', Icons.water_drop_outlined),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper Card Kalori Masuk / Keluar
  Widget _buildInOutCard({required IconData icon, required String title, required String value, required Color iconBgColor, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  const Text('kkal', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Helper Tiga Kotak Makronutrien bawah
  Widget _buildNutrientCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(color: const Color(0xFFFCEBEB), borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.black87),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
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