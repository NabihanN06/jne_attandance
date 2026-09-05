import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class OptionPage extends StatelessWidget {
  static const Color jneBlue = Color(0xFF005596);
  static const Color jneRed = Color(0xFFE31E24);
  static const Color bgLight = Color(0xFFF8FAFC);

  const OptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : bgLight,
      appBar: AppBar(
        backgroundColor: jneBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'MENU LAYANAN',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Aktivitas Kerja'),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Presensi Kehadiran',
              'Verifikasi wajah untuk mulai/selesai kerja.',
              Icons.fingerprint_rounded,
              jneRed,
              () => Navigator.pushNamed(context, '/attendance'),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Recap Bulanan',
              'Ringkasan kinerja & kehadiran bulan ini.',
              Icons.insights_rounded,
              const Color(0xFFE31E24),
              () => Navigator.pushNamed(context, '/recap'),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Pengajuan Izin',
              'Kirim permohonan cuti, sakit, atau dinas.',
              Icons.assignment_turned_in_rounded,
              Colors.orange,
              () => Navigator.pushNamed(context, '/leave'),
              imageAsset: 'assets/images/iconapk/leaverequest.png',
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Smart Calendar',
              'Jadwal meeting dan acara departemen.',
              Icons.calendar_month_rounded,
              const Color(0xFF8B5CF6),
              () => Navigator.pushNamed(context, '/calendar'),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Hub Support (Chat)',
              'Hubungi Admin untuk kendala operasional.',
              Icons.chat_bubble_rounded,
              const Color(0xFF10B981),
              () => Navigator.pushNamed(context, '/chat'),
              imageAsset: 'assets/images/iconapk/chatHR.png',
            ),

            const SizedBox(height: 32),
            _buildSectionTitle('Aplikasi'),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Pengaturan Aplikasi',
              'Mode gelap, notifikasi, dan informasi.',
              Icons.settings_outlined,
              Colors.blueGrey,
              () => Navigator.pushNamed(context, '/settings'),
              imageAsset: 'assets/images/iconapk/setelan.png',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String t) {
    return Text(
      t.toUpperCase(),
      style: GoogleFonts.outfit(
        color: const Color(0xFF94A3B8),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String desc,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? imageAsset,
  }) {
    // Theme-aware: kartu dulu hardcode putih → blok putih nyolok di dark mode.
    final isDark = Provider.of<AppProvider>(context, listen: false).isDarkMode;
    final cardColor = isDark ? const Color(0xFF15203A) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final descColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: imageAsset != null
                  ? Image.asset(imageAsset, width: 28, height: 28)
                  : Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: titleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.outfit(
                      color: descColor,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}
