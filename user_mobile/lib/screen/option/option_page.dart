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
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: jneBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'MENU LAYANAN',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
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
              'Pengajuan Izin',
              'Kirim permohonan cuti, sakit, atau dinas.',
              Icons.assignment_turned_in_rounded,
              Colors.orange,
              () => Navigator.pushNamed(context, '/leave'),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Pengajuan Lembur',
              'Permohonan jam kerja tambahan (Overtime).',
              Icons.more_time_rounded,
              jneBlue,
              () => Navigator.pushNamed(context, '/overtime'),
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
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Bantuan Darurat'),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String t) {
    return Text(t.toUpperCase(), style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1));
  }

  Widget _buildFeatureCard(BuildContext context, String title, String desc, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(desc, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12, height: 1.4, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
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
          gradient: const LinearGradient(colors: [Color(0xFFE31E24), Color(0xFFB71C1C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: const Color(0xFFE31E24).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.emergency_share_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DARURAT (SOS)', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('Kirim lokasi dan sinyal darurat ke Admin.', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500)),
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
        title: Text('KIRIM SINYAL SOS?', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFFE31E24))),
        content: Text('Sinyal darurat beserta lokasi GPS Anda akan dikirimkan ke Admin JNE Pusat. Pastikan Anda benar-benar dalam keadaan darurat.', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('BATAL', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w700))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AppProvider>().sendSOS(-3.414, 114.838, 'Martapura Street');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS Berhasil Terkirim! Admin segera merespon.'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE31E24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('KIRIM SEKARANG', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}