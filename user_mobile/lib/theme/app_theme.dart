import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// JNE Attendance — Centralized Design System
///
/// Sumber tunggal untuk warna, surface, dan dekorasi. Sebelumnya tiap screen
/// hardcode `Color(0xFF15203A)`, `brandRed`, dst. Sekarang semua lewat sini
/// supaya konsisten & gampang dirawat.
/// ─────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ── Brand JNE ──
  static const Color brandRed = Color(0xFFE31E24);
  static const Color brandRedDark = Color(0xFFB91C1C);
  static const Color jneOrange = Color(0xFFFF6B00);

  // ── Accent semantik ──
  static const Color blue = Color(0xFF2563EB);
  static const Color sky = Color(0xFF3B82F6);
  static const Color green = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color violet = Color(0xFF6366F1);

  // ── Surface gelap ──
  static const Color darkBg = Color(0xFF0B1120);
  static const Color darkCard = Color(0xFF15203A);
  static const Color darkCardAlt = Color(0xFF1E293B);

  // ── Surface terang ──
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color lightCard = Colors.white;

  // ── Teks ──
  static const Color inkPrimary = Color(0xFF0F172A);
  static const Color inkSub = Color(0xFF64748B);
  static const Color inkFaint = Color(0xFF94A3B8);

  /// Gradient hero navy yang dipakai untuk header & kartu utama.
  static const List<Color> heroGradient = [Color(0xFF15203A), Color(0xFF0B1120)];

  /// Gradient brand JNE oranye → merah (untuk hero bold & tombol utama).
  static const List<Color> brandGradient = [Color(0xFFFF8A1E), Color(0xFFE31E24)];

  /// Gradient ungu→biru untuk aksen sekunder.
  static const List<Color> coolGradient = [Color(0xFF6366F1), Color(0xFF2563EB)];
}

/// Palet sadar tema. Buat sekali per build dari `context.palette`.
class AppPalette {
  final bool isDark;
  const AppPalette(this.isDark);

  Color get bg => isDark ? AppColors.darkBg : AppColors.lightBg;
  /// Sama dengan [bg] — disatukan supaya semua layar punya background konsisten.
  Color get auroraBase => bg;
  Color get card => isDark ? AppColors.darkCard : AppColors.lightCard;
  Color get cardAlt => isDark ? AppColors.darkCardAlt : AppColors.lightBg;
  Color get textPrimary => isDark ? Colors.white : AppColors.inkPrimary;
  Color get textSub => isDark ? AppColors.inkFaint : AppColors.inkSub;
  Color get textFaint => isDark ? Colors.white38 : AppColors.inkFaint;
  Color get border =>
      isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0);

  /// Bayangan lembut hanya di light mode (dark mode pakai border tipis).
  List<BoxShadow>? get cardShadow => isDark
      ? null
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ];

  /// Dekorasi kartu standar.
  BoxDecoration cardDecoration({double radius = 24, Color? color}) =>
      BoxDecoration(
        color: color ?? card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
        boxShadow: cardShadow,
      );

  // ── Glassmorphism ──
  /// Isi kaca translucent (dipakai di atas background aurora + BackdropFilter).
  Color get glassFill =>
      isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.55);
  Color get glassBorder =>
      isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.7);

  /// Hero gradient brand JNE (oranye → merah) dengan glow kuat.
  BoxDecoration brandHeroDecoration({double radius = 28}) => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.brandGradient,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandRed.withValues(alpha: 0.45),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      );

  /// Dekorasi hero navy SOLID (untuk header utama tiap layar). Tanpa gradient.
  BoxDecoration heroDecoration({double radius = 28}) => BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      );
}

extension AppPaletteX on BuildContext {
  /// Palet sadar tema yang ikut rebuild saat dark mode berubah.
  AppPalette get palette => AppPalette(watch<AppProvider>().isDarkMode);
}
