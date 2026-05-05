import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../utils/connectivity_service.dart';
import '../../utils/geofence_service.dart';
import '../../models/app_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final conn = context.watch<ConnectivityService>();
    final geo = context.watch<GeofenceService>();
    final user = p.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _selectedIndex == 0 
        ? _buildHomeBody(context, p, geo, user, conn)
        : _buildPlaceholderPage(_selectedIndex),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeBody(BuildContext context, AppProvider p, GeofenceService geo, UserModel? user, ConnectivityService conn) {
    const Color jneRed = Color(0xFFE31E24);
    const Color jneBlue = Color(0xFF005596);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ── Header Section ──
          Stack(
            children: [
              Container(
                height: 220,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: jneBlue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: CustomPaint(
                  painter: WavePainter(),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset('assets/images/logo_jne.png', width: 32, height: 32, errorBuilder: (_, _, _) => const Icon(Icons.local_shipping, color: jneRed, size: 24)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'JNE E-Presence',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildConnIndicator(conn),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => Navigator.pushNamed(context, '/notification'),
                                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Update Kehadiran',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildHeaderStat('24', 'Hadir Bulan Ini', Colors.white)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildHeaderStat('02', 'Izin / Sakit', Colors.white.withValues(alpha: 0.9))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Menu Grid ──
                Text(
                  'Menu Utama',
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildMenuCard(context, 'Presensi', Icons.fingerprint_rounded, jneRed, () => Navigator.pushNamed(context, '/attendance')),
                    _buildMenuCard(context, 'Izin', Icons.assignment_rounded, Colors.orange, () => Navigator.pushNamed(context, '/leave')),
                    _buildMenuCard(context, 'Lembur', Icons.more_time_rounded, jneBlue, () => Navigator.pushNamed(context, '/overtime')),
                    _buildMenuCard(context, 'Statistik', Icons.bar_chart_rounded, Colors.blue, () => Navigator.pushNamed(context, '/statistic')),
                    _buildMenuCard(context, 'Riwayat', Icons.history_rounded, Colors.teal, () => Navigator.pushNamed(context, '/history')),
                    _buildMenuCard(context, 'SOS', Icons.emergency_share_rounded, jneRed, () => Navigator.pushNamed(context, '/option')),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Activity Section ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Aktivitas Hari Ini',
                      style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Lihat Semua',
                      style: GoogleFonts.outfit(color: jneBlue, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActivityCard(
                  title: 'Absensi Masuk Terdeteksi',
                  desc: geo.isInRange ? 'Lokasi Anda sudah sesuai dengan radius kantor.' : 'Segera lakukan absensi di area kantor.',
                  time: '08.00 WIB',
                  icon: Icons.location_on_rounded,
                  color: geo.isInRange ? Colors.green : jneRed,
                ),
                const SizedBox(height: 16),
                _buildActivityCard(
                  title: 'Update Pengumuman',
                  desc: 'Rapat koordinasi bulanan akan diadakan besok jam 10 pagi.',
                  time: '10.00 WIB',
                  icon: Icons.campaign_rounded,
                  color: Colors.blue,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: GoogleFonts.outfit(color: const Color(0xFF005596), fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              Text('/ 26', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return FadeInUp(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard({required String title, required String desc, required String time, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11, height: 1.4, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                      child: Text(time, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'Beranda'),
          _buildNavItem(1, Icons.notifications_rounded, 'Notifikasi'),
          _buildNavItem(2, Icons.person_rounded, 'Profil'),
          _buildNavItem(3, Icons.grid_view_rounded, 'Opsi'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.pushNamed(context, '/notification');
          return;
        }
        if (index == 2) {
          Navigator.pushNamed(context, '/profile');
          return;
        }
        if (index == 3) {
          Navigator.pushNamed(context, '/option');
          return;
        }
        setState(() => _selectedIndex = index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF005596) : const Color(0xFF94A3B8), size: 24),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.outfit(color: isSelected ? const Color(0xFF005596) : const Color(0xFF94A3B8), fontSize: 10, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildConnIndicator(ConnectivityService conn) {
    bool isOnline = conn.status != ConnectionStatus.none;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: isOnline ? Colors.greenAccent : Colors.redAccent)),
          const SizedBox(width: 8),
          Text(isOnline ? 'ON' : 'OFF', style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPage(int index) {
    return Center(child: Text('Halaman ${index + 1} Segera Hadir', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w700)));
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    for (var i = 0; i < 5; i++) {
      final y = 40.0 + (i * 30);
      path.moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 20) {
        path.lineTo(x, y + (x % 40 == 0 ? 10 : -10));
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}