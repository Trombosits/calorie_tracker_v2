import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'input.dart';
import 'profile.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _dashboardRefreshTick = 0;

  List<Widget> get _pages => [
        DashboardPage(key: ValueKey(_dashboardRefreshTick)),
        const HalamanUtama(),
        const ProfilePage(),
      ];

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;

      if (index == 0) {
        _dashboardRefreshTick++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _pages[_currentIndex],
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3134),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavButton(icon: Icons.home_rounded, index: 0),
                    const SizedBox(width: 15),
                    _buildNavButton(
                      icon: Icons.restaurant_menu_rounded,
                      index: 1,
                    ),
                    const SizedBox(width: 15),
                    _buildNavButton(icon: Icons.person_rounded, index: 2),
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
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => _changePage(index),
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
