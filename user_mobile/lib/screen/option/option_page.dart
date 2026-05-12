import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/geofence_service.dart';

class OptionPage extends StatelessWidget {
  const OptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;

    final bg          = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardBg      = isDark ? const Color(0xFF131D2E) : Colors.white;
    final appBarBg    = isDark ? const Color(0xFF0B1120) : const Color(0xFF005596);
    final titleColor  = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final descColor   = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final sectionColor= isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);
    final chevronColor= isDark ? const Color(0xFF1E3050)  : const Color(0xFFCBD5E1);
    final shadowColor = isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'MENU LAYANAN',
          style: GoogleFonts.outfit(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Aktivitas Kerja', sectionColor),
            const SizedBox(height: 12),
            _featureCard(
              context,
              title: 'Presensi Kehadiran',
              desc: 'Verifikasi wajah untuk mulai & selesai kerja.',
              icon: Icons.fingerprint_rounded,
              color: const Color(0xFFE31E24),
              cardBg: cardBg,
              titleColor: titleColor,
              descColor: descColor,
              chevronColor: chevronColor,
              shadowColor: shadowColor,
              onTap: () => Navigator.pushNamed(context, '/attendance'),
            ),
            const SizedBox(height: 12),
            _featureCard(
              context,
              title: 'Pengajuan Izin',
              desc: 'Kirim permohonan cuti, sakit, atau dinas.',
              icon: Icons.assignment_turned_in_rounded,
              color: const Color(0xFFF59E0B),
              cardBg: cardBg,
              titleColor: titleColor,
              descColor: descColor,
              chevronColor: chevronColor,
              shadowColor: shadowColor,
              onTap: () => Navigator.pushNamed(context, '/leave'),
            ),
            const SizedBox(height: 12),
            _featureCard(
              context,
              title: 'Pengajuan Lembur',
              desc: 'Permohonan jam kerja tambahan (Overtime).',
              icon: Icons.more_time_rounded,
              color: const Color(0xFF005596),
              cardBg: cardBg,
              titleColor: titleColor,
              descColor: descColor,
              chevronColor: chevronColor,
              shadowColor: shadowColor,
              onTap: () => Navigator.pushNamed(context, '/overtime'),
            ),
            const SizedBox(height: 12),
            _featureCard(
              context,
              title: 'Riwayat Kehadiran',
              desc: 'Lihat history absensi per bulan & tahun.',
              icon: Icons.history_rounded,
              color: const Color(0xFF4F46E5),
              cardBg: cardBg,
              titleColor: titleColor,
              descColor: descColor,
              chevronColor: chevronColor,
              shadowColor: shadowColor,
              onTap: () => Navigator.pushNamed(context, '/history'),
            ),
            const SizedBox(height: 28),
            _sectionTitle('Jadwal & Komunikasi', sectionColor),
            const SizedBox(height: 12),
            _featureCard(
              context,
              title: 'Smart Calendar',
              desc: 'Jadwal acara & kegiatan departemen dari Admin.',
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFF8B5CF6),
              cardBg: cardBg,
              titleColor: titleColor,
              descColor: descColor,
              chevronColor: chevronColor,
              shadowColor: shadowColor,
              onTap: () => Navigator.pushNamed(context, '/calendar'),
            ),
            const SizedBox(height: 12),
            _featureCard(
              context,
              title: 'Hub Support (Chat)',
              desc: 'Hubungi Admin untuk kendala operasional.',
              icon: Icons.chat_bubble_rounded,
              color: const Color(0xFF10B981),
              cardBg: cardBg,
              titleColor: titleColor,
              descColor: descColor,
              chevronColor: chevronColor,
              shadowColor: shadowColor,
              onTap: () => Navigator.pushNamed(context, '/chat'),
            ),
            const SizedBox(height: 28),
            _sectionTitle('Bantuan Darurat', sectionColor),
            const SizedBox(height: 12),
            _buildSOSCard(context),
            const SizedBox(height: 28),
            _sectionTitle('Aplikasi', sectionColor),
            const SizedBox(height: 12),
            _featureCard(
              context,
              title: 'Pengaturan Aplikasi',
              desc: 'Mode gelap, notifikasi, dan informasi.',
              icon: Icons.settings_outlined,
              color: const Color(0xFF64748B),
              cardBg: cardBg,
              titleColor: titleColor,
              descColor: descColor,
              chevronColor: chevronColor,
              shadowColor: shadowColor,
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t, Color color) => Text(
    t.toUpperCase(),
    style: GoogleFonts.outfit(
      color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5,
    ),
  );

  Widget _featureCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color titleColor,
    required Color descColor,
    required Color chevronColor,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: shadowColor, blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: titleColor, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: GoogleFonts.outfit(
                      color: descColor, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4, letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: chevronColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSOSConfirm(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE31E24), Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE31E24).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emergency_share_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DARURAT (SOS)',
                    style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Kirim lokasi & sinyal darurat ke Admin.',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500, height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }

  void _showSOSConfirm(BuildContext context) {
    bool dialogLoading = false;
    final isDark = context.read<AppProvider>().isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF131D2E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'KIRIM SINYAL SOS?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFFE31E24), fontSize: 16),
          ),
          content: Text(
            'Sinyal darurat beserta lokasi GPS Anda akan dikirimkan ke Admin JNE Pusat. Pastikan Anda benar-benar dalam keadaan darurat.',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: dialogLoading ? null : () => Navigator.pop(ctx),
              child: Text('BATAL', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              onPressed: dialogLoading
                  ? null
                  : () async {
                      setDialogState(() => dialogLoading = true);
                      try {
                        final geo = ctx.read<GeofenceService>();
                        final pos = geo.currentPosition;
                        final lat = pos?.latitude ?? geo.officeLat;
                        final lng = pos?.longitude ?? geo.officeLng;
                        final locationName = pos != null
                            ? 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}'
                            : 'Lokasi tidak tersedia';
                        await ctx.read<AppProvider>().sendSOS(lat, lng, locationName);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                'SOS Berhasil Terkirim! Admin segera merespon.',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: dialogLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('KIRIM SEKARANG', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
