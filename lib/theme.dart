import 'package:flutter/material.dart';

// Class untuk mengelola state Tema (Hanya Warna, tanpa Dark Mode)
class ThemeNotifier extends ChangeNotifier {
  Color _seedColor = const Color(0xFFFF5A16); 

  Color get seedColor => _seedColor;

  void updateSeedColor(Color newColor) {
    _seedColor = newColor;
    notifyListeners();
  }
}

// Variabel global agar bisa diakses dari file mana saja
final themeNotifier = ThemeNotifier();