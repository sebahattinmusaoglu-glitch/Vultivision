import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Ana renkler
  static const Color primary = Color(0xFFFF6B6B);      // Mercan pembe
  static const Color primaryDark = Color(0xFFE55555);  // Koyu mercan (pressed state)

  // Arka planlar
  static const Color background = Color(0xFF000000);   // Saf siyah
  static const Color surface = Color(0xFF111111);      // Kart / bottom sheet
  static const Color surfaceVariant = Color(0xFF1A1A1A); // Input, liste item

  // Metin
  static const Color textPrimary = Color(0xFFFFFFFF);  // Ana metin
  static const Color textSecondary = Color(0xFF9E9E9E); // İkincil metin
  static const Color textTertiary = Color(0xFF555555);  // Placeholder

  // Ayırıcı
  static const Color divider = Color(0xFF222222);

  // Durum renkleri
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF50);
}