import 'package:flutter/material.dart';
import 'dashboard.dart';

// =========================================================================
// TANDA UNTUK TEMAN: Import file halaman input asli kalian di sini. Contoh:
// import 'input.dart'; 
// import 'profile.dart';
// =========================================================================

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // State Management Lokal Aplikasi
  int totalKaloriMasuk = 0;
  int totalKaloriKeluar = 0;
  int protein = 0;
  int karbohidrat = 0;
  int lemak = 0;

  // Fungsi menambah nutrisi dari makanan (Dipanggil di Laman Input)
  void tambahMakanan({required int kalori, required int prot, required int karbo, required int lem}) {
    setState(() {
      totalKaloriMasuk += kalori;
      protein += prot;
      karbohidrat += karbo;
      lemak += lem;
      _currentIndex = 0; // Balik ke Dashboard setelah submit
    });
  }

  // Fungsi menambah kalori keluar dari olahraga (Dipanggil di Laman Input)
  void tambahOlahraga({required int kalori}) {
    setState(() {
      totalKaloriKeluar += kalori;
      _currentIndex = 0; // Balik ke Dashboard setelah submit
    });
  }

  // Getter List Halaman Aplikasi
  List<Widget> get _pages => [
    DashboardPage(
      totalTargetKalori: 2600,
      totalKaloriMasuk: totalKaloriMasuk,
      totalKaloriKeluar: totalKaloriKeluar,
      protein: protein,
      karbohidrat: karbohidrat,
      lemak: lemak,
    ),
    
    // =========================================================================
    // TANDA UNTUK TEMAN: Ganti widget `Center()` di bawah ini dengan class halaman 
    // input buatanmu. Jangan lupa oper parameter fungsinya agar sinkron ke Dashboard.
    // Contoh pemasangan:
    // HalamanInputKamu(onMakananAdded: tambahMakanan, onOlahragaAdded: tambahOlahraga),
    // =========================================================================
    const Center(
      child: Text(
        'Ganti bagian ini dengan file input.dart buatan temanmu', 
        textAlign: TextAlign.center, 
        style: TextStyle(fontSize: 16, color: Colors.grey)
      )
    ),

    // =========================================================================
    // TANDA UNTUK TEMAN: Ganti widget Center ini dengan class halaman Profil asli
    // =========================================================================
    const Center(child: Text('Laman Profil', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Menampilkan halaman aktif
          _pages[_currentIndex],
          
          // Floating Navbar UI sesuai desain
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3134),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavButton(icon: Icons.home_rounded, index: 0),
                    const SizedBox(width: 15),
                    _buildNavButton(icon: Icons.restaurant_menu_rounded, index: 1),
                    const SizedBox(width: 15),
                    _buildNavButton(icon: Icons.settings_rounded, index: 2),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, required int index}) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFA6623) : const Color(0xFF43494D),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}