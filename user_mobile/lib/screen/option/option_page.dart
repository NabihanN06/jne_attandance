import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/geofence_service.dart';

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
              'Pengajuan Lembur',
              'Permohonan jam kerja tambahan (Overtime).',
              Icons.more_time_rounded,
              jneBlue,
              () => Navigator.pushNamed(context, '/overtime'),
              imageAsset: 'assets/images/iconapk/iconpengajuan.png',
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
            _buildSectionTitle('Darurat'),
            const SizedBox(height: 16),
            _buildSOSCard(context),

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

  Widget _buildSOSCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSOSConfirm(context),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE31E24), Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE31E24).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/iconapk/sosicon.png',
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DARURAT (SOS)',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kirim lokasi dan sinyal darurat ke Admin.',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _showSOSConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'KIRIM SINYAL SOS?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: const Color(0xFFE31E24),
          ),
        ),
        content: Text(
          'Sinyal darurat beserta lokasi GPS Anda akan dikirimkan ke Admin JNE Pusat. Pastikan Anda benar-benar dalam keadaan darurat.',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'BATAL',
              style: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              final geo = context.read<GeofenceService>();
              final pos = geo.currentPosition;
              if (pos == null) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Lokasi GPS belum siap. Aktifkan GPS lalu coba lagi.',
                    ),
                    backgroundColor: Color(0xFFE31E24),
                  ),
                );
                return;
              }
              try {
                await context.read<AppProvider>().sendSOS(
                  pos.latitude,
                  pos.longitude,
                  'Lokasi Anda saat ini',
                );
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('SOS terkirim. Admin akan merespon segera.'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal kirim SOS: $e'),
                    backgroundColor: const Color(0xFFE31E24),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'KIRIM SEKARANG',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
